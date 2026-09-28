use c35_mod_consumption::consumption_coach_enrich;
use sqlx::PgPool;

use crate::inst_macro::InstRow;

pub struct InstEnrichCtx<'a> {
    pub pool: &'a PgPool,
    pub owner_iid: i64,
    pub locale: &'a str,
    pub user_text: &'a str,
    pub attachments_json: &'a str,
}

pub struct InstEnrichResult {
    pub suffix: String,
    pub keys: Vec<String>,
}

pub async fn inst_enrich_append(matched: &[InstRow], ctx: &InstEnrichCtx<'_>) -> InstEnrichResult {
    if ctx.owner_iid <= 0 || matched.is_empty() {
        return InstEnrichResult {
            suffix: String::new(),
            keys: vec![],
        };
    }
    let mut suffix = String::new();
    let mut keys = Vec::new();
    for row in matched {
        if row.id == "inst.presentation" {
            if let Some(block) = crate::pdf_cas::presentation_pdf_enrich(ctx.pool, ctx.attachments_json).await {
                keys.push("presentation.pdf".into());
                suffix.push_str(&format!("\n\n[ENRICH:presentation.pdf]\n{block}"));
            }
            if let Some(block) = crate::video_source::presentation_youtube_enrich(ctx.pool, ctx.user_text, ctx.owner_iid).await {
                keys.push("presentation.youtube".into());
                suffix.push_str(&format!("\n\n[ENRICH:presentation.youtube]\n{block}"));
            }
            continue;
        }
        let Some((key, block)) = enrich_one(row, ctx).await else {
            continue;
        };
        keys.push(key.clone());
        suffix.push_str(&format!("\n\n[ENRICH:{key}]\n{block}"));
    }
    InstEnrichResult { suffix, keys }
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