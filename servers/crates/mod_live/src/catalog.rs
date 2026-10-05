use std::sync::{OnceLock, RwLock};

use anyhow::Result;
use c35_mod_billing::RETAIL_MARKUP;
use c35_proto::{LiveCatalog, LiveOffer};
use c35_store::db_retry;
use chrono::Utc;
use sqlx::PgPool;

#[derive(Clone, Debug)]
pub struct LiveOfferRow {
    pub id: String,
    pub family: String,
    pub label_key: String,
    pub provider: String,
    pub provider_model: String,
    pub inst_id: String,
    pub input_usd_per_min: f64,
    pub output_usd_per_min: f64,
    pub enabled: bool,
    pub sort: i32,
}

fn cache() -> &'static RwLock<Vec<LiveOfferRow>> {
    static C: OnceLock<RwLock<Vec<LiveOfferRow>>> = OnceLock::new();
    C.get_or_init(|| RwLock::new(Vec::new()))
}

pub fn live_retail_usd_per_min(row: &LiveOfferRow) -> f64 {
    (row.input_usd_per_min + row.output_usd_per_min) * RETAIL_MARKUP
}

pub async fn live_catalog_init(pool: &PgPool) -> Result<()> {
    match live_catalog_reload(pool).await {
        Ok(()) => Ok(()),
        Err(e) => {
            tracing::warn!("live_catalog_reload failed ({e:#}); using embedded live_offer defaults");
            *cache().write().expect("live cache lock") = live_catalog_defaults();
            Ok(())
        }
    }
}

pub async fn live_catalog_reload(pool: &PgPool) -> Result<()> {
    let rows = db_retry(pool, || async {
        sqlx::query_as::<_, (String, String, String, String, String, String, f64, f64, bool, i32)>(
            "SELECT id, family, label_key, provider, provider_model, inst_id, \
             input_usd_per_min, output_usd_per_min, enabled, sort \
             FROM ai.live_offer WHERE deleted_ts IS NULL ORDER BY sort, id",
        )
        .fetch_all(pool)
        .await
    })
    .await?;
    let mapped: Vec<LiveOfferRow> = if rows.is_empty() {
        live_catalog_defaults()
    } else {
        rows.into_iter()
            .map(
                |(id, family, label_key, provider, provider_model, inst_id, input_usd_per_min, output_usd_per_min, enabled, sort)| {
                    LiveOfferRow {
                        id,
                        family,
                        label_key,
                        provider,
                        provider_model,
                        inst_id,
                        input_usd_per_min,
                        output_usd_per_min,
                        enabled,
                        sort,
                    }
                },
            )
            .collect()
    };
    *cache().write().expect("live cache lock") = mapped;
    Ok(())
}

pub async fn live_offer_resolve(pool: &PgPool, id: &str) -> Option<LiveOfferRow> {
    if let Some(row) = live_offer_get(id) {
        return Some(row);
    }
    live_catalog_reload(pool).await.ok()?;
    live_offer_get(id)
}

fn live_catalog_defaults() -> Vec<LiveOfferRow> {
    vec![
        LiveOfferRow {
            id: "live.alienai".into(),
            family: "alienai".into(),
            label_key: "live.alienai.label".into(),
            provider: "google".into(),
            provider_model: "gemini-3.8-live".into(),
            inst_id: "inst.general".into(),
            input_usd_per_min: 0.005,
            output_usd_per_min: 0.018,
            enabled: true,
            sort: 10,
        },
        LiveOfferRow {
            id: "live.gemini".into(),
            family: "gemini".into(),
            label_key: "live.gemini.label".into(),
            provider: "google".into(),
            provider_model: "gemini-3.8-live".into(),
            inst_id: String::new(),
            input_usd_per_min: 0.005,
            output_usd_per_min: 0.018,
            enabled: true,
            sort: 20,
        },
        LiveOfferRow {
            id: "live.gemini.thinker".into(),
            family: "gemini".into(),
            label_key: "live.gemini.thinker.label".into(),
            provider: "google".into(),
            provider_model: "gemini-3.8-live-extended-thinking".into(),
            inst_id: String::new(),
            input_usd_per_min: 0.005,
            output_usd_per_min: 0.018,
            enabled: true,
            sort: 21,
        },
        LiveOfferRow {
            id: "live.chatgpt".into(),
            family: "openai".into(),
            label_key: "live.chatgpt.label".into(),
            provider: "openai".into(),
            provider_model: "gpt-4o-realtime-preview".into(),
            inst_id: String::new(),
            input_usd_per_min: 0.006,
            output_usd_per_min: 0.024,
            enabled: false,
            sort: 30,
        },
        LiveOfferRow {
            id: "live.grok".into(),
            family: "xai".into(),
            label_key: "live.grok.label".into(),
            provider: "xai".into(),
            provider_model: "grok-voice".into(),
            inst_id: String::new(),
            input_usd_per_min: 0.006,
            output_usd_per_min: 0.024,
            enabled: false,
            sort: 40,
        },
    ]
}

pub fn live_catalog_rows() -> Vec<LiveOfferRow> {
    cache().read().expect("live cache lock").clone()
}

pub fn live_offer_get(id: &str) -> Option<LiveOfferRow> {
    let key = id.trim();
    cache().read().expect("live cache lock").iter().find(|r| r.id == key).cloned()
}

pub fn live_catalog_proto() -> LiveCatalog {
    let rows = cache().read().expect("live cache lock").clone();
    LiveCatalog {
        updated_ts_ms: Utc::now().timestamp_millis(),
        offers: rows.into_iter().map(row_to_proto).collect(),
    }
}

fn row_to_proto(row: LiveOfferRow) -> LiveOffer {
    let retail = live_retail_usd_per_min(&row);
    LiveOffer {
        id: row.id,
        family: row.family,
        label: String::new(),
        label_key: row.label_key,
        provider: row.provider,
        enabled: row.enabled,
        retail_usd_per_min: retail,
        input_usd_per_min: row.input_usd_per_min,
        output_usd_per_min: row.output_usd_per_min,
    }
}
