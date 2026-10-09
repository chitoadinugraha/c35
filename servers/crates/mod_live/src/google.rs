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
    match ticket.offer.provider.as_str() {
        "google" => live_google_proxy_run(pool, nats, ticket, client).await,
        "openai" => crate::openai::live_openai_run(pool, nats, ticket, client).await,
        "xai" => crate::grok::live_grok_run(pool, nats, ticket, client).await,
        other => {
            tracing::warn!(provider = other, "unsupported live provider");
            let _ = client
                .send(Message::Text(
                    json!({"liveError":"Live provider not supported yet"}).to_string().into(),
                ))
                .await;
            let _ = live_billing_abort(&pool, &ticket.req_id).await;
        }
    }
}

pub async fn live_google_proxy_run(
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
    if !active_mention_ids.is_empty() {
        let dev_name = device_rows
            .iter()
            .find(|(id, ..)| active_mention_ids.contains(&id.to_string()))
            .map(|(_, name, ..)| name.clone());
        if let Some(name) = dev_name {
            mention_label = name;
        } else if let Some(first) = active_mention_ids.first() {
            mention_label = first.clone();
        }
    }
    let mut mention_ctx = live_mention_context(&pool, owner_iid, &active_mention_ids, &device_iids).await;
    let site_inst_block = c35_mod_chat::mention_context_sites_block(&mention_ctx);

    // User prompt context (timezone, location, locale)
    let user_ctx = c35_mod_chat::prompt::user_context::user_prompt_context_get(&pool, owner_iid).await;
    let tz = c35_mod_chat::prompt::time::time_timezone_resolve(&user_ctx.tz, &user_ctx.locale, "");
    let time_block = c35_mod_chat::prompt::time::time_prompt_block(&tz);

    let chat_id_opt = ticket.chat_id;
    let history_rows = live_recent_msgs(&pool, chat_id_opt).await;
    let has_mention = !active_mention_ids.is_empty();
    let full_system = live_voice_system(
        &live_inst_text(&pool, &offer.inst_id).await,
        &time_block,
        &user_ctx.location_city,
        &device_inst_block,
        &site_inst_block,
        &mention_label,
    );

    let staff_view = c35_mod_admin::staff_view_load(&pool, owner_iid).await;
    let caps = c35_mod_chat::site_capability_view_for_mention(&pool, &mention_ctx).await;
    let all_tools = c35_mod_chat::tools::cluster_tools();
    let mut eligible_tools = crate::live_tool_select(&all_tools, &offer.tool_topics, &mention_ctx, &staff_view, &caps, has_mention);
    tracing::info!(decls = eligible_tools.len(), offer = %offer.id, "live: tool decls");

    let tools_val = if !eligible_tools.is_empty() {
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
    c35_mod_llm::gemini_request_reject_provider_grounding(&setup_obj)
        .expect("Live setup must not enable provider web grounding; use cluster web.search");
    let setup = json!({ "setup": setup_obj });
    if g_tx.send(GMsg::Text(setup.to_string().into())).await.is_err() {
        let _ = live_billing_abort(&pool, &req_id).await;
        return;
    }

    let mut video_tracker = crate::billing::VideoActivityTracker::new();
    let mut quota_interval = tokio::time::interval(std::time::Duration::from_secs(30));
    quota_interval.tick().await;

    let mut ready = false;
    let mut turn_user_text = String::new();
    let mut turn_assistant_text = String::new();
    let mut turn_tool_blocks: Vec<Value> = Vec::new();
    let mut swap_job: Option<(Vec<String>, String)> = None;
    let mut pending_mention: Option<(Vec<String>, String)> = None;
    let mut handover_task: Option<tokio::task::JoinHandle<Result<HandoverSuccess, String>>> = None;
    let mut off_topic_turns: u32 = 0;
    let mut generation_open = false;
    let mut last_swap: Option<Instant> = None;
    let mut seeded = false;
    let opened_with_handle = false;
    let announce_mention = false;
    loop {
        if swap_job.is_none() && handover_task.is_none() {
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

            let pool_c = pool.clone();
            let dev_iids_c = device_iids.clone();
            let offer_c = offer.clone();
            let time_block_c = time_block.clone();
            let city_c = user_ctx.location_city.clone();
            let device_block_c = device_inst_block.clone();
            let all_tools_c = all_tools.clone();
            let staff_c = staff_view.clone();
            let model_c = model.clone();
            let voice_c = voice_name.clone();
            let url_c = url.clone();
            let resume_handle_c = resume.handle.clone();

            handover_task = Some(tokio::spawn(async move {
                perform_handover(
                    pool_c,
                    owner_iid,
                    ids,
                    label,
                    dev_iids_c,
                    offer_c,
                    time_block_c,
                    city_c,
                    device_block_c,
                    all_tools_c,
                    staff_c,
                    model_c,
                    voice_c,
                    url_c,
                    resume_handle_c,
                )
                .await
            }));
        }
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
            handover_res = async {
                if let Some(task) = handover_task.as_mut() {
                    task.await
                } else {
                    std::future::pending().await
                }
            } => {
                handover_task = None;
                match handover_res {
                    Ok(Ok(success)) => {
                        let mut new_tx = success.tx;
                        let new_rx = success.rx;
                        let new_ids = success.ids;
                        let new_label = success.label;
                        let new_mention_ctx = success.mention_ctx;
                        let new_eligible_tools = success.eligible_tools;
                        let new_opened_with_handle = success.opened_with_handle;

                        // Once the new connection receives setupComplete, seed it
                        let mut new_seeded = false;
                        live_seed_after_setup(
                            &mut new_tx,
                            &mut client,
                            &resume,
                            new_opened_with_handle,
                            &history_rows,
                            &new_label,
                            &new_ids,
                            &mut new_seeded,
                            true,
                        )
                        .await;

                        // Send GMsg::Close(None) to old socket
                        let _ = g_tx.send(GMsg::Close(None)).await;

                        // Atomically swap g_tx and g_rx
                        g_tx = new_tx;
                        g_rx = new_rx;

                        active_mention_ids = new_ids;
                        mention_label = new_label;
                        mention_ctx = new_mention_ctx;
                        eligible_tools = new_eligible_tools;
                        last_swap = Some(Instant::now());
                        off_topic_turns = 0;
                        generation_open = false;
                        ready = true;
                        tracing::info!(ids = ?active_mention_ids, label = %mention_label, "live: make-before-break hot swap completed");
                    }
                    Ok(Err(e)) => {
                        warn!(?e, "live: handover task failed, keeping existing connection");
                        let _ = client
                            .send(Message::Text(
                                json!({"live":"mention","mention_ids": active_mention_ids, "label": mention_label, "switching": false})
                                    .to_string()
                                    .into(),
                            ))
                            .await;
                    }
                    Err(join_err) => {
                        warn!(?join_err, "live: handover join failed");
                    }
                }
            }
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
                        if let Some(video_chunk) = live_video_frame(trimmed) {
                            video_tracker.on_frame(Instant::now());
                            if ready {
                                let _ = g_tx.send(GMsg::Text(video_chunk.to_string().into())).await;
                            }
                            continue;
                        }
                        if let Some(attach) = crate::media::parse_media_attach(trimmed) {
                            if attach.mime_type.starts_with("image/") || attach.mime_type.starts_with("video/") {
                                video_tracker.on_frame(Instant::now());
                            }
                            if ready {
                                if attach.mime_type.starts_with("image/") {
                                    let chunk = json!({
                                        "realtimeInput": {
                                            "mediaChunks": [{
                                                "mimeType": attach.mime_type,
                                                "data": attach.data,
                                            }]
                                        }
                                    });
                                    let _ = g_tx.send(GMsg::Text(chunk.to_string().into())).await;
                                } else {
                                    let text = crate::media::extract_attachment_text(&attach.name, &attach.data);
                                    let chunk = json!({
                                        "clientContent": {
                                            "turns": [{
                                                "role": "user",
                                                "parts": [{ "text": text }]
                                            }],
                                            "turnComplete": true
                                        }
                                    });
                                    let _ = g_tx.send(GMsg::Text(chunk.to_string().into())).await;
                                }
                            }
                            continue;
                        }
                        if let Some((ids, label)) = live_mention_frame(trimmed) {
                            if ids != active_mention_ids {
                                if handover_task.is_none()
                                    && crate::live_swap_should_run(Instant::now(), last_swap, false, generation_open)
                                {
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
                            live_seed_after_setup(
                                &mut g_tx,
                                &mut client,
                                &resume,
                                opened_with_handle,
                                &history_rows,
                                &mention_label,
                                &active_mention_ids,
                                &mut seeded,
                                announce_mention,
                            )
                            .await;
                        }
                        if let Ok(v) = serde_json::from_str::<Value>(&t) {
                            if let Some(err) = v.pointer("/error/message").and_then(|x| x.as_str()) {
                                warn!(%err, "live: gemini returned error message");
                                let _ = client
                                    .send(Message::Text(
                                        json!({"liveError": err}).to_string().into(),
                                    ))
                                    .await;
                                break;
                            }
                            resume.note_server_msg(&v);
                            live_turn_flags(&v, &mut generation_open);
                            if !generation_open && handover_task.is_none() {
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

                        if let Ok(v) = serde_json::from_str::<Value>(&t) {
                            if live_handle_tool_call(
                                &v,
                                &pool,
                                &nats,
                                owner_iid,
                                &sid,
                                &req_id,
                                &mention_ctx,
                                &user_ctx,
                                &http_client,
                                &mut g_tx,
                                &mut client,
                                &mut turn_tool_blocks,
                                &mut swap_job,
                                &mut off_topic_turns,
                                chat_id_opt.unwrap_or(0),
                                turn_user_text.trim(),
                            )
                            .await
                            .is_err()
                            {
                                break;
                            }

                            live_process_server_content(
                                &v,
                                &pool,
                                &nats,
                                &mut client,
                                chat_id_opt,
                                owner_iid,
                                &req_id,
                                &mut turn_user_text,
                                &mut turn_assistant_text,
                                &mut turn_tool_blocks,
                                &active_mention_ids,
                                &eligible_tools,
                                &mut off_topic_turns,
                                &mut swap_job,
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
                                    live_seed_after_setup(
                                        &mut g_tx,
                                        &mut client,
                                        &resume,
                                        opened_with_handle,
                                        &history_rows,
                                        &mention_label,
                                        &active_mention_ids,
                                        &mut seeded,
                                        announce_mention,
                                    )
                                    .await;
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

                        if let Ok(v) = serde_json::from_slice::<Value>(&b) {
                            resume.note_server_msg(&v);
                            live_turn_flags(&v, &mut generation_open);
                            if live_handle_tool_call(
                                &v,
                                &pool,
                                &nats,
                                owner_iid,
                                &sid,
                                &req_id,
                                &mention_ctx,
                                &user_ctx,
                                &http_client,
                                &mut g_tx,
                                &mut client,
                                &mut turn_tool_blocks,
                                &mut swap_job,
                                &mut off_topic_turns,
                                chat_id_opt.unwrap_or(0),
                                turn_user_text.trim(),
                            )
                            .await
                            .is_err()
                            {
                                break;
                            }

                            live_process_server_content(
                                &v,
                                &pool,
                                &nats,
                                &mut client,
                                chat_id_opt,
                                owner_iid,
                                &req_id,
                                &mut turn_user_text,
                                &mut turn_assistant_text,
                                &mut turn_tool_blocks,
                                &active_mention_ids,
                                &eligible_tools,
                                &mut off_topic_turns,
                                &mut swap_job,
                            )
                            .await;
                        }
                    }
                    Some(Ok(GMsg::Close(cf))) => {
                        warn!(?cf, "live: google ws closed");
                        let reason = cf.as_ref().map(|c| c.reason.to_string()).unwrap_or_default();
                        if !reason.is_empty() {
                            let _ = client
                                .send(Message::Text(
                                    json!({"liveError": reason}).to_string().into(),
                                ))
                                .await;
                        }
                        break;
                    }
                    Some(Err(e)) => {
                        warn!(?e, "live: google ws err");
                        let _ = client
                            .send(Message::Text(
                                json!({"liveError": format!("Voice service error: {e}")}).to_string().into(),
                            ))
                            .await;
                        break;
                    }
                    None => break,
                    _ => {}
                }
            }
        }
    }

    if let Some(task) = handover_task.take() {
        task.abort();
    }
    let _ = g_tx.send(GMsg::Close(None)).await;
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

pub fn live_video_frame(text: &str) -> Option<Value> {
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
    Some(json!({
        "realtimeInput": {
            "video": {
                "mimeType": mime,
                "data": data,
            }
        }
    }))
}

pub fn is_mention_tool_called(name: &str, eligible_tools: &[c35_mod_chat::ToolDef]) -> bool {
    let norm = name.replace('.', "_");
    if norm == "topic_reset" || norm == "call_end" {
        return false;
    }
    if norm.starts_with("device_")
        || norm.starts_with("shell_")
        || norm.starts_with("site_")
        || norm.starts_with("browser_")
        || norm.starts_with("bot_")
        || norm.starts_with("computer_use_")
    {
        return true;
    }
    for t in eligible_tools {
        let t_norm = t.name.replace('.', "_");
        if t_norm == norm {
            if !t.requires_kinds.is_empty() {
                return true;
            }
            if t.topics.iter().any(|top| top != "general") {
                return true;
            }
        }
    }
    false
}

struct HandoverSuccess {
    tx: futures_util::stream::SplitSink<
        tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>,
        GMsg,
    >,
    rx: futures_util::stream::SplitStream<
        tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>,
    >,
    ids: Vec<String>,
    label: String,
    mention_ctx: c35_mod_chat::MentionContext,
    eligible_tools: Vec<c35_mod_chat::ToolDef>,
    opened_with_handle: bool,
}

async fn perform_handover(
    pool: PgPool,
    owner_iid: i64,
    ids: Vec<String>,
    label: String,
    device_iids: Vec<i64>,
    offer: crate::catalog::LiveOfferRow,
    time_block: String,
    city: String,
    device_inst_block: String,
    all_tools: Vec<c35_mod_chat::ToolDef>,
    staff_view: c35_mod_admin::StaffView,
    model: String,
    voice_name: String,
    url: String,
    resume_handle: Option<String>,
) -> Result<HandoverSuccess, String> {
    let mention_ctx = live_mention_context(&pool, owner_iid, &ids, &device_iids).await;
    let caps = c35_mod_chat::site_capability_view_for_mention(&pool, &mention_ctx).await;
    let site_inst_block = c35_mod_chat::mention_context_sites_block(&mention_ctx);
    let full_system = live_voice_system(
        &live_inst_text(&pool, &offer.inst_id).await,
        &time_block,
        &city,
        &device_inst_block,
        &site_inst_block,
        &label,
    );
    let has_mention = !ids.is_empty();
    let eligible_tools = crate::live_tool_select(&all_tools, &offer.tool_topics, &mention_ctx, &staff_view, &caps, has_mention);
    let tools_val = if !eligible_tools.is_empty() {
        Some(c35_mod_chat::tools::tool_decls(&eligible_tools))
    } else {
        None
    };

    let mut resume = crate::LiveResume::default();
    resume.handle = resume_handle.clone();
    let mut opened_with_handle = resume.handle.is_some();
    let mut setup = live_setup_message(&model, &voice_name, &full_system, &resume, &tools_val);

    let ws = match connect_async(&url).await {
        Ok((s, _)) => s,
        Err(e) => {
            warn!(?e, "live handover: resume connect failed");
            if opened_with_handle {
                resume.handle = None;
                opened_with_handle = false;
                setup = live_setup_message(&model, &voice_name, &full_system, &resume, &tools_val);
                match connect_async(&url).await {
                    Ok((s, _)) => s,
                    Err(e2) => return Err(format!("live handover fresh connect failed: {e2:?}")),
                }
            } else {
                return Err(format!("live handover connect failed: {e:?}"));
            }
        }
    };

    let (mut tx, mut rx) = ws.split();
    if let Err(e) = tx.send(GMsg::Text(setup.to_string().into())).await {
        return Err(format!("live handover send setup failed: {e:?}"));
    }

    let wait_setup = async {
        while let Some(msg) = rx.next().await {
            match msg {
                Ok(GMsg::Text(t)) if t.contains("setupComplete") => return true,
                Ok(GMsg::Binary(b)) => {
                    if let Ok(s) = String::from_utf8(b.to_vec()) {
                        if s.contains("setupComplete") {
                            return true;
                        }
                    }
                }
                Ok(GMsg::Close(_)) | Err(_) => return false,
                _ => {}
            }
        }
        false
    };

    let setup_done = match tokio::time::timeout(std::time::Duration::from_secs(10), wait_setup).await {
        Ok(ok) => ok,
        Err(_) => false,
    };

    if !setup_done {
        if opened_with_handle {
            resume.handle = None;
            let setup_fresh = live_setup_message(&model, &voice_name, &full_system, &resume, &tools_val);
            if let Ok((fresh_ws, _)) = connect_async(&url).await {
                let (mut fresh_tx, mut fresh_rx) = fresh_ws.split();
                if fresh_tx.send(GMsg::Text(setup_fresh.to_string().into())).await.is_ok() {
                    let wait_fresh = async {
                        while let Some(msg) = fresh_rx.next().await {
                            match msg {
                                Ok(GMsg::Text(t)) if t.contains("setupComplete") => return true,
                                Ok(GMsg::Binary(b)) => {
                                    if let Ok(s) = String::from_utf8(b.to_vec()) {
                                        if s.contains("setupComplete") {
                                            return true;
                                        }
                                    }
                                }
                                Ok(GMsg::Close(_)) | Err(_) => return false,
                                _ => {}
                            }
                        }
                        false
                    };
                    if let Ok(true) = tokio::time::timeout(std::time::Duration::from_secs(10), wait_fresh).await {
                        return Ok(HandoverSuccess {
                            tx: fresh_tx,
                            rx: fresh_rx,
                            ids,
                            label,
                            mention_ctx,
                            eligible_tools,
                            opened_with_handle: false,
                        });
                    }
                }
            }
        }
        return Err("live handover setupComplete timeout or failure".into());
    }

    Ok(HandoverSuccess {
        tx,
        rx,
        ids,
        label,
        mention_ctx,
        eligible_tools,
        opened_with_handle,
    })
}

async fn live_handle_tool_call(
    v: &Value,
    pool: &PgPool,
    nats: &Option<Client>,
    owner_iid: i64,
    sid: &str,
    req_id: &str,
    mention_ctx: &c35_mod_chat::MentionContext,
    user_ctx: &c35_mod_chat::prompt::user_context::UserPromptContext,
    http_client: &reqwest::Client,
    g_tx: &mut futures_util::stream::SplitSink<
        tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>,
        GMsg,
    >,
    client: &mut WebSocket,
    turn_tool_blocks: &mut Vec<Value>,
    swap_job: &mut Option<(Vec<String>, String)>,
    off_topic_turns: &mut u32,
    chat_id: i64,
    user_text: &str,
) -> Result<(), ()> {
    let Some(tool_call) = v.get("toolCall").or_else(|| v.pointer("/serverContent/toolCall")) else {
        return Ok(());
    };
    let Some(function_calls) = tool_call.get("functionCalls").and_then(|c| c.as_array()) else {
        return Ok(());
    };

    let dispatcher = c35_mod_chat::tools::default_dispatcher();
    let mut function_responses = Vec::with_capacity(function_calls.len());
    let mut end_call_after_response = false;

    for fc in function_calls {
        let call_id = fc.get("id").and_then(|i| i.as_str()).unwrap_or("").to_string();
        let call_name = fc.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
        let call_args = fc.get("args").cloned().unwrap_or(json!({}));
        let norm_name = call_name.replace('.', "_");

        tracing::info!(tool = %call_name, call_id = %call_id, req_id = %sid, "live: executing tool call");

        if norm_name == "call_end" {
            let result = json!({
                "status": "ok",
                "message": "Live call ending"
            });
            turn_tool_blocks.push(json!({
                "kind": "tool",
                "collapsed": false,
                "body": {
                    "name": call_name,
                    "args": call_args,
                    "result": result.clone()
                }
            }));
            let mut tr_entry = json!({
                "name": call_name,
                "response": {
                    "output": result
                }
            });
            if !call_id.is_empty() {
                tr_entry.as_object_mut().unwrap().insert("id".to_string(), json!(call_id));
            }
            function_responses.push(tr_entry);
            end_call_after_response = true;
            continue;
        }

        if norm_name == "topic_reset" {
            let result = json!({
                "status": "ok",
                "message": "Returned to general conversation"
            });
            *swap_job = Some((Vec::new(), String::new()));
            *off_topic_turns = 0;
            let _ = client
                .send(Message::Text(
                    json!({"live":"mention","mention_ids":[],"label":"","switching":false})
                        .to_string()
                        .into(),
                ))
                .await;
            turn_tool_blocks.push(json!({
                "kind": "tool",
                "collapsed": false,
                "body": {
                    "name": call_name,
                    "args": call_args,
                    "result": result.clone()
                }
            }));
            let mut tr_entry = json!({
                "name": call_name,
                "response": {
                    "output": result
                }
            });
            if !call_id.is_empty() {
                tr_entry.as_object_mut().unwrap().insert("id".to_string(), json!(call_id));
            }
            function_responses.push(tr_entry);
            continue;
        }

        let _ = client
            .send(Message::Text(
                json!({"live":"tool_start", "name": call_name, "id": call_id})
                    .to_string()
                    .into(),
            ))
            .await;

        let tool_ctx = c35_mod_chat::tools::ToolContext::new(
            pool.clone(),
            nats.clone(),
            owner_iid,
            chat_id,
            mention_ctx.default_site_iid,
            mention_ctx.clone(),
            vec![],
            user_text,
            &user_ctx.locale,
            &user_ctx.location_city,
            &user_ctx.location_region,
            &user_ctx.location_country,
            "",
            req_id,
            http_client.clone(),
        )
        .with_mcp_agent(true)
        .with_tool_call_id(&call_id);

        let (mut result, cost_usd) = dispatcher.execute(&call_name, call_args.clone(), &tool_ctx).await;
        tracing::info!(tool = %call_name, cost_usd, "live: tool executed");

        let _ = client
            .send(Message::Text(
                json!({"live":"tool_end", "name": call_name, "id": call_id})
                    .to_string()
                    .into(),
            ))
            .await;

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

        let mut clean_output = result.clone();
        if let Some(obj) = clean_output.as_object_mut() {
            obj.remove("block");
        }
        let mut fr_entry = json!({
            "name": call_name,
            "response": {
                "output": clean_output
            }
        });
        if !call_id.is_empty() {
            fr_entry.as_object_mut().unwrap().insert("id".to_string(), json!(call_id));
        }
        function_responses.push(fr_entry);
    }

    let resp_msg = json!({
        "toolResponse": {
            "functionResponses": function_responses
        }
    });
    if g_tx.send(GMsg::Text(resp_msg.to_string().into())).await.is_err() {
        warn!("live: failed to send toolResponse to Gemini Live");
        return Err(());
    }
    if end_call_after_response {
        let _ = client
            .send(Message::Text(json!({"live":"hangup"}).to_string().into()))
            .await;
        tracing::info!(req_id = %sid, "live: call.end — ending session");
        return Err(());
    }
    Ok(())
}

pub(crate) fn live_voice_system(
    inst: &str,
    time_block: &str,
    city: &str,
    device_block: &str,
    site_block: &str,
    mention_label: &str,
) -> String {
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
    let trimmed_label = mention_label.trim();
    if !trimmed_label.is_empty() {
        full.push_str(&format!(
            "\n\n[TOPIC FOCUS]\nYou are currently focused on {trimmed_label}. If the conversation naturally transitions away and the user is no longer discussing {trimmed_label} for multiple turns, autonomously call topic_reset."
        ));
    }
    full.push_str("\n\n[VOICE INTERACTION & TOOLS]\nYou are in a live voice call with the user. You have tools available to search the web, inspect and control paired remote devices, manage notes, etc. When the user asks you a question that requires real-time information, actions on their computer, or checking anything, call the appropriate tool. Once you receive the tool response, summarize and answer the user clearly and concisely in natural conversational speech. Do not read raw JSON aloud.\nIf the user wants to end the call, hang up, or says goodbye to disconnect, call call.end after a brief farewell (one short sentence). Do not keep chatting after call.end.");
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
    c35_mod_llm::gemini_request_reject_provider_grounding(&setup_obj)
        .expect("Live setup must not enable provider web grounding; use cluster web.search");
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
    nats: &Option<Client>,
    client: &mut WebSocket,
    chat_id_opt: Option<i64>,
    owner_iid: i64,
    req_id: &str,
    turn_user_text: &mut String,
    turn_assistant_text: &mut String,
    turn_tool_blocks: &mut Vec<Value>,
    active_mention_ids: &[String],
    eligible_tools: &[c35_mod_chat::ToolDef],
    off_topic_turns: &mut u32,
    swap_job: &mut Option<(Vec<String>, String)>,
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
        let u_text = turn_user_text.trim().to_string();
        let a_text = turn_assistant_text.trim().to_string();
        let had_content = !u_text.is_empty() || !a_text.is_empty() || !turn_tool_blocks.is_empty();

        if let Some(cid) = chat_id_opt {
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

                let preview = if !a_text.is_empty() { &a_text } else { &u_text };
                let _ = c35_mod_chat::chat_touch(pool, nats.as_ref(), cid, owner_iid, preview, "done").await;
            }
        }

        // Autonomous Topic Drift Detection: 5 consecutive turns without mention tools triggers reset
        if had_content && !active_mention_ids.is_empty() {
            let mention_tool_called = turn_tool_blocks.iter().any(|b| {
                let name = b.pointer("/body/name").and_then(|n| n.as_str()).unwrap_or("");
                is_mention_tool_called(name, eligible_tools)
            });
            if mention_tool_called {
                *off_topic_turns = 0;
            } else {
                *off_topic_turns += 1;
                tracing::info!(off_topic_turns = *off_topic_turns, "live: off-topic turn count incremented");
                if *off_topic_turns >= 5 {
                    tracing::info!("live: drift threshold reached (5 consecutive turns), resetting to general topic");
                    *swap_job = Some((Vec::new(), String::new()));
                    let _ = client
                        .send(Message::Text(
                            json!({"live":"mention","mention_ids":[],"label":"","switching":false})
                                .to_string()
                                .into(),
                        ))
                        .await;
                    *off_topic_turns = 0;
                }
            }
        }

        turn_user_text.clear();
        turn_assistant_text.clear();
        turn_tool_blocks.clear();
    }
}

pub(crate) async fn live_inst_text(pool: &PgPool, inst_id: &str) -> String {
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

    #[test]
    fn test_live_video_frame_relay() {
        use super::live_video_frame;

        let text_jpeg = r#"{"type":"video","data":"/9j/4AAQSkZJRg==","mime_type":"image/jpeg"}"#;
        let v = live_video_frame(text_jpeg).expect("must parse video frame");
        assert_eq!(v["realtimeInput"]["video"]["mimeType"], "image/jpeg");
        assert_eq!(v["realtimeInput"]["video"]["data"], "/9j/4AAQSkZJRg==");

        let text_frame_type = r#"{"type":"video_frame","data":"abc123xyz","mimeType":"image/png"}"#;
        let v2 = live_video_frame(text_frame_type).expect("must parse video_frame type");
        assert_eq!(v2["realtimeInput"]["video"]["mimeType"], "image/png");
        assert_eq!(v2["realtimeInput"]["video"]["data"], "abc123xyz");

        let text_hangup = r#"{"type":"hangup"}"#;
        assert!(live_video_frame(text_hangup).is_none());

        let text_empty = r#"{"type":"video","data":""}"#;
        assert!(live_video_frame(text_empty).is_none());
    }

    #[test]
    fn test_is_mention_tool_called() {
        use super::is_mention_tool_called;

        let tools = vec![
            c35_mod_chat::ToolDef::new("web.search".into(), "web search".into(), json!({})),
            c35_mod_chat::ToolDef::new("device.screenshot".into(), "screenshot".into(), json!({})),
            c35_mod_chat::ToolDef::new("site.create".into(), "site create".into(), json!({})),
        ];

        assert!(is_mention_tool_called("device_screenshot", &tools));
        assert!(is_mention_tool_called("shell_run", &tools));
        assert!(is_mention_tool_called("site_create", &tools));
        assert!(is_mention_tool_called("browser_page_act", &tools));
        assert!(!is_mention_tool_called("web_search", &tools));
        assert!(!is_mention_tool_called("memory_save", &tools));
        assert!(!is_mention_tool_called("topic_reset", &tools));
        assert!(!is_mention_tool_called("call.end", &tools));
    }

    #[test]
    fn test_live_voice_system_prompt_steering() {
        use super::live_voice_system;

        let sys_no_mention = live_voice_system("Inst", "Time", "City", "", "", "");
        assert!(!sys_no_mention.contains("[TOPIC FOCUS]"));
        assert!(!sys_no_mention.contains("topic_reset"));
        assert!(sys_no_mention.contains("call.end"));

        let sys_with_mention = live_voice_system("Inst", "Time", "City", "", "", "Desktop PC");
        assert!(sys_with_mention.contains("[TOPIC FOCUS]"));
        assert!(sys_with_mention.contains("You are currently focused on Desktop PC."));
        assert!(sys_with_mention.contains("autonomously call topic_reset."));
    }
}
