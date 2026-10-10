use anyhow::{anyhow, bail, Result};
use c35_store::snowflake_id;
use serde::Serialize;
use sqlx::{PgPool, Row};

use crate::mention_context::MentionContext;

pub const MODE_ALWAYS: &str = "always";
pub const MODE_AUTO: &str = "auto";
pub const MODE_DISABLED: &str = "disabled";

pub const KIND_USER: &str = "user";
pub const KIND_SITE: &str = "site";

const MAX_BODY_LEN: usize = 12_000;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ScopeInstructionRow {
    pub id: i64,
    pub owner_iid: i64,
    pub scope_kind: String,
    pub scope_iid: i64,
    pub mode: String,
    pub body: String,
}

pub fn normalize_mode(mode: &str) -> Result<String> {
    let m = mode.trim().to_lowercase();
    match m.as_str() {
        MODE_ALWAYS | MODE_AUTO | MODE_DISABLED => Ok(m),
        "" => Ok(MODE_DISABLED.to_string()),
        _ => bail!("invalid mode: {mode}"),
    }
}

pub fn normalize_kind(kind: &str) -> Result<String> {
    let k = kind.trim().to_lowercase();
    match k.as_str() {
        KIND_USER | KIND_SITE => Ok(k),
        _ => bail!("invalid scope_kind: {kind}"),
    }
}

pub fn instruction_auto_match(user_text: &str, body: &str) -> bool {
    let ut = user_text.trim().to_lowercase();
    if ut.len() < 3 {
        return false;
    }
    let body_l = body.to_lowercase();
    for word in body_l.split_whitespace() {
        let w: String = word
            .chars()
            .filter(|c| c.is_alphanumeric())
            .collect();
        if w.len() >= 4 && ut.contains(&w) {
            return true;
        }
    }
    false
}

fn should_inject(mode: &str, user_text: &str, body: &str) -> bool {
    let body = body.trim();
    if body.is_empty() {
        return false;
    }
    match mode {
        MODE_ALWAYS => true,
        MODE_AUTO => instruction_auto_match(user_text, body),
        _ => false,
    }
}

pub fn scope_instruction_prompt_block(
    user_text: &str,
    user_row: Option<&ScopeInstructionRow>,
    site_rows: &[(String, ScopeInstructionRow)],
) -> String {
    let mut out = String::new();
    if let Some(row) = user_row {
        if should_inject(&row.mode, user_text, &row.body) {
            out.push_str("[USER INSTRUCTIONS]\n");
            out.push_str(row.body.trim());
        }
    }
    for (site_name, row) in site_rows {
        if !should_inject(&row.mode, user_text, &row.body) {
            continue;
        }
        if !out.is_empty() {
            out.push_str("\n\n");
        }
        let label = site_name.trim();
        if label.is_empty() {
            out.push_str("[SITE INSTRUCTIONS]\n");
        } else {
            out.push_str(&format!("[SITE INSTRUCTIONS — {label}]\n"));
        }
        out.push_str(row.body.trim());
    }
    out
}

pub async fn scope_instruction_get_row(
    pool: &PgPool,
    scope_kind: &str,
    scope_iid: i64,
) -> Result<Option<ScopeInstructionRow>> {
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, scope_kind, scope_iid, mode, body
        FROM ai.scope_instruction
        WHERE scope_kind = $1 AND scope_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(scope_kind)
    .bind(scope_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| ScopeInstructionRow {
        id: r.get("id"),
        owner_iid: r.get("owner_iid"),
        scope_kind: r.get("scope_kind"),
        scope_iid: r.get("scope_iid"),
        mode: r.get("mode"),
        body: r.get("body"),
    }))
}

async fn scope_instruction_assert_access(
    pool: &PgPool,
    caller_iid: i64,
    scope_kind: &str,
    scope_iid: i64,
    write: bool,
) -> Result<i64> {
    match scope_kind {
        KIND_USER => {
            if scope_iid != caller_iid {
                bail!("forbidden");
            }
            Ok(caller_iid)
        }
        KIND_SITE => c35_mod_site::grant::site_grant_check(pool, caller_iid, scope_iid, write).await,
        _ => bail!("invalid scope_kind"),
    }
}

pub async fn scope_instruction_get(
    pool: &PgPool,
    caller_iid: i64,
    scope_kind: &str,
    scope_iid: i64,
) -> Result<ScopeInstructionRow> {
    let kind = normalize_kind(scope_kind)?;
    if scope_iid <= 0 {
        bail!("scope_iid required");
    }
    let owner_iid =
        scope_instruction_assert_access(pool, caller_iid, &kind, scope_iid, false).await?;
    if let Some(row) = scope_instruction_get_row(pool, &kind, scope_iid).await? {
        return Ok(row);
    }
    Ok(ScopeInstructionRow {
        id: 0,
        owner_iid,
        scope_kind: kind,
        scope_iid,
        mode: MODE_DISABLED.to_string(),
        body: String::new(),
    })
}

pub async fn scope_instruction_put(
    pool: &PgPool,
    caller_iid: i64,
    scope_kind: &str,
    scope_iid: i64,
    mode: &str,
    body: &str,
) -> Result<ScopeInstructionRow> {
    let kind = normalize_kind(scope_kind)?;
    let mode = normalize_mode(mode)?;
    if scope_iid <= 0 {
        bail!("scope_iid required");
    }
    let body = body.trim();
    if body.len() > MAX_BODY_LEN {
        bail!("body too long (max {MAX_BODY_LEN} chars)");
    }
    let owner_iid =
        scope_instruction_assert_access(pool, caller_iid, &kind, scope_iid, true).await?;

    if let Some(row) = scope_instruction_get_row(pool, &kind, scope_iid).await? {
        sqlx::query(
            r#"
            UPDATE ai.scope_instruction
            SET owner_iid = $2, mode = $3, body = $4, updated_ts = NOW()
            WHERE id = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(row.id)
        .bind(owner_iid)
        .bind(&mode)
        .bind(body)
        .execute(pool)
        .await?;
    } else {
        let id = snowflake_id();
        sqlx::query(
            r#"
            INSERT INTO ai.scope_instruction (id, owner_iid, scope_kind, scope_iid, mode, body, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
            "#,
        )
        .bind(id)
        .bind(owner_iid)
        .bind(&kind)
        .bind(scope_iid)
        .bind(&mode)
        .bind(body)
        .execute(pool)
        .await?;
    }

    scope_instruction_get_row(pool, &kind, scope_iid)
        .await?
        .ok_or_else(|| anyhow!("scope_instruction missing after put"))
}

pub async fn scope_instruction_load_for_prompt(
    pool: &PgPool,
    owner_iid: i64,
    site_iids: &[i64],
    site_names: &[(i64, String)],
) -> Result<(Option<ScopeInstructionRow>, Vec<(String, ScopeInstructionRow)>)> {
    let user = scope_instruction_get_row(pool, KIND_USER, owner_iid).await?;

    if site_iids.is_empty() {
        return Ok((user, vec![]));
    }

    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, scope_kind, scope_iid, mode, body
        FROM ai.scope_instruction
        WHERE scope_kind = 'site' AND scope_iid = ANY($1) AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iids)
    .fetch_all(pool)
    .await?;

    let mut site_rows = Vec::new();
    for r in rows {
        let site_iid: i64 = r.get("scope_iid");
        let name = site_names
            .iter()
            .find(|(id, _)| *id == site_iid)
            .map(|(_, n)| n.clone())
            .unwrap_or_default();
        site_rows.push((
            name,
            ScopeInstructionRow {
                id: r.get("id"),
                owner_iid: r.get("owner_iid"),
                scope_kind: r.get("scope_kind"),
                scope_iid: site_iid,
                mode: r.get("mode"),
                body: r.get("body"),
            },
        ));
    }
    Ok((user, site_rows))
}

pub fn mention_site_names(ctx: &MentionContext) -> Vec<(i64, String)> {
    ctx.sites
        .iter()
        .map(|s| (s.site_iid, s.name.clone()))
        .collect()
}
fn preview_trim(s: &str, max: usize) -> String {
    let t = s.trim();
    if t.len() <= max {
        return t.to_string();
    }
    let mut out = t.chars().take(max).collect::<String>();
    out.push_str("...");
    out
}

#[derive(Debug, Clone, Serialize)]
pub struct ScopeInstructionTraceEntry {
    pub scope_kind: String,
    pub scope_iid: i64,
    pub site_name: String,
    pub mode: String,
    pub applied: bool,
    pub body_chars: usize,
    pub body_preview: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct ScopeInstructionTrace {
    pub entries: Vec<ScopeInstructionTraceEntry>,
    pub injected: bool,
    pub block_chars: usize,
    pub block_preview: String,
}

fn trace_entry_from_row(
    site_name: Option<&str>,
    row: &ScopeInstructionRow,
    user_text: &str,
) -> ScopeInstructionTraceEntry {
    let applied = should_inject(&row.mode, user_text, &row.body);
    ScopeInstructionTraceEntry {
        scope_kind: row.scope_kind.clone(),
        scope_iid: row.scope_iid,
        site_name: site_name.unwrap_or("").to_string(),
        mode: row.mode.clone(),
        applied,
        body_chars: row.body.trim().len(),
        body_preview: preview_trim(&row.body, 280),
    }
}

pub fn scope_instruction_build_trace(
    user_text: &str,
    user_row: Option<&ScopeInstructionRow>,
    site_rows: &[(String, ScopeInstructionRow)],
    injected_block: &str,
) -> ScopeInstructionTrace {
    let mut entries = Vec::new();
    if let Some(row) = user_row {
        entries.push(trace_entry_from_row(None, row, user_text));
    }
    for (name, row) in site_rows {
        entries.push(trace_entry_from_row(Some(name), row, user_text));
    }
    let block = injected_block.trim();
    ScopeInstructionTrace {
        entries,
        injected: !block.is_empty(),
        block_chars: block.len(),
        block_preview: preview_trim(block, 480),
    }
}
