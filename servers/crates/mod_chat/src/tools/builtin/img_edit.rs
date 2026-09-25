use anyhow::bail;
use c35_mod_billing::billing_can_afford_tool;
use crate::tool;
use crate::tools::image_tier::{image_default_draft_tier, image_tier_resolve, image_tier_retail_usd};

tool! {
    struct: ImgEditTool,
    name: "img.edit",
    aliases: ["image.edit", "img_edit"],
    description: "Edit or transform an existing image from an attachment or source_hash using a text instruction (change background, add object, restyle, remove background, etc.). Uses Flash Image (not Lite). @image-high requests 2K output.",
    topics: ["image"],
    ui_calling_key: "tool.img.edit.calling",
    ui_done_key: "tool.img.edit.done",
    parameters: {
        prompt: (string, "Expanded English edit instruction describing the desired change.", required),
        source_hash: (string, "CAS file hash of the source image; defaults to the first attached image.", optional),
        aspect_ratio: (string, "Aspect ratio: '1:1', '16:9', '9:16', '4:3', or '3:4'. Default '1:1'.", optional, default = "1:1"),
        quality: (string, "Image quality mode: 'draft' (Flash 1K) or 'hd' (Flash 2K). Default 'draft'.", optional, default = "draft"),
    },
    execute: |args, ctx| {
        let prompt = args["prompt"].as_str().unwrap_or_default();
        let source_hash = args["source_hash"].as_str().unwrap_or("");
        let aspect_ratio = args["aspect_ratio"].as_str().unwrap_or("1:1");
        let quality = args["quality"].as_str().unwrap_or("draft");
        let default_draft = image_default_draft_tier(&ctx.pool).await;
        let tier = image_tier_resolve(&ctx.mention_ids, &ctx.user_text, prompt, quality, true, &default_draft);
        if ctx.owner_iid > 0 {
            let retail = image_tier_retail_usd(&tier);
            let can_afford = billing_can_afford_tool(&ctx.pool, ctx.owner_iid, retail)
                .await
                .unwrap_or(false);
            if !can_afford {
                bail!("Not enough balance or quota to edit image. Please top up your balance or wait for quota reset.");
            }
        }
        crate::tools::img::img_edit_exec(
            &ctx.pool,
            ctx.owner_iid,
            &ctx.http_client,
            prompt,
            source_hash,
            &ctx.attachments_json,
            aspect_ratio,
            quality,
            &ctx.mention_ids,
            &ctx.user_text,
        )
        .await
    }
}
