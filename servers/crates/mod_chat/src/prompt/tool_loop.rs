use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::Result;
use c35_mod_billing::billing_cost_usd;
use c35_store::snowflake_id;
use futures_util::future::join_all;
use serde_json::{json, Value};
use tokio_util::sync::CancellationToken;

use super::llm_route::{bill_model_slug, llm_stream_chain};
use super::prose_tool::apply_prose_tool_calls;
use super::staff_registrations::{
    staff_registrations_append_user_context, staff_registrations_should_prefetch,
    staff_registrations_tool_args, user_text_looks_like_staff_registrations_intent,
};
use super::thought::{thinking_level, thought_push};
use super::web_grounding::{
    pick_visit_url_for_query, reply_looks_like_web_deferral, reply_looks_like_web_placeholder,
    search_payload, web_grounding_append_user_context,
};
use super::computer_use::{
    computer_use_final_text_acceptable, computer_use_stopped_incomplete_message,
    parent_reply_after_incomplete_delegate, DELEGATE_INCOMPLETE_CHECKPOINT_KEY,
    COMPUTER_USE_CONTINUE_HINT, COMPUTER_USE_FORCE_TOOL_HINT, COMPUTER_USE_INCOMPLETE_FAIL_CLASS,
    COMPUTER_USE_PARENT_INCOMPLETE_HINT,
};
use crate::prompt::google_forms::ComputerUseToolCounts;
use crate::prompt::google_sheets::{
    google_sheets_device_input_uses_pixel_grid_without_goto,
    google_sheets_parent_turn_may_finish, google_sheets_shell_blocked_on_ui_turn,
    user_text_looks_like_device_spreadsheet_ui, GOOGLE_SHEETS_PARENT_CONTINUE_HINT,
    GOOGLE_SHEETS_PIXEL_GRID_STEER_HINT, GOOGLE_SHEETS_SHELL_FORBIDDEN_HINT,
};
use super::{ChatReq, ChatRes};
use crate::catalog_web::{catalog_query_arms_web, catalog_web_after_stock, CatalogWebPhase};
use crate::chat_title_set;
use crate::mention_context::{json_device_iid_field, mention_context_register_site};
use crate::prompt::hooks::PromptHopCheckpoint;
use crate::prompt_run::{
    chat_tool_rounds_max, checkpoint_record_tool, checkpoint_set_fatal, checkpoint_tool_should_stop,
};
use crate::tools::{cluster_tool_def, cluster_tool_exec, http_client, tool_decls, TurnCtx};
use crate::turn_tracer::TurnTracer;

pub const CHAT_TOOL_ROUNDS_MAX: u8 = 24;
pub const CHAT_WRAPUP_HINT: &str =
    "Stop using tools. Answer the user now with what you already found. Do not call more tools.";

fn cluster_system(req: &ChatReq) -> String {
    req.system.trim().to_string()
}

pub fn chat_tool_rounds_done(round: u8, run_kind: &str) -> bool {
    round >= chat_tool_rounds_max(run_kind)
}

pub fn tool_call_dup(prev: &Option<(String, Value)>, name: &str, args: &Value) -> bool {
    prev.as_ref()
        .map(|(n, a)| n == name && a == args)
        .unwrap_or(false)
}

pub fn tool_calls_dup(
    prev: &[(String, Value, Option<String>)],
    current: &[(String, Value, Option<String>)],
) -> bool {
    !prev.is_empty()
        && prev.len() == current.len()
        && prev
            .iter()
            .zip(current)
            .all(|(a, b)| a.0 == b.0 && a.1 == b.1)
}

fn tool_name_key(name: &str) -> String {
    name.replace('.', "_")
}

fn is_long_running_delegate_tool(name: &str) -> bool {
    let k = tool_name_key(name);
    k == "computer_use_delegate" || k == "delegate_run"
}

fn append_block(blocks_json: &str, block: Value) -> String {
    let mut arr = serde_json::from_str::<Vec<Value>>(blocks_json).unwrap_or_default();
    arr.push(block);
    serde_json::to_string(&arr).unwrap_or_else(|_| "[]".into())
}

/// Prune previous desktop screenshots from conversation context so only the latest
/// observation is retained. Ensures the model is never confused by stale desktop states
/// and prevents base64 network payload bloat across multi-turn computer use sessions.
pub fn prune_previous_screenshots(contents: &mut [Value]) {
    for msg in contents.iter_mut() {
        if let Some(parts) = msg.get_mut("parts").and_then(|p| p.as_array_mut()) {
            for part in parts.iter_mut() {
                if let Some(inline) = part.get("inlineData") {
                    if inline.get("mimeType").and_then(|m| m.as_str()) == Some("image/jpeg") {
                        *part = json!({
                            "text": "[Previous desktop screenshot omitted; current state in latest observation]"
                        });
                    }
                }
            }
        }
    }
}

pub fn truncate_large_tool_payload(val: &mut Value, max_chars: usize) {
    match val {
        Value::String(s) => {
            if s.chars().count() > max_chars {
                let keep: String = s.chars().take(max_chars).collect();
                *s = format!("{keep}\n\n[...truncated to fit context budget...]");
            }
        }
        Value::Array(arr) => {
            for item in arr {
                truncate_large_tool_payload(item, max_chars);
            }
        }
        Value::Object(map) => {
            for (_k, v) in map.iter_mut() {
                truncate_large_tool_payload(v, max_chars);
            }
        }
        _ => {}
    }
}

pub fn is_device_turn(req: &ChatReq, run_kind: &str, turn_ctx: Option<&TurnCtx<'_>>) -> bool {
    if run_kind == "computer_use" {
        return true;
    }
    if req.device_prefetch.is_some() {
        return true;
    }
    if req.tools.iter().any(|t| t.name.starts_with("device.") || t.name.starts_with("computer_use.")) {
        return true;
    }
    if req.matched_inst_ids.iter().any(|id| id.starts_with("inst.device.") || id == "inst.computer_use") {
        return true;
    }
    if let Some(ctx) = turn_ctx {
        if !ctx.mention.devices.is_empty() {
            return true;
        }
    }
    if req.user.to_ascii_lowercase().contains("@device") {
        return true;
    }
    false
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
    let is_device = is_device_turn(req, run_kind, turn_ctx.as_deref());
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
        let role = if h.role == "assistant" {
            "model"
        } else {
            "user"
        };
        contents.push(json!({ "role": role, "parts": [{ "text": trimmed }] }));
    }
    contents.push(json!({ "role": "user", "parts": [{ "text": req.user }] }));
    if let Some(prefetch) = &req.device_prefetch {
        crate::prompt::device_screenshot_prefetch::device_screenshot_prefetch_attach_user_turn(
            &mut contents,
            prefetch,
        );
    }
    if let Some(ctx) = turn_ctx.as_ref() {
        let image_parts =
            crate::tools::img::user_image_inline_parts(ctx.pool, ctx.attachments_json).await;
        if !image_parts.is_empty() {
            if let Some(parts) = contents
                .last_mut()
                .and_then(|m| m.get_mut("parts"))
                .and_then(|p| p.as_array_mut())
            {
                parts.extend(image_parts);
            }
        }
    }
    let mut tokens_in = 0i32;
    let mut tokens_out = 0i32;
    let mut thought = String::new();
    let mut text = String::new();
    let mut blocks_json = String::from("[]");
    let mut tools_cost_usd = 0.0f64;
    let mut device_tool_counts = ComputerUseToolCounts::default();
    let mut delegate_goal_met = false;
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
            is_device,
        )
        .await?;
        let hop_ms = hop_started.elapsed().as_millis() as i64;
        tokens_in += out.in_tok;
        tokens_out += out.out_tok;
        text = out.text.clone();
        thought = out.thought.clone();
        if let Some(tr) = tracer {
            let hop_cost = billing_cost_usd(&bill_slug, out.in_tok, out.out_tok);
            tr.llm_call(
                1,
                &bill_slug,
                out.in_tok,
                out.out_tok,
                hop_ms,
                hop_cost,
                &out.text,
            )
            .await;
        }
        hop_checkpoint(
            turn_ctx.as_deref(),
            &on_hop,
            1,
            1,
            tokens_in,
            tokens_out,
            tools_cost_usd,
            &blocks_json,
            "",
        );
        return Ok(ChatRes {
            text,
            thought,
            blocks_json,
            tokens_in,
            tokens_out,
            model_used,
            tools_cost_usd: 0.0,
        });
    }

    let mut prev_calls: Vec<(String, Value, Option<String>)> = Vec::new();
    let mut cu_text_rejects: u8 = 0;
    let mut used_tool = false;
    let mut web_grounded = false;
    let mut stock_returned = false;
    if req.force_web_tool_call
        && !req.skip_web_prefetch
        && !staff_registrations_should_prefetch(&req.matched_inst_ids, &tools)
        && tools.iter().any(|t| t.name == "web.search")
    {
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
            prev_calls = vec![("web.search".into(), json!({ "query": q, "limit": 6 }), None)];
        }
    }
    if staff_registrations_should_prefetch(&req.matched_inst_ids, &tools) {
        let args = staff_registrations_tool_args(&req.user);
        emit_thought(on_delta, &mut thought, "Using admin.user.registrations.list…\n");
        let tool_started = Instant::now();
        let (result, tool_cost) = cluster_tool_exec(
            &client,
            "admin.user.registrations.list",
            &args,
            turn_ctx.as_deref(),
            None,
        )
        .await;
        tools_cost_usd += tool_cost;
        let tool_ms = tool_started.elapsed().as_millis() as i64;
        let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
        if let Some(tr) = tracer {
            tr.tool_result(
                "admin.user.registrations.list",
                &snowflake_id().to_string(),
                &args,
                &result,
                ok,
                tool_ms,
            )
            .await;
        }
        staff_registrations_append_user_context(&mut contents, &result);
        tools.retain(|t| t.name != "web.search" && t.name != "web.visit");
        tool_json = tool_decls(&tools);
        used_tool = true;
        web_grounded = true;
        prev_calls = vec![(
            "admin.user.registrations.list".into(),
            args,
            None,
        )];
    }
    for round in 0..rounds_max {
        if cancel.is_cancelled() {
            anyhow::bail!("aborted");
        }
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
                        crate::prompt_followup::prompt_followup_append_to_contents(
                            &mut contents,
                            &steer_texts,
                        );
                    }
                    Err(e) => tracing::warn!(
                        "[c35:prompt_followup] drain failed req_id={}: {e:#}",
                        ctx.req_id
                    ),
                    _ => {}
                }
            }
        }
        let wrap = chat_tool_rounds_done(round + 1, run_kind);
        let hop = round + 1;
        let hop_started = Instant::now();
        let tool_call_mode = if round == 0 && req.force_tool_call && !web_grounded && !wrap {
            "ANY"
        } else {
            "AUTO"
        };
        let tools_for_hop = if web_grounded && !wrap {
            json!([])
        } else {
            tool_json.clone()
        };
        let buffer_deltas = req.force_web_tool_call && web_grounded && !wrap;
        let mut delta_buf: Option<Vec<(bool, String)>> = if buffer_deltas {
            Some(Vec::new())
        } else {
            None
        };
        let mut hop_delta = |thought: bool, s: String| {
            if let Some(buf) = &mut delta_buf {
                buf.push((thought, s));
            } else {
                on_delta(thought, s);
            }
        };
        let (out, _provider_model, _) = if wrap {
            contents.push(json!({ "role": "user", "parts": [{ "text": CHAT_WRAPUP_HINT }] }));
            llm_stream_chain(
                &requested_model,
                &contents,
                &json!([]),
                &thinking,
                &system,
                "AUTO",
                on_delta,
                cancel,
                is_device,
            )
            .await?
        } else {
            llm_stream_chain(
                &requested_model,
                &contents,
                &tools_for_hop,
                &thinking,
                &system,
                tool_call_mode,
                &mut hop_delta,
                cancel,
                is_device,
            )
            .await?
        };
        let out = apply_prose_tool_calls(out, &tools);
        let hop_ms = hop_started.elapsed().as_millis() as i64;
        tokens_in += out.in_tok;
        tokens_out += out.out_tok;
        if let Some(tr) = tracer {
            let hop_cost = billing_cost_usd(&bill_slug, out.in_tok, out.out_tok);
            tr.llm_call(
                hop as u8,
                &bill_slug,
                out.in_tok,
                out.out_tok,
                hop_ms,
                hop_cost,
                &out.text,
            )
            .await;
        }
        hop_checkpoint(
            turn_ctx.as_deref(),
            &on_hop,
            hop as i32,
            hop as i32,
            tokens_in,
            tokens_out,
            tools_cost_usd,
            &blocks_json,
            "",
        );
        if !out.thought.is_empty() {
            thought_push(&mut thought, &out.thought);
        }
        if !out.function_calls.is_empty() {
            if wrap || tool_calls_dup(&prev_calls, &out.function_calls) {
                // After prefetch, the model may echo the same tool call as prose; wrap up instead.
                if !out.text.is_empty() && !used_tool {
                    if let Some(buf) = delta_buf.as_mut() {
                        for (thought, s) in buf.iter() {
                            on_delta(*thought, s.clone());
                        }
                        buf.clear();
                    }
                    text = out.text.clone();
                    return Ok(ChatRes {
                        text,
                        thought,
                        blocks_json,
                        tokens_in,
                        tokens_out,
                        model_used,
                        tools_cost_usd,
                    });
                }
                if let Some(buf) = delta_buf.as_mut() {
                    buf.clear();
                }
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
                    is_device,
                )
                .await;
            }
            for (name, _, _) in &out.function_calls {
                let label = format!("Using {name}…\n");
                emit_thought(on_delta, &mut thought, &label);
            }

            let executions = join_all(out.function_calls.iter().map(
                |(name, args, gemini_call_id)| {
                    let client = &client;
                    let turn_ctx_ref = turn_ctx.as_deref();
                    let gemini_call_id = gemini_call_id.clone();
                    async move {
                        let tool_started = Instant::now();
                        let tool_call_id = snowflake_id().to_string();
                        let tool_timeout_secs = if is_long_running_delegate_tool(name) {
                            320
                        } else {
                            60
                        };
                        let cancel_tool = cancel.clone();
                        let exec = cluster_tool_exec(
                            client,
                            name,
                            args,
                            turn_ctx_ref,
                            Some(&tool_call_id),
                        );
                        let tool_res = tokio::select! {
                            res = tokio::time::timeout(Duration::from_secs(tool_timeout_secs), exec) => res,
                            _ = cancel_tool.cancelled() => Ok((
                                serde_json::json!({
                                    "ok": false,
                                    "error": "aborted"
                                }),
                                0.0,
                            )),
                        };
                        let (result, tool_cost) = match tool_res {
                            Ok(res) => res,
                            Err(_) => (
                                serde_json::json!({
                                    "ok": false,
                                    "error": format!("tool {name} timed out after {tool_timeout_secs}s")
                                }),
                                0.0,
                            ),
                        };
                        let tool_ms = tool_started.elapsed().as_millis() as i64;
                        (
                            name.clone(),
                            args.clone(),
                            gemini_call_id,
                            result,
                            tool_cost,
                            tool_ms,
                            tool_call_id,
                        )
                    }
                },
            ))
            .await;

            if let Some(ctx) = turn_ctx.as_ref() {
                let title = ctx.title_slot.lock().ok().and_then(|g| g.clone());
                if let Some(title) = title {
                    let _ = chat_title_set(
                        ctx.pool,
                        ctx.nats,
                        ctx.owner_iid,
                        ctx.chat_id,
                        &title,
                        true,
                    )
                    .await;
                }
            }

            let mut function_parts = Vec::with_capacity(executions.len());
            let mut latest_img_b64 = None;
            let mut catalog_stock_rows: Option<usize> = None;
            let mut sheets_steer_hint: Option<&'static str> = None;
            let sheets_turn = user_text_looks_like_device_spreadsheet_ui(&req.user);

            for (name, args, gemini_call_id, result, tool_cost, tool_ms, tool_call_id) in executions
            {
                if name == "site.query.run"
                    && args
                        .get("query_id")
                        .and_then(|v| v.as_str())
                        .is_some_and(|qid| catalog_query_arms_web(req.catalog_web, qid))
                {
                    stock_returned = true;
                    catalog_stock_rows = Some(
                        result
                            .get("rows")
                            .and_then(|v| v.as_array())
                            .map(|a| a.len())
                            .unwrap_or(0),
                    );
                }
                tools_cost_usd += tool_cost;
                if name == "device.input" {
                    device_tool_counts.device_input += 1;
                    if sheets_turn && google_sheets_device_input_uses_pixel_grid_without_goto(&args) {
                        sheets_steer_hint = Some(GOOGLE_SHEETS_PIXEL_GRID_STEER_HINT);
                    }
                } else if name == "device.screenshot" {
                    device_tool_counts.device_screenshot += 1;
                } else if name == "shell.run" && sheets_turn {
                    let cmd = args
                        .get("command")
                        .and_then(|v| v.as_str())
                        .unwrap_or("");
                    if google_sheets_shell_blocked_on_ui_turn(cmd) {
                        sheets_steer_hint = Some(GOOGLE_SHEETS_SHELL_FORBIDDEN_HINT);
                    }
                }
                let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
                if let Some(tr) = tracer {
                    tr.tool_result(&name, &tool_call_id, &args, &result, ok, tool_ms)
                        .await;
                }
                if let Some(block) = result.get("block") {
                    blocks_json = append_block(&blocks_json, block.clone());
                    on_blocks(blocks_json.clone());
                }
                if let Some(extra) = result.get("blocks").and_then(|v| v.as_array()) {
                    for block in extra {
                        blocks_json = append_block(&blocks_json, block.clone());
                    }
                    if !extra.is_empty() {
                        on_blocks(blocks_json.clone());
                    }
                }
                if name == "site.create" && ok {
                    if let Some(ctx) = turn_ctx.as_mut() {
                        let site_iid = json_device_iid_field(&result, "site_iid");
                        if site_iid > 0 {
                            let alien_id = result
                                .get("alien_id")
                                .and_then(|v| v.as_str())
                                .unwrap_or("");
                            let site_name =
                                result.get("name").and_then(|v| v.as_str()).unwrap_or("");
                            mention_context_register_site(
                                &mut ctx.mention,
                                site_iid,
                                alien_id,
                                site_name,
                            );
                            ctx.site_iid = Some(site_iid);
                        }
                    }
                }
                let fail_class = result
                    .get("fail_class")
                    .and_then(|v| v.as_str())
                    .unwrap_or("");
                let circuit_stop = if let Some(ctx) = turn_ctx.as_mut() {
                    if let Some(cp) = ctx.checkpoint.as_deref_mut() {
                        checkpoint_record_tool(cp, &name, &result, Some(hop as u32));
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
                let err = result.get("error").and_then(|v| v.as_str()).unwrap_or("");
                let missing_device =
                    err.contains("device_iid is required") || err.contains("device_iid required");
                let fatal_unrecoverable = matches!(fail_class, "fatal_auth" | "fatal_offline");
                if fatal_unrecoverable && !missing_device {
                    let err = if err.is_empty() {
                        "device fatal error"
                    } else {
                        err
                    };
                    hop_checkpoint(
                        turn_ctx.as_deref(),
                        &on_hop,
                        hop as i32,
                        hop as i32,
                        tokens_in,
                        tokens_out,
                        tools_cost_usd,
                        &blocks_json,
                        fail_class,
                    );
                    anyhow::bail!(err.to_string());
                }
                let mut llm_result = result.get("llm").cloned().unwrap_or(result.clone());
                if !ok && (name == "gsheet.update" || name == "gsheet.append") {
                    let err = result
                        .get("error")
                        .and_then(|v| v.as_str())
                        .unwrap_or("sheet write failed");
                    llm_result = json!({ "ok": false, "error": err });
                }
                let maybe_img = llm_result.as_object_mut().and_then(|obj| {
                    obj.remove("image_base64")
                        .and_then(|v| v.as_str().map(|s| s.to_string()))
                });
                if let Some(img_b64) = maybe_img {
                    latest_img_b64 = Some(img_b64);
                }

                truncate_large_tool_payload(&mut llm_result, 24_000);

                if is_long_running_delegate_tool(&name) {
                    if result.get("goal_met").and_then(|v| v.as_bool()) == Some(true) {
                        delegate_goal_met = true;
                    }
                    let incomplete = result
                        .get("incomplete")
                        .and_then(|v| v.as_bool())
                        .unwrap_or(false)
                        || (result.get("ok").and_then(|v| v.as_bool()) == Some(false)
                            && result.get("kind").and_then(|v| v.as_str()) == Some("computer_use"));
                    if incomplete {
                        if let Some(ctx) = turn_ctx.as_deref_mut() {
                            if let Some(cp) = ctx.checkpoint.as_deref_mut() {
                                cp[DELEGATE_INCOMPLETE_CHECKPOINT_KEY] = json!(true);
                            }
                        }
                    }
                }

                let mut function_response = json!({
                    "name": name.replace('.', "_"),
                    "response": llm_result
                });
                if let Some(id) = gemini_call_id {
                    function_response["id"] = json!(id);
                }
                function_parts.push(json!({ "functionResponse": function_response }));
            }

            used_tool = true;
            contents.push(out.model_content);
            contents.push(json!({
                "role": "user",
                "parts": function_parts
            }));

            if let Some(img_b64) = latest_img_b64 {
                // Strictly retain only latest desktop screenshot; prune previous ones to text placeholders
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
            if let Some(hint) = sheets_steer_hint {
                contents.push(json!({
                    "role": "user",
                    "parts": [{ "text": hint }]
                }));
            }

            if out
                .function_calls
                .iter()
                .any(|(n, _, _)| n == "web.search" || n == "web.visit")
            {
                ensure_web_visit_tool(&mut tools, &mut tool_json);
            }

            if let Some(row_count) = catalog_stock_rows {
                if catalog_web_after_stock(req.catalog_web, row_count) {
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
                        web_grounded = true;
                    }
                } else if req.catalog_web == CatalogWebPhase::PriceLookup && row_count > 0 {
                    tools.retain(|t| t.name != "web.search" && t.name != "web.visit");
                    tool_json = tool_decls(&tools);
                }
            }

            prev_calls = out.function_calls;
            continue;
        }
        let catalog_defer_web = req.catalog_web == CatalogWebPhase::Stock
            || (matches!(
                req.catalog_web,
                CatalogWebPhase::PriceLookup | CatalogWebPhase::PriceCompare
            ) && !stock_returned);
        if round == 0
            && !used_tool
            && !catalog_defer_web
            && !req.skip_web_prefetch
            && tools.iter().any(|t| t.name == "web.search")
            && (req.force_web_tool_call || user_wants_search(&req.user))
            && !staff_registrations_should_prefetch(&req.matched_inst_ids, &tools)
        {
            let q = search_query_from_user(&req.user);
            if tool_loop_run_web_search(
                &client,
                &q,
                req.force_web_tool_call,
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
                prev_calls = vec![("web.search".into(), json!({ "query": q, "limit": 6 }), None)];
                continue;
            }
        }
        if !out.text.is_empty() {
            let reject_ungrounded = req.force_web_tool_call && !web_grounded && !used_tool;
            let reject_placeholder =
                req.force_web_tool_call && reply_looks_like_web_placeholder(&out.text);
            let reject_deferral =
                req.force_web_tool_call && web_grounded && reply_looks_like_web_deferral(&out.text);
            let delegate_incomplete = turn_ctx
                .as_ref()
                .and_then(|t| t.checkpoint.as_ref())
                .and_then(|cp| {
                    cp.get(DELEGATE_INCOMPLETE_CHECKPOINT_KEY)
                        .and_then(|v| v.as_bool())
                })
                .unwrap_or(false);
            let reject_parent_delegate = run_kind != "computer_use"
                && delegate_incomplete
                && !computer_use_final_text_acceptable(&out.text);
            if reject_parent_delegate {
                contents.push(json!({
                    "role": "model",
                    "parts": [{ "text": out.text }]
                }));
                contents.push(json!({
                    "role": "user",
                    "parts": [{ "text": COMPUTER_USE_PARENT_INCOMPLETE_HINT }]
                }));
                if let Some(buf) = delta_buf.as_mut() {
                    buf.clear();
                }
                if wrap || round + 1 >= rounds_max {
                    let locale = turn_ctx
                        .as_ref()
                        .map(|t| t.locale)
                        .unwrap_or("en");
                    text = parent_reply_after_incomplete_delegate(locale);
                    return Ok(ChatRes {
                        text,
                        thought,
                        blocks_json,
                        tokens_in,
                        tokens_out,
                        model_used,
                        tools_cost_usd,
                    });
                }
                continue;
            }
            let reject_sheets_parent = run_kind != "computer_use"
                && user_text_looks_like_device_spreadsheet_ui(&req.user)
                && !google_sheets_parent_turn_may_finish(
                    &req.user,
                    &out.text,
                    device_tool_counts,
                    delegate_goal_met,
                );
            if reject_sheets_parent {
                if wrap || round + 1 >= rounds_max {
                    let locale = turn_ctx
                        .as_ref()
                        .map(|t| t.locale)
                        .unwrap_or("en");
                    text = if locale.to_ascii_lowercase().starts_with("id") {
                        "Automasi Google Sheet di VM belum selesai (belum terverifikasi di screenshot). \
Silakan coba lagi — saya akan memakai computer_use.delegate atau device.input dengan name box."
                            .to_string()
                    } else {
                        computer_use_stopped_incomplete_message()
                    };
                    return Ok(ChatRes {
                        text,
                        thought,
                        blocks_json,
                        tokens_in,
                        tokens_out,
                        model_used,
                        tools_cost_usd,
                    });
                }
                contents.push(json!({
                    "role": "model",
                    "parts": [{ "text": out.text }]
                }));
                contents.push(json!({
                    "role": "user",
                    "parts": [{ "text": GOOGLE_SHEETS_PARENT_CONTINUE_HINT }]
                }));
                if let Some(buf) = delta_buf.as_mut() {
                    buf.clear();
                }
                continue;
            }
            let reject_cu_bad = run_kind == "computer_use"
                && !wrap
                && (!computer_use_final_text_acceptable(&out.text)
                    || (user_text_looks_like_device_spreadsheet_ui(&req.user)
                        && !google_sheets_parent_turn_may_finish(
                            &req.user,
                            &out.text,
                            device_tool_counts,
                            false,
                        )));
            if reject_cu_bad {
                cu_text_rejects = cu_text_rejects.saturating_add(1);
                let sheets_cu = user_text_looks_like_device_spreadsheet_ui(&req.user);
                let hint = if sheets_cu {
                    if cu_text_rejects >= 3 {
                        COMPUTER_USE_FORCE_TOOL_HINT
                    } else {
                        GOOGLE_SHEETS_PARENT_CONTINUE_HINT
                    }
                } else if cu_text_rejects >= 3 {
                    COMPUTER_USE_FORCE_TOOL_HINT
                } else {
                    COMPUTER_USE_CONTINUE_HINT
                };
                if wrap || round + 1 >= rounds_max {
                    if let Some(ctx) = turn_ctx.as_deref_mut() {
                        if let Some(cp) = ctx.checkpoint.as_deref_mut() {
                            checkpoint_set_fatal(
                                cp,
                                COMPUTER_USE_INCOMPLETE_FAIL_CLASS,
                                "computer use ended without completing goal",
                            );
                        }
                    }
                    hop_checkpoint(
                        turn_ctx.as_deref(),
                        &on_hop,
                        hop as i32,
                        hop as i32,
                        tokens_in,
                        tokens_out,
                        tools_cost_usd,
                        &blocks_json,
                        COMPUTER_USE_INCOMPLETE_FAIL_CLASS,
                    );
                    text = computer_use_stopped_incomplete_message();
                    return Ok(ChatRes {
                        text,
                        thought,
                        blocks_json,
                        tokens_in,
                        tokens_out,
                        model_used,
                        tools_cost_usd,
                    });
                }
                contents.push(json!({
                    "role": "model",
                    "parts": [{ "text": out.text }]
                }));
                contents.push(json!({
                    "role": "user",
                    "parts": [{ "text": hint }]
                }));
                if let Some(buf) = delta_buf.as_mut() {
                    buf.clear();
                }
                continue;
            }
            if !reject_ungrounded && !reject_placeholder && !reject_deferral {
                if let Some(buf) = delta_buf.as_mut() {
                    for (thought, s) in buf.iter() {
                        on_delta(*thought, s.clone());
                    }
                    buf.clear();
                }
                if !out.thought.is_empty() {
                    thought_push(&mut thought, &out.thought);
                }
                text = out.text.clone();
                return Ok(ChatRes {
                    text,
                    thought,
                    blocks_json,
                    tokens_in,
                    tokens_out,
                    model_used,
                    tools_cost_usd,
                });
            }
            if let Some(buf) = delta_buf.as_mut() {
                buf.clear();
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
            is_device,
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
    is_device: bool,
) -> Result<ChatRes> {
    if cancel.is_cancelled() {
        anyhow::bail!("aborted");
    }
    contents.push(json!({ "role": "user", "parts": [{ "text": CHAT_WRAPUP_HINT }] }));
    let hop_started = Instant::now();
    let (out, _provider_model, _) = llm_stream_chain(
        requested_model,
        &contents,
        &json!([]),
        thinking,
        system,
        "AUTO",
        on_delta,
        cancel,
        is_device,
    )
    .await?;
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
        tr.llm_call(
            99,
            bill_slug,
            out.in_tok,
            out.out_tok,
            hop_ms,
            hop_cost,
            &out.text,
        )
        .await;
    }
    if text.is_empty() {
        let fallback = "I could not finish that lookup. Try again with a shorter question.";
        emit_text(on_delta, &mut text, fallback);
    }
    Ok(ChatRes {
        text,
        thought,
        blocks_json,
        tokens_in,
        tokens_out,
        model_used: bill_slug.to_string(),
        tools_cost_usd,
    })
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
    if piece.trim().is_empty() {
        return;
    }
    thought_push(acc, piece);
    on_delta(
        true,
        if piece.ends_with('\n') {
            piece.to_string()
        } else {
            format!("{piece}\n")
        },
    );
}

fn emit_text(on_delta: &mut (dyn FnMut(bool, String) + Send), acc: &mut String, piece: &str) {
    if piece.is_empty() {
        return;
    }
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
    let (result, tool_cost) = cluster_tool_exec(client, "web.search", &args, turn_ctx, None).await;
    *tools_cost_usd += tool_cost;
    let tool_ms = tool_started.elapsed().as_millis() as i64;
    let ok = result.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
    if let Some(tr) = tracer {
        tr.tool_result(
            "web.search",
            &snowflake_id().to_string(),
            &args,
            &result,
            ok,
            tool_ms,
        )
        .await;
    }
    ensure_web_visit_tool(tools, tool_json);
    let search_ok = search_payload(&result)
        .get("ok")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let mut visit_result: Option<Value> = None;
    if force_visit && search_ok && tools.iter().any(|t| t.name == "web.visit") {
        if let Some(url) = pick_visit_url_for_query(&result, q) {
            emit_thought(on_delta, thought, "Using web.visit…\n");
            let visit_args = json!({ "url": url });
            let visit_started = Instant::now();
            let (visit_payload, visit_cost) =
                cluster_tool_exec(client, "web.visit", &visit_args, turn_ctx, None).await;
            *tools_cost_usd += visit_cost;
            let visit_ms = visit_started.elapsed().as_millis() as i64;
            let visit_ok = visit_payload
                .get("ok")
                .and_then(|v| v.as_bool())
                .unwrap_or(true);
            if let Some(tr) = tracer {
                tr.tool_result(
                    "web.visit",
                    &snowflake_id().to_string(),
                    &visit_args,
                    &visit_payload,
                    visit_ok,
                    visit_ms,
                )
                .await;
            }
            visit_result = Some(visit_payload);
        }
    }
    web_grounding_append_user_context(contents, &result, visit_result.as_ref());
    Ok(true)
}

fn ensure_web_visit_tool(
    tools: &mut Vec<crate::tools::ToolDef>,
    tool_json: &mut serde_json::Value,
) {
    if tools.iter().any(|t| t.name == "web.visit") {
        return;
    }
    if let Some(def) = cluster_tool_def("web.visit") {
        tools.push(def);
        *tool_json = tool_decls(tools);
    }
}

pub fn user_wants_search(text: &str) -> bool {
    if user_text_looks_like_staff_registrations_intent(text) {
        return false;
    }
    let t = text.to_ascii_lowercase();
    [
        "search",
        "cari ",
        "google ",
        "berita",
        "latest ",
        "news ",
        "what is ",
        "apa itu ",
        "siapa ",
        "film",
        "bioskop",
        "cinema",
        "jadwal",
        "tayang",
        "nonton",
        "cuaca",
        "harga ",
        "sekarang apa",
        "hari ini apa",
        "apa yang tayang",
        "jadwal nonton",
        "showtime",
    ]
    .iter()
    .any(|k| t.contains(k))
}

pub fn strip_mentions_for_search(text: &str) -> String {
    crate::mention_content::mention_plain_for_title(text)
}

pub fn search_query_from_user(text: &str) -> String {
    let cleaned = strip_mentions_for_search(text);
    let lower = cleaned.to_ascii_lowercase();
    for key in ["cari ", "search ", "google ", "look up "] {
        if let Some(i) = lower.rfind(key) {
            let q = cleaned[i + key.len()..].trim();
            if !q.is_empty() {
                return q.to_string();
            }
        }
    }
    cleaned.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_wants_search_cinema_id() {
        assert!(user_wants_search(
            "film apa saja di bioskop malang hari ini ?"
        ));
    }

    #[test]
    fn user_wants_search_skips_staff_siapa_saja() {
        assert!(!user_wants_search("siapa saja"));
        assert!(user_wants_search("siapa presiden indonesia sekarang"));
    }

    #[test]
    fn prune_previous_screenshots_keeps_append_only_under_threshold() {
        let mut contents = vec![
            json!({
                "role": "user",
                "parts": [
                    { "text": "Visual desktop observation from device:" },
                    {
                        "inlineData": {
                            "mimeType": "image/jpeg",
                            "data": "base64image1"
                        }
                    }
                ]
            }),
            json!({
                "role": "model",
                "parts": [{ "text": "Clicked button" }]
            }),
        ];

        prune_previous_screenshots(&mut contents);

        // Previous screenshot is pruned immediately to an omission note
        let text = contents[0]["parts"][1].get("text").and_then(|v| v.as_str());
        assert!(text.is_some(), "previous screenshot must be converted to text omission");
        assert!(text.unwrap().contains("[Previous desktop screenshot omitted"));
        assert!(contents[0]["parts"][1].get("inlineData").is_none());

        // When appending the new observation, only the latest screenshot has inlineData
        contents.push(json!({
            "role": "user",
            "parts": [
                {
                    "inlineData": {
                        "mimeType": "image/jpeg",
                        "data": "latest_base64_img"
                    }
                }
            ]
        }));
        let latest_inline = contents[2]["parts"][0].get("inlineData");
        assert!(latest_inline.is_some());
        assert_eq!(latest_inline.unwrap()["data"].as_str(), Some("latest_base64_img"));
    }

    #[test]
    fn prune_previous_screenshots_handles_turn0_prefetch_with_axtree() {
        let mut contents = vec![
            json!({
                "role": "user",
                "parts": [
                    { "text": "Click the settings icon" },
                    {
                        "inlineData": {
                            "mimeType": "image/jpeg",
                            "data": "prefetched_base64_img"
                        }
                    },
                    { "text": "Interactive UI elements:\n@1 Button 'Settings'" }
                ]
            }),
            json!({
                "role": "model",
                "parts": [{ "text": "Clicking settings" }]
            }),
        ];

        prune_previous_screenshots(&mut contents);

        // Turn 0 user text is intact
        assert_eq!(
            contents[0]["parts"][0]["text"].as_str(),
            Some("Click the settings icon")
        );

        // Turn 0 prefetched screenshot inlineData is converted to text omission
        assert!(contents[0]["parts"][1].get("inlineData").is_none());
        let omission_text = contents[0]["parts"][1]["text"].as_str().unwrap();
        assert!(omission_text.contains("[Previous desktop screenshot omitted"));

        // Turn 0 structured axtree text is preserved intact
        assert_eq!(
            contents[0]["parts"][2]["text"].as_str(),
            Some("Interactive UI elements:\n@1 Button 'Settings'")
        );

        // New observation can be appended
        contents.push(json!({
            "role": "user",
            "parts": [
                { "text": "Visual desktop observation from device:" },
                {
                    "inlineData": {
                        "mimeType": "image/jpeg",
                        "data": "hop1_new_img"
                    }
                }
            ]
        }));
        assert_eq!(
            contents[2]["parts"][1]["inlineData"]["data"].as_str(),
            Some("hop1_new_img")
        );
    }
}
