//! Background agent daemon loop for Android: manages pairing, WebSocket connection,
//! and profile synchronization with c35-server.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, OnceLock, RwLock};
use std::time::{Duration, Instant};

use c_remote_core::agent_profile::{agent_profile_fetch, owner_display};
use c_remote_core::config::{
    device_iid_load, session_key_clear, session_key_load, session_key_save,
};
use c_remote_core::conn_ws::{conn_ws_run_reconnect, is_invalid_session};
use c_remote_core::pair::{pair_connect_status, pair_poll, pair_register, pair_unpair, PairPoll};
use c_remote_core::ConnExit;
use serde::{Deserialize, Serialize};
use tokio::sync::Notify;
use tracing::{info, warn};

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct DaemonStatusSnapshot {
    pub paired: bool,
    pub online: bool,
    pub status: String,
    pub pairing_code: String,
    pub pairing_seconds_remaining: i64,
    pub owner_label: String,
    pub device_name: String,
    pub package_name: String,
    pub active_viewers: usize,
}

static STATUS_SNAPSHOT: RwLock<Option<DaemonStatusSnapshot>> = RwLock::new(None);
static DAEMON_RUNNING: AtomicBool = AtomicBool::new(false);
static UNPAIR_NOTIFY: OnceLock<Arc<Notify>> = OnceLock::new();

pub fn status_snapshot_json() -> String {
    if let Ok(guard) = STATUS_SNAPSHOT.read() {
        if let Some(ref snap) = *guard {
            return serde_json::to_string(snap).unwrap_or_else(|_| "{}".into());
        }
    }
    serde_json::to_string(&DaemonStatusSnapshot::default()).unwrap_or_else(|_| "{}".into())
}

fn update_snapshot<F: FnOnce(&mut DaemonStatusSnapshot)>(f: F) {
    if let Ok(mut guard) = STATUS_SNAPSHOT.write() {
        let mut snap = guard.clone().unwrap_or_default();
        f(&mut snap);
        *guard = Some(snap);
    }
}

pub fn trigger_unpair() {
    if let Some(notify) = UNPAIR_NOTIFY.get() {
        notify.notify_one();
    }
}

pub fn start_daemon_loop(
    server_url: String,
    data_dir: String,
    device_name: String,
    status_change_cb: Box<dyn Fn(String) + Send + Sync + 'static>,
) {
    if DAEMON_RUNNING.swap(true, Ordering::SeqCst) {
        info!("Daemon loop already running");
        return;
    }

    let unpair_notify = Arc::new(Notify::new());
    let _ = UNPAIR_NOTIFY.set(unpair_notify.clone());

    // Point c_remote_core to Android app data directory
    std::env::set_var("C35_AGENT_STORAGE", &data_dir);

    let update_base = server_url.clone();
    tokio::spawn(async move {
        c_remote_core::update::update_run_loop(update_base).await;
    });

    tokio::spawn(async move {
        info!(server = %server_url, dev = %device_name, "Starting Android Agent Daemon Loop");

        update_snapshot(|s| {
            s.device_name = device_name.clone();
            s.status = "Initializing…".into();
            s.paired = session_key_load().is_some();
        });
        status_change_cb(status_snapshot_json());

        loop {
            if !DAEMON_RUNNING.load(Ordering::SeqCst) {
                break;
            }

            // =================================================================
            // PHASE 1: UNPAIRED -> RUN PAIRING REGISTRATION & POLL
            // =================================================================
            if session_key_load().is_none() {
                update_snapshot(|s| {
                    s.paired = false;
                    s.online = false;
                    s.owner_label = "".into();
                    s.status = "Registering pairing code…".into();
                });
                status_change_cb(status_snapshot_json());

                let mut pair_reg = None;
                while pair_reg.is_none() {
                    if !DAEMON_RUNNING.load(Ordering::SeqCst) {
                        return;
                    }
                    match pair_register(&server_url, &device_name, "android").await {
                        Ok(pending) => {
                            info!(code = %pending.display_code, "Received pairing code from server");
                            pair_reg = Some(pending);
                        }
                        Err(e) => {
                            let msg = pair_connect_status(&e, &server_url);
                            warn!(err = %e, "Failed to register pair code: {msg}");
                            update_snapshot(|s| {
                                s.status = msg;
                            });
                            status_change_cb(status_snapshot_json());
                            tokio::time::sleep(Duration::from_secs(3)).await;
                        }
                    }
                }

                let pending = pair_reg.unwrap();
                let deadline = pending.deadline();
                let code = pending.display_code.clone();

                update_snapshot(|s| {
                    s.pairing_code = code.clone();
                    s.pairing_seconds_remaining = pending.expires_in_sec;
                    s.status = "Ready to pair in Alien AI app".into();
                });
                status_change_cb(status_snapshot_json());

                // Poll loop until claimed or expired
                let mut claimed_info = None;
                loop {
                    if !DAEMON_RUNNING.load(Ordering::SeqCst) {
                        return;
                    }

                    let now = Instant::now();
                    let remain_secs = if now < deadline {
                        deadline.duration_since(now).as_secs() as i64
                    } else {
                        0
                    };

                    update_snapshot(|s| {
                        s.pairing_seconds_remaining = remain_secs;
                    });
                    status_change_cb(status_snapshot_json());

                    match pair_poll(&server_url, &pending.secret).await {
                        Ok(PairPoll::Claimed { session_key, device_iid }) => {
                            info!(device_iid, "Device claimed by user!");
                            claimed_info = Some((session_key, device_iid));
                            break;
                        }
                        Ok(PairPoll::Expired) => {
                            info!("Pairing code expired, refreshing…");
                            break;
                        }
                        Ok(PairPoll::Pending) => {
                            if now >= deadline {
                                info!("Pairing code deadline reached, refreshing…");
                                break;
                            }
                        }
                        Err(e) => {
                            warn!(err = %e, "Pair poll transient error");
                        }
                    }

                    tokio::time::sleep(Duration::from_millis(1500)).await;
                }

                if let Some((sess_key, dev_iid)) = claimed_info {
                    if let Err(e) = session_key_save(&sess_key, dev_iid) {
                        warn!(err = %e, "Failed to save session key");
                    }
                    update_snapshot(|s| {
                        s.paired = true;
                        s.pairing_code = "".into();
                        s.status = "Pairing successful! Connecting…".into();
                    });
                    status_change_cb(status_snapshot_json());
                } else {
                    // Code expired, loop around to re-register
                    continue;
                }
            }

            // =================================================================
            // PHASE 2: PAIRED -> CONNECT WEBSOCKET & PROFILE SYNC
            // =================================================================
            let session_key = match session_key_load() {
                Some(k) => k,
                None => continue,
            };
            let device_iid = device_iid_load().unwrap_or(0);

            // Fetch profile
            if let Some(prof) = agent_profile_fetch(&server_url, &session_key).await {
                let owner = owner_display(&prof);
                update_snapshot(|s| {
                    s.owner_label = owner;
                    if !prof.device_name.is_empty() {
                        s.device_name = prof.device_name.clone();
                    }
                    s.package_name = prof.device_package_name.clone();
                });
                status_change_cb(status_snapshot_json());
            }

            update_snapshot(|s| {
                s.paired = true;
                s.online = true;
                s.status = "Connected to Alien AI Cloud".into();
            });
            status_change_cb(status_snapshot_json());

            let ws_url = server_url.clone();
            let sess = session_key.clone();
            let mut conn = tokio::spawn(async move {
                conn_ws_run_reconnect(&ws_url, &sess, device_iid).await
            });

            tokio::select! {
                r = &mut conn => {
                    match r {
                        Ok(Ok(ConnExit::Unpaired)) => {
                            info!("Unpaired via server push");
                            let _ = session_key_clear();
                        }
                        Ok(Ok(ConnExit::Completed)) => {
                            warn!("conn_ws exited normally");
                        }
                        Ok(Err(e)) if is_invalid_session(&e) => {
                            info!("Session key invalid, clearing to re-pair");
                            let _ = session_key_clear();
                        }
                        Ok(Err(e)) => {
                            warn!(err = %e, "conn_ws connection error");
                        }
                        Err(e) => {
                            warn!(err = %e, "conn_ws task join error");
                        }
                    }
                }
                _ = unpair_notify.notified() => {
                    info!("Local unpair triggered");
                    conn.abort();
                    let _ = pair_unpair(&server_url, &session_key).await;
                    let _ = session_key_clear();
                }
            }

            update_snapshot(|s| {
                s.online = false;
                s.status = "Disconnected".into();
            });
            status_change_cb(status_snapshot_json());
            tokio::time::sleep(Duration::from_secs(1)).await;
        }
    });
}
