use crate::runtime_config::{alien_chain_models, alien_default_model};

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
            .map(|m| ModelTarget { provider: "google".into(), provider_model: m })
            .collect();
    }
    vec![model_resolve_target(slug)]
}

pub fn model_resolve_target(slug: &str) -> ModelTarget {
    let s = slug.trim();
    if model_is_alien(s) {
        return ModelTarget {
            provider: "google".into(),
            provider_model: alien_default_model(),
        };
    }
    if s.starts_with("gemini-") || s.starts_with("models/gemini-") {
        return ModelTarget {
            provider: "google".into(),
            provider_model: s.strip_prefix("models/").unwrap_or(s).to_string(),
        };
    }
    for (slug_key, provider, model) in MODEL_SEEDS {
        if s.eq_ignore_ascii_case(slug_key) {
            return ModelTarget { provider: (*provider).into(), provider_model: (*model).into() };
        }
    }
    ModelTarget {
        provider: "google".into(),
        provider_model: alien_default_model(),
    }
}

const MODEL_SEEDS: &[(&str, &str, &str)] = &[
    ("gpt-4o", "openai", "gpt-4o"),
    ("claude-sonnet-4-5", "openrouter", "anthropic/claude-sonnet-4-5"),
    ("hermes-3-70b", "openrouter", "nousresearch/hermes-3-llama-3.1-70b"),
];

#[cfg(test)]
mod tests {
    use super::*;
    use crate::runtime_config::model_is_flash_lite;

    #[test]
    fn alien_chain_stays_flash_lite_family() {
        let chain = model_chain_for_slug("alienai");
        assert!(chain.len() >= 2);
        for t in &chain {
            assert!(model_is_flash_lite(&t.provider_model), "{}", t.provider_model);
        }
        assert_eq!(chain[0].provider_model, DEFAULT_GEMINI_MODEL);
    }
}
