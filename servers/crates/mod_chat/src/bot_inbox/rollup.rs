use anyhow::Result;
use blake3;
use chrono::{DateTime, NaiveDate, Utc};
use sqlx::{PgPool, Row};
use tracing::warn;

pub fn bot_inbox_content_normalize(content: &str) -> String {
    let mut s = content.trim().to_string();
    if s.is_empty() {
        return s;
    }
    while let Some(start) = s.find("[@") {
        if let Some(end) = s[start..].find(']') {
            s.replace_range(start..start + end + 1, " ");
        } else {
            break;
        }
    }
    s = s.split_whitespace().collect::<Vec<_>>().join(" ");
    s.to_lowercase()
}

pub fn bot_inbox_content_fingerprint(normalized: &str) -> String {
    blake3::hash(normalized.as_bytes()).to_hex().to_string()
}

pub async fn bot_inbox_user_msg_record(
    pool: &PgPool,
    chat_id: i64,
    content: &str,
    at: DateTime<Utc>,
) -> Result<()> {
    let row = sqlx::query(
        r#"
        SELECT kind, bot_iid, channel_id
        FROM ai.chat
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(());
    };
    let kind: String = row.get("kind");
    if kind != "bot_peer" {
        return Ok(());
    }
    let bot_iid: i64 = row.get("bot_iid");
    let channel_id: String = row.get("channel_id");
    if bot_iid <= 0 {
        return Ok(());
    }
    let day = at.date_naive();
    if let Err(e) = bot_inbox_day_bump(pool, bot_iid, day, &channel_id, chat_id).await {
        warn!("bot_inbox_day_bump chat_id={chat_id}: {e}");
    }
    let normalized = bot_inbox_content_normalize(content);
    if normalized.len() < 2 {
        return Ok(());
    }
    let fingerprint = bot_inbox_content_fingerprint(&normalized);
    let sample = content.trim().chars().take(500).collect::<String>();
    if let Err(e) =
        bot_inbox_question_bump(pool, bot_iid, day, &channel_id, &fingerprint, &sample).await
    {
        warn!("bot_inbox_question_bump chat_id={chat_id}: {e}");
    }
    Ok(())
}

async fn bot_inbox_day_bump(
    pool: &PgPool,
    bot_iid: i64,
    day: NaiveDate,
    channel_id: &str,
    chat_id: i64,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.bot_inbox_day (bot_iid, day, channel_id, user_msg_count, active_chat_count, updated_ts)
        VALUES ($1, $2, $3, 1, 0, NOW())
        ON CONFLICT (bot_iid, day, channel_id) DO UPDATE
        SET user_msg_count = ai.bot_inbox_day.user_msg_count + 1,
            updated_ts = NOW()
        "#,
    )
    .bind(bot_iid)
    .bind(day)
    .bind(channel_id)
    .execute(pool)
    .await?;

    let inserted = sqlx::query_scalar::<_, bool>(
        r#"
        INSERT INTO ai.bot_inbox_chat_touch (bot_iid, day, channel_id, chat_id, created_ts)
        VALUES ($1, $2, $3, $4, NOW())
        ON CONFLICT (bot_iid, day, channel_id, chat_id) DO NOTHING
        RETURNING TRUE
        "#,
    )
    .bind(bot_iid)
    .bind(day)
    .bind(channel_id)
    .bind(chat_id)
    .fetch_optional(pool)
    .await?
    .unwrap_or(false);

    if inserted {
        sqlx::query(
            r#"
            UPDATE ai.bot_inbox_day
            SET active_chat_count = active_chat_count + 1, updated_ts = NOW()
            WHERE bot_iid = $1 AND day = $2 AND channel_id = $3
            "#,
        )
        .bind(bot_iid)
        .bind(day)
        .bind(channel_id)
        .execute(pool)
        .await?;
    }
    Ok(())
}

async fn bot_inbox_question_bump(
    pool: &PgPool,
    bot_iid: i64,
    day: NaiveDate,
    channel_id: &str,
    fingerprint: &str,
    sample_text: &str,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.bot_inbox_question (bot_iid, day, channel_id, fingerprint, sample_text, count, updated_ts)
        VALUES ($1, $2, $3, $4, $5, 1, NOW())
        ON CONFLICT (bot_iid, day, channel_id, fingerprint) DO UPDATE
        SET count = ai.bot_inbox_question.count + 1,
            sample_text = CASE
                WHEN length(EXCLUDED.sample_text) > length(ai.bot_inbox_question.sample_text)
                THEN EXCLUDED.sample_text
                ELSE ai.bot_inbox_question.sample_text
            END,
            updated_ts = NOW()
        "#,
    )
    .bind(bot_iid)
    .bind(day)
    .bind(channel_id)
    .bind(fingerprint)
    .bind(sample_text)
    .execute(pool)
    .await?;
    Ok(())
}
