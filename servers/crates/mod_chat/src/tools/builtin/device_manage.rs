use anyhow::Result;
use chrono::Utc;
use c35_mod_device::device_unpair_notify;
use c35_mod_identity::{identity_delete, identity_grant_patch, identity_list, identity_put};
use c35_proto::{
    IdentityListRow, ReqIdentityDelete, ReqIdentityGrantPatch, ReqIdentityList, ReqIdentityPut,
};
use serde_json::{json, Value};

use crate::tool;
use crate::tools::builtin::device::resolve_device_iid;
use crate::tools::context::ToolContext;

const DEVICE_KINDS: &[&str] = &["remote", "iot"];

fn cloud_online_from_meta(meta: &Value) -> bool {
    if meta.get("online").and_then(|v| v.as_bool()) == Some(false) {
        return false;
    }
    let now = Utc::now().timestamp_millis();
    let last = meta
        .get("last_seen_ts_ms")
        .or_else(|| meta.get("last_seen_ms"))
        .or_else(|| meta.get("last_seen"))
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    if last <= 0 {
        return meta.get("online").and_then(|v| v.as_bool()) == Some(true);
    }
    now - last < 120_000
}

fn parse_identity_meta(meta_json: &str) -> Value {
    if meta_json.trim().is_empty() {
        return json!({});
    }
    serde_json::from_str(meta_json).unwrap_or_else(|_| json!({}))
}

pub fn device_row_llm(row: &IdentityListRow) -> Value {
    let id = row.identity.as_ref();
    let meta = id
        .map(|i| parse_identity_meta(&i.meta_json))
        .unwrap_or_else(|| json!({}));
    json!({
        "device_iid": id.map(|i| i.iid).unwrap_or(0),
        "name": id.map(|i| i.name.as_str()).unwrap_or(""),
        "alien_id": id.map(|i| i.alien_id.as_str()).unwrap_or(""),
        "kind": id.map(|i| i.kind.as_str()).unwrap_or(""),
        "type": id.map(|i| i.r#type.as_str()).unwrap_or(""),
        "is_pinned": row.is_pinned,
        "sort_order": row.sort_order,
        "archived": row.archived_ts_ms > 0,
        "cloud_online": cloud_online_from_meta(&meta),
    })
}

async fn device_rows_for_owner(
    ctx: &ToolContext,
    include_archived: bool,
) -> Result<Vec<IdentityListRow>> {
    let req = ReqIdentityList {
        kinds: DEVICE_KINDS.iter().map(|s| s.to_string()).collect(),
        include_archived,
    };
    let res = identity_list(&ctx.pool, ctx.owner_iid, req)
        .await
        .map_err(|e| anyhow::anyhow!(e.to_string()))?;
    Ok(res.rows)
}

async fn device_row_get(ctx: &ToolContext, device_iid: i64) -> Result<IdentityListRow, Value> {
    let rows = device_rows_for_owner(ctx, true)
        .await
        .map_err(|e| json!({ "ok": false, "error": e.to_string() }))?;
    rows.into_iter()
        .find(|r| r.identity.as_ref().map(|i| i.iid) == Some(device_iid))
        .ok_or_else(|| {
            json!({
                "ok": false,
                "error": "device not found or not accessible",
            })
        })
}

async fn assert_device_owner(ctx: &ToolContext, device_iid: i64) -> Result<IdentityListRow, Value> {
    let row = device_row_get(ctx, device_iid).await?;
    let owner = row.identity.as_ref().map(|i| i.owner_iid).unwrap_or(0);
    if owner != ctx.owner_iid {
        return Err(json!({
            "ok": false,
            "error": "forbidden",
        }));
    }
    Ok(row)
}

pub async fn device_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let include_archived = args
        .get("include_archived")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let rows = device_rows_for_owner(ctx, include_archived).await?;
    let items: Vec<Value> = rows.iter().map(device_row_llm).collect();
    Ok(json!({
        "ok": true,
        "tool": "device.list",
        "count": items.len(),
        "devices": items,
        "llm": { "count": items.len(), "devices": items },
    }))
}

pub async fn device_get_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let row = match device_row_get(ctx, device_iid).await {
        Ok(r) => r,
        Err(v) => return Ok(v),
    };
    let llm = device_row_llm(&row);
    Ok(json!({
        "ok": true,
        "tool": "device.get",
        "device": llm,
        "llm": llm,
    }))
}

pub async fn device_rename_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let row = match assert_device_owner(ctx, device_iid).await {
        Ok(r) => r,
        Err(v) => return Ok(v),
    };
    let id = row
        .identity
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("device row missing identity"))?;
    let name = args
        .get("name")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("");
    if name.is_empty() {
        return Ok(json!({
            "ok": false,
            "tool": "device.rename",
            "error": "name required",
        }));
    }
    match identity_put(
        &ctx.pool,
        ctx.nats.as_ref(),
        ctx.owner_iid,
        &ctx.req_id,
        ReqIdentityPut {
            iid: id.iid,
            kind: id.kind.clone(),
            r#type: id.r#type.clone(),
            name: name.to_string(),
            pic: id.pic.clone(),
            alien_id: id.alien_id.clone(),
            meta_json: id.meta_json.clone(),
        },
    )
    .await
    {
        Ok(res) => {
            let llm = res
                .row
                .as_ref()
                .map(device_row_llm)
                .unwrap_or_else(|| json!({ "device_iid": device_iid, "name": name }));
            Ok(json!({
                "ok": true,
                "tool": "device.rename",
                "device": llm,
                "llm": llm,
            }))
        }
        Err(e) => Ok(json!({
            "ok": false,
            "tool": "device.rename",
            "error": e.to_string(),
        })),
    }
}

pub async fn device_pin_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let pinned = args
        .get("pinned")
        .and_then(|v| v.as_bool())
        .unwrap_or(true);
    if device_row_get(ctx, device_iid).await.is_err() {
        return Ok(json!({
            "ok": false,
            "tool": "device.pin",
            "error": "device not found or not accessible",
        }));
    }
    match identity_grant_patch(
        &ctx.pool,
        ctx.owner_iid,
        ReqIdentityGrantPatch {
            resource_iid: device_iid,
            is_pinned: Some(pinned),
            sort_order: None,
            archived: None,
        },
    )
    .await
    {
        Ok(res) => {
            let llm = res.row.as_ref().map(device_row_llm).unwrap_or_else(|| json!({ "device_iid": device_iid }));
            Ok(json!({
                "ok": true,
                "tool": "device.pin",
                "device": llm,
                "llm": llm,
            }))
        }
        Err(e) => Ok(json!({
            "ok": false,
            "tool": "device.pin",
            "error": e.to_string(),
        })),
    }
}

pub async fn device_archive_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let archived = args
        .get("archived")
        .and_then(|v| v.as_bool())
        .unwrap_or(true);
    if device_row_get(ctx, device_iid).await.is_err() {
        return Ok(json!({
            "ok": false,
            "tool": "device.archive",
            "error": "device not found or not accessible",
        }));
    }
    match identity_grant_patch(
        &ctx.pool,
        ctx.owner_iid,
        ReqIdentityGrantPatch {
            resource_iid: device_iid,
            is_pinned: None,
            sort_order: None,
            archived: Some(archived),
        },
    )
    .await
    {
        Ok(res) => {
            let llm = res.row.as_ref().map(device_row_llm).unwrap_or_else(|| json!({ "device_iid": device_iid }));
            Ok(json!({
                "ok": true,
                "tool": "device.archive",
                "device": llm,
                "llm": llm,
            }))
        }
        Err(e) => Ok(json!({
            "ok": false,
            "tool": "device.archive",
            "error": e.to_string(),
        })),
    }
}

pub async fn device_unpair_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return Ok(v),
    };
    let row = match assert_device_owner(ctx, device_iid).await {
        Ok(r) => r,
        Err(v) => return Ok(v),
    };
    let kind = row
        .identity
        .as_ref()
        .map(|i| i.kind.as_str())
        .unwrap_or("");
    let name = row
        .identity
        .as_ref()
        .map(|i| i.name.as_str())
        .unwrap_or("");
    match identity_delete(
        &ctx.pool,
        ctx.owner_iid,
        ReqIdentityDelete { iid: device_iid },
    )
    .await
    {
        Ok(res) if res.ok => {
            if kind == "remote" || kind == "iot" {
                let _ = device_unpair_notify(ctx.nats.as_ref(), device_iid).await;
            }
            let llm = json!({
                "device_iid": device_iid,
                "name": name,
                "removed": true,
            });
            Ok(json!({
                "ok": true,
                "tool": "device.unpair",
                "llm": llm,
            }))
        }
        Ok(res) => Ok(json!({
            "ok": false,
            "tool": "device.unpair",
            "error": res.error,
        })),
        Err(e) => Ok(json!({
            "ok": false,
            "tool": "device.unpair",
            "error": e.to_string(),
        })),
    }
}

tool! {
    struct: DeviceGetTool,
    name: "device.get",
    aliases: ["device_get", "get device"],
    description: "Read one paired remote or IoT device (name, type, online hint, pin, archived).",
    topics: ["general", "device"],
    always: ["general", "device"],
    rag_phrases: ["device details", "info device", "status device"],
    ui_calling_key: "tool.device.get.calling",
    ui_done_key: "tool.device.get.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
    },
    execute: |args, ctx| device_get_exec(ctx, &args).await
}

tool! {
    struct: DeviceRenameTool,
    name: "device.rename",
    aliases: ["device_rename", "rename device", "ganti nama device"],
    description: "Rename a paired remote or IoT device you own. Does not change agent config or meta.",
    topics: ["general", "device"],
    always: ["general", "device"],
    rag_phrases: ["rename device", "rename pc", "ganti nama pc", "ganti nama device", "ubah nama device"],
    ui_calling_key: "tool.device.rename.calling",
    ui_done_key: "tool.device.rename.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        name: (string, "New display name", required),
    },
    execute: |args, ctx| device_rename_exec(ctx, &args).await
}

tool! {
    struct: DevicePinTool,
    name: "device.pin",
    aliases: ["device_pin", "pin device", "sematkan device"],
    description: "Pin or unpin a paired device in the Devices list (pinned devices sort first).",
    topics: ["general", "device"],
    always: ["general", "device"],
    rag_phrases: ["pin device", "pin pc", "sematkan device", "unpin device", "lepas pin device"],
    ui_calling_key: "tool.device.pin.calling",
    ui_done_key: "tool.device.pin.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        pinned: (boolean, "true to pin, false to unpin (default true)", optional, default = true),
    },
    execute: |args, ctx| device_pin_exec(ctx, &args).await
}

tool! {
    struct: DeviceArchiveTool,
    name: "device.archive",
    aliases: ["device_archive", "archive device", "arsipkan device"],
    description: "Archive or restore a paired device (hidden from default list without deleting the agent).",
    topics: ["general", "device"],
    always: ["general", "device"],
    rag_phrases: ["archive device", "hide device", "arsipkan device", "restore device", "unarchive device"],
    ui_calling_key: "tool.device.archive.calling",
    ui_done_key: "tool.device.archive.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        archived: (boolean, "true to archive, false to restore (default true)", optional, default = true),
    },
    execute: |args, ctx| device_archive_exec(ctx, &args).await
}

tool! {
    struct: DeviceUnpairTool,
    name: "device.unpair",
    aliases: ["device_unpair", "remove device", "unpair device", "hapus device"],
    description: "Remove a paired remote or IoT device from your account and notify the agent to disconnect. Destructive — use only when the user clearly asks to remove or unpair.",
    topics: ["general", "device"],
    always: ["general", "device"],
    rag_phrases: ["unpair device", "remove device", "hapus device", "putuskan device", "delete device"],
    ui_calling_key: "tool.device.unpair.calling",
    ui_done_key: "tool.device.unpair.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
    },
    execute: |args, ctx| device_unpair_exec(ctx, &args).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn device_row_llm_includes_pin_and_online() {
        let row = IdentityListRow {
            identity: Some(c35_proto::IdentityRow {
                iid: 42,
                kind: "remote".into(),
                r#type: "windows".into(),
                alien_id: String::new(),
                name: "Office".into(),
                pic: String::new(),
                meta_json: r#"{"last_seen_ts_ms":0}"#.into(),
                owner_iid: 99000,
                updated_ts_ms: 0,
            }),
            grant_role: "admin".into(),
            is_pinned: true,
            sort_order: 10,
            archived_ts_ms: 0,
        };
        let v = device_row_llm(&row);
        assert_eq!(v["device_iid"], 42);
        assert_eq!(v["is_pinned"], true);
        assert_eq!(v["name"], "Office");
    }
}
