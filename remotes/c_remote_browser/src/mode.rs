use c_remote_core::config::config_load;

pub fn headless_default() -> bool {
    std::env::var("C35_BROWSER_HEADLESS").as_deref() == Ok("1")
}

pub fn chrome_extension_install_exe() -> bool {
    std::env::current_exe()
        .map(|p| {
            let s = p.to_string_lossy().to_lowercase();
            s.contains("chrome_extension") && s.contains("install")
        })
        .unwrap_or(false)
}

pub fn is_extension_engine() -> bool {
    match std::env::var("C35_BROWSER_ENGINE").as_deref() {
        Ok("extension" | "ext") => true,
        Ok(s) if s.eq_ignore_ascii_case("extension") => true,
        _ => chrome_extension_install_exe(),
    }
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