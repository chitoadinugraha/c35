use crate::catalog_types::LlmModelRow;

const BAND_ALIENAI: i32 = 0;
const BAND_OPENAI: i32 = 100;
const BAND_ANTHROPIC: i32 = 110;
const BAND_DEEPSEEK: i32 = 120;
const BAND_XAI: i32 = 130;
const BAND_MOONSHOT: i32 = 135;
const BAND_META: i32 = 136;
const BAND_MISTRAL: i32 = 137;
const BAND_QWEN: i32 = 138;
const BAND_COHERE: i32 = 139;
const BAND_CLOUDFLARE: i32 = 140;
const BAND_GOOGLE: i32 = 200;
const BAND_HIDDEN: i32 = 900;

fn id_tokens(id: &str) -> Vec<String> {
    id.to_ascii_lowercase()
        .split(|c: char| !c.is_ascii_alphanumeric())
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .collect()
}

/// Product line from the provider id. Patterns only — no pinned model list.
pub fn family_of(id: &str) -> String {
    let tokens = id_tokens(id);
    let has = |t: &str| tokens.iter().any(|x| x == t);
    if tokens.windows(2).any(|w| w[0] == "flash" && w[1] == "lite") || has("flashlite") {
        return "flash-lite".into();
    }
    for t in ["haiku", "sonnet", "opus", "reasoner", "mini", "nano", "luna", "grok"] {
        if has(t) {
            return t.into();
        }
    }
    if tokens.iter().any(|t| t == "o1" || t == "o3" || t == "o4") {
        return "reasoner".into();
    }
    if has("flash") {
        return "flash".into();
    }
    if has("pro") {
        return "pro".into();
    }
    if has("chat") {
        return "chat".into();
    }
    if has("gpt") {
        return "gpt".into();
    }
    if has("llama") || id.to_ascii_lowercase().contains("@cf/") {
        return "llama".into();
    }
    "other".into()
}

/// 0 daily, 1 standard, 2 heavy, 3 other.
pub fn tier_of_family(family: &str) -> i32 {
    match family {
        "flash-lite" | "mini" | "nano" | "haiku" => 0,
        "flash" | "sonnet" | "gpt" | "luna" | "grok" | "chat" | "llama" => 1,
        "pro" | "opus" | "reasoner" => 2,
        _ => 3,
    }
}

fn tier_rank(family: &str, daily_lead: bool) -> i32 {
    let tier = tier_of_family(family);
    if daily_lead || tier >= 2 {
        tier
    } else {
        1 - tier
    }
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
        "moonshot" => BAND_MOONSHOT,
        "meta" => BAND_META,
        "mistral" => BAND_MISTRAL,
        "qwen" => BAND_QWEN,
        "cohere" => BAND_COHERE,
        "perplexity" => BAND_COHERE,
        "nvidia" => BAND_COHERE,
        "microsoft" => BAND_COHERE,
        "zai" => BAND_COHERE,
        "minimax" => BAND_COHERE,
        "baidu" => BAND_COHERE,
        "amazon" => BAND_COHERE,
        "cloudflare" => BAND_CLOUDFLARE,
        "google" => BAND_GOOGLE,
        _ => BAND_HIDDEN,
    }
}

pub fn is_rolling_alias(id: &str) -> bool {
    id_tokens(id).iter().any(|t| t == "latest")
}

pub fn is_preview_id(id: &str) -> bool {
    let m = id.to_ascii_lowercase();
    m.contains("preview")
        || m.contains("experimental")
        || m.contains("-exp")
        || m.contains("beta")
        || m.ends_with("-preview")
}

fn daily_lead_providers(models: &[LlmModelRow]) -> std::collections::HashSet<String> {
    models.iter().filter(|m| m.family == "flash-lite").map(|m| m.provider.clone()).collect()
}

fn picker_cmp(a: &LlmModelRow, b: &LlmModelRow, daily_lead: &std::collections::HashSet<String>) -> std::cmp::Ordering {
    let tier = |m: &LlmModelRow| tier_rank(&m.family, daily_lead.contains(&m.provider));
    provider_band(&a.provider)
        .cmp(&provider_band(&b.provider))
        .then_with(|| is_preview_id(&a.id).cmp(&is_preview_id(&b.id)))
        .then_with(|| tier(a).cmp(&tier(b)))
        .then_with(|| b.version_rank.cmp(&a.version_rank))
        .then_with(|| a.label.cmp(&b.label))
}

#[cfg(test)]
pub fn model_list_sort_cmp(a: &LlmModelRow, b: &LlmModelRow) -> std::cmp::Ordering {
    let daily = daily_lead_providers(&[a.clone(), b.clone()]);
    picker_cmp(a, b, &daily)
}

/// Picker order: Alien AI first, then CF frontier providers, then explicit Gemini pins.
#[cfg(test)]
pub fn model_picker_sort_cmp(a: &LlmModelRow, b: &LlmModelRow) -> std::cmp::Ordering {
    if a.id == "alienai" {
        return std::cmp::Ordering::Less;
    }
    if b.id == "alienai" {
        return std::cmp::Ordering::Greater;
    }
    model_list_sort_cmp(a, b)
}

const PICKER_STABLE_KEEP: usize = 2;
const PICKER_PREVIEW_KEEP: usize = 1;
const SORT_DISABLED: i32 = 1000;

fn refresh_rank_fields(models: &mut [LlmModelRow]) {
    for m in models.iter_mut() {
        if m.source == "pinned" || m.id == "alienai" {
            continue;
        }
        m.family = family_of(&m.id);
        m.version_rank = version_rank_of(&m.id);
    }
}

fn picker_family_ok(m: &LlmModelRow) -> bool {
    if m.provider != "google" {
        return true;
    }
    matches!(m.family.as_str(), "flash-lite" | "flash" | "pro")
}

fn apply_picker_window(models: &mut [LlmModelRow]) {
    use std::collections::HashMap;
    let mut groups: HashMap<(String, String), Vec<usize>> = HashMap::new();
    for (i, m) in models.iter().enumerate() {
        if m.source == "pinned" || m.source == "manual" || m.id == "alienai" {
            continue;
        }
        groups.entry((m.provider.clone(), m.family.clone())).or_default().push(i);
    }
    for indices in groups.values_mut() {
        indices.sort_by(|&a, &b| {
            let (a, b) = (&models[a], &models[b]);
            is_rolling_alias(&a.id)
                .cmp(&is_rolling_alias(&b.id))
                .then_with(|| is_preview_id(&a.id).cmp(&is_preview_id(&b.id)))
                .then_with(|| b.version_rank.cmp(&a.version_rank))
                .then_with(|| a.id.cmp(&b.id))
        });
        let has_concrete = indices.iter().any(|&i| !is_rolling_alias(&models[i].id) && !is_preview_id(&models[i].id));
        let mut stable_n = 0usize;
        let mut preview_n = 0usize;
        for &i in indices.iter() {
            if !picker_family_ok(&models[i]) {
                models[i].enabled = false;
                continue;
            }
            let alias = is_rolling_alias(&models[i].id);
            if is_preview_id(&models[i].id) {
                preview_n += 1;
                models[i].enabled = !alias && preview_n <= PICKER_PREVIEW_KEEP;
                continue;
            }
            if alias && has_concrete {
                models[i].enabled = false;
                continue;
            }
            stable_n += 1;
            models[i].enabled = stable_n <= PICKER_STABLE_KEEP;
        }
    }
}

/// Recompute family and version from each id, keep the newest rows per line, write `sort_order`.
pub fn assign_picker_order(models: &mut [LlmModelRow]) {
    refresh_rank_fields(models);
    apply_picker_window(models);
    let daily_lead = daily_lead_providers(models);
    let mut enabled: Vec<usize> = (0..models.len()).filter(|&i| models[i].enabled).collect();
    enabled.sort_by(|&a, &b| picker_cmp(&models[a], &models[b], &daily_lead));
    for (n, i) in enabled.into_iter().enumerate() {
        models[i].sort_order = n as i32;
    }
    let mut disabled_n = 0i32;
    for m in models.iter_mut().filter(|m| !m.enabled) {
        m.sort_order = SORT_DISABLED + disabled_n;
        disabled_n += 1;
    }
}

/// Interactive chat / prompt picker only (not batch jobs, embeddings, etc.).
pub fn chat_picker_id_eligible(id: &str) -> bool {
    let m = id.to_ascii_lowercase();
    if m.contains("(batch)") {
        return false;
    }
    if id_tokens(id).iter().any(|t| t == "batch") {
        return false;
    }
    true
}

pub fn chat_picker_label_eligible(label: &str) -> bool {
    !label.to_ascii_lowercase().contains("(batch)")
}

pub fn chat_picker_row_eligible(m: &LlmModelRow) -> bool {
    if m.provider == "alienai" || m.id == "alienai" {
        return true;
    }
    if !chat_picker_id_eligible(&m.id) || !chat_picker_id_eligible(&m.provider_model) {
        return false;
    }
    if !chat_picker_label_eligible(&m.label) {
        return false;
    }
    if m.provider == "google" {
        return gemini_chat_eligible(&m.id, &["generateContent".into()]);
    }
    true
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
    fn batch_slug_not_picker_eligible() {
        assert!(!chat_picker_id_eligible("openai/gpt-oss-120b-batch"));
        assert!(!chat_picker_label_eligible("OpenAI: gpt-oss-120b (batch)"));
        assert!(chat_picker_id_eligible("openai/gpt-oss-120b"));
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

    fn sample(id: &str, provider: &str) -> LlmModelRow {
        LlmModelRow {
            id: id.into(),
            provider: provider.into(),
            label: id.into(),
            provider_model: id.into(),
            input_micro_per_m: 0,
            output_micro_per_m: 0,
            supports_thinking: false,
            enabled: true,
            is_default: false,
            sort_order: 0,
            family: String::new(),
            version_rank: 0,
            source: "api".into(),
        }
    }

    #[test]
    fn family_reads_product_line_from_id() {
        assert_eq!(family_of("gpt-5.2-luna"), "luna");
        assert_eq!(family_of("gpt-5-mini"), "mini");
        assert_eq!(family_of("claude-sonnet-4-5"), "sonnet");
        assert_eq!(family_of("claude-3-5-haiku-latest"), "haiku");
        assert_eq!(family_of("o3-mini"), "mini");
        assert_eq!(family_of("o3"), "reasoner");
    }

    #[test]
    fn picker_puts_current_common_models_first() {
        let mut models = vec![
            sample("gemini-2.5-flash", "google"),
            sample("gemini-flash-latest", "google"),
            sample("gemini-2.5-flash-lite", "google"),
            sample("gemini-flash-lite-latest", "google"),
            sample("gemini-3.1-flash-lite-preview", "google"),
            sample("gemini-3.5-flash-lite", "google"),
            sample("gemini-3.1-flash-lite", "google"),
            sample("gemini-3.8-flash", "google"),
            sample("gemini-3.7-flash", "google"),
            sample("gemini-3.6-flash", "google"),
            sample("gemini-2.5-pro", "google"),
            sample("gemini-pro-latest", "google"),
            sample("gpt-4.1", "openai"),
            sample("gpt-4.1-mini", "openai"),
            sample("gpt-4o", "openai"),
            sample("gpt-5.2-luna", "openai"),
            sample("gpt-5-mini", "openai"),
            sample("grok-2-latest", "xai"),
        ];
        assign_picker_order(&mut models);
        let enabled: Vec<&str> = models.iter().filter(|m| m.enabled).map(|m| m.id.as_str()).collect();
        assert!(!enabled.contains(&"gemini-flash-latest"));
        assert!(!enabled.contains(&"gemini-flash-lite-latest"));
        assert!(!enabled.contains(&"gemini-2.5-flash"));
        assert!(!enabled.contains(&"gemini-3.6-flash"));
        assert!(enabled.contains(&"grok-2-latest"));
        let mut shown: Vec<&LlmModelRow> = models.iter().filter(|m| m.enabled).collect();
        shown.sort_by_key(|m| m.sort_order);
        let ids: Vec<&str> = shown.iter().map(|m| m.id.as_str()).collect();
        assert_eq!(
            ids,
            vec![
                "gpt-5.2-luna",
                "gpt-4.1",
                "gpt-4o",
                "gpt-5-mini",
                "gpt-4.1-mini",
                "grok-2-latest",
                "gemini-3.5-flash-lite",
                "gemini-3.1-flash-lite",
                "gemini-3.8-flash",
                "gemini-3.7-flash",
                "gemini-2.5-pro",
                "gemini-3.1-flash-lite-preview",
            ]
        );
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
