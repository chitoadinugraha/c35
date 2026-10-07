//! Block provider-native web grounding (Gemini Google Search, Vertex retrieval, OpenAI web_search tools).
//! Product policy: factual grounding goes through cluster `web.search` / `web.visit` / `web.research` only.

use anyhow::{bail, Result};
use serde_json::Value;

const FORBIDDEN_OBJECT_KEYS: &[&str] = &[
    "googleSearch",
    "enterpriseWebSearch",
    "groundingConfig",
    "google_search_retrieval",
    "dynamicRetrievalConfig",
    "web_search_options",
];

const FORBIDDEN_TOOL_TYPES: &[&str] = &["web_search", "web_search_preview"];

/// Reject LLM request payloads that enable opaque provider web grounding.
pub fn gemini_request_reject_provider_grounding(v: &Value) -> Result<()> {
    walk(v, "")?;
    Ok(())
}

fn walk(v: &Value, path: &str) -> Result<()> {
    match v {
        Value::Object(map) => {
            for (key, child) in map {
                if FORBIDDEN_OBJECT_KEYS.iter().any(|k| *k == key.as_str()) {
                    bail!(
                        "provider web grounding forbidden at {}.{} — use cluster web.search (see web-grounding-cluster-only rule)",
                        path,
                        key
                    );
                }
                if key == "type" {
                    if let Some(t) = child.as_str() {
                        if FORBIDDEN_TOOL_TYPES.iter().any(|ft| *ft == t) {
                            bail!(
                                "provider web_search tool forbidden at {} — use cluster web.search",
                                path
                            );
                        }
                    }
                }
                let child_path = if path.is_empty() {
                    key.clone()
                } else {
                    format!("{}.{}", path, key)
                };
                walk(child, &child_path)?;
            }
        }
        Value::Array(arr) => {
            for (i, item) in arr.iter().enumerate() {
                walk(item, &format!("{}[{}]", path, i))?;
            }
        }
        _ => {}
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn rejects_gemini_google_search_tool() {
        let body = json!({
            "tools": [{ "googleSearch": {} }]
        });
        assert!(gemini_request_reject_provider_grounding(&body).is_err());
    }

    #[test]
    fn rejects_openai_web_search_tool_type() {
        let body = json!({
            "tools": [{ "type": "web_search" }]
        });
        assert!(gemini_request_reject_provider_grounding(&body).is_err());
    }

    #[test]
    fn allows_function_declarations_only() {
        let body = json!({
            "tools": [{ "functionDeclarations": [{ "name": "web_search" }] }]
        });
        gemini_request_reject_provider_grounding(&body).unwrap();
    }
}
