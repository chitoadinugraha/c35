use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteConfigPut, ResSiteConfigPut, SiteConfig, sync_push,
};
use chrono::Utc;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::site_assistant::{
    site_assistant_capabilities_merge, site_config_assistant_bot_iid_from_row,
};
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;

pub fn site_capability_enabled(caps: &serde_json::Value, key: &str) -> bool {
    caps.get(key).and_then(|v| v.as_bool()).unwrap_or(true)
}

/// In-house kitchen / order processing (POS open-order queue, guest `pending` step).
/// When the key is absent, defaults to **commerce** so existing F&B sites keep current behavior.
pub fn site_order_fulfillment_enabled(caps: &serde_json::Value) -> bool {
    caps
        .get("order_fulfillment")
        .and_then(|v| v.as_bool())
        .unwrap_or_else(|| site_capability_enabled(caps, "commerce"))
}

/// Customer member portal (sign-in, order history). Defaults on when commerce is on.
pub fn site_member_portal_enabled(caps: &serde_json::Value) -> bool {
    caps
        .get("member_portal")
        .and_then(|v| v.as_bool())
        .unwrap_or_else(|| site_capability_enabled(caps, "commerce"))
}

pub async fn site_capabilities_get(pool: &PgPool, site_iid: i64) -> serde_json::Value {
    let row = sqlx::query(
        r#"
        SELECT capabilities_json, assistant_bot_iid
        FROM site.config
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    let (caps, bot_iid) = match row {
        Some(r) => (
            r.try_get::<serde_json::Value, _>("capabilities_json")
                .ok()
                .unwrap_or_else(|| serde_json::json!({})),
            site_config_assistant_bot_iid_from_row(&r),
        ),
        None => (serde_json::json!({}), 0),
    };
    site_assistant_capabilities_merge(&caps, bot_iid)
}

pub async fn site_capability_check(pool: &PgPool, site_iid: i64, capability: &str) -> bool {
    let caps = site_capabilities_get(pool, site_iid).await;
    site_capability_enabled(&caps, capability)
}

fn ts_ms(t: Option<chrono::DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

pub async fn site_config_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteConfigPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteConfigPut> {
    let site_iid = req.site_iid;
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let caps_raw = req.capabilities_json.trim();
    if caps_raw.is_empty() {
        return Err(anyhow!("capabilities_json required"));
    }
    let caps: serde_json::Value = serde_json::from_str(caps_raw)
        .map_err(|e| anyhow!("invalid capabilities_json: {e}"))?;

    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, capabilities_json, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
            capabilities_json = EXCLUDED.capabilities_json,
            updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&caps)
    .execute(pool)
    .await?;

    let _ = c35_mod_hint::hint_invalidate_for_asset(pool, site_iid).await;

    let row = sqlx::query(
        r#"
        SELECT site_iid, owner_iid, published_version_id, inventory_costing_method, tz,
               payroll_policy_json, presence_policy_json, capabilities_json,
               assistant_bot_iid, alien_id_changed_ts, created_ts, updated_ts, deleted_ts
        FROM site.config WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_one(pool)
    .await?;

    let config = SiteConfig {
        site_iid: row.get("site_iid"),
        owner_iid: row.get("owner_iid"),
        published_version_id: row
            .try_get::<Option<String>, _>("published_version_id")
            .ok()
            .flatten()
            .unwrap_or_default(),
        inventory_costing_method: row.get("inventory_costing_method"),
        tz: row.get("tz"),
        payroll_policy_json: row.get::<serde_json::Value, _>("payroll_policy_json").to_string(),
        presence_policy_json: row
            .get::<serde_json::Value, _>("presence_policy_json")
            .to_string(),
        capabilities_json: row.get::<serde_json::Value, _>("capabilities_json").to_string(),
        assistant_bot_iid: site_config_assistant_bot_iid_from_row(&row),
        alien_id_changed_ts_ms: ts_ms(row.get("alien_id_changed_ts")),
        created_ts_ms: ts_ms(Some(row.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(row.get("updated_ts"))),
        deleted_ts_ms: ts_ms(row.get("deleted_ts")),
    };

    if let Some(tx) = out_tx {
        site_sync_push(tx, sync_push::Body::SiteConfig(config.clone()));
    }

    Ok(ResSiteConfigPut { config: Some(config) })
}
