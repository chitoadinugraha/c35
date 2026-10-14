use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteAssistantEnsure, ReqSiteAssistantGet, ResSiteAssistantEnsure, ResSiteAssistantGet,
    SiteAssistantChannelSummary,
};
use c35_store::snowflake_id;
use serde_json::{json, Map, Value};
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;
use crate::guest_product::guest_product_list;
use crate::guest_product_display::guest_product_price_label;

const KNOWLEDGE_BOOT_MAX_ITEMS: usize = 50;
const KNOWLEDGE_BOOT_MAX_CHARS: usize = 32_000;
pub const GUEST_PRODUCT_PROMPT_MAX_ITEMS: usize = 80;
pub const GUEST_PRODUCT_PROMPT_MAX_CHARS: usize = 28_000;
const CAP_KEY_ASSISTANT_BOT: &str = "assistant_bot_iid";

pub fn site_assistant_capabilities_merge(caps: &Value, assistant_bot_iid: i64) -> Value {
    let mut out = if caps.is_object() {
        caps.clone()
    } else {
        json!({})
    };
    if assistant_bot_iid > 0 {
        if let Some(obj) = out.as_object_mut() {
            obj.insert(CAP_KEY_ASSISTANT_BOT.into(), json!(assistant_bot_iid));
        }
    }
    out
}

pub fn site_guest_knowledge_public(meta: &Value) -> Value {
    let rows = meta
        .get("knowledge")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    let mut out: Vec<Value> = Vec::new();
    let mut chars = 0usize;
    for raw in rows {
        if out.len() >= KNOWLEDGE_BOOT_MAX_ITEMS {
            break;
        }
        let title = raw.get("title").and_then(|v| v.as_str()).unwrap_or("").trim();
        let content = raw.get("content").and_then(|v| v.as_str()).unwrap_or("").trim();
        if title.is_empty() && content.is_empty() {
            continue;
        }
        let row = json!({
            "id": raw.get("id").cloned().unwrap_or(Value::Null),
            "title": title,
            "content": content,
        });
        let add = title.len() + content.len() + 4;
        if chars + add > KNOWLEDGE_BOOT_MAX_CHARS && !out.is_empty() {
            break;
        }
        chars += add;
        out.push(row);
    }
    Value::Array(out)
}

pub fn site_guest_ai_assistant_public(meta: &Value) -> Value {
    meta.get("ai_assistant")
        .filter(|v| v.is_object() && !v.as_object().is_some_and(|o| o.is_empty()))
        .cloned()
        .unwrap_or_else(|| json!({}))
}

/// Top-level boot keys for guest renderer (`ai_assistant`, `knowledge`).
pub fn site_assistant_boot_extras(meta: &Value) -> Map<String, Value> {
    let mut m = Map::new();
    m.insert("ai_assistant".into(), site_guest_ai_assistant_public(meta));
    m.insert("knowledge".into(), site_guest_knowledge_public(meta));
    m
}

/// Sellable catalog rows for guest assistant price / description answers.
pub async fn site_guest_product_prompt_block(pool: &PgPool, site_iid: i64) -> String {
    let res = guest_product_list(
        pool,
        site_iid,
        "",
        "",
        "",
        GUEST_PRODUCT_PROMPT_MAX_ITEMS as i32,
    )
    .await;
    let rows = match res {
        Ok(r) => r.items,
        Err(_) => return String::new(),
    };
    if rows.is_empty() {
        return String::new();
    }
    let mut out = String::from(
        "[SITE PRODUCTS]\nUse these rows for prices, descriptions, and cart tools (product_id). Do not invent items.\n",
    );
    let mut chars = out.len();
    let mut count = 0usize;
    for p in rows {
        if count >= GUEST_PRODUCT_PROMPT_MAX_ITEMS {
            break;
        }
        let price = guest_product_price_label(p.price);
        let desc = p.desc.trim();
        let desc_short = if desc.len() > 160 {
            format!("{}…", desc.chars().take(160).collect::<String>())
        } else {
            desc.to_string()
        };
        let line = if desc_short.is_empty() {
            format!(
                "- product_id={} | {} | {}\n",
                p.product_id,
                p.name.trim(),
                price
            )
        } else {
            format!(
                "- product_id={} | {} | {} | {}\n",
                p.product_id,
                p.name.trim(),
                price,
                desc_short
            )
        };
        if chars + line.len() > GUEST_PRODUCT_PROMPT_MAX_CHARS && count > 0 {
            break;
        }
        out.push_str(&line);
        chars += line.len();
        count += 1;
    }
    if count == 0 {
        String::new()
    } else {
        out.trim_end().to_string()
    }
}

pub async fn site_assistant_bot_iid_get(pool: &PgPool, site_iid: i64) -> Option<i64> {
    let row = sqlx::query(
        r#"
        SELECT assistant_bot_iid, capabilities_json
        FROM site.config
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()?;
    let Some(row) = row else {
        return None;
    };
    let column: Option<i64> = row.try_get("assistant_bot_iid").ok().flatten();
    let caps: Value = row
        .try_get("capabilities_json")
        .ok()
        .unwrap_or_else(|| json!({}));
    let from_caps = caps
        .get(CAP_KEY_ASSISTANT_BOT)
        .and_then(|v| v.as_i64())
        .filter(|id| *id > 0);
    let candidate = column.filter(|id| *id > 0).or(from_caps);
    let Some(bot_iid) = candidate else {
        return None;
    };
    let valid = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM ai.identity
            WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL
        )
        "#,
    )
    .bind(bot_iid)
    .fetch_one(pool)
    .await
    .ok()
    .unwrap_or(false);
    if valid {
        Some(bot_iid)
    } else {
        None
    }
}

fn channel_summaries_from_meta(meta: &Value) -> Vec<SiteAssistantChannelSummary> {
    let channels = meta
        .get("channels")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    channels
        .iter()
        .filter_map(|ch| {
            let id = ch.get("id").and_then(|v| v.as_str()).unwrap_or("").trim();
            if id.is_empty() {
                return None;
            }
            Some(SiteAssistantChannelSummary {
                id: id.to_string(),
                platform: ch
                    .get("platform")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                provider: ch
                    .get("provider")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                status: ch
                    .get("status")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                bot_username: ch
                    .get("bot_username")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                phone: ch
                    .get("phone")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                error_message: ch
                    .get("error_message")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
            })
        })
        .collect()
}

async fn assistant_bot_channels(
    pool: &PgPool,
    bot_iid: i64,
    site_iid: i64,
) -> Result<Vec<SiteAssistantChannelSummary>> {
    let row = sqlx::query(
        r#"
        SELECT meta FROM ai.identity
        WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL
        "#,
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(vec![]);
    };
    let meta: Value = row.get("meta");
    let parent = meta
        .get("parent_site_iid")
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    if parent != site_iid {
        return Ok(vec![]);
    }
    Ok(channel_summaries_from_meta(&meta))
}

async fn site_assistant_link_bot(
    pool: &PgPool,
    site_iid: i64,
    owner_iid: i64,
    bot_iid: i64,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, assistant_bot_iid, capabilities_json, created_ts, updated_ts)
        VALUES ($1, $2, $3, jsonb_build_object($4::text, $3::bigint), NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
            assistant_bot_iid = EXCLUDED.assistant_bot_iid,
            capabilities_json = site.config.capabilities_json
                || jsonb_build_object($4::text, EXCLUDED.assistant_bot_iid),
            updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(bot_iid)
    .bind(CAP_KEY_ASSISTANT_BOT)
    .execute(pool)
    .await?;
    Ok(())
}

async fn site_assistant_create_bot(
    pool: &PgPool,
    site_iid: i64,
    owner_iid: i64,
    site_name: &str,
) -> Result<i64> {
    let label = site_name.trim();
    let name = if label.is_empty() {
        "Site AI".to_string()
    } else {
        format!("{label} AI")
    };
    let bot_iid = snowflake_id();
    let meta = json!({
        "active": false,
        "parent_site_iid": site_iid,
        "source": "site_assistant",
        "inst_base": "",
        "channels": [],
        "strict_mode": true,
        "auto_block_spammer": true,
        "web_search": false,
        "billing_plan_slug": "shared",
    });
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'bot', 'chat', $2, $3, $4, NOW(), NOW())
        "#,
    )
    .bind(bot_iid)
    .bind(&name)
    .bind(owner_iid)
    .bind(&meta)
    .execute(pool)
    .await?;
    Ok(bot_iid)
}

/// Idempotent: returns existing site assistant bot or creates one (`meta.active=false`).
pub async fn site_assistant_ensure_bot(pool: &PgPool, caller_iid: i64, site_iid: i64) -> Result<i64> {
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    if let Some(bot_iid) = site_assistant_bot_iid_get(pool, site_iid).await {
        return Ok(bot_iid);
    }
    let site_name: String = sqlx::query_scalar(
        "SELECT name FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .unwrap_or_default();
    let bot_iid = site_assistant_create_bot(pool, site_iid, owner_iid, &site_name).await?;
    site_assistant_link_bot(pool, site_iid, owner_iid, bot_iid).await?;
    let _ = c35_mod_hint::hint_invalidate_for_asset(pool, site_iid).await;
    Ok(bot_iid)
}

pub async fn site_assistant_get(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteAssistantGet,
) -> Result<ResSiteAssistantGet> {
    if req.site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let bot_iid = site_assistant_bot_iid_get(pool, req.site_iid).await.unwrap_or(0);
    let channels = if bot_iid > 0 {
        assistant_bot_channels(pool, bot_iid, req.site_iid).await?
    } else {
        vec![]
    };
    Ok(ResSiteAssistantGet {
        assistant_bot_iid: bot_iid,
        channels,
    })
}

pub async fn site_assistant_ensure(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteAssistantEnsure,
) -> Result<ResSiteAssistantEnsure> {
    let bot_iid = site_assistant_ensure_bot(pool, caller_iid, req.site_iid).await?;
    Ok(ResSiteAssistantEnsure {
        assistant_bot_iid: bot_iid,
    })
}

pub fn site_config_assistant_bot_iid_from_row(row: &sqlx::postgres::PgRow) -> i64 {
    row.try_get::<Option<i64>, _>("assistant_bot_iid")
        .ok()
        .flatten()
        .unwrap_or(0)
}
