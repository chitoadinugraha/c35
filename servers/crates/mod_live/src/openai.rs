use std::time::Instant;

use async_nats::Client;
use axum::extract::ws::{Message, WebSocket};
use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_llm::{
    cf_realtime_via_cf, cf_realtime_ws_header_pairs, cf_realtime_ws_url, CfRealtimeUpstream,
};
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio_tungstenite::{
    connect_async,
    tungstenite::client::IntoClientRequest,
    tungstenite::Message as WsMsg,
};
use tracing::{debug, warn};

use crate::billing::{live_billing_abort, live_billing_settle};
use crate::session::LiveSessionTicket;
use crate::smoke::audio::pcm16k_to_pcm24k;

pub async fn live_openai_run(
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

    let model = if offer.provider_model.trim().is_empty() {
        "gpt-4o-realtime-preview"
    } else {
        offer.provider_model.trim()
    };

    let provider_key = std::env::var("OPENAI_API_KEY")
        .or_else(|_| std::env::var("OPENAI_KEY"))
        .unwrap_or_default()
        .trim()
        .to_string();

    let use_cf = cf_realtime_via_cf();
    let (ws_url, headers) = if use_cf {
        if let Some(cf_url) = cf_realtime_ws_url(model, CfRealtimeUpstream::OpenAi) {
            let provider_bearer = if provider_key.is_empty() {
                None
            } else {
                Some(provider_key.as_str())
            };
            let h = cf_realtime_ws_header_pairs(CfRealtimeUpstream::OpenAi, provider_bearer);
            (cf_url, h)
        } else {
            let direct_url = format!(
                "wss://api.openai.com/v1/realtime?model={}",
                urlencoding::encode(model)
            );
            let mut h = vec![("OpenAI-Beta".to_string(), "realtime=v1".to_string())];
            if !provider_key.is_empty() {
                h.push(("Authorization".to_string(), format!("Bearer {provider_key}")));
            }
            (direct_url, h)
        }
    } else {
        let direct_url = format!(
            "wss://api.openai.com/v1/realtime?model={}",
            urlencoding::encode(model)
        );
        let mut h = vec![("OpenAI-Beta".to_string(), "realtime=v1".to_string())];
        if !provider_key.is_empty() {
            h.push(("Authorization".to_string(), format!("Bearer {provider_key}")));
        }
        (direct_url, h)
    };

    let mut req = match ws_url.into_client_request() {
        Ok(r) => r,
        Err(e) => {
            warn!(?e, "live: openai ws request invalid");
            let _ = client
                .send(Message::Text(
                    json!({"liveError": format!("Invalid OpenAI request: {e}")})
                        .to_string()
                        .into(),
                ))
                .await;
            let _ = live_billing_abort(&pool, &req_id).await;
            return;
        }
    };

    for (k, v) in headers {
        if let (Ok(name), Ok(val)) = (
            http::HeaderName::from_bytes(k.as_bytes()),
            http::HeaderValue::from_str(&v),
        ) {
            req.headers_mut().insert(name, val);
        }
    }

    let (openai_ws, _) = match connect_async(req).await {
        Ok(s) => s,
        Err(e) => {
            warn!(?e, "live: openai ws connect failed");
            let _ = client
                .send(Message::Text(
                    json!({"liveError": "Could not connect to OpenAI Realtime"})
                        .to_string()
                        .into(),
                ))
                .await;
            let _ = live_billing_abort(&pool, &req_id).await;
            return;
        }
    };

    let (mut o_tx, mut o_rx) = openai_ws.split();

    // Prepare system prompt
    let user_ctx = c35_mod_chat::prompt::user_context::user_prompt_context_get(&pool, owner_iid).await;
    let tz = c35_mod_chat::prompt::time::time_timezone_resolve(&user_ctx.tz, &user_ctx.locale, "");
    let time_block = c35_mod_chat::prompt::time::time_prompt_block(&tz);
    let inst_text = crate::google::live_inst_text(&pool, &offer.inst_id).await;
    let full_system = crate::google::live_voice_system(&inst_text, &time_block, &user_ctx.location_city, "", "", "");

    // Send session.update
    let session_init = json!({
        "type": "session.update",
        "session": {
            "modalities": ["text", "audio"],
            "instructions": full_system,
            "voice": "alloy",
            "input_audio_format": "pcm16",
            "output_audio_format": "pcm16",
            "input_audio_transcription": {
                "model": "whisper-1"
            },
            "turn_detection": {
                "type": "server_vad"
            }
        }
    });

    if o_tx.send(WsMsg::Text(session_init.to_string().into())).await.is_err() {
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    let mut video_tracker = crate::billing::VideoActivityTracker::new();
    let mut quota_interval = tokio::time::interval(std::time::Duration::from_secs(30));
    quota_interval.tick().await;

    let mut ready = false;
    let mut turn_user_text = String::new();
    let mut turn_assistant_text = String::new();

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
            c_msg = client.recv() => {
                match c_msg {
                    Some(Ok(Message::Binary(pcm))) if !pcm.is_empty() => {
                        if !ready {
                            continue;
                        }
                        // Client sends 16kHz PCM audio; resample to 24kHz for OpenAI Realtime
                        let pcm24k = pcm16k_to_pcm24k(&pcm);
                        let append = json!({
                            "type": "input_audio_buffer.append",
                            "audio": B64.encode(&pcm24k)
                        });
                        if o_tx.send(WsMsg::Text(append.to_string().into())).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Text(t))) => {
                        let trimmed = t.trim();
                        if trimmed == r#"{"type":"hangup"}"# {
                            break;
                        }
                        // Ingest video frames
                        if let Some((mime, data)) = parse_video_frame(trimmed) {
                            video_tracker.on_frame(Instant::now());
                            if ready {
                                let img_item = json!({
                                    "type": "conversation.item.create",
                                    "item": {
                                        "type": "message",
                                        "role": "user",
                                        "content": [
                                            {
                                                "type": "input_image",
                                                "image_url": format!("data:{mime};base64,{data}")
                                            }
                                        ]
                                    }
                                });
                                let _ = o_tx.send(WsMsg::Text(img_item.to_string().into())).await;
                            }
                            continue;
                        }
                        if let Some(attach) = crate::media::parse_media_attach(trimmed) {
                            if attach.mime_type.starts_with("image/") || attach.mime_type.starts_with("video/") {
                                video_tracker.on_frame(Instant::now());
                            }
                            if ready {
                                if attach.mime_type.starts_with("image/") {
                                    let img_item = json!({
                                        "type": "conversation.item.create",
                                        "item": {
                                            "type": "message",
                                            "role": "user",
                                            "content": [
                                                {
                                                    "type": "input_image",
                                                    "image_url": format!("data:{};base64,{}", attach.mime_type, attach.data)
                                                }
                                            ]
                                        }
                                    });
                                    let _ = o_tx.send(WsMsg::Text(img_item.to_string().into())).await;
                                } else {
                                    let text = crate::media::extract_attachment_text(&attach.name, &attach.data);
                                    let txt_item = json!({
                                        "type": "conversation.item.create",
                                        "item": {
                                            "type": "message",
                                            "role": "user",
                                            "content": [
                                                {
                                                    "type": "input_text",
                                                    "text": text
                                                }
                                            ]
                                        }
                                    });
                                    let _ = o_tx.send(WsMsg::Text(txt_item.to_string().into())).await;
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
            o_msg = o_rx.next() => {
                match o_msg {
                    Some(Ok(WsMsg::Text(t))) => {
                        let text = t.to_string();
                        if let Ok(v) = serde_json::from_str::<Value>(&text) {
                            let msg_type = v.get("type").and_then(|x| x.as_str()).unwrap_or("");
                            if (!ready) && (msg_type == "session.created" || msg_type == "session.updated") {
                                ready = true;
                                let _ = client.send(Message::Text(r#"{"live":"ready"}"#.into())).await;
                            }

                            // Relay speech interruption
                            if msg_type == "input_audio_buffer.speech_started" {
                                let _ = client
                                    .send(Message::Text(
                                        json!({"serverContent":{"interrupted": true}}).to_string().into(),
                                    ))
                                    .await;
                            }

                            // Relay incoming audio delta
                            if msg_type == "response.audio.delta" {
                                if let Some(delta) = v.get("delta").and_then(|d| d.as_str()) {
                                    if let Ok(pcm_bytes) = B64.decode(delta) {
                                        // Relay as binary PCM frames to client
                                        let _ = client.send(Message::Binary(pcm_bytes.into())).await;
                                    }
                                    // Also relay Gemini-compatible inlineData JSON for universal client support
                                    let _ = client.send(Message::Text(json!({
                                        "serverContent": {
                                            "modelTurn": {
                                                "parts": [{
                                                    "inlineData": {
                                                        "mimeType": "audio/pcm;rate=24000",
                                                        "data": delta
                                                    }
                                                }]
                                            }
                                        }
                                    }).to_string().into())).await;
                                }
                            }

                            // Relay assistant audio transcript delta
                            if msg_type == "response.audio_transcript.delta" {
                                if let Some(delta) = v.get("delta").and_then(|d| d.as_str()) {
                                    turn_assistant_text.push_str(delta);
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
                                }
                            }

                            // Relay user input transcription completed
                            if msg_type == "conversation.item.input_audio_transcription.completed" {
                                if let Some(transcript) = v.get("transcript").and_then(|t| t.as_str()) {
                                    turn_user_text = transcript.to_string();
                                    let _ = client
                                        .send(Message::Text(
                                            json!({
                                                "serverContent": {
                                                    "inputTranscription": {
                                                        "text": transcript
                                                    }
                                                }
                                            })
                                            .to_string()
                                            .into(),
                                        ))
                                        .await;
                                }
                            }

                            // On response.done: commit turn and notify client
                            if msg_type == "response.done" {
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

                                if !turn_user_text.is_empty() || !turn_assistant_text.is_empty() {
                                    let _ = client
                                        .send(Message::Text(
                                            json!({
                                                "liveTurnCommitted": {
                                                    "user_text": &turn_user_text,
                                                    "assistant_text": &turn_assistant_text
                                                }
                                            })
                                            .to_string()
                                            .into(),
                                        ))
                                        .await;

                                    if let Some(cid) = chat_id_opt {
                                        commit_turn_to_db(&pool, cid, owner_iid, &req_id, &turn_user_text, &turn_assistant_text).await;
                                    }

                                    turn_user_text.clear();
                                    turn_assistant_text.clear();
                                }
                            }
                        }
                    }
                    Some(Ok(WsMsg::Close(_))) | None => break,
                    Some(Err(e)) => {
                        warn!(?e, "live: openai ws err");
                        break;
                    }
                    _ => {}
                }
            }
        }
    }

    let _ = o_tx.send(WsMsg::Close(None)).await;
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

pub fn parse_video_frame(text: &str) -> Option<(String, String)> {
    let v: Value = serde_json::from_str(text).ok()?;
    let msg_type = v.get("type").and_then(|t| t.as_str())?;
    if msg_type != "video" && msg_type != "video_frame" {
        return None;
    }
    let data = v.get("data").and_then(|d| d.as_str())?;
    if data.is_empty() {
        return None;
    }
    let mime = v
        .get("mime_type")
        .or_else(|| v.get("mimeType"))
        .and_then(|m| m.as_str())
        .unwrap_or("image/jpeg");
    Some((mime.to_string(), data.to_string()))
}

async fn commit_turn_to_db(
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
    fn test_parse_video_frame() {
        let valid = r#"{"type":"video","data":"base64image","mime_type":"image/png"}"#;
        let res = parse_video_frame(valid);
        assert!(res.is_some());
        let (mime, data) = res.unwrap();
        assert_eq!(mime, "image/png");
        assert_eq!(data, "base64image");

        let invalid = r#"{"type":"other","data":"abc"}"#;
        assert!(parse_video_frame(invalid).is_none());
    }

    #[test]
    fn test_session_update_payload_shape() {
        let payload = json!({
            "type": "session.update",
            "session": {
                "modalities": ["text", "audio"],
                "voice": "alloy",
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "turn_detection": { "type": "server_vad" }
            }
        });
        assert_eq!(payload["type"], "session.update");
        assert_eq!(payload["session"]["modalities"][0], "text");
        assert_eq!(payload["session"]["voice"], "alloy");
    }
}
