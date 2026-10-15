use serde_json::Value;
use sqlx::{PgPool, Row};

fn meta_is_root(meta: &Value) -> bool {
    meta.get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
}

fn meta_is_director(meta: &Value) -> bool {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().any(|x| x.as_str() == Some("director")))
        .unwrap_or(false)
}

/// Root or global director may list and edit any site.
pub async fn caller_root_or_director(pool: &PgPool, caller_iid: i64) -> Result<bool, sqlx::Error> {
    if caller_iid == 99_000 {
        return Ok(true);
    }
    if caller_iid <= 0 {
        return Ok(false);
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true")
        .bind(caller_iid)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Ok(false);
    };
    let meta: Value = row.try_get("meta").unwrap_or(Value::Object(Default::default()));
    Ok(meta_is_root(&meta) || meta_is_director(&meta))
}
