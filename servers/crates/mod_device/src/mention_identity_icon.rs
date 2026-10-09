use serde_json::Value;

use crate::release_config::meta_browser_engine;

/// Wire format for composer mention `MentionItem.icon` (see `mention_device_icon.dart`).
pub fn mention_identity_icon(kind: &str, identity_type: &str, meta: &Value, pic: &str) -> String {
    let pic = pic.trim();
    if !pic.is_empty() && (kind == "site" || kind == "bot") {
        return format!("identity-pic:{pic}");
    }
    match kind {
        "iot" => "device-kind:iot".into(),
        "remote" => mention_device_kind_icon(identity_type, meta),
        "site" => "iconify://mdi:web".into(),
        "bot" => "iconify://mdi:robot-outline".into(),
        _ => "alternate_email".into(),
    }
}

fn mention_device_kind_icon(identity_type: &str, meta: &Value) -> String {
    let t = identity_type.to_lowercase();
    match t.as_str() {
        "android" => "device-kind:android".into(),
        "windows" => "device-kind:windows".into(),
        "browser" => {
            let engine = meta_browser_engine(meta);
            if engine.eq_ignore_ascii_case("extension") {
                "device-kind:browser:extension".into()
            } else {
                format!("device-kind:browser:{engine}")
            }
        }
        "" => "device-kind:remote".into(),
        _ => format!("device-kind:remote:{t}"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn mention_icon_windows_and_android() {
        assert_eq!(
            mention_identity_icon("remote", "windows", &json!({}), ""),
            "device-kind:windows"
        );
        assert_eq!(
            mention_identity_icon("remote", "android", &json!({}), ""),
            "device-kind:android"
        );
    }

    #[test]
    fn mention_icon_browser_extension() {
        assert_eq!(
            mention_identity_icon(
                "remote",
                "browser",
                &json!({"browser_engine": "extension"}),
                ""
            ),
            "device-kind:browser:extension"
        );
    }

    #[test]
    fn mention_icon_site_pic() {
        assert_eq!(
            mention_identity_icon("site", "web", &json!({}), "/fs/abc"),
            "identity-pic:/fs/abc"
        );
    }
}
