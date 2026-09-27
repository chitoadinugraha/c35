use std::time::Instant;

use c35_mod_consumption::consumption_coach_enrich;
use sqlx::PgPool;

use crate::inst_macro::InstRow;

pub struct InstEnrichCtx<'a> {
    pub pool: &'a PgPool,
    pub owner_iid: i64,
    pub locale: &'a str,
    pub user_text: &'a str,
}

pub struct InstEnrichResult {
    pub suffix: String,
    pub keys: Vec<String>,
    pub duration_ms: i64,
}

pub async fn inst_enrich_append(matched: &[InstRow], ctx: &InstEnrichCtx<'_>) -> InstEnrichResult {
    let started = Instant::now();
    if ctx.owner_iid <= 0 || matched.is_empty() {
        return InstEnrichResult {
            suffix: String::new(),
            keys: vec![],
            duration_ms: 0,
        };
    }
    let mut suffix = String::new();
    let mut keys = Vec::new();
    for row in matched {
        let Some((key, block)) = enrich_one(row, ctx).await else {
            continue;
        };
        keys.push(key.clone());
        suffix.push_str(&format!("\n\n[ENRICH:{key}]\n{block}"));
    }
    InstEnrichResult {
        suffix,
        keys,
        duration_ms: started.elapsed().as_millis() as i64,
    }
}

async fn enrich_one(row: &InstRow, ctx: &InstEnrichCtx<'_>) -> Option<(String, String)> {
    match row.id.as_str() {
        "inst.consumption_coach" => {
            let v = consumption_coach_enrich(ctx.pool, ctx.owner_iid, ctx.locale, ctx.user_text).await.ok()?;
            Some(("consumption.nutrition".into(), v.to_string()))
        }
        _ => None,
    }
}