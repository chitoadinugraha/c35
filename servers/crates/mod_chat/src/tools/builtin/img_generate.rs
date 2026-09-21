use crate::tool;

tool! {
    struct: ImgGenerateTool,
    name: "img.generate",
    aliases: ["image.generate", "img_generate"],
    description: "Generate, create, draw, paint, or render an image, artwork, illustration, logo, icon, sketch, or photo from a text prompt description.",
    topics: ["*", "image"],
    ui_calling_key: "tool.img.generate.calling",
    ui_done_key: "tool.img.generate.done",
    parameters: {
        prompt: (string, "Expanded, highly descriptive English visual prompt describing the subject, style, composition, lighting, and colors.", required),
        aspect_ratio: (string, "Aspect ratio: '1:1' (square / icons / logos), '16:9' (landscape), '9:16' (portrait), '4:3', or '3:4'. Default '1:1'.", optional, default = "1:1"),
        quality: (string, "Image quality mode: 'draft' (fast standard) or 'hd'. Default is 'draft'.", optional, default = "draft"),
    },
    execute: |args, ctx| {
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
