//! Guest checkout metadata inside `site.tx.tx_data_json.guest`.

use anyhow::Result;
use serde_json::json;
use sqlx::PgPool;

pub fn guest_tx_meta_merge(base: &serde_json::Value, buyer_user_iid: i64, visitor_id: &str) -> serde_json::Value {
    let mut out = if base.is_object() {
        base.clone()
    } else {
        json!({})
    };
    let guest = json!({
        "buyer_user_iid": buyer_user_iid,
        "visitor_id": visitor_id.trim(),
    });
    if let Some(obj) = out.as_object_mut() {
        obj.insert("guest".into(), guest);
    }
    out
}

pub async fn guest_tx_meta_patch(
    pool: &PgPool,
    site_iid: i64,
    tx_id: i64,
    buyer_user_iid: i64,
    visitor_id: &str,
) -> Result<()> {
    if buyer_user_iid <= 0 && visitor_id.trim().is_empty() {
        return Ok(());
    }
    let row: Option<serde_json::Value> = sqlx::query_scalar(
        r#"SELECT tx_data_json FROM site.tx WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_optional(pool)
    .await?;
    let base = row.unwrap_or_else(|| json!({}));
    let merged = guest_tx_meta_merge(&base, buyer_user_iid, visitor_id);
    sqlx::query(
        r#"UPDATE site.tx SET tx_data_json = $3::jsonb, updated_ts = NOW() WHERE site_iid = $1 AND tx_id = $2"#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .bind(merged)
    .execute(pool)
    .await?;
    Ok(())
}

pub fn guest_tx_buyer_user_iid(tx_data_json: &serde_json::Value) -> i64 {
    tx_data_json
        .get("guest")
        .and_then(|g| g.get("buyer_user_iid"))
        .and_then(|v| v.as_i64())
        .unwrap_or(0)
}

pub fn guest_tx_visitor_id(tx_data_json: &serde_json::Value) -> String {
    tx_data_json
        .get("guest")
        .and_then(|g| g.get("visitor_id"))
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}
