use chrono::Utc;
use serde_json::{json, Value};
use sqlx::PgPool;

pub struct AgentVersionReport {
    pub build: i64,
    pub version_name: String,
}

pub async fn agent_presence_put(
    pool: &PgPool,
    device_iid: i64,
    online: bool,
    version: Option<AgentVersionReport>,
) -> Result<(), String> {
    let now = Utc::now().timestamp_millis();
    let patch = if online {
        let (build, version_name, label) = match version {
            Some(v) if v.build > 0 => {
                let label = if v.version_name.is_empty() {
                    format!("v{}", v.build)
                } else {
                    format!("{} (v{})", v.version_name, v.build)
                };
                (v.build, v.version_name, label)
            }
            _ => (0_i64, String::new(), "unknown".to_string()),
        };
        json!({
            "online": true,
            "last_seen_ts_ms": now,
            "agent_build": build,
            "agent_version_name": version_name,
            "agent_version": label,
        })
    } else {
        json!({
            "online": false,
            "last_seen_ts_ms": now,
        })
    };
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
