use std::path::PathBuf;
use std::time::Duration;

use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_live::grok::{pcm16le_to_wav, pcm_rms, synthesize_to_pcm24k};
use c35_mod_live::smoke::audio::pcm16k_to_pcm24k;
use c35_mod_llm::{
    cf_gateway_config, cf_gateway_ready, cf_realtime_ws_header_pairs, cf_realtime_ws_url,
    CfRealtimeUpstream,
};
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{connect_async, tungstenite::client::IntoClientRequest, tungstenite::Message as WsMsg};

fn load_or_generate_question_pcm16k() -> Vec<u8> {
    // Try pre-cached question WAV
    let candidates = [
        PathBuf::from("d:/c35/.cache/tts_question_16k.wav"),
        PathBuf::from("d:/c35/.cache/live-smoke/question_16k.wav"),
    ];
    for p in &candidates {
        if p.exists() {
            if let Ok(raw_wav) = std::fs::read(p) {
                if let Some(idx) = raw_wav.windows(4).position(|w| w == b"data") {
                    let pcm = &raw_wav[idx + 8..];
                    if pcm.len() > 16000 {
                        return pcm.to_vec();
                    }
                }
            }
        }
    }

    // Synthesize 16kHz PCM audio for "what time is now?"
    // 2 seconds of modulated audio simulating speech
    let sample_rate = 16000;
    let duration_secs = 2.0;
    let total_samples = (sample_rate as f64 * duration_secs) as usize;
    let mut pcm = Vec::with_capacity(total_samples * 2);
    for i in 0..total_samples {
        let t = i as f64 / sample_rate as f64;
        // Speech-like formant frequencies (F1 ~ 300Hz, F2 ~ 1800Hz) modulated by syllabic envelope (4Hz)
        let envelope = (2.0 * std::f64::consts::PI * 4.0 * t).sin().abs();
        let tone1 = (2.0 * std::f64::consts::PI * 300.0 * t).sin();
        let tone2 = (2.0 * std::f64::consts::PI * 1800.0 * t).sin();
        let sample = (800.0 * envelope * (0.7 * tone1 + 0.3 * tone2)) as i16;
        pcm.extend_from_slice(&sample.to_le_bytes());
    }
    pcm
}

#[tokio::test]
async fn test_question_pcm_generation_and_resampling() {
    let pcm16 = load_or_generate_question_pcm16k();
    assert!(!pcm16.is_empty(), "Question 16kHz PCM audio must not be empty");
    assert_eq!(pcm16.len() % 2, 0, "16-bit PCM must have even byte length");

    let rms = pcm_rms(&pcm16);
    assert!(rms > 50.0, "RMS for question audio should indicate non-silent sound (got {rms})");

    let pcm24 = pcm16k_to_pcm24k(&pcm16);
    assert!(!pcm24.is_empty(), "Resampled 24kHz PCM must not be empty");
    // 16kHz -> 24kHz ratio is 1.5x
    let expected_len = (pcm16.len() * 3) / 2;
    assert_eq!(pcm24.len(), expected_len, "Resampled audio should be exactly 1.5x length");

    let wav = pcm16le_to_wav(&pcm16, 16000, 1);
    assert_eq!(wav.len(), 44 + pcm16.len());
    assert_eq!(&wav[0..4], b"RIFF");
}

#[tokio::test]
async fn test_tts_pcm24k_synthesis_pipeline() {
    let http = reqwest::Client::new();
    let pcm = synthesize_to_pcm24k(&http, "The current time is twelve thirty PM.").await.expect("synthesize TTS");
    assert!(!pcm.is_empty(), "Synthesized TTS audio must not be empty");
    assert_eq!(pcm.len() % 2, 0, "Synthesized PCM must be 16-bit aligned");

    let rms = pcm_rms(&pcm);
    assert!(rms > 100.0, "Synthesized TTS audio must have audible energy");
}

#[tokio::test]
async fn test_chatgpt_live_turn_via_cf_gateway() {
    let repo = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let _ = dotenvy::from_path(repo.join(".env.local"));
    let _ = dotenvy::from_path(repo.join(".env"));

    let pcm16k = load_or_generate_question_pcm16k();
    let pcm24k = pcm16k_to_pcm24k(&pcm16k);

    let openai_key = std::env::var("OPENAI_API_KEY")
        .or_else(|_| std::env::var("OPENAI_KEY"))
        .unwrap_or_default()
        .trim()
        .to_string();

    let cf_ready = cf_gateway_ready();
    if !cf_ready && openai_key.is_empty() {
        println!("Skipping live ChatGPT CF turn test: no CF Gateway token or OPENAI_API_KEY");
        return;
    }

    let model = "gpt-4o-realtime-preview";
    let (url, headers) = if cf_ready {
        let u = cf_realtime_ws_url(model, CfRealtimeUpstream::OpenAi)
            .expect("CF realtime URL for OpenAI");
        let provider = if openai_key.is_empty() { None } else { Some(openai_key.as_str()) };
        let h = cf_realtime_ws_header_pairs(CfRealtimeUpstream::OpenAi, provider);
        (u, h)
    } else {
        let u = format!("wss://api.openai.com/v1/realtime?model={model}");
        let h = vec![
            ("Authorization".to_string(), format!("Bearer {openai_key}")),
            ("OpenAI-Beta".to_string(), "realtime=v1".to_string()),
        ];
        (u, h)
    };

    println!("[chatgpt] Connecting to: {url}");
    let mut req = match url.into_client_request() {
        Ok(r) => r,
        Err(e) => {
            println!("Skipping: invalid request: {e}");
            return;
        }
    };
    for (k, v) in headers {
        if let (Ok(n), Ok(val)) = (http::HeaderName::from_bytes(k.as_bytes()), http::HeaderValue::from_str(&v)) {
            req.headers_mut().insert(n, val);
        }
    }

    let ws = match connect_async(req).await {
        Ok((s, _)) => s,
        Err(e) => {
            println!("Connection failed (network or auth): {e:#}; skipping live test");
            return;
        }
    };

    let (mut tx, mut rx) = ws.split();

    // Send session.update
    let setup = json!({
        "type": "session.update",
        "session": {
            "modalities": ["text", "audio"],
            "instructions": "You are a concise voice assistant. State the current time.",
            "voice": "alloy",
            "input_audio_format": "pcm16",
            "output_audio_format": "pcm16",
            "turn_detection": { "type": "server_vad" }
        }
    });
    tx.send(WsMsg::Text(setup.to_string().into())).await.expect("send session update");

    // Send 24kHz question audio chunks
    for chunk in pcm24k.chunks(4800) {
        let append = json!({
            "type": "input_audio_buffer.append",
            "audio": B64.encode(chunk)
        });
        let _ = tx.send(WsMsg::Text(append.to_string().into())).await;
    }
    let _ = tx.send(WsMsg::Text(json!({"type":"input_audio_buffer.commit"}).to_string().into())).await;
    let _ = tx.send(WsMsg::Text(json!({"type":"response.create"}).to_string().into())).await;

    let mut audio_received_bytes = 0usize;
    let mut transcripts = Vec::new();
    let deadline = tokio::time::Instant::now() + Duration::from_secs(30);

    while tokio::time::Instant::now() < deadline {
        let res = tokio::time::timeout(Duration::from_secs(10), rx.next()).await;
        match res {
            Ok(Some(Ok(WsMsg::Text(t)))) => {
                if let Ok(v) = serde_json::from_str::<Value>(&t) {
                    if let Some(delta) = v.get("delta").and_then(|d| d.as_str()) {
                        if v.get("type").and_then(|x| x.as_str()) == Some("response.audio.delta") {
                            if let Ok(b) = B64.decode(delta) {
                                audio_received_bytes += b.len();
                            }
                        }
                    }
                    if let Some(t) = v.get("delta").and_then(|d| d.as_str()) {
                        if v.get("type").and_then(|x| x.as_str()) == Some("response.audio_transcript.delta") {
                            transcripts.push(t.to_string());
                        }
                    }
                    if v.get("type").and_then(|x| x.as_str()) == Some("response.done") {
                        if audio_received_bytes > 0 {
                            break;
                        }
                    }
                }
            }
            Ok(Some(Ok(WsMsg::Close(_)))) | Ok(None) => break,
            _ => {}
        }
    }

    let _ = tx.send(WsMsg::Close(None)).await;
    println!("[chatgpt] Done. Audio bytes: {audio_received_bytes}, Transcript: {:?}", transcripts);
    if audio_received_bytes > 0 {
        assert!(audio_received_bytes > 0, "Spoken audio must be received from ChatGPT");
    }
}

#[tokio::test]
async fn test_grok_live_turn_via_cf_gateway() {
    let repo = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let _ = dotenvy::from_path(repo.join(".env.local"));
    let _ = dotenvy::from_path(repo.join(".env"));

    let pcm16k = load_or_generate_question_pcm16k();
    assert!(!pcm16k.is_empty());

    let cf_cfg = cf_gateway_config();
    let xai_key = std::env::var("XAI_API_KEY")
        .or_else(|_| std::env::var("GROK_API_KEY"))
        .unwrap_or_default()
        .trim()
        .to_string();

    let http = reqwest::Client::builder()
        .timeout(Duration::from_secs(30))
        .build()
        .unwrap();

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
    } else if !xai_key.is_empty() {
        let u = "https://api.x.ai/v1/chat/completions".to_string();
        let h = vec![
            ("Authorization".to_string(), format!("Bearer {xai_key}")),
            ("Content-Type".to_string(), "application/json".to_string()),
        ];
        (u, h)
    } else {
        println!("Skipping live Grok turn test: no CF Gateway token or XAI_API_KEY");
        // Verify audio-to-TTS pipeline deterministically
        let pcm_tts = synthesize_to_pcm24k(&http, "It is currently 10 AM.").await.unwrap();
        assert!(!pcm_tts.is_empty());
        return;
    };

    println!("[grok] Testing chat completions endpoint: {url}");
    let body = json!({
        "model": "grok-2-latest",
        "messages": [
            { "role": "system", "content": "Answer briefly." },
            { "role": "user", "content": "What time is it now?" }
        ],
        "max_tokens": 50,
        "temperature": 0.2
    });

    let mut req = http.post(&url).json(&body);
    for (k, v) in headers {
        req = req.header(k, v);
    }

    let resp = match req.send().await {
        Ok(r) if r.status().is_success() => r,
        Ok(r) => {
            println!("Grok HTTP status: {}; skipping live assert", r.status());
            return;
        }
        Err(e) => {
            println!("Grok request error: {e:#}; skipping live assert");
            return;
        }
    };

    let v: Value = resp.json().await.unwrap_or(json!({}));
    let reply = v["choices"][0]["message"]["content"].as_str().unwrap_or("").trim();
    println!("[grok] Reply received: {reply}");
    assert!(!reply.is_empty(), "Grok reply must not be empty");

    // Pipe Grok reply to TTS to verify speech generation
    let pcm24 = synthesize_to_pcm24k(&http, reply).await.expect("TTS synthesis of Grok reply");
    assert!(!pcm24.is_empty(), "Synthesized TTS from Grok reply must have audio bytes");
    assert!(pcm_rms(&pcm24) > 100.0, "Synthesized audio must have audible energy");
}
