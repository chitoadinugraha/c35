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
    let body = json!({
        "config": {
            "encoding": encoding,
            "sampleRateHertz": sample_rate,
            "languageCode": language,
            "enableAutomaticPunctuation": true,
        },
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
    // Filter timestamps like "00:00", "0:00", "00:00 - 00:05", "00:01"
    if t == "00:00" || t == "0:00" || t.starts_with("00:00") {
        return String::new();
    }
    let lower = t.to_ascii_lowercase();
    if lower == "[silence]" || lower == "(silence)" || lower == "silence" || lower == "no speech" {
        return String::new();
    }
    // If the entire text consists only of digits, colons, hyphens, and whitespace, it's a timestamp marker
    if t.chars().all(|c| c.is_ascii_digit() || c == ':' || c == '-' || c == ' ' || c == '–' || c == '—') {
        return String::new();
    }
    t.to_string()
}

const TRANSCRIBE_PROMPT: &str =
    "Transcribe the spoken audio verbatim. Reply with only the spoken words. If no speech is heard or if there is only silence, noise, or breathing, return an empty string. Never return timestamps (such as 00:00), duration markers, explanations, or commentary.";

const TRANSCRIBE_PROMPT_ID: &str =
    "Transkripsikan pesan suara ini dengan akurat dalam Bahasa Indonesia atau bahasa yang digunakan penutur. Balas hanya dengan kata-kata yang diucapkan, tanpa tanda kutip atau komentar. PENTING: Jika tidak ada ucapan manusia yang jelas atau hanya ada hening/suara latar, jangan kembalikan apapun (balas teks kosong). Jangan berikan penanda waktu atau timestamp seperti 00:00.";

pub async fn gemini_stt(client: &reqwest::Client, audio: &[u8], mime: &str, lang: &str) -> Result<String> {
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
    let prompt = if lang.starts_with("id") {
        TRANSCRIBE_PROMPT_ID
    } else {
        TRANSCRIBE_PROMPT
    };
    let body = json!({
        "contents": [{
            "parts": [
                {
                    "inline_data": {
                        "mime_type": effective_mime,
                        "data": STANDARD.encode(audio)
                    }
                },
                { "text": prompt }
            ]
        }],
        "generationConfig": {
            "temperature": 0.1,
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
