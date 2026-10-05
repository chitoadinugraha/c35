use anyhow::bail;
use c35_mod_billing::billing_can_afford_tool;
use crate::tool;
use crate::tools::music::music_retail_estimate;

tool! {
    struct: MusicGenerateTool,
    name: "music.generate",
    aliases: ["music_generate"],
    description: "Generate background music from a text prompt (~30s). Default ElevenLabs music-v2; lyria uses Gemini Lyria clip preview.",
    topics: ["music"],
    ui_calling_key: "tool.music.generate.calling",
    ui_done_key: "tool.music.generate.done",
    parameters: {
        prompt: (string, "Music style and mood description.", required),
        duration_sec: (integer, "Clip length in seconds (default 30).", optional, default = 30),
        instrumental: (boolean, "Instrumental only (no vocals).", optional, default = true),
        provider: (string, "Provider override: auto, elevenlabs, or lyria.", optional, default = ""),
    },
    execute: |args, ctx| {
        let prompt = args["prompt"].as_str().unwrap_or_default();
        let duration_sec = args["duration_sec"].as_i64().unwrap_or(30) as i32;
        let instrumental = args["instrumental"].as_bool().unwrap_or(true);
        let provider = args["provider"].as_str().unwrap_or("");
        if ctx.owner_iid > 0 {
            let retail = music_retail_estimate(provider, "", duration_sec);
            let can_afford = billing_can_afford_tool(&ctx.pool, ctx.owner_iid, retail)
                .await
                .unwrap_or(false);
            if !can_afford {
                bail!("Not enough balance or quota to generate music.");
            }
        }
        crate::tools::music::music_generate_exec(
            &ctx.pool,
            ctx.owner_iid,
            &ctx.http_client,
            prompt,
            duration_sec,
            instrumental,
            provider,
        )
        .await
    }
}
