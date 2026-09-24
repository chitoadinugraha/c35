use std::sync::MutexGuard;

use c35_mod_platform::TEST_ENV_LOCK;

pub fn env_lock() -> MutexGuard<'static, ()> {
    TEST_ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner())
}
