use std::collections::HashMap;

use serde_json::Value;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CatalogPricing {
    pub input_micro_per_m: i64,
    pub output_micro_per_m: i64,
    pub input_cache_micro_per_m: i64,
}

pub fn usd_per_token_to_micro_per_m(usd_per_token: f64) -> i64 {
    (usd_per_token * 1_000_000.0 * 1_000_000.0).round() as i64
}

/// OpenRouter-style `pricing` object (also used by CF models search `format=openrouter`).
pub fn pricing_from_openrouter_value(pricing: &Value) -> Option<CatalogPricing> {
    let in_s = pricing
        .get("prompt")
        .and_then(|v| v.as_str())
        .or_else(|| pricing.get("input").and_then(|v| v.as_str()))?;
    let out_s = pricing
        .get("completion")
        .and_then(|v| v.as_str())
        .or_else(|| pricing.get("output").and_then(|v| v.as_str()))?;
    let in_tok = in_s.trim().parse::<f64>().ok().filter(|&n| n >= 0.0)?;
    let out_tok = out_s.trim().parse::<f64>().ok().filter(|&n| n >= 0.0)?;
    if in_tok == 0.0 && out_tok == 0.0 {
        return None;
    }
    let cache_tok = cache_read_usd_per_token(pricing);
    Some(CatalogPricing {
        input_micro_per_m: usd_per_token_to_micro_per_m(in_tok),
        output_micro_per_m: usd_per_token_to_micro_per_m(out_tok),
        input_cache_micro_per_m: cache_tok.map(usd_per_token_to_micro_per_m).unwrap_or(0),
    })
}

pub fn pricing_from_model_row(raw: &Value) -> Option<CatalogPricing> {
    raw.get("pricing").and_then(pricing_from_openrouter_value)
}

fn cache_read_usd_per_token(pricing: &Value) -> Option<f64> {
    const KEYS: &[&str] = &[
        "input_cache_read",
        "cache_read",
        "prompt_cache_read",
        "input_cache",
    ];
    for key in KEYS {
        let Some(s) = pricing.get(key).and_then(|v| v.as_str()) else {
            continue;
        };
        let n = s.trim().parse::<f64>().ok().filter(|&n| n > 0.0)?;
        return Some(n);
    }
    None
}

/// OpenRouter ids use provider prefixes; keep in sync with `catalog_sync::CF_CHAT_ID_PREFIXES`.
const OR_PREFIX_BY_PROVIDER: &[(&str, &str)] = &[
    ("openai", "openai"),
    ("anthropic", "anthropic"),
    ("google", "google"),
    ("deepseek", "deepseek"),
    ("xai", "x-ai"),
    ("moonshot", "moonshotai"),
    ("meta", "meta-llama"),
    ("mistral", "mistralai"),
    ("qwen", "qwen"),
    ("cohere", "cohere"),
    ("perplexity", "perplexity"),
];

pub fn pricing_lookup_keys(id: &str, provider: &str, provider_model: &str) -> Vec<String> {
    let mut keys = Vec::new();
    let id = id.trim();
    let provider = provider.trim();
    let provider_model = provider_model.trim();
    let mut push = |k: String| {
        if !k.is_empty() && !keys.iter().any(|x| x == &k) {
            keys.push(k);
        }
    };
    if !id.is_empty() {
        push(id.to_string());
    }
    if !provider_model.is_empty() {
        push(provider_model.to_string());
    }
    for (prov, pfx) in OR_PREFIX_BY_PROVIDER {
        if provider == *prov && !id.is_empty() {
            push(format!("{}/{}", pfx, id));
        }
    }
    keys
}

#[cfg(test)]
mod tests {
    use super::pricing_lookup_keys;

    #[test]
    fn lookup_keys_openai_slug_and_prefix() {
        let keys = pricing_lookup_keys("gpt-4o", "openai", "openai/gpt-4o");
        assert!(keys.contains(&"gpt-4o".to_string()));
        assert!(keys.contains(&"openai/gpt-4o".to_string()));
    }
}

pub fn apply_openrouter_pricing(
    row: &mut crate::catalog_types::LlmModelRow,
    index: &HashMap<String, CatalogPricing>,
) {
    for key in pricing_lookup_keys(&row.id, &row.provider, &row.provider_model) {
        if let Some(p) = index.get(&key) {
            row.input_micro_per_m = p.input_micro_per_m;
            row.output_micro_per_m = p.output_micro_per_m;
            row.input_cache_micro_per_m = p.input_cache_micro_per_m;
            return;
        }
    }
}
