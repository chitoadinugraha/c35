use anyhow::{anyhow, Context, Result};
use std::path::PathBuf;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::process::Command;

pub const SMOKE_QUESTION: &str = "What time is it now?";


pub async fn smoke_recording_pcm16k(client: &reqwest::Client) -> Result<(Vec<u8>, PathBuf)> {
    if let Ok(p) = std::env::var("LIVE_SMOKE_WAV") {
        let path = PathBuf::from(p.trim());
        let raw = std::fs::read(&path).with_context(|| format!("read {}", path.display()))?;
        let pcm = wav_to_pcm16k(&raw)?;
        return Ok((pcm, path));
    }
    let mp3 = match google_tts_mp3(client).await {
        Ok(b) => b,
        Err(e) => {
            eprintln!("google tts skipped: {e:#}");
            openai_tts_mp3(client).await?
        }
    };
    let wav = ffmpeg_to_wav(mp3, 16_000).await?;
    let pcm = wav_to_pcm(&wav)?;
    let out = smoke_cache_path("question_16k.wav");
    if let Some(dir) = out.parent() {
        std::fs::create_dir_all(dir).ok();
    }
    std::fs::write(&out, &wav).context("write smoke wav")?;
    Ok((pcm, out))
}

pub fn pcm16k_to_pcm24k(pcm16: &[u8]) -> Vec<u8> {
    if pcm16.len() < 2 {
        return Vec::new();
    }
    let frames = pcm16.len() / 2;
    let out_frames = frames * 3 / 2;
    let mut out = Vec::with_capacity(out_frames * 2);
    let mut i = 0f64;
    let step = 2.0 / 3.0;
    while (i as usize) < frames {
        let idx = (i as usize).min(frames - 1) * 2;
        out.extend_from_slice(&pcm16[idx..idx + 2]);
        i += step;
    }
    out
}

pub async fn ffmpeg_to_wav(audio: Vec<u8>, rate: u32) -> Result<Vec<u8>> {
    let mut child = Command::new("ffmpeg")
        .args([
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            "pipe:0",
            "-f",
            "wav",
            "-acodec",
            "pcm_s16le",
            "-ar",
            &rate.to_string(),
            "-ac",
            "1",
            "pipe:1",
        ])
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .context("ffmpeg spawn (is ffmpeg on PATH?)")?;
    let mut stdin = child.stdin.take().context("ffmpeg stdin")?;
    let mut stdout = child.stdout.take().context("ffmpeg stdout")?;
    let write = tokio::spawn(async move {
        stdin.write_all(&audio).await.context("ffmpeg write")?;
        stdin.shutdown().await.context("ffmpeg stdin shutdown")?;
        Ok::<(), anyhow::Error>(())
    });
    let mut wav = Vec::new();
    stdout.read_to_end(&mut wav).await.context("ffmpeg read")?;
    write.await.context("ffmpeg stdin task")??;
    let status = child.wait().await.context("ffmpeg wait")?;
    if !status.success() {
        return Err(anyhow!("ffmpeg failed: {status:?}"));
    }
    if wav.len() <= 44 {
        return Err(anyhow!("ffmpeg produced empty wav"));
    }
    Ok(wav)
}


pub fn wav_to_pcm16k(wav: &[u8]) -> Result<Vec<u8>> {
    if wav.len() < 44 || !wav.starts_with(b"RIFF") {
        return Err(anyhow!("invalid wav"));
    }
    let channels = u16::from_le_bytes([wav[22], wav[23]]) as usize;
    let rate = u32::from_le_bytes([wav[24], wav[25], wav[26], wav[27]]) as usize;
    let bits = u16::from_le_bytes([wav[34], wav[35]]);
    if bits != 16 {
        return Err(anyhow!("wav must be 16-bit PCM"));
    }
    let mut pcm = wav[44..].to_vec();
    if channels == 2 {
        let mut mono = Vec::with_capacity(pcm.len() / 2);
        for ch in pcm.chunks_exact(4) {
            mono.extend_from_slice(&ch[0..2]);
        }
        pcm = mono;
    } else if channels != 1 {
        return Err(anyhow!("unsupported channel count {channels}"));
    }
    if rate == 16_000 {
        return Ok(pcm);
    }
    Ok(resample_pcm16(&pcm, rate, 16_000))
}

fn resample_pcm16(pcm: &[u8], src_rate: usize, dst_rate: usize) -> Vec<u8> {
    let frames = pcm.len() / 2;
    if frames == 0 || src_rate == 0 {
        return Vec::new();
    }
    let dst_frames = frames * dst_rate / src_rate;
    let mut out = Vec::with_capacity(dst_frames * 2);
    for i in 0..dst_frames {
        let src_i = (i * src_rate / dst_rate).min(frames.saturating_sub(1));
        let off = src_i * 2;
        out.extend_from_slice(&pcm[off..off + 2]);
    }
    out
}

pub fn wav_to_pcm(wav: &[u8]) -> Result<Vec<u8>> {
    if wav.len() <= 44 {
        return Err(anyhow!("wav too short"));
    }
    Ok(wav[44..].to_vec())
}

pub fn smoke_cache_path(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../../.cache/live-smoke")
        .join(name)
}

async fn google_tts_mp3(client: &reqwest::Client) -> Result<Vec<u8>> {
    let (mp3, _) = c35_mod_voice::google_tts(client, SMOKE_QUESTION, "en-US").await?;
    Ok(mp3)
}

async fn openai_tts_mp3(client: &reqwest::Client) -> Result<Vec<u8>> {
    let key = std::env::var("OPENAI_API_KEY")
        .or_else(|_| std::env::var("OPENAI_KEY"))
        .context("OPENAI_API_KEY not set (needed for TTS fallback)")?;
    let res = client
        .post("https://api.openai.com/v1/audio/speech")
        .header("Authorization", format!("Bearer {}", key.trim()))
        .json(&serde_json::json!({
            "model": "tts-1",
            "voice": "alloy",
            "input": SMOKE_QUESTION,
            "response_format": "mp3"
        }))
        .send()
        .await
        .context("openai tts")?;
    if !res.status().is_success() {
        return Err(anyhow!("openai tts {}: {}", res.status(), res.text().await.unwrap_or_default()));
    }
    Ok(res.bytes().await.context("openai tts body")?.to_vec())
}