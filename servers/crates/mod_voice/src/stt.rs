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
        .trim()
        .to_string();
    Ok(text)
}

pub fn lang_normalize(lang: &str) -> String {
    let lang = lang.trim();
    if lang.is_empty() {
        return "en-US".into();
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
