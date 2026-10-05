use std::time::Instant;

use anyhow::{anyhow, Result};
use async_nats::Client;
use axum::extract::ws::{Message, WebSocket};
use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_chat::gemini_api_key;
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio_tungstenite::{connect_async, tungstenite::Message as GMsg};
use tracing::{debug, warn};

use crate::billing::{live_billing_abort, live_billing_settle};
use crate::session::LiveSessionTicket;

const GEMINI_LIVE_WS: &str =
    "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent";

pub async fn live_proxy_run(
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

    if offer.provider != "google" {
        let _ = client
            .send(Message::Text(
                json!({"liveError":"Live provider not supported yet"}).to_string().into(),
            ))
            .await;
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    let key = gemini_api_key();
    if key.is_empty() {
        let _ = client
            .send(Message::Text(
                json!({"liveError":"Gemini API key not configured"}).to_string().into(),
            ))
            .await;
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    let system = live_inst_text(&pool, &offer.inst_id).await;
    let model = format!("models/{}", offer.provider_model.trim());
    let url = format!("{GEMINI_LIVE_WS}?key={}", urlencoding::encode(&key));

    let google = match connect_async(&url).await {
        Ok((s, _)) => s,
        Err(e) => {
            warn!(?e, "live: google ws connect failed");
            let _ = client
                .send(Message::Text(
                    json!({"liveError":"Could not connect to Gemini Live"}).to_string().into(),
                ))
                .await;
            let _ = live_billing_abort(&pool, &req_id).await;
            return;
        }
    };

    let (mut g_tx, mut g_rx) = google.split();
    let setup = json!({
        "setup": {
            "model": model,
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": {
                        "prebuiltVoiceConfig": { "voiceName": "Aoede" }
                    }
                }
            },
            "systemInstruction": {
                "parts": [{ "text": system }]
            }
        }
    });
    if g_tx.send(GMsg::Text(setup.to_string().into())).await.is_err() {
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    let mut ready = false;
    let mut last_pcm_at: Option<Instant> = None;
    let mut pending_turn = false;
    let mut silence_tick = tokio::time::interval(std::time::Duration::from_millis(200));
    silence_tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
    loop {
        tokio::select! {
            _ = silence_tick.tick(), if ready && pending_turn => {
                if last_pcm_at.is_some_and(|t| t.elapsed() >= std::time::Duration::from_millis(900)) {
                    let turn = json!({ "clientContent": { "turnComplete": true } });
                    if g_tx.send(GMsg::Text(turn.to_string().into())).await.is_err() {
                        break;
                    }
                    pending_turn = false;
                    last_pcm_at = None;
                }
            }
            c_msg = client.recv() => {
                match c_msg {
                    Some(Ok(Message::Binary(pcm))) if !pcm.is_empty() => {
                        if !ready {
                            continue;
                        }
                        last_pcm_at = Some(Instant::now());
                        pending_turn = true;
                        let chunk = json!({
                            "realtimeInput": {
                                "mediaChunks": [{
                                    "mimeType": "audio/pcm;rate=16000",
                                    "data": B64.encode(&pcm)
                                }]
                            }
                        });
                        if g_tx.send(GMsg::Text(chunk.to_string().into())).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Text(t))) if t.trim() == r#"{"type":"hangup"}"# => break,
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Err(e)) => {
                        debug!(?e, "live: client ws err");
                        break;
                    }
                    _ => {}
                }
            }
            g_msg = g_rx.next() => {
                match g_msg {
                    Some(Ok(GMsg::Text(t))) => {
                        if !ready && t.contains("setupComplete") {
                            ready = true;
                            let _ = client.send(Message::Text(r#"{"live":"ready"}"#.into())).await;
                        }
                        if client.send(Message::Text(t.to_string().into())).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(GMsg::Binary(b))) => {
                        if !ready {
                            if let Ok(s) = String::from_utf8(b.to_vec()) {
                                if s.contains("setupComplete") {
                                    ready = true;
                                    let _ = client.send(Message::Text(r#"{"live":"ready"}"#.into())).await;
                                }
                            }
                        }
                        let out = if let Ok(s) = String::from_utf8(b.to_vec()) {
                            Message::Text(s.into())
                        } else {
                            Message::Binary(b)
                        };
                        if client.send(out).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(GMsg::Close(_))) | None => break,
                    Some(Err(e)) => {
                        warn!(?e, "live: google ws err");
                        break;
                    }
                    _ => {}
                }
            }
        }
    }

    let _ = g_tx.send(GMsg::Close(None)).await;
    let duration = started.elapsed().as_secs_f64();
    if let Err(e) = live_billing_settle(
        &pool,
        nats.as_ref(),
        owner_iid,
        &billing_row,
        &req_id,
        &offer,
        duration,
    )
    .await
    {
        warn!(?e, req_id = %sid, "live: billing settle failed");
    }
}

async fn live_inst_text(pool: &PgPool, inst_id: &str) -> String {
    let id = inst_id.trim();
    if id.is_empty() {
        return "You are a helpful voice assistant. Respond naturally in the user's language.".into();
    }
    let row: Option<(String,)> = sqlx::query_as(
        "SELECT inst FROM ai.inst WHERE id = $1 AND deleted_ts IS NULL AND enabled = TRUE",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.map(|(t,)| t.trim().to_string())
        .filter(|t| !t.is_empty())
        .unwrap_or_else(|| {
            "You are Alien AI, a helpful personal assistant. Respond conversationally in the user's language."
                .into()
        })
}

pub fn live_google_ping() -> Result<()> {
    if gemini_api_key().is_empty() {
        return Err(anyhow!("missing GEMINI_API_KEY"));
    }
    Ok(())
}

#[allow(dead_code)]
fn parse_gemini_audio(v: &Value) -> Option<(Vec<u8>, u32)> {
    let data = v
        .pointer("/serverContent/modelTurn/parts/0/inlineData/data")
        .or_else(|| v.pointer("/serverContent/modelTurn/parts/0/inline_data/data"))?
        .as_str()?;
    let mime = v
        .pointer("/serverContent/modelTurn/parts/0/inlineData/mimeType")
        .or_else(|| v.pointer("/serverContent/modelTurn/parts/0/inline_data/mime_type"))
        .and_then(|m| m.as_str())
        .unwrap_or("audio/pcm;rate=24000");
    let rate = mime
        .split("rate=")
        .nth(1)
        .and_then(|s| s.split(';').next())
        .and_then(|s| s.parse().ok())
        .unwrap_or(24_000);
    let bytes = B64.decode(data.trim()).ok()?;
    Some((bytes, rate))
}
