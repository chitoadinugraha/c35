use anyhow::Result;
use c35_mod_llm::{cf_chat_generate, model_chain_for_slug, model_is_alien, model_log_label, model_resolve_target};
use reqwest::Client;
use serde_json::Value;
use tokio_util::sync::CancellationToken;

use super::gemini::{gemini_generate, gemini_generate_stream};
use super::thought::ParseOut;

fn parse_out_ready(out: &ParseOut) -> bool {
    !out.text.trim().is_empty() || out.function_call.is_some()
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
) -> Result<(ParseOut, String, String)> {
    let chain = model_chain_for_slug(requested_model);
    if chain.is_empty() {
        anyhow::bail!("no catalog models available for {requested_model}");
    }
    let mut last_err = String::new();
    for target in chain {
        let attempt = if target.provider == "google" {
            gemini_generate(contents, tools, thinking, &target.provider_model, system)
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
            Ok((out, provider_model)) => return Ok((out, provider_model, bill_model_slug(requested_model))),
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
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    cancel: &CancellationToken,
) -> Result<(ParseOut, String, String)> {
    if !model_is_alien(requested_model) {
        let target = model_resolve_target(requested_model)
            .ok_or_else(|| anyhow::anyhow!("unknown model {requested_model}"))?;
        let out = gemini_generate_stream(contents, tools, thinking, &target.provider_model, system, on_delta, cancel).await?;
        return Ok((out, target.provider_model, bill_model_slug(requested_model)));
    }
    let chain = model_chain_for_slug(requested_model);
    if chain.is_empty() {
        anyhow::bail!("no catalog models available for {requested_model}");
    }
    let mut last_err = String::new();
    for target in chain {
        if target.provider != "google" {
            continue;
        }
        match gemini_generate_stream(contents, tools, thinking, &target.provider_model, system, on_delta, cancel).await {
            Ok(out) if parse_out_ready(&out) => {
                return Ok((out, target.provider_model, bill_model_slug(requested_model)));
            }
            Ok(out) => {
                let promoted = parse_out_promote_thought(out);
                if parse_out_ready(&promoted) {
                    return Ok((promoted, target.provider_model, bill_model_slug(requested_model)));
                }
                last_err = format!("empty response from {}", target.provider_model);
            }
            Err(e) => last_err = format!("{e:#}"),
        }
    }
    Err(anyhow::anyhow!(last_err))
}
