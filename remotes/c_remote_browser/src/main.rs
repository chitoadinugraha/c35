mod agent_version;
mod browser_command;
mod browser_download;
mod browser_idle;
mod browser_input;
mod browser_state;
mod browser_stream;
mod browser_tabs;
mod browser_task;
mod engine;
mod mode;
mod pair_loop;
mod webrtc;

use c_remote_core::config::{device_iid_load, session_key_clear, session_key_load, server_url};
use c_remote_core::conn_ws::{conn_ws_run_reconnect, is_invalid_session};
use c_remote_core::log_local;
use c_remote_core::ConnExit;
use tracing::info;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    log_local::init();
    agent_version::register();
    let cli = std::env::args().any(|a| a == "--cli");

    println!(
        "Alien AI Remote browser {} - server {}",
        c_remote_core::version::agent_version_label(),
        server_url()
    );

    let state = browser_state::BrowserState::new();
    browser_state::init(state.clone());
    browser_task::register_task_handler();
    browser_command::register_command_handler();
    webrtc::register_handlers();
    browser_idle::spawn_screencast_idle_loop(state.clone());

    loop {
        if session_key_load().is_none() {
            pair_loop::pair_until_claimed(cli).await?;
            if session_key_load().is_none() {
                return Ok(());
            }
            continue;
        }

        info!(
            device_iid = device_iid_load().unwrap_or(0),
            "already paired; pair window skipped (run dev_browser with -Unpair to re-pair)"
        );

        {
            let mut slot = state.engine.lock().map_err(|_| anyhow::anyhow!("lock"))?;
            if slot.is_none() {
                let headless = mode::headless_from_config();
                info!(
                    headless,
                    "launching Playwright Chromium (headless=false shows a visible window)"
                );
                match engine::process::spawn_engine(headless, "default").await {
                    Ok(e) => *slot = Some(e),
                    Err(e) => {
                        eprintln!("browser_engine not started: {e:#}");
                        tracing::warn!("browser_engine not started: {e:#}");
                    }
                }
            }
        }

        let session_key = session_key_load().expect("paired");
        let device_iid = device_iid_load().unwrap_or(0);
        let url = server_url();

        let mut conn = tokio::spawn(async move { conn_ws_run_reconnect(&url, &session_key, device_iid).await });

        loop {
            tokio::select! {
                r = &mut conn => {
                    match r {
                        Ok(Ok(ConnExit::Unpaired)) => {
                            info!("unpaired");
                            if let Ok(mut g) = state.engine.lock() {
                                if let Some(mut e) = g.take() {
                                    engine::process::shutdown_engine(&mut e).await;
                                }
                            }
                            session_key_clear()?;
                        }
                        Ok(Ok(ConnExit::Completed)) => tracing::warn!("conn_ws exited"),
                        Ok(Err(e)) if is_invalid_session(&e) => {
                            if let Ok(mut g) = state.engine.lock() {
                                if let Some(mut e) = g.take() {
                                    engine::process::shutdown_engine(&mut e).await;
                                }
                            }
                            session_key_clear()?;
                        }
                        Ok(Err(e)) => tracing::warn!("conn_ws error: {e}"),
                        Err(e) => tracing::warn!("conn_ws join: {e}"),
                    }
                    break;
                }
            }
        }
    }
}
