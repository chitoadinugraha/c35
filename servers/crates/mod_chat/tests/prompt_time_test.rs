use c35_mod_chat::prompt::time::{time_prompt_block, time_timezone_resolve, user_asks_time};
use c35_mod_llm::alien_default_model;
use serde_json::json;
use tokio_util::sync::CancellationToken;

#[test]
fn prompt_time_question_is_detected() {
    assert!(user_asks_time("sekarang hari apa ?"));
}

#[test]
fn prompt_time_block_has_context_for_answer() {
    let tz = time_timezone_resolve("id", "sekarang hari apa ?");
    let block = time_prompt_block(tz);
    assert!(block.contains("Now:"));
}

#[tokio::test]
#[ignore = "requires GEMINI_API_KEY and network"]
async fn live_prompt_time_question_streams_text() {
    let key = c35_mod_chat::prompt::gemini::gemini_api_key();
    if key.is_empty() {
        eprintln!("skipping live_prompt_time_question_streams_text: GEMINI_API_KEY missing");
        return;
    }
    let tz = time_timezone_resolve("id", "sekarang hari apa ?");
    let system = time_prompt_block(tz);
    let contents = [json!({ "role": "user", "parts": [{ "text": "sekarang hari apa ?" }] })];
    let cancel = CancellationToken::new();
    let mut deltas = Vec::new();
    let mut on_delta = |thought: bool, text: String| {
        deltas.push((thought, text));
    };
    let model = alien_default_model();
    let out = c35_mod_chat::prompt::gemini::gemini_generate_stream(
        &contents,
        &json!([]),
        "off",
        &model,
        &system,
        &mut on_delta,
        &cancel,
    )
    .await
    .expect("gemini stream");
    assert!(!out.text.trim().is_empty(), "model={model} deltas={deltas:?} text={:?} thought={:?}", out.text, out.thought);
}
