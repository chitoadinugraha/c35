use crate::catalog_resolve::{catalog_provider_model, catalog_row_by_provider_model};
use crate::llm_catalog::catalog_row_resolve;
use crate::runtime_config::alien_chain_models;

#[derive(Debug, Clone)]
pub struct ModelTarget {
    pub provider: String,
    pub provider_model: String,
}

pub fn model_is_alien(slug: &str) -> bool {
    matches!(slug.trim().to_ascii_lowercase().as_str(), "" | "auto" | "alien" | "alienai" | "cloud")
}

pub fn model_log_label(requested: &str) -> String {
    if model_is_alien(requested) {
        "alienai".into()
    } else {
        requested.trim().to_string()
    }
}

pub fn model_chain_for_slug(slug: &str) -> Vec<ModelTarget> {
    if model_is_alien(slug) {
        return alien_chain_models()
            .into_iter()
            .filter_map(|m| {
                catalog_provider_model(&m).map(|provider_model| ModelTarget {
                    provider: "google".into(),
                    provider_model,
                })
            })
            .collect();
    }
    model_resolve_target(slug).into_iter().collect()
}

pub fn model_resolve_target(slug: &str) -> Option<ModelTarget> {
    let s = slug.trim();
    if model_is_alien(s) {
        return catalog_row_resolve("alienai").map(|row| ModelTarget {
            provider: row.provider,
            provider_model: row.provider_model,
        });
    }
    if let Some(row) = catalog_row_resolve(s) {
        return Some(ModelTarget {
            provider: row.provider,
            provider_model: row.provider_model,
        });
    }
    catalog_row_by_provider_model(s).map(|row| ModelTarget {
        provider: row.provider,
        provider_model: row.provider_model,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::runtime_config::model_is_flash_lite;

    #[test]
    fn alien_slug_is_detected() {
        assert!(model_is_alien("alienai"));
        assert!(model_is_alien("auto"));
        assert!(!model_is_alien("gemini-2.5-flash-lite"));
    }

    #[test]
    fn flash_lite_family_guard() {
        assert!(model_is_flash_lite("gemini-3.1-flash-lite"));
        assert!(!model_is_flash_lite("gemini-2.5-pro"));
    }
}
