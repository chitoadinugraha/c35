use std::time::Duration;

use c_remote_core::config::{session_key_load, session_key_save, server_url};
use c_remote_core::pair::{pair_poll, pair_register, pair_should_reroll, PairPoll};

const DEVICE_TYPE: &str = "browser";

pub async fn pair_until_claimed(cli: bool) -> anyhow::Result<()> {
    if session_key_load().is_some() {
        return Ok(());
    }

    let base_url = server_url();
    let device_name = device_name();

    #[cfg(windows)]
    let ui = c_remote_windows::pair_ui::PairUi::spawn(
        cli,
        c_remote_windows::pair_window::PairAgentKind::Browser,
    );

    loop {
        #[cfg(windows)]
        if ui.user_requested_quit() {
            return Ok(());
        }

        #[cfg(windows)]
        ui.set_connecting();

        let pending = match pair_register(&base_url, &device_name, DEVICE_TYPE).await {
            Ok(p) => p,
            Err(e) => {
                tracing::warn!("pair_register failed: {e}");
                #[cfg(windows)]
                ui.set_status(&c_remote_core::pair::pair_connect_status(&e, &base_url));
                tokio::time::sleep(Duration::from_secs(3)).await;
                continue;
            }
        };

        #[cfg(windows)]
        ui.set_code(&pending.display_code, pending.expires_in_sec);
        #[cfg(not(windows))]
        print_code_banner(&pending.display_code, pending.expires_in_sec);

        tracing::info!(
            code = %pending.display_code,
            expires_sec = pending.expires_in_sec,
            "remote browser pairing — enter code in Alien AI -> Devices -> Pair with Code"
        );

        let deadline = pending.deadline();
        while std::time::Instant::now() < deadline {
            tokio::time::sleep(Duration::from_secs(2)).await;

            #[cfg(windows)]
            if ui.user_requested_quit() {
                return Ok(());
            }

            let poll = match pair_poll(&base_url, &pending.secret).await {
                Ok(p) => p,
                Err(e) => {
                    tracing::warn!("pair_poll failed: {e}");
                    #[cfg(windows)]
                    ui.set_status(&c_remote_core::pair::pair_connect_status(&e, &base_url));
                    continue;
                }
            };

            if let PairPoll::Claimed { session_key, device_iid } = poll {
                #[cfg(windows)]
                {
                    ui.set_status("Device paired. Starting remote browser…");
                    ui.close();
                }
                session_key_save(&session_key, device_iid)?;
                tracing::info!(device_iid, "remote browser paired");
                println!("\nPaired successfully. Connecting...\n");
                return Ok(());
            }

            if pair_should_reroll(&poll, deadline, std::time::Instant::now()) {
                tracing::info!("pairing code expired; requesting new code");
                #[cfg(windows)]
                {
                    ui.set_connecting();
                    ui.set_status("Code expired. Connecting for a new code…");
                }
                break;
            }
        }
    }
}

#[cfg(not(windows))]
fn print_code_banner(code: &str, expires_in_sec: i64) {
    println!();
    println!("============================================================");
    println!("Alien AI Remote browser — Pair with Code");
    println!("Enter in app: Devices -> Pair with Code");
    println!("  [ {} ]  (refresh in {}s)", code, expires_in_sec);
    println!("============================================================");
    println!();
}

pub fn device_name() -> String {
    let host = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "Browser".into());
    format!("{host} Browser")
}
