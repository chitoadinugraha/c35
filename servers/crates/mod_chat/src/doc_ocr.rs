//! Gemini page OCR for `doc.extract`. Usage is folded into the turn bill.

use std::time::Duration;

use anyhow::{anyhow, Result};
use base64::Engine;
use reqwest::Client;
use serde_json::Value;

use crate::context_billing::ContextBillingExtra;

pub const DOC_OCR_MAX_PAGES: usize = 4;
const OCR_USER_TEXT: &str = "Transcribe the document page. Return only the text.";

/// Gate must succeed before any OCR HTTP call. A failed gate bills nothing.
pub fn ocr_charge_allowed(gate_ok: bool) -> bool {
    gate_ok
}

pub struct OcrUsage {
    pub text: String,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
}

pub fn ocr_usage_from_response(v: &Value) -> Option<OcrUsage> {
    if v.get("error").is_some() {
        return None;
    }
    let text = gemini_candidate_text(v);
    if text.trim().is_empty() {
        return None;
    }
    let tokens_in = usage_count(v, "promptTokenCount");
    let tokens_out = usage_count(v, "candidatesTokenCount");
    let cost_usd =
        c35_mod_billing::billing_cost_usd(c35_mod_llm::CHEAP_MODEL, tokens_in, tokens_out);
    Some(OcrUsage {
        text: text.trim().to_string(),
        tokens_in,
        tokens_out,
        cost_usd,
    })
}

pub fn apply_ocr_charge(slot: &std::sync::Mutex<ContextBillingExtra>, usage: &OcrUsage) {
    let Ok(mut extra) = slot.lock() else {
        return;
    };
    extra.doc_ocr_cost_usd += usage.cost_usd;
    extra.doc_ocr_tokens_in += usage.tokens_in;
    extra.doc_ocr_tokens_out += usage.tokens_out;
    extra.doc_ocr_pages += 1;
}

/// POST one page image to Gemini. Caller has already passed `billing_gate_scoped`.
pub async fn ocr_jpeg(client: &Client, jpeg: &[u8]) -> Result<OcrUsage> {
    let key = crate::prompt::gemini::gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let data = base64::engine::general_purpose::STANDARD.encode(jpeg);
    let body = serde_json::json!({
        "contents": [{
            "role": "user",
            "parts": [
                {"inlineData": {"mimeType": "image/jpeg", "data": data}},
                {"text": OCR_USER_TEXT}
            ]
        }]
    });
    c35_mod_llm::gemini_request_reject_provider_grounding(&body)?;
    let model = c35_mod_llm::google_gemini_api_model_id(c35_mod_llm::CHEAP_MODEL);
    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    );
    let resp = client
        .post(&url)
        .timeout(Duration::from_secs(30))
        .json(&body)
        .send()
        .await?;
    if !resp.status().is_success() {
        anyhow::bail!("gemini HTTP {}", resp.status());
    }
    let v: Value = resp
        .json()
        .await
        .map_err(|e| anyhow!("gemini OCR parse: {e}"))?;
    ocr_usage_from_response(&v).ok_or_else(|| anyhow!("gemini OCR response empty"))
}

fn gemini_candidate_text(v: &Value) -> String {
    let Some(parts) = v["candidates"][0]["content"]["parts"].as_array() else {
        return String::new();
    };
    let mut out = String::new();
    for part in parts {
        if let Some(text) = part.get("text").and_then(|t| t.as_str()) {
            if !out.is_empty() && !text.is_empty() {
                out.push('\n');
            }
            out.push_str(text);
        }
    }
    out
}

fn usage_count(v: &Value, key: &str) -> i32 {
    let Some(n) = v.get("usageMetadata").and_then(|u| u.get(key)) else {
        return 0;
    };
    let raw = n
        .as_i64()
        .or_else(|| n.as_u64().and_then(|u| i64::try_from(u).ok()))
        .unwrap_or(0);
    i32::try_from(raw.max(0)).unwrap_or(i32::MAX)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn doc_ocr_charge_allowed_false_when_gate_failed() {
        assert!(!ocr_charge_allowed(false));
        assert!(ocr_charge_allowed(true));
    }

    #[test]
    fn doc_ocr_cheap_model_cost_is_positive() {
        let cost = c35_mod_billing::billing_cost_usd(c35_mod_llm::CHEAP_MODEL, 1000, 100);
        assert!(cost > 0.0);
    }

    #[test]
    fn doc_ocr_missing_usage_is_zero_and_empty_text_is_not_charged() {
        let empty = serde_json::json!({
            "candidates": [{"content": {"parts": [{"text": "  "}]}}],
            "usageMetadata": {"promptTokenCount": 10, "candidatesTokenCount": 2}
        });
        assert!(ocr_usage_from_response(&empty).is_none());
        let ok = serde_json::json!({
            "candidates": [{"content": {"parts": [{"text": "Hello page"}]}}]
        });
        let usage = ocr_usage_from_response(&ok).expect("text");
        assert_eq!(usage.text, "Hello page");
        assert_eq!(usage.tokens_in, 0);
        assert_eq!(usage.tokens_out, 0);
    }
}
