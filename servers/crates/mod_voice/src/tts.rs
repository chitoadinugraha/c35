use anyhow::{bail, Context, Result};
use base64::{engine::general_purpose::STANDARD, Engine as _};
use serde_json::json;

use crate::stt::lang_normalize;

const TTS_ATTEMPTS: usize = 2;
/// Google TTS rejects input over 5000 bytes; stay under it.
const TTS_MAX_BYTES: usize = 4500;

/// Truncates to at most `max` bytes on a char boundary, preferring the last whitespace.
pub fn cap_tts_text(text: &str, max: usize) -> &str {
    if text.len() <= max {
        return text;
    }
    let mut end = max;
    while !text.is_char_boundary(end) {
        end -= 1;
    }
    let cut = &text[..end];
    match cut.rfind(char::is_whitespace) {
        Some(i) if i > max / 2 => cut[..i].trim_end(),
        _ => cut,
    }
}

pub async fn google_tts(client: &reqwest::Client, text: &str, lang: &str) -> Result<(Vec<u8>, String)> {
    let text = cap_tts_text(text, TTS_MAX_BYTES);
    let key = std::env::var("GOOGLE_CLOUD_API_KEY")
        .or_else(|_| std::env::var("GOOGLE_API_KEY"))
        .or_else(|_| std::env::var("GEMINI_API_KEY"))
        .context("GOOGLE_CLOUD_API_KEY / GOOGLE_API_KEY / GEMINI_API_KEY not set")?
        .trim()
        .to_string();
    let language = lang_normalize(lang);
    let body = json!({
        "input": { "text": text },
        "voice": {
            "languageCode": language,
            "ssmlGender": "NEUTRAL",
        },
        "audioConfig": {
            "audioEncoding": "MP3",
            "speakingRate": 1.0,
        }
    });
    let url = format!("https://texttospeech.googleapis.com/v1/text:synthesize?key={}", key);
    let mut last_err: Option<anyhow::Error> = None;
    let mut payload = String::new();
    for attempt in 0..TTS_ATTEMPTS {
        if attempt > 0 {
            tokio::time::sleep(std::time::Duration::from_millis(300)).await;
        }
        match client.post(&url).json(&body).send().await {
            Err(e) => {
                last_err = Some(anyhow::Error::new(e).context("tts api request failed"));
            }
            Ok(res) => {
                let status = res.status();
                match res.text().await {
                    Err(e) => {
                        last_err = Some(anyhow::Error::new(e).context("tts api read failed"));
                    }
                    Ok(text) if status.is_success() => {
                        payload = text;
                        last_err = None;
                        break;
                    }
                    Ok(text) => {
                        let transient = status.as_u16() == 429 || status.is_server_error();
                        last_err = Some(anyhow::anyhow!("tts api error ({status}): {text}"));
                        if !transient {
                            break;
                        }
                    }
                }
            }
        }
    }
    if let Some(e) = last_err {
        return Err(e);
    }
    let v: serde_json::Value = serde_json::from_str(&payload).context("tts api json")?;
    if let Some(err) = v.get("error") {
        bail!("tts api: {err}");
    }
    let b64 = v
        .get("audioContent")
        .and_then(|a| a.as_str())
        .context("tts api missing audioContent")?;
    let bytes = STANDARD.decode(b64).context("tts audio decode")?;
    Ok((bytes, "audio/mpeg".into()))
}

#[cfg(test)]
mod tests {
    use super::cap_tts_text;

    #[test]
    fn cap_tts_text_respects_limit_and_char_boundary() {
        assert_eq!(cap_tts_text("short", 100), "short");
        let long = "kata ".repeat(2000);
        let capped = cap_tts_text(&long, 4500);
        assert!(capped.len() <= 4500);
        let multi = "é".repeat(3000);
        assert!(cap_tts_text(&multi, 4501).len() <= 4501);
    }
}
