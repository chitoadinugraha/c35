use std::time::{Duration, Instant};

use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_chat::gemini_api_key;
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{connect_async, tungstenite::Message as GMsg};

use super::report::SmokeOutcome;

const GEMINI_LIVE_WS: &str =
    "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent";

pub async fn smoke_gemini_live(pcm16k: Vec<u8>, model: &str) -> SmokeOutcome {
    let label = "gemini_live";
    let key = gemini_api_key();
    if key.is_empty() {
        return SmokeOutcome::fail(label, "GEMINI_API_KEY / GOOGLE_API_KEY not set");
    }
    let url = format!("{GEMINI_LIVE_WS}?key={key}");
    let started = Instant::now();
    let (ws, _) = match connect_async(&url).await {
        Ok(v) => v,
        Err(e) => return SmokeOutcome::fail(label, format!("connect: {e:#}")),
    };
    let (mut tx, mut rx) = ws.split();
    let setup = json!({
        "setup": {
            "model": format!("models/{}", model.trim()),
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": { "prebuiltVoiceConfig": { "voiceName": "Aoede" } }
                }
            },
            "systemInstruction": {
                "parts": [{ "text": "Answer briefly. If asked for the time, state the current time." }]
            }
        }
    });
    if tx.send(GMsg::Text(setup.to_string().into())).await.is_err() {
        return SmokeOutcome::fail(label, "setup send failed");
    }
    let mut ready = false;
    let mut notes = Vec::new();
    let mut text_parts = Vec::new();
    let chunk_bytes = 16_000 / 10 * 2;
    let mut sent = false;
    let deadline = Instant::now() + Duration::from_secs(90);
    loop {
        if Instant::now() > deadline {
            notes.push("timeout".into());
            break;
        }
        tokio::select! {
            msg = rx.next() => {
                match msg {
                    Some(Ok(m)) => {
                        if let Some(s) = gemini_ws_payload(&m) {
                            notes.push(truncate(&s, 180));
                            if let Ok(v) = serde_json::from_str::<Value>(&s) {
                                if v.get("setupComplete").is_some() || s.contains("setupComplete") {
                                    ready = true;
                                    notes.push("setupComplete".into());
                                }
                                if let Some(err) = v.pointer("/error/message").and_then(|x| x.as_str()) {
                                    notes.push(format!("api error: {err}"));
                                }
                                collect_gemini_text(&v, &mut text_parts);
                            }
                            if sent && !text_parts.is_empty() {
                                break;
                            }
                        }
                    }
                    Some(Err(e)) => {
                        notes.push(format!("ws err: {e:#}"));
                        break;
                    }
                    None => break,
                }
            }
            _ = tokio::time::sleep(Duration::from_millis(50)), if ready && !sent => {
                for chunk in pcm16k.chunks(chunk_bytes) {
                    let body = json!({
                        "realtimeInput": {
                            "mediaChunks": [{
                                "mimeType": "audio/pcm;rate=16000",
                                "data": B64.encode(chunk)
                            }]
                        }
                    });
                    let _ = tx.send(GMsg::Text(body.to_string().into())).await;
                    tokio::time::sleep(Duration::from_millis(80)).await;
                }
                sent = true;
                notes.push("audio_sent".into());
                let _ = tx.send(GMsg::Text(json!({"clientContent":{"turnComplete":true}}).to_string().into())).await;
            }
        }
    }
    let _ = tx.send(GMsg::Close(None)).await;
    let reply = text_parts.join(" ").trim().to_string();
    if !ready && notes.is_empty() {
        notes.push("ws closed before any message".into());
    }
    let ok = ready && sent && !reply.is_empty();
    SmokeOutcome {
        provider: label.into(),
        ok,
        elapsed_ms: started.elapsed().as_millis() as u64,
        reply: if reply.is_empty() { notes.join("; ") } else { reply },
        detail: notes.join("; "),
    }
}

fn gemini_ws_payload(msg: &GMsg) -> Option<String> {
    match msg {
        GMsg::Text(t) => Some(t.to_string()),
        GMsg::Binary(b) => String::from_utf8(b.to_vec()).ok(),
        _ => None,
    }
}

fn collect_gemini_text(v: &Value, out: &mut Vec<String>) {
    if let Some(t) = v.pointer("/serverContent/outputTranscription/text").and_then(|x| x.as_str()) {
        if !t.trim().is_empty() {
            out.push(t.trim().to_string());
        }
    }
    if let Some(parts) = v.pointer("/serverContent/modelTurn/parts").and_then(|p| p.as_array()) {
        for p in parts {
            if let Some(t) = p.get("text").and_then(|x| x.as_str()) {
                if !t.trim().is_empty() {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore = "needs GEMINI_API_KEY"]
    async fn gemini_live_setup_complete() {
        let key = gemini_api_key();
        assert!(!key.is_empty(), "set GEMINI_API_KEY");
        let url = format!("{GEMINI_LIVE_WS}?key={key}");
        let (ws, _) = connect_async(&url).await.expect("connect");
        let (mut tx, mut rx) = ws.split();
        let setup = json!({
            "setup": {
                "model": "models/gemini-3.8-live",
                "generationConfig": { "responseModalities": ["AUDIO"] }
            }
        });
        tx.send(GMsg::Text(setup.to_string().into()))
            .await
            .expect("setup send");
        let msg = tokio::time::timeout(Duration::from_secs(15), rx.next())
            .await
            .expect("timeout")
            .expect("stream")
            .expect("ws");
        let payload = gemini_ws_payload(&msg).expect("payload");
        assert!(payload.contains("setupComplete"), "got: {payload}");
    }
}
