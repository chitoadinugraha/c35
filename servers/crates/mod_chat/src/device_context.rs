use anyhow::{anyhow, bail, Result};
use c35_proto::{
    Chat, ChatKind, ChatMember, ReqChatDeviceContextCreate, ReqChatDeviceContextList, ReqPrompt,
    ResChatDeviceContextCreate, ResChatDeviceContextList,
};
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};
use tracing::warn;

use crate::inbox::ts_ms;
use crate::mention_registry::{mention_ref_iid, mention_ref_parse, MentionRef};

pub fn chat_bound_device_iid(meta: &Value) -> i64 {
    meta.get("bound_device_iid")
        .and_then(|v| {
            v.as_i64()
                .or_else(|| v.as_str().and_then(|s| s.parse().ok()))
        })
        .filter(|i| *i > 0)
        .unwrap_or(0)
}

async fn device_caller_may_access(pool: &PgPool, caller_iid: i64, device_iid: i64) -> Result<()> {
    if device_iid <= 0 {
        bail!("invalid device");
    }
    let ok = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT i.id
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1
          AND i.kind = 'remote'
          AND i.deleted_ts IS NULL
          AND (i.owner_iid = $2 OR g.grantee_iid = $2)
        LIMIT 1
        "#,
    )
    .bind(device_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?;
    if ok.is_some() {
        Ok(())
    } else {
        bail!("device not found or forbidden");
    }
}

async fn device_display_name(pool: &PgPool, device_iid: i64) -> Result<String> {
    let name: Option<String> = sqlx::query_scalar(
        "SELECT name FROM ai.identity WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL",
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await?;
    name.filter(|s| !s.trim().is_empty())
        .map(|s| s.trim().to_string())
        .ok_or_else(|| anyhow!("device not found"))
}

async fn bound_context_count(pool: &PgPool, owner_iid: i64, device_iid: i64) -> Result<i64> {
    Ok(sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*)::bigint
        FROM ai.chat c
        WHERE c.kind = 'prompt'
          AND c.owner_iid = $1
          AND c.deleted_ts IS NULL
          AND c.bound_device_iid = $2
        "#,
    )
    .bind(owner_iid)
    .bind(device_iid)
    .fetch_one(pool)
    .await?)
}

fn mention_device_iids_from_req(mention_ids: &[String]) -> Vec<i64> {
    mention_ids
        .iter()
        .filter_map(|raw| match mention_ref_parse(raw) {
            Some(MentionRef::Iid(iid)) => Some(iid),
            _ => None,
        })
        .collect()
}

pub async fn chat_device_context_list(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqChatDeviceContextList,
) -> Result<ResChatDeviceContextList> {
    let device_iid = req.device_iid;
    device_caller_may_access(pool, owner_iid, device_iid).await?;
    let limit = if req.limit <= 0 {
        20
    } else {
        req.limit.min(50)
    };
    let archived_clause = if req.include_archived {
        ""
    } else {
        "AND m.archived_ts IS NULL"
    };
    let sql = format!(
        r#"
        SELECT c.id, c.kind, c.owner_iid, c.title, c.model, c.last_msg_ts, c.last_msg_preview, c.meta,
               c.context_window, c.created_ts, c.updated_ts, c.deleted_ts,
               m.last_read_msg_id, m.unread_count, m.last_msg_ts AS member_last_msg_ts,
               m.last_msg_preview AS member_preview,
               m.pinned_ts, m.archived_ts, m.created_ts AS member_created_ts, m.updated_ts AS member_updated_ts,
               m.deleted_ts AS member_deleted_ts,
               COALESCE(m.last_msg_status, 'done') AS last_msg_status
        FROM ai.chat c
        JOIN ai.chat_member m ON m.chat_id = c.id AND m.member_iid = $1 AND m.deleted_ts IS NULL
        WHERE c.kind = 'prompt'
          AND c.owner_iid = $1
          AND c.deleted_ts IS NULL
          AND c.bound_device_iid = $2
          {archived_clause}
        ORDER BY c.last_msg_ts DESC
        LIMIT $3
        "#,
        archived_clause = archived_clause
    );
    let rows = sqlx::query(&sql)
        .bind(owner_iid)
        .bind(device_iid)
        .bind(limit)
        .fetch_all(pool)
        .await?;
    let mut chats = Vec::with_capacity(rows.len());
    let mut members = Vec::with_capacity(rows.len());
    for r in rows {
        let chat_id: i64 = r.get("id");
        let preview: String = r
            .get::<Option<String>, _>("member_preview")
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| r.get("last_msg_preview"));
        let last_at = r
            .get::<Option<chrono::DateTime<chrono::Utc>>, _>("member_last_msg_ts")
            .or_else(|| r.get("last_msg_ts"));
        let meta: Value = r.get("meta");
        chats.push(Chat {
            id: chat_id,
            kind: ChatKind::Prompt as i32,
            owner_iid: r.get("owner_iid"),
            title: r.get("title"),
            model: r.get("model"),
            last_msg_ts_ms: ts_ms(last_at),
            last_msg_preview: preview.clone(),
            meta_json: meta.to_string(),
            context_window: r.get("context_window"),
            created_ts_ms: ts_ms(r.get("created_ts")),
            updated_ts_ms: ts_ms(r.get("updated_ts")),
            deleted_ts_ms: ts_ms(r.get("deleted_ts")),
            ..Default::default()
        });
        members.push(ChatMember {
            chat_id,
            member_iid: owner_iid,
            last_read_msg_id: r.get::<Option<i64>, _>("last_read_msg_id").unwrap_or(0),
            unread_count: r.get("unread_count"),
            last_msg_ts_ms: ts_ms(last_at),
            last_msg_preview: preview,
            pinned_ts_ms: ts_ms(r.get("pinned_ts")),
            archived_ts_ms: ts_ms(r.get("archived_ts")),
            created_ts_ms: ts_ms(r.get("member_created_ts")),
            updated_ts_ms: ts_ms(r.get("member_updated_ts")),
            deleted_ts_ms: ts_ms(r.get("member_deleted_ts")),
            last_msg_status: r.get::<String, _>("last_msg_status"),
        });
    }
    Ok(ResChatDeviceContextList { chats, members })
}

pub async fn chat_device_context_create(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqChatDeviceContextCreate,
) -> Result<ResChatDeviceContextCreate> {
    let device_iid = req.device_iid;
    device_caller_may_access(pool, owner_iid, device_iid).await?;
    let device_name = device_display_name(pool, device_iid).await?;
    let title = req.title.trim();
    let title = if title.is_empty() {
        let n = bound_context_count(pool, owner_iid, device_iid).await?;
        if n == 0 {
            device_name
        } else {
            format!("{} (#{})", device_name, n + 1)
        }
    } else {
        title.to_string()
    };
    let meta = json!({
        "bound_device_iid": device_iid,
        "bound_device_kind": "remote",
    });
    let meta_json = meta.to_string();
    let id = snowflake_id();
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat (id, kind, owner_iid, title, model, meta, bound_device_iid, created_ts, updated_ts)
        VALUES ($1, 'prompt', $2, $3, 'cloud', $4, $5, NOW(), NOW())
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(&title)
    .bind(meta)
    .bind(device_iid)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat_member (chat_id, member_iid, last_msg_preview, created_ts, updated_ts)
        VALUES ($1, $2, '', NOW(), NOW())
        ON CONFLICT (chat_id, member_iid) DO NOTHING
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    let chat = Chat {
        id,
        kind: ChatKind::Prompt as i32,
        owner_iid,
        title,
        model: "cloud".into(),
        meta_json,
        ..Default::default()
    };
    let member = ChatMember {
        chat_id: id,
        member_iid: owner_iid,
        ..Default::default()
    };
    Ok(ResChatDeviceContextCreate {
        chat: Some(chat),
        member: Some(member),
    })
}

/// Persist sticky composer mentions on the chat and bind a single device when unbound.
pub async fn chat_mention_context_commit(
    pool: &PgPool,
    chat_id: i64,
    owner_iid: i64,
    mention_ids: &[String],
) -> Result<()> {
    if mention_ids.is_empty() {
        return Ok(());
    }
    let meta_row: Option<Value> = sqlx::query_scalar(
        "SELECT COALESCE(meta, '{}'::jsonb) FROM ai.chat WHERE id = $1 AND owner_iid = $2 AND kind = 'prompt' AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    let Some(mut meta) = meta_row else {
        return Ok(());
    };
    let mut sticky: Vec<String> = meta
        .get("sticky_mention_ids")
        .and_then(|v| serde_json::from_value(v.clone()).ok())
        .unwrap_or_default();
    for id in mention_ids {
        let t = id.trim();
        if t.is_empty() || sticky.iter().any(|x| x == t) {
            continue;
        }
        sticky.push(t.to_string());
    }
    meta["sticky_mention_ids"] = json!(sticky);
    let devices = mention_device_iids_from_req(mention_ids);
    if devices.len() == 1 {
        let device = devices[0];
        sqlx::query(
            r#"
            UPDATE ai.chat
            SET bound_device_iid = $1,
                meta = $2,
                updated_ts = NOW()
            WHERE id = $3 AND owner_iid = $4 AND kind = 'prompt'
              AND (bound_device_iid = 0 OR bound_device_iid = $1)
            "#,
        )
        .bind(device)
        .bind(&meta)
        .bind(chat_id)
        .bind(owner_iid)
        .execute(pool)
        .await?;
    } else {
        sqlx::query(
            "UPDATE ai.chat SET meta = $1, updated_ts = NOW() WHERE id = $2 AND owner_iid = $3 AND kind = 'prompt'",
        )
        .bind(&meta)
        .bind(chat_id)
        .bind(owner_iid)
        .execute(pool)
        .await?;
    }
    Ok(())
}

/// When the user has exactly one paired remote device, inject it like a bound chat (no @mention needed).
pub async fn prompt_single_paired_device_inject(
    pool: &PgPool,
    owner_iid: i64,
    req: &mut ReqPrompt,
) -> Result<()> {
    if !mention_device_iids_from_req(&req.mention_ids).is_empty()
        || req.device_iids.iter().any(|i| *i > 0)
    {
        return Ok(());
    }
    let ids: Vec<i64> = sqlx::query_scalar(
        r#"
        SELECT id
        FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'remote' AND deleted_ts IS NULL
        ORDER BY id
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await?;
    if ids.len() != 1 {
        return Ok(());
    }
    let device = ids[0];
    req.mention_ids.push(mention_ref_iid(device));
    req.device_iids.push(device);
    Ok(())
}

pub async fn bound_device_prompt_prepare(
    pool: &PgPool,
    owner_iid: i64,
    chat_id: i64,
    req: &mut ReqPrompt,
) -> Result<()> {
    let row = sqlx::query_as::<_, (i64, i64, Value)>(
        "SELECT owner_iid, bound_device_iid, meta FROM ai.chat WHERE id = $1 AND kind = 'prompt' AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let Some((chat_owner, bound_col, meta)) = row else {
        bail!("chat not found");
    };
    if chat_owner != owner_iid {
        bail!("chat not found");
    }
    let bound = if bound_col > 0 {
        bound_col
    } else {
        chat_bound_device_iid(&meta)
    };
    if bound <= 0 {
        return prompt_single_paired_device_inject(pool, owner_iid, req).await;
    }
    let mentioned = mention_device_iids_from_req(&req.mention_ids);
    for other in &mentioned {
        if *other != bound {
            bail!("chat is bound to a different device");
        }
    }
    for other in &req.device_iids {
        if *other != 0 && *other != bound {
            bail!("chat is bound to a different device");
        }
    }
    let has_mention = mentioned.iter().any(|i| *i == bound);
    if !has_mention {
        warn!(
            owner_iid,
            chat_id,
            bound_device_iid = bound,
            "injecting missing device mention for bound prompt chat"
        );
        req.mention_ids.push(mention_ref_iid(bound));
    }
    if !req.device_iids.iter().any(|i| *i == bound) {
        req.device_iids.push(bound);
    }
    Ok(())
}

/// Desktop-only remote tools (shell, vision, computer_use, host fs) — not on `type=browser` agents.
pub const BROWSER_DEVICE_TOOL_EXCLUDE: &[&str] = &[
    "shell.run",
    "device.screenshot",
    "device.input",
    "computer_use.delegate",
    "device.fs.list",
    "device.fs.read",
];

/// When every device in scope is `type=browser`, exclude desktop remote tools from compose.
pub async fn tool_exclude_browser_devices(
    pool: &PgPool,
    owner_iid: i64,
    mention_device_iids: &[i64],
    bound_device_iid: i64,
) -> Vec<String> {
    let mut ids: Vec<i64> = mention_device_iids
        .iter()
        .copied()
        .filter(|i| *i > 0)
        .collect();
    if bound_device_iid > 0 && !ids.contains(&bound_device_iid) {
        ids.push(bound_device_iid);
    }
    ids.sort_unstable();
    ids.dedup();
    if ids.is_empty() {
        return Vec::new();
    }
    let rows = sqlx::query_as::<_, (String, Value)>(
        r#"
        SELECT type, COALESCE(meta, '{}'::jsonb)
        FROM ai.identity
        WHERE id = ANY($1::bigint[])
          AND owner_iid = $2
          AND kind = 'remote'
          AND deleted_ts IS NULL
        "#,
    )
    .bind(&ids)
    .bind(owner_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    if rows.is_empty() || rows.len() != ids.len() {
        return Vec::new();
    }
    if rows.iter().all(|(t, _)| t.eq_ignore_ascii_case("browser")) {
        let mut out: Vec<String> = BROWSER_DEVICE_TOOL_EXCLUDE
            .iter()
            .map(|s| s.to_string())
            .collect();
        if rows
            .iter()
            .all(|(_, m)| c35_mod_device::meta_browser_engine(m).eq_ignore_ascii_case("extension"))
        {
            out.push("browser.task.run".to_string());
            out.push("browser.file.upload".to_string());
        }
        return out;
    }
    Vec::new()
}

pub async fn chat_bound_device_iid_for_owner(pool: &PgPool, owner_iid: i64, chat_id: i64) -> i64 {
    let row: Option<(i64, Value)> = sqlx::query_as(
        r#"
        SELECT owner_iid, COALESCE(meta, '{}'::jsonb)
        FROM ai.chat
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await
    .unwrap_or(None);
    match row {
        Some((oid, meta)) if oid == owner_iid => chat_bound_device_iid(&meta),
        _ => 0,
    }
}
