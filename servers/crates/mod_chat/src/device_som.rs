use std::time::Instant;

use anyhow::Result;
use base64::Engine;
use c35_mod_device::remote_device_screenshot_capture;
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::task::JoinHandle;

use crate::context_pack::ContextUsageEst;
use crate::mcp_agent::mcp_agent_owner_allowed;
use crate::mcp_tool_artifact::mcp_json_i64;
use crate::mention_context::{device_iid_resolve, MentionContext};
use crate::prompt_turn::{PromptTurn, PromptTurnHooks};
use crate::tools::device_screenshot_artifact::device_screenshot_artifact_put;

pub const SOM_SLASH_CMD: &str = "/som";

#[derive(Debug, Clone, PartialEq)]
pub struct SomCaptureOpts {
    pub device_iid: i64,
    pub max_width: u32,
    pub quality: u32,
    pub marker: Option<(f64, f64)>,
    pub som_mark: Option<u32>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SomSlashParsed {
    pub device_iid: Option<i64>,
    pub som_mark: Option<u32>,
    pub marker: Option<(f64, f64)>,
}

pub fn som_command_invoked(text: &str) -> bool {
    let t = text.trim();
    if t == SOM_SLASH_CMD {
        return true;
    }
    let prefix = format!("{SOM_SLASH_CMD} ");
    t.starts_with(&prefix) || t.starts_with(&format!("{SOM_SLASH_CMD}\t"))
}

pub fn som_command_parse(text: &str) -> Result<SomSlashParsed, String> {
    let t = text.trim();
    let rest = if t == SOM_SLASH_CMD {
        ""
    } else if let Some(r) = t.strip_prefix(SOM_SLASH_CMD) {
        r.trim()
    } else {
        return Err(format!("expected {SOM_SLASH_CMD} command"));
    };
    let mut out = SomSlashParsed {
        device_iid: None,
        som_mark: None,
        marker: None,
    };
    if rest.is_empty() {
        return Ok(out);
    }
    let tokens: Vec<&str> = rest.split_whitespace().collect();
    let mut i = 0;
    while i < tokens.len() {
        let tok = tokens[i];
        let low = tok.to_ascii_lowercase();
        if low == "device" || low == "device_iid" {
            i += 1;
            if i >= tokens.len() {
                return Err("device requires device_iid".into());
            }
            let id = parse_i64_token(tokens[i])?;
            if id <= 0 {
                return Err("device_iid must be positive".into());
            }
            out.device_iid = Some(id);
            i += 1;
            continue;
        }
        if low == "mark" || low == "marker" {
            i += 1;
            if i >= tokens.len() {
                return Err("mark requires index".into());
            }
            let n = parse_mark_index(tokens[i])?;
            out.som_mark = Some(n);
            i += 1;
            continue;
        }
        if low == "at" || low == "point" {
            i += 1;
            if i + 1 >= tokens.len() {
                return Err("at requires normalized x y".into());
            }
            let mx = parse_f64_token(tokens[i])?;
            let my = parse_f64_token(tokens[i + 1])?;
            if !(mx >= 0.0 && mx <= 1.0 && my >= 0.0 && my <= 1.0) {
                return Err("marker coordinates must be normalized 0..1".into());
            }
            out.marker = Some((mx, my));
            i += 2;
            continue;
        }
        if let Some(id) = tok.strip_prefix("device_iid=") {
            let n = parse_i64_token(id)?;
            if n <= 0 {
                return Err("device_iid must be positive".into());
            }
            out.device_iid = Some(n);
            i += 1;
            continue;
        }
        if let Ok(n) = parse_mark_index(tok) {
            out.som_mark = Some(n);
            i += 1;
            continue;
        }
        return Err(format!("unknown token: {tok}"));
    }
    Ok(out)
}

fn parse_i64_token(s: &str) -> Result<i64, String> {
    s.trim()
        .parse::<i64>()
        .map_err(|_| format!("invalid integer: {s}"))
}

fn parse_f64_token(s: &str) -> Result<f64, String> {
    s.trim()
        .parse::<f64>()
        .map_err(|_| format!("invalid number: {s}"))
}

fn parse_mark_index(s: &str) -> Result<u32, String> {
    let raw = s.trim().strip_prefix('@').unwrap_or(s.trim());
    let n: u32 = raw
        .parse()
        .map_err(|_| format!("invalid mark index: {s}"))?;
    if n == 0 {
        return Err("mark index must be >= 1".into());
    }
    Ok(n)
}

pub struct SomCaptureResult {
    pub width: u32,
    pub height: u32,
    pub jpeg_bytes: Vec<u8>,
    pub axtree_text: String,
    pub marker_used: bool,
}

pub async fn device_som_capture(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    opts: SomCaptureOpts,
) -> Result<SomCaptureResult, String> {
    if opts.device_iid <= 0 {
        return Err("device_iid is required".into());
    }
    if let Some(n) = opts.som_mark {
        let first = capture_once(
            pool,
            nats,
            owner_iid,
            opts.device_iid,
            opts.max_width,
            opts.quality,
            None,
            true,
        )
        .await?;
        let (mx, my) = som_mark_center(&first.axtree_text, n)?;
        let second = capture_once(
            pool,
            nats,
            owner_iid,
            opts.device_iid,
            opts.max_width,
            opts.quality,
            Some((mx, my)),
            false,
        )
        .await?;
        return Ok(SomCaptureResult {
            width: second.width,
            height: second.height,
            jpeg_bytes: second.jpeg_bytes,
            axtree_text: first.axtree_text,
            marker_used: true,
        });
    }
    let marker_used = opts.marker.is_some();
    let res = capture_once(
        pool,
        nats,
        owner_iid,
        opts.device_iid,
        opts.max_width,
        opts.quality,
        opts.marker,
        true,
    )
    .await?;
    Ok(SomCaptureResult {
        width: res.width,
        height: res.height,
        jpeg_bytes: res.jpeg_bytes,
        axtree_text: res.axtree_text,
        marker_used,
    })
}

struct RawCapture {
    width: u32,
    height: u32,
    jpeg_bytes: Vec<u8>,
    axtree_text: String,
}

async fn capture_once(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    device_iid: i64,
    max_width: u32,
    quality: u32,
    marker: Option<(f64, f64)>,
    som: bool,
) -> Result<RawCapture, String> {
    let res = remote_device_screenshot_capture(
        pool,
        nats,
        owner_iid,
        device_iid,
        max_width,
        quality,
        marker,
        som,
    )
    .await?;
    if !res.ok {
        let msg = if res.error.is_empty() {
            "screenshot failed".to_string()
        } else {
            res.error
        };
        return Err(msg);
    }
    Ok(RawCapture {
        width: res.width,
        height: res.height,
        jpeg_bytes: res.jpeg_bytes,
        axtree_text: res.axtree_text,
    })
}

pub fn som_mark_center(axtree_text: &str, mark: u32) -> Result<(f64, f64), String> {
    let prefix = format!("@{mark} ");
    for line in axtree_text.lines() {
        let line = line.trim();
        if !line.starts_with(&prefix) {
            continue;
        }
        if let Some(coords) = parse_center_pair(line) {
            return Ok(coords);
        }
    }
    Err(format!("mark @{mark} not found in axtree"))
}

fn parse_center_pair(line: &str) -> Option<(f64, f64)> {
    let needle = "center=(";
    let start = line.find(needle)?;
    let after = &line[start + needle.len()..];
    let end = after.find(')')?;
    let pair = after[..end].trim();
    let (x_s, y_s) = pair.split_once(',')?;
    let mx = x_s.trim().parse::<f64>().ok()?;
    let my = y_s.trim().parse::<f64>().ok()?;
    if mx >= 0.0 && mx <= 1.0 && my >= 0.0 && my <= 1.0 {
        Some((mx, my))
    } else {
        None
    }
}

fn som_capture_opts_from_json(device_iid: i64, args: &Value) -> SomCaptureOpts {
    let max_width = args
        .get("max_width")
        .and_then(|v| v.as_u64())
        .unwrap_or(1280)
        .clamp(320, 3840) as u32;
    let quality = args
        .get("quality")
        .and_then(|v| v.as_u64())
        .unwrap_or(72)
        .clamp(20, 100) as u32;
    let som_mark = args
        .get("som_mark")
        .or_else(|| args.get("mark"))
        .and_then(|v| {
            if let Some(n) = v.as_u64() {
                u32::try_from(n).ok()
            } else {
                v.as_str().and_then(|s| parse_mark_index(s).ok())
            }
        });
    let marker = match (
        args.get("marker_x").and_then(|v| v.as_f64()),
        args.get("marker_y").and_then(|v| v.as_f64()),
    ) {
        (Some(mx), Some(my)) if mx >= 0.0 && my >= 0.0 && mx <= 1.0 && my <= 1.0 => Some((mx, my)),
        _ => None,
    };
    SomCaptureOpts {
        device_iid,
        max_width,
        quality,
        marker,
        som_mark,
    }
}

pub async fn mcp_device_som(
    pool: &PgPool,
    nats: Option<async_nats::Client>,
    owner_iid: i64,
    req_id: &str,
    args: &Value,
) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return json!({ "ok": false, "error": "owner not allowed", "owner_iid": owner_iid });
    }
    let device_iid = mcp_json_i64(args, "device_iid").unwrap_or(0);
    if device_iid <= 0 {
        return json!({ "ok": false, "error": "args_json.device_iid required" });
    }
    let opts = som_capture_opts_from_json(device_iid, args);
    match device_som_capture(pool, nats.as_ref(), owner_iid, opts).await {
        Ok(cap) => som_capture_to_json(pool, owner_iid, req_id, device_iid, &cap).await,
        Err(e) => json!({ "ok": false, "error": e, "device_iid": device_iid }),
    }
}

async fn som_capture_to_json(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    device_iid: i64,
    cap: &SomCaptureResult,
) -> Value {
    let tool_call_id = snowflake_id().to_string();
    let b64 = base64::engine::general_purpose::STANDARD.encode(&cap.jpeg_bytes);
    let mut out = json!({
        "ok": true,
        "device_iid": device_iid.to_string(),
        "width": cap.width,
        "height": cap.height,
        "mime_type": "image/jpeg",
        "image_base64": b64,
        "som": true,
        "marker": cap.marker_used,
    });
    if !cap.axtree_text.is_empty() {
        out["axtree_text"] = json!(cap.axtree_text);
    }
    match device_screenshot_artifact_put(
        pool,
        owner_iid,
        req_id,
        &tool_call_id,
        "device.som",
        device_iid,
        &cap.jpeg_bytes,
        cap.width,
        cap.height,
        true,
        cap.marker_used,
        cap.axtree_text.len(),
    )
    .await
    {
        Ok((hash, url)) => {
            out["image_hash"] = json!(hash);
            out["image_url"] = json!(url);
        }
        Err(e) => {
            out["artifact_error"] = json!(e.to_string());
        }
    }
    out
}

fn resolve_device_iid(
    parsed: &SomSlashParsed,
    bound_device_iid: i64,
    mention: &MentionContext,
    mention_ids: &[String],
) -> Result<i64, String> {
    if let Some(iid) = parsed.device_iid.filter(|i| *i > 0) {
        return Ok(iid);
    }
    if bound_device_iid > 0 {
        return Ok(bound_device_iid);
    }
    device_iid_resolve(mention, mention_ids, 0).map_err(|e| e.to_string())
}

fn som_blocks_json(hash: &str, url: &str, width: u32, height: u32) -> String {
    let block = json!({
        "kind": "image",
        "collapsed": false,
        "body": {
            "hash": hash,
            "url": url,
            "mime": "image/jpeg",
            "width": width,
            "height": height,
            "tool": "device.som",
        }
    });
    serde_json::to_string(&vec![block]).unwrap_or_else(|_| "[]".into())
}

async fn som_finish_error_turn(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    req_id: &str,
    chat_id: i64,
    user_msg_id: i64,
    turn_started: Instant,
    error: &str,
    mut on_delta: impl FnMut(bool, String) + Send,
) -> Result<PromptTurn> {
    let duration_ms = turn_started.elapsed().as_millis() as i32;
    let assistant_msg_id = snowflake_id();
    let content = error.to_string();
    on_delta(false, content.clone());
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source,
            content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
            created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', $5, '', '[]'::jsonb, 0, 0, $6, 0, 'error', $5, NOW(), NOW())
        "#,
    )
    .bind(assistant_msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(&content)
    .bind(duration_ms)
    .execute(pool)
    .await?;
    let _ = crate::chat_sync::chat_touch(pool, nats, chat_id, owner_iid, &content, "error").await;
    let _ = c35_mod_billing::billing_reservation_refund(pool, req_id).await;
    Ok(PromptTurn {
        chat_id,
        user_msg_id,
        assistant_msg_id,
        text: content.clone(),
        thought: String::new(),
        blocks_json: "[]".into(),
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
        billing_included: false,
        model: "alienai".into(),
        duration_ms,
        error_text: content,
        prompt_tokens: 0,
        context_window: 0,
        usage: ContextUsageEst {
            instructions: 0,
            memory: 0,
            context: 0,
            tools: 0,
            conversation: 0,
        },
    })
}

pub async fn som_try_prompt_shortcut<F, G>(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    is_root: bool,
    req_id: &str,
    chat_id: i64,
    user_msg_id: i64,
    user_text: &str,
    mention_ids: &[String],
    mention_ctx: &MentionContext,
    bound_device_iid: i64,
    persist_handle: &mut JoinHandle<Result<(), sqlx::Error>>,
    turn_started: Instant,
    on_delta: &mut F,
    on_blocks: &mut G,
    hooks: &PromptTurnHooks,
) -> Result<Option<PromptTurn>>
where
    F: FnMut(bool, String) + Send,
    G: FnMut(String) + Send,
{
    if !som_command_invoked(user_text) {
        return Ok(None);
    }
    if !is_root {
        match persist_handle.await {
            Ok(Ok(())) => {}
            Ok(Err(e)) => return Err(e.into()),
            Err(e) => return Err(e.into()),
        }
        return Ok(Some(
            som_finish_error_turn(
                pool,
                nats,
                owner_iid,
                req_id,
                chat_id,
                user_msg_id,
                turn_started,
                "/som is root-only",
                &mut *on_delta,
            )
            .await?,
        ));
    }
    let parsed = match som_command_parse(user_text) {
        Ok(p) => p,
        Err(e) => {
            match persist_handle.await {
                Ok(Ok(())) => {}
                Ok(Err(err)) => return Err(err.into()),
                Err(err) => return Err(err.into()),
            }
            let turn = som_finish_error_turn(
                pool,
                nats,
                owner_iid,
                req_id,
                chat_id,
                user_msg_id,
                turn_started,
                &e,
                &mut *on_delta,
            )
            .await?;
            return Ok(Some(turn));
        }
    };
    let device_iid = match resolve_device_iid(&parsed, bound_device_iid, mention_ctx, mention_ids)
    {
        Ok(iid) => iid,
        Err(e) => {
            match persist_handle.await {
                Ok(Ok(())) => {}
                Ok(Err(err)) => return Err(err.into()),
                Err(err) => return Err(err.into()),
            }
            let turn = som_finish_error_turn(
                pool,
                nats,
                owner_iid,
                req_id,
                chat_id,
                user_msg_id,
                turn_started,
                &e,
                &mut *on_delta,
            )
            .await?;
            return Ok(Some(turn));
        }
    };
    match persist_handle.await {
        Ok(Ok(())) => {}
        Ok(Err(e)) => return Err(e.into()),
        Err(e) => return Err(e.into()),
    }
    let opts = SomCaptureOpts {
        device_iid,
        max_width: 1280,
        quality: 72,
        marker: parsed.marker,
        som_mark: parsed.som_mark,
    };
    let cap = match device_som_capture(pool, nats, owner_iid, opts).await {
        Ok(c) => c,
        Err(e) => {
            let turn = som_finish_error_turn(
                pool,
                nats,
                owner_iid,
                req_id,
                chat_id,
                user_msg_id,
                turn_started,
                &e,
                &mut *on_delta,
            )
            .await?;
            return Ok(Some(turn));
        }
    };
    let tool_call_id = snowflake_id().to_string();
    let (hash, url) = device_screenshot_artifact_put(
        pool,
        owner_iid,
        req_id,
        &tool_call_id,
        "device.som",
        device_iid,
        &cap.jpeg_bytes,
        cap.width,
        cap.height,
        true,
        cap.marker_used,
        cap.axtree_text.len(),
    )
    .await?;
    let mut assistant_content = format!(
        "Set-of-Mark screenshot for device {} ({}x{}).",
        device_iid,
        cap.width,
        cap.height
    );
    if !cap.axtree_text.is_empty() {
        assistant_content.push_str("\n\n");
        assistant_content.push_str(&cap.axtree_text);
    }
    let blocks_json = som_blocks_json(&hash, &url, cap.width, cap.height);
    on_blocks(blocks_json.clone());
    on_delta(false, assistant_content.clone());
    let duration_ms = turn_started.elapsed().as_millis() as i32;
    let assistant_msg_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source,
            content, thought, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd, status, error_text,
            created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', $5, '', $6::jsonb, 0, 0, $7, 0, 'done', '', NOW(), NOW())
        "#,
    )
    .bind(assistant_msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(req_id)
    .bind(&assistant_content)
    .bind(&blocks_json)
    .bind(duration_ms)
    .execute(pool)
    .await?;
    let _ = crate::chat_sync::chat_touch(
        pool,
        nats,
        chat_id,
        owner_iid,
        &assistant_content,
        "done",
    )
    .await;
    let _ = c35_mod_billing::billing_usage_report(
        pool,
        nats,
        owner_iid,
        req_id,
        chat_id,
        "alienai",
        0,
        0,
        duration_ms,
        None,
        0.0,
        None,
    )
    .await;
    if let Some(ref session) = hooks.owner_session {
        use crate::context_pack::HistoryRow;
        crate::owner_session::chat_cache_append_turn(
            session,
            chat_id,
            HistoryRow {
                id: user_msg_id,
                role: "user".into(),
                content: user_text.to_string(),
                blocks_json: "[]".into(),
            },
            HistoryRow {
                id: assistant_msg_id,
                role: "assistant".into(),
                content: assistant_content.clone(),
                blocks_json: blocks_json.clone(),
            },
        );
    }
    Ok(Some(PromptTurn {
        chat_id,
        user_msg_id,
        assistant_msg_id,
        text: assistant_content,
        thought: String::new(),
        blocks_json,
        tokens_in: 0,
        tokens_out: 0,
        cost_usd: 0.0,
        billing_included: false,
        model: "alienai".into(),
        duration_ms,
        error_text: String::new(),
        prompt_tokens: 0,
        context_window: 0,
        usage: ContextUsageEst {
            instructions: 0,
            memory: 0,
            context: 0,
            tools: 0,
            conversation: 0,
        },
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn som_command_invoked_detects_prefix() {
        assert!(som_command_invoked("/som"));
        assert!(som_command_invoked("  /som  "));
        assert!(som_command_invoked("/som mark 2"));
        assert!(!som_command_invoked("som"));
        assert!(!som_command_invoked("/something"));
    }

    #[test]
    fn som_command_parse_empty() {
        let p = som_command_parse("/som").expect("parse");
        assert_eq!(
            p,
            SomSlashParsed {
                device_iid: None,
                som_mark: None,
                marker: None,
            }
        );
    }

    #[test]
    fn som_command_parse_mark_shorthand() {
        let p = som_command_parse("/som 4").expect("parse");
        assert_eq!(p.som_mark, Some(4));
        let p2 = som_command_parse("/som @7").expect("parse");
        assert_eq!(p2.som_mark, Some(7));
        let p3 = som_command_parse("/som mark 3").expect("parse");
        assert_eq!(p3.som_mark, Some(3));
    }

    #[test]
    fn som_command_parse_device_and_at() {
        let p = som_command_parse("/som device 99001 mark 2").expect("parse");
        assert_eq!(p.device_iid, Some(99001));
        assert_eq!(p.som_mark, Some(2));
        let p2 = som_command_parse("/som at 0.25 0.75").expect("parse");
        assert_eq!(p2.marker, Some((0.25, 0.75)));
    }

    #[test]
    fn som_mark_center_parses_axtree_line() {
        let tree = "Interactive UI elements (use exact normalized x, y to click):\n@2 Button 'OK' -> center=(0.500, 0.250) pixel=(10, 20)";
        let (x, y) = som_mark_center(tree, 2).expect("coords");
        assert!((x - 0.5).abs() < 0.001);
        assert!((y - 0.25).abs() < 0.001);
    }
}
