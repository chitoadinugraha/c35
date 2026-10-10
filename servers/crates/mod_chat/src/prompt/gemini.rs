use std::sync::OnceLock;
use std::time::Duration;

use anyhow::Result;
use futures_util::StreamExt;
use reqwest::Client;
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use super::thought::{gemini_thinking_config, parse_candidate, part_is_thought, part_thought_text};
use c35_mod_llm::{
    alien_default_model, gemini_request_reject_provider_grounding, google_gemini_api_model_id,
    model_is_alien, provider_model_resolve,
};

/// Sampling for Gemini chat. Frontier (pinned models) keeps legacy 0.2 / 2048; Alien pool only is warmer.
pub fn gemini_generation_config(
    requested_slug: &str,
    provider_model: &str,
    thinking: &str,
) -> Value {
    let alien = model_is_alien(requested_slug);
    let temperature = if alien { 0.65 } else { 0.2 };
    let max_output_tokens = 2048;
    json!({
        "maxOutputTokens": max_output_tokens,
        "temperature": temperature,
        "thinkingConfig": gemini_thinking_config(provider_model, thinking),
    })
}

fn gemini_http() -> &'static Client {
    static CLIENT: OnceLock<Client> = OnceLock::new();
    CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(Duration::from_secs(180))
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
    let resolved = provider_model_resolve(model).unwrap_or_else(alien_default_model);
    google_gemini_api_model_id(&resolved)
}

pub async fn gemini_generate(
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    provider_model: &str,
    requested_slug: &str,
    system: &str,
    tool_call_mode: &str,
) -> Result<super::thought::ParseOut> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let mut body = json!({
        "contents": contents,
        "generationConfig": gemini_generation_config(requested_slug, provider_model, thinking),
    });
    if !system.trim().is_empty() {
        body["systemInstruction"] = json!({ "parts": [{ "text": system }] });
    }
    if !tools.is_null()
        && tools.as_array().map(|a| !a.is_empty()).unwrap_or(true)
        && tools != &json!([])
    {
        body["tools"] = tools.clone();
        let mode = if tool_call_mode.trim().is_empty() {
            "AUTO"
        } else {
            tool_call_mode.trim()
        };
        body["toolConfig"] = json!({ "functionCallingConfig": { "mode": mode } });
    }
    gemini_request_reject_provider_grounding(&body)?;
    let api_model = google_gemini_api_model_id(provider_model);
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{api_model}:generateContent?key={key}");
    let resp = gemini_http().post(&url).json(&body).send().await?;
    if !resp.status().is_success() {
        let status = resp.status();
        let err_body = resp.text().await.unwrap_or_default();
        anyhow::bail!("gemini HTTP {status}: {err_body}");
    }
    let v: Value = resp.json().await?;
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
    let parts = v["candidates"][0]["content"]["parts"]
        .as_array()
        .cloned()
        .unwrap_or_default();
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
    provider_model: &str,
    requested_slug: &str,
    system: &str,
    tool_call_mode: &str,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    cancel: &CancellationToken,
) -> Result<super::thought::ParseOut> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY missing");
    }
    let mut body = json!({
        "contents": contents,
        "generationConfig": gemini_generation_config(requested_slug, provider_model, thinking),
    });
    if !system.trim().is_empty() {
        body["systemInstruction"] = json!({ "parts": [{ "text": system }] });
    }
    if !tools.is_null()
        && tools.as_array().map(|a| !a.is_empty()).unwrap_or(true)
        && tools != &json!([])
    {
        body["tools"] = tools.clone();
        let mode = if tool_call_mode.trim().is_empty() {
            "AUTO"
        } else {
            tool_call_mode.trim()
        };
        body["toolConfig"] = json!({ "functionCallingConfig": { "mode": mode } });
    }
    gemini_request_reject_provider_grounding(&body)?;
    let api_model = google_gemini_api_model_id(provider_model);
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{api_model}:streamGenerateContent?alt=sse&key={key}");
    let resp = gemini_http().post(&url).json(&body).send().await?;
    if !resp.status().is_success() {
        let status = resp.status();
        let err_body = resp.text().await.unwrap_or_default();
        anyhow::bail!("gemini HTTP {status}: {err_body}");
    }
    let mut stream = resp.bytes_stream();
    let mut buf = String::new();
    let mut last = json!({});
    let mut acc_content = json!(null);
    let mut acc_text = String::new();
    let mut acc_thought = String::new();
    loop {
        if cancel.is_cancelled() {
            anyhow::bail!("aborted");
        }
        let chunk_opt = match tokio::time::timeout(Duration::from_secs(45), stream.next()).await {
            Ok(c) => c,
            Err(_) => anyhow::bail!("gemini stream timed out waiting for chunks"),
        };
        let Some(chunk) = chunk_opt else { break };
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
                        anyhow::bail!(
                            "{}",
                            v["error"]["message"]
                                .as_str()
                                .unwrap_or("gemini stream failed")
                        );
                    }
                    gemini_stream_emit(&v, on_delta, &mut acc_text, &mut acc_thought);
                    gemini_stream_acc_content(&mut acc_content, &v);
                    last = v;
                }
            }
        }
    }
    Ok(gemini_stream_finalize(
        &last,
        &acc_content,
        &acc_text,
        &acc_thought,
    ))
}

fn gemini_stream_acc_content(acc: &mut Value, v: &Value) {
    let content = v["candidates"][0]["content"].clone();
    if content.is_null() {
        return;
    }
    if acc.is_null() {
        *acc = content;
        return;
    }
    let Some(new_parts) = content["parts"].as_array() else {
        return;
    };
    if acc.get("parts").and_then(|p| p.as_array()).is_none() {
        acc["parts"] = json!([]);
    }
    let parts = acc["parts"].as_array_mut().expect("parts array");
    for part in new_parts {
        if part.get("functionCall").is_some() {
            // Parallel calls arrive as separate stream chunks. Keep each one.
            // A repeated id is an update of the same call, not a new product.
            let new_id = part
                .get("functionCall")
                .and_then(|fc| fc.get("id"))
                .and_then(|v| v.as_str())
                .unwrap_or("");
            if !new_id.is_empty() {
                if let Some(last) = parts.last_mut() {
                    let last_id = last
                        .get("functionCall")
                        .and_then(|fc| fc.get("id"))
                        .and_then(|v| v.as_str())
                        .unwrap_or("");
                    if last_id == new_id {
                        *last = part.clone();
                        continue;
                    }
                }
            }
            parts.push(part.clone());
            continue;
        }
        if part.get("thoughtSignature").is_some() {
            if let Some(last_fc) = parts
                .iter_mut()
                .rev()
                .find(|p| p.get("functionCall").is_some())
            {
                if let Some(sig) = part.get("thoughtSignature") {
                    last_fc["thoughtSignature"] = sig.clone();
                }
            }
            continue;
        }
        if part_is_thought(part) {
            parts.push(part.clone());
            continue;
        }
        if let Some(t) = part["text"].as_str().filter(|s| !s.is_empty()) {
            if let Some(last_text) = parts
                .iter_mut()
                .rev()
                .find(|p| p.get("text").is_some() && !part_is_thought(p))
            {
                let merged = format!("{}{}", last_text["text"].as_str().unwrap_or(""), t);
                last_text["text"] = json!(merged);
            } else {
                parts.push(part.clone());
            }
        }
    }
    if content.get("role").and_then(|r| r.as_str()).is_some() {
        acc["role"] = content["role"].clone();
    }
}

fn gemini_stream_finalize(
    last: &Value,
    acc_content: &Value,
    acc_text: &str,
    acc_thought: &str,
) -> super::thought::ParseOut {
    let parsed = if !acc_content.is_null() {
        let mut wrap = last.clone();
        if wrap["candidates"].is_null()
            || wrap["candidates"]
                .as_array()
                .map(|a| a.is_empty())
                .unwrap_or(true)
        {
            wrap = json!({ "candidates": [{}], "usageMetadata": last.get("usageMetadata").cloned().unwrap_or(json!({})) });
        }
        wrap["candidates"][0]["content"] = acc_content.clone();
        parse_candidate(&wrap)
    } else {
        parse_candidate(last)
    };
    super::thought::ParseOut {
        text: if acc_text.is_empty() {
            parsed.text
        } else {
            acc_text.to_string()
        },
        thought: if acc_thought.is_empty() {
            parsed.thought
        } else {
            acc_thought.to_string()
        },
        function_call: parsed.function_call,
        function_calls: parsed.function_calls,
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
    fn stream_acc_keeps_parallel_function_calls() {
        let mut acc = json!(null);
        let first = json!({
            "candidates": [{
                "content": {
                    "role": "model",
                    "parts": [{
                        "functionCall": {
                            "name": "site_product_put",
                            "args": { "name": "Caffe Americano", "price": 33000 }
                        }
                    }]
                }
            }]
        });
        let second = json!({
            "candidates": [{
                "content": {
                    "role": "model",
                    "parts": [{
                        "functionCall": {
                            "name": "site_product_put",
                            "args": { "name": "Mineral Water", "price": 10000 }
                        },
                        "thoughtSignature": "sig"
                    }]
                }
            }]
        });
        gemini_stream_acc_content(&mut acc, &first);
        gemini_stream_acc_content(&mut acc, &second);
        let parts = acc["parts"].as_array().unwrap();
        assert_eq!(parts.len(), 2);
        assert_eq!(parts[0]["functionCall"]["args"]["name"], "Caffe Americano");
        assert_eq!(parts[0]["functionCall"]["args"]["price"], 33000);
        assert_eq!(parts[1]["functionCall"]["args"]["name"], "Mineral Water");
        assert_eq!(parts[1]["functionCall"]["args"]["price"], 10000);
        assert_eq!(parts[1]["thoughtSignature"], "sig");
    }

    #[test]
    fn stream_emit_accumulates_text_before_empty_final_chunk() {
        let mut acc_text = String::new();
        let mut acc_thought = String::new();
        let mut noop = |_thought: bool, _text: String| {};
        let chunk1 =
            json!({"candidates":[{"content":{"parts":[{"text":"Sekarang hari Senin."}]}}]});
        let chunk2 =
            json!({"candidates":[{"content":{"parts":[{"text":"","thoughtSignature":"sig"}]}}]});
        gemini_stream_emit(&chunk1, &mut noop, &mut acc_text, &mut acc_thought);
        gemini_stream_emit(&chunk2, &mut noop, &mut acc_text, &mut acc_thought);
        assert_eq!(acc_text, "Sekarang hari Senin.");
        let out = gemini_stream_finalize(&chunk2, &json!(null), &acc_text, &acc_thought);
        assert_eq!(out.text, "Sekarang hari Senin.");
    }

    #[test]
    fn stream_finalize_without_accumulation_reads_empty_final_chunk() {
        let chunk2 =
            json!({"candidates":[{"content":{"parts":[{"text":"","thoughtSignature":"sig"}]}}]});
        let out = gemini_stream_finalize(&chunk2, &json!(null), "", "");
        assert!(out.text.is_empty());
    }

    #[test]
    fn sse_take_block_handles_crlf_delimiter() {
        let mut buf = "data: {}\r\n\r\ndata: {\"ok\":true}".to_string();
        let first = gemini_sse_take_block(&mut buf).expect("first block");
        assert_eq!(first, "data: {}");
        assert_eq!(buf, "data: {\"ok\":true}");
    }

    #[test]
    fn generation_config_alien_warmer_than_frontier() {
        let alien = gemini_generation_config("alienai", "gemini-3.1-flash-lite", "off");
        let frontier =
            gemini_generation_config("gemini-3.1-flash-lite", "gemini-3.1-flash-lite", "off");
        assert_eq!(alien["temperature"], 0.65);
        assert_eq!(frontier["temperature"], 0.2);
    }
}
