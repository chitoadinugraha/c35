//! Mail access — partner / root / mailbox member.

use serde_json::Value;
use sqlx::{PgPool, Row};

fn meta_is_root(meta: &Value) -> bool {
    meta.get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
}

fn meta_has_partner(meta: &Value) -> bool {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().any(|x| x.as_str() == Some("partner")))
        .unwrap_or(false)
}

pub async fn mail_access(pool: &PgPool, viewer_iid: i64) -> Result<bool, String> {
    if viewer_iid <= 0 {
        return Ok(false);
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    if let Some(row) = row {
        let meta: Value = row.try_get("meta").unwrap_or(Value::Null);
        if meta_is_root(&meta) || meta_has_partner(&meta) {
            return Ok(true);
        }
    }
    let count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM mail.mailbox_member WHERE member_iid = $1",
    )
    .bind(viewer_iid)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(count > 0)
}

pub async fn is_mail_admin(pool: &PgPool, viewer_iid: i64) -> Result<bool, String> {
    if viewer_iid <= 0 {
        return Ok(false);
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        return Ok(false);
    };
    let meta: Value = row.try_get("meta").unwrap_or(Value::Null);
    if meta_is_root(&meta) {
        return Ok(true);
    }
    Ok(meta
        .get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().any(|x| x.as_str() == Some("director")))
        .unwrap_or(false))
}
