use anyhow::Result;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::guest_product::{guest_product_list, pic_url, product_row_json};
use crate::rows::col_text;
use crate::site_config::{site_capability_enabled, site_capabilities_get};

pub fn order_progress_steps_json() -> Value {
    json!([
        { "state": "waiting_payment", "label": "Menunggu pembayaran" },
        { "state": "pending", "label": "Diproses" },
        { "state": "ok", "label": "Selesai" },
        { "state": "cancelled", "label": "Dibatalkan" },
    ])
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
        "payment_methods": default_payment_methods(),
    }))
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

fn meta_from_doc_json(doc: Option<serde_json::Value>) -> Value {
    doc.and_then(|d| d.get("meta").cloned())
        .unwrap_or_else(|| json!({}))
}
