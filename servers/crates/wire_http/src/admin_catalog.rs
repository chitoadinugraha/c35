use c35_mod_admin::{admin_llm_catalog_list, AdminError};
use c35_mod_billing::{rate_card_retail_usd, rate_card_rows};
use c35_mod_live::{live_catalog_rows, LiveOfferRow};
use c35_mod_llm::{catalog_models, llm_catalog_ensure_memory};
use c35_proto::{
    AdminServiceRateRow, ReqAdminLlmCatalogList, ResAdminLlmCatalogList,
};
use sqlx::PgPool;

pub async fn admin_catalog_prices_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminLlmCatalogList,
) -> Result<ResAdminLlmCatalogList, AdminError> {
    let mut res = admin_llm_catalog_list(pool, viewer_iid, req).await?;
    llm_catalog_ensure_memory(pool).await;
    let markup = res.retail_markup;
    let mut services: Vec<AdminServiceRateRow> = rate_card_rows()
        .into_iter()
        .map(|r| AdminServiceRateRow {
            category: r.category,
            id: r.id,
            label: r.label,
            unit: r.unit,
            wholesale_usd: r.wholesale_usd,
            retail_usd: rate_card_retail_usd(r.wholesale_usd),
            detail: r.detail,
        })
        .collect();
    for m in catalog_models() {
        if m.family != "embed" {
            continue;
        }
        let wholesale_in = m.input_micro_per_m as f64 / 1_000_000.0;
        if wholesale_in <= 0.0 {
            continue;
        }
        services.push(AdminServiceRateRow {
            category: "embed".into(),
            id: m.id.clone(),
            label: if m.label.is_empty() { m.id.clone() } else { m.label.clone() },
            unit: "usd_per_1m_tokens".into(),
            wholesale_usd: wholesale_in,
            retail_usd: rate_card_retail_usd(wholesale_in),
            detail: m.provider_model.clone(),
        });
    }
    services.sort_by(|a, b| a.category.cmp(&b.category).then(a.id.cmp(&b.id)));
    res.services = services;
    res.live = live_catalog_rows()
        .into_iter()
        .map(live_row_to_admin)
        .collect();
    res.retail_markup = markup;
    Ok(res)
}

fn live_row_to_admin(row: LiveOfferRow) -> AdminServiceRateRow {
    let wholesale = row.input_usd_per_min + row.output_usd_per_min;
    AdminServiceRateRow {
        category: "live".into(),
        id: row.id,
        label: row.label_key,
        unit: "usd_per_min_combined".into(),
        wholesale_usd: wholesale,
        retail_usd: rate_card_retail_usd(wholesale),
        detail: format!(
            "in ${}/min out ${}/min · {}{}",
            row.input_usd_per_min,
            row.output_usd_per_min,
            row.provider_model,
            if row.enabled { "" } else { " · disabled" }
        ),
    }
}
