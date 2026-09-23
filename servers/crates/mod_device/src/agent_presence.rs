use chrono::Utc;
use serde_json::{json, Value};
use sqlx::PgPool;

pub async fn agent_presence_put(
    pool: &PgPool,
    device_iid: i64,
    online: bool,
    agent_version: Option<&str>,
) -> Result<(), String> {
    let now = Utc::now().timestamp_millis();
    let patch = json!({
        "online": online,
        "last_seen_ts_ms": now,
        "agent_version": agent_version,
    });
    sqlx::query(
        r#"
        UPDATE ai.identity
        SET meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb,
            updated_ts = NOW()
        WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .bind(patch)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn agent_meta_get(pool: &PgPool, device_iid: i64) -> Result<Value, String> {
    let row = sqlx::query_scalar::<_, Value>(
        r#"SELECT COALESCE(meta, '{}'::jsonb) FROM ai.identity WHERE id = $1"#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.unwrap_or_else(|| json!({})))
}
