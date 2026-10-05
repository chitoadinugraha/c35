use std::time::{Duration, Instant};

use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_llm::{cf_realtime_via_cf, cf_realtime_ws_header_pairs, cf_realtime_ws_url, CfRealtimeUpstream};
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{
    connect_async,
    tungstenite::client::IntoClientRequest,
    tungstenite::Message as WsMsg,
};

use super::report::SmokeOutcome;

#[derive(Clone, Copy)]
pub enum RealtimeVendor {
    OpenAi,
    Xai,
}

struct RealtimeSpec {
    label: &'static str,
    model: &'static str,
    direct_url: &'static str,
    cf_upstream: CfRealtimeUpstream,
}

fn spec(vendor: RealtimeVendor) -> RealtimeSpec {
    match vendor {
        RealtimeVendor::OpenAi => RealtimeSpec {
            label: "chatgpt_realtime",
            model: "gpt-4o-realtime-preview",
            direct_url: "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview",
            cf_upstream: CfRealtimeUpstream::OpenAi,
        },
        RealtimeVendor::Xai => RealtimeSpec {
            label: "grok_voice",
            model: "grok-voice-latest",
            direct_url: "wss://api.x.ai/v1/realtime?model=grok-voice-latest",
            cf_upstream: CfRealtimeUpstream::Grok,
        },
    }
}

pub async fn smoke_realtime(pcm24k: Vec<u8>, vendor: RealtimeVendor) -> SmokeOutcome {
    let s = spec(vendor);
    let key = provider_key(vendor);
    let force_cf = cf_realtime_force_only();
    if cf_realtime_via_cf() {
        if let Some(url) = cf_realtime_ws_url(s.model, s.cf_upstream) {
            let provider = if key.is_empty() { None } else { Some(key.as_str()) };
            let headers = cf_realtime_ws_header_pairs(s.cf_upstream, provider);
            let out = smoke_realtime_session(format!("{}_cf", s.label), &url, headers, pcm24k.clone()).await;
            if out.ok || force_cf || !cf_realtime_fallback_direct() {
                return out;
            }
        } else if force_cf {
            let cf_label = format!("{}_cf", s.label);
            return SmokeOutcome::fail(
                &cf_label,
                "CF AI Gateway not configured (CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN, CLOUDFLARE_AI_GATEWAY_ID)",
            );
        }
    }
    smoke_realtime_direct(pcm24k, vendor, &s, &key).await
}

async fn smoke_realtime_direct(
    pcm24k: Vec<u8>,
    vendor: RealtimeVendor,
    s: &RealtimeSpec,
    key: &str,
) -> SmokeOutcome {
    if key.is_empty() {
        let hint = if cf_realtime_via_cf() {
            "provider key not set (set OPENAI_API_KEY / XAI_API_KEY, or configure CF gateway BYOK)"
        } else {
            match vendor {
                RealtimeVendor::OpenAi => "OPENAI_API_KEY not set",
                RealtimeVendor::Xai => "XAI_API_KEY not set",
            }
        };
        return SmokeOutcome::fail(s.label, hint);
    }
    let mut headers = vec![("Authorization".to_string(), format!("Bearer {key}"))];
    if matches!(vendor, RealtimeVendor::OpenAi) {
        headers.push(("OpenAI-Beta".to_string(), "realtime=v1".to_string()));
    }
    smoke_realtime_session(s.label.to_string(), s.direct_url, headers, pcm24k).await
}

fn cf_realtime_force_only() -> bool {
    matches!(
        std::env::var("LIVE_REALTIME_VIA_CF")
            .ok()
            .map(|v| v.trim().to_ascii_lowercase())
            .as_deref(),
        Some("1") | Some("true") | Some("on") | Some("yes")
    )
}

fn cf_realtime_fallback_direct() -> bool {
    matches!(
        std::env::var("LIVE_REALTIME_CF_FALLBACK")
            .ok()
            .map(|v| v.trim().to_ascii_lowercase())
            .as_deref(),
        Some("1") | Some("true") | Some("on") | Some("yes")
    )
}

async fn smoke_realtime_session(
    label: String,
    url: &str,
    headers: Vec<(String, String)>,
    pcm24k: Vec<u8>,
) -> SmokeOutcome {
    let started = Instant::now();
    let mut req = match url.into_client_request() {
        Ok(r) => r,
        Err(e) => return SmokeOutcome::fail(&label, format!("ws request: {e:#}")),
    };
    for (k, v) in headers {
        if let (Ok(name), Ok(val)) = (
            http::HeaderName::from_bytes(k.as_bytes()),
            http::HeaderValue::from_str(&v),
        ) {
            req.headers_mut().insert(name, val);
        }
    }
    let (ws, _) = match connect_async(req).await {
        Ok(v) => v,
        Err(e) => return SmokeOutcome::fail(&label, format!("connect: {e:#}")),
    };
    let (mut tx, mut rx) = ws.split();
    let session = json!({
        "type": "session.update",
        "session": {
            "modalities": ["text", "audio"],
            "instructions": "Answer briefly. If asked for the time, state the current time.",
            "voice": "alloy",
            "turn_detection": { "type": "server_vad" }
        }
    });
    let _ = tx.send(WsMsg::Text(session.to_string().into())).await;
    let mut session_ready = false;
    let mut audio_sent = false;
    let mut transcripts = Vec::new();
    let mut errors = Vec::new();
    let chunk = pcm24k.len().max(1).min(4800);
    let deadline = Instant::now() + Duration::from_secs(90);
    loop {
        if Instant::now() > deadline {
            errors.push("timeout".into());
            break;
        }
        tokio::select! {
            msg = rx.next() => {
                match msg {
                    Some(Ok(WsMsg::Text(t))) => {
                        let s = t.to_string();
                        let v: Value = serde_json::from_str(&s).unwrap_or(json!({ "raw": s }));
                        let ty = v.get("type").and_then(|x| x.as_str()).unwrap_or("");
                        if ty == "session.created" || ty == "session.updated" {
                            session_ready = true;
                        }
                        if ty == "error" {
                            errors.push(truncate(&s, 300));
                        }
                        collect_openai_text(&v, &mut transcripts);
                        if ty == "response.done" && audio_sent {
                            break;
                        }
                    }
                    Some(Ok(WsMsg::Close(_))) | None => break,
                    Some(Err(e)) => {
                        errors.push(format!("ws: {e:#}"));
                        break;
                    }
                    _ => {}
                }
            }
            _ = tokio::time::sleep(Duration::from_millis(80)), if session_ready && !audio_sent => {
                for part in pcm24k.chunks(chunk) {
                    let append = json!({
                        "type": "input_audio_buffer.append",
                        "audio": B64.encode(part)
                    });
                    let _ = tx.send(WsMsg::Text(append.to_string().into())).await;
                }
                let _ = tx.send(WsMsg::Text(json!({"type":"input_audio_buffer.commit"}).to_string().into())).await;
                let _ = tx.send(WsMsg::Text(json!({"type":"response.create"}).to_string().into())).await;
                audio_sent = true;
            }
        }
    }
    let _ = tx.send(WsMsg::Close(None)).await;
    let reply = transcripts.join(" ").trim().to_string();
    let ok = session_ready && audio_sent && !reply.is_empty() && errors.is_empty();
    SmokeOutcome {
        provider: label,
        ok,
        elapsed_ms: started.elapsed().as_millis() as u64,
        reply: if reply.is_empty() { errors.join("; ") } else { reply },
        detail: errors.join("; "),
    }
}

fn provider_key(vendor: RealtimeVendor) -> String {
    match vendor {
        RealtimeVendor::OpenAi => std::env::var("OPENAI_API_KEY")
            .or_else(|_| std::env::var("OPENAI_KEY"))
            .unwrap_or_default()
            .trim()
            .to_string(),
        RealtimeVendor::Xai => std::env::var("XAI_API_KEY")
            .or_else(|_| std::env::var("GROK_API_KEY"))
            .unwrap_or_default()
            .trim()
            .to_string(),
    }
}

fn collect_openai_text(v: &Value, out: &mut Vec<String>) {
    let ty = v.get("type").and_then(|x| x.as_str()).unwrap_or("");
    let keys = ["transcript", "text", "delta"];
    for k in keys {
        if let Some(t) = v.get(k).and_then(|x| x.as_str()) {
            if !t.trim().is_empty() {
                out.push(t.trim().to_string());
            }
        }
    }
    if ty.contains("transcript") {
        if let Some(t) = v.pointer("/transcript").and_then(|x| x.as_str()) {
            out.push(t.to_string());
        }
    }
    if let Some(item) = v.get("item") {
        if let Some(content) = item.get("content").and_then(|c| c.as_array()) {
            for c in content {
                if let Some(t) = c.get("transcript").or_else(|| c.get("text")).and_then(|x| x.as_str()) {
                    out.push(t.trim().to_string());
                }
            }
        }
    }
}

fn truncate(s: &str, max: usize) -> String {
    if s.len() <= max {
        s.to_string()
    } else {
        format!("{}…", &s[..max])
    }
}
