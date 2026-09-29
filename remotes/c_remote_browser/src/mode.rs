use c_remote_core::config::config_load;

pub fn headless_default() -> bool {
    std::env::var("C35_BROWSER_HEADLESS").as_deref() == Ok("1")
}

pub fn headless_from_config() -> bool {
    if std::env::var("C35_BROWSER_HEADLESS").as_deref() == Ok("0") {
        return false;
    }
    config_load()
        .and_then(|j| j.get("browser_mode").and_then(|v| v.as_str()).map(|s| s == "background"))
        .unwrap_or(false)
        || headless_default()
}