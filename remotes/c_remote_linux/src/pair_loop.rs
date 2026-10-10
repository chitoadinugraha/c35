use std::time::Duration;

use c_remote_core::config::{session_key_load, session_key_save, server_url};
use c_remote_core::pair::{pair_poll, pair_register, pair_should_reroll, PairPoll};

use crate::pair_ui::PairUi;

pub async fn pair_until_claimed(cli: bool) -> anyhow::Result<()> {
    if session_key_load().is_some() {
        return Ok(());
    }

    let base_url = server_url();
    let ui = PairUi::new(cli);
    let device_name = device_name();

    loop {
        if ui.user_requested_quit() {
            return Ok(());
        }

        ui.set_connecting();

        let pending = match pair_register(&base_url, &device_name, "linux").await {
            Ok(p) => p,
            Err(e) => {
                tracing::warn!("pair_register failed: {e}");
                ui.set_status(&c_remote_core::pair::pair_connect_status(&e, &base_url));
                tokio::time::sleep(Duration::from_secs(3)).await;
                continue;
            }
        };

        ui.set_code(&pending.display_code, pending.expires_in_sec);
        tracing::info!(
            code = %pending.display_code,
            expires_sec = pending.expires_in_sec,
            "Linux remote pairing — enter code in Alien AI -> Devices -> Pair with Code"
        );

        let deadline = pending.deadline();
        while std::time::Instant::now() < deadline {
            tokio::time::sleep(Duration::from_secs(2)).await;

            if ui.user_requested_quit() {
                return Ok(());
            }

            let poll = match pair_poll(&base_url, &pending.secret).await {
                Ok(p) => p,
                Err(e) => {
                    tracing::warn!("pair_poll failed: {e}");
                    ui.set_status(&c_remote_core::pair::pair_connect_status(&e, &base_url));
                    continue;
                }
            };

            if let PairPoll::Claimed {
                session_key,
                device_iid,
            } = poll
            {
                ui.set_status("Device paired. Starting remote session…");
                tracing::info!(device_iid, "Linux remote agent paired");
                session_key_save(&session_key, device_iid)?;
                ui.close();
                return Ok(());
            }

            if pair_should_reroll(&poll, deadline, std::time::Instant::now()) {
                tracing::info!("pairing code expired; requesting new code");
                ui.set_connecting();
                ui.set_status("Code expired. Connecting for a new code…");
                break;
            }
        }
    }
}

pub fn device_name() -> String {
    hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "Linux PC".to_string())
}
