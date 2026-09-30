use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use dashmap::DashMap;

static RUN_CANCEL: std::sync::LazyLock<DashMap<i64, Arc<AtomicBool>>> =
    std::sync::LazyLock::new(DashMap::new);

pub fn task_run_cancel_register(run_id: i64) -> Arc<AtomicBool> {
    let flag = Arc::new(AtomicBool::new(false));
    RUN_CANCEL.insert(run_id, flag.clone());
    flag
}

pub fn task_run_cancel_signal(run_id: i64) {
    if let Some(f) = RUN_CANCEL.get(&run_id) {
        f.value().store(true, Ordering::SeqCst);
    }
}

pub fn task_run_cancelled(run_id: i64) -> bool {
    RUN_CANCEL
        .get(&run_id)
        .map(|f| f.value().load(Ordering::SeqCst))
        .unwrap_or(false)
}

pub fn task_run_cancel_clear(run_id: i64) {
    RUN_CANCEL.remove(&run_id);
}

pub fn task_run_cancel_check(run_id: i64) -> Result<(), String> {
    if task_run_cancelled(run_id) {
        Err("cancelled".into())
    } else {
        Ok(())
    }
}
