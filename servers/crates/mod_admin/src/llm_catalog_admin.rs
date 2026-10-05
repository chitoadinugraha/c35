use crate::{require_root, AdminError};
use c35_mod_llm::{ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M, catalog_models, llm_catalog_ensure_memory};
use c35_proto::{AdminLlmCatalogRow, ReqAdminLlmCatalogList, ResAdminLlmCatalogList};
use sqlx::PgPool;

/// Keep in sync with `c35_mod_billing::billing_cost::RETAIL_MARKUP`.
const RETAIL_MARKUP: f64 = 1.50;

fn micro_per_m_to_usd(micro_per_m: i64) -> f64 {
    micro_per_m as f64 / 1_000_000.0
}

fn retail_usd(wholesale: f64) -> f64 {
    wholesale * RETAIL_MARKUP
}

pub async fn admin_llm_catalog_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminLlmCatalogList,
) -> Result<ResAdminLlmCatalogList, AdminError> {
    require_root(pool, viewer_iid).await?;
    llm_catalog_ensure_memory(pool).await;
    let mut models = catalog_models();
    if req.enabled_only {
        models.retain(|m| m.enabled);
    }
    models.sort_by(|a, b| {
        a.provider
            .cmp(&b.provider)
            .then_with(|| a.label.to_lowercase().cmp(&b.label.to_lowercase()))
    });
    let rows = models
        .into_iter()
        .map(|m| {
            let (in_usd, out_usd, cache_usd) = if m.id == "alienai" || m.provider == "alienai" {
                (ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M, 0.0)
            } else {
                (
                    micro_per_m_to_usd(m.input_micro_per_m),
                    micro_per_m_to_usd(m.output_micro_per_m),
                    micro_per_m_to_usd(m.input_cache_micro_per_m),
                )
            };
            AdminLlmCatalogRow {
                id: m.id,
                provider: m.provider,
                label: m.label,
                source: m.source,
                enabled: m.enabled,
                usd_in_per_1m: in_usd,
                usd_in_cache_per_1m: cache_usd,
                usd_out_per_1m: out_usd,
                retail_usd_in_per_1m: retail_usd(in_usd),
                retail_usd_in_cache_per_1m: if cache_usd > 0.0 { retail_usd(cache_usd) } else { 0.0 },
                retail_usd_out_per_1m: retail_usd(out_usd),
            }
        })
        .collect();
    Ok(ResAdminLlmCatalogList {
        models: rows,
        retail_markup: RETAIL_MARKUP,
        services: vec![],
        live: vec![],
    })
}
