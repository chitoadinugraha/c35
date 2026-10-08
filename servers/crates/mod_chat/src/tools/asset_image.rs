use anyhow::{bail, Result};
use c35_mod_billing::billing_frontier_try_deduct;
use sqlx::PgPool;

use crate::tools::image_tier::{
    image_default_draft_tier, image_tier_resolve, image_tier_retail_usd,
};
use crate::tools::img::img_generate_exec;

pub struct AssetImage {
    pub hash: String,
    pub url: String,
    pub mime: String,
    pub prompt: String,
}

/// Generate a 1:1 draft image and charge the frontier ring only.
/// `owner_iid <= 0` skips the deduct (tests). Positive owners deduct before the provider call.
pub async fn asset_image_generate(
    pool: &PgPool,
    owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    provider: &str,
) -> Result<AssetImage> {
    let prompt = prompt.trim();
    if prompt.is_empty() {
        bail!("image prompt cannot be empty");
    }
    let default_draft = image_default_draft_tier(pool).await;
    let tier = image_tier_resolve(&[], prompt, prompt, "draft", false, &default_draft);
    let retail = image_tier_retail_usd(&tier);
    if owner_iid > 0 {
        let deducted = billing_frontier_try_deduct(pool, owner_iid, retail).await?;
        if !deducted {
            bail!("Not enough frontier quota");
        }
    }
    let value = img_generate_exec(
        pool,
        owner_iid,
        client,
        prompt,
        "1:1",
        "draft",
        &[],
        prompt,
        provider,
    )
    .await?;
    let hash = json_str(&value, "/block/body/hash");
    if hash.is_empty() {
        bail!("image hash missing");
    }
    Ok(AssetImage {
        url: json_str(&value, "/block/body/url"),
        mime: json_str(&value, "/block/body/mime"),
        prompt: prompt.to_string(),
        hash,
    })
}

fn json_str(value: &serde_json::Value, pointer: &str) -> String {
    value
        .pointer(pointer)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string()
}
