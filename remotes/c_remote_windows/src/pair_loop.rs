use std::time::Duration;

use c_remote_core::config::{session_key_load, session_key_save, server_url};
use c_remote_core::conn_ws::conn_ws_run;
use c_remote_core::pair::{pair_poll, pair_register, pair_should_reroll, PairPoll};
use tracing::info;

use crate::pair_ui::PairUi;

pub async fn pair_loop_run(cli: bool) -> anyhow::Result<()> {
    let base_url = server_url();

    if let Some(session_key) = session_key_load() {
        info!("already paired; starting conn_ws");
        return conn_ws_run(&base_url, &session_key).await;
    }

    let ui = PairUi::spawn(cli);
    ui.set_status("Requesting a pairing code…");
    let device_name = device_name();

    loop {
        let pending = match pair_register(&base_url, &device_name, "windows").await {
            Ok(p) => p,
            Err(e) => {
                tracing::warn!("pair_register failed: {e}");
                ui.set_status("Can't reach Alien AI right now. Retrying…");
                tokio::time::sleep(Duration::from_secs(3)).await;
                continue;
            }
        };

        ui.set_code(&pending.display_code, pending.expires_in_sec);
        let deadline = pending.deadline();

        loop {
            tokio::time::sleep(Duration::from_secs(2)).await;

            let poll = match pair_poll(&base_url, &pending.secret).await {
                Ok(p) => p,
                Err(e) => {
                    tracing::warn!("pair_poll failed: {e}");
                    ui.set_status("Can't reach Alien AI right now. Retrying…");
                    continue;
                }
            };

            if let PairPoll::Claimed {
                session_key,
                device_iid,
            } = poll
            {
                ui.set_status("Device paired. Starting remote session…");
                session_key_save(&session_key, device_iid)?;
                ui.close();
                return conn_ws_run(&base_url, &session_key).await;
            }

            if pair_should_reroll(&poll, deadline, std::time::Instant::now()) {
                ui.set_status("Code expired. Requesting a new one…");
                break;
            }
        }
    }
}

fn device_name() -> String {
    #[cfg(target_os = "windows")]
    {
        if let Ok(name) = std::env::var("COMPUTERNAME") {
            let trimmed = name.trim();
            if !trimmed.is_empty() {
                return trimmed.to_string();
            }
        }
    }
    hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "Windows PC".to_string())
}
