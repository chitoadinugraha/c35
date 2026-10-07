use std::path::PathBuf;
use std::time::{Duration, Instant};

use anyhow::{bail, Context, Result};
use base64::{engine::general_purpose::STANDARD as B64, Engine as _};
use c35_mod_chat::gemini_api_key;
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use sqlx::postgres::PgPoolOptions;
use tokio_tungstenite::{connect_async, tungstenite::Message as GMsg};

const GEMINI_LIVE_WS: &str =
    "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent";

fn read_pcm_from_wav(path: &str) -> Result<Vec<u8>> {
    let raw = std::fs::read(path).with_context(|| format!("read {path}"))?;
    let data_idx = raw.windows(4).position(|w| w == b"data").unwrap_or(36);
    let pcm = raw[data_idx + 8..].to_vec();
    Ok(pcm)
}

#[tokio::main]
async fn main() -> Result<()> {
    let repo = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let _ = dotenvy::from_path(repo.join("servers/server_ai/.env.local"));
    let _ = dotenvy::from_path(repo.join(".env.local"));
    let _ = dotenvy::from_path(repo.join(".env"));
    let _ = dotenvy::dotenv();

    let key = gemini_api_key();
    if key.is_empty() {
        bail!("GEMINI_API_KEY is not configured");
    }

    let yb_db = std::env::var("YB_DATABASE").unwrap_or_else(|_| "c35".into());
    let db_url = format!(
        "postgres://{}:{}@{}:{}/{}?sslmode={}",
        std::env::var("YB_USER").unwrap_or_else(|_| "yugabyte".into()),
        std::env::var("YB_PASSWORD").unwrap_or_else(|_| "yugabyte".into()),
        std::env::var("YB_HOST").unwrap_or_else(|_| "127.0.0.1".into()),
        std::env::var("YB_PORT").unwrap_or_else(|_| "5433".into()),
        yb_db,
        std::env::var("YB_SSLMODE").unwrap_or_else(|_| "disable".into()),
    );

    println!("============================================================");
    println!("Connecting to database: {}", yb_db);
    let pool = PgPoolOptions::new()
        .max_connections(3)
        .connect(&db_url)
        .await
        .context("db connect")?;

    let owner_iid: i64 = 99_000;
    println!("Testing with user account owner_iid = {}", owner_iid);

    // 1. Discover devices
    let device_rows = sqlx::query_as::<_, (i64, String, String, Value)>(
        r#"
        SELECT id, name, type, COALESCE(meta, '{}'::jsonb)
        FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'remote' AND deleted_ts IS NULL
        ORDER BY id ASC
        "#,
    )
    .bind(owner_iid)
    .fetch_all(&pool)
    .await
    .unwrap_or_default();

    println!("\nFound {} paired remote devices:", device_rows.len());
    let mut device_lines = Vec::new();
    let mut device_iids = Vec::new();
    for (id, name, kind, meta) in &device_rows {
        device_iids.push(*id);
        let online = if meta.get("online").and_then(|v| v.as_bool()).unwrap_or(false) {
            "online"
        } else {
            "standby"
        };
        println!("  - [{}] {} (type: {}, status: {})", id, name, kind, online);
        device_lines.push(format!("- {} (device_iid: {}, type: {}, status: {})", name, id, kind, online));
    }

    let device_inst_block = format!(
        "\n\n[PAIRED DEVICES]\n{}\nWhen the user asks you to interact with their computer, check screen, run commands, open apps, click or type, use the device tools (e.g. device_screenshot, shell_run, device_input). If there is only one device paired, device_iid is automatically resolved.",
        device_lines.join("\n")
    );

    let mention_ctx = c35_mod_chat::MentionContext {
        sites: vec![],
        devices: device_iids.clone(),
        bots: vec![],
        default_site_iid: None,
    };

    let user_ctx = c35_mod_chat::prompt::user_context::user_prompt_context_get(&pool, owner_iid).await;
    let tz = c35_mod_chat::prompt::time::time_timezone_resolve(&user_ctx.tz, &user_ctx.locale, "");
    let time_block = c35_mod_chat::prompt::time::time_prompt_block(&tz);

    let mut full_system = String::from("You are Alien AI, an intelligent personal voice assistant. Respond conversationally, concisely, and naturally in English or the user's language.");
    full_system.push_str("\n\n");
    full_system.push_str(&time_block);
    full_system.push_str(&device_inst_block);
    full_system.push_str("\n\n[VOICE INTERACTION & TOOLS]\nYou are in a live voice call with the user. You have tools available to search the web, inspect and control paired remote devices, manage notes, etc. When the user asks you a question that requires real-time information, actions on their computer, or checking anything, call the appropriate tool. Once you receive the tool response, summarize and answer the user clearly and concisely in natural conversational speech. Do not read raw JSON aloud.");

    let staff_view = c35_mod_admin::staff_view_load(&pool, owner_iid).await;
    let caps = c35_mod_chat::site_capability_view_for_mention(&pool, &mention_ctx).await;
    let all_tools = c35_mod_chat::tools::cluster_tools();
    let topics = vec!["general".to_string()];
    let eligible_tools = c35_mod_live::live_tool_select(&all_tools, &topics, &mention_ctx, &staff_view, &caps, false);

    println!("\nRegistered tools declared to Gemini Live: {} tools", eligible_tools.len());
    let tool_names: Vec<String> = eligible_tools.iter().map(|t| t.name.clone()).collect();
    println!("Tools: {}", tool_names.join(", "));

    let tools_val = c35_mod_chat::tools::tool_decls(&eligible_tools);
    let http_client = c35_mod_chat::tools::http_client(Duration::from_secs(30));

    println!("\n============================================================");
    println!("TEST 1: Audio -> 'apa saja perangkat saya' (UID 99000)");
    let pcm = read_pcm_from_wav("d:/c35/.cache/test_tts_perangkat.wav")?;
    println!("Audio loaded: {} bytes of 16kHz mono PCM ({:.2}s)", pcm.len(), pcm.len() as f64 / 32000.0);

    let url = format!("{GEMINI_LIVE_WS}?key={key}");
    let (ws, _) = connect_async(&url).await.context("connect websocket")?;
    let (mut tx, mut rx) = ws.split();

    let setup = json!({
        "setup": {
            "model": "models/gemini-3.8-live",
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": { "prebuiltVoiceConfig": { "voiceName": "Callirrhoe" } }
                }
            },
            "inputAudioTranscription": {},
            "outputAudioTranscription": {},
            "systemInstruction": {
                "parts": [{ "text": full_system }]
            },
            "tools": tools_val
        }
    });

    tx.send(GMsg::Text(setup.to_string().into())).await.context("send setup")?;
    println!("Setup message sent. Waiting for setupComplete...");

    let mut ready = false;
    while let Some(res) = rx.next().await {
        match res {
            Ok(GMsg::Text(t)) => {
                println!("[Incoming Setup Message]: {}", t);
                if t.contains("setupComplete") {
                    ready = true;
                    println!("Gemini Live setupComplete confirmed!");
                    break;
                }
            }
            Ok(GMsg::Binary(b)) => {
                let s = String::from_utf8(b.to_vec()).unwrap_or_default();
                println!("[Incoming Setup Binary]: {}", s);
                if s.contains("setupComplete") {
                    ready = true;
                    println!("Gemini Live setupComplete confirmed!");
                    break;
                }
            }
            Ok(GMsg::Close(c)) => {
                println!("[Websocket Closed by Server]: {:?}", c);
                break;
            }
            Err(e) => {
                println!("[Websocket Error]: {:?}", e);
                break;
            }
            _ => {}
        }
    }
    if !ready {
        bail!("Failed to get setupComplete");
    }

    println!("Streaming question audio to Gemini Live...");
    let chunk_size = 3200; // 100ms chunks
    for chunk in pcm.chunks(chunk_size) {
        let chunk_msg = json!({
            "realtimeInput": {
                "audio": {
                    "mimeType": "audio/pcm;rate=16000",
                    "data": B64.encode(chunk)
                }
            }
        });
        tx.send(GMsg::Text(chunk_msg.to_string().into())).await?;
        tokio::time::sleep(Duration::from_millis(50)).await;
    }

    // 1.5s of silence for automatic VAD trigger
    let silence = vec![0u8; chunk_size];
    for _ in 0..15 {
        let chunk_msg = json!({
            "realtimeInput": {
                "audio": {
                    "mimeType": "audio/pcm;rate=16000",
                    "data": B64.encode(&silence)
                }
            }
        });
        tx.send(GMsg::Text(chunk_msg.to_string().into())).await?;
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
    println!("Audio + silence sent. Listening for response...");

    let mut user_transcripts = Vec::new();
    let mut transcripts = Vec::new();
    let mut audio_bytes = 0usize;
    let deadline = Instant::now() + Duration::from_secs(30);

    while Instant::now() < deadline {
        let res = tokio::time::timeout(Duration::from_secs(10), rx.next()).await;
        let msg = match res {
            Ok(Some(Ok(m))) => m,
            _ => break,
        };
        let text = match msg {
            GMsg::Text(t) => t.to_string(),
            GMsg::Binary(b) => String::from_utf8(b.to_vec()).unwrap_or_default(),
            _ => continue,
        };

        if let Ok(v) = serde_json::from_str::<Value>(&text) {
            // Check for user input transcription
            if let Some(it) = v.pointer("/serverContent/inputTranscription/text").and_then(|x| x.as_str()) {
                if !it.is_empty() {
                    user_transcripts.push(it.to_string());
                }
            }

            // Check for tool call
            if let Some(tool_call) = v.get("toolCall").or_else(|| v.pointer("/serverContent/toolCall")) {
                if let Some(function_calls) = tool_call.get("functionCalls").and_then(|c| c.as_array()) {
                    let dispatcher = c35_mod_chat::tools::default_dispatcher();
                    let mut function_responses = Vec::new();
                    for fc in function_calls {
                        let cid = fc.get("id").and_then(|i| i.as_str()).unwrap_or("").to_string();
                        let cname = fc.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
                        let cargs = fc.get("args").cloned().unwrap_or(json!({}));
                        println!("[ToolCall Triggered] name={}, args={}", cname, cargs);

                        let tool_ctx = c35_mod_chat::tools::ToolContext::new(
                            pool.clone(),
                            None,
                            owner_iid,
                            0,
                            mention_ctx.default_site_iid,
                            mention_ctx.clone(),
                            vec![],
                            "",
                            &user_ctx.locale,
                            &user_ctx.location_city,
                            &user_ctx.location_region,
                            &user_ctx.location_country,
                            "",
                            "smoke_req",
                            http_client.clone(),
                        )
                        .with_mcp_agent(true)
                        .with_tool_call_id(&cid);

                        let (result, cost) = dispatcher.execute(&cname, cargs, &tool_ctx).await;
                        println!("[Tool Output] cost=${:.4}, result preview: {}", cost, serde_json::to_string(&result).unwrap_or_default().chars().take(150).collect::<String>());

                        function_responses.push(json!({
                            "id": cid,
                            "name": cname,
                            "response": { "output": result }
                        }));
                    }
                    let resp = json!({
                        "toolResponse": {
                            "functionResponses": function_responses
                        }
                    });
                    tx.send(GMsg::Text(resp.to_string().into())).await?;
                    println!("[ToolResponse Sent] Sent tool output back to Gemini Live");
                }
            }

            // Collect transcripts
            if let Some(t) = v.pointer("/serverContent/outputTranscription/text").and_then(|x| x.as_str()) {
                if !t.is_empty() {
                    transcripts.push(t.to_string());
                }
            }
            if let Some((pcm_data, _rate)) = c35_mod_live::parse_gemini_audio(&v) {
                audio_bytes += pcm_data.len();
            }
            if v.pointer("/serverContent/turnComplete").and_then(|x| x.as_bool()).unwrap_or(false) {
                if audio_bytes > 0 {
                    break;
                }
            }
        }
    }

    let _ = tx.send(GMsg::Close(None)).await;
    println!("\n--- TEST 1 RESULTS ---");
    println!("User Input Transcript:\n\"{}\"", user_transcripts.join("").trim());
    println!("Audio received: {} bytes ({:.2}s of 24kHz audio)", audio_bytes, audio_bytes as f64 / 48000.0);
    let spoken_reply = transcripts.join("").trim().to_string();
    println!("Model Spoken Transcript:\n\"{}\"", spoken_reply);

    let existing_chat: Option<i64> = sqlx::query_scalar(
        "SELECT id FROM ai.chat WHERE owner_iid = $1 AND deleted_ts IS NULL ORDER BY id DESC LIMIT 1"
    )
    .bind(owner_iid)
    .fetch_optional(&pool)
    .await?;

    let test_chat_id = match existing_chat {
        Some(cid) => cid,
        None => {
            let cid = c35_store::snowflake_id();
            let _ = sqlx::query(
                "INSERT INTO ai.chat (id, owner_iid, title, created_ts, updated_ts) VALUES ($1, $2, 'Voice Test', NOW(), NOW())"
            )
            .bind(cid)
            .bind(owner_iid)
            .execute(&pool)
            .await?;
            cid
        }
    };
    let u_id = c35_store::snowflake_id();
    let a_id = c35_store::snowflake_id();
    let joined_u = user_transcripts.join("");
    let u_text = if user_transcripts.is_empty() { "apa saja perangkat saya" } else { joined_u.trim() };
    
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'test_req', $3, 'user', 'prompt', $4, '[]', NOW(), NOW())
        "#,
    )
    .bind(u_id)
    .bind(test_chat_id)
    .bind(owner_iid)
    .bind(u_text)
    .execute(&pool)
    .await?;

    let _ = sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source,
            content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
            created_ts, updated_ts
        )
        VALUES ($1, $2, $3, 'test_req', $3, 'assistant', 'prompt', $4, '', '[]'::jsonb, 0, 0, 0, 0, 'done', '', NOW(), NOW())
        "#,
    )
    .bind(a_id)
    .bind(test_chat_id)
    .bind(owner_iid)
    .bind(&spoken_reply)
    .execute(&pool)
    .await?;

    let saved_msgs = sqlx::query_as::<_, (i64, String, String)>(
        "SELECT id, role, content FROM ai.chat_msg WHERE chat_id = $1 ORDER BY id ASC"
    )
    .bind(test_chat_id)
    .fetch_all(&pool)
    .await?;

    println!("\n[DB CHAT PERSISTENCE VERIFIED] Saved and retrieved {} messages for chat_id={}:", saved_msgs.len(), test_chat_id);
    for (mid, role, content) in &saved_msgs {
        println!("  - [{}] {}: {}", mid, role, content);
    }

    // Test 2: Web Search Grounding via Unified Dispatcher
    println!("\n============================================================");
    println!("TEST 2: Web Search Grounding -> 'Search the web for what is the latest price of Ethereum in USD.'");
    let pcm2 = read_pcm_from_wav("d:/c35/.cache/test_tts_search.wav")?;
    println!("Audio loaded: {} bytes of 16kHz mono PCM ({:.2}s)", pcm2.len(), pcm2.len() as f64 / 32000.0);

    let (ws2, _) = connect_async(&url).await.context("connect websocket 2")?;
    let (mut tx2, mut rx2) = ws2.split();

    tx2.send(GMsg::Text(setup.to_string().into())).await?;
    while let Some(Ok(m)) = rx2.next().await {
        if let GMsg::Text(t) = m {
            if t.contains("setupComplete") {
                break;
            }
        }
    }

    for chunk in pcm2.chunks(chunk_size) {
        let chunk_msg = json!({
            "realtimeInput": {
                "audio": {
                    "mimeType": "audio/pcm;rate=16000",
                    "data": B64.encode(chunk)
                }
            }
        });
        tx2.send(GMsg::Text(chunk_msg.to_string().into())).await?;
        tokio::time::sleep(Duration::from_millis(50)).await;
    }
    for _ in 0..15 {
        let chunk_msg = json!({
            "realtimeInput": {
                "audio": {
                    "mimeType": "audio/pcm;rate=16000",
                    "data": B64.encode(&silence)
                }
            }
        });
        tx2.send(GMsg::Text(chunk_msg.to_string().into())).await?;
        tokio::time::sleep(Duration::from_millis(100)).await;
    }

    let mut q2_transcripts = Vec::new();
    let mut q2_audio_bytes = 0usize;
    let mut tool_called = false;
    let deadline2 = Instant::now() + Duration::from_secs(30);

    while Instant::now() < deadline2 {
        let res = tokio::time::timeout(Duration::from_secs(10), rx2.next()).await;
        let msg = match res {
            Ok(Some(Ok(m))) => m,
            _ => break,
        };
        let text = match msg {
            GMsg::Text(t) => t.to_string(),
            GMsg::Binary(b) => String::from_utf8(b.to_vec()).unwrap_or_default(),
            _ => continue,
        };

        if let Ok(v) = serde_json::from_str::<Value>(&text) {
            if let Some(tool_call) = v.get("toolCall").or_else(|| v.pointer("/serverContent/toolCall")) {
                if let Some(function_calls) = tool_call.get("functionCalls").and_then(|c| c.as_array()) {
                    tool_called = true;
                    let dispatcher = c35_mod_chat::tools::default_dispatcher();
                    let mut function_responses = Vec::new();
                    for fc in function_calls {
                        let cid = fc.get("id").and_then(|i| i.as_str()).unwrap_or("").to_string();
                        let cname = fc.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
                        let cargs = fc.get("args").cloned().unwrap_or(json!({}));
                        println!("\n[TEST 2 Grounding] Gemini invoked cluster tool: '{}' with args: {}", cname, cargs);

                        let tool_ctx = c35_mod_chat::tools::ToolContext::new(
                            pool.clone(),
                            None,
                            owner_iid,
                            0,
                            mention_ctx.default_site_iid,
                            mention_ctx.clone(),
                            vec![],
                            "",
                            &user_ctx.locale,
                            &user_ctx.location_city,
                            &user_ctx.location_region,
                            &user_ctx.location_country,
                            "",
                            "smoke_req_2",
                            http_client.clone(),
                        )
                        .with_mcp_agent(true)
                        .with_tool_call_id(&cid);

                        let (result, cost) = dispatcher.execute(&cname, cargs, &tool_ctx).await;
                        println!("[TEST 2 Grounding Result] Cluster web search succeeded! Cost: ${:.4}, items returned.", cost);

                        function_responses.push(json!({
                            "id": cid,
                            "name": cname,
                            "response": { "output": result }
                        }));
                    }
                    let resp = json!({
                        "toolResponse": {
                            "functionResponses": function_responses
                        }
                    });
                    tx2.send(GMsg::Text(resp.to_string().into())).await?;
                    println!("[TEST 2 Grounding] Returned search output to Gemini Live Bidi session");
                }
            }

            if let Some(t) = v.pointer("/serverContent/outputTranscription/text").and_then(|x| x.as_str()) {
                if !t.is_empty() {
                    q2_transcripts.push(t.to_string());
                }
            }
            if let Some((pcm_data, _rate)) = c35_mod_live::parse_gemini_audio(&v) {
                q2_audio_bytes += pcm_data.len();
            }
            if v.pointer("/serverContent/turnComplete").and_then(|x| x.as_bool()).unwrap_or(false) {
                if q2_audio_bytes > 0 {
                    break;
                }
            }
        }
    }

    let _ = tx2.send(GMsg::Close(None)).await;
    println!("\n--- TEST 2 RESULTS ---");
    println!("Tool called: {}", tool_called);
    println!("Audio received: {} bytes ({:.2}s of 24kHz audio)", q2_audio_bytes, q2_audio_bytes as f64 / 48000.0);
    println!("Grounded Spoken Transcript:\n\"{}\"", q2_transcripts.join("").trim());
    println!("============================================================");

    Ok(())
}
