use c_remote_core::config::{device_iid_load, server_url, session_key_clear, session_key_load};
use c_remote_core::conn_ws::{conn_ws_run_reconnect, is_invalid_session};
use c_remote_core::update::{
    bind_runtime, is_dev_mode, is_idle, update_apply, update_check_on_start, update_run_loop,
    update_staged_version,
};
use c_remote_core::version::agent_version_label;
use c_remote_core::ConnExit;
use c_remote_linux::pair_loop::pair_until_claimed;
use tracing::info;

async fn run() -> anyhow::Result<()> {
    bind_runtime();
    let cli = std::env::args().any(|a| a == "--cli");
    let dev = is_dev_mode();
    let dev_name = c_remote_linux::pair_loop::device_name();
    let base_url = server_url();
    let paired = session_key_load().is_some();

    if c_remote_core::log_local::console_visible() {
        println!(
            "\n\
            +--------------------------------------------------------------+\n\
            |  AlienAI Remote Agent (Linux) {:<30}|\n\
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
        "==> [AGENT READY] Linux Remote Agent initialized"
    );

    c_remote_linux::session_linux::log_session_startup();

    c_remote_linux::fs_linux::register();
    c_remote_linux::linux_shell::register();

    c_remote_core::agent_ui::bool_providers_set(c_remote_core::agent_ui::AgentUiBoolProviders {
        capture_active: Some(c_remote_linux::screen_capture::is_capture_active),
        control_allowed: Some(c_remote_linux::input_exec::is_control_allowed),
        autostart_enabled: None,
    });

    c_remote_core::webrtc::set_input_handler(std::sync::Arc::new(
        c_remote_linux::input_exec::execute_input,
    ));
    c_remote_core::webrtc::set_screen_handler(std::sync::Arc::new(|dc| {
        c_remote_linux::screen_capture::start_screen_stream(dc, 0, 25);
    }));
    c_remote_core::webrtc::set_screen_control_handler(std::sync::Arc::new(
        c_remote_linux::screen_capture::set_viewer_stream_quality,
    ));
    c_remote_core::webrtc::register_media_handler();
    c_remote_core::webrtc::set_screenshot_handler(std::sync::Arc::new(
        |max_w, quality, marker, som| {
            c_remote_linux::screen_capture::capture_screen_jpeg(max_w, quality, marker, som)
        },
    ));
    c_remote_core::webrtc::set_webrtc_rtp_media_enabled(false);

    update_check_on_start(&base_url).await;
    c_remote_core::tools::ffmpeg::ffmpeg_tick(&base_url).await;
    tokio::spawn(update_run_loop(base_url.clone()));

    c_remote_core::agent_ui::device_name_set(&dev_name);
    c_remote_linux::drive::drive_start_on_agent_ready();

    loop {
        if session_key_load().is_none() {
            pair_until_claimed(cli).await?;
            if session_key_load().is_none() {
                return Ok(());
            }
            if c_remote_core::config::drive_enabled_load() {
                let _ = c_remote_linux::drive::drive_mount().await;
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
        let _ = c_remote_linux::drive::drive_mount().await;

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
                            c_remote_linux::drive::drive_unmount();
                            session_key_clear()?;
                        }
                        Ok(Ok(ConnExit::Completed)) => tracing::warn!("conn_ws exited unexpectedly"),
                        Ok(Err(e)) if is_invalid_session(&e) => {
                            info!("session invalid; clearing config and re-pairing");
                            c_remote_linux::drive::drive_unmount();
                            session_key_clear()?;
                        }
                        Ok(Err(e)) => tracing::warn!("conn_ws error: {e}"),
                        Err(e) => tracing::warn!("conn_ws task join error: {e}"),
                    }
                    break;
                }
                _ = tokio::signal::ctrl_c() => {
                    conn.abort();
                    info!("shutdown");
                    return Ok(());
                }
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let _ = c_remote_core::log_local::console_attach_from_parent();
    c_remote_core::log_local::init();
    c_remote_linux::agent_version::register();

    tokio::select! {
        r = run() => {
            if let Err(e) = r {
                tracing::error!("{e}");
                std::process::exit(1);
            }
        }
        _ = tokio::signal::ctrl_c() => {
            info!("shutdown");
        }
    }
}
