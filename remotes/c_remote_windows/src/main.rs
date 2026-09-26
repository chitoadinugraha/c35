#![cfg_attr(windows, windows_subsystem = "windows")]

use c_remote_core::config::{device_iid_load, server_url, session_key_clear, session_key_load};
use c_remote_core::conn_ws::{conn_ws_run_reconnect, is_invalid_session};
use c_remote_core::ConnExit;
use c_remote_core::update::{is_dev_mode, is_idle, update_apply, update_check_on_start, update_run_loop, update_staged_version};
use c_remote_core::version::agent_version_label;
use c_remote_windows::pair_loop::pair_until_claimed;
use c_remote_windows::tray::{start_tray_thread, TrayAction};
use tracing::info;

async fn run() -> anyhow::Result<()> {
    let cli = std::env::args().any(|a| a == "--cli");
    let dev = is_dev_mode();
    let dev_name = c_remote_windows::pair_loop::device_name();
    let base_url = server_url();
    let paired = session_key_load().is_some();

    if c_remote_core::log_local::console_visible() {
        println!(
            "\n\
            +--------------------------------------------------------------+\n\
            |  AlienAI Remote Agent (Windows) {:<28}|\n\
            |  Device: {:<18} Paired: {:<5} Dev: {:<5} |\n\
            |  Server: {:<52}|\n\
            +--------------------------------------------------------------+\n",
            agent_version_label(),
            dev_name,
            paired,
            dev,
            base_url,
        );
    }

    info!(
        version = agent_version_label(),
        device = %dev_name,
        cli,
        dev,
        paired,
        server = %base_url,
        "==> [AGENT READY] Windows Remote Agent initialized"
    );

    c_remote_windows::startup::prevent_sleep();

    c_remote_core::webrtc::set_input_handler(std::sync::Arc::new(
        c_remote_windows::input_exec::execute_input,
    ));
    c_remote_core::webrtc::set_screen_handler(std::sync::Arc::new(|dc| {
        c_remote_windows::screen_capture::start_screen_stream(dc, 1280, 25);
    }));
    c_remote_core::webrtc::set_track_handler(std::sync::Arc::new(|v_track, _a_track| {
        c_remote_windows::video_stream::start_video_stream(v_track);
    }));
    c_remote_core::webrtc::set_screenshot_handler(std::sync::Arc::new(|max_w, quality, marker, som| {
        c_remote_windows::screen_capture::capture_screen_jpeg(max_w, quality, marker, som)
    }));
    // Enable WebRTC RTP media (H.264 hardware GPU / software MFT stream with SCTP fallback)
    c_remote_core::webrtc::set_webrtc_rtp_media_enabled(true);

    let base_url = server_url();
    update_check_on_start(&base_url).await;
    tokio::spawn(update_run_loop(base_url.clone()));

    let (tray_tx, mut tray_rx) = tokio::sync::mpsc::unbounded_channel();
    start_tray_thread(tray_tx);

    loop {
        if session_key_load().is_none() {
            pair_until_claimed(cli, &mut tray_rx).await?;
            if session_key_load().is_none() {
                return Ok(());
            }
            continue;
        }

        if let Some(v) = update_staged_version() {
            if is_idle() && !is_dev_mode() {
                info!(version = v, "applying staged update before connect");
                let _ = update_apply(v);
            }
        }

        let session_key = session_key_load().expect("paired");
        let device_iid = device_iid_load().unwrap_or(0);

        let url = base_url.clone();
        let mut conn = tokio::spawn(async move {
            conn_ws_run_reconnect(&url, &session_key, device_iid).await
        });

        loop {
            tokio::select! {
                r = &mut conn => {
                    match r {
                        Ok(Ok(ConnExit::Unpaired)) => {
                            info!("unpaired via server push");
                            session_key_clear()?;
                        }
                        Ok(Ok(ConnExit::Completed)) => tracing::warn!("conn_ws exited unexpectedly"),
                        Ok(Err(e)) if is_invalid_session(&e) => {
                            info!("session invalid; clearing config and re-pairing");
                            session_key_clear()?;
                        }
                        Ok(Err(e)) => tracing::warn!("conn_ws error: {e}"),
                        Err(e) => tracing::warn!("conn_ws task join error: {e}"),
                    }
                    break;
                }
                action = tray_rx.recv() => match action {
                    Some(TrayAction::Unpair) => {
                        info!("Unpairing this PC…");
                        conn.abort();
                        if let Some(key) = session_key_load() {
                            let url = base_url.clone();
                            if let Err(e) = c_remote_core::pair::pair_unpair(&url, &key).await {
                                tracing::warn!("server unpair failed (clearing local anyway): {e}");
                            }
                        }
                        session_key_clear()?;
                        break;
                    }
                    Some(TrayAction::Quit) | None => {
                        conn.abort();
                        info!("Exiting per user request.");
                        return Ok(());
                    }
                }
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let _ = c_remote_core::log_local::console_attach_from_parent();
    #[cfg(windows)]
    unsafe {
        use windows::Win32::UI::HiDpi::{SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2};
        let _ = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    }
    c_remote_core::log_local::init();

    if is_dev_mode() {
        tokio::select! {
            r = run() => {
                if let Err(e) = r {
                    tracing::error!("{e}");
                    std::process::exit(1);
                }
                std::process::exit(0);
            }
            _ = tokio::signal::ctrl_c() => {
                info!("shutdown");
                std::process::exit(0);
            }
        }
    } else {
        // Production supervisor watchdog loop: recover and restart on crashes/panics
        let mut crash_count = 0usize;
        let mut last_crash = std::time::Instant::now();

        loop {
            let run_future = std::panic::AssertUnwindSafe(async {
                tokio::select! {
                    r = run() => r,
                    _ = tokio::signal::ctrl_c() => {
                        info!("shutdown");
                        Ok(())
                    }
                }
            });

            let res = match futures_util::FutureExt::catch_unwind(run_future).await {
                Ok(inner) => inner,
                Err(panic_err) => {
                    tracing::error!(?panic_err, "c_remote_windows panicked; watchdog supervisor recovering");
                    Err(anyhow::anyhow!("panic"))
                }
            };

            match res {
                Ok(()) => {
                    info!("c_remote_windows exited cleanly");
                    std::process::exit(0);
                }
                Err(e) => {
                    let now = std::time::Instant::now();
                    if now.duration_since(last_crash) < std::time::Duration::from_secs(60) {
                        crash_count += 1;
                    } else {
                        crash_count = 1;
                    }
                    last_crash = now;

                    let delay_secs = if crash_count >= 5 {
                        tracing::error!(crash_count, "==> [WATCHDOG CRITICAL] Frequent crashes detected; backing off 30s");
                        30
                    } else {
                        tracing::warn!(crash_count, error = %e, "==> [WATCHDOG RECOVERING] Agent crashed ({e}); supervisor restarting in 3s");
                        3
                    };

                    if let Some(key) = session_key_load() {
                        c_remote_core::log_push::spawn_log_push(
                            server_url(),
                            key,
                            "error".into(),
                            "agent.supervisor".into(),
                            format!("agent crash #{crash_count}: {e}"),
                            Some(serde_json::json!({
                                "crash_count": crash_count,
                                "delay_secs": delay_secs,
                                "error": e.to_string(),
                            })),
                        );
                    }

                    tokio::time::sleep(std::time::Duration::from_secs(delay_secs)).await;
                }
            }
        }
    }
}
