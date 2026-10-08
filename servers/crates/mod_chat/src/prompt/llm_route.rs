use std::time::Duration;

use anyhow::Result;
use c35_mod_llm::{cf_chat_generate, model_chain_for_slug, model_is_alien, model_log_label};
use reqwest::Client;
use serde_json::Value;
use tokio_util::sync::CancellationToken;

use super::gemini::{gemini_generate, gemini_generate_stream};
use super::thought::ParseOut;
use crate::tools::http_client;

fn llm_stream_uses_gemini(provider: &str) -> bool {
    provider == "google"
}

fn stream_contents_user(contents: &[Value]) -> String {
    for c in contents.iter().rev() {
        if c.get("role").and_then(|r| r.as_str()) != Some("user") {
            continue;
        }
        let mut text = String::new();
        if let Some(parts) = c["parts"].as_array() {
            for p in parts {
                if let Some(t) = p["text"].as_str() {
                    if !t.is_empty() {
                        if !text.is_empty() {
                            text.push('\n');
                        }
                        text.push_str(t);
                    }
                }
            }
        }
        return text;
    }
    String::new()
}

fn cf_stream_parse_out(text: String, tin: i32, tout: i32) -> ParseOut {
    ParseOut {
        text: text.clone(),
        thought: String::new(),
        in_tok: tin,
        out_tok: tout,
        function_call: None,
        function_calls: Vec::new(),
        model_content: serde_json::json!({ "role": "model", "parts": [{ "text": text }] }),
    }
}

fn parse_out_ready(out: &ParseOut) -> bool {
    !out.text.trim().is_empty() || out.function_call.is_some() || !out.function_calls.is_empty()
}

fn parse_out_promote_thought(mut out: ParseOut) -> ParseOut {
    if out.text.trim().is_empty() && !out.thought.trim().is_empty() {
        out.text = out.thought.trim().to_string();
        out.thought.clear();
    }
    out
}

pub fn bill_model_slug(requested: &str) -> String {
    model_log_label(requested)
}

pub async fn llm_generate_chain(
    client: &Client,
    requested_model: &str,
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    system: &str,
    user: &str,
    tool_call_mode: &str,
) -> Result<(ParseOut, String, String)> {
    let chain = model_chain_for_slug(requested_model);
    if chain.is_empty() {
        anyhow::bail!("no catalog models available for {requested_model}");
    }
    let mut last_err = String::new();
    for target in chain {
        let attempt = if target.provider == "google" {
            gemini_generate(
                contents,
                tools,
                thinking,
                &target.provider_model,
                requested_model,
                system,
                tool_call_mode,
            )
            .await
            .map(|o| (o, target.provider_model.clone()))
        } else {
            cf_chat_generate(client, &target.provider, &target.provider_model, system, user)
                .await
                .map(|(text, tin, tout)| {
                    (
                        ParseOut {
                            text: text.clone(),
                            thought: String::new(),
                            in_tok: tin,
                            out_tok: tout,
                            function_call: None,
                            function_calls: Vec::new(),
                            model_content: serde_json::json!({ "role": "model", "parts": [{ "text": text }] }),
                        },
                        target.provider_model.clone(),
                    )
                })
        };
        match attempt {
            Ok((out, provider_model)) if parse_out_ready(&out) => {
                return Ok((out, provider_model, bill_model_slug(requested_model)));
            }
            Ok((out, provider_model)) if model_is_alien(requested_model) => {
                let promoted = parse_out_promote_thought(out);
                if parse_out_ready(&promoted) {
                    return Ok((promoted, provider_model, bill_model_slug(requested_model)));
                }
                last_err = format!("empty response from {provider_model}");
                continue;
            }
            Ok((out, provider_model)) => {
                return Ok((out, provider_model, bill_model_slug(requested_model)))
            }
            Err(e) => {
                last_err = format!("{e:#}");
                if model_is_alien(requested_model) {
                    continue;
                }
                return Err(e);
            }
        }
    }
    Err(anyhow::anyhow!(last_err))
}

pub async fn llm_stream_chain(
    requested_model: &str,
    contents: &[Value],
    tools: &Value,
    thinking: &str,
    system: &str,
    tool_call_mode: &str,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    cancel: &CancellationToken,
) -> Result<(ParseOut, String, String)> {
    let client = http_client(Duration::from_secs(120));
    let chain = model_chain_for_slug(requested_model);
    if chain.is_empty() {
        anyhow::bail!("no catalog models available for {requested_model}");
    }
    let mut last_err = String::new();
    for target in chain {
        if model_is_alien(requested_model) && !llm_stream_uses_gemini(&target.provider) {
            continue;
        }
        let attempt = if llm_stream_uses_gemini(&target.provider) {
            gemini_generate_stream(
                contents,
                tools,
                thinking,
                &target.provider_model,
                requested_model,
                system,
                tool_call_mode,
                on_delta,
                cancel,
            )
            .await
            .map(|out| (out, target.provider_model.clone()))
        } else {
            let user = stream_contents_user(contents);
            cf_chat_generate(
                &client,
                &target.provider,
                &target.provider_model,
                system,
                &user,
            )
            .await
            .map(|(text, tin, tout)| {
                if !text.is_empty() {
                    on_delta(false, text.clone());
                }
                let out = cf_stream_parse_out(text, tin, tout);
                (out, target.provider_model.clone())
            })
        };
        match attempt {
            Ok((out, provider_model)) if parse_out_ready(&out) => {
                return Ok((out, provider_model, bill_model_slug(requested_model)));
            }
            Ok((out, provider_model)) if model_is_alien(requested_model) => {
                let promoted = parse_out_promote_thought(out);
                if parse_out_ready(&promoted) {
                    return Ok((promoted, provider_model, bill_model_slug(requested_model)));
                }
                last_err = format!("empty response from {provider_model}");
                continue;
            }
            Ok((out, provider_model)) => {
                return Ok((out, provider_model, bill_model_slug(requested_model)))
            }
            Err(e) => {
                last_err = format!("{e:#}");
                if model_is_alien(requested_model) {
                    continue;
                }
                return Err(e);
            }
        }
    }
    Err(anyhow::anyhow!(last_err))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn frontier_models_use_cf_not_gemini() {
        assert!(!llm_stream_uses_gemini("openai"));
        assert!(!llm_stream_uses_gemini("anthropic"));
        assert!(llm_stream_uses_gemini("google"));
    }

    #[test]
    fn stream_contents_user_reads_last_user_turn() {
        let contents = vec![
            json!({ "role": "user", "parts": [{ "text": "first" }] }),
            json!({ "role": "model", "parts": [{ "text": "ok" }] }),
            json!({ "role": "user", "parts": [{ "text": "second" }] }),
        ];
        assert_eq!(stream_contents_user(&contents), "second");
    }
}
