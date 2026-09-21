use anyhow::{anyhow, Context, Result};
use reqwest::Client;
use serde_json::json;

use crate::EMBED_TASK_DOCUMENT;

pub const EMBED_MODEL: &str = "gemini-embedding-2";

fn gemini_api_key() -> String {
    ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
        .iter()
        .find_map(|k| std::env::var(k).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

fn task_type(task: &str) -> &'static str {
    if task == EMBED_TASK_DOCUMENT {
        "RETRIEVAL_DOCUMENT"
    } else {
        "RETRIEVAL_QUERY"
    }
}

pub fn embed_l2_normalize(vec: &mut [f32]) {
    let norm: f32 = vec.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm > 0.0 {
        for v in vec.iter_mut() {
            *v /= norm;
        }
    }
}

pub async fn embed_text(http: &Client, text: &str, task: &str, dimensions: i32) -> Result<Vec<f32>> {
    let key = gemini_api_key();
    if key.is_empty() {
        anyhow::bail!("GEMINI_API_KEY required for embed");
    }
    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/{EMBED_MODEL}:embedContent?key={key}"
    );
    let res = http
        .post(&url)
        .timeout(std::time::Duration::from_secs(30))
        .json(&json!({
            "content": { "parts": [{ "text": text }] },
            "taskType": task_type(task),
            "outputDimensionality": dimensions
        }))
        .send()
        .await
        .context("gemini embed request")?;
    let status = res.status();
    let body: serde_json::Value = res.json().await.context("gemini embed json")?;
    if !status.is_success() {
        return Err(anyhow!("gemini embed {status}: {body}"));
    }
    let mut vec: Vec<f32> = body
        .pointer("/embedding/values")
        .or_else(|| body.pointer("/embeddings/0/values"))
        .and_then(|v| v.as_array())
        .map(|a| a.iter().filter_map(|v| v.as_f64().map(|f| f as f32)).collect())
        .ok_or_else(|| anyhow!("gemini embed missing vector"))?;
    if vec.is_empty() {
        return Err(anyhow!("gemini embed empty vector"));
    }
    embed_l2_normalize(&mut vec);
    Ok(vec)
}
