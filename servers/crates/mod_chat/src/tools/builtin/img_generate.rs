use anyhow::bail;
use c35_mod_billing::{billing_can_afford_tool, IMAGE_GEN_RETAIL_USD};
use crate::tool;

tool! {
    struct: ImgGenerateTool,
    name: "img.generate",
    aliases: ["image.generate", "img_generate"],
    description: "Generate, create, draw, paint, or render an image, artwork, illustration, logo, icon, sketch, or photo from a text prompt description.",
    topics: ["image"],
    ui_calling_key: "tool.img.generate.calling",
    ui_done_key: "tool.img.generate.done",
    cost_wholesale: 0.035,
    parameters: {
        prompt: (string, "Expanded, highly descriptive English visual prompt describing the subject, style, composition, lighting, and colors.", required),
        aspect_ratio: (string, "Aspect ratio: '1:1' (square / icons / logos), '16:9' (landscape), '9:16' (portrait), '4:3', or '3:4'. Default '1:1'.", optional, default = "1:1"),
        quality: (string, "Image quality mode: 'draft' (fast standard) or 'hd'. Default is 'draft'.", optional, default = "draft"),
    },
    execute: |args, ctx| {
        if ctx.owner_iid > 0 {
            let can_afford = billing_can_afford_tool(&ctx.pool, ctx.owner_iid, IMAGE_GEN_RETAIL_USD)
                .await
                .unwrap_or(false);
            if !can_afford {
                bail!("Not enough balance or quota to generate image. Please top up your balance or wait for quota reset.");
            }
        }
        let prompt = args["prompt"].as_str().unwrap_or_default();
        let aspect_ratio = args["aspect_ratio"].as_str().unwrap_or("1:1");
        let quality = args["quality"].as_str().unwrap_or("draft");
        crate::tools::img::img_generate_exec(
            &ctx.pool,
            ctx.owner_iid,
            &ctx.http_client,
            prompt,
            aspect_ratio,
            quality,
        )
        .await
    }
}
