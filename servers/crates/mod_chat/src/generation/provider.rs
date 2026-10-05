const KNOWN: &[&str] = &[
    "auto", "gemini", "grok", "seedance", "elevenlabs", "lyria", "minimax",
];

pub fn provider_normalize(raw: &str) -> String {
    let s = raw.trim().to_ascii_lowercase();
    if s.is_empty() {
        return "auto".into();
    }
    if KNOWN.contains(&s.as_str()) {
        return s;
    }
    "auto".into()
}

pub fn media_provider_label(provider: &str) -> String {
    match provider_normalize(provider).as_str() {
        "auto" => "Auto".into(),
        "gemini" | "lyria" => "Gemini".into(),
        "grok" => "Grok".into(),
        "seedance" => "Seedance".into(),
        "elevenlabs" => "ElevenLabs".into(),
        "minimax" => "MiniMax".into(),
        other => other.to_string(),
    }
}

pub fn image_provider_allowed(provider: &str) -> bool {
    matches!(provider_normalize(provider).as_str(), "auto" | "gemini" | "grok")
}

pub fn video_provider_allowed(provider: &str) -> bool {
    matches!(provider_normalize(provider).as_str(), "auto" | "seedance" | "gemini")
}

pub fn music_provider_allowed(provider: &str) -> bool {
    matches!(
        provider_normalize(provider).as_str(),
        "auto" | "gemini" | "elevenlabs" | "lyria" | "minimax"
    )
}
