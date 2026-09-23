use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use reqwest::Client;
use serde::Deserialize;
use serde_json::json;
use sqlx::PgPool;
use tracing::warn;

use crate::memory::memory_put;
use crate::prompt::gemini::{gemini_generate, gemini_model};
use crate::prompt::thought::thinking_level;

pub const MEMORY_EXTRACT_MAX_PER_TURN: usize = 2;
pub const MEMORY_EXTRACT_CONFIDENCE_MIN: f64 = 0.85;
const MEMORY_EXTRACT_MODEL: &str = "gemini-2.0-flash";

const EXTRACT_SYSTEM: &str = "Extract durable user facts and preferences only. Output JSON: {\"candidates\":[{\"category\":\"fact|preference|task\",\"key\":\"snake_case\",\"content\":\"…\",\"confidence\":0.0-1.0}]}. Skip greetings, weather, ephemeral trivia. Max 3 candidates.";

#[derive(Debug, Clone, Deserialize)]
pub struct MemoryCandidate {
    pub category: String,
    pub key: String,
    pub content: String,
    pub confidence: f64,
}

#[derive(Debug, Deserialize)]
struct MemoryExtractOut {
    candidates: Vec<MemoryCandidate>,
}

pub async fn memory_extract_apply(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    candidates: &[MemoryCandidate],
) -> Result<i32> {
    let mut writes = 0i32;
    for c in candidates.iter().take(MEMORY_EXTRACT_MAX_PER_TURN) {
        if c.confidence < MEMORY_EXTRACT_CONFIDENCE_MIN {
            continue;
        }
        let cat = c.category.trim().to_ascii_lowercase();
        if cat == "ephemeral" || c.key.trim().is_empty() || c.content.trim().is_empty() {
            continue;
        }
        memory_put(pool, owner_iid, bot_iid, c.key.trim(), c.content.trim(), &cat, source_req_id).await?;
        writes += 1;
    }
    Ok(writes)
}

async fn memory_extract_llm(transcript: &str) -> Result<(Vec<MemoryCandidate>, i32, i32, f64)> {
    let transcript = transcript.trim();
    if transcript.is_empty() {
        return Ok((vec![], 0, 0, 0.0));
    }
    let model = gemini_model(MEMORY_EXTRACT_MODEL);
    let contents = vec![json!({ "role": "user", "parts": [{ "text": transcript }] })];
    let out = gemini_generate(&contents, &json!([]), &thinking_level("off"), &model, EXTRACT_SYSTEM).await?;
    let cost = billing_cost_usd(MEMORY_EXTRACT_MODEL, out.in_tok, out.out_tok);
    let candidates = parse_memory_candidates(&out.text);
    Ok((candidates, out.in_tok, out.out_tok, cost))
}

fn parse_memory_candidates(text: &str) -> Vec<MemoryCandidate> {
    let t = text.trim();
    if let Ok(v) = serde_json::from_str::<MemoryExtractOut>(t) {
        return v.candidates;
    }
    if let Some(start) = t.find('{') {
        if let Some(end) = t.rfind('}') {
            if let Ok(v) = serde_json::from_str::<MemoryExtractOut>(&t[start..=end]) {
                return v.candidates;
            }
        }
    }
    vec![]
}

pub async fn memory_extract_batch(
    pool: &PgPool,
    _http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    transcript: &str,
) -> Result<(i32, i32, i32, f64)> {
    let (candidates, tin, tout, cost) = memory_extract_llm(transcript).await?;
    let writes = memory_extract_apply(pool, owner_iid, bot_iid, source_req_id, &candidates).await?;
    Ok((writes, tin, tout, cost))
}

pub async fn memory_extract_turn_gate(
    pool: &PgPool,
    _http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    user_text: &str,
    assistant_text: &str,
) -> Result<(i32, i32, i32, f64)> {
    if assistant_text.trim().len() < 50 {
        return Ok((0, 0, 0, 0.0));
    }
    let transcript = format!("User: {}\nAssistant: {}", user_text.trim(), assistant_text.trim());
    let (candidates, tin, tout, cost) = memory_extract_llm(&transcript).await?;
    let writes = memory_extract_apply(pool, owner_iid, bot_iid, source_req_id, &candidates).await?;
    Ok((writes, tin, tout, cost))
}

pub fn memory_extract_log_err(e: &anyhow::Error) {
    warn!("[c35:memory_extract] {e:#}");
}
