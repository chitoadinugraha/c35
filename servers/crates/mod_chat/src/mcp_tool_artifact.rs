use base64::Engine;
use c35_mod_file::{
    cas_bytes_get, cas_dir_default, cas_sign, tool_artifact_get, tool_artifact_list_by_req,
    ToolArtifactRow, CAS_URL_TTL,
};
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::mcp_agent::mcp_agent_owner_allowed;

fn cas_secret_from_env() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

pub fn mcp_json_i64(v: &Value, key: &str) -> Option<i64> {
    let raw = v.get(key)?;
    if let Some(n) = raw.as_i64() {
        return Some(n);
    }
    raw.as_str()?.trim().parse().ok()
}

fn artifact_json(row: &ToolArtifactRow, secret: &str) -> Value {
    let url = cas_sign(secret, &row.hash_blake3, CAS_URL_TTL);
    json!({
        "artifact_id": row.id.to_string(),
        "req_id": row.req_id,
        "tool_call_id": row.tool_call_id,
        "tool_id": row.tool_id,
        "device_iid": row.device_iid.to_string(),
        "hash_blake3": row.hash_blake3,
        "image_hash": row.hash_blake3,
        "image_url": url,
        "width": row.width,
        "height": row.height,
        "meta": row.meta_json,
        "created_ts": row.created_ts.to_rfc3339(),
        "expires_ts": row.expires_ts.to_rfc3339(),
    })
}

pub async fn mcp_tool_artifact_list(pool: &PgPool, owner_iid: i64, args: &Value) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return json!({ "ok": false, "error": "owner not allowed", "owner_iid": owner_iid });
    }
    let req_id = args.get("req_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    if req_id.is_empty() {
        return json!({ "ok": false, "error": "args_json.req_id required" });
    }
    let tool_id = args.get("tool_id").and_then(|v| v.as_str());
    match tool_artifact_list_by_req(pool, owner_iid, req_id, tool_id).await {
        Ok(rows) => {
            let secret = cas_secret_from_env();
            let artifacts: Vec<Value> = rows.iter().map(|r| artifact_json(r, &secret)).collect();
            json!({
                "ok": true,
                "owner_iid": owner_iid,
                "req_id": req_id,
                "count": artifacts.len(),
                "artifacts": artifacts,
            })
        }
        Err(e) => json!({ "ok": false, "error": e.to_string() }),
    }
}

pub async fn mcp_tool_artifact_fetch(pool: &PgPool, owner_iid: i64, args: &Value) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return json!({ "ok": false, "error": "owner not allowed", "owner_iid": owner_iid });
    }
    let artifact_id = mcp_json_i64(args, "artifact_id").or_else(|| mcp_json_i64(args, "id"));
    if artifact_id.unwrap_or(0) <= 0 {
        return json!({ "ok": false, "error": "args_json.artifact_id required" });
    }
    let artifact_id = artifact_id.unwrap();
    let include_base64 = args.get("include_base64").and_then(|v| v.as_bool()).unwrap_or(false);
    let row = match tool_artifact_get(pool, owner_iid, artifact_id).await {
        Ok(Some(r)) => r,
        Ok(None) => return json!({ "ok": false, "error": "artifact not found or expired" }),
        Err(e) => return json!({ "ok": false, "error": e.to_string() }),
    };
    let secret = cas_secret_from_env();
    let mut out = artifact_json(&row, &secret);
    if let Some(obj) = out.as_object_mut() {
        obj.insert("ok".into(), json!(true));
        obj.insert("mime_type".into(), json!("image/jpeg"));
    }
    if include_base64 {
        match cas_bytes_get(pool, &cas_dir_default(), &row.hash_blake3).await {
            Ok((bytes, mime)) => {
                let b64 = base64::engine::general_purpose::STANDARD.encode(&bytes);
                if let Some(obj) = out.as_object_mut() {
                    obj.insert("image_base64".into(), json!(b64));
                    if !mime.is_empty() {
                        obj.insert("mime_type".into(), json!(mime));
                    }
                    obj.insert("bytes".into(), json!(bytes.len()));
                }
            }
            Err(e) => {
                if let Some(obj) = out.as_object_mut() {
                    obj.insert("fetch_error".into(), json!(e.to_string()));
                }
            }
        }
    }
    out
}

pub async fn mcp_trace_screenshot(pool: &PgPool, owner_iid: i64, args: &Value) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return json!({ "ok": false, "error": "owner not allowed", "owner_iid": owner_iid });
    }
    let req_id = args.get("req_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    if req_id.is_empty() {
        return json!({ "ok": false, "error": "args_json.req_id required" });
    }
    let include_base64 = args.get("include_base64").and_then(|v| v.as_bool()).unwrap_or(false);
    let rows = match tool_artifact_list_by_req(pool, owner_iid, req_id, None).await {
        Ok(r) => r,
        Err(e) => return json!({ "ok": false, "error": e.to_string() }),
    };
    let shot = rows
        .iter()
        .rev()
        .find(|r| r.tool_id == "device.screenshot" || r.tool_id == "device.input");
    let Some(row) = shot else {
        return json!({
            "ok": false,
            "error": "no device screenshot artifact for req_id",
            "req_id": req_id,
            "artifact_count": rows.len(),
        });
    };
    let fetch_args = json!({
        "artifact_id": row.id.to_string(),
        "include_base64": include_base64,
    });
    mcp_tool_artifact_fetch(pool, owner_iid, &fetch_args).await
}
