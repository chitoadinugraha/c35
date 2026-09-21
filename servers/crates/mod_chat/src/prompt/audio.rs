use anyhow::{anyhow, Context, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use reqwest::Client;
use serde_json::{json, Value};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::process::Command;
use tracing::info;

use c35_mod_llm::alien_chain_models;
use super::gemini::gemini_api_key;

const TRANSCRIBE_PROMPT: &str =
    "Transcribe this voice message accurately. The speaker may use Indonesian (Bahasa Indonesia) or English. Reply with only the spoken words, no quotes or commentary.";
const TRANSCRIBE_LANGS: &[&str] = &["id-ID", "en-US"];

pub fn audio_mime_resolve(item_mime: &str, download_mime: &str, bytes: &[u8]) -> String {
    for mime in [item_mime, download_mime] {
        let m = mime.split(';').next().unwrap_or(mime).trim();
        if m.starts_with("audio/") && m != "audio/octet-stream" {
            return m.to_string();
        }
    }
    if bytes.len() >= 4 && bytes[..4] == *b"OggS" {
        return "audio/ogg".into();
    }
    if bytes.len() >= 3 && (bytes[..3] == *b"ID3" || bytes[..3] == *b"Ogg") {
        return if bytes[..4] == *b"OggS" { "audio/ogg".into() } else { "audio/mpeg".into() };
    }
    if bytes.len() >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0 {
        return "audio/mpeg".into();
    }
    "audio/ogg".into()
}

pub fn is_ogg_audio(mime: &str, bytes: &[u8]) -> bool {
    let m = mime.to_lowercase();
    if m.contains("ogg") || m.contains("opus") {
        return true;
    }
    bytes.len() >= 4 && bytes[..4] == *b"OggS"
}

pub async fn ffmpeg_to_wav_16k_mono(audio: &[u8]) -> Result<Vec<u8>> {
    let mut child = Command::new("ffmpeg")
        .args([
            "-hide_banner", "-loglevel", "error", "-f", "ogg", "-i", "pipe:0",
            "-f", "wav", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", "pipe:1",
        ])
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .context("ffmpeg spawn")?;
    let mut stdin = child.stdin.take().context("ffmpeg stdin")?;
    let mut stdout = child.stdout.take().context("ffmpeg stdout")?;
    let stderr = child.stderr.take();
    let input = audio.to_vec();
    let write = tokio::spawn(async move {
        stdin.write_all(&input).await.context("ffmpeg stdin write")?;
        stdin.shutdown().await.context("ffmpeg stdin shutdown")?;
        Ok::<(), anyhow::Error>(())
    });
    let mut wav = Vec::new();
    stdout.read_to_end(&mut wav).await.context("ffmpeg stdout read")?;
    write.await.context("ffmpeg stdin task")??;
    let status = child.wait().await.context("ffmpeg wait")?;
    if !status.success() {
        let err = if let Some(mut s) = stderr {
            let mut buf = Vec::new();
            let _ = s.read_to_end(&mut buf).await;
            String::from_utf8_lossy(&buf).trim().to_string()
        } else {
            String::new()
        };
        return Err(anyhow!("ffmpeg exit {:?}: {err}", status.code()));
    }
    if wav.len() <= 44 {
        return Err(anyhow!("ffmpeg produced empty wav"));
    }
    Ok(wav)
}

pub async fn stt_audio_prepare(audio: &[u8], mime: &str) -> Result<(Vec<u8>, String)> {
    let mime = audio_mime_resolve(mime, mime, audio);
    if !is_ogg_audio(&mime, audio) {
        return Ok((audio.to_vec(), mime));
    }
    let wav = ffmpeg_to_wav_16k_mono(audio).await.context("ogg->wav required for voice stt")?;
    Ok((wav, "audio/wav".into()))
}

pub fn transcript_valid(t: &str) -> bool {
    let t = t.trim();
    if t.len() < 2 {
        return false;
    }
    let lower = t.to_lowercase();
    for bad in [
        "cannot transcribe", "can't transcribe", "unable to process", "unable to transcribe",
        "raw ogg opus", "binary representation", "tidak bisa memproses", "file suara",
    ] {
        if lower.contains(bad) {
            return false;
        }
    }
    true
}

pub async fn transcribe_audio(client: &Client, audio: &[u8], mime: &str) -> Result<String> {
    if audio.len() < 16 {
        return Err(anyhow!("audio too short ({} bytes)", audio.len()));
    }
    let (audio, mime) = stt_audio_prepare(audio, mime).await?;
    info!("[c35:audio] stt prepared mime={mime} bytes={}", audio.len());
    let mut last_err;
    match gemini_transcribe(client, &audio, &mime).await {
        Ok(t) if transcript_valid(&t) => return Ok(t),
        Ok(t) => last_err = format!("gemini stt rejected: {}", t.chars().take(80).collect::<String>()),
        Err(e) => last_err = format!("gemini: {e:#}"),
    }
    for lang in TRANSCRIBE_LANGS {
        match google_chromium_transcribe(client, &audio, lang, &mime).await {
            Ok(t) if transcript_valid(&t) => return Ok(t),
            Ok(_) => last_err = format!("{last_err}; chromium stt {lang}: rejected transcript"),
            Err(e) => last_err = format!("{last_err}; chromium stt {lang}: {e:#}"),
        }
    }
    Err(anyhow!(last_err))
}

async fn google_chromium_transcribe(client: &Client, audio: &[u8], lang: &str, mime: &str) -> Result<String> {
    let url = format!(
        "https://www.google.com/speech-api/v2/recognize?output=json&lang={}&client=chromium",
        urlencoding::encode(lang)
    );
    let res = client
        .post(&url)
        .header("Content-Type", mime)
        .header("User-Agent", "Mozilla/5.0 Chrome/120.0.0.0")
        .body(audio.to_vec())
        .send()
        .await
        .context("chromium stt request")?;
    if !res.status().is_success() {
        return Err(anyhow!("chromium stt status {}", res.status()));
    }
    let body = res.text().await.context("chromium stt body")?;
    for line in body.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let v: Value = serde_json::from_str(line).with_context(|| format!("chromium stt json: {line}"))?;
        let text = v
            .get("result")
            .and_then(|r| r.as_array())
            .and_then(|arr| arr.first())
            .and_then(|r| r.get("alternative"))
            .and_then(|a| a.as_array())
            .and_then(|a| a.first())
            .and_then(|a| a.get("transcript"))
            .and_then(|t| t.as_str())
            .map(str::trim)
            .filter(|t| !t.is_empty());
        if let Some(t) = text {
            return Ok(t.to_string());
        }
    }
    Err(anyhow!("chromium stt empty result"))
}

pub async fn gemini_transcribe(client: &Client, audio: &[u8], mime: &str) -> Result<String> {
    let mime = audio_mime_resolve(mime, mime, audio);
    let api_key = gemini_api_key();
    let mut last_err = String::new();
    for model in alien_chain_models() {
        let url = format!(
            "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        );
        let payload = json!({
            "contents": [{
                "parts": [
                    { "inline_data": { "mime_type": mime, "data": STANDARD.encode(&audio) } },
                    { "text": TRANSCRIBE_PROMPT }
                ]
            }],
            "generationConfig": { "temperature": 0.1, "maxOutputTokens": 1024 }
        });
        let res = client.post(&url).json(&payload).send().await.with_context(|| format!("gemini transcribe {model}"))?;
        if !res.status().is_success() {
            last_err = format!("gemini transcribe {model} {}", res.status());
            continue;
        }
        let v: Value = res.json().await.with_context(|| format!("gemini transcribe json {model}"))?;
        if let Some(text) = extract_gemini_text(&v) {
            return Ok(text);
        }
        last_err = format!("gemini transcribe {model}: empty response");
    }
    Err(anyhow!(last_err))
}

fn extract_gemini_text(v: &Value) -> Option<String> {
    v.get("candidates")?
        .as_array()?
        .first()?
        .get("content")?
        .get("parts")?
        .as_array()?
        .iter()
        .filter_map(|p| p.get("text").and_then(|t| t.as_str()))
        .map(str::trim)
        .find(|t| !t.is_empty())
        .map(str::to_string)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn audio_mime_resolve_detects_ogg_magic() {
        assert_eq!(audio_mime_resolve("", "application/octet-stream", b"OggS\x00"), "audio/ogg");
    }

    #[test]
    fn transcript_valid_rejects_refusal() {
        assert!(!transcript_valid("I'm sorry, but I cannot transcribe this file."));
        assert!(transcript_valid("besok hari apa"));
    }
}
