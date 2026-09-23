use base64::{engine::general_purpose::STANDARD, Engine as _};
use c35_mod_billing::{billing_cost_usd, billing_deduct};
use serde::Deserialize;
use sqlx::PgPool;

use super::types::{ExpenseDetectResult, ExpenseItem};

const PROMPT_TEXT: &str = r#"You are a personal expense assistant. Extract purchase line items from the description.
Output JSON object only:
{"subject":"","headline":"","payment_method":"cash","items":[{"name":"","name_id":"","qty":1,"price_minor":0,"total_minor":0,"obj_id":0}]}
subject = merchant/store name. headline = short friendly summary of what was bought.
payment_method: cash, card, transfer, qris, or wallet.
[AMOUNT INFERENCE] Infer realistic IDR minor units (integer rupiah, no decimals): small numbers for food/daily items mean thousands (18 → 18000, 6.5 → 6500), electronics/rent mean millions (18 → 18000000, 2.5 → 2500000). Suffixes k/rb = ×1,000, jt/m = ×1,000,000.
price_minor and total_minor are in IDR (rupiah). total_minor = price_minor × qty (rounded).
Default qty to 1. name_id in Bahasa Indonesia Title Case."#;

const PROMPT_PIC: &str = r#"You are a personal expense assistant. You are given a receipt or purchase photo.
Extract merchant, line items, and amounts. Output JSON object only:
{"subject":"","headline":"","payment_method":"cash","items":[{"name":"","name_id":"","qty":1,"price_minor":0,"total_minor":0,"obj_id":0}]}
[AMOUNT INFERENCE] Infer realistic IDR minor units: small numbers for food/daily items mean thousands (18 → 18000), electronics/rent mean millions (18 → 18000000). Suffixes k/rb = ×1,000, jt/m = ×1,000,000.
price_minor and total_minor are integer IDR rupiah. name_id in Bahasa Indonesia Title Case."#;

fn detect_model() -> Result<String, String> {
    if let Ok(raw) = std::env::var("GEMINI_MODEL") {
        let key = raw.trim();
        if key.is_empty() {
            return Err("GEMINI_MODEL empty".into());
        }
        return c35_mod_llm::catalog_provider_model(key)
            .ok_or_else(|| format!("unknown GEMINI_MODEL {key}"));
    }
    let model = c35_mod_llm::alien_default_model();
    if model.is_empty() {
        return Err("no catalog model for expense detect".into());
    }
    Ok(model)
}

fn gemini_api_key() -> String {
    ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
        .iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
        .trim()
        .to_string()
}

#[derive(Debug, Deserialize)]
struct LlmItem {
    #[serde(default)]
    name: String,
    #[serde(default)]
    name_id: String,
    #[serde(default)]
    qty: f64,
    #[serde(default)]
    price_minor: i64,
    #[serde(default)]
    total_minor: i64,
    #[serde(default)]
    obj_id: i64,
}

#[derive(Debug, Deserialize)]
struct LlmDetect {
    #[serde(default)]
    subject: String,
    #[serde(default)]
    headline: String,
    #[serde(default)]
    payment_method: String,
    #[serde(default)]
    items: Vec<LlmItem>,
}

pub async fn detect_text(pool: &PgPool, owner_iid: i64, text: &str) -> Result<ExpenseDetectResult, String> {
    let t = text.trim();
    if t.is_empty() {
        return Err("description required".into());
    }
    run_gemini_text(pool, owner_iid, &format!("{PROMPT_TEXT}\n\nDescription: {t}")).await
}

pub async fn detect_pic(
    pool: &PgPool,
    owner_iid: i64,
    image: &[u8],
    mime: &str,
    user_note: &str,
) -> Result<ExpenseDetectResult, String> {
    if image.is_empty() {
        return Err("image required".into());
    }
    let note = user_note.trim();
    let prompt = if note.is_empty() {
        PROMPT_PIC.to_string()
    } else {
        format!("{PROMPT_PIC}\n\nThe user also wrote: \"{note}\". Adjust items and amounts to match.")
    };
    run_gemini_vision(pool, owner_iid, image, mime, &prompt).await
}

fn usage_tokens(v: &serde_json::Value) -> (i32, i32) {
    let in_tok = v["usageMetadata"]["promptTokenCount"].as_i64().unwrap_or(0) as i32;
    let out_tok = v["usageMetadata"]["candidatesTokenCount"].as_i64().unwrap_or(0) as i32;
    (in_tok, out_tok)
}

async fn billing_charge(pool: &PgPool, owner_iid: i64, model: &str, in_tok: i32, out_tok: i32) -> Result<(), String> {
    let cost = billing_cost_usd(model, in_tok, out_tok);
    if cost > 0.0 {
        billing_deduct(pool, owner_iid, cost).await.map_err(|e| e.to_string())?;
    }
    Ok(())
}

fn detect_http_client() -> &'static reqwest::Client {
    static CLIENT: std::sync::OnceLock<reqwest::Client> = std::sync::OnceLock::new();
    CLIENT.get_or_init(|| {
        reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .unwrap_or_default()
    })
}

async fn run_gemini_text(pool: &PgPool, owner_iid: i64, prompt: &str) -> Result<ExpenseDetectResult, String> {
    let key = gemini_api_key();
    if key.is_empty() {
        return Err("GEMINI_API_KEY missing".into());
    }
    let model = detect_model()?;
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}");
    let body = serde_json::json!({
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2, "responseMimeType": "application/json"}
    });
    let client = detect_http_client();
    let resp = client.post(&url).json(&body).send().await.map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        let err_text = resp.text().await.unwrap_or_default();
        return Err(format!("Gemini API error ({status}): {err_text}"));
    }
    let v: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
    if let Some(err) = v.get("error") {
        let msg = err.get("message").and_then(|m| m.as_str()).unwrap_or("unknown Gemini error");
        return Err(format!("Gemini error: {msg}"));
    }
    let (in_tok, out_tok) = usage_tokens(&v);
    billing_charge(pool, owner_iid, &model, in_tok, out_tok).await?;
    parse_detect_response(&v)
}

async fn run_gemini_vision(
    pool: &PgPool,
    owner_iid: i64,
    image: &[u8],
    mime: &str,
    prompt: &str,
) -> Result<ExpenseDetectResult, String> {
    let key = gemini_api_key();
    if key.is_empty() {
        return Err("GEMINI_API_KEY missing".into());
    }
    let model = detect_model()?;
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}");
    let body = serde_json::json!({
        "contents": [{
            "role": "user",
            "parts": [
                {"inline_data": {"mime_type": mime, "data": STANDARD.encode(image)}},
                {"text": prompt}
            ]
        }],
        "generationConfig": {"temperature": 0.2, "responseMimeType": "application/json"}
    });
    let client = detect_http_client();
    let resp = client.post(&url).json(&body).send().await.map_err(|e| e.to_string())?;
    let status = resp.status();
    if !status.is_success() {
        let err_text = resp.text().await.unwrap_or_default();
        return Err(format!("Gemini API error ({status}): {err_text}"));
    }
    let v: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
    if let Some(err) = v.get("error") {
        let msg = err.get("message").and_then(|m| m.as_str()).unwrap_or("unknown Gemini error");
        return Err(format!("Gemini error: {msg}"));
    }
    let (in_tok, out_tok) = usage_tokens(&v);
    billing_charge(pool, owner_iid, &model, in_tok, out_tok).await?;
    parse_detect_response(&v)
}

fn parse_detect_response(v: &serde_json::Value) -> Result<ExpenseDetectResult, String> {
    let candidates = v.get("candidates").and_then(|c| c.as_array());
    if candidates.map(|c| c.is_empty()).unwrap_or(true) {
        if let Some(feedback) = v.get("promptFeedback") {
            return Err(format!("Gemini safety block: {feedback}"));
        }
        return Err("Gemini returned empty candidates".into());
    }
    let text_out = v["candidates"][0]["content"]["parts"][0]["text"].as_str().unwrap_or("{}");
    parse_detect(text_out)
}

fn parse_detect(raw: &str) -> Result<ExpenseDetectResult, String> {
    let parsed: LlmDetect = serde_json::from_str(raw).map_err(|e| format!("expense json: {e}"))?;
    if parsed.items.is_empty() {
        return Err("no expense items detected".into());
    }
    let items = parsed
        .items
        .into_iter()
        .filter_map(|i| {
            let name = i.name.trim();
            if name.is_empty() {
                return None;
            }
            let qty = i.qty.max(0.01) as f32;
            let price_minor = i.price_minor.max(0);
            let total_minor = if i.total_minor > 0 {
                i.total_minor
            } else {
                (price_minor as f64 * qty as f64).round() as i64
            };
            Some(ExpenseItem {
                name: name.to_string(),
                name_id: if i.name_id.trim().is_empty() { name.to_string() } else { i.name_id.trim().to_string() },
                qty,
                obj_id: i.obj_id,
                price_minor,
                total_minor,
            })
        })
        .collect::<Vec<_>>();
    if items.is_empty() {
        return Err("no expense items detected".into());
    }
    let payment_method = if parsed.payment_method.trim().is_empty() {
        "cash".into()
    } else {
        parsed.payment_method.trim().to_ascii_lowercase()
    };
    Ok(ExpenseDetectResult {
        subject: parsed.subject.trim().to_string(),
        headline: parsed.headline.trim().to_string(),
        payment_method,
        items,
    })
}
