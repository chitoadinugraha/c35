//! Report `browser_ready` / extension version to cluster (WS query + `agent.presence` logs).

use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use serde_json::{json, Value};
use tracing::warn;

use crate::browser_ensure::extension_version_sync_probe;
use crate::extension_install::install_extension_manifest_version;

const CACHE_TTL: Duration = Duration::from_secs(20);

struct ReadyCache {
    ready: bool,
    at: Instant,
}

fn ready_cache() -> &'static Mutex<ReadyCache> {
    static CACHE: OnceLock<Mutex<ReadyCache>> = OnceLock::new();
    CACHE.get_or_init(|| {
        Mutex::new(ReadyCache {
            ready: false,
            at: Instant::now() - CACHE_TTL,
        })
    })
}

pub fn refresh_browser_extension_connected() -> bool {
    let mut cache = ready_cache().lock().unwrap_or_else(|e| e.into_inner());
    if cache.at.elapsed() < CACHE_TTL {
        return cache.ready;
    }
    let ready = extension_version_sync_probe();
    cache.ready = ready;
    cache.at = Instant::now();
    ready
}

pub fn browser_extension_connected() -> bool {
    refresh_browser_extension_connected()
}

pub fn browser_presence_meta() -> Value {
    let install = install_extension_manifest_version();
    json!({
        "browser_ready": browser_extension_connected(),
        "browser_engine": "extension",
        "extension_install_version": install,
    })
}

pub fn agent_ws_query_suffix() -> String {
    let meta = browser_presence_meta();
    let ready = meta
        .get("browser_ready")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let mut url = format!("&browser_ready={}&browser_engine=extension", ready);
    if let Some(v) = meta
        .get("extension_install_version")
        .and_then(|x| x.as_str())
        .filter(|s| !s.is_empty())
    {
        url.push_str("&extension_install_version=");
        url.push_str(&urlencoding::encode(v));
    }
    url
}

pub fn register_agent_browser_ws_query() {
    c_remote_core::conn_ws::set_agent_ws_query_suffix(std::sync::Arc::new(|| agent_ws_query_suffix()));
}

pub fn spawn_browser_presence_reports() {
    tokio::spawn(async {
        let mut tick = tokio::time::interval(Duration::from_secs(45));
        tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
        loop {
            tick.tick().await;
            let session_key = c_remote_core::config::session_key_load();
            let base_url = c_remote_core::config::server_url();
            let key = match session_key {
                Some(k) if !k.trim().is_empty() => k,
                _ => continue,
            };
            let _ = tokio::task::spawn_blocking(refresh_browser_extension_connected).await;
            let meta = browser_presence_meta();
            c_remote_core::log_push::spawn_log_push(
                base_url,
                key,
                "presence".into(),
                "agent.presence".into(),
                "browser".into(),
                Some(meta),
            );
        }
    });
}

pub fn push_browser_presence_now() {
    let session_key = c_remote_core::config::session_key_load();
    let base_url = c_remote_core::config::server_url();
    let key = match session_key {
        Some(k) if !k.trim().is_empty() => k,
        _ => {
            warn!("browser presence push skipped: no session key");
            return;
        }
    };
    refresh_browser_extension_connected();
    c_remote_core::log_push::spawn_log_push(
        base_url,
        key,
        "presence".into(),
        "agent.presence".into(),
        "browser".into(),
        Some(browser_presence_meta()),
    );
}