use anyhow::{bail, Context, Result};
use base64::Engine;
use c35_mod_drive::{drive_normalize_path, drive_tree_list};
use c35_mod_file::{cas_bytes_get, cas_dir_default, cas_sign, CAS_URL_TTL};
use serde_json::{json, Value};
use sqlx::Row;

use crate::tool;
use crate::tools::context::ToolContext;

const DRIVE_READ_MAX_BYTES: usize = 256 * 1024;

async fn drive_path_row(ctx: &ToolContext, path: &str) -> Result<(String, i64, String), Value> {
    let path = drive_normalize_path(path);
    if path.is_empty() {
        return Err(json!({ "ok": false, "error": "path is required" }));
    }
    let row = sqlx::query(
        r#"
        SELECT hash_blake3, size_bytes
        FROM ai.drive_file
        WHERE owner_iid = $1 AND path = $2 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(ctx.owner_iid)
    .bind(&path)
    .fetch_optional(&ctx.pool)
    .await
    .map_err(|e| json!({ "ok": false, "error": e.to_string() }))?;
    let Some(row) = row else {
        return Err(json!({ "ok": false, "error": "file not found", "path": path }));
    };
    let hash: String = row.get("hash_blake3");
    let size: i64 = row.get("size_bytes");
    Ok((path, size, hash))
}

async fn drive_list_exec(args: Value, ctx: &ToolContext) -> Result<Value> {
    let prefix = args
        .get("path_prefix")
        .and_then(|v| v.as_str())
        .map(drive_normalize_path)
        .unwrap_or_default();
    let items = drive_tree_list(&ctx.pool, ctx.owner_iid)
        .await
        .context("drive tree list")?;
    let files: Vec<Value> = items
        .iter()
        .filter(|e| prefix.is_empty() || e.path.starts_with(&prefix))
        .map(|e| {
            json!({
                "path": e.path,
                "name": e.name,
                "hash": e.hash,
                "size_bytes": e.size,
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "path_prefix": prefix,
        "files": files,
        "count": files.len(),
    }))
}

async fn drive_read_exec(args: Value, ctx: &ToolContext) -> Result<Value> {
    let path = args.get("path").and_then(|v| v.as_str()).unwrap_or_default();
    let (path, size, hash) = match drive_path_row(ctx, path).await {
        Ok(v) => v,
        Err(j) => return Ok(j),
    };
    if size > DRIVE_READ_MAX_BYTES as i64 {
        bail!(
            "file too large for inline read ({} bytes; max {})",
            size,
            DRIVE_READ_MAX_BYTES
        );
    }
    let (bytes, mime) = cas_bytes_get(&ctx.pool, &cas_dir_default(), &hash)
        .await
        .context("read blob")?;
    let public_origin = std::env::var("C35_PUBLIC_ORIGIN")
        .ok()
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "https://ai.alienai.id".into());
    let cas_secret = std::env::var("CAS_SECRET").unwrap_or_default();
    let signed = cas_sign(&cas_secret, &hash, CAS_URL_TTL);
    let origin = public_origin.trim_end_matches('/');
    let url = format!("{origin}{signed}");
    let is_text = mime.starts_with("text/")
        || mime == "application/json"
        || mime == "application/xml"
        || mime.ends_with("+json")
        || mime.ends_with("+xml");
    let mut out = json!({
        "ok": true,
        "path": path,
        "hash": hash,
        "size_bytes": size,
        "mime_type": mime,
        "url": url,
    });
    if is_text && bytes.len() <= DRIVE_READ_MAX_BYTES {
        out["text"] = json!(String::from_utf8_lossy(&bytes));
    } else {
        out["data_base64"] = json!(base64::engine::general_purpose::STANDARD.encode(&bytes));
    }
    Ok(out)
}

tool! {
    struct: DriveListTool,
    name: "drive.list",
    aliases: ["drive_list"],
    description: "List files on the owner's Alien AI Drive (cloud A: volume). Returns relative paths, hashes, and sizes.",
    topics: ["general", "device"],
    rag_phrases: ["alien ai drive", "cloud drive", "drive files", "a drive"],
    readonly: true,
    parameters: {
        path_prefix: (string, "Optional path prefix filter (e.g. reports/)", optional),
    },
    execute: |args, ctx| {
        drive_list_exec(args, ctx).await
    }
}

tool! {
    struct: DriveReadTool,
    name: "drive.read",
    aliases: ["drive_read"],
    description: "Read a small file from Alien AI Drive by relative path. Returns UTF-8 text when possible, else base64. Max 256KB inline.",
    topics: ["general", "device"],
    rag_phrases: ["read drive file", "open file on drive", "alien ai drive"],
    readonly: true,
    parameters: {
        path: (string, "Relative drive path (e.g. notes/todo.txt)", required),
    },
    execute: |args, ctx| {
        match drive_read_exec(args, ctx).await {
            Ok(v) => Ok(v),
            Err(e) => Ok(json!({ "ok": false, "error": e.to_string() })),
        }
    }
}