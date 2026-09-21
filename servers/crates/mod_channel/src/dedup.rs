use sqlx::PgPool;
use tracing::debug;

pub async fn channel_dedup_try_mark(
    pool: &PgPool,
    bot_iid: i64,
    channel_id: &str,
    external_msg_id: &str,
) -> bool {
    if bot_iid <= 0 || channel_id.is_empty() || external_msg_id.trim().is_empty() {
        return true;
    }
    let result = sqlx::query_scalar::<_, bool>(
        r#"
        INSERT INTO ai.channel_msg_dedup (bot_iid, channel_id, external_msg_id)
        VALUES ($1, $2, $3)
        ON CONFLICT (bot_iid, channel_id, external_msg_id) DO NOTHING
        RETURNING true
        "#,
    )
    .bind(bot_iid)
    .bind(channel_id)
    .bind(external_msg_id.trim())
    .fetch_optional(pool)
    .await;
    match result {
        Ok(opt) => {
            let inserted = opt.is_some();
            if !inserted {
                debug!(
                    "[c35:channel] duplicate inbound skipped bot_iid={} channel_id={} msg_id={}",
                    bot_iid,
                    channel_id,
                    external_msg_id
                );
            }
            inserted
        }
        Err(e) => {
            debug!("[c35:channel] dedup unavailable (process anyway): {e:#}");
            true
        }
    }
}

pub async fn channel_inbound_msg_put(
    pool: &PgPool,
    bot_iid: i64,
    channel_id: &str,
    external_msg_id: &str,
    chat_id: i64,
    chat_msg_id: i64,
    text: &str,
) {
    if bot_iid <= 0 || channel_id.is_empty() || external_msg_id.trim().is_empty() || chat_id <= 0 {
        return;
    }
    let preview: String = text.chars().take(500).collect();
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.channel_inbound_msg (bot_iid, channel_id, external_msg_id, chat_id, chat_msg_id, text_preview)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (bot_iid, channel_id, external_msg_id) DO UPDATE
        SET chat_id = EXCLUDED.chat_id, chat_msg_id = EXCLUDED.chat_msg_id,
            text_preview = EXCLUDED.text_preview, processed_at = NOW()
        "#,
    )
    .bind(bot_iid)
    .bind(channel_id)
    .bind(external_msg_id.trim())
    .bind(chat_id)
    .bind(if chat_msg_id > 0 { Some(chat_msg_id) } else { None })
    .bind(&preview)
    .execute(pool)
    .await;
}
