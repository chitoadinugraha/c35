#![cfg_attr(all(windows, not(debug_assertions)), windows_subsystem = "windows")]

mod agent_version;
mod browser_command;
mod browser_download;
mod browser_idle;
mod browser_input;
mod browser_state;
mod browser_stream;
mod browser_tabs;
mod browser_task;
mod chrome_native;
mod engine;
mod extension_agent;
mod extension_ipc;
mod extension_page;
mod extension_tabs;
mod mode;
mod pair_loop;
mod webrtc;

use c_remote_core::config::{device_iid_load, session_key_clear, session_key_load, server_url};
use c_remote_core::conn_ws::{conn_ws_run_reconnect, is_invalid_session};
use c_remote_core::log_local;
use c_remote_core::ConnExit;
use tracing::{info, warn};

fn main() {
    if mode::chrome_extension_install_exe() {
        std::env::set_var("C35_BROWSER_ENGINE", "extension");
        std::env::set_var("C35_SKIP_OTA", "1");
    }
    if chrome_native::should_run_native_host() {
        std::env::set_var("C35_NATIVE_MESSAGING_HOST", "1");
        std::env::set_var("C35_BROWSER_ENGINE", "extension");
        let code = if chrome_native::run_chrome_native_host().is_ok() {
            0
        } else {
            1
        };
        std::process::exit(code);
    }
    if let Err(e) = run_agent_async() {
        eprintln!("alienai_remote_browser exited: {e:#}");
        std::process::exit(1);
    }
}

#[tokio::main]
async fn run_agent_async() -> anyhow::Result<()> {
    run_agent().await
}

async fn run_agent() -> anyhow::Result<()> {
    log_local::init();
    agent_version::register();
    let cli = std::env::args().any(|a| a == "--cli");
    let extension_engine = mode::is_extension_engine();
    if extension_engine && extension_ipc::extension_ipc_port_in_use() {
        eprintln!(
            "Alien AI Chrome remote agent already running (extension IPC port in use). \
             Use your existing Chrome window; do not start another agent."
        );
        return Ok(());
    }

    println!(
        "Alien AI Remote browser {} - server {} ({})",
        c_remote_core::version::agent_version_label(),
        server_url(),
        if extension_engine { "chrome extension" } else { "playwright" }
    );

    let state = browser_state::BrowserState::new();
    browser_state::init(state.clone());
    browser_task::register_task_handler();
    browser_command::register_command_handler();
    webrtc::register_handlers();
    browser_idle::spawn_screencast_idle_loop(state.clone());

    if extension_engine {
        if let Err(e) = extension_ipc::spawn_extension_ipc_server(state.clone()) {
            warn!("extension ipc server: {e:#}");
        }
        info!("extension engine mode — Playwright sidecar disabled");
    }

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
            extension_engine,
            "already paired; pair window skipped (run dev_browser with -Unpair to re-pair)"
        );

        if !extension_engine {
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
                        warn!("browser_engine not started: {e:#}");
                    }
                }
            }
        }

        let session_key = match session_key_load() {
            Some(k) => k,
            None => continue,
        };
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
                            if let Err(clear_err) = session_key_clear() {
                                warn!("session_key_clear: {clear_err:#}");
                            }
                        }
                        Ok(Ok(ConnExit::Completed)) => warn!("conn_ws exited"),
                        Ok(Err(e)) if is_invalid_session(&e) => {
                            if let Ok(mut g) = state.engine.lock() {
                                if let Some(mut e) = g.take() {
                                    engine::process::shutdown_engine(&mut e).await;
                                }
                            }
                            eprintln!(
                                "Session rejected by {} (wrong server or expired). Run .\\dev_browser.ps1 -Unpair and pair again.",
                                server_url()
                            );
                            warn!("session invalid for {}: {e:#}", server_url());
                            if let Err(clear_err) = session_key_clear() {
                                warn!("session_key_clear: {clear_err:#}");
                            }
                        }
                        Ok(Err(e)) => warn!("conn_ws error: {e:#}"),
                        Err(e) => warn!("conn_ws join: {e:#}"),
                    }
                    break;
                }
            }
        }
    }
}
