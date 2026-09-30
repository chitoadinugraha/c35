use anyhow::Result;
use c35_mod_chat::bot_inbox::bot_inbox_user_msg_record;
use c35_mod_log::{log_put, LogPut};
use c35_store::snowflake_id;
use chrono::Utc;
use sqlx::{PgPool, Row};

use crate::policy::AUTO_BLOCK_OOS_THRESHOLD;
use crate::types::ChannelInboundMessage;

pub async fn peer_iid_resolve(pool: &PgPool, inbound: &ChannelInboundMessage) -> Result<i64> {
    if let Some(row) = sqlx::query(
        r#"
        SELECT id FROM ai.identity
        WHERE kind = 'user' AND type = 'external'
          AND meta->>'platform' = $1 AND meta->>'external_id' = $2 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(&inbound.platform)
    .bind(&inbound.external_user_id)
    .fetch_optional(pool)
    .await? {
        let id: i64 = row.get("id");
        peer_profile_refresh(pool, id, inbound).await?;
        return Ok(id);
    }

    let id = snowflake_id();
    let meta = serde_json::json!({
        "platform": inbound.platform,
        "external_id": inbound.external_user_id,
        "platform_user_id": inbound.platform_user_id,
    });
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, pic, meta, created_ts, updated_ts)
        VALUES ($1, 'user', 'external', $2, NULLIF($3, ''), $4, NOW(), NOW())
        "#,
    )
    .bind(id)
    .bind(&inbound.display_name)
    .bind(peer_pic_from_hash(&inbound.avatar_hash))
    .bind(meta)
    .execute(pool)
    .await?;
    Ok(id)
}

async fn peer_profile_refresh(pool: &PgPool, peer_iid: i64, inbound: &ChannelInboundMessage) -> Result<()> {
    if !inbound.display_name.trim().is_empty() {
        let _ = sqlx::query(
            "UPDATE ai.identity SET name = $2, updated_ts = NOW() WHERE id = $1 AND name IS DISTINCT FROM $2",
        )
        .bind(peer_iid)
        .bind(inbound.display_name.trim())
        .execute(pool)
        .await;
    }
    let pic = peer_pic_from_hash(&inbound.avatar_hash);
    if !pic.is_empty() {
        let _ = sqlx::query(
            "UPDATE ai.identity SET pic = $2, updated_ts = NOW() WHERE id = $1 AND (pic IS NULL OR pic = '' OR pic IS DISTINCT FROM $2)",
        )
        .bind(peer_iid)
        .bind(&pic)
        .execute(pool)
        .await;
    }
    Ok(())
}

fn peer_pic_from_hash(hash: &str) -> String {
    if hash.trim().is_empty() {
        String::new()
    } else {
        format!("/fs/{}", hash.trim())
    }
}

pub async fn bot_peer_chat_id_get(
    pool: &PgPool,
    bot_iid: i64,
    channel_id: &str,
    peer_key: &str,
) -> Result<Option<i64>> {
    let row = sqlx::query(
        r#"
        SELECT id FROM ai.chat
        WHERE kind = 'bot_peer' AND bot_iid = $1 AND channel_id = $2 AND peer_key = $3 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(bot_iid)
    .bind(channel_id)
    .bind(peer_key)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| r.get("id")))
}

pub async fn bot_peer_chat_resolve(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    inbound: &ChannelInboundMessage,
) -> Result<(i64, bool)> {
    if let Some(row) = sqlx::query(
        r#"
        SELECT id FROM ai.chat
        WHERE kind = 'bot_peer' AND bot_iid = $1 AND channel_id = $2 AND peer_key = $3 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(bot_iid)
    .bind(channel_id)
    .bind(&inbound.external_user_id)
    .fetch_optional(pool)
    .await? {
        let chat_id: i64 = row.get("id");
        let pic = peer_pic_from_hash(&inbound.avatar_hash);
        let _ = sqlx::query(
            r#"
            UPDATE ai.chat
            SET peer_name = $2,
                peer_pic = CASE WHEN $3 <> '' THEN $3 ELSE peer_pic END,
                last_msg_ts = NOW(),
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(chat_id)
        .bind(&inbound.display_name)
        .bind(&pic)
        .execute(pool)
        .await;
        return Ok((chat_id, false));
    }

    let chat_id = snowflake_id();
    let preview: String = if inbound.text.trim().is_empty() && !inbound.attachments.is_empty() {
        "[Photo]".to_string()
    } else {
        inbound.text.chars().take(255).collect()
    };
    sqlx::query(
        r#"
        INSERT INTO ai.chat (
            id, kind, owner_iid, title, bot_iid, channel_id, peer_key, peer_name, peer_pic,
            last_msg_preview, created_ts, updated_ts
        )
        VALUES ($1, 'bot_peer', $2, $3, $4, $5, $6, $7, NULLIF($8, ''), $9, NOW(), NOW())
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .bind(format!("{} · {}", inbound.platform, inbound.display_name))
    .bind(bot_iid)
    .bind(channel_id)
    .bind(&inbound.external_user_id)
    .bind(&inbound.display_name)
    .bind(peer_pic_from_hash(&inbound.avatar_hash))
    .bind(preview)
    .execute(pool)
    .await?;
    Ok((chat_id, true))
}

pub async fn chat_msg_external_put(
    pool: &PgPool,
    chat_id: i64,
    owner_iid: i64,
    peer_iid: i64,
    req_id: &str,
    content: &str,
    attachments: Option<&serde_json::Value>,
) -> Result<i64> {
    let msg_id = snowflake_id();
    let atts_val = attachments.cloned().unwrap_or_else(|| serde_json::json!([]));
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, status, created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $5, 'user', 'external', $6, $7, 'done', NOW(), NOW())
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(peer_iid)
    .bind(content)
    .bind(atts_val)
    .execute(&mut *tx)
    .await?;
    let preview: String = if content.trim().is_empty() {
        if attachments.and_then(|a| a.as_array()).map(|a| !a.is_empty()).unwrap_or(false) {
            "[Photo]".to_string()
        } else {
            String::new()
        }
    } else {
        content.chars().take(255).collect()
    };
    sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(preview)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    let _ = bot_inbox_user_msg_record(pool, chat_id, content, Utc::now()).await;
    Ok(msg_id)
}

pub async fn chat_msg_assistant_put(
    pool: &PgPool,
    chat_id: i64,
    owner_iid: i64,
    bot_iid: i64,
    req_id: &str,
    content: &str,
) -> Result<i64> {
    chat_msg_assistant_put_usage(pool, chat_id, owner_iid, bot_iid, req_id, content, 0, 0, 0, 0.0).await
}

pub async fn chat_msg_usage_sync_from_log(pool: &PgPool, chat_msg_id: i64, req_id: &str) -> Result<()> {
    if chat_msg_id <= 0 || req_id.trim().is_empty() {
        return Ok(());
    }
    sqlx::query(
        r#"
        WITH agg AS (
            SELECT
                COALESCE(SUM(CASE WHEN kind IN ('llm', 'tool') THEN tokens_in ELSE 0 END), 0)::int AS tin,
                COALESCE(SUM(CASE WHEN kind IN ('llm', 'tool') THEN tokens_out ELSE 0 END), 0)::int AS tout,
                COALESCE(SUM(CASE WHEN kind IN ('llm', 'tool') THEN duration_ms ELSE 0 END), 0)::int AS dur,
                COALESCE(SUM(CASE WHEN kind IN ('llm', 'tool') THEN cost_usd ELSE 0 END), 0)::float8 AS cost,
                (
                    SELECT model FROM ai.log
                    WHERE req_id = $2 AND kind = 'llm' AND model <> ''
                    ORDER BY created_ts DESC
                    LIMIT 1
                ) AS model
            FROM ai.log
            WHERE req_id = $2
        )
        UPDATE ai.chat_msg m
        SET
            tokens_in = CASE WHEN m.tokens_in = 0 AND a.tin > 0 THEN a.tin ELSE m.tokens_in END,
            tokens_out = CASE WHEN m.tokens_out = 0 AND a.tout > 0 THEN a.tout ELSE m.tokens_out END,
            duration_ms = CASE WHEN m.duration_ms = 0 AND a.dur > 0 THEN a.dur ELSE m.duration_ms END,
            cost_usd = CASE WHEN m.cost_usd = 0 AND a.cost > 0::float8 THEN a.cost ELSE m.cost_usd END,
            updated_ts = NOW()
        FROM agg a
        WHERE m.id = $1
          AND (a.tin > 0 OR a.tout > 0 OR a.dur > 0 OR a.cost > 0::float8)
        "#,
    )
    .bind(chat_msg_id)
    .bind(req_id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn chat_msg_assistant_put_usage(
    pool: &PgPool,
    chat_id: i64,
    owner_iid: i64,
    bot_iid: i64,
    req_id: &str,
    content: &str,
    tokens_in: i32,
    tokens_out: i32,
    duration_ms: i32,
    cost_usd: f64,
) -> Result<i64> {
    let msg_id = snowflake_id();
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source, content,
            tokens_in, tokens_out, duration_ms, cost_usd, status, created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $5, 'assistant', 'prompt', $6, $7, $8, $9, $10, 'done', NOW(), NOW())
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(bot_iid)
    .bind(content)
    .bind(tokens_in)
    .bind(tokens_out)
    .bind(duration_ms)
    .bind(cost_usd)
    .execute(&mut *tx)
    .await?;
    let preview: String = content.chars().take(255).collect();
    sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(preview)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(msg_id)
}

pub async fn chat_ai_reply_enabled(pool: &PgPool, chat_id: i64) -> bool {
    sqlx::query_scalar::<_, bool>(
        "SELECT ai_reply_enabled FROM ai.chat WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .unwrap_or(true)
}

pub async fn chat_strict_oos_count_get(pool: &PgPool, chat_id: i64) -> Result<u32> {
    let row = sqlx::query_scalar::<_, Option<serde_json::Value>>(
        "SELECT meta->'strict_oos_count' FROM ai.chat WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    Ok(row
        .and_then(|v| v.and_then(|n| n.as_u64()))
        .unwrap_or(0) as u32)
}

pub async fn chat_strict_oos_count_set(pool: &PgPool, chat_id: i64, count: u32) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE ai.chat
        SET meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{strict_oos_count}', to_jsonb($2::int)),
            updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(count as i32)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn chat_ai_reply_set(pool: &PgPool, chat_id: i64, enabled: bool) -> Result<()> {
    sqlx::query(
        "UPDATE ai.chat SET ai_reply_enabled = $2, updated_ts = NOW() WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .bind(enabled)
    .execute(pool)
    .await?;
    Ok(())
}

pub struct StrictOosApplyResult {
    pub count: u32,
    pub newly_blocked: bool,
}

pub async fn chat_strict_oos_apply(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    bot_iid: i64,
    chat_id: i64,
    was_oos: bool,
    auto_block: bool,
) -> Result<StrictOosApplyResult> {
    let count = if was_oos {
        chat_strict_oos_count_get(pool, chat_id).await? + 1
    } else {
        0
    };
    chat_strict_oos_count_set(pool, chat_id, count).await?;
    let newly_blocked = auto_block && was_oos && count >= AUTO_BLOCK_OOS_THRESHOLD;
    if newly_blocked {
        chat_ai_reply_set(pool, chat_id, false).await?;
        let _ = log_put(
            pool,
            nats,
            LogPut {
                class: None,
                owner_iid,
                kind: "system",
                topic: "channel",
                dv: "c35-server",
                req_id: None,
                chat_id: Some(chat_id),
                task_id: None,
                device_iid: None,
                text: "Auto-blocked peer after repeated out-of-scope messages",
                model: "",
                tokens_in: 0,
                tokens_out: 0,
                duration_ms: 0,
                cost_usd: 0.0,
                meta: serde_json::json!({
                    "channel": {
                        "bot_iid": bot_iid,
                        "chat_id": chat_id,
                        "strict_oos_count": count,
                        "event": "peer_auto_blocked",
                    }
                }),
            },
        )
        .await;
    }
    Ok(StrictOosApplyResult { count, newly_blocked })
}
