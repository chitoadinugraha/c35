use std::sync::atomic::{AtomicBool, Ordering};

static UNPAIR_REQUESTED: AtomicBool = AtomicBool::new(false);

pub enum ConnExit {
    Completed,
    Unpaired,
}

pub fn request_unpair() {
    UNPAIR_REQUESTED.store(true, Ordering::SeqCst);
}

pub fn unpair_requested() -> bool {
    UNPAIR_REQUESTED.load(Ordering::SeqCst)
}

pub fn reset_unpair_flag() {
    UNPAIR_REQUESTED.store(false, Ordering::SeqCst);
}
