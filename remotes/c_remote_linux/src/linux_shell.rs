use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;

use c_remote_core::c35_proto::ResRemoteCommand;
use c_remote_core::shell_delegate::{not_supported, ShellOutput};

fn shell_stub(command: &str, _timeout_secs: u32) -> ShellOutput {
    not_supported(command)
}

/// Deny-by-default shell allowlist (see `_/specs/remote-linux.md`).
pub fn command_allowed(command: &str) -> bool {
    let cmd = command.trim();
    if cmd.is_empty() {
        return false;
    }
    let lower = cmd.to_ascii_lowercase();
    if lower.contains("&&") || lower.contains("||") || lower.contains(';') || lower.contains('|') {
        return false;
    }
    if lower.starts_with("uname") {
        return true;
    }
    if lower.starts_with("df ") || lower == "df" || lower.starts_with("df\t") {
        return true;
    }
    if lower.starts_with("free ") || lower == "free" {
        return true;
    }
    if lower.starts_with("uptime") {
        return true;
    }
    if lower.starts_with("systemctl --user") {
        return true;
    }
    if lower.starts_with("journalctl --user") {
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
    if lower.starts_with("id") || lower == "whoami" {
        return true;
    }
    false
}

#[cfg(target_os = "linux")]
fn shell_impl(command: &str, timeout_secs: u32) -> ShellOutput {
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
            error: "command not on Linux shell allowlist (deny by default)".into(),
        };
    }

    let timeout = std::time::Duration::from_secs(timeout_secs.max(1).min(120) as u64);
    let child = std::process::Command::new("sh")
        .args(["-c", cmd])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn();

    match child {
        Ok(mut c) => {
            let start = std::time::Instant::now();
            loop {
                match c.try_wait() {
                    Ok(Some(status)) => {
                        let stdout = match c.stdout.take() {
                            Some(mut o) => {
                                let mut buf = Vec::new();
                                let _ = std::io::Read::read_to_end(&mut o, &mut buf);
                                String::from_utf8_lossy(&buf).into_owned()
                            }
                            None => String::new(),
                        };
                        let stderr = match c.stderr.take() {
                            Some(mut e) => {
                                let mut buf = Vec::new();
                                let _ = std::io::Read::read_to_end(&mut e, &mut buf);
                                String::from_utf8_lossy(&buf).into_owned()
                            }
                            None => String::new(),
                        };
                        let code = status.code().unwrap_or(-1);
                        return ShellOutput {
                            ok: status.success(),
                            exit_code: code,
                            stdout,
                            stderr,
                            error: String::new(),
                        };
                    }
                    Ok(None) => {
                        if start.elapsed() > timeout {
                            let _ = c.kill();
                            return ShellOutput {
                                ok: false,
                                exit_code: -1,
                                stdout: String::new(),
                                stderr: String::new(),
                                error: "command timed out".into(),
                            };
                        }
                        std::thread::sleep(std::time::Duration::from_millis(50));
                    }
                    Err(e) => {
                        return ShellOutput {
                            ok: false,
                            exit_code: -1,
                            stdout: String::new(),
                            stderr: String::new(),
                            error: e.to_string(),
                        };
                    }
                }
            }
        }
        Err(e) => ShellOutput {
            ok: false,
            exit_code: -1,
            stdout: String::new(),
            stderr: String::new(),
            error: e.to_string(),
        },
    }
}

#[cfg(not(target_os = "linux"))]
fn shell_impl(command: &str, timeout_secs: u32) -> ShellOutput {
    shell_stub(command, timeout_secs)
}

fn register_command_handler() {
    c_remote_core::webrtc::set_command_handler(Arc::new(
        |raw: String, timeout_secs: u32| -> Pin<Box<dyn Future<Output = Option<ResRemoteCommand>> + Send>> {
            Box::pin(async move {
                let cmd = raw.trim().to_string();
                if cmd.is_empty() {
                    return Some(ResRemoteCommand {
                        ok: false,
                        error: "empty command".into(),
                        exit_code: -1,
                        stdout: String::new(),
                        stderr: String::new(),
                    });
                }
                if !command_allowed(&cmd) {
                    return Some(ResRemoteCommand {
                        ok: false,
                        error: "command not on Linux shell allowlist (deny by default)".into(),
                        exit_code: 126,
                        stdout: String::new(),
                        stderr: String::new(),
                    });
                }
                let run_res = tokio::time::timeout(
                    std::time::Duration::from_secs(timeout_secs.max(1).min(120) as u64),
                    tokio::task::spawn_blocking(move || shell_impl(&cmd, timeout_secs)),
                )
                .await;
                match run_res {
                    Ok(Ok(out)) => Some(ResRemoteCommand {
                        ok: out.ok,
                        error: out.error,
                        exit_code: out.exit_code,
                        stdout: out.stdout,
                        stderr: out.stderr,
                    }),
                    Ok(Err(e)) => Some(ResRemoteCommand {
                        ok: false,
                        error: format!("task join error: {e}"),
                        exit_code: -1,
                        stdout: String::new(),
                        stderr: String::new(),
                    }),
                    Err(_) => Some(ResRemoteCommand {
                        ok: false,
                        error: format!("command execution timed out after {timeout_secs}s"),
                        exit_code: -1,
                        stdout: String::new(),
                        stderr: String::new(),
                    }),
                }
            })
        },
    ));
}

pub fn register() {
    #[cfg(target_os = "linux")]
    {
        c_remote_core::shell_delegate::register_shell(shell_impl);
        register_command_handler();
    }
    #[cfg(not(target_os = "linux"))]
    c_remote_core::shell_delegate::register_shell(shell_stub);
}