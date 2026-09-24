use anyhow::bail;
use c35_mod_billing::billing_can_afford_tool;
use crate::tool;
use crate::tools::image_tier::{image_tier_resolve, image_tier_retail_usd};

tool! {
    struct: ImgGenerateTool,
    name: "img.generate",
    aliases: ["image.generate", "img_generate"],
    description: "Generate, create, draw, paint, or render a new image, artwork, illustration, logo, icon, sketch, or photo from a text prompt. For editing an attached image, use img.edit instead. Default uses Flash-Lite; @image-high or quality hd uses Flash Image.",
    topics: ["image"],
    ui_calling_key: "tool.img.generate.calling",
    ui_done_key: "tool.img.generate.done",
    parameters: {
        prompt: (string, "Expanded, highly descriptive English visual prompt describing the subject, style, composition, lighting, and colors.", required),
        aspect_ratio: (string, "Aspect ratio: '1:1' (square / icons / logos), '16:9' (landscape), '9:16' (portrait), '4:3', or '3:4'. Default '1:1'.", optional, default = "1:1"),
        quality: (string, "Image quality mode: 'draft' (Flash-Lite 1K default) or 'hd' (Flash Image 2K). Use hd for logos and text-in-image.", optional, default = "draft"),
    },
    execute: |args, ctx| {
        let prompt = args["prompt"].as_str().unwrap_or_default();
        let aspect_ratio = args["aspect_ratio"].as_str().unwrap_or("1:1");
        let quality = args["quality"].as_str().unwrap_or("draft");
        let tier = image_tier_resolve(&ctx.mention_ids, &ctx.user_text, prompt, quality, false);
        if ctx.owner_iid > 0 {
            let retail = image_tier_retail_usd(&tier);
            let can_afford = billing_can_afford_tool(&ctx.pool, ctx.owner_iid, retail)
                .await
                .unwrap_or(false);
            if !can_afford {
                bail!("Not enough balance or quota to generate image. Please top up your balance or wait for quota reset.");
            }
        }
        crate::tools::img::img_generate_exec(
            &ctx.pool,
            ctx.owner_iid,
            &ctx.http_client,
            prompt,
            aspect_ratio,
            quality,
            &ctx.mention_ids,
            &ctx.user_text,
        )
        .await
    }
}
