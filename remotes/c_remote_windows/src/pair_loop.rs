use std::time::Duration;

use c_remote_core::config::{session_key_load, session_key_save, server_url};
use c_remote_core::pair::{pair_poll, pair_register, pair_should_reroll, PairPoll};
use crate::pair_ui::PairUi;
use crate::tray::TrayAction;

pub async fn pair_until_claimed(
    cli: bool,
    tray_rx: &mut tokio::sync::mpsc::UnboundedReceiver<TrayAction>,
) -> anyhow::Result<()> {
    if session_key_load().is_some() {
        return Ok(());
    }

    let base_url = server_url();
    let ui = PairUi::spawn(cli);
    ui.set_connecting();
    let device_name = device_name();

    loop {
        if ui.user_requested_quit() {
            return Ok(());
        }

        let register = tokio::spawn({
            let base_url = base_url.clone();
            let device_name = device_name.clone();
            async move { pair_register(&base_url, &device_name, "windows").await }
        });
        let pending = match register.await {
            Ok(Ok(p)) => p,
            Ok(Err(e)) => {
                tracing::warn!("pair_register failed: {e}");
                ui.set_connecting();
                ui.set_status("Can't reach Alien AI right now. Retrying…");
                tokio::time::sleep(Duration::from_secs(3)).await;
                continue;
            }
            Err(e) => {
                tracing::warn!("pair_register task failed: {e}");
                ui.set_connecting();
                ui.set_status("Can't reach Alien AI right now. Retrying…");
                tokio::time::sleep(Duration::from_secs(3)).await;
                continue;
            }
        };

        ui.set_code(&pending.display_code, pending.expires_in_sec);
        tracing::info!(
            code = %pending.display_code,
            expires_sec = pending.expires_in_sec,
            "==> [PAIRING REQUIRED] Enter code '{}' in Alien AI -> Devices -> Pair with Code",
            pending.display_code
        );
        let deadline = pending.deadline();

        loop {
            if ui.user_requested_quit() {
                return Ok(());
            }

            tokio::select! {
                _ = tokio::time::sleep(Duration::from_secs(2)) => {}
                action = tray_rx.recv() => match action {
                    Some(TrayAction::Quit) => {
                        ui.close();
                        return Ok(());
                    }
                    Some(TrayAction::Unpair) | None => {}
                }
            }

            if ui.user_requested_quit() {
                return Ok(());
            }

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
                tracing::info!(
                    device_iid = device_iid,
                    "==> [PAIRED SUCCESSFULLY] Device claimed! Encrypting credentials and starting remote session"
                );
                session_key_save(&session_key, device_iid)?;
                let _ = crate::startup::set_autostart_enabled(true);
                ui.close();
                return Ok(());
            }

            if pair_should_reroll(&poll, deadline, std::time::Instant::now()) {
                tracing::info!("==> [PAIRING CODE EXPIRED] Requesting a new pairing code…");
                ui.set_connecting();
                ui.set_status("Code expired. Connecting for a new code…");
                break;
            }
        }
    }
}

pub fn device_name() -> String {
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
