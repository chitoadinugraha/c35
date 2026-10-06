use std::time::Instant;

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

    let http_client = c35_mod_chat::tools::http_client(std::time::Duration::from_secs(30));

    // Discover paired remote devices for the caller
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
    let device_iids: Vec<i64> = device_rows.iter().map(|(id, ..)| *id).collect();

    let mut device_lines = Vec::new();
    for (id, name, kind, meta) in &device_rows {
        let online = if meta.get("online").and_then(|v| v.as_bool()).unwrap_or(false) {
            "online"
        } else {
            "standby"
        };
        device_lines.push(format!("- {} (device_iid: {}, type: {}, status: {})", name, id, kind, online));
    }
    let device_inst_block = if !device_lines.is_empty() {
        format!(
            "\n\n[PAIRED DEVICES]\n{}\nWhen the user asks you to interact with their computer, check screen, run commands, open apps, click or type, use the device tools (e.g. device_screenshot, shell_run, device_input). If there is only one device paired, device_iid is automatically resolved.",
            device_lines.join("\n")
        )
    } else {
        String::new()
    };

    let mut active_mention_ids = ticket.mention_ids.clone();
    let mut mention_label = String::new();
    let mut mention_ctx = live_mention_context(&pool, owner_iid, &active_mention_ids, &device_iids).await;
    let site_inst_block = c35_mod_chat::mention_context_sites_block(&mention_ctx);

    // User prompt context (timezone, location, locale)
    let user_ctx = c35_mod_chat::prompt::user_context::user_prompt_context_get(&pool, owner_iid).await;
    let tz = c35_mod_chat::prompt::time::time_timezone_resolve(&user_ctx.tz, &user_ctx.locale, "");
    let time_block = c35_mod_chat::prompt::time::time_prompt_block(&tz);

    let chat_id_opt = ticket.chat_id;
    let history_rows = live_recent_msgs(&pool, chat_id_opt).await;
    let mut full_system = live_voice_system(
        &live_inst_text(&pool, &offer.inst_id).await,
        &time_block,
        &user_ctx.location_city,
        &device_inst_block,
        &site_inst_block,
    );

    let staff_view = c35_mod_admin::staff_view_load(&pool, owner_iid).await;
    let mut caps = c35_mod_chat::site_capability_view_for_mention(&pool, &mention_ctx).await;
    let all_tools = c35_mod_chat::tools::cluster_tools();
    let mut eligible_tools = crate::live_tool_select(&all_tools, &offer.tool_topics, &mention_ctx, &staff_view, &caps);
    tracing::info!(decls = eligible_tools.len(), offer = %offer.id, "live: tool decls");

    let mut tools_val = if !eligible_tools.is_empty() {
        Some(c35_mod_chat::tools::tool_decls(&eligible_tools))
    } else {
        None
    };

    let mut resume = crate::LiveResume::default();
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
    let voice_name = std::env::var("GEMINI_LIVE_VOICE").unwrap_or_else(|_| "Callirrhoe".into());

    let mut setup_obj = json!({
        "model": model,
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": { "voiceName": voice_name }
                }
            }
        },
        "inputAudioTranscription": {},
        "outputAudioTranscription": {},
        "systemInstruction": {
            "parts": [{ "text": full_system }]
        }
    });
    if let Some(fields) = resume.setup_fields().as_object() {
        for (k, v) in fields {
            setup_obj[k] = v.clone();
        }
    }
    if let Some(tv) = tools_val.clone() {
        setup_obj["tools"] = tv;
    }
    let setup = json!({ "setup": setup_obj });
    if g_tx.send(GMsg::Text(setup.to_string().into())).await.is_err() {
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    let mut ready = false;
    let mut turn_user_text = String::new();
    let mut turn_assistant_text = String::new();
    let mut turn_tool_blocks: Vec<Value> = Vec::new();
    let mut swap_job: Option<(Vec<String>, String)> = None;
    let mut pending_mention: Option<(Vec<String>, String)> = None;
    let mut generation_open = false;
    let mut last_swap: Option<Instant> = None;
    let mut seeded = false;
    let mut opened_with_handle = false;
    let mut announce_mention = false;
    loop {
        if swap_job.is_none() {
            if let Some((ids, label)) = pending_mention.clone() {
                if ids != active_mention_ids
                    && crate::live_swap_should_run(Instant::now(), last_swap, false, generation_open)
                {
                    pending_mention = None;
                    swap_job = Some((ids, label));
                }
            }
        }
        if let Some((ids, label)) = swap_job.take() {
            let _ = client
                .send(Message::Text(
                    json!({"live":"mention","mention_ids": ids, "label": label, "switching": true})
                        .to_string()
                        .into(),
                ))
                .await;
            let _ = g_tx.send(GMsg::Close(None)).await;
            active_mention_ids = ids;
            mention_label = label;
            mention_ctx = live_mention_context(&pool, owner_iid, &active_mention_ids, &device_iids).await;
            caps = c35_mod_chat::site_capability_view_for_mention(&pool, &mention_ctx).await;
            let site_inst_block = c35_mod_chat::mention_context_sites_block(&mention_ctx);
            full_system = live_voice_system(
                &live_inst_text(&pool, &offer.inst_id).await,
                &time_block,
                &user_ctx.location_city,
                &device_inst_block,
                &site_inst_block,
            );
            eligible_tools = crate::live_tool_select(&all_tools, &offer.tool_topics, &mention_ctx, &staff_view, &caps);
            tracing::info!(decls = eligible_tools.len(), offer = %offer.id, "live: tool decls");
            tools_val = if !eligible_tools.is_empty() {
                Some(c35_mod_chat::tools::tool_decls(&eligible_tools))
            } else {
                None
            };
            opened_with_handle = resume.handle.is_some();
            let mut setup = live_setup_message(&model, &voice_name, &full_system, &resume, &tools_val);
            let google = match connect_async(&url).await {
                Ok((s, _)) => s,
                Err(e) => {
                    warn!(?e, "live: google resume connect failed");
                    if opened_with_handle {
                        resume.handle = None;
                        opened_with_handle = false;
                        setup = live_setup_message(&model, &voice_name, &full_system, &resume, &tools_val);
                        match connect_async(&url).await {
                            Ok((s, _)) => s,
                            Err(e2) => {
                                warn!(?e2, "live: google fresh connect failed");
                                break;
                            }
                        }
                    } else {
                        break;
                    }
                }
            };
            let split = google.split();
            g_tx = split.0;
            g_rx = split.1;
            if g_tx.send(GMsg::Text(setup.to_string().into())).await.is_err() {
                break;
            }
            last_swap = Some(Instant::now());
            seeded = false;
            announce_mention = true;
            ready = false;
        }
        tokio::select! {
            c_msg = client.recv() => {
                match c_msg {
                    Some(Ok(Message::Binary(pcm))) if !pcm.is_empty() => {
                        if !ready {
                            continue;
                        }
                        let chunk = json!({
                            "realtimeInput": {
                                "audio": {
                                    "mimeType": "audio/pcm;rate=16000",
                                    "data": B64.encode(&pcm)
                                }
                            }
                        });
                        if g_tx.send(GMsg::Text(chunk.to_string().into())).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Text(t))) => {
                        let trimmed = t.trim();
                        if trimmed == r#"{"type":"hangup"}"# {
                            break;
                        }
                        if let Some((ids, label)) = live_mention_frame(trimmed) {
                            if ids != active_mention_ids {
                                if crate::live_swap_should_run(Instant::now(), last_swap, false, generation_open) {
                                    swap_job = Some((ids, label));
                                } else {
                                    pending_mention = Some((ids, label));
                                }
                            }
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
            g_msg = g_rx.next() => {
                match g_msg {
                    Some(Ok(GMsg::Text(t))) => {
                        if !ready && t.contains("setupComplete") {
                            ready = true;
                            let _ = client.send(Message::Text(r#"{"live":"ready"}"#.into())).await;
                            live_seed_after_setup(&mut g_tx, &mut client, &resume, opened_with_handle, &history_rows, &mention_label, &active_mention_ids, &mut seeded, announce_mention).await;
                        }
                        if let Ok(v) = serde_json::from_str::<Value>(&t) {
                            resume.note_server_msg(&v);
                            live_turn_flags(&v, &mut generation_open);
                            if !generation_open {
                                if let Some((ids, label)) = pending_mention.clone() {
                                    if ids != active_mention_ids
                                        && crate::live_swap_should_run(Instant::now(), last_swap, false, false)
                                    {
                                        pending_mention = None;
                                        swap_job = Some((ids, label));
                                    }
                                }
                            }
                        }
                        if client.send(Message::Text(t.to_string().into())).await.is_err() {
                            break;
                        }

                        // Check and handle toolCall
                        if let Ok(v) = serde_json::from_str::<Value>(&t) {
                            if let Some(tool_call) = v.get("toolCall").or_else(|| v.pointer("/serverContent/toolCall")) {
                                if let Some(function_calls) = tool_call.get("functionCalls").and_then(|c| c.as_array()) {
                                    let dispatcher = c35_mod_chat::tools::default_dispatcher();
                                    let mut function_responses = Vec::with_capacity(function_calls.len());

                                    for fc in function_calls {
                                        let call_id = fc.get("id").and_then(|i| i.as_str()).unwrap_or("").to_string();
                                        let call_name = fc.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
                                        let call_args = fc.get("args").cloned().unwrap_or(json!({}));

                                        tracing::info!(tool = %call_name, call_id = %call_id, req_id = %sid, "live: executing tool call");

                                        let tool_ctx = c35_mod_chat::tools::ToolContext::new(
                                            pool.clone(),
                                            nats.clone(),
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
                                            &req_id,
                                            http_client.clone(),
                                        )
                                        .with_mcp_agent(true)
                                        .with_tool_call_id(&call_id);

                                        let (mut result, cost_usd) = dispatcher.execute(&call_name, call_args.clone(), &tool_ctx).await;
                                        tracing::info!(tool = %call_name, cost_usd, "live: tool executed");
                                        turn_tool_blocks.push(json!({
                                            "kind": "tool",
                                            "collapsed": false,
                                            "body": {
                                                "name": call_name,
                                                "args": call_args,
                                                "result": result.clone()
                                            }
                                        }));

                                        // If screenshot captured, stream as video frame to Gemini Live visual input
                                        if let Some(b64) = result.get("image_base64").and_then(|v| v.as_str()) {
                                            let video_chunk = json!({
                                                "realtimeInput": {
                                                    "video": {
                                                        "mimeType": "image/jpeg",
                                                        "data": b64
                                                    }
                                                }
                                            });
                                            let _ = g_tx.send(GMsg::Text(video_chunk.to_string().into())).await;
                                            if let Some(obj) = result.as_object_mut() {
                                                obj.insert(
                                                    "image_base64".into(),
                                                    json!("[Screenshot captured and delivered to visual perception stream]"),
                                                );
                                            }
                                        }

                                        function_responses.push(json!({
                                            "id": call_id,
                                            "name": call_name,
                                            "response": {
                                                "output": result
                                            }
                                        }));
                                    }

                                    let resp_msg = json!({
                                        "toolResponse": {
                                            "functionResponses": function_responses
                                        }
                                    });
                                    if g_tx.send(GMsg::Text(resp_msg.to_string().into())).await.is_err() {
                                        warn!("live: failed to send toolResponse to Gemini Live");
                                        break;
                                    }
                                }
                            }

                            live_process_server_content(
                                &v,
                                &pool,
                                &mut client,
                                chat_id_opt,
                                owner_iid,
                                &req_id,
                                &mut turn_user_text,
                                &mut turn_assistant_text,
                                &mut turn_tool_blocks,
                            )
                            .await;
                        }
                    }
                    Some(Ok(GMsg::Binary(b))) => {
                        if !ready {
                            if let Ok(s) = String::from_utf8(b.to_vec()) {
                                if s.contains("setupComplete") {
                                    ready = true;
                                    let _ = client.send(Message::Text(r#"{"live":"ready"}"#.into())).await;
                                    live_seed_after_setup(&mut g_tx, &mut client, &resume, opened_with_handle, &history_rows, &mention_label, &active_mention_ids, &mut seeded, announce_mention).await;
                                }
                            }
                        }
                        let out = if let Ok(s) = String::from_utf8(b.to_vec()) {
                            Message::Text(s.into())
                        } else {
                            Message::Binary(b.clone())
                        };
                        if client.send(out).await.is_err() {
                            break;
                        }

                        // Check and handle toolCall in binary UTF-8 payloads
                        if let Ok(v) = serde_json::from_slice::<Value>(&b) {
                            resume.note_server_msg(&v);
                            live_turn_flags(&v, &mut generation_open);
                            if let Some(tool_call) = v.get("toolCall").or_else(|| v.pointer("/serverContent/toolCall")) {
                                if let Some(function_calls) = tool_call.get("functionCalls").and_then(|c| c.as_array()) {
                                    let dispatcher = c35_mod_chat::tools::default_dispatcher();
                                    let mut function_responses = Vec::with_capacity(function_calls.len());

                                    for fc in function_calls {
                                        let call_id = fc.get("id").and_then(|i| i.as_str()).unwrap_or("").to_string();
                                        let call_name = fc.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
                                        let call_args = fc.get("args").cloned().unwrap_or(json!({}));

                                        tracing::info!(tool = %call_name, call_id = %call_id, req_id = %sid, "live: executing tool call");

                                        let tool_ctx = c35_mod_chat::tools::ToolContext::new(
                                            pool.clone(),
                                            nats.clone(),
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
                                            &req_id,
                                            http_client.clone(),
                                        )
                                        .with_mcp_agent(true)
                                        .with_tool_call_id(&call_id);

                                        let (mut result, cost_usd) = dispatcher.execute(&call_name, call_args.clone(), &tool_ctx).await;
                                        tracing::info!(tool = %call_name, cost_usd, "live: tool executed");
                                        turn_tool_blocks.push(json!({
                                            "kind": "tool",
                                            "collapsed": false,
                                            "body": {
                                                "name": call_name,
                                                "args": call_args,
                                                "result": result.clone()
                                            }
                                        }));

                                        // If screenshot captured, stream as video frame to Gemini Live visual input
                                        if let Some(b64) = result.get("image_base64").and_then(|v| v.as_str()) {
                                            let video_chunk = json!({
                                                "realtimeInput": {
                                                    "video": {
                                                        "mimeType": "image/jpeg",
                                                        "data": b64
                                                    }
                                                }
                                            });
                                            let _ = g_tx.send(GMsg::Text(video_chunk.to_string().into())).await;
                                            if let Some(obj) = result.as_object_mut() {
                                                obj.insert(
                                                    "image_base64".into(),
                                                    json!("[Screenshot captured and delivered to visual perception stream]"),
                                                );
                                            }
                                        }

                                        function_responses.push(json!({
                                            "id": call_id,
                                            "name": call_name,
                                            "response": {
                                                "output": result
                                            }
                                        }));
                                    }

                                    let resp_msg = json!({
                                        "toolResponse": {
                                            "functionResponses": function_responses
                                        }
                                    });
                                    if g_tx.send(GMsg::Text(resp_msg.to_string().into())).await.is_err() {
                                        warn!("live: failed to send toolResponse to Gemini Live");
                                        break;
                                    }
                                }
                            }

                            live_process_server_content(
                                &v,
                                &pool,
                                &mut client,
                                chat_id_opt,
                                owner_iid,
                                &req_id,
                                &mut turn_user_text,
                                &mut turn_assistant_text,
                                &mut turn_tool_blocks,
                            )
                            .await;
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

fn live_voice_system(inst: &str, time_block: &str, city: &str, device_block: &str, site_block: &str) -> String {
    let mut full = String::new();
    full.push_str(inst);
    full.push_str("\n\n");
    full.push_str(time_block);
    if !city.is_empty() {
        full.push_str(&format!("\n\n[USER LOCATION] {city}\n"));
    }
    if !device_block.is_empty() {
        full.push_str(device_block);
    }
    if !site_block.is_empty() {
        full.push_str("\n\n");
        full.push_str(site_block);
    }
    full.push_str("\n\n[VOICE INTERACTION & TOOLS]\nYou are in a live voice call with the user. You have tools available to search the web, inspect and control paired remote devices, manage notes, etc. When the user asks you a question that requires real-time information, actions on their computer, or checking anything, call the appropriate tool. Once you receive the tool response, summarize and answer the user clearly and concisely in natural conversational speech. Do not read raw JSON aloud.");
    full
}

async fn live_mention_context(
    pool: &PgPool,
    owner_iid: i64,
    mention_ids: &[String],
    paired_devices: &[i64],
) -> c35_mod_chat::MentionContext {
    let resolved = c35_mod_chat::mention_resolve_all(pool, owner_iid, mention_ids).await;
    let mut ctx = c35_mod_chat::mention_context_build(&resolved);
    for id in paired_devices {
        if !ctx.devices.contains(id) {
            ctx.devices.push(*id);
        }
    }
    ctx
}

async fn live_recent_msgs(pool: &PgPool, chat_id: Option<i64>) -> Vec<(String, String)> {
    let Some(cid) = chat_id else {
        return Vec::new();
    };
    let mut rows = sqlx::query_as::<_, (String, String)>(
        r#"
        SELECT role, content
        FROM ai.chat_msg
        WHERE chat_id = $1 AND deleted_ts IS NULL AND status <> 'error'
        ORDER BY id DESC
        LIMIT 6
        "#,
    )
    .bind(cid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.reverse();
    rows
}

fn live_setup_message(model: &str, voice_name: &str, system: &str, resume: &crate::LiveResume, tools: &Option<Value>) -> Value {
    let mut setup_obj = json!({
        "model": model,
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": { "voiceName": voice_name }
                }
            }
        },
        "inputAudioTranscription": {},
        "outputAudioTranscription": {},
        "systemInstruction": { "parts": [{ "text": system }] }
    });
    if let Some(fields) = resume.setup_fields().as_object() {
        for (k, v) in fields {
            setup_obj[k] = v.clone();
        }
    }
    if let Some(tv) = tools {
        setup_obj["tools"] = tv.clone();
    }
    json!({ "setup": setup_obj })
}

fn live_mention_frame(text: &str) -> Option<(Vec<String>, String)> {
    let v: Value = serde_json::from_str(text).ok()?;
    if v.get("type").and_then(|t| t.as_str()) != Some("mention") {
        return None;
    }
    let ids = v
        .get("mention_ids")
        .and_then(|a| a.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.trim().to_string()))
                .filter(|s| !s.is_empty())
                .collect()
        })
        .unwrap_or_default();
    let label = v.get("label").and_then(|s| s.as_str()).unwrap_or("").trim().to_string();
    Some((ids, label))
}

fn live_turn_flags(v: &Value, generation_open: &mut bool) {
    let Some(sc) = v.get("serverContent") else {
        return;
    };
    if sc.get("turnComplete").and_then(|b| b.as_bool()).unwrap_or(false)
        || sc.get("generationComplete").and_then(|b| b.as_bool()).unwrap_or(false)
    {
        *generation_open = false;
        return;
    }
    let spoke = sc.pointer("/outputTranscription/text").and_then(|s| s.as_str()).is_some()
        || sc.pointer("/modelTurn").is_some();
    if spoke {
        *generation_open = true;
    }
}

async fn live_seed_after_setup(
    g_tx: &mut futures_util::stream::SplitSink<
        tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>,
        GMsg,
    >,
    client: &mut WebSocket,
    resume: &crate::LiveResume,
    opened_with_handle: bool,
    history_rows: &[(String, String)],
    label: &str,
    mention_ids: &[String],
    seeded: &mut bool,
    announce: bool,
) {
    if *seeded {
        return;
    }
    *seeded = true;
    if opened_with_handle && !label.is_empty() {
        let _ = g_tx.send(GMsg::Text(crate::live_focus_pin(label).to_string().into())).await;
    } else if resume.handle.is_none() {
        for msg in crate::live_text_seed(history_rows) {
            if g_tx.send(GMsg::Text(msg.to_string().into())).await.is_err() {
                break;
            }
        }
    }
    if announce {
        let _ = client
            .send(Message::Text(
                json!({"live":"mention","mention_ids": mention_ids, "label": label, "switching": false})
                    .to_string()
                    .into(),
            ))
            .await;
    }
}

async fn live_process_server_content(
    v: &Value,
    pool: &PgPool,
    client: &mut WebSocket,
    chat_id_opt: Option<i64>,
    owner_iid: i64,
    req_id: &str,
    turn_user_text: &mut String,
    turn_assistant_text: &mut String,
    turn_tool_blocks: &mut Vec<Value>,
) {
    let Some(sc) = v.get("serverContent") else {
        return;
    };

    if let Some(in_t) = sc.pointer("/inputTranscription/text").and_then(|s| s.as_str()) {
        turn_user_text.push_str(in_t);
    }
    if let Some(out_t) = sc.pointer("/outputTranscription/text").and_then(|s| s.as_str()) {
        turn_assistant_text.push_str(out_t);
    }
    if sc.get("interrupted").and_then(|b| b.as_bool()).unwrap_or(false) {
        turn_assistant_text.push_str(" [interrupted]");
    }
    if sc.get("turnComplete").and_then(|b| b.as_bool()).unwrap_or(false)
        || sc.get("generationComplete").and_then(|b| b.as_bool()).unwrap_or(false)
    {
        if let Some(cid) = chat_id_opt {
            let u_text = turn_user_text.trim().to_string();
            let a_text = turn_assistant_text.trim().to_string();
            if !u_text.is_empty() || !a_text.is_empty() {
                let u_id = c35_store::snowflake_id();
                let a_id = c35_store::snowflake_id();
                if !u_text.is_empty() {
                    let _ = sqlx::query(
                        r#"
                        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
                        VALUES ($1, $2, $3, $4, $3, 'user', 'prompt', $5, '[]', NOW(), NOW())
                        "#,
                    )
                    .bind(u_id)
                    .bind(cid)
                    .bind(owner_iid)
                    .bind(req_id)
                    .bind(&u_text)
                    .execute(pool)
                    .await;
                }
                if !a_text.is_empty() || !turn_tool_blocks.is_empty() {
                    let blocks_val = json!(turn_tool_blocks);
                    let _ = sqlx::query(
                        r#"
                        INSERT INTO ai.chat_msg (
                            id, chat_id, owner_iid, req_id, sender_iid, role, source,
                            content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
                            created_ts, updated_ts
                        )
                        VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', $5, '', $6::jsonb, 0, 0, 0, 0, 'done', '', NOW(), NOW())
                        "#,
                    )
                    .bind(a_id)
                    .bind(cid)
                    .bind(owner_iid)
                    .bind(req_id)
                    .bind(&a_text)
                    .bind(blocks_val)
                    .execute(pool)
                    .await;
                }
                let _ = client
                    .send(Message::Text(
                        json!({
                            "liveTurnCommitted": {
                                "chat_id": cid,
                                "user_msg_id": u_id,
                                "user_text": u_text,
                                "assistant_msg_id": a_id,
                                "assistant_text": a_text,
                            }
                        })
                        .to_string()
                        .into(),
                    ))
                    .await;
            }
        }
        turn_user_text.clear();
        turn_assistant_text.clear();
        turn_tool_blocks.clear();
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

pub fn parse_gemini_audio(v: &Value) -> Option<(Vec<u8>, u32)> {
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

#[allow(dead_code)]
pub fn pcm16_has_speech(pcm: &[u8], threshold: i16) -> bool {
    for chunk in pcm.chunks_exact(2) {
        let sample = i16::from_le_bytes([chunk[0], chunk[1]]);
        if sample.saturating_abs() >= threshold {
            return true;
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    #[test]
    fn test_gemini_live_tool_decls_format() {
        let tools = c35_mod_chat::tools::cluster_tools();
        assert!(!tools.is_empty(), "cluster_tools must have registered tools");

        let decls_val = c35_mod_chat::tools::tool_decls(&tools);
        let arr = decls_val.as_array().expect("tools must be array");
        assert_eq!(arr.len(), 1);
        let fns = arr[0].get("functionDeclarations").and_then(|f| f.as_array()).expect("must have functionDeclarations");
        assert!(!fns.is_empty());

        // Ensure dots are converted to underscores for Gemini Live API
        let names: Vec<&str> = fns.iter().filter_map(|f| f.get("name").and_then(|n| n.as_str())).collect();
        assert!(names.contains(&"web_search"), "must contain web_search");
        assert!(names.contains(&"device_screenshot"), "must contain device_screenshot");
        assert!(names.contains(&"shell_run"), "must contain shell_run");
    }

    #[test]
    fn test_gemini_live_tool_call_payload_and_response() {
        let incoming_tool_call = json!({
            "toolCall": {
                "functionCalls": [
                    {
                        "id": "call_abc123",
                        "name": "web_search",
                        "args": { "query": "weather today" }
                    }
                ]
            }
        });

        let tool_call = incoming_tool_call
            .get("toolCall")
            .or_else(|| incoming_tool_call.pointer("/serverContent/toolCall"))
            .expect("must find toolCall");
        let function_calls = tool_call
            .get("functionCalls")
            .and_then(|c| c.as_array())
            .expect("must have functionCalls");
        assert_eq!(function_calls.len(), 1);

        let fc = &function_calls[0];
        let id = fc["id"].as_str().unwrap();
        let name = fc["name"].as_str().unwrap();
        assert_eq!(id, "call_abc123");
        assert_eq!(name, "web_search");

        // Simulate tool response construction matching Gemini Live protocol
        let simulated_output = json!({ "ok": true, "result": "Sunny 28C" });
        let resp_msg = json!({
            "toolResponse": {
                "functionResponses": [
                    {
                        "id": id,
                        "name": name,
                        "response": {
                            "output": simulated_output
                        }
                    }
                ]
            }
        });

        assert_eq!(resp_msg["toolResponse"]["functionResponses"][0]["id"], "call_abc123");
        assert_eq!(resp_msg["toolResponse"]["functionResponses"][0]["name"], "web_search");
        assert_eq!(
            resp_msg["toolResponse"]["functionResponses"][0]["response"]["output"]["ok"],
            true
        );
    }

    #[test]
    fn test_gemini_live_device_instruction_and_mention_resolution() {
        let device_iids = vec![987654321i64];
        let mention_ctx = c35_mod_chat::MentionContext {
            sites: vec![],
            devices: device_iids.clone(),
            bots: vec![],
            default_site_iid: None,
        };

        // When a single device is paired, device_iid resolves automatically
        let resolved = c35_mod_chat::device_iid_resolve(&mention_ctx, &[], 0);
        assert_eq!(resolved.unwrap(), 987654321i64);
    }
}
