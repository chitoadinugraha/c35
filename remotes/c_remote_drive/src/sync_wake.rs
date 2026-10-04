use std::collections::HashSet;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{LazyLock, Mutex, OnceLock};

use tokio::sync::Notify;

static WAKE: OnceLock<Notify> = OnceLock::new();
static PENDING: LazyLock<Mutex<HashSet<String>>> = LazyLock::new(|| Mutex::new(HashSet::new()));
static CYCLES: AtomicU32 = AtomicU32::new(0);

pub fn wake_notify() -> &'static Notify {
    WAKE.get_or_init(Notify::new)
}

pub fn wake_sync() {
    wake_notify().notify_waiters();
}

pub fn pending_push(rel_path: &str) {
    let rel = rel_path.replace('\\', "/").trim_start_matches('/').to_string();
    if rel.is_empty() {
        return;
    }
    if let Ok(mut g) = PENDING.lock() {
        g.insert(rel);
    }
    wake_sync();
}

pub fn pending_take() -> HashSet<String> {
    PENDING.lock().map(|mut g| g.drain().collect()).unwrap_or_default()
}

pub fn cycle_tick() -> u32 {
    CYCLES.fetch_add(1, Ordering::Relaxed) + 1
}

/// Full directory push scan about every 8 idle-heavy cycles (~15+ min).
pub fn should_full_push_scan() -> bool {
    cycle_tick() % 8 == 0
}
