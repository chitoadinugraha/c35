use std::time::Duration;

use c35_mod_device::{release_config_get, release_needs_update, release_summary};
use c35_proto::{AppReleaseNudge, WsRes, ws_res};
use futures_util::StreamExt;
use serde_json::Value;
use sqlx::PgPool;
use tokio::sync::mpsc;
use tracing::warn;

const WINDOWS_APP_RELEASE_PLATFORM: &str = "windows";
const WINDOWS_RELEASE_NATS_SUBJECT: &str = "c35.release.windows";
const RELEASE_NUDGE_INTERVAL: Duration = Duration::from_secs(90);

fn send_nudge(tx: &mpsc::UnboundedSender<WsRes>, version: i64) {
    let _ = tx.send(WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::AppReleaseNudge(AppReleaseNudge {
            platform: WINDOWS_APP_RELEASE_PLATFORM.to_string(),
            version,
        })),
    });
}

fn version_from_nats_payload(payload: &[u8]) -> i64 {
    if payload.is_empty() {
        return 0;
    }
    let Ok(v) = serde_json::from_slice::<Value>(payload) else {
        return 0;
    };
    v.get("version")
        .and_then(|x| x.as_i64().or_else(|| x.as_u64().map(|u| u as i64)))
        .unwrap_or(0)
}

fn spawn_release_nudge_loop(pool: PgPool, app_build: i64, tx: mpsc::UnboundedSender<WsRes>) {
    if app_build <= 0 {
        return;
    }
    tokio::spawn(async move {
        loop {
            let needs = match release_config_get(&pool, WINDOWS_APP_RELEASE_PLATFORM).await {
                Ok(Some(rel)) => release_needs_update(app_build, &rel),
                _ => false,
            };
            if !needs {
                break;
            }
            let version = match release_config_get(&pool, WINDOWS_APP_RELEASE_PLATFORM).await {
                Ok(Some(rel)) => release_summary(&rel).0,
                _ => 0,
            };
            send_nudge(&tx, version);
            tokio::time::sleep(RELEASE_NUDGE_INTERVAL).await;
        }
    });
}

/// Per-app WebSocket fanout for Windows desktop OTA (platform query param == 3).
pub fn attach_windows_release_nudge(
    pool: PgPool,
    nats: Option<&async_nats::Client>,
    app_build: i64,
    tx: mpsc::UnboundedSender<WsRes>,
) {
    if app_build <= 0 {
        return;
    }
    spawn_release_nudge_loop(pool.clone(), app_build, tx.clone());

    let Some(nats) = nats.cloned() else {
        return;
    };
    tokio::spawn(async move {
        if let Ok(mut sub) = nats.subscribe(WINDOWS_RELEASE_NATS_SUBJECT.to_string()).await {
            while let Some(msg) = sub.next().await {
                let version = version_from_nats_payload(msg.payload.as_ref());
                send_nudge(&tx, version);
            }
        } else {
            warn!(
                "app ws: failed to subscribe {}",
                WINDOWS_RELEASE_NATS_SUBJECT
            );
        }
    });
}