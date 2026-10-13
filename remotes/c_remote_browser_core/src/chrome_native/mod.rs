mod host;
mod ipc;
mod parent;
pub mod messages;

pub use host::run_chrome_native_host;

pub fn should_run_native_host() -> bool {
    if std::env::args().any(|a| a == "--chrome-native-host" || a.starts_with("chrome-extension://")) {
        return true;
    }
    parent::launched_by_chrome_browser()
}
