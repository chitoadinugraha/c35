pub fn site_link_display_normalize(raw: &str) -> &'static str {
    match raw.trim().to_ascii_lowercase().as_str() {
        "icon" => "icon",
        "card" => "card",
        "" | "list" | "icon_label" | "chip" => "list",
        _ => "list",
    }
}
