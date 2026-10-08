use anyhow::Result;
use c35_mod_admin::{admin_log_list, admin_log_trace, admin_msg_find, admin_msg_get};
use c35_mod_log::log_meta_redact;
use c35_proto::Log;
use c35_proto::ReqAdminLogList;
use serde_json::{json, Value};

use crate::tool;
use crate::tools::builtin::staff::{
    admin_err_json, arg_i64, arg_str, require_root_json, subject_iid_resolve,
};
use crate::tools::ToolContext;

fn log_to_json(l: &Log) -> Value {
    let meta = serde_json::from_str::<Value>(&l.meta_json).unwrap_or(json!({}));
    json!({
        "id": l.id,
        "owner_iid": l.owner_iid,
        "kind": l.kind,
        "topic": l.topic,
        "req_id": l.req_id,
        "text": l.text,
        "model": l.model,
        "tokens_in": l.tokens_in,
        "tokens_out": l.tokens_out,
        "duration_ms": l.duration_ms,
        "cost_usd": l.cost_usd,
        "event_kind": l.event_kind,
        "class": l.class,
        "subject": l.subject,
        "meta": log_meta_redact(&meta),
        "created_ts_ms": l.created_ts_ms,
    })
}

pub async fn admin_log_tail_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.log.tail").await {
        return Ok(v);
    }
    let global = args
        .get("global")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let subject_iid = if global {
        0
    } else {
        match subject_iid_resolve(&ctx.pool, args).await {
            Ok(id) => id,
            Err(e) => return Ok(json!({ "ok": false, "tool": "admin.log.tail", "error": e })),
        }
    };
    let since_minutes = arg_i64(args, "since_minutes");
    let since_ms = if since_minutes > 0 {
        chrono::Utc::now().timestamp_millis() - since_minutes * 60_000
    } else {
        arg_i64(args, "since_ms")
    };
    let req = ReqAdminLogList {
        owner_iid: if subject_iid > 0 {
            Some(subject_iid)
        } else {
            None
        },
        since_ms,
        until_ms: arg_i64(args, "until_ms"),
        text: arg_str(args, "q"),
        kind: {
            let k = arg_str(args, "kind");
            if k.is_empty() {
                None
            } else {
                Some(k)
            }
        },
        topic: {
            let t = arg_str(args, "topic");
            if t.is_empty() {
                None
            } else {
                Some(t)
            }
        },
        limit: arg_i64(args, "limit") as i32,
        before_id: {
            let b = arg_i64(args, "before_id");
            if b > 0 {
                Some(b)
            } else {
                None
            }
        },
        event_kind: {
            let e = arg_str(args, "event_kind");
            if e.is_empty() {
                None
            } else {
                Some(e)
            }
        },
        class: {
            let c = arg_str(args, "class");
            if c.is_empty() {
                None
            } else {
                Some(c)
            }
        },
        subject_prefix: {
            let p = arg_str(args, "subject_prefix");
            if p.is_empty() {
                None
            } else {
                Some(p)
            }
        },
        exclude_trace: args
            .get("exclude_trace")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
    };
    match admin_log_list(&ctx.pool, ctx.owner_iid, req).await {
        Ok(res) => {
            let logs = res.logs.iter().map(log_to_json).collect::<Vec<_>>();
            Ok(json!({
                "ok": true,
                "tool": "admin.log.tail",
                "subject_uid": if subject_iid > 0 { json!(subject_iid) } else { json!(null) },
                "global": global,
                "count": logs.len(),
                "logs": logs,
            }))
        }
        Err(e) => Ok(admin_err_json(e)),
    }
}

pub async fn admin_trace_get_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.trace.get").await {
        return Ok(v);
    }
    let req_id = arg_str(args, "req_id");
    let subject_iid = if arg_i64(args, "subject_uid") > 0 {
        arg_i64(args, "subject_uid")
    } else if !arg_str(args, "subject_handle").is_empty() {
        match subject_iid_resolve(&ctx.pool, args).await {
            Ok(id) => id,
            Err(e) => return Ok(json!({ "ok": false, "tool": "admin.trace.get", "error": e })),
        }
    } else {
        0
    };
    let limit = arg_i64(args, "limit") as i32;
    match admin_log_trace(&ctx.pool, ctx.owner_iid, &req_id, subject_iid, limit).await {
        Ok(mut v) => {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("tool".into(), json!("admin.trace.get"));
            }
            Ok(v)
        }
        Err(e) => Ok(admin_err_json(e)),
    }
}

pub async fn admin_msg_get_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.msg.get").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.msg.get", "error": e })),
    };
    let msg_id = arg_i64(args, "msg_id");
    let req_id = arg_str(args, "req_id");
    match admin_msg_get(&ctx.pool, ctx.owner_iid, msg_id, &req_id, subject_iid).await {
        Ok(mut v) => {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("tool".into(), json!("admin.msg.get"));
                obj.insert("subject_uid".into(), json!(subject_iid));
            }
            Ok(v)
        }
        Err(e) => Ok(admin_err_json(e)),
    }
}

pub async fn admin_msg_find_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Err(v) = require_root_json(ctx, "admin.msg.find").await {
        return Ok(v);
    }
    let subject_iid = match subject_iid_resolve(&ctx.pool, args).await {
        Ok(id) => id,
        Err(e) => return Ok(json!({ "ok": false, "tool": "admin.msg.find", "error": e })),
    };
    let q = arg_str(args, "q");
    let chat_id = arg_i64(args, "chat_id");
    let limit = arg_i64(args, "limit") as i32;
    match admin_msg_find(&ctx.pool, ctx.owner_iid, subject_iid, &q, chat_id, limit).await {
        Ok(mut v) => {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("tool".into(), json!("admin.msg.find"));
                obj.insert("subject_uid".into(), json!(subject_iid));
            }
            Ok(v)
        }
        Err(e) => Ok(admin_err_json(e)),
    }
}

tool! {
    struct: AdminLogTailTool,
    name: "admin.log.tail",
    aliases: ["admin_log_tail"],
    description: "Root only: tail ai.log for debugging (errors, events, trace). Default: one user via subject_handle/subject_uid. Set global true only for platform-wide scans (slower). Redacts secrets in meta.",
    topics: ["staff"],
    always: ["staff"],
    rag_phrases: [
        "tail log", "cek log error", "ai.log", "log platform", "trace log",
        "debug server log", "lihat log user",
    ],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "User whose logs to read; omit when global true", optional),
        subject_handle: (string, "User alien_id when not global", optional),
        global: (boolean, "Platform-wide log scan (root only); do not use for normal user debug", optional, default = false),
        q: (string, "ILIKE filter on text/topic/subject", optional, default = ""),
        kind: (string, "Log kind filter", optional, default = ""),
        topic: (string, "Log topic filter", optional, default = ""),
        event_kind: (string, "Domain event_kind filter", optional, default = ""),
        class: (string, "event | error | trace", optional, default = ""),
        subject_prefix: (string, "Subject prefix filter", optional, default = ""),
        exclude_trace: (boolean, "Only event/error rows", optional, default = false),
        since_minutes: (integer, "Relative window in minutes", optional, default = 0),
        since_ms: (integer, "Absolute since epoch ms", optional, default = 0),
        until_ms: (integer, "Until epoch ms", optional, default = 0),
        limit: (integer, "Max rows 1-500", optional, default = 100),
        before_id: (integer, "Pagination: rows older than this log id", optional, default = 0),
    },
    execute: |args, ctx| admin_log_tail_exec(ctx, &args).await
}

tool! {
    struct: AdminTraceGetTool,
    name: "admin.trace.get",
    aliases: ["admin_trace_get", "trace_get"],
    description: "Root only: full ai.log trace for a req_id (tool filter, LLM hops, tools). Pass subject_uid when known to avoid cross-tenant ambiguity.",
    topics: ["staff"],
    always: ["general", "staff"],
    rag_phrases: [
        "trace req", "debug turn", "lihat trace", "analyze trace", "req_id trace",
        "kenapa error turn", "tool filter trace",
    ],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        req_id: (string, "Turn request id from message or log", required),
        subject_uid: (integer, "Owner user id when known", optional, default = 0),
        subject_handle: (string, "Resolve owner via alien_id (optional)", optional),
        limit: (integer, "Max trace rows", optional, default = 200),
    },
    execute: |args, ctx| admin_trace_get_exec(ctx, &args).await
}

tool! {
    struct: AdminMsgGetTool,
    name: "admin.msg.get",
    aliases: ["admin_msg_get", "msg_get"],
    description: "Root only: get chat message(s) by msg_id or req_id for a user, with linked trace rows. Requires subject_uid or subject_handle.",
    topics: ["staff"],
    always: ["staff"],
    rag_phrases: ["get message", "msg id", "req id message", "isi pesan error"],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "Message owner user id", optional),
        subject_handle: (string, "Message owner alien_id", optional),
        msg_id: (integer, "Single message id", optional, default = 0),
        req_id: (string, "All messages in turn", optional, default = ""),
    },
    execute: |args, ctx| admin_msg_get_exec(ctx, &args).await
}

tool! {
    struct: AdminMsgFindTool,
    name: "admin.msg.find",
    aliases: ["admin_msg_find", "msg_find"],
    description: "Root only: search a user's chat messages by content substring. Requires subject_uid or subject_handle.",
    topics: ["staff"],
    always: ["staff"],
    rag_phrases: ["cari pesan", "search message", "find chat text", "user said"],
    requires_global_roles: ["root"],
    readonly: true,
    parameters: {
        subject_uid: (integer, "User identity id", optional),
        subject_handle: (string, "User alien_id", optional),
        q: (string, "Substring to match in content", required),
        chat_id: (integer, "Optional chat filter", optional, default = 0),
        limit: (integer, "Max hits 1-50", optional, default = 20),
    },
    execute: |args, ctx| admin_msg_find_exec(ctx, &args).await
}
