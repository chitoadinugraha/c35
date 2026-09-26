use anyhow::Result;
use c35_store::snowflake_id;
use chrono::{DateTime, Utc};
use sqlx::PgPool;

#[derive(Debug, Clone)]
pub struct FollowupRow {
    pub id: String,
    pub req_id: String,
    pub chat_id: i64,
    pub owner_iid: i64,
    pub seq: i32,
    pub kind: String,
    pub status: String,
    pub text: String,
    pub attachments_json: String,
    pub source: String,
    pub created_ts: DateTime<Utc>,
}

pub async fn prompt_followup_active_req(pool: &PgPool, chat_id: i64) -> Result<Option<String>> {
    let row = sqlx::query_scalar::<_, String>(
        r#"
        SELECT req_id FROM ai.prompt_run
        WHERE chat_id = $1 AND status IN ('queued', 'running', 'waiting_child')
        ORDER BY created_ts DESC
        LIMIT 1
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    Ok(row)
}

pub async fn prompt_followup_dedup_exists(pool: &PgPool, key: &str) -> Result<bool> {
    let n = sqlx::query_scalar::<_, i64>(
        r#"SELECT COUNT(*) FROM ai.prompt_followup WHERE external_dedup_key = $1 AND status = 'pending'"#,
    )
    .bind(key)
    .fetch_one(pool)
    .await?;
    Ok(n > 0)
}

pub async fn prompt_followup_next_seq(pool: &PgPool, req_id: &str) -> Result<i32> {
    let n = sqlx::query_scalar::<_, Option<i32>>(
        r#"SELECT MAX(seq) FROM ai.prompt_followup WHERE req_id = $1"#,
    )
    .bind(req_id)
    .fetch_one(pool)
    .await?;
    Ok(n.unwrap_or(0) + 1)
}

pub async fn prompt_followup_pending_count(pool: &PgPool, req_id: &str, kind: &str) -> Result<i32> {
    let n = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM ai.prompt_followup
        WHERE req_id = $1 AND kind = $2 AND status = 'pending'
        "#,
    )
    .bind(req_id)
    .bind(kind)
    .fetch_one(pool)
    .await?;
    Ok(n as i32)
}

pub async fn prompt_followup_steer_used(pool: &PgPool, req_id: &str) -> Result<i32> {
    let n = sqlx::query_scalar::<_, Option<i32>>(
        r#"SELECT steer_delivered_count FROM ai.prompt_run WHERE req_id = $1"#,
    )
    .bind(req_id)
    .fetch_optional(pool)
    .await?;
    Ok(n.flatten().unwrap_or(0))
}

pub async fn prompt_followup_insert(
    pool: &PgPool,
    id: &str,
    req_id: &str,
    chat_id: i64,
    owner_iid: i64,
    seq: i32,
    kind: &str,
    text: &str,
    attachments_json: &str,
    source: &str,
    external_dedup_key: Option<&str>,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.prompt_followup (
            id, req_id, chat_id, owner_iid, seq, kind, status, text, attachments_json, source, external_dedup_key
        ) VALUES ($1, $2, $3, $4, $5, $6, 'pending', $7, $8, $9, $10)
        "#,
    )
    .bind(id)
    .bind(req_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(seq)
    .bind(kind)
    .bind(text)
    .bind(attachments_json)
    .bind(source)
    .bind(external_dedup_key)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_followup_list_pending(pool: &PgPool, req_id: &str) -> Result<Vec<FollowupRow>> {
    let rows = sqlx::query_as::<_, (String, String, i64, i64, i32, String, String, String, String, String, DateTime<Utc>)>(
        r#"
        SELECT id, req_id, chat_id, owner_iid, seq, kind, status, text, attachments_json, source, created_ts
        FROM ai.prompt_followup
        WHERE req_id = $1 AND status = 'pending'
        ORDER BY seq ASC
        "#,
    )
    .bind(req_id)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(
            |(id, req_id, chat_id, owner_iid, seq, kind, status, text, attachments_json, source, created_ts)| {
                FollowupRow {
                    id,
                    req_id,
                    chat_id,
                    owner_iid,
                    seq,
                    kind,
                    status,
                    text,
                    attachments_json,
                    source,
                    created_ts,
                }
            },
        )
        .collect())
}

pub async fn prompt_followup_meta(
    pool: &PgPool,
    id: &str,
) -> Result<Option<(i64, i64, String)>> {
    let row = sqlx::query_as::<_, (i64, i64, String)>(
        r#"SELECT chat_id, owner_iid, req_id FROM ai.prompt_followup WHERE id = $1"#,
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;
    Ok(row)
}

pub async fn prompt_followup_cancel(pool: &PgPool, owner_iid: i64, id: &str) -> Result<bool> {
    let r = sqlx::query(
        r#"
        UPDATE ai.prompt_followup SET status = 'cancelled'
        WHERE id = $1 AND owner_iid = $2 AND status = 'pending' AND kind = 'queue'
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .execute(pool)
    .await?;
    Ok(r.rows_affected() > 0)
}

pub async fn prompt_followup_cancel_all_for_req(pool: &PgPool, req_id: &str) -> Result<()> {
    sqlx::query(
        r#"UPDATE ai.prompt_followup SET status = 'cancelled' WHERE req_id = $1 AND status = 'pending'"#,
    )
    .bind(req_id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_followup_drain_steers(
    pool: &PgPool,
    req_id: &str,
    chat_id: i64,
    owner_iid: i64,
) -> Result<Vec<String>> {
    let rows = sqlx::query_as::<_, (String, String, String)>(
        r#"
        SELECT id, text, attachments_json FROM ai.prompt_followup
        WHERE req_id = $1 AND kind = 'steer' AND status = 'pending'
        ORDER BY seq ASC
        FOR UPDATE
        "#,
    )
    .bind(req_id)
    .fetch_all(pool)
    .await?;
    if rows.is_empty() {
        return Ok(vec![]);
    }
    let mut out = Vec::new();
    for (id, text, _attachments) in rows {
        let msg_id = snowflake_id();
        sqlx::query(
            r#"
            INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, $3, 'user', 'prompt', $5, '[]', NOW(), NOW())
            "#,
        )
        .bind(msg_id)
        .bind(chat_id)
        .bind(owner_iid)
        .bind(req_id)
        .bind(&text)
        .execute(pool)
        .await?;
        sqlx::query(
            r#"UPDATE ai.prompt_followup SET status = 'delivered', delivered_ts = NOW() WHERE id = $1"#,
        )
        .bind(&id)
        .execute(pool)
        .await?;
        sqlx::query(
            r#"UPDATE ai.prompt_run SET steer_delivered_count = steer_delivered_count + 1, updated_ts = NOW() WHERE req_id = $1"#,
        )
        .bind(req_id)
        .execute(pool)
        .await?;
        out.push(text);
    }
    Ok(out)
}

pub async fn prompt_followup_next_queued(pool: &PgPool, req_id: &str) -> Result<Option<FollowupRow>> {
    let row = sqlx::query_as::<_, (String, String, i64, i64, i32, String, String, String, String, String, DateTime<Utc>)>(
        r#"
        SELECT id, req_id, chat_id, owner_iid, seq, kind, status, text, attachments_json, source, created_ts
        FROM ai.prompt_followup
        WHERE req_id = $1 AND kind = 'queue' AND status = 'pending'
        ORDER BY seq ASC
        LIMIT 1
        "#,
    )
    .bind(req_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(
        |(id, req_id, chat_id, owner_iid, seq, kind, status, text, attachments_json, source, created_ts)| {
            FollowupRow {
                id,
                req_id,
                chat_id,
                owner_iid,
                seq,
                kind,
                status,
                text,
                attachments_json,
                source,
                created_ts,
            }
        },
    ))
}

pub async fn prompt_followup_mark_queue_delivered(pool: &PgPool, id: &str) -> Result<()> {
    sqlx::query(
        r#"UPDATE ai.prompt_followup SET status = 'delivered', delivered_ts = NOW() WHERE id = $1"#,
    )
    .bind(id)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn prompt_followup_pop_delivered_queue(_pool: &PgPool, _req_id: &str) -> Result<Option<(String, String)>> {
    Ok(None)
}
