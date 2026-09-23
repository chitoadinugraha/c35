use crate::catalog_types::LlmModelRow;

const BAND_ALIENAI: i32 = 0;
const BAND_GOOGLE: i32 = 100;
const BAND_OPENAI: i32 = 200;
const BAND_ANTHROPIC: i32 = 300;
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
        "google" => BAND_GOOGLE,
        "openai" => BAND_OPENAI,
        "anthropic" => BAND_ANTHROPIC,
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

pub fn model_list_sort_cmp(a: &LlmModelRow, b: &LlmModelRow) -> std::cmp::Ordering {
    provider_band(&a.provider)
        .cmp(&provider_band(&b.provider))
        .then_with(|| family_priority(&a.family).cmp(&family_priority(&b.family)))
        .then_with(|| b.version_rank.cmp(&a.version_rank))
        .then_with(|| a.label.cmp(&b.label))
}

pub fn sort_order_for(m: &LlmModelRow, index: i32) -> i32 {
    if !m.enabled {
        return BAND_HIDDEN + index;
    }
    provider_band(&m.provider) + family_priority(&m.family) * 10 + index
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

pub fn pick_default_provider(models: &[LlmModelRow], provider: &str) -> Option<String> {
    models
        .iter()
        .filter(|m| m.provider == provider && m.enabled && m.source != "pinned")
        .max_by_key(|m| (m.version_rank, m.family == "flash-lite", m.family == "flash"))
        .map(|m| m.id.clone())
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
    fn flash_lite_sorts_before_other() {
        let flash = LlmModelRow {
            id: "gemini-3.1-flash-lite-preview".into(),
            provider: "google".into(),
            label: "Gemini 3.1 Flash Lite Preview".into(),
            provider_model: "gemini-3.1-flash-lite-preview".into(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: true,
            enabled: true,
            is_default: false,
            sort_order: 0,
            family: "flash-lite".into(),
            version_rank: version_rank_of("gemini-3.1-flash-lite-preview"),
            source: "api".into(),
        };
        let other = LlmModelRow {
            family: "other".into(),
            id: "gemini-3.5-transcribe".into(),
            label: "Gemini 3.5 Transcribe".into(),
            ..flash.clone()
        };
        assert_eq!(model_list_sort_cmp(&flash, &other), std::cmp::Ordering::Less);
    }
}
