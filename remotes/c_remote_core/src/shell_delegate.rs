//! Platform shell hooks (`shell.run` / `ReqRemoteCommand`).

use std::sync::OnceLock;

pub struct ShellOutput {
    pub ok: bool,
    pub exit_code: i32,
    pub stdout: String,
    pub stderr: String,
    pub error: String,
}

type ShellFn = fn(command: &str, timeout_secs: u32) -> ShellOutput;

static SHELL: OnceLock<ShellFn> = OnceLock::new();

pub fn register_shell(handler: ShellFn) {
    let _ = SHELL.set(handler);
}

pub fn is_registered() -> bool {
    SHELL.get().is_some()
}

pub fn run(command: &str, timeout_secs: u32) -> Option<ShellOutput> {
    SHELL.get().map(|f| f(command, timeout_secs))
}

pub fn not_supported(command: &str) -> ShellOutput {
    ShellOutput {
        ok: false,
        exit_code: -1,
        stdout: String::new(),
        stderr: String::new(),
        error: format!(
            "shell not available (command not run): {}",
            command.chars().take(120).collect::<String>()
        ),
    }
}
