use anyhow::{anyhow, Result};
use async_nats::Client as NatsClient;
use c35_mod_log::{log_put, LogPut};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};
use tracing::{debug, info};

pub const PROVIDER_LINKED: &str = "linked_device";
/// Legacy provider slug before c35 aligned with identity.md
pub const PROVIDER_LEGACY: &str = "channel-whatsapp-device";
pub const LOG_DV: &str = "channel-wa-device";

pub fn truncate_log_text(s: &str) -> String {
    const MAX: usize = 120;
    if s.chars().count() <= MAX {
        return s.to_string();
    }
    format!("{}…", s.chars().take(MAX).collect::<String>())
}

#[derive(Debug, Clone)]
pub struct ChannelRow {
    pub bot_iid: i64,
    pub channel_id: String,
    pub owner_iid: i64,
    pub status: String,
    pub phone_jid: String,
    pub qr_raw: String,
    pub error_message: String,
}

fn channels_array(meta: &Value) -> Vec<Value> {
    meta.get("channels")
        .and_then(|v| v.as_array())
        .map(|a| a.to_vec())
        .unwrap_or_default()
}

fn channel_matches_device(ch: &Value) -> bool {
    if ch.get("platform").and_then(|v| v.as_str()) != Some("whatsapp") {
        return false;
    }
    matches!(
        ch.get("provider").and_then(|v| v.as_str()),
        Some(PROVIDER_LINKED) | Some(PROVIDER_LEGACY)
    )
}

fn session_field(ch: &Value, key: &str) -> String {
    ch.get("session")
        .and_then(|s| s.get(key))
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string()
}

fn row_from_parts(bot_iid: i64, owner_iid: i64, ch: &Value) -> Option<ChannelRow> {
    if !channel_matches_device(ch) {
        return None;
    }
    let channel_id = ch.get("id").and_then(|v| v.as_str()).unwrap_or_default();
    if channel_id.is_empty() {
        return None;
    }
    Some(ChannelRow {
        bot_iid,
        channel_id: channel_id.to_string(),
        owner_iid,
        status: ch.get("status").and_then(|v| v.as_str()).unwrap_or_default().to_string(),
        phone_jid: session_field(ch, "phone_jid"),
        qr_raw: session_field(ch, "qr_raw"),
        error_message: session_field(ch, "error_message"),
    })
}

async fn bot_meta_get(pool: &PgPool, bot_iid: i64) -> Result<Value> {
    let row = sqlx::query("SELECT meta, owner_iid FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await?;
    row.map(|r| r.get("meta")).ok_or_else(|| anyhow!("bot not found"))
}

async fn bot_meta_put(pool: &PgPool, bot_iid: i64, meta: Value) -> Result<()> {
    sqlx::query("UPDATE ai.identity SET meta = $2, updated_ts = NOW() WHERE id = $1")
        .bind(bot_iid)
        .bind(meta)
        .execute(pool)
        .await?;
    Ok(())
}

async fn update_channel(
    pool: &PgPool,
    bot_iid: i64,
    channel_id: &str,
    mutator: impl FnOnce(&mut Value),
) -> Result<()> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Err(anyhow!("bot not found"));
    };
    let mut meta: Value = row.get("meta");
    let mut channels = channels_array(&meta);
    let idx = channels
        .iter()
        .position(|ch| ch.get("id").and_then(|v| v.as_str()) == Some(channel_id))
        .ok_or_else(|| anyhow!("channel not found"))?;
    mutator(&mut channels[idx]);
    let updated = channels;
    if let Some(obj) = meta.as_object_mut() {
        obj.insert("channels".into(), json!(updated));
    }
    bot_meta_put(pool, bot_iid, meta).await
}

pub async fn channel_log(
    pool: &PgPool,
    nats: Option<&NatsClient>,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    topic: &str,
    text: &str,
    meta: Value,
) -> Result<()> {
    if owner_iid <= 0 {
        return Ok(());
    }
    let log_kind = if topic == "error" { "error" } else { "system" };
    let meta = json!({
        "channel": {
            "bot_iid": bot_iid,
            "channel_id": channel_id,
            "event": topic,
        },
        "detail": meta,
    });
    let _ = log_put(
        pool,
        nats,
        LogPut {
            owner_iid,
            kind: log_kind,
            topic,
            dv: LOG_DV,
            req_id: None,
            chat_id: None,
            task_id: None,
            device_iid: None,
            text: &truncate_log_text(text),
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta,
        },
    )
    .await?;
    Ok(())
}

pub async fn list_whatsapp_active_channels(pool: &PgPool) -> Result<Vec<ChannelRow>> {
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, meta FROM ai.identity
        WHERE kind = 'bot' AND type = 'chat' AND deleted_ts IS NULL
        "#,
    )
    .fetch_all(pool)
    .await?;
    let mut out = Vec::new();
    let mut seen_owner = std::collections::HashSet::new();
    for row in rows {
        let bot_iid: i64 = row.get("id");
        let owner_iid: i64 = row.try_get("owner_iid").ok().flatten().unwrap_or(0);
        let meta: Value = row.get("meta");
        for ch in channels_array(&meta) {
            if !channel_matches_device(&ch) {
                continue;
            }
            let status = ch.get("status").and_then(|v| v.as_str()).unwrap_or_default();
            if status != "connected" {
                continue;
            }
            if seen_owner.contains(&owner_iid) {
                continue;
            }
            if let Some(r) = row_from_parts(bot_iid, owner_iid, &ch) {
                seen_owner.insert(owner_iid);
                out.push(r);
            }
        }
    }
    Ok(out)
}

pub async fn list_expired_pairing_channels(pool: &PgPool) -> Result<Vec<ChannelRow>> {
    let now_ms = chrono::Utc::now().timestamp_millis();
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, meta FROM ai.identity
        WHERE kind = 'bot' AND type = 'chat' AND deleted_ts IS NULL
        "#,
    )
    .fetch_all(pool)
    .await?;
    let mut out = Vec::new();
    for row in rows {
        let bot_iid: i64 = row.get("id");
        let owner_iid: i64 = row.try_get("owner_iid").ok().flatten().unwrap_or(0);
        let meta: Value = row.get("meta");
        for ch in channels_array(&meta) {
            if !channel_matches_device(&ch) {
                continue;
            }
            let status = ch.get("status").and_then(|v| v.as_str()).unwrap_or_default();
            if status != "pairing" {
                continue;
            }
            let until = ch
                .get("session")
                .and_then(|s| s.get("pair_watch_until_ms"))
                .and_then(|v| v.as_i64())
                .unwrap_or(0);
            if until >= now_ms {
                continue;
            }
            if let Some(r) = row_from_parts(bot_iid, owner_iid, &ch) {
                out.push(r);
            }
        }
    }
    Ok(out)
}

pub async fn channel_pair_watch_active(pool: &PgPool, bot_iid: i64, channel_id: &str) -> Result<bool> {
    let meta = bot_meta_get(pool, bot_iid).await?;
    let until = channels_array(&meta)
        .iter()
        .find(|ch| ch.get("id").and_then(|v| v.as_str()) == Some(channel_id))
        .and_then(|ch| ch.get("session"))
        .and_then(|s| s.get("pair_watch_until_ms"))
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    Ok(until > chrono::Utc::now().timestamp_millis())
}

pub async fn channel_abort_pairing(pool: &PgPool, bot_iid: i64, channel_id: &str) -> Result<()> {
    update_channel(pool, bot_iid, channel_id, |ch| {
        ch["status"] = json!("disconnected");
        ch["session"] = json!({
            "qr_raw": "",
            "error_message": "",
            "sqlite_session_b64": "",
            "phone_jid": "",
            "pair_watch_until_ms": 0
        });
    })
    .await
}

pub async fn channel_get(pool: &PgPool, bot_iid: i64, channel_id: &str) -> Result<Option<ChannelRow>> {
    let row = sqlx::query("SELECT id, owner_iid, meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let owner_iid: i64 = row.try_get("owner_iid").ok().flatten().unwrap_or(0);
    let meta: Value = row.get("meta");
    Ok(channels_array(&meta)
        .iter()
        .find(|ch| ch.get("id").and_then(|v| v.as_str()) == Some(channel_id))
        .and_then(|ch| row_from_parts(bot_iid, owner_iid, ch)))
}

pub async fn channel_get_by_id(pool: &PgPool, channel_id: &str) -> Result<Option<ChannelRow>> {
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, meta FROM ai.identity
        WHERE kind = 'bot' AND type = 'chat' AND deleted_ts IS NULL
        "#,
    )
    .fetch_all(pool)
    .await?;
    for row in rows {
        let bot_iid: i64 = row.get("id");
        let owner_iid: i64 = row.try_get("owner_iid").ok().flatten().unwrap_or(0);
        let meta: Value = row.get("meta");
        if let Some(ch) = channels_array(&meta)
            .iter()
            .find(|ch| ch.get("id").and_then(|v| v.as_str()) == Some(channel_id))
        {
            if let Some(r) = row_from_parts(bot_iid, owner_iid, ch) {
                return Ok(Some(r));
            }
        }
    }
    Ok(None)
}

pub async fn channel_update_status(pool: &PgPool, bot_iid: i64, channel_id: &str, status: &str) -> Result<()> {
    info!("[wa-device] status bot_iid={bot_iid} channel_id={channel_id} status={status}");
    update_channel(pool, bot_iid, channel_id, |ch| {
        ch["status"] = json!(status);
    })
    .await
}

pub async fn channel_patch_session(pool: &PgPool, bot_iid: i64, channel_id: &str, patch: Value) -> Result<()> {
    debug!("[wa-device] session patch bot_iid={bot_iid} channel_id={channel_id}");
    update_channel(pool, bot_iid, channel_id, |ch| {
        let session = ch
            .get("session")
            .cloned()
            .unwrap_or_else(|| json!({}));
        let mut merged = session;
        if let Some(obj) = patch.as_object() {
            if let Some(base) = merged.as_object_mut() {
                for (k, v) in obj {
                    base.insert(k.clone(), v.clone());
                }
            }
        }
        ch["session"] = merged;
    })
    .await
}

pub async fn channel_session_blob_get(pool: &PgPool, bot_iid: i64, channel_id: &str) -> Result<Option<Vec<u8>>> {
    let meta = bot_meta_get(pool, bot_iid).await?;
    let channels = channels_array(&meta);
    let b64 = channels
        .iter()
        .find(|ch| ch.get("id").and_then(|v| v.as_str()) == Some(channel_id))
        .and_then(|ch| ch.get("session"))
        .and_then(|s| s.get("sqlite_session_b64"))
        .and_then(|v| v.as_str());
    match b64 {
        Some(s) if !s.is_empty() => {
            let bytes = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, s)?;
            if bytes.len() < 8192 {
                return Ok(None);
            }
            Ok(Some(bytes))
        }
        _ => Ok(None),
    }
}

pub async fn channel_session_blob_put(pool: &PgPool, bot_iid: i64, channel_id: &str, data: &[u8]) -> Result<()> {
    let b64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, data);
    channel_patch_session(
        pool,
        bot_iid,
        channel_id,
        json!({ "sqlite_session_b64": b64 }),
    )
    .await
}

pub async fn channel_session_blob_clear(pool: &PgPool, bot_iid: i64, channel_id: &str) -> Result<()> {
    channel_patch_session(
        pool,
        bot_iid,
        channel_id,
        json!({
            "sqlite_session_b64": "",
            "error_message": "",
            "qr_raw": "",
            "phone_jid": ""
        }),
    )
    .await
}
