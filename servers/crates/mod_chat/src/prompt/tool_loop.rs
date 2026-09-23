use std::sync::Arc;
use std::time::Instant;

use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use c35_store::snowflake_id;
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use super::llm_route::{bill_model_slug, llm_generate_chain, llm_stream_chain};
use super::thought::{thought_push, thinking_level};
use super::{ChatReq, ChatRes};
use crate::prompt::hooks::PromptHopCheckpoint;
use crate::prompt_run::{
    chat_tool_rounds_max, checkpoint_record_tool, checkpoint_set_fatal, checkpoint_tool_should_stop,
};
use crate::tools::{cluster_tool_exec, http_client, tool_decls, TurnCtx};
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
    let tools = req.tools.clone();
    let tool_json = tool_decls(&tools);
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

    let mut prev_call: Option<(String, Value)> = None;
    let mut used_tool = false;
    for round in 0..rounds_max {
        if cancel.is_cancelled() { anyhow::bail!("aborted"); }
        let wrap = chat_tool_rounds_done(round + 1, run_kind);
        let hop = round + 1;
        let hop_started = Instant::now();
        let (out, _provider_model, _) = if wrap {
            contents.push(json!({ "role": "user", "parts": [{ "text": CHAT_WRAPUP_HINT }] }));
            llm_generate_chain(&client, &requested_model, &contents, &json!([]), &thinking, &system, &req.user).await?
        } else {
            llm_generate_chain(&client, &requested_model, &contents, &tool_json, &thinking, &system, &req.user).await?
        };
        let hop_ms = hop_started.elapsed().as_millis() as i64;
        tokens_in += out.in_tok;
        tokens_out += out.out_tok;
        if let Some(tr) = tracer {
            let hop_cost = billing_cost_usd(&bill_slug, out.in_tok, out.out_tok);
            tr.llm_call(hop as u8, &bill_slug, out.in_tok, out.out_tok, hop_ms, hop_cost, &out.text).await;
        }
        hop_checkpoint(turn_ctx.as_deref(), &on_hop, hop as i32, hop as i32, tokens_in, tokens_out, tools_cost_usd, &blocks_json, "");
        emit_thought(on_delta, &mut thought, &out.thought);
        if let Some((name, args)) = out.function_call {
            if wrap || tool_call_dup(&prev_call, &name, &args) {
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
            let label = format!("Using {name}…\n");
            emit_thought(on_delta, &mut thought, &label);
            contents.push(out.model_content);
            let tool_started = Instant::now();
            let (result, tool_cost) = cluster_tool_exec(&client, &name, &args, turn_ctx.as_deref()).await;
            tools_cost_usd += tool_cost;
            let tool_ms = tool_started.elapsed().as_millis() as i64;
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

            used_tool = true;
            contents.push(json!({
                "role": "function",
                "parts": [{ "functionResponse": { "name": name.replace('.', "_"), "response": llm_result } }]
            }));

            if let Some(img_b64) = maybe_img {
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

            prev_call = Some((name, args));
            continue;
        }
        if !out.text.is_empty() {
            emit_thought(on_delta, &mut thought, &out.thought);
            emit_text(on_delta, &mut text, &out.text);
            return Ok(ChatRes { text, thought, blocks_json, tokens_in, tokens_out, model_used, tools_cost_usd });
        }
        if round == 0 && !used_tool && user_wants_search(&req.user) && tools.iter().any(|t| t.name == "web.search") {
            let q = search_query_from_user(&req.user);
            emit_thought(on_delta, &mut thought, "Using web.search…\n");
            let tool_started = Instant::now();
            let args = json!({ "query": q, "limit": 6 });
            let (result, tool_cost) = cluster_tool_exec(&client, "web.search", &args, turn_ctx.as_deref()).await;
            tools_cost_usd += tool_cost;
            let tool_ms = tool_started.elapsed().as_millis() as i64;
            let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
            if let Some(tr) = tracer {
                tr.tool_result("web.search", &snowflake_id().to_string(), &args, &result, ok, tool_ms).await;
            }
            used_tool = true;
            contents.push(json!({ "role": "model", "parts": [{ "functionCall": { "name": "web_search", "args": { "query": q } } }] }));
            contents.push(json!({
                "role": "function",
                "parts": [{ "functionResponse": { "name": "web_search", "response": result } }]
            }));
            prev_call = Some(("web.search".into(), args));
            continue;
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
    let (out, _provider_model, _) = llm_stream_chain(requested_model, &contents, &json!([]), thinking, system, on_delta, cancel).await?;
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

pub fn user_wants_search(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    ["search", "cari ", "google ", "berita", "latest ", "news ", "what is ", "apa itu ", "siapa "]
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
