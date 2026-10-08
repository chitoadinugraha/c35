use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use reqwest::Client;
use serde::Deserialize;
use serde_json::json;
use sqlx::PgPool;
use tracing::warn;

use crate::memory::{memory_delete, memory_list_active, memory_put};
use crate::prompt::gemini::{gemini_generate, gemini_model};
use crate::prompt::thought::thinking_level;

pub const MEMORY_EXTRACT_MAX_PER_TURN: usize = 3;
pub const MEMORY_EXTRACT_CONFIDENCE_MIN: f64 = 0.85;
const MEMORY_EXTRACT_MODEL: &str = c35_mod_llm::CHEAP_MODEL;

const EXTRACT_SYSTEM: &str = r#"You are the memory manager for Alien AI.
Your job is to identify durable facts about the user and durable preferences, or explicit retractions.

Categories:
- "identity": user's personal details (e.g. name, location, profession, timezone).
- "preference": long-term preferences, habits, styles (e.g. dietary restrictions, currency, UI mode, communication style).
- "fact": durable project, business, or life facts (e.g. vehicle model, pet name, company name).
- "task": open long-term goals or ongoing tasks.
- "ephemeral": transient remarks, greetings, weather, temporary questions (NEVER save).

Operations:
- "add": a new fact or preference.
- "update": updating or correcting a previously known fact.
- "delete": the user explicitly said to forget or contradicted an existing memory (e.g. "I'm no longer vegan", "forget my city").

Guidelines:
- Keys must be concise snake_case nouns (e.g. "user_name", "diet_preference", "default_currency", "job_title").
- Content must be concise, factual summary (e.g. "Alice", "vegetarian", "IDR", "software engineer").
- If there are no durable facts to extract, return {"actions":[]}.
- Do NOT extract assistant statements, bot instructions, or one-off questions.
- Max 3 actions per turn.

Output strict JSON:
{
  "actions": [
    {
      "op": "add|update|delete",
      "category": "identity|preference|fact|task",
      "key": "snake_case_key",
      "content": "concise description (empty for delete)",
      "confidence": 0.85-1.0
    }
  ]
}"#;

#[derive(Debug, Clone, Deserialize)]
pub struct MemoryAction {
    #[serde(default = "default_op")]
    pub op: String,
    #[serde(default)]
    pub category: String,
    pub key: String,
    #[serde(default)]
    pub content: String,
    pub confidence: f64,
}

fn default_op() -> String {
    "add".into()
}

#[derive(Debug, Deserialize)]
struct MemoryExtractOut {
    #[serde(default)]
    actions: Vec<MemoryAction>,
    #[serde(default)]
    candidates: Vec<MemoryAction>,
}

pub async fn memory_extract_apply(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    actions: &[MemoryAction],
) -> Result<i32> {
    let mut writes = 0i32;
    for c in actions.iter().take(MEMORY_EXTRACT_MAX_PER_TURN) {
        if c.confidence < MEMORY_EXTRACT_CONFIDENCE_MIN {
            continue;
        }
        let op = c.op.trim().to_ascii_lowercase();
        let key = c.key.trim();
        if key.is_empty() {
            continue;
        }
        if op == "delete" {
            if c.confidence >= 0.85 {
                let deleted = memory_delete(pool, owner_iid, bot_iid, key).await?;
                if deleted {
                    writes += 1;
                }
            }
            continue;
        }
        let cat = c.category.trim().to_ascii_lowercase();
        if cat == "ephemeral" || c.content.trim().is_empty() {
            continue;
        }
        memory_put(
            pool,
            owner_iid,
            bot_iid,
            key,
            c.content.trim(),
            &cat,
            source_req_id,
        )
        .await?;
        writes += 1;
    }
    Ok(writes)
}

async fn memory_extract_llm(
    transcript: &str,
    existing: &[(String, String)],
) -> Result<(Vec<MemoryAction>, i32, i32, f64)> {
    let transcript = transcript.trim();
    if transcript.is_empty() {
        return Ok((vec![], 0, 0, 0.0));
    }
    let model = gemini_model(MEMORY_EXTRACT_MODEL);

    let user_prompt = if existing.is_empty() {
        format!("Transcript:\n{transcript}")
    } else {
        let mem_lines: Vec<String> = existing
            .iter()
            .map(|(k, c)| format!("- {k}: {c}"))
            .collect();
        format!(
            "Known memories for this user:\n{}\n\nTranscript:\n{transcript}",
            mem_lines.join("\n")
        )
    };

    let contents = vec![json!({ "role": "user", "parts": [{ "text": user_prompt }] })];
    let out = gemini_generate(
        &contents,
        &json!([]),
        &thinking_level("off"),
        &model,
        MEMORY_EXTRACT_MODEL,
        EXTRACT_SYSTEM,
        "AUTO",
    )
    .await?;
    let cost = billing_cost_usd(&model, out.in_tok, out.out_tok);
    let actions = parse_memory_actions(&out.text);
    Ok((actions, out.in_tok, out.out_tok, cost))
}

fn parse_memory_actions(text: &str) -> Vec<MemoryAction> {
    let t = text.trim();
    if let Ok(v) = serde_json::from_str::<MemoryExtractOut>(t) {
        if !v.actions.is_empty() {
            return v.actions;
        }
        if !v.candidates.is_empty() {
            return v.candidates;
        }
    }
    if let Some(start) = t.find('{') {
        if let Some(end) = t.rfind('}') {
            if let Ok(v) = serde_json::from_str::<MemoryExtractOut>(&t[start..=end]) {
                if !v.actions.is_empty() {
                    return v.actions;
                }
                if !v.candidates.is_empty() {
                    return v.candidates;
                }
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
    let existing = memory_list_active(pool, owner_iid, bot_iid, 10)
        .await
        .unwrap_or_default();
    let (actions, tin, tout, cost) = memory_extract_llm(transcript, &existing).await?;
    let writes = memory_extract_apply(pool, owner_iid, bot_iid, source_req_id, &actions).await?;
    Ok((writes, tin, tout, cost))
}

pub fn memory_extract_should_skip(user_text: &str) -> bool {
    let t = user_text.trim();
    if t.is_empty() {
        return true;
    }
    if crate::prompt::time::user_asks_time(t) {
        return true;
    }
    let lower = t.to_ascii_lowercase();
    const EPHEMERAL_EXACT: &[&str] = &[
        "hi",
        "hello",
        "halo",
        "hai",
        "hey",
        "p",
        "test",
        "ping",
        "ok",
        "oke",
        "okay",
        "thanks",
        "terima kasih",
        "makasih",
        "siap",
        "yes",
        "ya",
        "no",
        "tidak",
        "gak",
        "nggak",
        "bye",
        "good morning",
        "selamat pagi",
        "selamat siang",
        "selamat sore",
        "selamat malam",
    ];
    if EPHEMERAL_EXACT.iter().any(|&e| lower == e) {
        return true;
    }
    false
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
    if assistant_text.trim().is_empty()
        || user_text.trim().is_empty()
        || memory_extract_should_skip(user_text)
    {
        return Ok((0, 0, 0, 0.0));
    }
    let transcript = format!(
        "User: {}\nAssistant: {}",
        user_text.trim(),
        assistant_text.trim()
    );
    let existing = memory_list_active(pool, owner_iid, bot_iid, 8)
        .await
        .unwrap_or_default();
    let (actions, tin, tout, cost) = memory_extract_llm(&transcript, &existing).await?;
    let writes = memory_extract_apply(pool, owner_iid, bot_iid, source_req_id, &actions).await?;
    Ok((writes, tin, tout, cost))
}

pub fn memory_extract_log_err(e: &anyhow::Error) {
    warn!("[c35:memory_extract] {e:#}");
}
