use crate::catalog_types::LlmModelRow;

const BAND_ALIENAI: i32 = 0;
const BAND_OPENAI: i32 = 100;
const BAND_ANTHROPIC: i32 = 110;
const BAND_DEEPSEEK: i32 = 120;
const BAND_XAI: i32 = 130;
const BAND_CLOUDFLARE: i32 = 140;
const BAND_GOOGLE: i32 = 200;
const BAND_HIDDEN: i32 = 900;

pub fn family_of(id: &str) -> String {
    let m = id.to_ascii_lowercase();
    if m.contains("flash-lite") || m.contains("flash_lite") {
        return "flash-lite".into();
    }
    if m.contains("flash") {
        return "flash".into();
    }
    if m.contains("pro") {
        return "pro".into();
    }
    if m.starts_with("@cf/") {
        return "llama".into();
    }
    "other".into()
}

pub fn version_rank_of(id: &str) -> i32 {
    let m = id.to_ascii_lowercase();
    let mut major = 0i32;
    let mut minor = 0i32;
    let mut patch = 0i32;
    let mut nums = Vec::new();
    let mut cur = String::new();
    for ch in m.chars() {
        if ch.is_ascii_digit() {
            cur.push(ch);
        } else if !cur.is_empty() {
            nums.push(cur.clone());
            cur.clear();
        }
    }
    if !cur.is_empty() {
        nums.push(cur);
    }
    if !nums.is_empty() {
        major = nums[0].parse().unwrap_or(0);
    }
    if nums.len() > 1 {
        minor = nums[1].parse().unwrap_or(0);
    }
    if nums.len() > 2 {
        patch = nums[2].parse().unwrap_or(0);
    }
    major * 1_000_000 + minor * 1_000 + patch
}

pub fn provider_band(provider: &str) -> i32 {
    match provider {
        "alienai" => BAND_ALIENAI,
        "openai" => BAND_OPENAI,
        "anthropic" => BAND_ANTHROPIC,
        "deepseek" => BAND_DEEPSEEK,
        "xai" => BAND_XAI,
        "cloudflare" => BAND_CLOUDFLARE,
        "google" => BAND_GOOGLE,
        _ => BAND_HIDDEN,
    }
}

pub fn family_priority(family: &str) -> i32 {
    match family {
        "flash-lite" => 0,
        "flash" => 10,
        "pro" => 20,
        _ => 90,
    }
}

pub fn is_preview_id(id: &str) -> bool {
    let m = id.to_ascii_lowercase();
    m.contains("preview")
        || m.contains("experimental")
        || m.contains("-exp")
        || m.contains("beta")
        || m.ends_with("-preview")
}

pub fn model_list_sort_cmp(a: &LlmModelRow, b: &LlmModelRow) -> std::cmp::Ordering {
    provider_band(&a.provider)
        .cmp(&provider_band(&b.provider))
        .then_with(|| family_priority(&a.family).cmp(&family_priority(&b.family)))
        .then_with(|| is_preview_id(&a.id).cmp(&is_preview_id(&b.id)))
        .then_with(|| b.version_rank.cmp(&a.version_rank))
        .then_with(|| a.label.cmp(&b.label))
}

/// Picker order: Alien AI first, then CF frontier providers, then explicit Gemini pins.
pub fn model_picker_sort_cmp(a: &LlmModelRow, b: &LlmModelRow) -> std::cmp::Ordering {
    if a.id == "alienai" {
        return std::cmp::Ordering::Less;
    }
    if b.id == "alienai" {
        return std::cmp::Ordering::Greater;
    }
    model_list_sort_cmp(a, b)
}

pub fn sort_order_for(m: &LlmModelRow, index: i32) -> i32 {
    if !m.enabled {
        return BAND_HIDDEN + index;
    }
    if m.id == "alienai" {
        return 0;
    }
    provider_band(&m.provider) + family_priority(&m.family) * 10 + index
}

pub fn apply_cf_enabled(models: &mut [LlmModelRow]) {
    use std::collections::HashMap;
    models.sort_by(model_list_sort_cmp);
    let mut by_provider: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, m) in models.iter().enumerate() {
        by_provider.entry(m.provider.clone()).or_default().push(i);
    }
    for indices in by_provider.values_mut() {
        indices.sort_by(|&a, &b| model_list_sort_cmp(&models[a], &models[b]));
        let mut stable_n = 0usize;
        let mut preview_n = 0usize;
        for &i in indices.iter() {
            let m = &models[i];
            if is_preview_id(&m.id) {
                preview_n += 1;
                models[i].enabled = preview_n <= 1;
            } else {
                stable_n += 1;
                models[i].enabled = stable_n <= 6;
            }
        }
    }
}

pub fn gemini_chat_eligible(id: &str, methods: &[String]) -> bool {
    let m = id.to_ascii_lowercase();
    if !methods.iter().any(|x| x == "generateContent") {
        return false;
    }
    const SKIP: &[&str] = &[
        "embedding",
        "embed",
        "aqa",
        "image",
        "imagen",
        "veo",
        "tts",
        "live",
        "transcribe",
        "computer-use",
        "robotics",
        "deep-research",
        "lyria",
        "nano-banana",
        "omni",
        "customtools",
    ];
    if SKIP.iter().any(|s| m.contains(s)) {
        return false;
    }
    if m.contains("latest") {
        return m.contains("flash") || m.contains("pro");
    }
    m.contains("gemini") && (m.contains("flash") || m.contains("pro"))
}

const ALIEN_CHAIN_PRIMARY: &[&str] = &["gemini-3.1-flash-lite", "gemini-3.5-flash-lite"];

pub fn alien_chain_sort_key(id: &str) -> (i32, i32) {
    let m = id.to_ascii_lowercase();
    for (i, p) in ALIEN_CHAIN_PRIMARY.iter().enumerate() {
        if m == *p {
            return (0, i as i32);
        }
    }
    if is_preview_id(&m) {
        return (3, -version_rank_of(&m));
    }
    if m.contains("latest") {
        return (2, -version_rank_of(&m));
    }
    (1, -version_rank_of(&m))
}

pub fn alien_chain_sort_cmp(a: &str, b: &str) -> std::cmp::Ordering {
    alien_chain_sort_key(a).cmp(&alien_chain_sort_key(b))
}

pub fn pick_default_provider(models: &[LlmModelRow], provider: &str) -> Option<String> {
    models
        .iter()
        .filter(|m| m.provider == provider && m.enabled && m.source != "pinned" && !is_preview_id(&m.id))
        .max_by_key(|m| (m.version_rank, m.family == "flash-lite", m.family == "flash"))
        .map(|m| m.id.clone())
}

pub fn apply_gemini_enabled(models: &mut [LlmModelRow]) {
    const FAMILIES: &[&str] = &["flash-lite", "flash", "pro"];
    models.sort_by(model_list_sort_cmp);
    let mut stable_n: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
    let mut preview_n: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
    for m in models.iter_mut() {
        if !FAMILIES.contains(&m.family.as_str()) {
            m.enabled = false;
            continue;
        }
        if is_preview_id(&m.id) {
            let n = preview_n.entry(m.family.clone()).or_insert(0);
            *n += 1;
            m.enabled = *n <= 1;
        } else {
            let n = stable_n.entry(m.family.clone()).or_insert(0);
            *n += 1;
            m.enabled = *n <= 8;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_rank_orders_gemini() {
        assert!(version_rank_of("gemini-3.1-flash-lite") > version_rank_of("gemini-2.5-flash"));
    }

    #[test]
    fn family_detects_flash_lite() {
        assert_eq!(family_of("gemini-3.1-flash-lite"), "flash-lite");
    }

    #[test]
    fn transcribe_is_not_chat_eligible() {
        assert!(!gemini_chat_eligible(
            "gemini-3.5-transcribe",
            &["generateContent".into()]
        ));
    }

    #[test]
    fn stable_sorts_before_preview() {
        let stable = LlmModelRow {
            id: "gemini-3.1-flash-lite".into(),
            provider: "google".into(),
            label: "Gemini 3.1 Flash Lite".into(),
            provider_model: "gemini-3.1-flash-lite".into(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: true,
            enabled: true,
            is_default: false,
            sort_order: 0,
            family: "flash-lite".into(),
            version_rank: version_rank_of("gemini-3.1-flash-lite"),
            source: "api".into(),
        };
        let preview = LlmModelRow {
            id: "gemini-3.1-flash-lite-preview".into(),
            label: "Gemini 3.1 Flash Lite Preview".into(),
            ..stable.clone()
        };
        assert_eq!(model_list_sort_cmp(&stable, &preview), std::cmp::Ordering::Less);
    }

    #[test]
    fn alien_chain_prefers_31_then_35() {
        let mut chain = vec![
            "gemini-3.5-flash-lite".to_string(),
            "gemini-2.5-flash-lite".to_string(),
            "gemini-3.1-flash-lite".to_string(),
            "gemini-flash-lite-latest".to_string(),
        ];
        chain.sort_by(|a, b| alien_chain_sort_cmp(a, b));
        assert_eq!(
            chain,
            vec![
                "gemini-3.1-flash-lite".to_string(),
                "gemini-3.5-flash-lite".to_string(),
                "gemini-2.5-flash-lite".to_string(),
                "gemini-flash-lite-latest".to_string(),
            ]
        );
    }

    #[test]
    fn model_picker_puts_alien_first() {
        let alien = LlmModelRow {
            id: "alienai".into(),
            provider: "alienai".into(),
            label: "Alien AI".into(),
            provider_model: String::new(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: true,
            enabled: true,
            is_default: true,
            sort_order: 0,
            family: "flash-lite".into(),
            version_rank: 0,
            source: "pinned".into(),
        };
        let gemini = LlmModelRow {
            id: "gemini-3.1-flash-lite".into(),
            provider: "google".into(),
            label: "Gemini 3.1 Flash Lite".into(),
            provider_model: "gemini-3.1-flash-lite".into(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: true,
            enabled: true,
            is_default: false,
            sort_order: 100,
            family: "flash-lite".into(),
            version_rank: version_rank_of("gemini-3.1-flash-lite"),
            source: "api".into(),
        };
        assert_eq!(model_picker_sort_cmp(&alien, &gemini), std::cmp::Ordering::Less);
    }

    #[test]
    fn frontier_provider_before_google() {
        let openai = LlmModelRow {
            id: "gpt-4o".into(),
            provider: "openai".into(),
            label: "GPT-4o".into(),
            provider_model: "openai/gpt-4o".into(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: false,
            enabled: true,
            is_default: false,
            sort_order: 0,
            family: "other".into(),
            version_rank: 0,
            source: "cf_api".into(),
        };
        let gemini = LlmModelRow {
            id: "gemini-2.5-flash".into(),
            provider: "google".into(),
            label: "Gemini 2.5 Flash".into(),
            provider_model: "gemini-2.5-flash".into(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: true,
            enabled: true,
            is_default: false,
            sort_order: 0,
            family: "flash".into(),
            version_rank: version_rank_of("gemini-2.5-flash"),
            source: "api".into(),
        };
        assert_eq!(model_list_sort_cmp(&openai, &gemini), std::cmp::Ordering::Less);
    }
}
