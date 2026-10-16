//! User-session helper: owns desktop `app_conn` WebSocket and WinRT toasts (Wave 4).
//! IPC listener on `127.0.0.1:19831` for Flutter `NotifyDesktopClient`.
//!
//! See [`config`] for JWT / API base environment variables.

mod config;
mod ipc;
mod state;
mod toast;
mod ws;

use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let state = state::AppState::new();
    tracing::info!(
        ipc = ipc::IPC_ADDR,
        client_id = %config::client_id(),
        "alienai_notify starting"
    );

    let st = state.clone();
    tokio::spawn(async move {
        ws::ws_run_loop(st).await;
    });

    ipc::ipc_listen(state).await?;
    Ok(())
}
