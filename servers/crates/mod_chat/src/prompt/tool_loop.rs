use std::sync::Arc;
use std::time::Instant;

use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use c35_store::snowflake_id;
use futures_util::future::join_all;
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use super::llm_route::{bill_model_slug, llm_stream_chain};
use super::thought::{thought_push, thinking_level};
use super::web_grounding::{pick_visit_url, reply_looks_like_web_placeholder, search_payload};
use super::{ChatReq, ChatRes};
use crate::prompt::hooks::PromptHopCheckpoint;
use crate::prompt_run::{
    chat_tool_rounds_max, checkpoint_record_tool, checkpoint_set_fatal, checkpoint_tool_should_stop,
};
use crate::chat_title_set;
use crate::tools::{cluster_tool_def, cluster_tool_exec, http_client, tool_decls, TurnCtx};
use crate::turn_tracer::TurnTracer;

pub const CHAT_TOOL_ROUNDS_MAX: u8 = 24;
pub const CHAT_WRAPUP_HINT: &str =
    "Stop using tools. Answer the user now with what you already found. Do not call more tools.";

fn cluster_system(req: &ChatReq) -> String { req.system.trim().to_string() }

pub fn chat_tool_rounds_done(round: u8, run_kind: &str) -> bool {
    round >= chat_tool_rounds_max(run_kind)
}

pub fn tool_call_dup(prev: &Option<(String, Value)>, name: &str, args: &Value) -> bool {
    prev.as_ref().map(|(n, a)| n == name && a == args).unwrap_or(false)
}

pub fn tool_calls_dup(prev: &[(String, Value)], current: &[(String, Value)]) -> bool {
    !prev.is_empty() && prev == current
}

fn append_block(blocks_json: &str, block: Value) -> String {
    let mut arr = serde_json::from_str::<Vec<Value>>(blocks_json).unwrap_or_default();
    arr.push(block);
    serde_json::to_string(&arr).unwrap_or_else(|_| "[]".into())
}

/// Prune previous desktop screenshots from conversation context so only the latest
/// observation is retained, avoiding token explosion during multi-step Computer Use.
fn prune_previous_screenshots(contents: &mut [Value]) {
    for msg in contents.iter_mut() {
        if let Some(parts) = msg.get_mut("parts").and_then(|p| p.as_array_mut()) {
            for part in parts.iter_mut() {
                if let Some(inline) = part.get("inlineData") {
                    if inline.get("mimeType").and_then(|m| m.as_str()) == Some("image/jpeg") {
                        *part = json!({
                            "text": "[Previous desktop screenshot omitted for token optimization; state superseded by recent action]"
                        });
                    }
                }
            }
        }
    }
}

pub async fn prompt_cluster_turn(
    req: &ChatReq,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    on_blocks: &mut (dyn FnMut(String) + Send),
    cancel: &CancellationToken,
    tracer: Option<&TurnTracer>,
    mut turn_ctx: Option<&mut TurnCtx<'_>>,
    on_hop: Option<Arc<dyn Fn(PromptHopCheckpoint) + Send + Sync>>,
) -> Result<ChatRes> {
    let run_kind = turn_ctx.as_ref().map(|t| t.run_kind).unwrap_or("main");
    let rounds_max = chat_tool_rounds_max(run_kind);
    let requested_model = req.model.clone();
    let bill_slug = bill_model_slug(&requested_model);
    let thinking = thinking_level(&req.thinking);
    let system = cluster_system(req);
    let mut tools = req.tools.clone();
    let mut tool_json = tool_decls(&tools);
    let client = http_client(std::time::Duration::from_secs(30));
    let mut contents: Vec<Value> = Vec::with_capacity(req.history.len() + 1);
    for h in &req.history {
        let trimmed = h.content.trim();
        if trimmed.is_empty() {
            continue;
        }
        let role = if h.role == "assistant" { "model" } else { "user" };
        contents.push(json!({ "role": role, "parts": [{ "text": trimmed }] }));
    }
    contents.push(json!({ "role": "user", "parts": [{ "text": req.user }] }));
    let mut tokens_in = 0i32;
    let mut tokens_out = 0i32;
    let mut thought = String::new();
    let mut text = String::new();
    let mut blocks_json = String::from("[]");
    let mut tools_cost_usd = 0.0f64;
    let model_used = bill_slug.clone();

    if tools.is_empty() {
        let hop_started = Instant::now();
        let (out, _provider_model, _) = llm_stream_chain(
            &requested_model,
            &contents,
            &json!([]),
            &thinking,
            &system,
            "AUTO",
            on_delta,
            cancel,
        )
        .await?;
        let hop_ms = hop_started.elapsed().as_millis() as i64;
        tokens_in += out.in_tok;
        tokens_out += out.out_tok;
        text = out.text.clone();
        thought = out.thought.clone();
        if let Some(tr) = tracer {
            let hop_cost = billing_cost_usd(&bill_slug, out.in_tok, out.out_tok);
            tr.llm_call(1, &bill_slug, out.in_tok, out.out_tok, hop_ms, hop_cost, &out.text).await;
        }
        hop_checkpoint(turn_ctx.as_deref(), &on_hop, 1, 1, tokens_in, tokens_out, tools_cost_usd, &blocks_json, "");
        return Ok(ChatRes { text, thought, blocks_json, tokens_in, tokens_out, model_used, tools_cost_usd: 0.0 });
    }

    let mut prev_calls: Vec<(String, Value)> = Vec::new();
    let mut used_tool = false;
    let mut web_grounded = false;
    if req.force_tool_call && tools.iter().any(|t| t.name == "web.search") {
        let q = search_query_from_user(&req.user);
        if tool_loop_run_web_search(
            &client,
            &q,
            true,
            &mut contents,
            &mut tools,
            &mut tool_json,
            &mut tools_cost_usd,
            &mut thought,
            on_delta,
            turn_ctx.as_deref(),
            tracer,
        )
        .await?
        {
            used_tool = true;
            web_grounded = true;
            prev_calls = vec![("web.search".into(), json!({ "query": q, "limit": 6 }))];
        }
    }
    for round in 0..rounds_max {
        if cancel.is_cancelled() { anyhow::bail!("aborted"); }
        if let Some(ctx) = turn_ctx.as_ref() {
            if crate::prompt_followup::prompt_followup_enabled() {
                match crate::prompt_followup::prompt_followup_drain_steers(
                    ctx.pool,
                    ctx.req_id,
                    ctx.chat_id,
                    ctx.owner_iid,
                )
                .await
                {
                    Ok(steer_texts) if !steer_texts.is_empty() => {
                        crate::prompt_followup::prompt_followup_append_to_contents(&mut contents, &steer_texts);
                    }
                    Err(e) => tracing::warn!("[c35:prompt_followup] drain failed req_id={}: {e:#}", ctx.req_id),
                    _ => {}
                }
            }
        }
        let wrap = chat_tool_rounds_done(round + 1, run_kind);
        let hop = round + 1;
        let hop_started = Instant::now();
        let tool_call_mode = if round == 0 && req.force_tool_call && !web_grounded && !wrap { "ANY" } else { "AUTO" };
        let (out, _provider_model, _) = if wrap {
            contents.push(json!({ "role": "user", "parts": [{ "text": CHAT_WRAPUP_HINT }] }));
            llm_stream_chain(&requested_model, &contents, &json!([]), &thinking, &system, "AUTO", on_delta, cancel).await?
        } else {
            llm_stream_chain(
                &requested_model,
                &contents,
                &tool_json,
                &thinking,
                &system,
                tool_call_mode,
                on_delta,
                cancel,
            )
            .await?
        };
        let hop_ms = hop_started.elapsed().as_millis() as i64;
        tokens_in += out.in_tok;
        tokens_out += out.out_tok;
        if let Some(tr) = tracer {
            let hop_cost = billing_cost_usd(&bill_slug, out.in_tok, out.out_tok);
            tr.llm_call(hop as u8, &bill_slug, out.in_tok, out.out_tok, hop_ms, hop_cost, &out.text).await;
        }
        hop_checkpoint(turn_ctx.as_deref(), &on_hop, hop as i32, hop as i32, tokens_in, tokens_out, tools_cost_usd, &blocks_json, "");
        if !out.thought.is_empty() {
            thought_push(&mut thought, &out.thought);
        }
        if !out.function_calls.is_empty() {
            if wrap || tool_calls_dup(&prev_calls, &out.function_calls) {
                return wrap_up(
                    &requested_model,
                    contents,
                    thought,
                    text,
                    blocks_json,
                    tokens_in,
                    tokens_out,
                    &bill_slug,
                    &thinking,
                    &system,
                    on_delta,
                    cancel,
                    tracer,
                    tools_cost_usd,
                )
                .await;
            }
            for (name, _) in &out.function_calls {
                let label = format!("Using {name}…\n");
                emit_thought(on_delta, &mut thought, &label);
            }

            let executions = join_all(out.function_calls.iter().map(|(name, args)| {
                let client = &client;
                let turn_ctx_ref = turn_ctx.as_deref();
                async move {
                    let tool_started = Instant::now();
                    let (result, tool_cost) = cluster_tool_exec(client, name, args, turn_ctx_ref).await;
                    let tool_ms = tool_started.elapsed().as_millis() as i64;
                    (name.clone(), args.clone(), result, tool_cost, tool_ms)
                }
            }))
            .await;

            if let Some(ctx) = turn_ctx.as_ref() {
                let title = ctx.title_slot.lock().ok().and_then(|g| g.clone());
                if let Some(title) = title {
                    let _ = chat_title_set(ctx.pool, ctx.nats, ctx.owner_iid, ctx.chat_id, &title).await;
                }
            }

            let mut function_parts = Vec::with_capacity(executions.len());
            let mut latest_img_b64 = None;

            for (name, args, result, tool_cost, tool_ms) in executions {
                tools_cost_usd += tool_cost;
                let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
                if let Some(tr) = tracer {
                    tr.tool_result(&name, &snowflake_id().to_string(), &args, &result, ok, tool_ms).await;
                }
                if let Some(block) = result.get("block") {
                    blocks_json = append_block(&blocks_json, block.clone());
                    on_blocks(blocks_json.clone());
                }
                let fail_class = result.get("fail_class").and_then(|v| v.as_str()).unwrap_or("");
                let circuit_stop = if let Some(ctx) = turn_ctx.as_mut() {
                    if let Some(cp) = ctx.checkpoint.as_deref_mut() {
                        checkpoint_record_tool(cp, &name, &result);
                        if let Some((fc, reason)) = checkpoint_tool_should_stop(cp, ctx.run_kind) {
                            checkpoint_set_fatal(cp, fc, reason);
                            Some((fc, reason))
                        } else {
                            None
                        }
                    } else {
                        None
                    }
                } else {
                    None
                };
                if let Some((fc, reason)) = circuit_stop {
                    hop_checkpoint_with_json(
                        &on_hop,
                        hop as i32,
                        hop as i32,
                        tokens_in,
                        tokens_out,
                        tools_cost_usd,
                        &blocks_json,
                        fc,
                        turn_ctx
                            .as_ref()
                            .and_then(|t| t.checkpoint.as_ref())
                            .map(|v| v.to_string())
                            .unwrap_or_else(|| "{}".into()),
                    );
                    anyhow::bail!(reason);
                }
                if fail_class.starts_with("fatal_") {
                    hop_checkpoint(turn_ctx.as_deref(), &on_hop, hop as i32, hop as i32, tokens_in, tokens_out, tools_cost_usd, &blocks_json, fail_class);
                    let err = result
                        .get("error")
                        .and_then(|v| v.as_str())
                        .unwrap_or("device fatal error")
                        .to_string();
                    anyhow::bail!(err);
                }
                let mut llm_result = result.get("llm").cloned().unwrap_or(result.clone());
                let maybe_img = llm_result.as_object_mut().and_then(|obj| {
                    obj.remove("image_base64").and_then(|v| v.as_str().map(|s| s.to_string()))
                });
                if let Some(img_b64) = maybe_img {
                    latest_img_b64 = Some(img_b64);
                }

                function_parts.push(json!({
                    "functionResponse": {
                        "name": name.replace('.', "_"),
                        "response": llm_result
                    }
                }));
            }

            used_tool = true;
            contents.push(out.model_content);
            contents.push(json!({
                "role": "function",
                "parts": function_parts
            }));

            if let Some(img_b64) = latest_img_b64 {
                // Optimize context window: prune older screenshots so only the latest desktop state is in context
                prune_previous_screenshots(&mut contents);
                contents.push(json!({
                    "role": "user",
                    "parts": [
                        { "text": "Visual desktop observation from device:" },
                        {
                            "inlineData": {
                                "mimeType": "image/jpeg",
                                "data": img_b64
                            }
                        }
                    ]
                }));
            }

            if out.function_calls.iter().any(|(n, _)| n == "web.search" || n == "web.visit") {
                ensure_web_visit_tool(&mut tools, &mut tool_json);
            }

            prev_calls = out.function_calls;
            continue;
        }
        if round == 0
            && !used_tool
            && user_wants_consumption_recap(&req.user)
            && tools.iter().any(|t| t.name == "consumption.today")
        {
            let locale = turn_ctx.as_ref().map(|t| t.locale).unwrap_or("id-ID");
            let args = consumption_recap_args_from_user(&req.user, locale);
            emit_thought(on_delta, &mut thought, "Using consumption.today…\n");
            let tool_started = Instant::now();
            let (result, tool_cost) =
                cluster_tool_exec(&client, "consumption.today", &args, turn_ctx.as_deref()).await;
            tools_cost_usd += tool_cost;
            let tool_ms = tool_started.elapsed().as_millis() as i64;
            let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
            if let Some(tr) = tracer {
                tr.tool_result("consumption.today", &snowflake_id().to_string(), &args, &result, ok, tool_ms).await;
            }
            if let Some(block) = result.get("block") {
                blocks_json = append_block(&blocks_json, block.clone());
                on_blocks(blocks_json.clone());
            }
            used_tool = true;
            let day_id = args.get("day_id").and_then(|v| v.as_str()).unwrap_or("today");
            contents.push(json!({
                "role": "model",
                "parts": [{ "functionCall": { "name": "consumption_today", "args": { "day_id": day_id } } }]
            }));
            let llm_result = result.get("llm").cloned().unwrap_or(result.clone());
            contents.push(json!({
                "role": "function",
                "parts": [{ "functionResponse": { "name": "consumption_today", "response": llm_result } }]
            }));
            prev_calls = vec![("consumption.today".into(), args)];
            continue;
        }
        if round == 0
            && !used_tool
            && tools.iter().any(|t| t.name == "web.search")
            && (req.force_tool_call || user_wants_search(&req.user))
        {
            let q = search_query_from_user(&req.user);
            if tool_loop_run_web_search(
                &client,
                &q,
                req.force_tool_call,
                &mut contents,
                &mut tools,
                &mut tool_json,
                &mut tools_cost_usd,
                &mut thought,
                on_delta,
                turn_ctx.as_deref(),
                tracer,
            )
            .await?
            {
                used_tool = true;
                prev_calls = vec![("web.search".into(), json!({ "query": q, "limit": 6 }))];
                continue;
            }
        }
        if !out.text.is_empty() {
            let reject_ungrounded = req.force_tool_call && !web_grounded && !used_tool;
            let reject_placeholder = req.force_tool_call && reply_looks_like_web_placeholder(&out.text);
            if !reject_ungrounded && !reject_placeholder {
                if !out.thought.is_empty() {
                    thought_push(&mut thought, &out.thought);
                }
                text = out.text.clone();
                return Ok(ChatRes { text, thought, blocks_json, tokens_in, tokens_out, model_used, tools_cost_usd });
            }
        }
        break;
    }
    if used_tool || !text.is_empty() {
        return wrap_up(
            &requested_model,
            contents,
            thought,
            text,
            blocks_json,
            tokens_in,
            tokens_out,
            &bill_slug,
            &thinking,
            &system,
            on_delta,
            cancel,
            tracer,
            tools_cost_usd,
        )
        .await;
    }
    anyhow::bail!("cluster tool loop exhausted without text")
}

async fn wrap_up(
    requested_model: &str,
    mut contents: Vec<Value>,
    mut thought: String,
    mut text: String,
    blocks_json: String,
    mut tokens_in: i32,
    mut tokens_out: i32,
    bill_slug: &str,
    thinking: &str,
    system: &str,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    cancel: &CancellationToken,
    tracer: Option<&TurnTracer>,
    tools_cost_usd: f64,
) -> Result<ChatRes> {
    if cancel.is_cancelled() { anyhow::bail!("aborted"); }
    contents.push(json!({ "role": "user", "parts": [{ "text": CHAT_WRAPUP_HINT }] }));
    let hop_started = Instant::now();
    let (out, _provider_model, _) = llm_stream_chain(requested_model, &contents, &json!([]), thinking, system, "AUTO", on_delta, cancel).await?;
    let hop_ms = hop_started.elapsed().as_millis() as i64;
    tokens_in += out.in_tok;
    tokens_out += out.out_tok;
    if !out.text.is_empty() {
        text.push_str(&out.text);
    }
    if !out.thought.is_empty() {
        thought_push(&mut thought, &out.thought);
    }
    if let Some(tr) = tracer {
        let hop_cost = billing_cost_usd(bill_slug, out.in_tok, out.out_tok);
        tr.llm_call(99, bill_slug, out.in_tok, out.out_tok, hop_ms, hop_cost, &out.text).await;
    }
    if text.is_empty() {
        let fallback = "I could not finish that lookup. Try again with a shorter question.";
        emit_text(on_delta, &mut text, fallback);
    }
    Ok(ChatRes { text, thought, blocks_json, tokens_in, tokens_out, model_used: bill_slug.to_string(), tools_cost_usd })
}

fn hop_checkpoint(
    turn_ctx: Option<&TurnCtx<'_>>,
    on_hop: &Option<Arc<dyn Fn(PromptHopCheckpoint) + Send + Sync>>,
    hop: i32,
    turn_count: i32,
    tokens_in: i32,
    tokens_out: i32,
    cost_usd: f64,
    blocks_json: &str,
    fail_class: &str,
) {
    let checkpoint_json = turn_ctx
        .and_then(|t| t.checkpoint.as_ref())
        .map(|v| v.to_string())
        .unwrap_or_else(|| "{}".into());
    hop_checkpoint_with_json(
        on_hop,
        hop,
        turn_count,
        tokens_in,
        tokens_out,
        cost_usd,
        blocks_json,
        fail_class,
        checkpoint_json,
    );
}

fn hop_checkpoint_with_json(
    on_hop: &Option<Arc<dyn Fn(PromptHopCheckpoint) + Send + Sync>>,
    hop: i32,
    turn_count: i32,
    tokens_in: i32,
    tokens_out: i32,
    cost_usd: f64,
    blocks_json: &str,
    fail_class: &str,
    checkpoint_json: String,
) {
    if let Some(f) = on_hop {
        f(PromptHopCheckpoint {
            hop,
            turn_count,
            tokens_in,
            tokens_out,
            cost_usd,
            blocks_json: blocks_json.to_string(),
            fail_class: fail_class.to_string(),
            checkpoint_json,
        });
    }
}

fn emit_thought(on_delta: &mut (dyn FnMut(bool, String) + Send), acc: &mut String, piece: &str) {
    if piece.trim().is_empty() { return; }
    thought_push(acc, piece);
    on_delta(true, if piece.ends_with('\n') { piece.to_string() } else { format!("{piece}\n") });
}

fn emit_text(on_delta: &mut (dyn FnMut(bool, String) + Send), acc: &mut String, piece: &str) {
    if piece.is_empty() { return; }
    acc.push_str(piece);
    on_delta(false, piece.to_string());
}

/// Run web.search (+ web.visit on best URL) and append Gemini function messages to `contents`.
async fn tool_loop_run_web_search(
    client: &reqwest::Client,
    query: &str,
    force_visit: bool,
    contents: &mut Vec<Value>,
    tools: &mut Vec<crate::tools::ToolDef>,
    tool_json: &mut Value,
    tools_cost_usd: &mut f64,
    thought: &mut String,
    on_delta: &mut (dyn FnMut(bool, String) + Send),
    turn_ctx: Option<&TurnCtx<'_>>,
    tracer: Option<&TurnTracer>,
) -> Result<bool> {
    let q = query.trim();
    if q.is_empty() {
        return Ok(false);
    }
    emit_thought(on_delta, thought, "Using web.search…\n");
    let args = json!({ "query": q, "limit": 6 });
    let tool_started = Instant::now();
    let (result, tool_cost) = cluster_tool_exec(client, "web.search", &args, turn_ctx).await;
    *tools_cost_usd += tool_cost;
    let tool_ms = tool_started.elapsed().as_millis() as i64;
    let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
    if let Some(tr) = tracer {
        tr.tool_result("web.search", &snowflake_id().to_string(), &args, &result, ok, tool_ms).await;
    }
    let mut model_parts = vec![json!({ "functionCall": { "name": "web_search", "args": { "query": q } } })];
    let mut function_parts = vec![json!({ "functionResponse": { "name": "web_search", "response": result } })];
    ensure_web_visit_tool(tools, tool_json);
    let search_ok = search_payload(&result).get("ok").and_then(|v| v.as_bool()).unwrap_or(false);
    if force_visit && search_ok && tools.iter().any(|t| t.name == "web.visit") {
        if let Some(url) = pick_visit_url(&result) {
            emit_thought(on_delta, thought, "Using web.visit…\n");
            let visit_args = json!({ "url": url });
            let visit_started = Instant::now();
            let (visit_result, visit_cost) = cluster_tool_exec(client, "web.visit", &visit_args, turn_ctx).await;
            *tools_cost_usd += visit_cost;
            let visit_ms = visit_started.elapsed().as_millis() as i64;
            let visit_ok = visit_result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
            if let Some(tr) = tracer {
                tr.tool_result("web.visit", &snowflake_id().to_string(), &visit_args, &visit_result, visit_ok, visit_ms).await;
            }
            model_parts.push(json!({ "functionCall": { "name": "web_visit", "args": visit_args } }));
            function_parts.push(json!({ "functionResponse": { "name": "web_visit", "response": visit_result } }));
        }
    }
    contents.push(json!({ "role": "model", "parts": model_parts }));
    contents.push(json!({ "role": "function", "parts": function_parts }));
    Ok(true)
}

fn ensure_web_visit_tool(tools: &mut Vec<crate::tools::ToolDef>, tool_json: &mut serde_json::Value) {
    if tools.iter().any(|t| t.name == "web.visit") {
        return;
    }
    if let Some(def) = cluster_tool_def("web.visit") {
        tools.push(def);
        *tool_json = tool_decls(tools);
    }
}

pub fn user_wants_search(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    [
        "search", "cari ", "google ", "berita", "latest ", "news ", "what is ", "apa itu ", "siapa ",
        "film", "bioskop", "cinema", "jadwal", "tayang", "nonton", "cuaca", "harga ", "sekarang apa",
        "hari ini apa", "apa yang tayang", "jadwal nonton", "showtime",
    ]
    .iter()
    .any(|k| t.contains(k))
}

pub fn search_query_from_user(text: &str) -> String {
    let lower = text.to_ascii_lowercase();
    for key in ["cari ", "search ", "google ", "look up "] {
        if let Some(i) = lower.rfind(key) {
            let q = text[i + key.len()..].trim();
            if !q.is_empty() { return q.to_string(); }
        }
    }
    text.trim().to_string()
}

pub fn user_wants_consumption_recap(text: &str) -> bool {
    let t = text.trim().to_ascii_lowercase();
    if t.is_empty() {
        return false;
    }
    if ["catat ", "track food", "log meal", "log food", "hapus ", "delete meal", "berapa kalori"]
        .iter()
        .any(|k| t.contains(k))
    {
        return false;
    }
    [
        "apa aja yang aku makan",
        "apa yang aku makan",
        "riwayat makan",
        "makan hari ini",
        "makan kemarin",
        "what did i eat",
        "food history",
        "meal recap",
        "nutrition recap",
        "ringkasan nutrisi",
        "cek makanan",
        "konsumsi makanan",
        "minggu lalu",
        "minggu ini",
    ]
    .iter()
    .any(|k| t.contains(k))
        || (t.contains("makan") && (t.contains("hari ini") || t.contains("kemarin") || t.contains("yesterday")))
}

pub fn consumption_recap_args_from_user(text: &str, locale: &str) -> Value {
    let day_id = c35_mod_consumption::day_id_from_query(text, locale);
    json!({ "day_id": day_id, "days": 1 })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_wants_search_cinema_id() {
        assert!(user_wants_search("film apa saja di bioskop malang hari ini ?"));
    }

}
