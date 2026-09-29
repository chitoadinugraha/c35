//! Pause Playwright screencast when no WebRTC viewers (saves CPU).

use std::sync::Arc;
use std::time::Duration;

use tracing::info;

use crate::browser_state::BrowserState;
use crate::extension_ipc::extension_bridge_get;
use crate::mode;

fn idle_poll_ms() -> u64 {
    std::env::var("C35_BROWSER_IDLE_MS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(1000)
        .clamp(250, 60_000)
}

async fn screencast_stop(state: &BrowserState) {
    let bridge = state
        .engine
        .lock()
        .ok()
        .and_then(|g| g.as_ref().map(|e| e.bridge.clone()));
    if let Some(bridge) = bridge {
        let _ = bridge
            .call("screencast.stop", serde_json::json!({}))
            .await;
    }
}

async fn screencast_start(state: &BrowserState) {
    let bridge = state
        .engine
        .lock()
        .ok()
        .and_then(|g| g.as_ref().map(|e| e.bridge.clone()));
    if let Some(bridge) = bridge {
        let _ = bridge
            .call("screencast.start", serde_json::json!({}))
            .await;
    }
}

fn spawn_extension_capture_idle_loop(_state: Arc<BrowserState>) {
    tokio::spawn(async move {
        let poll_ms = idle_poll_ms();
        let mut interval = tokio::time::interval(Duration::from_millis(poll_ms));
        interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
        let mut capture_on = false;
        loop {
            interval.tick().await;
            let sessions = c_remote_core::update::active_sessions();
            let bridge = extension_bridge_get();
            if sessions == 0 && capture_on {
                if let Some(b) = bridge.as_ref() {
                    let _ = b.capture_stop();
                }
                capture_on = false;
                info!(poll_ms, "extension capture paused (no WebRTC viewers)");
            } else if sessions > 0 && !capture_on {
                if let Some(b) = bridge.as_ref() {
                    if b.capture_start().is_ok() {
                        capture_on = true;
                        info!(active_sessions = sessions, "extension capture started");
                    }
                }
            }
        }
    });
}

pub fn spawn_screencast_idle_loop(state: Arc<BrowserState>) {
    if mode::is_extension_engine() {
        spawn_extension_capture_idle_loop(state);
        return;
    }
    tokio::spawn(async move {
        let poll_ms = idle_poll_ms();
        let mut interval = tokio::time::interval(Duration::from_millis(poll_ms));
        interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
        let mut screencast_running = true;

        loop {
            interval.tick().await;
            let sessions = c_remote_core::update::active_sessions();
            if sessions == 0 && screencast_running {
                screencast_stop(&state).await;
                screencast_running = false;
                info!(poll_ms, "screencast paused (no WebRTC viewers)");
            } else if sessions > 0 && !screencast_running {
                screencast_start(&state).await;
                screencast_running = true;
                info!(active_sessions = sessions, "screencast resumed (viewer connected)");
            }
        }
    });
}
