use base64::{engine::general_purpose::STANDARD, Engine as _};
use c35_mod_billing::{billing_cost_usd, billing_deduct};
use serde::Deserialize;
use sqlx::PgPool;

use super::types::ConsumptionItem;

const PROMPT_TEXT: &str = r#"You are a nutrition expert. Extract food items from the description.
Output JSON ARRAY only:
[{"name":"","name_id":"","qty":1,"calories":0,"protein":0,"fat":0,"carbs":0,"fiber":0,"sugar":0,"sodium":0}]
Detect fractional portions: qty 0.5 for half/setengah, 0.25 for quarter. Nutrition per one full serving; qty scales consumption.
Use reasonable estimates. name_id in Bahasa Indonesia Title Case."#;

const PROMPT_PIC: &str = r#"You are a nutrition expert. You are given a picture of food or drinks.
Estimate portions (half plate → qty 0.5). Extract every distinct item. Output JSON ARRAY only:
[{"name":"","name_id":"","qty":1,"calories":0,"protein":0,"fat":0,"carbs":0,"fiber":0,"sugar":0,"sodium":0}]
Use reasonable estimates. name_id in Bahasa Indonesia Title Case."#;


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
        return Err("no catalog model for consumption detect".into());
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
    calories: f64,
    #[serde(default)]
    protein: f64,
    #[serde(default)]
    fat: f64,
    #[serde(default)]
    carbs: f64,
    #[serde(default)]
    fiber: f64,
    #[serde(default)]
    sugar: f64,
    #[serde(default)]
    sodium: f64,
}

pub async fn detect_text(pool: &PgPool, owner_iid: i64, text: &str) -> Result<Vec<ConsumptionItem>, String> {
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
) -> Result<Vec<ConsumptionItem>, String> {
    if image.is_empty() {
        return Err("image required".into());
    }
    let note = user_note.trim();
    let prompt = if note.is_empty() {
        PROMPT_PIC.to_string()
    } else {
        format!("{PROMPT_PIC}\n\nThe user also wrote: \"{note}\". Adjust qty and items to match what they consumed.")
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

async fn run_gemini_text(pool: &PgPool, owner_iid: i64, prompt: &str) -> Result<Vec<ConsumptionItem>, String> {
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
    let candidates = v.get("candidates").and_then(|c| c.as_array());
    if candidates.map(|c| c.is_empty()).unwrap_or(true) {
        if let Some(feedback) = v.get("promptFeedback") {
            return Err(format!("Gemini safety block: {feedback}"));
        }
        return Err("Gemini returned empty candidates".into());
    }
    let text_out = v["candidates"][0]["content"]["parts"][0]["text"].as_str().unwrap_or("[]");
    parse_items(text_out)
}

async fn run_gemini_vision(
    pool: &PgPool,
    owner_iid: i64,
    image: &[u8],
    mime: &str,
    prompt: &str,
) -> Result<Vec<ConsumptionItem>, String> {
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
    let candidates = v.get("candidates").and_then(|c| c.as_array());
    if candidates.map(|c| c.is_empty()).unwrap_or(true) {
        if let Some(feedback) = v.get("promptFeedback") {
            return Err(format!("Gemini safety block: {feedback}"));
        }
        return Err("Gemini returned empty candidates".into());
    }
    let text_out = v["candidates"][0]["content"]["parts"][0]["text"].as_str().unwrap_or("[]");
    parse_items(text_out)
}

fn parse_items(raw: &str) -> Result<Vec<ConsumptionItem>, String> {
    let items: Vec<LlmItem> = serde_json::from_str(raw).map_err(|e| format!("food json: {e}"))?;
    if items.is_empty() {
        return Err("no food items detected".into());
    }
    Ok(items
        .into_iter()
        .filter_map(|i| {
            let name = i.name.trim();
            if name.is_empty() {
                return None;
            }
            Some(ConsumptionItem {
                name: name.to_string(),
                name_id: if i.name_id.trim().is_empty() { name.to_string() } else { i.name_id.trim().to_string() },
                qty: i.qty as f32,
                calories: i.calories.round() as i32,
                protein: i.protein.round() as i32,
                fat: i.fat.round() as i32,
                carbs: i.carbs.round() as i32,
                fiber: i.fiber.round() as i32,
                sugar: i.sugar.round() as i32,
                sodium: i.sodium.round() as i32,
            })
        })
        .collect())
}

pub fn items_from_json(v: &serde_json::Value) -> Result<Vec<ConsumptionItem>, String> {
    let arr = v.as_array().ok_or_else(|| "items_json must be array".to_string())?;
    let mut out = Vec::new();
    for item in arr {
        let name = item.get("name").and_then(|x| x.as_str()).unwrap_or("").trim();
        if name.is_empty() {
            continue;
        }
        out.push(ConsumptionItem {
            name: name.to_string(),
            name_id: item.get("name_id").and_then(|x| x.as_str()).unwrap_or(name).to_string(),
            qty: item.get("qty").and_then(|x| x.as_f64()).unwrap_or(1.0) as f32,
            calories: item.get("calories").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
            protein: item.get("protein").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
            fat: item.get("fat").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
            carbs: item.get("carbs").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
            fiber: item.get("fiber").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
            sugar: item.get("sugar").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
            sodium: item.get("sodium").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        });
    }
    if out.is_empty() {
        return Err("no items".into());
    }
    Ok(out)
}
