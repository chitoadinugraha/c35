use std::collections::HashMap;

use c35_mod_site::site_capability_enabled;
use serde_json::json;
use sqlx::PgPool;

use crate::mention_context::MentionContext;

#[derive(Debug, Clone, Default)]
pub struct SiteCapabilityView {
    by_site: HashMap<i64, serde_json::Value>,
}

impl SiteCapabilityView {
    pub fn empty() -> Self {
        Self::default()
    }

    pub async fn load(pool: &PgPool, site_iids: &[i64]) -> Self {
        let mut by_site = HashMap::new();
        for &site_iid in site_iids {
            if site_iid <= 0 || by_site.contains_key(&site_iid) {
                continue;
            }
            let caps = c35_mod_site::site_capabilities_get(pool, site_iid).await;
            by_site.insert(site_iid, caps);
        }
        Self { by_site }
    }

    pub fn from_map(by_site: HashMap<i64, serde_json::Value>) -> Self {
        Self { by_site }
    }

    pub fn has(&self, site_iid: i64, capability: &str) -> bool {
        let caps = self
            .by_site
            .get(&site_iid)
            .cloned()
            .unwrap_or_else(|| json!({}));
        site_capability_enabled(&caps, capability)
    }

    pub fn commerce_site_iids(&self, site_iids: &[i64]) -> Vec<i64> {
        site_iids
            .iter()
            .copied()
            .filter(|&iid| self.has(iid, "commerce"))
            .collect()
    }
}

pub async fn site_capability_view_for_mention(pool: &PgPool, mention: &MentionContext) -> SiteCapabilityView {
    SiteCapabilityView::load(pool, &mention.site_iids()).await
}
