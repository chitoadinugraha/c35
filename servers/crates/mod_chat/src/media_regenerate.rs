use anyhow::{bail, Context, Result};
use c35_mod_billing::{billing_can_afford_tool, billing_deduct, media_regenerate_retail_usd};
use c35_proto::{ReqMediaRegenerate, ResMediaRegenerate};
use reqwest::Client;
use serde_json::Value;
use sqlx::{PgPool, Row};

use crate::generation::{
    generation_prefs_get, generation_prefs_put_one, provider_normalize, GenerationPrefs,
};
use crate::tools::{img, music, vid};

pub async fn media_regenerate(
    pool: &PgPool,
    owner_iid: i64,
    http: &Client,
    req: ReqMediaRegenerate,
) -> Result<ResMediaRegenerate> {
    if owner_iid <= 0 {
        bail!("owner required");
    }
    if req.msg_id <= 0 {
        bail!("msg_id required");
    }
    if req.block_index < 0 {
        bail!("block_index required");
    }
    let row = sqlx::query(
        r#"
        SELECT blocks_json
        FROM ai.chat_msg
        WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(req.msg_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .context("media_regenerate load msg")?;
    let Some(row) = row else {
        bail!("message not found");
    };
    let blocks_raw: String = row.get("blocks_json");
    let mut blocks: Vec<Value> = serde_json::from_str(&blocks_raw).unwrap_or_default();
    let idx = req.block_index as usize;
    if idx >= blocks.len() {
        bail!("block_index out of range");
    }
    let block = blocks[idx].clone();
    let kind = block.get("kind").and_then(|v| v.as_str()).unwrap_or("").to_string();
    let body = block.get("body").cloned().unwrap_or(Value::Object(Default::default()));
    let prompt = body.get("prompt").and_then(|v| v.as_str()).unwrap_or("").trim();
    if prompt.is_empty() {
        bail!("block has no prompt to regenerate");
    }
    let provider_override = provider_normalize(&req.provider);
    let retail = media_regenerate_retail_usd(
        &kind,
        &body.get("media_provider").and_then(|v| v.as_str()).unwrap_or("auto"),
        &body.get("media_model").and_then(|v| v.as_str()).unwrap_or(""),
        &body.get("quality").and_then(|v| v.as_str()).unwrap_or("draft"),
        body.get("duration_sec").and_then(|v| v.as_i64()).unwrap_or(30) as i32,
    );
    if retail > 0.0 {
        let can = billing_can_afford_tool(pool, owner_iid, retail).await.unwrap_or(false);
        if !can {
            bail!("Not enough balance or quota to regenerate media.");
        }
    }
    let tool_out = match kind.as_str() {
        "image" => {
            let aspect_ratio = body.get("aspect_ratio").and_then(|v| v.as_str()).unwrap_or("1:1");
            let quality = body.get("quality").and_then(|v| v.as_str()).unwrap_or("draft");
            let tool_name = body.get("tool").and_then(|v| v.as_str()).unwrap_or("img.generate");
            if tool_name.contains("edit") {
                let source_hash = body.get("source_hash").and_then(|v| v.as_str()).unwrap_or("");
                img::img_edit_exec(
                    pool,
                    owner_iid,
                    http,
                    prompt,
                    source_hash,
                    "[]",
                    aspect_ratio,
                    quality,
                    &[],
                    "",
                    &provider_override,
                )
                .await?
            } else {
                img::img_generate_exec(
                    pool,
                    owner_iid,
                    http,
                    prompt,
                    aspect_ratio,
                    quality,
                    &[],
                    "",
                    &provider_override,
                )
                .await?
            }
        }
        "video" => {
            let aspect_ratio = body.get("aspect_ratio").and_then(|v| v.as_str()).unwrap_or("16:9");
            vid::vid_generate_exec(pool, owner_iid, http, prompt, aspect_ratio, &provider_override).await?
        }
        "music" => {
            let duration = body.get("duration_sec").and_then(|v| v.as_i64()).unwrap_or(30) as i32;
            let instrumental = body.get("instrumental").and_then(|v| v.as_bool()).unwrap_or(false);
            music::music_generate_exec(pool, owner_iid, http, prompt, duration, instrumental, &provider_override)
                .await?
        }
        other => bail!("unsupported block kind: {other}"),
    };
    let new_block = tool_out
        .get("block")
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("tool response missing block"))?;
    blocks[idx] = new_block;
    let blocks_json = serde_json::to_string(&blocks)?;
    sqlx::query(
        r#"
        UPDATE ai.chat_msg SET blocks_json = $1, updated_ts = NOW()
        WHERE id = $2 AND owner_iid = $3 AND deleted_ts IS NULL
        "#,
    )
    .bind(&blocks_json)
    .bind(req.msg_id)
    .bind(owner_iid)
    .execute(pool)
    .await
    .context("media_regenerate update msg")?;
    let charged = tool_out
        .get("wholesale_usd")
        .and_then(|v| v.as_f64())
        .map(c35_mod_billing::billing_to_retail_usd)
        .unwrap_or(retail);
    if charged > 0.0 {
        billing_deduct(pool, owner_iid, charged).await?;
    }
    let media_provider = blocks[idx]
        .pointer("/body/media_provider")
        .and_then(|v| v.as_str())
        .unwrap_or("auto")
        .to_string();
    if req.set_default && !req.provider.trim().is_empty() {
        let kind_key = match kind.as_str() {
            "image" => "image",
            "video" => "video",
            "music" => "music",
            _ => "",
        };
        if !kind_key.is_empty() {
            generation_prefs_put_one(pool, owner_iid, kind_key, &provider_override).await?;
        }
    }
    let prefs_after = generation_prefs_get(pool, owner_iid).await.unwrap_or(GenerationPrefs::defaults());
    Ok(ResMediaRegenerate {
        blocks_json,
        retail_usd: charged,
        media_provider,
        generation_image: prefs_after.image,
        generation_video: prefs_after.video,
        generation_music: prefs_after.music,
        req_id: String::new(),
        msg_id: req.msg_id,
    })
}
