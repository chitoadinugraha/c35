mod params;
mod product;
mod tx;

use std::collections::HashMap;
use std::sync::{Arc, OnceLock};

use anyhow::{anyhow, bail, Result};
use async_trait::async_trait;
use c35_proto::{ResSiteQueryRun, SiteQueryRow};
use serde_json::Value;
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;

pub struct QueryResult {
    pub rows: Vec<SiteQueryRow>,
    pub result_json: String,
}

#[async_trait]
pub trait QueryDef: Send + Sync {
    fn id(&self) -> &'static str;
    fn label(&self) -> &'static str;
    fn site_scoped(&self) -> bool {
        true
    }
    async fn run(
        &self,
        pool: &PgPool,
        caller_iid: i64,
        site_iids: &[i64],
        params: &Value,
    ) -> Result<QueryResult>;
}

fn query_registry() -> &'static Vec<Arc<dyn QueryDef>> {
    static REG: OnceLock<Vec<Arc<dyn QueryDef>>> = OnceLock::new();
    REG.get_or_init(|| {
        vec![
            Arc::new(product::ProductListQuery),
            Arc::new(product::ProductStockStatusQuery),
            Arc::new(product::ProductStockQuery),
            Arc::new(tx::SalesSummaryQuery),
            Arc::new(tx::ProfitSummaryQuery),
            Arc::new(tx::TopProductsQuery),
            Arc::new(tx::ProductCompareQuery),
        ]
    })
}

pub fn query_def_get(query_id: &str) -> Option<Arc<dyn QueryDef>> {
    query_registry()
        .iter()
        .find(|q| q.id() == query_id)
        .cloned()
}

pub fn query_def_list() -> Vec<(&'static str, &'static str)> {
    query_registry()
        .iter()
        .map(|q| (q.id(), q.label()))
        .collect()
}

async fn site_names_map(pool: &PgPool, site_iids: &[i64]) -> Result<HashMap<i64, String>> {
    if site_iids.is_empty() {
        return Ok(HashMap::new());
    }
    let rows = sqlx::query(
        r#"
        SELECT id, COALESCE(name, '') AS name
        FROM ai.identity
        WHERE id = ANY($1) AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iids)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|r| (r.get("id"), r.get("name")))
        .collect())
}

pub(crate) async fn site_query_rows_with_names(
    pool: &PgPool,
    site_iids: &[i64],
    mut rows: Vec<SiteQueryRow>,
) -> Result<Vec<SiteQueryRow>> {
    let names = site_names_map(pool, site_iids).await?;
    for row in &mut rows {
        if row.site_name.is_empty() {
            row.site_name = names.get(&row.site_iid).cloned().unwrap_or_default();
        }
    }
    Ok(rows)
}

pub async fn site_query_run(
    pool: &PgPool,
    caller_iid: i64,
    site_iids: Vec<i64>,
    query_id: &str,
    params_json: &str,
) -> Result<ResSiteQueryRun> {
    if query_id.trim().is_empty() {
        bail!("query_id is required");
    }
    if site_iids.is_empty() {
        bail!("site_iids is required — mention @site or pass site_iids");
    }
    for site_iid in &site_iids {
        site_grant_check(pool, caller_iid, *site_iid, false).await?;
    }
    let def = query_def_get(query_id)
        .ok_or_else(|| anyhow!("unknown query_id: {query_id}"))?;
    if def.site_scoped() && site_iids.is_empty() {
        bail!("site_iids required for query {query_id}");
    }
    let params: Value = if params_json.trim().is_empty() {
        Value::Object(serde_json::Map::new())
    } else {
        serde_json::from_str(params_json)
            .map_err(|e| anyhow!("invalid params_json: {e}"))?
    };
    let result = def
        .run(pool, caller_iid, &site_iids, &params)
        .await?;
    Ok(ResSiteQueryRun {
        rows: result.rows,
        result_json: result.result_json,
    })
}

#[macro_export]
macro_rules! query_register {
    (
        struct: $struct_name:ident,
        id: $id:expr,
        label: $label:expr,
        $(site_scoped: $site_scoped:expr,)?
        run: |$pool:ident, $caller:ident, $sites:ident, $params:ident| $body:expr
    ) => {
        pub struct $struct_name;

        #[async_trait::async_trait]
        impl $crate::query::QueryDef for $struct_name {
            fn id(&self) -> &'static str {
                $id
            }

            fn label(&self) -> &'static str {
                $label
            }

            fn site_scoped(&self) -> bool {
                $crate::query_register_site_scoped!($($site_scoped)?)
            }

            async fn run(
                &self,
                $pool: &sqlx::PgPool,
                $caller: i64,
                $sites: &[i64],
                $params: &serde_json::Value,
            ) -> anyhow::Result<$crate::query::QueryResult> {
                $body
            }
        }
    };
}

pub use query_register;

#[cfg(test)]
mod registry_test;

#[macro_export]
#[doc(hidden)]
macro_rules! query_register_site_scoped {
    () => { true };
    ($v:expr) => { $v };
}
