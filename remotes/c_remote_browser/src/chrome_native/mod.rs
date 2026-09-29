mod host;
mod ipc;
mod parent;
pub mod messages;

pub use host::run_chrome_native_host;

pub fn should_run_native_host() -> bool {
    if std::env::args().any(|a| a == "--chrome-native-host") {
        return true;
    }
    if !crate::mode::chrome_extension_install_exe() {
        return false;
    }
    parent::launched_by_chrome_browser()
}
