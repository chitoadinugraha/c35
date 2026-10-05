use anyhow::bail;
use c35_mod_billing::billing_can_afford_tool;
use crate::tool;
use crate::tools::vid::vid_retail_estimate;

tool! {
    struct: VidGenerateTool,
    name: "vid.generate",
    aliases: ["video.generate", "vid_generate"],
    description: "Generate a short video clip from a text prompt. Default provider Seedance 2.0-mini via Cloudflare.",
    topics: ["video"],
    ui_calling_key: "tool.vid.generate.calling",
    ui_done_key: "tool.vid.generate.done",
    parameters: {
        prompt: (string, "English visual motion prompt.", required),
        aspect_ratio: (string, "Aspect ratio: 16:9, 9:16, or 1:1. Default 16:9.", optional, default = "16:9"),
        provider: (string, "Provider override: auto or seedance.", optional, default = ""),
    },
    execute: |args, ctx| {
        let prompt = args["prompt"].as_str().unwrap_or_default();
        let aspect_ratio = args["aspect_ratio"].as_str().unwrap_or("16:9");
        let provider = args["provider"].as_str().unwrap_or("");
        if ctx.owner_iid > 0 {
            let retail = vid_retail_estimate(provider, "");
            let can_afford = billing_can_afford_tool(&ctx.pool, ctx.owner_iid, retail)
                .await
                .unwrap_or(false);
            if !can_afford {
                bail!("Not enough balance or quota to generate video.");
            }
        }
        crate::tools::vid::vid_generate_exec(
            &ctx.pool,
            ctx.owner_iid,
            &ctx.http_client,
            prompt,
            aspect_ratio,
            provider,
        )
        .await
    }
}
