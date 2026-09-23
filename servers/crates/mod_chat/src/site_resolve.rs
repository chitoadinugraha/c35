use anyhow::{anyhow, Result};
use sqlx::{PgPool, Row};

#[derive(Debug, Clone)]
pub struct SiteContext {
    pub site_iid: i64,
    pub alien_id: String,
    pub name: String,
}

pub fn site_context_block(ctx: &SiteContext) -> String {
    format!(
        "[SITE CONTEXT] site_iid={} alien_id={} name={}",
        ctx.site_iid,
        ctx.alien_id,
        ctx.name
    )
}

fn alien_id_normalize(raw: &str) -> String {
    raw.trim().trim_start_matches('@').to_lowercase()
}

pub fn site_at_tokens(text: &str) -> Vec<String> {
    let mut out = Vec::new();
    for word in text.split_whitespace() {
        let w = word.trim_matches(|c: char| !c.is_alphanumeric() && c != '@' && c != '_' && c != '-');
        if let Some(rest) = w.strip_prefix('@') {
            let id = alien_id_normalize(rest);
            if !id.is_empty() && !out.contains(&id) {
                out.push(id);
            }
        }
    }
    out
}

async fn site_row_get(pool: &PgPool, caller_iid: i64, site_iid: i64) -> Result<Option<SiteContext>> {
    let row = sqlx::query(
        r#"
        SELECT i.id, COALESCE(i.alien_id, '') AS alien_id, COALESCE(i.name, '') AS name,
               i.owner_iid, g.role
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.kind = 'site' AND i.deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let owner_iid: i64 = row.get("owner_iid");
    let role: Option<String> = row.try_get("role").ok().flatten();
    let allowed = owner_iid == caller_iid || role.as_deref().is_some_and(|r| r != "guest");
    if !allowed {
        return Ok(None);
    }
    Ok(Some(SiteContext {
        site_iid: row.get("id"),
        alien_id: row.get("alien_id"),
        name: row.get("name"),
    }))
}

async fn site_find_by_alien_id(pool: &PgPool, caller_iid: i64, alien_id: &str) -> Result<Option<SiteContext>> {
    let alien_id = alien_id_normalize(alien_id);
    if alien_id.is_empty() {
        return Ok(None);
    }
    let row = sqlx::query(
        r#"
        SELECT i.id, COALESCE(i.alien_id, '') AS alien_id, COALESCE(i.name, '') AS name,
               i.owner_iid, g.role
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL AND LOWER(i.alien_id) = LOWER($1)
        LIMIT 1
        "#,
    )
    .bind(&alien_id)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let owner_iid: i64 = row.get("owner_iid");
    let role: Option<String> = row.try_get("role").ok().flatten();
    let allowed = owner_iid == caller_iid || role.as_deref().is_some_and(|r| r != "guest");
    if !allowed {
        return Ok(None);
    }
    Ok(Some(SiteContext {
        site_iid: row.get("id"),
        alien_id: row.get("alien_id"),
        name: row.get("name"),
    }))
}

async fn site_list_granted(pool: &PgPool, caller_iid: i64) -> Result<Vec<SiteContext>> {
    let rows = sqlx::query(
        r#"
        SELECT i.id, COALESCE(i.alien_id, '') AS alien_id, COALESCE(i.name, '') AS name
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL
          AND (i.owner_iid = $1 OR (g.role IS NOT NULL AND g.role <> 'guest'))
        ORDER BY i.updated_ts DESC
        "#,
    )
    .bind(caller_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|r| SiteContext {
            site_iid: r.get("id"),
            alien_id: r.get("alien_id"),
            name: r.get("name"),
        })
        .collect())
}

fn site_match_by_name(text: &str, sites: &[SiteContext]) -> Option<SiteContext> {
    let lower = text.to_lowercase();
    let mut hits: Vec<&SiteContext> = sites
        .iter()
        .filter(|s| !s.name.is_empty() && lower.contains(&s.name.to_lowercase()))
        .collect();
    if hits.len() == 1 {
        return Some(hits.remove(0).clone());
    }
    hits = sites
        .iter()
        .filter(|s| !s.alien_id.is_empty() && lower.contains(&s.alien_id.to_lowercase()))
        .collect();
    if hits.len() == 1 {
        return Some(hits.remove(0).clone());
    }
    None
}

pub async fn site_context_resolve(
    pool: &PgPool,
    caller_iid: i64,
    text: &str,
    mention_ids: &[String],
) -> Result<Option<SiteContext>> {
    for mid in mention_ids {
        if let Some(rest) = mid.strip_prefix("site:") {
            if let Ok(iid) = rest.parse::<i64>() {
                if let Some(ctx) = site_row_get(pool, caller_iid, iid).await? {
                    return Ok(Some(ctx));
                }
            }
        }
        if let Some(ctx) = site_find_by_alien_id(pool, caller_iid, mid).await? {
            return Ok(Some(ctx));
        }
    }
    for token in site_at_tokens(text) {
        if let Some(ctx) = site_find_by_alien_id(pool, caller_iid, &token).await? {
            return Ok(Some(ctx));
        }
    }
    let sites = site_list_granted(pool, caller_iid).await?;
    if let Some(ctx) = site_match_by_name(text, &sites) {
        return Ok(Some(ctx));
    }
    if sites.len() == 1 {
        return Ok(Some(sites[0].clone()));
    }
    Ok(None)
}

pub async fn site_grant_owner(pool: &PgPool, caller_iid: i64, site_iid: i64) -> Result<i64> {
    let ctx = site_row_get(pool, caller_iid, site_iid)
        .await?
        .ok_or_else(|| anyhow!("site not found or forbidden"))?;
    let row = sqlx::query_scalar::<_, i64>(
        "SELECT owner_iid FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(ctx.site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    Ok(row)
}
