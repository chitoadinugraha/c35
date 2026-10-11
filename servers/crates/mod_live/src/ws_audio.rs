use axum::extract::ws::Message;
use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_proto::LiveWsAudio;
use prost::Message as ProstMessage;
use serde_json::Value;

pub const LIVE_WS_AUDIO_MAGIC: [u8; 2] = [0xC3, 0x35];

pub fn encode_audio_frame(sample_rate_hz: u32, pcm_s16le: &[u8]) -> Vec<u8> {
    let msg = LiveWsAudio {
        sample_rate_hz,
        pcm_s16le: pcm_s16le.to_vec(),
    };
    let mut out = Vec::with_capacity(2 + msg.encoded_len());
    out.extend_from_slice(&LIVE_WS_AUDIO_MAGIC);
    msg.encode(&mut out).expect("LiveWsAudio encode");
    out
}

pub fn decode_audio_frame(bytes: &[u8]) -> Option<(u32, Vec<u8>)> {
    if bytes.len() < 3 || bytes[0] != LIVE_WS_AUDIO_MAGIC[0] || bytes[1] != LIVE_WS_AUDIO_MAGIC[1] {
        return None;
    }
    let msg = LiveWsAudio::decode(bytes.get(2..)?).ok()?;
    if msg.pcm_s16le.is_empty() {
        return None;
    }
    let rate = msg.sample_rate_hz.max(8000);
    Some((rate, msg.pcm_s16le))
}

fn inline_audio_rate_mime(mime: &str) -> u32 {
    mime
        .split("rate=")
        .nth(1)
        .and_then(|s| s.split(';').next())
        .and_then(|s| s.parse().ok())
        .unwrap_or(24_000)
}

fn decode_inline_audio(inline: &Value) -> Option<(u32, Vec<u8>)> {
    let data = inline
        .get("data")
        .and_then(|d| d.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())?;
    let mime = inline
        .get("mimeType")
        .or_else(|| inline.get("mime_type"))
        .and_then(|m| m.as_str())
        .unwrap_or("audio/pcm;rate=24000");
    let pcm = B64.decode(data).ok()?;
    if pcm.is_empty() {
        return None;
    }
    Some((inline_audio_rate_mime(mime), pcm))
}

/// Pulls PCM from Gemini-style `serverContent.modelTurn.parts` and removes inline audio parts.
pub fn gemini_json_strip_audio(value: &mut Value) -> Vec<(u32, Vec<u8>)> {
    let mut extracted = Vec::new();
    let Some(parts) = value.pointer_mut("/serverContent/modelTurn/parts") else {
        return extracted;
    };
    let Some(parts) = parts.as_array_mut() else {
        return extracted;
    };

    let mut i = 0;
    while i < parts.len() {
        let inline = parts[i]
            .get("inlineData")
            .or_else(|| parts[i].get("inline_data"));
        if let Some(inline) = inline {
            if let Some((rate, pcm)) = decode_inline_audio(inline) {
                extracted.push((rate, pcm));
            }
            parts.remove(i);
            continue;
        }
        i += 1;
    }

    if parts.is_empty() {
        if let Some(sc) = value.get_mut("serverContent") {
            if let Some(obj) = sc.as_object_mut() {
                obj.remove("modelTurn");
            }
        }
    }

    extracted
}

/// Sends protobuf audio frames + lightweight JSON (no base64 audio) to the app client.
pub async fn live_client_send_gemini_value(
    client: &mut axum::extract::ws::WebSocket,
    value: &Value,
) -> Result<(), axum::Error> {
    let mut v = value.clone();
    let chunks = gemini_json_strip_audio(&mut v);
    for (rate, pcm) in chunks {
        let frame = encode_audio_frame(rate, &pcm);
        client.send(Message::Binary(frame.into())).await?;
    }
    if let Some(text) = gemini_json_for_client_after_audio_strip(&v) {
        client.send(Message::Text(text.into())).await?;
    }
    Ok(())
}

/// Returns JSON text for the client when anything remains after audio strip; otherwise None.
pub fn gemini_json_for_client_after_audio_strip(value: &Value) -> Option<String> {
    if value.is_null() {
        return None;
    }
    if value.as_object().is_some_and(|o| o.is_empty()) {
        return None;
    }
    let sc = value.get("serverContent");
    if sc.is_some_and(|s| {
        s.as_object().is_some_and(|o| {
            o.is_empty()
                || (o.len() == 1 && o.contains_key("modelTurn") && o["modelTurn"].is_null())
        })
    }) && value.as_object().is_some_and(|o| o.len() == 1) {
        return None;
    }
    serde_json::to_string(value).ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn roundtrip_audio_frame() {
        let pcm = vec![0u8, 1, 0, 2, 0, 3];
        let frame = encode_audio_frame(24_000, &pcm);
        let (rate, out) = decode_audio_frame(&frame).expect("decode");
        assert_eq!(rate, 24_000);
        assert_eq!(out, pcm);
    }

    #[test]
    fn strip_audio_from_model_turn() {
        let mut v = json!({
            "serverContent": {
                "modelTurn": {
                    "parts": [{
                        "inlineData": {
                            "mimeType": "audio/pcm;rate=24000",
                            "data": "AAEC"
                        }
                    }]
                },
                "turnComplete": true
            }
        });
        let chunks = gemini_json_strip_audio(&mut v);
        assert_eq!(chunks.len(), 1);
        assert!(v.pointer("/serverContent/modelTurn").is_none());
        assert_eq!(v["serverContent"]["turnComplete"], true);
        let text = gemini_json_for_client_after_audio_strip(&v).expect("json");
        assert!(!text.contains("inlineData"));
    }
}
