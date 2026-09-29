use serde_json::Value;
use sqlx::PgPool;

use crate::release_config::meta_browser_engine;

pub async fn device_browser_engine(pool: &PgPool, device_iid: i64) -> Result<String, String> {
    let meta = sqlx::query_scalar::<_, Value>(
        r#"
        SELECT COALESCE(meta, '{}'::jsonb)
        FROM ai.identity
        WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .unwrap_or(Value::Object(Default::default()));
    Ok(meta_browser_engine(&meta).to_string())
}