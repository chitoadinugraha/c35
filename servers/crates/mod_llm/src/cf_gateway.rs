use anyhow::{anyhow, Context, Result};
use reqwest::Client;
use serde_json::{json, Value};

use crate::runtime_config::{cf_gateway_config, cf_gateway_ready, CfGatewayRuntime};

fn cf_chat_url(cfg: &CfGatewayRuntime, provider: &str) -> Result<String> {
    if cfg.account_id.is_empty() {
        anyhow::bail!("CLOUDFLARE_ACCOUNT_ID missing");
    }
    let path = match provider {
        "openai" => "openai/chat/completions",
        "openrouter" | "anthropic" => "openrouter/chat/completions",
        _ => "compat/chat/completions",
    };
    Ok(format!(
        "https://gateway.ai.cloudflare.com/v1/{}/{}/{}",
        cfg.account_id, cfg.gateway_id, path
    ))
}

pub async fn cf_chat_generate(
    client: &Client,
    provider: &str,
    model: &str,
    system: &str,
    user: &str,
) -> Result<(String, i32, i32)> {
    if !cf_gateway_ready() {
        anyhow::bail!("CF AI Gateway not configured (set CLOUDFLARE_* env or ai.config llm.cf_gateway)");
    }
    let cfg = cf_gateway_config();
    let url = cf_chat_url(&cfg, provider)?;
    let mut headers = vec![
        ("cf-aig-authorization".to_string(), format!("Bearer {}", cfg.api_token)),
        ("Content-Type".to_string(), "application/json".to_string()),
    ];
    if provider == "openai" {
        if let Ok(k) = std::env::var("OPENAI_API_KEY") {
            if !k.is_empty() {
                headers.push(("Authorization".to_string(), format!("Bearer {k}")));
            }
        }
    }
    if provider == "openrouter" || provider == "anthropic" {
        if let Ok(k) = std::env::var("OPENROUTER_API_KEY") {
            if !k.is_empty() {
                headers.push(("Authorization".to_string(), format!("Bearer {k}")));
            }
        }
    }
    let body = json!({
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ],
        "max_tokens": 2048,
        "temperature": 0.2
    });
    let mut req = client.post(&url).json(&body);
    for (k, v) in headers {
        req = req.header(k, v);
    }
    let res = req.send().await.context("cf gateway request")?;
    let status = res.status();
    let v: Value = res.json().await.context("cf gateway json")?;
    if !status.is_success() {
        return Err(anyhow!("cf gateway {status}: {v}"));
    }
    let text = v["choices"][0]["message"]["content"]
        .as_str()
        .unwrap_or("")
        .trim()
        .to_string();
    let tin = v["usage"]["prompt_tokens"].as_i64().unwrap_or(0) as i32;
    let tout = v["usage"]["completion_tokens"].as_i64().unwrap_or(0) as i32;
    Ok((text, tin, tout))
}
