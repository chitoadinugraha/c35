//! Android `shell.run` allowlist + delegate to the JNI-backed executor.

use crate::shell_delegate::{not_supported, ShellOutput};

type ShellHandlerFn = fn(command: &str, timeout_secs: u32) -> ShellOutput;

static HANDLER: std::sync::OnceLock<ShellHandlerFn> = std::sync::OnceLock::new();

/// Register the platform executor (typically JNI → Kotlin `ProcessBuilder`).
pub fn set_shell_handler(handler: ShellHandlerFn) {
    let _ = HANDLER.set(handler);
}

pub fn handler_ready() -> bool {
    HANDLER.get().is_some()
}

/// Returns false when the command must be rejected before execution.
pub fn command_allowed(command: &str) -> bool {
    let cmd = command.trim();
    if cmd.is_empty() {
        return false;
    }
    let lower = cmd.to_ascii_lowercase();
    if lower.contains("&&") || lower.contains("||") || lower.contains(';') || lower.contains('|') {
        return false;
    }
    if lower.starts_with("getprop") {
        return true;
    }
    if lower.starts_with("pm list") {
        return true;
    }
    if lower.starts_with("am start") || lower.starts_with("am force-stop") {
        return true;
    }
    if lower.starts_with("cmd notification") {
        return true;
    }
    if lower.starts_with("input keyevent") || lower.starts_with("input text") {
        return true;
    }
    if lower.starts_with("ls ") || lower == "ls" {
        return true;
    }
    if lower.starts_with("cat ") {
        return true;
    }
    if lower.starts_with("echo ") {
        return true;
    }
    false
}

pub fn run(command: &str, timeout_secs: u32) -> ShellOutput {
    let cmd = command.trim();
    if cmd.is_empty() {
        return ShellOutput {
            ok: false,
            exit_code: -1,
            stdout: String::new(),
            stderr: String::new(),
            error: "empty command".into(),
        };
    }
    if !command_allowed(cmd) {
        return ShellOutput {
            ok: false,
            exit_code: 126,
            stdout: String::new(),
            stderr: String::new(),
            error: "command not on Android shell allowlist (deny by default)".into(),
        };
    }
    if let Some(h) = HANDLER.get() {
        return h(cmd, timeout_secs);
    }
    if let Some(out) = crate::shell_delegate::run(cmd, timeout_secs) {
        return out;
    }
    not_supported(cmd)
}
