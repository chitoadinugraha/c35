use crate::mention_context::device_iid_resolve;
use crate::tool;
use crate::tools::context::ToolContext;
use crate::tools::device_screenshot_artifact::device_screenshot_attach_artifact;
use base64::Engine as _;
use c35_mod_device::{remote_device_browser_invoke, remote_device_task_run_enqueue};
use c35_mod_file::{cas_bytes_get, cas_dir_default};
use serde_json::{json, Value};

const MAX_BROWSER_UPLOAD_BYTES: usize = 32 * 1024 * 1024;

fn arg_i64(v: &Value, key: &str) -> i64 {
    match v.get(key) {
        Some(x) if x.is_i64() => x.as_i64().unwrap_or(0),
        Some(x) if x.is_u64() => x.as_u64().unwrap_or(0) as i64,
        Some(x) => x.as_str().and_then(|s| s.trim().parse().ok()).unwrap_or(0),
        None => 0,
    }
}

fn arg_str(v: &Value, key: &str) -> String {
    v.get(key)
        .and_then(|x| x.as_str())
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

fn browser_fail(error: impl Into<String>) -> Value {
    json!({
        "ok": false,
        "error": error.into(),
        "fail_class": "fatal_env",
        "retryable": false,
    })
}

fn resolve_device_iid(args: &Value, ctx: &ToolContext) -> Result<i64, Value> {
    let direct = arg_i64(args, "device_iid");
    device_iid_resolve(&ctx.mention, &ctx.mention_ids, direct).map_err(|e| browser_fail(e.to_string()))
}

async fn browser_invoke(
    args: &Value,
    ctx: &ToolContext,
    method: &str,
    params: Value,
    timeout_sec: u32,
) -> Value {
    let device_iid = match resolve_device_iid(args, ctx) {
        Ok(iid) => iid,
        Err(v) => return v,
    };
    match remote_device_browser_invoke(
        &ctx.pool,
        ctx.nats.as_ref(),
        ctx.owner_iid,
        device_iid,
        method,
        params,
        timeout_sec,
    )
    .await
    {
        Ok(v) => {
            if v.get("ok").and_then(|x| x.as_bool()) == Some(false) {
                return browser_fail(
                    v.get("error")
                        .and_then(|x| x.as_str())
                        .unwrap_or("browser command failed"),
                );
            }
            let mut out = v;
            if out.get("device_iid").is_none() {
                if let Some(obj) = out.as_object_mut() {
                    obj.insert("device_iid".into(), json!(device_iid));
                }
            }
            out
        }
        Err(e) => browser_fail(e),
    }
}
tool! {
    struct: BrowserTaskRunTool,
    name: "browser.task.run",
    aliases: ["browser_task_run", "remote_browser_task"],
    description: "Run automation steps on a paired Remote browser device (type=browser). Playwright or Chrome extension (MV3): navigate, click, fill, extract, wait, tab ops. Async on the agent; returns run_id.",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["remote browser", "browser automation", "playwright", "open url on browser", "scrape page", "browser task"],
    ui_calling_key: "tool.browser.task.run.calling",
    ui_done_key: "tool.browser.task.run.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        slot_id: (string, "Named browser slot profile (default: default)", optional),
        tab_id: (string, "Optional active tab id for the run", optional),
        steps: (array, "Automation steps (navigate, click, fill, extract, tab_* ops)", required),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };
        let slot_raw = arg_str(&args, "slot_id");
        let slot_id = if slot_raw.is_empty() { "default".to_string() } else { slot_raw };
        let steps = args.get("steps").cloned().unwrap_or(json!([]));
        if !steps.is_array() || steps.as_array().map(|a| a.is_empty()).unwrap_or(true) {
            return Ok(browser_fail("steps must be a non-empty array"));
        }
        let mut prompt = json!({ "slot_id": slot_id.as_str(), "steps": steps });
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            prompt["tab_id"] = json!(tab_id);
        }
        let prompt_str = prompt.to_string();
        match remote_device_task_run_enqueue(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            ctx.chat_id,
            &ctx.req_id,
            &prompt_str,
            0,
            "",
        ).await {
            Ok(run_id) => Ok(json!({
                "ok": true,
                "device_iid": device_iid,
                "run_id": run_id,
                "status": "queued",
                "slot_id": slot_id,
            })),
            Err(e) => Ok(browser_fail(e)),
        }
    }
}

tool! {
    struct: BrowserPageObserveTool,
    name: "browser.page.observe",
    aliases: ["browser_page_observe"],
    description: "Accessibility snapshot (ARIA tree or body text) plus url/title from a Remote browser tab.",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["what is on the browser page", "browser snapshot", "page structure"],
    ui_calling_key: "tool.browser.page.observe.calling",
    ui_done_key: "tool.browser.page.observe.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        tab_id: (string, "Optional tab id (active tab if omitted)", optional),
        max_chars: (integer, "Max characters in snapshot (default 8000)", optional),
    },
    execute: |args, ctx| {
        let mut params = json!({});
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            params["tab_id"] = json!(tab_id);
        }
        let max_chars = arg_i64(&args, "max_chars");
        if max_chars > 0 {
            params["max_chars"] = json!(max_chars);
        }
        Ok(browser_invoke(&args, ctx, "page.observe", params, 90).await)
    }
}

tool! {
    struct: BrowserPageScreenshotTool,
    name: "browser.page.screenshot",
    aliases: ["browser_page_screenshot", "remote_browser_screenshot"],
    description: "Capture a JPEG screenshot of a Remote browser tab (Playwright or Chrome extension). Returns CAS artifact for vision/debug.",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["browser screenshot", "capture browser tab", "see browser page", "cloudflare check browser"],
    ui_calling_key: "tool.browser.page.screenshot.calling",
    ui_done_key: "tool.browser.page.screenshot.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        tab_id: (string, "Optional tab id (active tab if omitted)", optional),
        quality: (integer, "JPEG quality 40-95 (default 80)", optional),
        marker: (boolean, "Draw red action marker at marker_x/marker_y or last pointer input on the agent (default true)", optional),
        marker_x: (number, "Normalized X (0..1) for the red marker", optional),
        marker_y: (number, "Normalized Y (0..1) for the red marker", optional),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };
        let mut params = json!({});
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            params["tab_id"] = json!(tab_id);
        }
        let quality = arg_i64(&args, "quality");
        if quality > 0 {
            params["quality"] = json!(quality);
        }
        params["marker"] = json!(args.get("marker").and_then(|v| v.as_bool()).unwrap_or(true));
        if let Some(mx) = args.get("marker_x").and_then(|v| v.as_f64()) {
            params["marker_x"] = json!(mx);
        }
        if let Some(my) = args.get("marker_y").and_then(|v| v.as_f64()) {
            params["marker_y"] = json!(my);
        }
        let mut out = browser_invoke(&args, ctx, "page.screenshot", params, 90).await;
        if out.get("ok").and_then(|x| x.as_bool()) != Some(true) {
            return Ok(out);
        }
        let shot = out.get("screenshot").cloned().unwrap_or(Value::Null);
        let jpeg_b64 = shot.get("jpeg_b64").and_then(|x| x.as_str()).unwrap_or("");
        let width = shot.get("width").and_then(|x| x.as_u64()).unwrap_or(0) as u32;
        let height = shot.get("height").and_then(|x| x.as_u64()).unwrap_or(0) as u32;
        let marker_applied = shot
            .get("marker_applied")
            .and_then(|x| x.as_bool())
            .unwrap_or(false);
        if !jpeg_b64.is_empty() {
            if let Ok(bytes) = base64::engine::general_purpose::STANDARD.decode(jpeg_b64) {
                device_screenshot_attach_artifact(
                    &ctx,
                    "browser.page.screenshot",
                    device_iid,
                    &bytes,
                    width,
                    height,
                    false,
                    marker_applied,
                    0,
                    &mut out,
                )
                .await;
                if let Some(obj) = out.as_object_mut() {
                    if let Some(sc) = obj.get_mut("screenshot").and_then(|v| v.as_object_mut()) {
                        sc.remove("jpeg_b64");
                    }
                    obj.insert("width".into(), json!(width));
                    obj.insert("height".into(), json!(height));
                    obj.insert(
                        "hint".into(),
                        json!(format!(
                            "Captured {}x{} browser tab screenshot (artifact attached).",
                            width,
                            height
                        )),
                    );
                }
            }
        }
        Ok(out)
    }
}

tool! {
    struct: BrowserPageExtractTool,
    name: "browser.page.extract",
    aliases: ["browser_page_extract"],
    description: "Extract visible text from a CSS selector on a Remote browser tab.",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["extract from page", "read selector", "scrape element", "get text from browser"],
    ui_calling_key: "tool.browser.page.extract.calling",
    ui_done_key: "tool.browser.page.extract.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        selector: (string, "CSS selector to read", required),
        tab_id: (string, "Optional tab id", optional),
        result_key: (string, "Result key name (default: selector)", optional),
    },
    execute: |args, ctx| {
        let selector = arg_str(&args, "selector");
        if selector.is_empty() {
            return Ok(browser_fail("selector required"));
        }
        let mut params = json!({ "selector": selector });
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            params["tab_id"] = json!(tab_id);
        }
        let as_key = arg_str(&args, "result_key");
        if !as_key.is_empty() {
            params["as"] = json!(as_key);
        }
        Ok(browser_invoke(&args, ctx, "page.extract", params, 90).await)
    }
}

tool! {
    struct: BrowserPageActTool,
    name: "browser.page.act",
    aliases: ["browser_page_act"],
    description: "Single UI action on a Remote browser tab: click, fill, or press (press requires selector until key IPC ships).",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["click button in browser", "fill form browser", "browser click", "type in browser"],
    ui_calling_key: "tool.browser.page.act.calling",
    ui_done_key: "tool.browser.page.act.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        action: (string, "click | fill | press", required),
        selector: (string, "CSS selector target", optional),
        text: (string, "Text for fill or press", optional),
        tab_id: (string, "Optional tab id", optional),
    },
    execute: |args, ctx| {
        let action = arg_str(&args, "action");
        if action.is_empty() {
            return Ok(browser_fail("action required"));
        }
        let mut params = json!({ "action": action });
        let selector = arg_str(&args, "selector");
        if !selector.is_empty() {
            params["selector"] = json!(selector);
        }
        let text = arg_str(&args, "text");
        if !text.is_empty() {
            params["text"] = json!(text);
        }
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            params["tab_id"] = json!(tab_id);
        }
        Ok(browser_invoke(&args, ctx, "page.act", params, 90).await)
    }
}

tool! {
    struct: BrowserTabsTool,
    name: "browser.tabs",
    aliases: ["browser_tabs"],
    description: "List, open, activate, or close tabs on a paired Remote browser device.",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["browser tabs", "open tab", "close tab", "switch tab", "new browser tab"],
    ui_calling_key: "tool.browser.tabs.calling",
    ui_done_key: "tool.browser.tabs.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        op: (string, "list | new | activate | close", required),
        tab_id: (string, "Tab id for activate/close", optional),
        url: (string, "URL for op=new", optional),
    },
    execute: |args, ctx| {
        let op = arg_str(&args, "op");
        if op.is_empty() {
            return Ok(browser_fail("op required"));
        }
        let mut params = json!({ "op": op });
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            params["tab_id"] = json!(tab_id);
        }
        let url = arg_str(&args, "url");
        if !url.is_empty() {
            params["url"] = json!(url);
        }
        Ok(browser_invoke(&args, ctx, "tabs", params, 45).await)
    }
}

tool! {
    struct: BrowserExtensionTool,
    name: "browser.extension",
    aliases: ["browser_extension"],
    description: "Chrome MV3 extension on a paired type=browser device: read manifest version or reload the service worker after syncing dist/ to the install folder (no chrome://extensions click).",
    topics: ["device", "browser"],
    rag_phrases: [
        "reload chrome extension", "reload extension", "extension version", "refresh alien ai remote",
        "mv3 reload", "service worker reload"
    ],
    ui_calling_key: "tool.browser.extension.calling",
    ui_done_key: "tool.browser.extension.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        op: (string, "version | reload", required),
    },
    execute: |args, ctx| {
        let op = arg_str(&args, "op").to_lowercase();
        let method = match op.as_str() {
            "version" | "get_version" => "extension.version",
            "reload" | "refresh" => "extension.reload",
            "" => return Ok(browser_fail("op required (version | reload)")),
            _ => return Ok(browser_fail("op must be version or reload")),
        };
        Ok(browser_invoke(&args, ctx, method, json!({}), 20).await)
    }
}

tool! {
    struct: BrowserSheetsAppendRowTool,
    name: "browser.sheets.append_row",
    aliases: ["browser_sheets_append_row"],
    description: "Fast path: append product + stock on an open Google Sheet (Chrome extension). Default columns B/C (Test Stock layout); override with product_col/stock_col.",
    topics: ["browser", "sheets"],
    rag_phrases: [
        "google sheet", "google sheets", "spreadsheet", "test stock", "append row sheet",
        "add row sheet", "stock sheet", "update inventory sheet"
    ],
    ui_calling_key: "tool.browser.sheets.append_row.calling",
    ui_done_key: "tool.browser.sheets.append_row.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        tab_id: (string, "Chrome tab id for the spreadsheet", required),
        product: (string, "Product name", required),
        stock: (string, "Stock count", required),
        row: (integer, "Sheet row number (default 7)", optional),
        product_col: (string, "Product column letter (default B)", optional),
        stock_col: (string, "Stock column letter (default C)", optional),
    },
    execute: |args, ctx| {
        let product = arg_str(&args, "product");
        let stock = arg_str(&args, "stock");
        let tab_id = arg_str(&args, "tab_id");
        if product.is_empty() || stock.is_empty() || tab_id.is_empty() {
            return Ok(browser_fail("tab_id, product, and stock are required"));
        }
        let mut params = json!({ "product": product, "stock": stock, "tab_id": tab_id });
        let row = arg_i64(&args, "row");
        if row > 0 {
            params["row"] = json!(row);
        }
        let product_col = arg_str(&args, "product_col");
        if !product_col.is_empty() {
            params["product_col"] = json!(product_col);
        }
        let stock_col = arg_str(&args, "stock_col");
        if !stock_col.is_empty() {
            params["stock_col"] = json!(stock_col);
        }
        Ok(browser_invoke(&args, ctx, "sheets.append_row", params, 60).await)
    }
}

tool! {
    struct: BrowserSheetsCellSetTool,
    name: "browser.sheets.cell_set",
    aliases: ["browser_sheets_cell_set", "browser_sheets_set_cell"],
    description: "Set one cell value on an open Google Sheet tab (Chrome extension CDP).",
    topics: ["browser", "sheets"],
    rag_phrases: ["google sheet", "set cell", "write cell spreadsheet", "update cell sheets"],
    ui_calling_key: "tool.browser.sheets.cell_set.calling",
    ui_done_key: "tool.browser.sheets.cell_set.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        tab_id: (string, "Chrome tab id for the spreadsheet", required),
        cell: (string, "Cell reference e.g. A7 or B3", required),
        value: (string, "Value to write", required),
    },
    execute: |args, ctx| {
        let tab_id = arg_str(&args, "tab_id");
        let cell = arg_str(&args, "cell");
        let value = args.get("value").map(|v| v.as_str().unwrap_or("").to_string()).unwrap_or_default();
        if tab_id.is_empty() || cell.is_empty() {
            return Ok(browser_fail("tab_id and cell are required"));
        }
        let params = json!({ "tab_id": tab_id, "cell": cell, "value": value });
        Ok(browser_invoke(&args, ctx, "sheets.cell_set", params, 60).await)
    }
}

tool! {
    struct: BrowserSheetsRowReadTool,
    name: "browser.sheets.row_read",
    aliases: [
        "browser_sheets_row_read",
        "browser_sheets_read_row",
        "browser_sheets_cell_read",
        "browser_sheets_read_cell",
    ],
    description: "Read cells on an open Google Sheet (Chrome extension). One cell: cell=B7. Row slice: row + start_col (default A) + columns (default 6). Test Stock product+stock: row, start_col B, columns 2.",
    topics: ["browser", "sheets"],
    rag_phrases: [
        "google sheet", "read row", "read cell", "get cell value spreadsheet", "stock list row",
    ],
    ui_calling_key: "tool.browser.sheets.row_read.calling",
    ui_done_key: "tool.browser.sheets.row_read.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        tab_id: (string, "Chrome tab id for the spreadsheet", required),
        cell: (string, "Single cell e.g. B7 (alternative to row)", optional),
        row: (integer, "Sheet row number (1-based); required if cell omitted", optional),
        start_col: (string, "First column letter when using row (default A)", optional),
        columns: (integer, "Column count from start_col (default 6, max 26; default 1 when cell set)", optional),
    },
    execute: |args, ctx| {
        let tab_id = arg_str(&args, "tab_id");
        if tab_id.is_empty() {
            return Ok(browser_fail("tab_id is required"));
        }
        let cell = arg_str(&args, "cell");
        let row = arg_i64(&args, "row");
        if cell.is_empty() && row < 1 {
            return Ok(browser_fail("cell (e.g. B7) or row (>=1) is required"));
        }
        let mut params = json!({ "tab_id": tab_id });
        if !cell.is_empty() {
            params["cell"] = json!(cell);
        } else {
            params["row"] = json!(row);
        }
        let start_col = arg_str(&args, "start_col");
        if !start_col.is_empty() {
            params["start_col"] = json!(start_col);
        }
        let columns = arg_i64(&args, "columns");
        if columns > 0 {
            params["columns"] = json!(columns);
        }
        Ok(browser_invoke(&args, ctx, "sheets.row_read", params, 90).await)
    }
}

tool! {
    struct: BrowserFileUploadTool,
    name: "browser.file.upload",
    aliases: ["browser_file_upload"],
    description: "Upload a chat attachment into a file input on a Remote browser page (CAS fetch to agent file.upload).",
    topics: ["device", "browser"],
    always: ["device", "browser"],
    rag_phrases: ["upload file browser", "attach file to form", "file input"],
    ui_calling_key: "tool.browser.file.upload.calling",
    ui_done_key: "tool.browser.file.upload.done",
    parameters: {
        device_iid: (integer, "Target remote browser device identity ID", required),
        selector: (string, "CSS selector for file input", required),
        attachment_id: (string, "Chat attachment id from the user message", required),
        tab_id: (string, "Optional tab id", optional),
    },
    execute: |args, ctx| {
        let selector = arg_str(&args, "selector");
        let attachment_id = arg_str(&args, "attachment_id");
        if selector.is_empty() || attachment_id.is_empty() {
            return Ok(browser_fail("selector and attachment_id required"));
        }
        let att = match attachment_resolve(&ctx.attachments_json, &attachment_id) {
            Some(a) => a,
            None => return Ok(browser_fail("attachment not found on this turn")),
        };
        let (bytes, _mime) = match cas_bytes_get(&ctx.pool, &cas_dir_default(), &att.hash).await {
            Ok(v) => v,
            Err(e) => return Ok(browser_fail(e.to_string())),
        };
        if bytes.len() > MAX_BROWSER_UPLOAD_BYTES {
            return Ok(browser_fail(format!(
                "attachment exceeds {} byte upload cap",
                MAX_BROWSER_UPLOAD_BYTES
            )));
        }
        let b64 = base64::engine::general_purpose::STANDARD.encode(&bytes);
        let mut params = json!({
            "selector": selector,
            "file_name": att.name,
            "bytes_b64": b64,
        });
        let tab_id = arg_str(&args, "tab_id");
        if !tab_id.is_empty() {
            params["tab_id"] = json!(tab_id);
        }
        Ok(browser_invoke(&args, ctx, "file.upload", params, 120).await)
    }
}

struct ResolvedAttachment {
    hash: String,
    name: String,
}

fn attachment_resolve(attachments_json: &str, attachment_id: &str) -> Option<ResolvedAttachment> {
    let Ok(items) = serde_json::from_str::<Vec<Value>>(attachments_json) else {
        return None;
    };
    let id = attachment_id.trim();
    for a in items {
        let hash = a.get("hash").and_then(|x| x.as_str()).unwrap_or("").trim();
        if hash.is_empty() {
            continue;
        }
        let aid = a.get("id").and_then(|x| x.as_str()).unwrap_or("").trim();
        if aid != id && hash != id {
            continue;
        }
        let name = a
            .get("name")
            .and_then(|x| x.as_str())
            .filter(|s| !s.is_empty())
            .unwrap_or("upload.bin");
        return Some(ResolvedAttachment {
            hash: hash.to_string(),
            name: name.to_string(),
        });
    }
    None
}
