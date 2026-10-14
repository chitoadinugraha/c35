use crate::mention_context::{device_iid_resolve, json_device_iid_field};
use crate::tool;
use crate::tools::context::ToolContext;
use crate::tools::device_screenshot_artifact::device_screenshot_attach_artifact;
use c35_mod_device::{
    device_pair, remote_device_command_run, remote_device_fs_list, remote_device_fs_read,
    remote_device_input_send, remote_device_screenshot_capture,
};
use c35_proto::ReqDevicePair;
use serde_json::{json, Value};

fn device_fail_class(error: &str) -> (&'static str, bool) {
    let e = error.to_lowercase();
    if e.contains("forbidden") || e.contains("access denied") || e.contains("invalid device") {
        ("fatal_auth", false)
    } else if e.contains("offline")
        || e.contains("not connected")
        || e.contains("disconnected")
        || e.contains("unreachable")
    {
        ("fatal_offline", false)
    } else if e.contains("timeout") || e.contains("timed out") {
        ("transient", true)
    } else if e.contains("device_iid is required") || e.contains("device_iid required") {
        ("transient", true)
    } else {
        ("tool_error", false)
    }
}

fn device_fail(error: impl Into<String>) -> Value {
    let error = error.into();
    let (fail_class, retryable) = device_fail_class(&error);
    json!({
        "ok": false,
        "error": error,
        "fail_class": fail_class,
        "retryable": retryable,
    })
}

pub(crate) fn resolve_device_iid(args: &Value, ctx: &ToolContext) -> Result<i64, Value> {
    let direct = json_device_iid_field(args, "device_iid");
    device_iid_resolve(&ctx.mention, &ctx.mention_ids, direct)
        .map_err(|e| device_fail(e.to_string()))
}

tool! {
    struct: ShellRunTool,
    name: "shell.run",
    aliases: ["device.command", "device_command", "device.shell.run", "shell_run", "run_command_on_device", "exec_device"],
    description: "Run a shell command on a paired remote device. On Windows this is PowerShell/cmd; on Android only allowlisted sh diagnostics (see tool description after device type is known). Use device.input for UI when possible.",
    topics: ["device", "computer_use"],
    always: ["device", "computer_use"],
    rag_phrases: ["ping", "shell", "powershell", "cmd", "terminal", "run command", "network latency"],
    ui_calling_key: "tool.shell.run.calling",
    ui_done_key: "tool.shell.run.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        command: (string, "Shell or PowerShell command to execute", required),
        timeout_sec: (integer, "Execution timeout in seconds (default 15, max 60)", optional),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };
        let command = args["command"].as_str().unwrap_or_default().trim();
        let timeout_sec = args["timeout_sec"].as_i64().unwrap_or(15).clamp(1, 60) as u32;
        if command.is_empty() {
            return Ok(device_fail("command cannot be empty"));
        }

        match remote_device_command_run(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            command,
            timeout_sec,
        ).await {
            Ok(res) => {
                if !res.ok && !res.error.is_empty() {
                    return Ok(device_fail(format!("Failed to execute command: {}", res.error)));
                }
                Ok(json!({
                    "ok": true,
                    "status": if res.ok { "ok" } else { "failed" },
                    "device_iid": device_iid,
                    "command": command,
                    "exit_code": res.exit_code,
                    "stdout": res.stdout,
                    "stderr": res.stderr,
                }))
            }
            Err(e) => Ok(device_fail(format!("Failed to execute command on device: {e}"))),
        }
    }
}

tool! {
    struct: DeviceScreenshotTool,
    name: "device.screenshot",
    aliases: ["device_screenshot", "take_device_screenshot", "screenshot_device", "device_capture_screen"],
    description: "Capture a JPEG desktop screenshot from a user's paired remote device (e.g. Chito-PC). Returns visual observation of the desktop to inspect UI elements, locate coordinates, and verify actions. Can optionally draw a high-contrast red marker at (marker_x, marker_y) or generate Set-of-Mark (SoM) bounding boxes with UI automation tags.",
    topics: ["*"],
    always: ["device", "computer_use"],
    ui_calling_key: "tool.device.screenshot.calling",
    ui_done_key: "tool.device.screenshot.done",
    readonly: true,
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        max_width: (integer, "Maximum width in pixels (e.g. 1280 or 1920, default 1280)", optional),
        quality: (integer, "JPEG quality 1-100 (default 72)", optional),
        marker_x: (number, "Optional normalized X coordinate (0.0 to 1.0) to plot a visual red marker", optional),
        marker_y: (number, "Optional normalized Y coordinate (0.0 to 1.0) to plot a visual red marker", optional),
        som: (boolean, "Optional Set-of-Mark (SoM) visual tags and accessibility tree extraction. When true, labels interactive controls with numbered badges and returns exact coordinates.", optional),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };
        let max_width = args["max_width"].as_i64().unwrap_or(1280).clamp(320, 3840) as u32;
        let quality = args["quality"].as_i64().unwrap_or(72).clamp(20, 100) as u32;
        let som = args["som"].as_bool().unwrap_or(false);
        let marker = match (args.get("marker_x").and_then(|v| v.as_f64()), args.get("marker_y").and_then(|v| v.as_f64())) {
            (Some(mx), Some(my)) if mx >= 0.0 && my >= 0.0 => Some((mx, my)),
            _ => None,
        };

        match remote_device_screenshot_capture(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            max_width,
            quality,
            marker,
            som,
        ).await {
            Ok(res) => {
                if !res.ok {
                    return Ok(device_fail(format!("Failed to capture screenshot: {}", res.error)));
                }
                use base64::Engine;
                let b64 = base64::engine::general_purpose::STANDARD.encode(&res.jpeg_bytes);
                let mut out = json!({
                    "ok": true,
                    "status": "ok",
                    "device_iid": device_iid,
                    "width": res.width,
                    "height": res.height,
                    "image_base64": b64,
                    "mime_type": "image/jpeg",
                    "hint": format!("Captured {}x{} screenshot. Visual observation is attached.", res.width, res.height),
                });
                if !res.axtree_text.is_empty() {
                    out["axtree_text"] = json!(res.axtree_text);
                }
                let marker_used = marker.is_some();
                device_screenshot_attach_artifact(
                    &ctx,
                    "device.screenshot",
                    device_iid,
                    &res.jpeg_bytes,
                    res.width,
                    res.height,
                    som,
                    marker_used,
                    res.axtree_text.len(),
                    &mut out,
                )
                .await;
                Ok(out)
            }
            Err(e) => Ok(device_fail(format!("Failed to request screenshot from device: {e}"))),
        }
    }
}

pub(crate) fn normalize_input_event_type(raw: &str) -> String {
    let s = raw.trim().to_lowercase();
    match s.as_str() {
        "click" => "mouse_click".into(),
        "doubleclick" => "double_click".into(),
        "tripleclick" => "triple_click".into(),
        "rightclick" => "right_click".into(),
        "drag" => "mouse_drag".into(),
        "hotkey" | "key_combo" => "shortcut".into(),
        "click_and_type" | "clickandtype" => "click_and_type".into(),
        "clear_text" | "cleartext" => "clear_text".into(),
        _ => s,
    }
}

pub(crate) fn parse_single_input_event(
    val: &Value,
    default_tab_id: &str,
) -> Result<c35_proto::RemoteInputEvent, &'static str> {
    let raw_type = val
        .get("event_type")
        .and_then(|v| v.as_str())
        .unwrap_or_default();
    let event_type = normalize_input_event_type(raw_type);
    if event_type.is_empty() {
        return Err("event_type is required");
    }

    let x = val.get("x").and_then(|v| v.as_f64()).unwrap_or(0.0);
    let y = val.get("y").and_then(|v| v.as_f64()).unwrap_or(0.0);
    let text = val
        .get("text")
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();
    let key_code = val.get("key_code").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
    let button = val.get("button").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
    let delta_y = val.get("delta_y").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
    let tab_id = val
        .get("tab_id")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or(default_tab_id)
        .to_string();

    Ok(c35_proto::RemoteInputEvent {
        event_type,
        x,
        y,
        button,
        key_code,
        text,
        delta_y,
        tab_id,
    })
}

pub(crate) fn resolve_input_settle_ms(
    explicit_settle_ms: Option<i64>,
    is_batch: bool,
    primary_event_type: &str,
) -> u64 {
    match explicit_settle_ms {
        Some(ms) => ms.clamp(100, 2000) as u64,
        None => {
            if !is_batch && matches!(primary_event_type, "type_text" | "key_down" | "key_up") {
                150
            } else {
                450
            }
        }
    }
}

tool! {
    struct: DeviceInputTool,
    name: "device.input",
    aliases: ["device_input", "device_computer_use"],
    description: "Send mouse or keyboard input (mouse_click, type_text, shortcut, etc.) to a paired remote device. Coordinates (x, y) are normalized 0.0–1.0. Chrome extension browser devices use CDP trusted keys/clicks (not OS SendKeys); pass tab_id for the target tab. For Google Sheets prefer browser.sheets.* tools. Desktop agents use OS input. screenshot_after=true captures a follow-up JPEG with a red marker when supported.",
    topics: ["device", "computer_use"],
    always: ["device", "computer_use"],
    ui_calling_key: "tool.device.input.calling",
    ui_done_key: "tool.device.input.done",
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        event_type: (string, "Input event type: 'mouse_click', 'double_click', 'triple_click', 'right_click', 'middle_click', 'mouse_move', 'mouse_down', 'mouse_up', 'mouse_drag', 'wheel', 'type_text', 'click_and_type', 'clear_text', 'shortcut', 'key_down', 'key_up'", optional),
        actions: (array, "Optional list of consecutive input events to execute in one turn, e.g. [{'event_type': 'click_and_type', 'x': 0.2, 'y': 0.3, 'text': '...'}, {'event_type': 'shortcut', 'text': 'tab'}]", optional),
        x: (number, "Normalized X coordinate (0.0 to 1.0, where 0.0 is left edge and 1.0 is right edge)", optional),
        y: (number, "Normalized Y coordinate (0.0 to 1.0, where 0.0 is top edge and 1.0 is bottom edge)", optional),
        text: (string, "Text string to type (for type_text or click_and_type) or key combo like 'ctrl+c', 'alt+tab', 'win+r' (for shortcut)", optional),
        key_code: (integer, "Virtual key code (e.g. 13 for Enter, 27 for Escape, 9 for Tab)", optional),
        button: (integer, "Mouse button (0: left, 1: middle, 2: right)", optional),
        delta_y: (integer, "Wheel scroll delta (positive = up, negative = down)", optional),
        screenshot_after: (boolean, "If true, captures and returns a new screenshot with a red target marker showing where the click landed to verify action", optional),
        settle_ms: (integer, "Settle delay in milliseconds before capturing screenshot_after (default 150 for typing, 450 for click/nav/batch, min 100, max 2000)", optional),
        tab_id: (string, "Chrome extension remote browser: target tab id (empty = agent default tab)", optional),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };

        let default_tab_id = args["tab_id"].as_str().unwrap_or_default().trim();
        let actions_opt = args.get("actions").and_then(|v| v.as_array());
        let is_batch = actions_opt.map(|a| !a.is_empty()).unwrap_or(false);

        let parsed_events: Vec<c35_proto::RemoteInputEvent> = if is_batch {
            let actions = actions_opt.unwrap();
            let mut evs = Vec::with_capacity(actions.len());
            for (idx, act) in actions.iter().enumerate() {
                match parse_single_input_event(act, default_tab_id) {
                    Ok(ev) => evs.push(ev),
                    Err(e) => return Ok(device_fail(format!("Action #{idx} invalid: {e}"))),
                }
            }
            evs
        } else {
            match parse_single_input_event(&args, default_tab_id) {
                Ok(ev) => vec![ev],
                Err(e) => return Ok(device_fail(e)),
            }
        };

        for (idx, event) in parsed_events.iter().enumerate() {
            if idx > 0 {
                tokio::time::sleep(std::time::Duration::from_millis(30)).await;
            }
            if let Err(e) = remote_device_input_send(
                &ctx.pool,
                ctx.nats.as_ref(),
                ctx.owner_iid,
                device_iid,
                event.clone(),
            ).await {
                return Ok(device_fail(format!("Failed to send input to device: {e}")));
            }
        }

        let mut out = if is_batch {
            json!({
                "ok": true,
                "status": "dispatched",
                "device_iid": device_iid,
                "event_type": "batch",
                "actions_count": parsed_events.len(),
            })
        } else {
            json!({
                "ok": true,
                "status": "dispatched",
                "device_iid": device_iid,
                "event_type": parsed_events[0].event_type,
            })
        };

        let screenshot_after = args["screenshot_after"].as_bool().unwrap_or(false);
        if screenshot_after {
            let explicit_settle_ms = args.get("settle_ms").and_then(|v| {
                if let Some(n) = v.as_i64() {
                    Some(n)
                } else if let Some(s) = v.as_str() {
                    s.parse::<i64>().ok()
                } else {
                    None
                }
            });
            let settle_ms = resolve_input_settle_ms(
                explicit_settle_ms,
                is_batch,
                &parsed_events[0].event_type,
            );
            tokio::time::sleep(std::time::Duration::from_millis(settle_ms)).await;
            let marker = parsed_events
                .iter()
                .rev()
                .find(|ev| {
                    ev.event_type.contains("click")
                        || ev.event_type.contains("move")
                        || ev.event_type.contains("drag")
                })
                .map(|ev| (ev.x, ev.y));

            if let Ok(res) = remote_device_screenshot_capture(
                &ctx.pool,
                ctx.nats.as_ref(),
                ctx.owner_iid,
                device_iid,
                1024,
                60,
                marker,
                false,
            ).await {
                if res.ok {
                    use base64::Engine;
                    let b64 = base64::engine::general_purpose::STANDARD.encode(&res.jpeg_bytes);
                    out["screenshot"] = json!({
                        "width": res.width,
                        "height": res.height,
                    });
                    out["width"] = json!(res.width);
                    out["height"] = json!(res.height);
                    out["image_base64"] = json!(b64);
                    out["mime_type"] = json!("image/jpeg");
                    out["hint"] = json!(format!(
                        "Follow-up screenshot captured ({}x{}). Observation is attached with red action marker.",
                        res.width, res.height
                    ));
                    let marker_used = marker.is_some();
                    device_screenshot_attach_artifact(
                        &ctx,
                        "device.input",
                        device_iid,
                        &res.jpeg_bytes,
                        res.width,
                        res.height,
                        false,
                        marker_used,
                        0,
                        &mut out,
                    )
                    .await;
                }
            }
        }

        Ok(out)
    }
}

fn extract_user_subpath(path: &str) -> Option<String> {
    let clean = path.trim().trim_matches('"').trim_matches('\'').trim();
    if clean.is_empty() {
        return None;
    }
    let norm = clean.replace('/', "\\");
    let lower = norm.to_ascii_lowercase();

    // Direct known folders or shell: shortcuts
    for (name, canonical) in [
        ("desktop", "Desktop"),
        ("downloads", "Downloads"),
        ("documents", "Documents"),
        ("my documents", "Documents"),
        ("personal", "Documents"),
        ("pictures", "Pictures"),
        ("videos", "Videos"),
        ("music", "Music"),
    ] {
        if lower == name || lower == format!("shell:{name}") {
            return Some(canonical.to_string());
        }
        if lower.starts_with(&format!("{name}\\")) {
            let rest = &norm[name.len() + 1..];
            return Some(format!("{}\\{}", canonical, rest));
        }
    }

    // ~ or %userprofile% prefixes
    for prefix in ["~\\", "%userprofile%\\"] {
        if lower.starts_with(prefix) {
            let rest = &norm[prefix.len()..];
            return extract_user_subpath(rest);
        }
    }

    // Full paths like C:\Users\<username>\<folder>[\<rest>]
    if let Some(pos) = lower.find("\\users\\") {
        let after_users = &lower[pos + 7..];
        let after_users_norm = &norm[pos + 7..];
        if let Some(slash_pos) = after_users.find('\\') {
            let sub = &after_users[slash_pos + 1..];
            let sub_norm = &after_users_norm[slash_pos + 1..];
            for (name, canonical) in [
                ("desktop", "Desktop"),
                ("downloads", "Downloads"),
                ("documents", "Documents"),
                ("my documents", "Documents"),
                ("pictures", "Pictures"),
                ("videos", "Videos"),
                ("music", "Music"),
            ] {
                if sub == name {
                    return Some(canonical.to_string());
                }
                if sub.starts_with(&format!("{name}\\")) {
                    let rest = &sub_norm[name.len() + 1..];
                    return Some(format!("{}\\{}", canonical, rest));
                }
            }
        }
    }

    None
}

async fn resolve_windows_user_path(
    ctx: &ToolContext,
    device_iid: i64,
    sub_path: &str,
) -> Option<String> {
    if let Ok(users_res) = remote_device_fs_list(
        &ctx.pool,
        ctx.nats.as_ref(),
        ctx.owner_iid,
        device_iid,
        "C:\\Users",
    )
    .await
    {
        for ent in users_res.entries {
            if ent.is_dir {
                let name = ent.name.trim();
                let lower = name.to_ascii_lowercase();
                if !matches!(
                    lower.as_str(),
                    "default" | "public" | "all users" | "default user"
                ) && !name.starts_with('.')
                {
                    return Some(format!("C:\\Users\\{}\\{}", name, sub_path));
                }
            }
        }
    }
    None
}

tool! {
    struct: DeviceFsListTool,
    name: "device.fs.list",
    aliases: ["device_fs_list", "list_device_directory"],
    description: "List files and folders on a paired remote device. Windows: drive letters and Desktop paths. Android: virtual roots app:, shared:, tree:{id}/... (not C:\\ or Recycle Bin).",
    topics: ["device", "computer_use"],
    always: ["device", "computer_use"],
    readonly: true,
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        path: (string, "Directory path on the device (empty string lists drives)", optional),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };
        let path = args["path"].as_str().unwrap_or_default();
        let mut list_path = path.to_string();

        let mut res = remote_device_fs_list(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            &list_path,
        ).await;

        if let Ok(ref r) = res {
            if !r.error.is_empty() {
                if let Some(folder) = extract_user_subpath(path) {
                    if let Some(resolved) = resolve_windows_user_path(ctx, device_iid, &folder).await {
                        list_path = resolved.clone();
                        res = remote_device_fs_list(
                            &ctx.pool,
                            ctx.nats.as_ref(),
                            ctx.owner_iid,
                            device_iid,
                            &list_path,
                        ).await;
                    }
                }
            }
        }

        match res {
            Ok(res) => {
                if !res.error.is_empty() {
                    return Ok(device_fail(format!("Failed to list path: {}", res.error)));
                }
                let entries: Vec<Value> = res.entries.iter().map(|e| {
                    json!({
                        "name": e.name,
                        "path": e.path,
                        "is_dir": e.is_dir,
                        "size": e.size,
                        "modified_ms": e.modified_ms,
                    })
                }).collect();
                Ok(json!({
                    "ok": true,
                    "status": "ok",
                    "device_iid": device_iid,
                    "path": list_path,
                    "entries": entries,
                }))
            }
            Err(e) => Ok(device_fail(format!("Failed to list directory on device: {e}"))),
        }
    }
}

tool! {
    struct: DeviceFsReadTool,
    name: "device.fs.read",
    aliases: ["device_fs_read", "read_device_file"],
    description: "Read bytes from a file on a paired remote device (Windows paths or Android virtual paths). Returns base64 data with mime hint; capped at 256KB per call — use offset for larger files.",
    topics: ["device", "computer_use"],
    always: ["device", "computer_use"],
    readonly: true,
    parameters: {
        device_iid: (integer, "Target device identity ID", required),
        path: (string, "File path on the device", required),
        offset: (integer, "Byte offset to start reading (default 0)", optional),
        max_bytes: (integer, "Max bytes to read (default 256KB, server cap 256KB)", optional),
    },
    execute: |args, ctx| {
        let device_iid = match resolve_device_iid(&args, ctx) {
            Ok(iid) => iid,
            Err(v) => return Ok(v),
        };
        let path = args["path"].as_str().unwrap_or_default().trim();
        if path.is_empty() {
            return Ok(device_fail("path is required"));
        }
        let offset = args["offset"].as_i64().unwrap_or(0).max(0);
        let max_bytes = args["max_bytes"].as_i64().unwrap_or(0) as i32;
        let mut read_path = path.to_string();

        let mut res = remote_device_fs_read(
            &ctx.pool,
            ctx.nats.as_ref(),
            ctx.owner_iid,
            device_iid,
            &read_path,
            offset,
            max_bytes,
        ).await;

        if let Ok(ref r) = res {
            if !r.error.is_empty() {
                if let Some(sub_path) = extract_user_subpath(path) {
                    if let Some(resolved) = resolve_windows_user_path(ctx, device_iid, &sub_path).await {
                        read_path = resolved.clone();
                        res = remote_device_fs_read(
                            &ctx.pool,
                            ctx.nats.as_ref(),
                            ctx.owner_iid,
                            device_iid,
                            &read_path,
                            offset,
                            max_bytes,
                        ).await;
                    }
                }
            }
        }

        match res {
            Ok(res) => {
                if !res.error.is_empty() {
                    return Ok(device_fail(format!("Failed to read file: {}", res.error)));
                }
                use base64::Engine;
                let b64 = base64::engine::general_purpose::STANDARD.encode(&res.data);
                Ok(json!({
                    "ok": true,
                    "status": "ok",
                    "device_iid": device_iid,
                    "path": read_path,
                    "offset": offset,
                    "eof": res.eof,
                    "mime": res.mime,
                    "data_base64": b64,
                    "bytes": res.data.len(),
                }))
            }
            Err(e) => Ok(device_fail(format!("Failed to read file on device: {e}"))),
        }
    }
}

const SHELL_RUN_DESC_WINDOWS: &str =
    "Run PowerShell or cmd on a paired Windows PC. Use for ping, scripts, bulk file work, and stdout/stderr. To open a GUI app (Chrome, Edge, Notepad), use a simple launch such as `chrome` or `Start-Process chrome` — the agent opens it directly like a double-click (no shell window). Before launching Chrome for Google Forms, prefer device.screenshot: reuse an existing Forms tab instead of opening forms.new again. Use device.input when the UI is already on screen.";

const SHELL_RUN_DESC_ANDROID: &str =
    "Run an allowlisted `/system/bin/sh -c` command on a paired Android remote agent (not PowerShell). Only approved diagnostics are permitted (e.g. getprop, pm list packages, df, id, ls on paths the FS layer cannot reach). Arbitrary root, package install, or destructive commands are denied. Prefer device.fs.list / device.fs.read for files and device.input for UI taps, swipes, and text.";

const DEVICE_FS_LIST_DESC_WINDOWS: &str =
    "List files and folders on a paired Windows remote device. Use normal paths (e.g. C:\\Users, Desktop, Downloads). Empty path lists drive roots. For Recycle Bin use path recycle bin or Shell:RecycleBinFolder (not $RecycleBin$). Do not use shell.run to list the bin.";

const DEVICE_FS_LIST_DESC_ANDROID: &str =
    "List files and folders on a paired Android remote device. Paths are virtual UTF-8 roots — not Windows drive letters. Use empty path for entry roots; `app:` for agent-private storage; optional `shared:` when exposed; `tree:{id}/...` for SAF document-tree grants the user picked on the device. No Recycle Bin or Desktop-style paths.";

const DEVICE_FS_READ_DESC_WINDOWS: &str =
    "Read bytes from a file on a paired Windows remote device. Returns base64 data with mime hint; capped at 256KB per call — use offset for larger files.";

const DEVICE_FS_READ_DESC_ANDROID: &str =
    "Read bytes from a file on a paired Android remote device using the same virtual paths as device.fs.list (`app:`, `shared:`, `tree:{id}/...`). Returns base64 data with mime hint; capped at 256KB per call — use offset for larger files.";

pub fn shell_run_description(windows: bool, android: bool) -> String {
    match (windows, android) {
        (true, true) => format!(
            "{}\n\nOn Android agents in this turn: {}",
            SHELL_RUN_DESC_WINDOWS,
            SHELL_RUN_DESC_ANDROID
        ),
        (false, true) => SHELL_RUN_DESC_ANDROID.to_string(),
        _ => SHELL_RUN_DESC_WINDOWS.to_string(),
    }
}

pub fn device_fs_list_description(windows: bool, android: bool) -> String {
    match (windows, android) {
        (true, true) => format!(
            "{}\n\nOn Android agents in this turn: {}",
            DEVICE_FS_LIST_DESC_WINDOWS,
            DEVICE_FS_LIST_DESC_ANDROID
        ),
        (false, true) => DEVICE_FS_LIST_DESC_ANDROID.to_string(),
        _ => DEVICE_FS_LIST_DESC_WINDOWS.to_string(),
    }
}

pub fn device_fs_read_description(windows: bool, android: bool) -> String {
    match (windows, android) {
        (true, true) => format!(
            "{}\n\nOn Android agents in this turn: {}",
            DEVICE_FS_READ_DESC_WINDOWS,
            DEVICE_FS_READ_DESC_ANDROID
        ),
        (false, true) => DEVICE_FS_READ_DESC_ANDROID.to_string(),
        _ => DEVICE_FS_READ_DESC_WINDOWS.to_string(),
    }
}

pub async fn device_pair_exec(ctx: &ToolContext, args: &Value) -> anyhow::Result<Value> {
    let code = args
        .get("code")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("");
    if code.is_empty() {
        return Ok(json!({
            "ok": false,
            "tool": "device.pair",
            "error": "code required (10 characters, with or without hyphen)",
        }));
    }
    match device_pair(
        &ctx.pool,
        ctx.owner_iid,
        ReqDevicePair {
            code: code.to_string(),
        },
    )
    .await
    {
        Ok(res) => {
            let id = res.device.as_ref().and_then(|r| r.identity.as_ref());
            let llm = json!({
                "device_iid": id.map(|i| i.iid).unwrap_or(0),
                "name": id.map(|i| i.name.as_str()).unwrap_or(""),
                "type": id.map(|i| i.r#type.as_str()).unwrap_or(""),
                "alien_id": id.map(|i| i.alien_id.as_str()).unwrap_or(""),
            });
            Ok(json!({
                "ok": true,
                "tool": "device.pair",
                "device": llm,
                "llm": llm,
            }))
        }
        Err(e) => Ok(json!({ "ok": false, "tool": "device.pair", "error": e })),
    }
}

tool! {
    struct: DevicePairTool,
    name: "device.pair",
    aliases: ["device_pair", "pair device", "pairing code", "pasangkan device"],
    description: "Claim a remote PC or IoT device using the pairing code shown on the agent screen (XXXXX-XXXXX or 10 letters/digits). Same as Devices → Add in the app.",
    topics: ["general", "device"],
    always: ["general", "device"],
    ui_calling_key: "tool.device.pair.calling",
    ui_done_key: "tool.device.pair.done",
    parameters: {
        code: (string, "Pairing code from the device agent (e.g. AB12C-D34EF or AB12CD34EF)", required),
    },
    execute: |args, ctx| device_pair_exec(ctx, &args).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn device_fail_class_maps_auth() {
        let (c, r) = device_fail_class("forbidden");
        assert_eq!(c, "fatal_auth");
        assert!(!r);
    }

    #[test]
    fn device_fail_class_maps_offline() {
        let (c, r) = device_fail_class("agent offline");
        assert_eq!(c, "fatal_offline");
        assert!(!r);
    }

    #[test]
    fn device_fail_class_maps_timeout() {
        let (c, r) = device_fail_class("screenshot capture timed out");
        assert_eq!(c, "transient");
        assert!(r);
    }

    #[test]
    fn device_fail_class_maps_operational_error() {
        let (c, r) = device_fail_class("The system cannot find the path specified. (os error 3)");
        assert_eq!(c, "tool_error");
        assert!(!r);
    }

    #[test]
    fn test_extract_user_subpath() {
        assert_eq!(extract_user_subpath("Desktop").as_deref(), Some("Desktop"));
        assert_eq!(
            extract_user_subpath("\"downloads\"").as_deref(),
            Some("Downloads")
        );
        assert_eq!(
            extract_user_subpath("shell:personal").as_deref(),
            Some("Documents")
        );
        assert_eq!(
            extract_user_subpath(r"C:\Users\User\Desktop").as_deref(),
            Some("Desktop")
        );
        assert_eq!(
            extract_user_subpath(r"C:\Users\Admin\Desktop\file.txt").as_deref(),
            Some("Desktop\\file.txt")
        );
        assert_eq!(
            extract_user_subpath(r"Desktop\test.png").as_deref(),
            Some("Desktop\\test.png")
        );
        assert_eq!(extract_user_subpath("C:\\foo"), None);
    }

    #[test]
    fn test_device_input_tool_definition() {
        use crate::tools::Tool;
        let def = DeviceInputTool.definition();
        assert_eq!(def.name, "device.input");
        let props = def.parameters["properties"].as_object().unwrap();
        assert!(props.contains_key("settle_ms"));
        assert!(props.contains_key("actions"));
        let actions_prop = &props["actions"];
        assert_eq!(actions_prop["type"], "array");
        assert_eq!(actions_prop["items"]["type"], "object");
        let event_type_desc = props["event_type"]["description"].as_str().unwrap();
        assert!(event_type_desc.contains("click_and_type"));
        assert!(event_type_desc.contains("clear_text"));
    }

    #[test]
    fn test_resolve_input_settle_ms() {
        // Explicit value takes precedence (clamped to [100, 2000])
        assert_eq!(resolve_input_settle_ms(Some(300), false, "mouse_click"), 300);
        assert_eq!(resolve_input_settle_ms(Some(50), false, "mouse_click"), 100);
        assert_eq!(resolve_input_settle_ms(Some(5000), false, "mouse_click"), 2000);

        // Pure typing defaults to 150ms when not explicit
        assert_eq!(resolve_input_settle_ms(None, false, "type_text"), 150);
        assert_eq!(resolve_input_settle_ms(None, false, "key_down"), 150);
        assert_eq!(resolve_input_settle_ms(None, false, "key_up"), 150);

        // Navigation, click, shortcut default to 450ms when not explicit
        assert_eq!(resolve_input_settle_ms(None, false, "mouse_click"), 450);
        assert_eq!(resolve_input_settle_ms(None, false, "click_and_type"), 450);
        assert_eq!(resolve_input_settle_ms(None, false, "shortcut"), 450);
        assert_eq!(resolve_input_settle_ms(None, false, "mouse_move"), 450);

        // Batch always defaults to 450ms when not explicit
        assert_eq!(resolve_input_settle_ms(None, true, "type_text"), 450);
        assert_eq!(resolve_input_settle_ms(None, true, "mouse_click"), 450);
    }

    #[test]
    fn test_parse_input_events_single_and_batch() {
        // Single event
        let single_val = json!({
            "event_type": "click",
            "x": 0.5,
            "y": 0.25,
        });
        let ev = parse_single_input_event(&single_val, "").unwrap();
        assert_eq!(ev.event_type, "mouse_click");
        assert_eq!(ev.x, 0.5);
        assert_eq!(ev.y, 0.25);

        // Alias normalization
        let hotkey_val = json!({
            "event_type": "hotkey",
            "text": "ctrl+c",
        });
        let ev = parse_single_input_event(&hotkey_val, "").unwrap();
        assert_eq!(ev.event_type, "shortcut");
        assert_eq!(ev.text, "ctrl+c");

        let click_and_type_val = json!({
            "event_type": "clickandtype",
            "x": 0.1,
            "y": 0.2,
            "text": "test",
        });
        let ev = parse_single_input_event(&click_and_type_val, "").unwrap();
        assert_eq!(ev.event_type, "click_and_type");
        assert_eq!(ev.text, "test");

        // Missing event_type errors
        let empty_val = json!({});
        assert!(parse_single_input_event(&empty_val, "").is_err());
    }
}
