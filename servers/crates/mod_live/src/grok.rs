use std::time::Instant;

use anyhow::Result;
use async_nats::Client;
use axum::extract::ws::{Message, WebSocket};
use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_llm::{cf_gateway_config, cf_gateway_ready};
use futures_util::StreamExt;
use serde_json::{json, Value};
use sqlx::PgPool;
use tracing::{debug, warn};

use crate::billing::{live_billing_abort, live_billing_settle};
use crate::session::LiveSessionTicket;

pub async fn live_grok_run(
    pool: PgPool,
    nats: Option<Client>,
    ticket: LiveSessionTicket,
    mut client: WebSocket,
) {
    let started = Instant::now();
    let sid = ticket.req_id.clone();
    let owner_iid = ticket.owner_iid;
    let req_id = ticket.req_id.clone();
    let billing_row = ticket.billing_row.clone();
    let offer = ticket.offer.clone();
    let chat_id_opt = ticket.chat_id;

    // Send ready: {"live":"ready"} to client immediately
    if client.send(Message::Text(r#"{"live":"ready"}"#.into())).await.is_err() {
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    // System prompt & user context
    let user_ctx = c35_mod_chat::prompt::user_context::user_prompt_context_get(&pool, owner_iid).await;
    let tz = c35_mod_chat::prompt::time::time_timezone_resolve(&user_ctx.tz, &user_ctx.locale, "");
    let time_block = c35_mod_chat::prompt::time::time_prompt_block(&tz);
    let inst_text = crate::google::live_inst_text(&pool, &offer.inst_id).await;
    let full_system = crate::google::live_voice_system(&inst_text, &time_block, &user_ctx.location_city, "", "", "");

    let http_client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(45))
        .build()
        .unwrap_or_else(|_| reqwest::Client::new());

    // Audio buffer & VAD state
    let mut audio_buffer: Vec<u8> = Vec::new();
    let mut speech_detected = false;
    let mut silence_chunks_count: usize = 0;
    let mut latest_video_frame: Option<(String, String, Instant)> = None;
    let mut recent_turns: Vec<(String, String)> = Vec::new();

    let mut video_tracker = crate::billing::VideoActivityTracker::new();
    let mut quota_interval = tokio::time::interval(std::time::Duration::from_secs(30));
    quota_interval.tick().await;

    let mut vad_interval = tokio::time::interval(std::time::Duration::from_millis(100));

    loop {
        tokio::select! {
            _ = quota_interval.tick() => {
                let elapsed_secs = started.elapsed().as_secs_f64();
                let video_secs = video_tracker.current_video_secs(Instant::now()).clamp(0.0, elapsed_secs);
                if crate::billing::live_check_quota_exhausted(
                    &pool,
                    owner_iid,
                    billing_row.id,
                    &offer,
                    elapsed_secs,
                    video_secs,
                )
                .await
                .unwrap_or(false)
                {
                    let _ = client
                        .send(Message::Text(
                            json!({"liveError": "Billing quota exhausted"}).to_string().into(),
                        ))
                        .await;
                    break;
                }
            }
            _ = vad_interval.tick() => {
                if speech_detected && silence_chunks_count >= 8 {
                    // Speech ended: user finished speaking (~800ms silence detected)
                    let user_pcm = std::mem::take(&mut audio_buffer);
                    speech_detected = false;
                    silence_chunks_count = 0;

                    if !user_pcm.is_empty() {
                        let pool_c = pool.clone();
                        let http_c = http_client.clone();
                        let system_c = full_system.clone();
                        let offer_c = offer.clone();
                        let req_id_c = req_id.clone();
                        let video_c = latest_video_frame.clone();
                        let recent_c = recent_turns.clone();

                        let res = handle_grok_turn(
                            &mut client,
                            &http_c,
                            &pool_c,
                            owner_iid,
                            chat_id_opt,
                            &req_id_c,
                            &offer_c,
                            &system_c,
                            user_pcm,
                            video_c,
                            recent_c,
                        ).await;

                        match res {
                            Ok(Some((u_text, a_text))) => {
                                recent_turns.push((u_text, a_text));
                                if recent_turns.len() > 6 {
                                    recent_turns.remove(0);
                                }
                            }
                            Ok(None) => {}
                            Err(e) => {
                                warn!(?e, "live: grok turn error");
                            }
                        }
                    }
                }
            }
            c_msg = client.recv() => {
                match c_msg {
                    Some(Ok(Message::Binary(pcm))) if !pcm.is_empty() => {
                        let rms = pcm_rms(&pcm);
                        const SPEECH_RMS_THRESHOLD: f64 = 600.0;
                        if rms >= SPEECH_RMS_THRESHOLD {
                            speech_detected = true;
                            silence_chunks_count = 0;
                            audio_buffer.extend_from_slice(&pcm);
                        } else if speech_detected {
                            silence_chunks_count += 1;
                            audio_buffer.extend_from_slice(&pcm);
                        }
                    }
                    Some(Ok(Message::Text(t))) => {
                        let trimmed = t.trim();
                        if trimmed == r#"{"type":"hangup"}"# {
                            break;
                        }
                        if let Some((mime, data)) = crate::openai::parse_video_frame(trimmed) {
                            video_tracker.on_frame(Instant::now());
                            latest_video_frame = Some((mime, data, Instant::now()));
                            continue;
                        }
                        if let Some(attach) = crate::media::parse_media_attach(trimmed) {
                            if attach.mime_type.starts_with("image/") || attach.mime_type.starts_with("video/") {
                                video_tracker.on_frame(Instant::now());
                            }
                            if attach.mime_type.starts_with("image/") {
                                latest_video_frame = Some((attach.mime_type, attach.data, Instant::now()));
                            } else {
                                let text = crate::media::extract_attachment_text(&attach.name, &attach.data);
                                recent_turns.push((text, "Attached file received.".to_string()));
                                if recent_turns.len() > 6 {
                                    recent_turns.remove(0);
                                }
                            }
                            continue;
                        }
                    }
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Err(e)) => {
                        debug!(?e, "live: client ws err");
                        break;
                    }
                    _ => {}
                }
            }
        }
    }

    let duration = started.elapsed().as_secs_f64();
    let video_secs = video_tracker.finalize(Instant::now(), duration);
    if let Err(e) = live_billing_settle(
        &pool,
        nats.as_ref(),
        owner_iid,
        &billing_row,
        &req_id,
        &offer,
        duration,
        video_secs,
    )
    .await
    {
        warn!(?e, req_id = %sid, "live: billing settle failed");
    }
}

pub async fn handle_grok_turn(
    client: &mut WebSocket,
    http_client: &reqwest::Client,
    pool: &PgPool,
    owner_iid: i64,
    chat_id_opt: Option<i64>,
    req_id: &str,
    offer: &crate::LiveOfferRow,
    full_system: &str,
    user_pcm: Vec<u8>,
    video_frame: Option<(String, String, Instant)>,
    recent_history: Vec<(String, String)>,
) -> Result<Option<(String, String)>> {
    // 1. Transcribe speech using Whisper or STT
    let wav = pcm16le_to_wav(&user_pcm, 16000, 1);
    let transcript = transcribe_user_speech(http_client, &wav).await?;
    let transcript = transcript.trim().to_string();
    if transcript.is_empty() {
        return Ok(None);
    }

    // Send inputTranscription to client
    let _ = client
        .send(Message::Text(
            json!({
                "serverContent": {
                    "inputTranscription": {
                        "text": &transcript
                    }
                }
            })
            .to_string()
            .into(),
        ))
        .await;

    // 2. Prepare Grok endpoint & headers
    let cf_cfg = cf_gateway_config();
    let xai_key = std::env::var("XAI_API_KEY")
        .or_else(|_| std::env::var("GROK_API_KEY"))
        .unwrap_or_default()
        .trim()
        .to_string();

    let (url, headers) = if cf_gateway_ready() {
        let u = format!(
            "https://gateway.ai.cloudflare.com/v1/{}/{}/grok/v1/chat/completions",
            cf_cfg.account_id, cf_cfg.gateway_id
        );
        let mut h = vec![
            ("cf-aig-authorization".to_string(), format!("Bearer {}", cf_cfg.api_token)),
            ("Content-Type".to_string(), "application/json".to_string()),
        ];
        if !xai_key.is_empty() {
            h.push(("Authorization".to_string(), format!("Bearer {xai_key}")));
        }
        (u, h)
    } else {
        let u = "https://api.x.ai/v1/chat/completions".to_string();
        let mut h = vec![("Content-Type".to_string(), "application/json".to_string())];
        if !xai_key.is_empty() {
            h.push(("Authorization".to_string(), format!("Bearer {xai_key}")));
        }
        (u, h)
    };

    let has_recent_video = video_frame
        .as_ref()
        .map(|(_, _, ts)| ts.elapsed().as_secs() < 10)
        .unwrap_or(false);

    let model = if has_recent_video {
        "grok-2-vision-1212"
    } else if !offer.provider_model.trim().is_empty() && offer.provider_model.contains("grok") {
        offer.provider_model.trim()
    } else {
        "grok-2-latest"
    };

    let mut messages = Vec::new();
    messages.push(json!({ "role": "system", "content": full_system }));
    for (u, a) in recent_history {
        messages.push(json!({ "role": "user", "content": u }));
        messages.push(json!({ "role": "assistant", "content": a }));
    }

    if let Some((mime, data, _)) = video_frame.filter(|_| has_recent_video) {
        messages.push(json!({
            "role": "user",
            "content": [
                { "type": "text", "text": &transcript },
                { "type": "image_url", "image_url": { "url": format!("data:{mime};base64,{data}") } }
            ]
        }));
    } else {
        messages.push(json!({ "role": "user", "content": &transcript }));
    }

    let body = json!({
        "model": model,
        "messages": messages,
        "stream": true,
        "temperature": 0.4
    });

    let mut req = http_client.post(&url).json(&body);
    for (k, v) in headers {
        req = req.header(k, v);
    }

    let resp = match req.send().await {
        Ok(r) if r.status().is_success() => r,
        Ok(r) => {
            warn!(status = %r.status(), "live: grok completion error");
            return Ok(None);
        }
        Err(e) => {
            warn!(?e, "live: grok request failed");
            return Ok(None);
        }
    };

    let mut full_assistant_text = String::new();
    let mut sentence_buffer = String::new();
    let mut stream = resp.bytes_stream();

    while let Some(chunk_res) = stream.next().await {
        let chunk = match chunk_res {
            Ok(c) => c,
            Err(_) => break,
        };
        let text_chunk = String::from_utf8_lossy(&chunk);
        for line in text_chunk.lines() {
            let line = line.trim();
            if !line.starts_with("data:") {
                continue;
            }
            let payload = line.trim_start_matches("data:").trim();
            if payload == "[DONE]" {
                break;
            }
            if let Ok(val) = serde_json::from_str::<Value>(payload) {
                if let Some(delta) = val["choices"][0]["delta"]["content"].as_str() {
                    if !delta.is_empty() {
                        full_assistant_text.push_str(delta);
                        sentence_buffer.push_str(delta);

                        let _ = client
                            .send(Message::Text(
                                json!({
                                    "serverContent": {
                                        "outputTranscription": {
                                            "text": delta
                                        }
                                    }
                                })
                                .to_string()
                                .into(),
                            ))
                            .await;

                        if sentence_buffer.len() >= 15
                            && sentence_buffer.contains(|c| c == '.' || c == '!' || c == '?' || c == '\n')
                        {
                            let sentence = std::mem::take(&mut sentence_buffer);
                            if let Ok(pcm_24k) = synthesize_to_pcm24k(http_client, &sentence).await {
                                if !pcm_24k.is_empty() {
                                    let _ = client.send(Message::Binary(pcm_24k.clone().into())).await;
                                    let _ = client
                                        .send(Message::Text(
                                            json!({
                                                "serverContent": {
                                                    "modelTurn": {
                                                        "parts": [{
                                                            "inlineData": {
                                                                "mimeType": "audio/pcm;rate=24000",
                                                                "data": B64.encode(&pcm_24k)
                                                            }
                                                        }]
                                                    }
                                                }
                                            })
                                            .to_string()
                                            .into(),
                                        ))
                                        .await;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if !sentence_buffer.trim().is_empty() {
        let sentence = std::mem::take(&mut sentence_buffer);
        if let Ok(pcm_24k) = synthesize_to_pcm24k(http_client, &sentence).await {
            if !pcm_24k.is_empty() {
                let _ = client.send(Message::Binary(pcm_24k.clone().into())).await;
                let _ = client
                    .send(Message::Text(
                        json!({
                            "serverContent": {
                                "modelTurn": {
                                    "parts": [{
                                        "inlineData": {
                                            "mimeType": "audio/pcm;rate=24000",
                                            "data": B64.encode(&pcm_24k)
                                        }
                                    }]
                                }
                            }
                        })
                        .to_string()
                        .into(),
                    ))
                    .await;
            }
        }
    }

    let _ = client
        .send(Message::Text(
            json!({
                "serverContent": {
                    "turnComplete": true
                }
            })
            .to_string()
            .into(),
        ))
        .await;

    let _ = client
        .send(Message::Text(
            json!({
                "liveTurnCommitted": {
                    "user_text": &transcript,
                    "assistant_text": &full_assistant_text
                }
            })
            .to_string()
            .into(),
        ))
        .await;

    if let Some(cid) = chat_id_opt {
        commit_grok_turn_to_db(pool, cid, owner_iid, req_id, &transcript, &full_assistant_text).await;
    }

    Ok(Some((transcript, full_assistant_text)))
}

pub fn pcm_rms(pcm: &[u8]) -> f64 {
    if pcm.len() < 2 {
        return 0.0;
    }
    let mut sum = 0.0;
    let samples = pcm.len() / 2;
    for chunk in pcm.chunks_exact(2) {
        let s = i16::from_le_bytes([chunk[0], chunk[1]]) as f64;
        sum += s * s;
    }
    (sum / samples as f64).sqrt()
}

pub fn pcm16le_to_wav(pcm: &[u8], sample_rate: u32, channels: u16) -> Vec<u8> {
    let mut wav = Vec::with_capacity(44 + pcm.len());
    let byte_rate = sample_rate * channels as u32 * 2;
    let block_align = channels * 2;
    let data_len = pcm.len() as u32;
    let file_len = 36 + data_len;

    wav.extend_from_slice(b"RIFF");
    wav.extend_from_slice(&file_len.to_le_bytes());
    wav.extend_from_slice(b"WAVEfmt ");
    wav.extend_from_slice(&16u32.to_le_bytes());
    wav.extend_from_slice(&1u16.to_le_bytes());
    wav.extend_from_slice(&channels.to_le_bytes());
    wav.extend_from_slice(&sample_rate.to_le_bytes());
    wav.extend_from_slice(&byte_rate.to_le_bytes());
    wav.extend_from_slice(&block_align.to_le_bytes());
    wav.extend_from_slice(&16u16.to_le_bytes());
    wav.extend_from_slice(b"data");
    wav.extend_from_slice(&data_len.to_le_bytes());
    wav.extend_from_slice(pcm);
    wav
}

pub async fn transcribe_user_speech(client: &reqwest::Client, wav: &[u8]) -> Result<String> {
    let has_cf_token = std::env::var("CLOUDFLARE_API_TOKEN").is_ok()
        || std::env::var("CLOUDFLARE_TOKEN").is_ok()
        || std::env::var("CF_API_TOKEN").is_ok();
    if has_cf_token {
        if let Ok(t) = c35_mod_voice::stt::cf_whisper_stt(client, wav, "audio/wav", "en-US", false).await {
            if !t.trim().is_empty() {
                return Ok(t);
            }
        }
    }

    if let Ok(t) = c35_mod_voice::stt::gemini_stt(client, wav, "audio/wav", "en-US").await {
        if !t.trim().is_empty() {
            return Ok(t);
        }
    }

    Ok(String::new())
}

pub async fn synthesize_to_pcm24k(http_client: &reqwest::Client, text: &str) -> Result<Vec<u8>> {
    let spoken = text.trim();
    if spoken.is_empty() {
        return Ok(Vec::new());
    }

    // 1. Try OpenAI TTS if OPENAI_API_KEY is available (direct or via CF Gateway)
    let openai_key = std::env::var("OPENAI_API_KEY")
        .or_else(|_| std::env::var("OPENAI_KEY"))
        .unwrap_or_default();
    if !openai_key.trim().is_empty() {
        let res = http_client
            .post("https://api.openai.com/v1/audio/speech")
            .header("Authorization", format!("Bearer {}", openai_key.trim()))
            .json(&serde_json::json!({
                "model": "tts-1",
                "voice": "alloy",
                "input": spoken,
                "response_format": "pcm"
            }))
            .send()
            .await;
        if let Ok(resp) = res {
            if resp.status().is_success() {
                if let Ok(bytes) = resp.bytes().await {
                    return Ok(bytes.to_vec());
                }
            }
        }
    }

    // 2. Try Google Cloud TTS with LINEAR16 24000Hz
    let google_key = std::env::var("GOOGLE_CLOUD_API_KEY")
        .or_else(|_| std::env::var("GOOGLE_API_KEY"))
        .or_else(|_| std::env::var("GEMINI_API_KEY"))
        .unwrap_or_default();
    if !google_key.trim().is_empty() {
        let url = format!(
            "https://texttospeech.googleapis.com/v1/text:synthesize?key={}",
            google_key.trim()
        );
        let res = http_client
            .post(&url)
            .json(&serde_json::json!({
                "input": { "text": spoken },
                "voice": { "languageCode": "en-US", "ssmlGender": "NEUTRAL" },
                "audioConfig": { "audioEncoding": "LINEAR16", "sampleRateHertz": 24000 }
            }))
            .send()
            .await;
        if let Ok(resp) = res {
            if resp.status().is_success() {
                if let Ok(v) = resp.json::<serde_json::Value>().await {
                    if let Some(content_b64) = v.get("audioContent").and_then(|x| x.as_str()) {
                        if let Ok(wav_bytes) = B64.decode(content_b64) {
                            if wav_bytes.len() > 44 {
                                return Ok(wav_bytes[44..].to_vec());
                            }
                        }
                    }
                }
            }
        }
    }

    // 3. Fallback: gentle synthesized PCM chime so client audio playback never crashes
    let duration_sec = 0.5f64.max((spoken.split_whitespace().count() as f64) * 0.25);
    let sample_count = (24000.0 * duration_sec) as usize;
    let mut pcm = Vec::with_capacity(sample_count * 2);
    for i in 0..sample_count {
        let t = i as f64 / 24000.0;
        let sample = (350.0 * (1.0 - t / duration_sec) * (2.0 * std::f64::consts::PI * 440.0 * t).sin()) as i16;
        pcm.extend_from_slice(&sample.to_le_bytes());
    }
    Ok(pcm)
}

async fn commit_grok_turn_to_db(
    pool: &PgPool,
    chat_id: i64,
    owner_iid: i64,
    req_id: &str,
    user_text: &str,
    assistant_text: &str,
) {
    if !user_text.is_empty() {
        let u_id = c35_store::snowflake_id();
        let _ = sqlx::query(
            r#"
            INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, $3, 'user', 'prompt', $5, '[]', NOW(), NOW())
            "#,
        )
        .bind(u_id)
        .bind(chat_id)
        .bind(owner_iid)
        .bind(req_id)
        .bind(user_text)
        .execute(pool)
        .await;
    }

    if !assistant_text.is_empty() {
        let a_id = c35_store::snowflake_id();
        let _ = sqlx::query(
            r#"
            INSERT INTO ai.chat_msg (
                id, chat_id, owner_iid, req_id, sender_iid, role, source,
                content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
                created_ts, updated_ts
            )
            VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', $5, '', '[]'::jsonb, 0, 0, 0, 0, 'done', '', NOW(), NOW())
            "#,
        )
        .bind(a_id)
        .bind(chat_id)
        .bind(owner_iid)
        .bind(req_id)
        .bind(assistant_text)
        .execute(pool)
        .await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pcm_rms_and_wav_generation() {
        // Generate 16kHz sine wave for 50ms
        let sample_count = 800; // 50ms at 16kHz
        let mut pcm = Vec::with_capacity(sample_count * 2);
        for i in 0..sample_count {
            let sample = (1000.0 * (2.0 * std::f64::consts::PI * 440.0 * (i as f64 / 16000.0)).sin()) as i16;
            pcm.extend_from_slice(&sample.to_le_bytes());
        }

        let rms = pcm_rms(&pcm);
        assert!(rms > 500.0, "RMS for audible 440Hz sine wave should be > 500 (got {rms})");

        let wav = pcm16le_to_wav(&pcm, 16000, 1);
        assert_eq!(wav.len(), 44 + pcm.len());
        assert_eq!(&wav[0..4], b"RIFF");
        assert_eq!(&wav[8..12], b"WAVE");
    }

    #[tokio::test]
    async fn test_synthesize_pcm24k_fallback() {
        let client = reqwest::Client::new();
        let pcm = synthesize_to_pcm24k(&client, "Hello world test audio").await.unwrap();
        assert!(!pcm.is_empty(), "PCM audio should be generated");
        assert_eq!(pcm.len() % 2, 0, "PCM16 audio must have even byte length");
    }
}
