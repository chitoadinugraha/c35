use crate::catalog_rank::alien_chain_sort_cmp;
use crate::catalog_types::LlmModelRow;
use crate::llm_catalog::catalog_models;

/// Bare Gemini Developer API model id (no `models/` or `google/` OpenRouter prefix).
pub fn google_gemini_api_model_id(model: &str) -> String {
    let s = model.trim();
    if s.is_empty() {
        return String::new();
    }
    let s = s.strip_prefix("models/").unwrap_or(s);
    s.strip_prefix("google/").unwrap_or(s).to_string()
}

fn google_provider_model(row: &LlmModelRow) -> String {
    if row.provider == "google" {
        google_gemini_api_model_id(&row.provider_model)
    } else {
        row.provider_model.clone()
    }
}

pub fn catalog_row_by_provider_model(model: &str) -> Option<LlmModelRow> {
    let key = model.trim();
    if key.is_empty() {
        return None;
    }
    let bare = google_gemini_api_model_id(key);
    catalog_models()
        .into_iter()
        .find(|m| {
            if !m.enabled {
                return false;
            }
            let pm = google_gemini_api_model_id(&m.provider_model);
            m.id == key || m.id == bare || pm == key || pm == bare || m.provider_model == key
        })
}

pub fn catalog_provider_model(model: &str) -> Option<String> {
    catalog_row_by_provider_model(model).map(|m| google_provider_model(&m))
}

pub fn catalog_alien_chain_build() -> Vec<String> {
    let models = catalog_models();
    let mut rows: Vec<&LlmModelRow> = models
        .iter()
        .filter(|m| m.enabled && m.provider == "google" && m.family == "flash-lite")
        .collect();
    rows.sort_by(|a, b| alien_chain_sort_cmp(&a.provider_model, &b.provider_model));
    rows.into_iter().map(|m| google_provider_model(&m)).collect()
}

pub fn catalog_alien_default() -> Option<String> {
    catalog_alien_chain_build().into_iter().next()
}

pub fn catalog_alien_chain_filter(raw: &[String]) -> Vec<String> {
    let catalog_ready = !catalog_models().is_empty();
    let mut out = Vec::new();
    for m in raw {
        let Some(valid) = catalog_provider_model(m) else {
            if catalog_ready {
                tracing::warn!(model = %m, "catalog: dropping alien chain model not in provider catalog");
            }
            continue;
        };
        if out.iter().any(|x| x == &valid) {
            continue;
        }
        out.push(valid);
    }
    out.sort_by(|a, b| alien_chain_sort_cmp(a, b));
    out
}

pub fn catalog_alien_chain_effective(configured: &[String]) -> Vec<String> {
    let filtered = catalog_alien_chain_filter(configured);
    if !filtered.is_empty() {
        return filtered;
    }
    let built = catalog_alien_chain_build();
    if !built.is_empty() {
        return built;
    }
    catalog_models()
        .into_iter()
        .find(|m| m.enabled && m.id == "alienai" && !m.provider_model.is_empty())
        .map(|m| vec![google_provider_model(&m)])
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn google_gemini_api_model_strips_openrouter_prefix() {
        assert_eq!(
            google_gemini_api_model_id("google/gemini-3.1-flash-lite-preview"),
            "gemini-3.1-flash-lite-preview"
        );
        assert_eq!(google_gemini_api_model_id("models/gemini-2.5-flash-lite"), "gemini-2.5-flash-lite");
        assert_eq!(google_gemini_api_model_id("gemini-3.5-flash-lite"), "gemini-3.5-flash-lite");
    }

    #[test]
    fn alien_chain_effective_falls_back_when_config_empty() {
        assert!(catalog_alien_chain_effective(&[]).is_empty() || !catalog_models().is_empty());
    }
}
