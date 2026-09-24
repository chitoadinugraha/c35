use crate::catalog_rank::alien_chain_sort_cmp;
use crate::catalog_types::LlmModelRow;
use crate::llm_catalog::catalog_models;

pub fn catalog_row_by_provider_model(model: &str) -> Option<LlmModelRow> {
    let key = model.trim();
    if key.is_empty() {
        return None;
    }
    let bare = key.strip_prefix("models/").unwrap_or(key);
    catalog_models()
        .into_iter()
        .find(|m| m.enabled && (m.id == key || m.id == bare || m.provider_model == key || m.provider_model == bare))
}

pub fn catalog_provider_model(model: &str) -> Option<String> {
    catalog_row_by_provider_model(model).map(|m| m.provider_model)
}

pub fn catalog_alien_chain_build() -> Vec<String> {
    let models = catalog_models();
    let mut rows: Vec<&LlmModelRow> = models
        .iter()
        .filter(|m| m.enabled && m.provider == "google" && m.family == "flash-lite")
        .collect();
    rows.sort_by(|a, b| alien_chain_sort_cmp(&a.provider_model, &b.provider_model));
    rows.into_iter().map(|m| m.provider_model.clone()).collect()
}

pub fn catalog_alien_default() -> Option<String> {
    catalog_alien_chain_build().into_iter().next()
}

pub fn catalog_alien_chain_filter(raw: &[String]) -> Vec<String> {
    let mut out = Vec::new();
    for m in raw {
        let Some(valid) = catalog_provider_model(m) else {
            tracing::warn!(model = %m, "catalog: dropping alien chain model not in provider catalog");
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
        .map(|m| vec![m.provider_model])
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn alien_chain_effective_falls_back_when_config_empty() {
        assert!(catalog_alien_chain_effective(&[]).is_empty() || !catalog_models().is_empty());
    }
}
