use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct SmokeOutcome {
    pub provider: String,
    pub ok: bool,
    pub elapsed_ms: u64,
    pub reply: String,
    pub detail: String,
}

impl SmokeOutcome {
    pub fn fail(provider: &str, msg: impl Into<String>) -> Self {
        Self {
            provider: provider.into(),
            ok: false,
            elapsed_ms: 0,
            reply: msg.into(),
            detail: String::new(),
        }
    }
}

pub fn print_report(question: &str, wav_path: &str, rows: &[SmokeOutcome]) {
    println!("=== live realtime smoke ===");
    println!("question: {question}");
    println!("recording: {wav_path}");
    println!();
    for r in rows {
        let mark = if r.ok { "OK" } else { "FAIL" };
        println!("[{mark}] {} ({} ms)", r.provider, r.elapsed_ms);
        println!("  reply: {}", r.reply);
        if !r.detail.is_empty() {
            println!("  detail: {}", r.detail);
        }
    }
    let ok_count = rows.iter().filter(|r| r.ok).count();
    println!();
    println!("passed {ok_count}/{}", rows.len());
}
