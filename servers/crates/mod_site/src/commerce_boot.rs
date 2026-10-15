use anyhow::Result;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::guest_product::{guest_product_list, pic_url, product_row_json};
use crate::rows::col_text;
use crate::site_config::{site_capability_enabled, site_capabilities_get};

pub async fn queue_boot_build(pool: &PgPool, site_iid: i64) -> Result<Value> {
    let caps = site_capabilities_get(pool, site_iid).await;
    if !site_capability_enabled(&caps, "queue") {
        return Ok(json!({ "enabled": false, "queues": [] }));
    }
    let rows = sqlx::query(
        r#"
        SELECT queue_id, name, description, prefix, fields, take_online, sort_order, meta_json
        FROM site.queue
        WHERE site_iid = $1 AND deleted_ts IS NULL AND is_active = TRUE
        ORDER BY sort_order, queue_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    let queues: Vec<Value> = rows
        .iter()
        .map(|r| {
            let meta = r.get::<Value, _>("meta_json");
            json!({
                "id": r.get::<i64, _>("queue_id"),
                "queue_id": r.get::<i64, _>("queue_id"),
                "name": r.get::<String, _>("name"),
                "description": r.get::<String, _>("description"),
                "prefix": r.get::<String, _>("prefix"),
                "fields": r.get::<Value, _>("fields"),
                "take_online": r.get::<bool, _>("take_online"),
                "sort_order": r.get::<i32, _>("sort_order"),
                "color": meta.get("color").cloned().unwrap_or(Value::Null),
                "icon": meta.get("icon").cloned().unwrap_or(Value::Null),
            })
        })
        .collect();
    Ok(json!({ "enabled": true, "queues": queues }))
}

pub fn order_progress_steps_json(fulfillment: bool) -> Value {
    let mut steps = vec![
        json!({ "state": "waiting_payment", "label": "Menunggu pembayaran" }),
    ];
    if fulfillment {
        steps.push(json!({ "state": "pending", "label": "Diproses" }));
    }
    steps.push(json!({ "state": "ok", "label": "Selesai" }));
    steps.push(json!({ "state": "cancelled", "label": "Dibatalkan" }));
    Value::Array(steps)
}

fn taxes_from_meta(meta: &Value) -> Vec<Value> {
    let raw = meta.get("taxes").and_then(|v| v.as_array());
    let Some(items) = raw else {
        return vec![];
    };
    items
        .iter()
        .filter_map(|t| {
            let active = t.get("active").and_then(|v| v.as_bool()).unwrap_or(true);
            if !active {
                return None;
            }
            let id = t.get("id").and_then(|v| v.as_str()).unwrap_or("").trim();
            let name = t.get("name").and_then(|v| v.as_str()).unwrap_or("Tax").trim();
            let percent = t.get("percent").and_then(|v| v.as_f64()).unwrap_or(0.0);
            if id.is_empty() && name.is_empty() {
                return None;
            }
            Some(json!({
                "id": if id.is_empty() { name } else { id },
                "name": name,
                "percent": percent,
            }))
        })
        .collect()
}

pub async fn commerce_boot_build(pool: &PgPool, site_iid: i64, doc_meta: &Value) -> Result<Value> {
    let caps = site_capabilities_get(pool, site_iid).await;
    if !site_capability_enabled(&caps, "commerce") {
        return Ok(json!({ "enabled": false }));
    }
    let listed = guest_product_list(pool, site_iid, "all", "", "", 200).await?;
    let products: Vec<Value> = listed.items.iter().map(product_row_json).collect();
    let objects = if site_capability_enabled(&caps, "booking") {
        reservable_objects(pool, site_iid).await?
    } else {
        Vec::new()
    };
    Ok(json!({
        "enabled": true,
        "products": products,
        "objects": objects,
        "taxes": taxes_from_meta(doc_meta),
        "payment_methods": payment_methods_from_meta(doc_meta),
    }))
}

/// Editor rows live on `doc.meta.payment_accounts`. An empty list keeps the
/// cash / transfer / QRIS defaults so checkout still has a choice.
pub fn payment_methods_from_meta(meta: &Value) -> Vec<Value> {
    let Some(items) = meta.get("payment_accounts").and_then(|v| v.as_array()) else {
        return default_payment_methods();
    };
    let mapped: Vec<Value> = items
        .iter()
        .filter_map(|row| {
            let id = row.get("id").and_then(|v| v.as_str()).unwrap_or("").trim();
            if id.is_empty() {
                return None;
            }
            let bank = row.get("bank").and_then(|v| v.as_str()).unwrap_or("").trim();
            let account_name = row
                .get("account_name")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .trim();
            let account_number = row
                .get("account_number")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .trim();
            let qris_pic = row.get("qris_pic").and_then(|v| v.as_str()).unwrap_or("").trim();
            let title = [bank, account_name]
                .into_iter()
                .filter(|s| !s.is_empty())
                .collect::<Vec<_>>()
                .join(" · ");
            let title = if title.is_empty() {
                if account_number.is_empty() { id.to_string() } else { account_number.to_string() }
            } else {
                title
            };
            let typ = if qris_pic.is_empty() { "transfer" } else { "qris" };
            Some(json!({
                "id": id,
                "type": typ,
                "title": title,
                "bank": bank,
                "account_name": account_name,
                "account_number": account_number,
                "qris_pic": qris_pic,
            }))
        })
        .collect();
    if mapped.is_empty() {
        default_payment_methods()
    } else {
        mapped
    }
}

async fn reservable_objects(pool: &PgPool, site_iid: i64) -> Result<Vec<Value>> {
    let rows = sqlx::query(
        r#"
        SELECT id, name, code, pic, kind, product_id
        FROM site.object
        WHERE site_iid = $1
          AND deleted_ts IS NULL
          AND is_active = TRUE
          AND can_be_reserved = TRUE
        ORDER BY sort_order, id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .iter()
        .map(|r| {
            let pic: String = col_text(r, "pic");
            let product_id: i64 = r.get::<Option<i64>, _>("product_id").unwrap_or(0);
            json!({
                "id": r.get::<i64, _>("id"),
                "name": r.get::<String, _>("name"),
                "code": r.get::<String, _>("code"),
                "pic": pic_url(&pic),
                "kind": r.get::<String, _>("kind"),
                "product_id": product_id,
            })
        })
        .collect())
}

fn default_payment_methods() -> Vec<Value> {
    vec![
        json!({ "id": "cash", "type": "cash", "title": "Bayar di tempat", "icon": "material-symbols:payments-outline" }),
        json!({ "id": "transfer", "type": "transfer", "title": "Transfer bank", "icon": "material-symbols:account-balance-outline" }),
        json!({ "id": "qris", "type": "qris", "title": "QRIS", "icon": "material-symbols:qr-code-scanner" }),
    ]
}

pub async fn site_published_meta_json(pool: &PgPool, site_iid: i64) -> Value {
    let row = sqlx::query_scalar::<_, serde_json::Value>(
        r#"
        SELECT doc_json FROM site.publish
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        ORDER BY published_ts DESC
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    meta_from_doc_json(row)
}

pub async fn site_draft_meta_json(pool: &PgPool, site_iid: i64) -> Value {
    let row = sqlx::query_scalar::<_, serde_json::Value>(
        r#"
        SELECT doc_json FROM site.draft
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    meta_from_doc_json(row)
}

fn meta_from_doc_json(doc: Option<serde_json::Value>) -> Value {
    doc.and_then(|d| d.get("meta").cloned())
        .unwrap_or_else(|| json!({}))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_payment_accounts_keep_defaults() {
        let methods = payment_methods_from_meta(&json!({}));
        assert_eq!(methods.len(), 3);
        assert_eq!(methods[0]["id"], "cash");
    }

    #[test]
    fn order_progress_steps_omit_pending_when_fulfillment_off() {
        let steps = order_progress_steps_json(false);
        let arr = steps.as_array().expect("array");
        assert_eq!(arr.len(), 3);
        assert!(!arr.iter().any(|s| s.get("state") == Some(&json!("pending"))));
    }

    #[test]
    fn order_progress_steps_include_pending_when_fulfillment_on() {
        let steps = order_progress_steps_json(true);
        let arr = steps.as_array().expect("array");
        assert_eq!(arr.len(), 4);
    }

    #[test]
    fn payment_accounts_replace_defaults() {
        let methods = payment_methods_from_meta(&json!({
            "payment_accounts": [{
                "id": "pa1",
                "bank": "BCA",
                "account_name": "Toko",
                "account_number": "123",
                "qris_pic": ""
            }]
        }));
        assert_eq!(methods.len(), 1);
        assert_eq!(methods[0]["id"], "pa1");
        assert_eq!(methods[0]["title"], "BCA · Toko");
        assert_eq!(methods[0]["type"], "transfer");
    }
}
