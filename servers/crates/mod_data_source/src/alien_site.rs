//! Bot-linked Alien site (commerce capabilities in config; no sheet-style sync).

use anyhow::{anyhow, Result};
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::config::SOURCE_KIND_ALIEN_SITE;
use crate::store::sync_upsert_ok;

pub const CAP_ANSWER_PRODUCT_QUESTIONS: &str = "answer_product_questions";
pub const CAP_TAKE_ORDERS: &str = "take_orders";
pub const CAP_SHARE_ORDER_STATUS: &str = "share_order_status";

pub fn config_site_iid(config: &Value) -> Option<i64> {
    config
        .get("site_iid")
        .and_then(|v| {
            if let Some(n) = v.as_i64() {
                return Some(n);
            }
            v.as_str().and_then(|s| s.trim().parse().ok())
        })
        .filter(|id| *id > 0)
}

pub fn config_capability(config: &Value, key: &str) -> bool {
    config
        .get(key)
        .and_then(|v| v.as_bool())
        .unwrap_or(true)
}

pub fn config_normalize_alien_site(config: &mut Value) -> Result<()> {
    let site_iid = config_site_iid(config).ok_or_else(|| anyhow!("site_iid required"))?;
    let obj = config
        .as_object_mut()
        .ok_or_else(|| anyhow!("config must be object"))?;
    obj.insert("site_iid".into(), json!(site_iid));
    for key in [
        CAP_ANSWER_PRODUCT_QUESTIONS,
        CAP_TAKE_ORDERS,
        CAP_SHARE_ORDER_STATUS,
    ] {
        let on = obj.get(key).and_then(|v| v.as_bool()).unwrap_or(true);
        obj.insert(key.into(), json!(on));
    }
    Ok(())
}

pub async fn alien_site_sync_run(pool: &PgPool, data_source_id: i64) -> Result<()> {
    sync_upsert_ok(pool, data_source_id, SOURCE_KIND_ALIEN_SITE, "linked", 0).await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn normalize_defaults_capabilities_on() {
        let mut cfg = json!({"site_iid": "42"});
        config_normalize_alien_site(&mut cfg).unwrap();
        assert_eq!(cfg["site_iid"], 42);
        assert_eq!(cfg[CAP_ANSWER_PRODUCT_QUESTIONS], true);
        assert_eq!(cfg[CAP_TAKE_ORDERS], true);
        assert_eq!(cfg[CAP_SHARE_ORDER_STATUS], true);
    }
}
