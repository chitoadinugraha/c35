use anyhow::Result;
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

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
    Ok(())
}

fn peer_pic_from_hash(hash: &str) -> String {
    if hash.trim().is_empty() {
        String::new()
    } else {
        format!("/fs/{}", hash.trim())
    }
}

pub async fn bot_peer_chat_resolve(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    inbound: &ChannelInboundMessage,
) -> Result<i64> {
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
        let _ = sqlx::query(
            r#"
            UPDATE ai.chat
            SET peer_name = $2, last_msg_ts = NOW(), updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(chat_id)
        .bind(&inbound.display_name)
        .execute(pool)
        .await;
        return Ok(chat_id);
    }

    let chat_id = snowflake_id();
    let preview: String = inbound.text.chars().take(255).collect();
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
    Ok(chat_id)
}

pub async fn chat_msg_external_put(
    pool: &PgPool,
    chat_id: i64,
    owner_iid: i64,
    peer_iid: i64,
    req_id: &str,
    content: &str,
) -> Result<i64> {
    let msg_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source, content, status, created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $5, 'user', 'external', $6, 'done', NOW(), NOW())
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(peer_iid)
    .bind(content)
    .execute(pool)
    .await?;
    let preview: String = content.chars().take(255).collect();
    sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(preview)
    .execute(pool)
    .await?;
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
    let msg_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source, content, status, created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $5, 'assistant', 'prompt', $6, 'done', NOW(), NOW())
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(bot_iid)
    .bind(content)
    .execute(pool)
    .await?;
    let preview: String = content.chars().take(255).collect();
    sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(preview)
    .execute(pool)
    .await?;
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
