pub mod audio;
mod gemini;
mod realtime_openai;
mod report;

pub use audio::{smoke_recording_pcm16k, SMOKE_QUESTION};
pub use gemini::smoke_gemini_live;
pub use realtime_openai::{smoke_realtime, RealtimeVendor};
pub use report::{print_report, SmokeOutcome};

pub async fn run_all_parallel(client: &reqwest::Client) -> anyhow::Result<Vec<SmokeOutcome>> {
    let (pcm16k, wav) = smoke_recording_pcm16k(client).await?;
    let pcm24k = audio::pcm16k_to_pcm24k(&pcm16k);
    let gemini_model =
        std::env::var("LIVE_SMOKE_GEMINI_MODEL").unwrap_or_else(|_| "gemini-3.8-live".into());
    let (g, o, x) = tokio::join!(
        smoke_gemini_live(pcm16k, &gemini_model),
        smoke_realtime(pcm24k.clone(), RealtimeVendor::OpenAi),
        smoke_realtime(pcm24k, RealtimeVendor::Xai),
    );
    let outcomes = [g, o, x];
    print_report(SMOKE_QUESTION, &wav.display().to_string(), &outcomes);
    Ok(outcomes.to_vec())
}
