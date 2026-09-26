use anyhow::{bail, Context, Result};
use base64::{engine::general_purpose::STANDARD, Engine as _};
use serde_json::json;

use crate::billing::wav_sample_rate_hz;

pub fn stt_encoding(mime: &str) -> Result<(&'static str, u32)> {
    let m = mime.to_ascii_lowercase();
    if m.contains("wav") {
        return Ok(("LINEAR16", 16_000));
    }
    if m.contains("ogg") || m.contains("opus") {
        return Ok(("OGG_OPUS", 48_000));
    }
    if m.contains("webm") {
        return Ok(("WEBM_OPUS", 48_000));
    }
    if m.contains("flac") {
        return Ok(("FLAC", 16_000));
    }
    bail!("unsupported audio mime: {mime}")
}

pub async fn google_stt(client: &reqwest::Client, audio: &[u8], mime: &str, lang: &str) -> Result<String> {
    let key = std::env::var("GOOGLE_CLOUD_API_KEY")
        .or_else(|_| std::env::var("GOOGLE_API_KEY"))
        .context("GOOGLE_CLOUD_API_KEY not set")?;
    let (encoding, default_rate) = stt_encoding(mime)?;
    let sample_rate = wav_sample_rate_hz(audio).unwrap_or(default_rate);
    let language = lang_normalize(lang);
    let mut config = json!({
        "languageCode": language,
        "enableAutomaticPunctuation": true,
    });
    if audio.starts_with(b"RIFF") {
        config["encoding"] = json!("ENCODING_UNSPECIFIED");
    } else {
        config["encoding"] = json!(encoding);
        config["sampleRateHertz"] = json!(sample_rate);
    }
    let body = json!({
        "config": config,
        "audio": {
            "content": STANDARD.encode(audio),
        }
    });
    let url = format!("https://speech.googleapis.com/v1/speech:recognize?key={}", key);
    let res = client
        .post(&url)
        .json(&body)
        .send()
        .await
        .context("speech api request failed")?;
    let status = res.status();
    let payload = res.text().await.context("speech api read failed")?;
    if !status.is_success() {
        bail!("speech api error ({status}): {payload}");
    }
    let v: serde_json::Value = serde_json::from_str(&payload).context("speech api json")?;
    if let Some(err) = v.get("error") {
        bail!("speech api: {err}");
    }
    let text = v
        .get("results")
        .and_then(|r| r.as_array())
        .and_then(|arr| arr.first())
        .and_then(|r| r.get("alternatives"))
        .and_then(|a| a.as_array())
        .and_then(|a| a.first())
        .and_then(|a| a.get("transcript"))
        .and_then(|t| t.as_str())
        .unwrap_or("")
        .trim();
    Ok(sanitize_transcript(text))
}

pub fn sanitize_transcript(raw: &str) -> String {
    let t = raw.trim();
    if t.is_empty() {
        return String::new();
    }
    if t.contains("[NO_SPEECH]") || t.contains("NO_SPEECH") {
        return String::new();
    }
    // Filter timestamps like "00:00", "0:00", "00:00 - 00:05", "00:01"
    if t == "00:00" || t == "0:00" || t.starts_with("00:00") {
        return String::new();
    }
    let lower = t.to_ascii_lowercase();
    if lower == "[silence]" || lower == "(silence)" || lower == "silence" || lower == "no speech" {
        return String::new();
    }
    let stripped = lower.trim_end_matches(|c: char| c == '.' || c == '!' || c == '?' || c == ',' || c == '…').trim();
    if stripped == "thank you"
        || stripped == "thanks"
        || stripped == "thank you very much"
        || stripped == "thanks for watching"
        || stripped == "thank you for watching"
        || stripped == "terima kasih"
        || stripped == "terima kasih banyak"
        || stripped == "terima kasih sudah menonton"
        || stripped == "terima kasih telah menonton"
        || stripped == "terima kasih sudah menyaksikan"
        || stripped == "makasih"
        || stripped == "makasih banyak"
        || stripped == "sampai jumpa"
        || stripped == "sampai jumpa lagi"
        || stripped == "you"
        || stripped == "bye"
    {
        return String::new();
    }
    if stripped.starts_with("subtitles by") || stripped.starts_with("subtitle by") {
        return String::new();
    }
    // If the entire text consists only of digits, colons, hyphens, and whitespace, it's a timestamp marker
    if t.chars().all(|c| c.is_ascii_digit() || c == ':' || c == '-' || c == ' ' || c == '–' || c == '—') {
        return String::new();
    }
    t.to_string()
}

const SYSTEM_TRANSCRIBE: &str =
    "You are a specialized audio speech transcriber. Listen carefully to the audio. If you hear actual human speech, output the verbatim transcription in the language spoken. Never add commentary, explanations, quotes, markdown formatting, or timestamps. If there are NO spoken words, or only silence, ambient noise, static, or breathing, output exactly: [NO_SPEECH]";

pub async fn gemini_stt(client: &reqwest::Client, audio: &[u8], mime: &str, _lang: &str) -> Result<String> {
    let key = std::env::var("GEMINI_API_KEY")
        .or_else(|_| std::env::var("GOOGLE_API_KEY"))
        .or_else(|_| std::env::var("GOOGLE_CLOUD_API_KEY"))
        .context("GEMINI_API_KEY not set")?;
    let effective_mime = if mime.is_empty() || mime == "application/octet-stream" {
        "audio/wav"
    } else {
        mime.split(';').next().unwrap_or(mime).trim()
    };
    let model = "gemini-3.1-flash-lite";
    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    );
    let body = json!({
        "system_instruction": {
            "parts": [{ "text": SYSTEM_TRANSCRIBE }]
        },
        "contents": [{
            "parts": [
                {
                    "inline_data": {
                        "mime_type": effective_mime,
                        "data": STANDARD.encode(audio)
                    }
                },
                { "text": "Transcribe the spoken words in the audio, or output [NO_SPEECH] if silent." }
            ]
        }],
        "generationConfig": {
            "temperature": 0.0,
            "maxOutputTokens": 1024
        }
    });
    let res = client
        .post(&url)
        .json(&body)
        .send()
        .await
        .context("gemini speech api request failed")?;
    let status = res.status();
    let payload = res.text().await.context("gemini speech api read failed")?;
    if !status.is_success() {
        bail!("gemini speech error ({status}): {payload}");
    }
    let v: serde_json::Value = serde_json::from_str(&payload).context("gemini speech json")?;
    if let Some(err) = v.get("error") {
        bail!("gemini speech: {err}");
    }
    let raw = v
        .get("candidates")
        .and_then(|c| c.as_array())
        .and_then(|arr| arr.first())
        .and_then(|c| c.get("content"))
        .and_then(|c| c.get("parts"))
        .and_then(|p| p.as_array())
        .and_then(|arr| arr.first())
        .and_then(|p| p.get("text"))
        .and_then(|t| t.as_str())
        .unwrap_or("")
        .trim();
    Ok(sanitize_transcript(raw))
}

pub fn lang_normalize(lang: &str) -> String {
    let lang = lang.trim();
    if lang.is_empty() || lang.eq_ignore_ascii_case("auto") {
        return "id-ID".into();
    }
    if lang.contains('-') {
        return lang.to_string();
    }
    match lang.to_ascii_lowercase().as_str() {
        "en" => "en-US".into(),
        "id" => "id-ID".into(),
        "ja" => "ja-JP".into(),
        "ko" => "ko-KR".into(),
        "zh" => "zh-CN".into(),
        other => {
            let upper = other.to_uppercase();
            format!("{other}-{upper}")
        }
    }
}

pub async fn cf_whisper_stt(
    client: &reqwest::Client,
    audio: &[u8],
    _mime: &str,
    lang: &str,
    _is_interim: bool,
) -> Result<String> {
    let token = std::env::var("CLOUDFLARE_API_TOKEN")
        .or_else(|_| std::env::var("CLOUDFLARE_TOKEN"))
        .or_else(|_| std::env::var("CF_API_TOKEN"))
        .context("CLOUDFLARE_API_TOKEN not set")?;
    let account_id = std::env::var("CLOUDFLARE_ACCOUNT_ID")
        .or_else(|_| std::env::var("CF_ACCOUNT_ID"))
        .unwrap_or_else(|_| "13bbda4c964029cb15bb16c7d57ec548".to_string());

    let url = if let Ok(gateway_url) = std::env::var("CLOUDFLARE_AI_GATEWAY_URL") {
        gateway_url
    } else if let Ok(gateway_id) = std::env::var("CLOUDFLARE_AI_GATEWAY_ID") {
        format!(
            "https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/workers-ai/@cf/openai/whisper-large-v3-turbo"
        )
    } else {
        format!(
            "https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run/@cf/openai/whisper-large-v3-turbo"
        )
    };

    let iso_lang = lang.split('-').next().unwrap_or(lang).trim().to_ascii_lowercase();
    let b64 = STANDARD.encode(audio);
    let mut payload = json!({
        "audio": b64,
        "vad_filter": true,
        "condition_on_previous_text": false,
        "temperature": 0.0,
    });
    if !iso_lang.is_empty() && iso_lang != "auto" {
        payload["language"] = json!(iso_lang);
    }

    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {token}"))
        .header("Content-Type", "application/json")
        .json(&payload)
        .send()
        .await
        .context("cloudflare whisper request failed")?;

    let status = res.status();
    let payload_str = res.text().await.context("cloudflare whisper read failed")?;
    if !status.is_success() {
        bail!("cloudflare whisper error ({status}): {payload_str}");
    }
    let v: serde_json::Value = serde_json::from_str(&payload_str).context("cloudflare whisper json")?;
    if let Some(err) = v.get("errors").and_then(|e| e.as_array()).and_then(|a| a.first()) {
        bail!("cloudflare whisper error: {err}");
    }
    let text = v
        .get("result")
        .and_then(|r| r.get("text"))
        .or_else(|| v.get("text"))
        .and_then(|t| t.as_str())
        .unwrap_or("")
        .trim();
    Ok(sanitize_transcript(text))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lang_normalize() {
        assert_eq!(lang_normalize("id"), "id-ID");
        assert_eq!(lang_normalize(""), "id-ID");
        assert_eq!(lang_normalize("auto"), "id-ID");
        assert_eq!(lang_normalize("en"), "en-US");
        assert_eq!(lang_normalize("en-GB"), "en-GB");
    }

    #[test]
    fn test_sanitize_transcript() {
        assert_eq!(sanitize_transcript(""), "");
        assert_eq!(sanitize_transcript("   "), "");
        assert_eq!(sanitize_transcript("[NO_SPEECH]"), "");
        assert_eq!(sanitize_transcript("NO_SPEECH"), "");
        assert_eq!(sanitize_transcript("00:00"), "");
        assert_eq!(sanitize_transcript("00:00 - 00:05"), "");
        assert_eq!(sanitize_transcript("[silence]"), "");
        assert_eq!(sanitize_transcript("Terima kasih."), "");
        assert_eq!(sanitize_transcript("Terima kasih!"), "");
        assert_eq!(sanitize_transcript("terima kasih sudah menonton."), "");
        assert_eq!(sanitize_transcript("Sampai jumpa."), "");
        assert_eq!(sanitize_transcript("Thank you."), "");
        assert_eq!(sanitize_transcript("Halo selamat pagi"), "Halo selamat pagi");
    }

    #[test]
    fn test_cf_whisper_json_parsing() {
        let sample1 = r#"{"result":{"text":"Halo dunia"},"success":true}"#;
        let v: serde_json::Value = serde_json::from_str(sample1).unwrap();
        let text = v.get("result").and_then(|r| r.get("text")).or_else(|| v.get("text")).and_then(|t| t.as_str()).unwrap();
        assert_eq!(text, "Halo dunia");

        let sample2 = r#"{"text":"Halo dunia gateway"}"#;
        let v2: serde_json::Value = serde_json::from_str(sample2).unwrap();
        let text2 = v2.get("result").and_then(|r| r.get("text")).or_else(|| v2.get("text")).and_then(|t| t.as_str()).unwrap();
        assert_eq!(text2, "Halo dunia gateway");
    }
}

