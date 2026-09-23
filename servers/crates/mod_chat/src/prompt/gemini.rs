use std::sync::OnceLock;
use std::time::Duration;

use anyhow::Result;
use futures_util::StreamExt;
use reqwest::Client;
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use c35_mod_llm::{alien_default_model, provider_model_resolve};
use super::thought::{gemini_thinking_config, parse_candidate, part_is_thought, part_thought_text};

fn gemini_http() -> &'static Client {
    static CLIENT: OnceLock<Client> = OnceLock::new();
    CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(Duration::from_secs(60))
            .build()
            .unwrap_or_else(|_| Client::new())
    })
}

pub fn gemini_api_key() -> String {
    ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
        .iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
        .trim()
        .to_string()
}

pub fn gemini_model(model: &str) -> String {
    provider_model_resolve(model).unwrap_or_else(alien_default_model)
}

pub async fn gemini_generate(
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    model: &str,
    system: &str,
) -> Result<super::thought::ParseOut> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let mut body = json!({
        "contents": contents,
        "generationConfig": { "maxOutputTokens": 2048, "temperature": 0.2, "thinkingConfig": gemini_thinking_config(model, thinking) }
    });
    if !system.trim().is_empty() {
        body["systemInstruction"] = json!({ "parts": [{ "text": system }] });
    }
    if !tools.is_null() && tools.as_array().map(|a| !a.is_empty()).unwrap_or(true) && tools != &json!([]) {
        body["tools"] = tools.clone();
        body["toolConfig"] = json!({ "functionCallingConfig": { "mode": "AUTO" } });
    }
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}");
    let v: Value = gemini_http().post(&url).json(&body).send().await?.error_for_status()?.json().await?;
    gemini_response_check(&v)?;
    Ok(parse_candidate(&v))
}

fn gemini_response_check(v: &Value) -> Result<()> {
    if let Some(err) = v.get("error") {
        let msg = err["message"].as_str().unwrap_or("gemini request failed");
        anyhow::bail!("{msg}");
    }
    Ok(())
}

fn gemini_sse_take_block(buf: &mut String) -> Option<String> {
    if let Some(pos) = buf.find("\r\n\r\n") {
        let block = buf[..pos].to_string();
        *buf = buf[pos + 4..].to_string();
        return Some(block);
    }
    if let Some(pos) = buf.find("\n\n") {
        let block = buf[..pos].to_string();
        *buf = buf[pos + 2..].to_string();
        return Some(block);
    }
    None
}

fn gemini_stream_emit(
    v: &Value,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    acc_text: &mut String,
    acc_thought: &mut String,
) {
    let parts = v["candidates"][0]["content"]["parts"].as_array().cloned().unwrap_or_default();
    for part in parts {
        if part_is_thought(&part) {
            if let Some(t) = part_thought_text(&part) {
                if !t.is_empty() {
                    acc_thought.push_str(t);
                    on_delta(true, t.to_string());
                }
            }
            continue;
        }
        if let Some(t) = part["text"].as_str() {
            if !t.is_empty() {
                acc_text.push_str(t);
                on_delta(false, t.to_string());
            }
        }
    }
}

pub async fn gemini_generate_stream(
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    model: &str,
    system: &str,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    cancel: &CancellationToken,
) -> Result<super::thought::ParseOut> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let mut body = json!({
        "contents": contents,
        "generationConfig": { "maxOutputTokens": 2048, "temperature": 0.2, "thinkingConfig": gemini_thinking_config(model, thinking) }
    });
    if !system.trim().is_empty() {
        body["systemInstruction"] = json!({ "parts": [{ "text": system }] });
    }
    if !tools.is_null() && tools.as_array().map(|a| !a.is_empty()).unwrap_or(true) && tools != &json!([]) {
        body["tools"] = tools.clone();
        body["toolConfig"] = json!({ "functionCallingConfig": { "mode": "AUTO" } });
    }
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse&key={key}");
    let mut stream = gemini_http().post(&url).json(&body).send().await?.error_for_status()?.bytes_stream();
    let mut buf = String::new();
    let mut last = json!({});
    let mut acc_text = String::new();
    let mut acc_thought = String::new();
    while let Some(chunk) = stream.next().await {
        if cancel.is_cancelled() {
            anyhow::bail!("aborted");
        }
        buf.push_str(&String::from_utf8_lossy(&chunk?));
        while let Some(block) = gemini_sse_take_block(&mut buf) {
            for line in block.lines() {
                let line = line.trim();
                if !line.starts_with("data: ") {
                    continue;
                }
                let payload = line[6..].trim();
                if payload.is_empty() || payload == "[DONE]" {
                    continue;
                }
                if let Ok(v) = serde_json::from_str::<Value>(payload) {
                    if gemini_response_check(&v).is_err() {
                        anyhow::bail!("{}", v["error"]["message"].as_str().unwrap_or("gemini stream failed"));
                    }
                    gemini_stream_emit(&v, on_delta, &mut acc_text, &mut acc_thought);
                    last = v;
                }
            }
        }
    }
    Ok(gemini_stream_finalize(&last, &acc_text, &acc_thought))
}

fn gemini_stream_finalize(last: &Value, acc_text: &str, acc_thought: &str) -> super::thought::ParseOut {
    let parsed = parse_candidate(last);
    super::thought::ParseOut {
        text: if acc_text.is_empty() { parsed.text } else { acc_text.to_string() },
        thought: if acc_thought.is_empty() { parsed.thought } else { acc_thought.to_string() },
        function_call: parsed.function_call,
        in_tok: parsed.in_tok,
        out_tok: parsed.out_tok,
        model_content: parsed.model_content,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn stream_emit_accumulates_text_before_empty_final_chunk() {
        let mut acc_text = String::new();
        let mut acc_thought = String::new();
        let mut noop = |_thought: bool, _text: String| {};
        let chunk1 = json!({"candidates":[{"content":{"parts":[{"text":"Sekarang hari Senin."}]}}]});
        let chunk2 = json!({"candidates":[{"content":{"parts":[{"text":"","thoughtSignature":"sig"}]}}]});
        gemini_stream_emit(&chunk1, &mut noop, &mut acc_text, &mut acc_thought);
        gemini_stream_emit(&chunk2, &mut noop, &mut acc_text, &mut acc_thought);
        assert_eq!(acc_text, "Sekarang hari Senin.");
        let out = gemini_stream_finalize(&chunk2, &acc_text, &acc_thought);
        assert_eq!(out.text, "Sekarang hari Senin.");
    }

    #[test]
    fn stream_finalize_without_accumulation_reads_empty_final_chunk() {
        let chunk2 = json!({"candidates":[{"content":{"parts":[{"text":"","thoughtSignature":"sig"}]}}]});
        let out = gemini_stream_finalize(&chunk2, "", "");
        assert!(out.text.is_empty());
    }

    #[test]
    fn sse_take_block_handles_crlf_delimiter() {
        let mut buf = "data: {}\r\n\r\ndata: {\"ok\":true}".to_string();
        let first = gemini_sse_take_block(&mut buf).expect("first block");
        assert_eq!(first, "data: {}");
        assert_eq!(buf, "data: {\"ok\":true}");
    }
}
