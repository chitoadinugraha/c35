/// Default label for Chrome extension remote (`meta.browser_engine=extension`).
pub fn chrome_extension_device_name() -> String {
    let user = std::env::var("USERNAME")
        .or_else(|_| std::env::var("USER"))
        .ok()
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "User".into());
    let nice = {
        let mut ch = user.chars();
        match ch.next() {
            None => user,
            Some(f) => f.to_uppercase().collect::<String>() + ch.as_str(),
        }
    };
    format!("{nice}'s Google Chrome")
}

pub fn browser_device_name() -> String {
    let host = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "Browser".into());
    format!("{host} Browser")
}
