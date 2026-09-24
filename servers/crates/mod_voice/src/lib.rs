mod billing;
mod stt;
mod tts;

use std::time::Instant;

use anyhow::Result;
use async_nats::Client;
use c35_proto::{ReqVoiceStt, ReqVoiceTts, ResVoiceStt, ResVoiceTts};
use sqlx::PgPool;

pub use billing::{
    estimate_stt_cost_usd, estimate_stt_duration, estimate_tts_cost_usd, voice_billing_abort,
    voice_billing_gate, voice_billing_settle, voice_req_id, voice_stt_wholesale_usd,
    voice_tts_wholesale_usd, VOICE_STT_HOLD, VOICE_TTS_HOLD,
};

static HTTP: std::sync::OnceLock<reqwest::Client> = std::sync::OnceLock::new();

fn http_client() -> &'static reqwest::Client {
    HTTP.get_or_init(|| reqwest::Client::new())
}

pub async fn voice_stt(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: &str,
    audio: &[u8],
    mime: &str,
    lang: &str,
) -> Result<String> {
    let started = Instant::now();
    let req_id = voice_req_id("voice_stt_", req_id);
    if req_id.is_empty() {
        anyhow::bail!("req_id required");
    }
    if audio.is_empty() {
        anyhow::bail!("audio required");
    }
    let is_interim = req_id.contains("interim");
    let row = if is_interim {
        None
    } else {
        Some(voice_billing_gate(pool, owner_iid, &req_id, VOICE_STT_HOLD).await?)
    };
    let text_res = if std::env::var("GOOGLE_CLOUD_API_KEY").is_ok() {
        match stt::google_stt(http_client(), audio, mime, lang).await {
            Ok(t) => Ok(t),
            Err(e) => {
                tracing::warn!("google_stt failed, falling back to gemini 3.1 flash lite: {e}");
                stt::gemini_stt(http_client(), audio, mime, lang).await
            }
        }
    } else {
        stt::gemini_stt(http_client(), audio, mime, lang).await
    };
    let text = match text_res {
        Ok(t) => t,
        Err(e) => {
            if row.is_some() {
                let _ = voice_billing_abort(pool, &req_id).await;
            }
            return Err(e);
        }
    };
    if text.trim().is_empty() {
        if row.is_some() {
            let _ = voice_billing_abort(pool, &req_id).await;
        }
        anyhow::bail!("No speech detected");
    }
    if let Some(row) = row {
        let wholesale = voice_stt_wholesale_usd(audio, mime);
        let duration_ms = started.elapsed().as_millis().min(i32::MAX as u128) as i32;
        let meta = serde_json::json!({
            "sku": "voice_stt",
            "mime": mime,
            "lang": lang,
            "audio_bytes": audio.len(),
            "wholesale_usd": wholesale,
        });
        voice_billing_settle(
            pool,
            nats,
            owner_iid,
            &row,
            &req_id,
            wholesale,
            "voice_stt",
            &text,
            "google.speech",
            duration_ms,
            meta,
        )
        .await?;
    }
    Ok(text)
}

pub async fn voice_tts(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: &str,
    text: &str,
    lang: &str,
) -> Result<(Vec<u8>, String)> {
    let started = Instant::now();
    let req_id = voice_req_id("voice_tts_", req_id);
    if req_id.is_empty() {
        anyhow::bail!("req_id required");
    }
    let spoken = text.trim();
    if spoken.is_empty() {
        anyhow::bail!("text required");
    }
    let row = voice_billing_gate(pool, owner_iid, &req_id, VOICE_TTS_HOLD).await?;
    let (audio, mime) = match tts::google_tts(http_client(), spoken, lang).await {
        Ok(v) => v,
        Err(e) => {
            let _ = voice_billing_abort(pool, &req_id).await;
            return Err(e);
        }
    };
    let wholesale = voice_tts_wholesale_usd(spoken);
    let duration_ms = started.elapsed().as_millis().min(i32::MAX as u128) as i32;
    let meta = serde_json::json!({
        "sku": "voice_tts",
        "lang": lang,
        "chars": spoken.chars().count(),
        "wholesale_usd": wholesale,
    });
    voice_billing_settle(
        pool,
        nats,
        owner_iid,
        &row,
        &req_id,
        wholesale,
        "voice_tts",
        spoken,
        "google.tts",
        duration_ms,
        meta,
    )
    .await?;
    Ok((audio, mime))
}

pub async fn voice_stt_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqVoiceStt,
) -> ResVoiceStt {
    match voice_stt(pool, nats, owner_iid, &req.req_id, &req.audio, &req.mime, &req.lang).await {
        Ok(text) => ResVoiceStt { text, error: String::new() },
        Err(e) => ResVoiceStt {
            text: String::new(),
            error: friendly_error(&e),
        },
    }
}

pub async fn voice_tts_rpc(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req: ReqVoiceTts,
) -> ResVoiceTts {
    match voice_tts(pool, nats, owner_iid, &req.req_id, &req.text, &req.lang).await {
        Ok((audio, mime)) => ResVoiceTts {
            audio,
            mime,
            error: String::new(),
        },
        Err(e) => ResVoiceTts {
            audio: Vec::new(),
            mime: String::new(),
            error: friendly_error(&e),
        },
    }
}

fn friendly_error(e: &anyhow::Error) -> String {
    let msg = e.to_string();
    if msg.contains("balance") || msg.contains("quota") || msg.contains("top up") {
        return "Not enough balance for cloud voice. Please top up or wait for quota reset.".into();
    }
    if msg.contains("GOOGLE_CLOUD_API_KEY") || msg.contains("GEMINI_API_KEY") {
        return "Cloud voice is temporarily unavailable.".into();
    }
    if msg.contains("audio required") || msg.contains("text required") || msg.contains("req_id") || msg.contains("No speech detected") {
        return msg;
    }
    tracing::warn!("voice rpc error: {msg}");
    "Cloud voice request failed. Please try again.".into()
}
