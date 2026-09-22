use anyhow::{anyhow, Result};
use c35_proto::BotChannelDoc;
use c35_store::snowflake_id;
use rand::Rng;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ChannelSession {
    #[serde(default)]
    pub qr_raw: String,
    #[serde(default)]
    pub phone_jid: String,
    #[serde(default)]
    pub sqlite_session_b64: String,
    #[serde(default)]
    pub pair_watch_until_ms: i64,
    #[serde(default)]
    pub error_message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelDoc {
    pub id: String,
    pub platform: String,
    #[serde(default)]
    pub provider: String,
    pub status: String,
    #[serde(default)]
    pub webhook_secret: String,
    #[serde(default)]
    pub verify_token: String,
    #[serde(default)]
    pub bot_token: String,
    #[serde(default)]
    pub bot_username: String,
    #[serde(default)]
    pub phone_number_id: String,
    #[serde(default)]
    pub access_token: String,
    #[serde(default)]
    pub phone: String,
    #[serde(default)]
    pub error_message: String,
    #[serde(default)]
    pub session: ChannelSession,
}

pub const PROVIDER_LINKED: &str = "linked_device";
pub const STATUS_PAIRING: &str = "pairing";
pub const STATUS_CONNECTED: &str = "connected";
pub const STATUS_ERROR: &str = "error";
pub const STATUS_DISCONNECTED: &str = "disconnected";

const PAIR_WATCH_INITIAL_MS: i64 = 5 * 60 * 1000;
const PAIR_WATCH_EXTEND_MS: i64 = 2 * 60 * 1000;

pub fn pair_watch_until_ms(initial: bool) -> i64 {
    chrono::Utc::now().timestamp_millis()
        + if initial {
            PAIR_WATCH_INITIAL_MS
        } else {
            PAIR_WATCH_EXTEND_MS
        }
}

pub fn channel_external_key(ch: &ChannelDoc) -> String {
    if ch.platform == "telegram" {
        let username = ch.bot_username.trim().trim_start_matches('@').to_lowercase();
        if !username.is_empty() {
            return format!("telegram:{username}");
        }
    }
    if ch.platform == "whatsapp" {
        let phone = if ch.phone.is_empty() {
            phone_jid_display(&ch.session.phone_jid)
        } else {
            ch.phone.clone()
        };
        let digits: String = phone.chars().filter(|c| c.is_ascii_digit()).collect();
        if !digits.is_empty() {
            return format!("whatsapp:{digits}");
        }
    }
    format!("{}:{}", ch.platform, ch.id)
}

pub fn phone_jid_display(jid: &str) -> String {
    let bare = jid.split('@').next().unwrap_or(jid).trim();
    if bare.is_empty() {
        return String::new();
    }
    if bare.starts_with('+') {
        bare.to_string()
    } else {
        format!("+{bare}")
    }
}

impl ChannelDoc {
    pub fn to_proto(&self) -> BotChannelDoc {
        let err = if self.error_message.is_empty() {
            self.session.error_message.clone()
        } else {
            self.error_message.clone()
        };
        let phone = if self.phone.is_empty() {
            phone_jid_display(&self.session.phone_jid)
        } else {
            self.phone.clone()
        };
        BotChannelDoc {
            id: self.id.clone(),
            platform: self.platform.clone(),
            provider: self.provider.clone(),
            status: self.status.clone(),
            bot_username: self.bot_username.clone(),
            phone,
            error_message: err,
        }
    }

    pub fn is_linked_whatsapp(&self) -> bool {
        self.platform == "whatsapp" && self.provider == PROVIDER_LINKED
    }
}

pub fn channel_secret_generate() -> String {
    let mut rng = rand::thread_rng();
    let bytes: [u8; 24] = rng.gen();
    blake3::hash(&bytes).to_hex().to_string()
}

pub fn webhook_base(public_origin: &str) -> String {
    public_origin.trim().trim_end_matches('/').to_string()
}

pub fn telegram_webhook_url(public_origin: &str, bot_iid: i64, channel_id: &str, secret: &str) -> String {
    format!(
        "{}/v1/channels/telegram/webhook/{bot_iid}/{channel_id}/{secret}",
        webhook_base(public_origin)
    )
}

pub fn whatsapp_webhook_url(public_origin: &str, bot_iid: i64, channel_id: &str) -> String {
    format!(
        "{}/v1/channels/whatsapp/webhook/{bot_iid}/{channel_id}",
        webhook_base(public_origin)
    )
}

fn channels_from_meta(meta: &Value) -> Vec<ChannelDoc> {
    meta.get("channels")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|item| serde_json::from_value(item.clone()).ok())
                .collect()
        })
        .unwrap_or_default()
}

fn channels_to_meta(channels: &[ChannelDoc]) -> Value {
    json!({ "channels": channels })
}

pub async fn bot_ensure(pool: &PgPool, owner_iid: i64, bot_iid: i64, name: &str) -> Result<i64> {
    if bot_iid > 0 {
        let ok = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS (
                SELECT 1 FROM ai.identity
                WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND type = 'chat' AND deleted_ts IS NULL
            )
            "#,
        )
        .bind(bot_iid)
        .bind(owner_iid)
        .fetch_one(pool)
        .await?;
        if ok {
            return Ok(bot_iid);
        }
        return Err(anyhow!("bot not found or not owned"));
    }
    let id = snowflake_id();
    let title = if name.trim().is_empty() { "Bot" } else { name.trim() };
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'bot', 'chat', $2, $3, '{}'::jsonb, NOW(), NOW())
        "#,
    )
    .bind(id)
    .bind(title)
    .bind(owner_iid)
    .execute(pool)
    .await?;
    Ok(id)
}

pub async fn bot_channel_list(pool: &PgPool, owner_iid: i64, bot_iid: i64) -> Result<Vec<ChannelDoc>> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
    Ok(row
        .map(|r| channels_from_meta(&r.get::<Value, _>("meta")))
        .unwrap_or_default())
}

pub async fn bot_channel_get(
    pool: &PgPool,
    bot_iid: i64,
    channel_id: &str,
) -> Result<Option<ChannelDoc>> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    Ok(channels_from_meta(&row.get::<Value, _>("meta"))
        .into_iter()
        .find(|c| c.id == channel_id))
}

pub async fn bot_channel_get_by_secret(
    pool: &PgPool,
    bot_iid: i64,
    channel_id: &str,
    secret: &str,
) -> Result<Option<ChannelDoc>> {
    let ch = bot_channel_get(pool, bot_iid, channel_id).await?;
    Ok(ch.filter(|c| c.webhook_secret == secret))
}

pub async fn bot_channel_external_taken(
    pool: &PgPool,
    bot_iid: i64,
    key: &str,
    exclude_id: &str,
) -> Result<bool> {
    if key.trim().is_empty() {
        return Ok(false);
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .fetch_optional(pool)
        .await?;
    let channels = row
        .map(|r| channels_from_meta(&r.get::<Value, _>("meta")))
        .unwrap_or_default();
    Ok(channels.iter().any(|c| {
        c.id != exclude_id
            && channel_external_key(c) == key
            && (c.status == STATUS_CONNECTED || c.status == STATUS_PAIRING)
    }))
}

pub async fn bot_channel_remove(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
) -> Result<Option<ChannelDoc>> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Err(anyhow!("bot not found"));
    };
    let mut channels = channels_from_meta(&row.get::<Value, _>("meta"));
    let removed = channels.iter().position(|c| c.id == channel_id);
    let removed = match removed {
        Some(idx) => channels.remove(idx),
        None => return Ok(None),
    };
    let meta = channels_to_meta(&channels);
    sqlx::query("UPDATE ai.identity SET meta = $2, updated_ts = NOW() WHERE id = $1")
        .bind(bot_iid)
        .bind(meta)
        .execute(pool)
        .await?;
    Ok(Some(removed))
}

pub async fn bot_channel_upsert(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel: ChannelDoc,
) -> Result<ChannelDoc> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Err(anyhow!("bot not found"));
    };
    let mut channels = channels_from_meta(&row.get::<Value, _>("meta"));
    let saved = channel.clone();
    if let Some(idx) = channels.iter().position(|c| c.id == channel.id) {
        channels[idx] = channel;
    } else {
        channels.push(channel);
    }
    let meta = channels_to_meta(&channels);
    sqlx::query("UPDATE ai.identity SET meta = $2, updated_ts = NOW() WHERE id = $1")
        .bind(bot_iid)
        .bind(meta)
        .execute(pool)
        .await?;
    Ok(saved)
}

pub async fn bot_owner_iid(pool: &PgPool, bot_iid: i64) -> Result<Option<i64>> {
    let row = sqlx::query_scalar::<_, Option<i64>>(
        "SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL",
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await?;
    Ok(row.flatten())
}

pub async fn bot_channel_find_telegram_token(pool: &PgPool, bot_token: &str) -> Result<Option<(i64, ChannelDoc)>> {
    let rows = sqlx::query(
        r#"
        SELECT id, meta FROM ai.identity
        WHERE kind = 'bot' AND type = 'chat' AND deleted_ts IS NULL
        "#,
    )
    .fetch_all(pool)
    .await?;
    for row in rows {
        let bot_iid: i64 = row.get("id");
        for ch in channels_from_meta(&row.get::<Value, _>("meta")) {
            if ch.platform == "telegram" && ch.bot_token == bot_token {
                return Ok(Some((bot_iid, ch)));
            }
        }
    }
    Ok(None)
}

pub fn new_channel_id() -> String {
    snowflake_id().to_string()
}

async fn bot_meta_get(pool: &PgPool, owner_iid: i64, bot_iid: i64) -> Result<Value> {
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
    row.map(|r| r.get("meta"))
        .ok_or_else(|| anyhow!("bot not found"))
}

async fn bot_meta_put(pool: &PgPool, bot_iid: i64, meta: Value) -> Result<()> {
    sqlx::query("UPDATE ai.identity SET meta = $2, updated_ts = NOW() WHERE id = $1")
        .bind(bot_iid)
        .bind(meta)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn bot_channel_patch_session(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    patch: Value,
) -> Result<()> {
    let mut meta = bot_meta_get(pool, owner_iid, bot_iid).await?;
    let mut channels = channels_from_meta(&meta);
    let idx = channels
        .iter()
        .position(|c| c.id == channel_id)
        .ok_or_else(|| anyhow!("channel not found"))?;
    let mut session = serde_json::to_value(&channels[idx].session).unwrap_or_else(|_| json!({}));
    if let Some(obj) = patch.as_object() {
        if let Some(base) = session.as_object_mut() {
            for (k, v) in obj {
                base.insert(k.clone(), v.clone());
            }
        }
    }
    channels[idx].session = serde_json::from_value(session).unwrap_or_default();
    let updated = channels_to_meta(&channels);
    if let Some(obj) = meta.as_object_mut() {
        if let Some(ch) = updated.get("channels") {
            obj.insert("channels".into(), ch.clone());
        }
    }
    bot_meta_put(pool, bot_iid, meta).await
}

pub async fn bot_channel_pair_watch_touch(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    initial: bool,
) -> Result<()> {
    let until = pair_watch_until_ms(initial);
    bot_channel_patch_session(
        pool,
        owner_iid,
        bot_iid,
        channel_id,
        json!({ "pair_watch_until_ms": until }),
    )
    .await?;
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL")
        .bind(bot_iid)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Ok(());
    };
    let mut channels = channels_from_meta(&row.get::<Value, _>("meta"));
    if let Some(ch) = channels.iter_mut().find(|c| c.id == channel_id) {
        ch.status = STATUS_PAIRING.into();
    }
    let meta = channels_to_meta(&channels);
    sqlx::query("UPDATE ai.identity SET meta = $2, updated_ts = NOW() WHERE id = $1")
        .bind(bot_iid)
        .bind(meta)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn channel_whatsapp_deactivate_siblings(
    pool: &PgPool,
    owner_iid: i64,
    keep_bot_iid: i64,
    keep_channel_id: &str,
) -> Result<()> {
    let rows = sqlx::query(
        r#"
        SELECT id, meta FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'bot' AND type = 'chat' AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await?;
    let mut tx = pool.begin().await?;
    for row in rows {
        let bot_iid: i64 = row.get("id");
        let mut channels = channels_from_meta(&row.get::<Value, _>("meta"));
        let mut changed = false;
        for ch in channels.iter_mut() {
            if !ch.is_linked_whatsapp() || ch.id == keep_channel_id {
                continue;
            }
            if ch.status != STATUS_PAIRING && ch.status != STATUS_CONNECTED {
                continue;
            }
            ch.status = STATUS_DISCONNECTED.into();
            ch.session = ChannelSession::default();
            ch.error_message.clear();
            changed = true;
        }
        if changed {
            let meta = channels_to_meta(&channels);
            sqlx::query("UPDATE ai.identity SET meta = $2, updated_ts = NOW() WHERE id = $1")
                .bind(bot_iid)
                .bind(meta)
                .execute(&mut *tx)
                .await?;
        }
    }
    tx.commit().await?;
    let _ = keep_bot_iid;
    Ok(())
}

pub async fn bot_linked_channel_get(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
) -> Result<Option<ChannelDoc>> {
    let _ = bot_meta_get(pool, owner_iid, bot_iid).await?;
    let ch = bot_channel_get(pool, bot_iid, channel_id).await?;
    Ok(ch.filter(|c| c.is_linked_whatsapp()))
}

pub async fn bot_channel_apply_pair_update(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    status: &str,
    qr_raw: &str,
    error_message: &str,
    phone_jid: &str,
) -> Result<Option<ChannelDoc>> {
    let mut ch = bot_channel_get(pool, bot_iid, channel_id)
        .await?
        .filter(|c| c.is_linked_whatsapp());
    let Some(ref mut doc) = ch else {
        return Ok(None);
    };
    doc.status = status.to_string();
    if !qr_raw.is_empty() {
        doc.session.qr_raw = qr_raw.to_string();
    }
    if !error_message.is_empty() {
        doc.session.error_message = error_message.to_string();
        doc.error_message = error_message.to_string();
    }
    if !phone_jid.is_empty() {
        doc.session.phone_jid = phone_jid.to_string();
        doc.phone = phone_jid_display(phone_jid);
    }
    if status == STATUS_CONNECTED || status == STATUS_DISCONNECTED || status == STATUS_ERROR {
        doc.session.pair_watch_until_ms = 0;
    }
    let saved = doc.clone();
    bot_channel_upsert(pool, owner_iid, bot_iid, saved.clone()).await?;
    Ok(Some(saved))
}
