use anyhow::{bail, Context, Result};
use base64::{engine::general_purpose::STANDARD, Engine as _};
use serde_json::json;

use crate::stt::lang_normalize;

pub async fn google_tts(client: &reqwest::Client, text: &str, lang: &str) -> Result<(Vec<u8>, String)> {
    let key = std::env::var("GOOGLE_CLOUD_API_KEY")
        .or_else(|_| std::env::var("GOOGLE_API_KEY"))
        .context("GOOGLE_CLOUD_API_KEY not set")?;
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
    let res = client
        .post(&url)
        .json(&body)
        .send()
        .await
        .context("tts api request failed")?;
    let status = res.status();
    let payload = res.text().await.context("tts api read failed")?;
    if !status.is_success() {
        bail!("tts api error ({status}): {payload}");
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
