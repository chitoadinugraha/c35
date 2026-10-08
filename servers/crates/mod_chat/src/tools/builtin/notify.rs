use std::collections::HashMap;
use std::sync::OnceLock;

use anyhow::anyhow;
use c35_fcm::Fcm;
use c35_mod_notify::{
    async_trait, notify_cancel, notify_list, notify_put, validate_notify_put, FcmSend, NotifyItem,
    NotifyPut, NotifyWhen,
};
use chrono::{DateTime, Utc};
use serde_json::{json, Value};

use crate::tool;
use crate::tools::ToolContext;

/// Adapts `c35_fcm::Fcm` to `FcmSend`. `from_env` is a no-op sender when credentials are missing.
struct EnvFcm(Fcm);

#[async_trait]
impl FcmSend for EnvFcm {
    async fn send_data(&self, tokens: &[String], data: HashMap<String, String>) {
        if let Err(err) = self.0.send_data(tokens, data).await {
            tracing::warn!("notify fcm send failed: {err}");
        }
    }
}

fn fcm() -> &'static EnvFcm {
    static FCM: OnceLock<EnvFcm> = OnceLock::new();
    FCM.get_or_init(|| EnvFcm(Fcm::from_env()))
}

fn bad_args(message: impl Into<String>) -> Value {
    json!({
        "error": "bad_args",
        "message": message.into(),
    })
}

fn row_json(row: &NotifyItem) -> Value {
    json!({
        "id": row.id,
        "status": row.status,
        "fire_at": row.fire_at.to_rfc3339(),
        "channels": row.channels,
    })
}

fn list_item_json(row: &NotifyItem) -> Value {
    json!({
        "id": row.id,
        "status": row.status,
        "fire_at": row.fire_at.to_rfc3339(),
        "channels": row.channels,
        "title": row.title,
        "body": row.body,
    })
}

fn arg_str<'a>(args: &'a Value, key: &str) -> Option<&'a str> {
    args.get(key)
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
}

pub async fn notify_schedule_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    if ctx.owner_iid <= 0 {
        return Ok(bad_args("caller is required"));
    }
    let Some(title) = arg_str(args, "title").map(str::to_string) else {
        return Ok(bad_args("title is required"));
    };
    let Some(body) = arg_str(args, "body").map(str::to_string) else {
        return Ok(bad_args("body is required"));
    };

    let when = match arg_str(args, "when").unwrap_or("delay") {
        "delay" => NotifyWhen::Delay,
        "turn" => NotifyWhen::Turn,
        _ => return Ok(bad_args("when must be delay or turn")),
    };

    let route_json = match args.get("route") {
        None | Some(Value::Null) => json!({}),
        Some(v) if v.is_object() => v.clone(),
        Some(_) => return Ok(bad_args("route must be an object")),
    };

    let (delay_sec, fire_at) = if when == NotifyWhen::Turn {
        (0, None)
    } else {
        match parse_delay(args) {
            Ok(pair) => pair,
            Err(message) => return Ok(bad_args(message)),
        }
    };

    let put = NotifyPut {
        owner_iid: ctx.owner_iid,
        title,
        body,
        delay_sec,
        fire_at,
        when,
        req_id: ctx.req_id.clone(),
        route_json,
    };
    if let Err(err) = validate_notify_put(&put) {
        return Ok(bad_args(err.to_string()));
    }

    // `c35_nats::Client` is `async_nats::Client` and already implements `NotifyNats`.
    let row = notify_put(&ctx.pool, ctx.nats.as_ref(), fcm(), put)
        .await
        .map_err(|e| anyhow!(e))?;
    Ok(row_json(&row))
}

fn parse_delay(args: &Value) -> Result<(u32, Option<DateTime<Utc>>), String> {
    let has_delay = args.get("delay_sec").is_some_and(|v| !v.is_null());
    let fire_raw = arg_str(args, "fire_at");
    if has_delay && fire_raw.is_some() {
        return Err("set delay_sec or fire_at, not both".into());
    }
    if let Some(raw) = fire_raw {
        let dt = DateTime::parse_from_rfc3339(raw)
            .map(|dt| dt.with_timezone(&Utc))
            .map_err(|_| "fire_at must be RFC3339".to_string())?;
        return Ok((0, Some(dt)));
    }
    if !has_delay {
        return Ok((0, None));
    }
    let Some(delay) = args.get("delay_sec").and_then(|v| v.as_i64()) else {
        return Err("delay_sec must be an integer".into());
    };
    if delay < 0 {
        return Err("delay_sec must be >= 0".into());
    }
    let delay_sec = u32::try_from(delay).map_err(|_| "delay_sec is too large".to_string())?;
    Ok((delay_sec, None))
}

pub async fn notify_list_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    if ctx.owner_iid <= 0 {
        return Ok(bad_args("caller is required"));
    }
    let limit = match args.get("limit") {
        None | Some(Value::Null) => 20,
        Some(v) => match v.as_i64() {
            Some(n) if (1..=50).contains(&n) => n as i32,
            Some(n) if n > 50 => 50,
            _ => return Ok(bad_args("limit must be an integer from 1 to 50")),
        },
    };
    let unread_only = match args.get("unread_only") {
        None | Some(Value::Null) => false,
        Some(v) => match v.as_bool() {
            Some(b) => b,
            None => return Ok(bad_args("unread_only must be a boolean")),
        },
    };
    let items = notify_list(&ctx.pool, ctx.owner_iid, limit, unread_only)
        .await
        .map_err(|e| anyhow!(e))?;
    Ok(json!({
        "items": items.iter().map(list_item_json).collect::<Vec<_>>(),
    }))
}

pub async fn notify_cancel_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    if ctx.owner_iid <= 0 {
        return Ok(bad_args("caller is required"));
    }
    let Some(id) = args.get("id").and_then(|v| v.as_i64()).filter(|id| *id > 0) else {
        return Ok(bad_args("id is required"));
    };
    let cancelled = notify_cancel(&ctx.pool, ctx.owner_iid, id)
        .await
        .map_err(|e| anyhow!(e))?;
    if !cancelled {
        return Ok(bad_args(
            "notification is not a scheduled or waiting row for this caller",
        ));
    }
    Ok(json!({
        "id": id,
        "status": "cancelled",
        "fire_at": Value::Null,
        "channels": "",
    }))
}

tool! {
    struct: NotifyScheduleTool,
    name: "notify.schedule",
    aliases: ["notify_schedule"],
    description: "Schedule a notification for the caller. title (required), body (required), delay_sec (seconds; 0 delivers now) or fire_at (RFC3339), when (delay or turn; default delay), route ({chat_id, path}).",
    topics: ["general"],
    rag_phrases: [
        "notify me", "remind me", "ingatkan", "kabari saya", "kasih tahu saya", "in 5 seconds",
    ],
    parameters: {
        title: (string, "Notification title", required),
        body: (string, "Notification body", required),
        delay_sec: (integer, "Seconds from now; 0 delivers immediately. Omit when fire_at is set.", optional),
        fire_at: (string, "RFC3339 timestamp. Omit when delay_sec is set.", optional),
        when: (string, "delay (default) or turn", optional),
        route: (object, "Optional route object {chat_id, path}", optional),
    },
    execute: |args, ctx| {
        notify_schedule_exec(ctx, &args).await
    }
}

tool! {
    struct: NotifyListTool,
    name: "notify.list",
    aliases: ["notify_list"],
    description: "List the caller's notifications. limit default 20 max 50. unread_only keeps status sent.",
    topics: ["general"],
    rag_phrases: [
        "notify me", "remind me", "ingatkan", "kabari saya", "kasih tahu saya",
    ],
    readonly: true,
    parameters: {
        limit: (integer, "Max rows, default 20, max 50", optional),
        unread_only: (boolean, "When true, only status sent", optional),
    },
    execute: |args, ctx| {
        notify_list_exec(ctx, &args).await
    }
}

tool! {
    struct: NotifyCancelTool,
    name: "notify.cancel",
    aliases: ["notify_cancel"],
    description: "Cancel one notification by id. Only a scheduled or waiting row owned by the caller.",
    topics: ["general"],
    rag_phrases: [
        "notify me", "remind me", "ingatkan",
    ],
    parameters: {
        id: (integer, "Notification id", required),
    },
    execute: |args, ctx| {
        notify_cancel_exec(ctx, &args).await
    }
}
