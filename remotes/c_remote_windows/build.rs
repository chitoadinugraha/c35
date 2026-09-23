fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let icon = std::path::Path::new("resources").join("alien_rounded.ico");
    let fallback = std::path::Path::new("..")
        .join("..")
        .join("clients")
        .join("app")
        .join("windows")
        .join("runner")
        .join("resources")
        .join("app_icon.ico");
    let icon = if icon.exists() { icon } else { fallback };
    if icon.exists() {
        let mut res = winres::WindowsResource::new();
        res.set_icon(icon.to_str().unwrap());
        res.set("ProductName", "Alien AI Remote Agent");
        res.set("FileDescription", "Alien AI Remote Agent");
        if let Err(e) = res.compile() {
            eprintln!("winres: {e}");
        }
    }
}
