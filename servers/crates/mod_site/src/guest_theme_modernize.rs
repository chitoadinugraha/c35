//! Render-time theme uplift for legacy light storefronts (does not mutate stored draft until publish).

use serde_json::{json, Map, Value};

pub const GUEST_THEME_RENDER_STYLE_VERSION: i32 = 2;

/// Default hub storefront theme for new sites (`site.create` and editor seeds).
pub fn default_modern_hub_theme(accent: &str) -> Value {
    json!({
        "accent": accent,
        "layout": "hub",
        "renderStyleVersion": GUEST_THEME_RENDER_STYLE_VERSION,
        "card": {
            "id": "elevated",
            "params": {
                "radius": 16.0,
                "shadow": 2.0,
                "borderWidth": 0.0,
                "padding": 12.0
            }
        },
        "profile": {
            "avatarSize": 88.0,
            "titleFontSize": 22.0,
            "bioFontSize": 14.0,
            "titleFontFamily": "Inter"
        },
        "product": { "titleTransform": "none" }
    })
}

/// Bump visual tokens for legacy mono/light themes so published HTML matches modern guest CSS.
pub fn modernize_theme_for_render(theme: &Value) -> Value {
    if !theme.is_object() {
        return theme.clone();
    }
    let dark = theme.get("dark").and_then(|v| v.as_bool()).unwrap_or(false);
    if dark {
        return apply_dark_glass_defaults(theme);
    }
    let ver = theme
        .get("renderStyleVersion")
        .and_then(|v| v.as_i64())
        .unwrap_or(0) as i32;
    if ver >= GUEST_THEME_RENDER_STYLE_VERSION {
        return theme.clone();
    }
    let mut out = theme.clone();
    let obj = out.as_object_mut().expect("theme object");
    modernize_light_card(obj);
    modernize_light_profile(obj);
    modernize_light_product(obj);
    obj.insert(
        "renderStyleVersion".into(),
        json!(GUEST_THEME_RENDER_STYLE_VERSION),
    );
    out
}

fn modernize_light_card(obj: &mut Map<String, Value>) {
    let card = obj
        .entry("card")
        .or_insert_with(|| json!({ "id": "solid", "params": {} }));
    if !card.is_object() {
        *card = json!({ "id": "solid", "params": {} });
    }
    let card_obj = card.as_object_mut().expect("card");
    let id = card_obj
        .get("id")
        .and_then(|v| v.as_str())
        .unwrap_or("solid");
    if id == "solid" || id.is_empty() {
        card_obj.insert("id".into(), json!("elevated"));
    }
    let params = card_obj
        .entry("params")
        .or_insert_with(|| json!({}));
    if !params.is_object() {
        *params = json!({});
    }
    let p = params.as_object_mut().expect("card params");
    let radius = p.get("radius").and_then(|v| v.as_f64()).unwrap_or(8.0);
    if radius < 14.0 {
        p.insert("radius".into(), json!(16.0));
    }
    let shadow = p.get("shadow").and_then(|v| v.as_f64()).unwrap_or(1.0);
    if shadow < 2.0 {
        p.insert("shadow".into(), json!(2.0));
    }
    if !p.contains_key("borderWidth") {
        p.insert("borderWidth".into(), json!(0.0));
    }
    let border_w = p.get("borderWidth").and_then(|v| v.as_f64()).unwrap_or(1.0);
    if border_w > 0.5 {
        p.insert("borderWidth".into(), json!(0.0));
    }
}

fn modernize_light_profile(obj: &mut Map<String, Value>) {
    let profile = obj.entry("profile").or_insert_with(|| json!({}));
    if !profile.is_object() {
        *profile = json!({});
    }
    let p = profile.as_object_mut().expect("profile");
    bump_f64(p, "avatarSize", 88.0, 72.0);
    bump_f64(p, "titleFontSize", 22.0, 18.0);
    bump_f64(p, "bioFontSize", 14.0, 12.0);
    if !p.contains_key("titleFontFamily")
        || p.get("titleFontFamily").and_then(|v| v.as_str()) == Some("")
    {
        p.insert("titleFontFamily".into(), json!("Inter"));
    }
}

fn modernize_light_product(obj: &mut Map<String, Value>) {
    let product = obj.entry("product").or_insert_with(|| json!({}));
    if !product.is_object() {
        *product = json!({});
    }
    let p = product.as_object_mut().expect("product");
    if !p.contains_key("titleTransform") {
        p.insert("titleTransform".into(), json!("none"));
    }
}

fn apply_dark_glass_defaults(theme: &Value) -> Value {
    let ver = theme
        .get("renderStyleVersion")
        .and_then(|v| v.as_i64())
        .unwrap_or(0) as i32;
    if ver >= GUEST_THEME_RENDER_STYLE_VERSION {
        return theme.clone();
    }
    let mut out = theme.clone();
    let obj = out.as_object_mut().expect("theme");
    let card = obj
        .entry("card")
        .or_insert_with(|| json!({ "id": "glass", "params": {} }));
    if let Some(c) = card.as_object_mut() {
        let id = c.get("id").and_then(|v| v.as_str()).unwrap_or("solid");
        if id == "solid" || id.is_empty() {
            c.insert("id".into(), json!("glass"));
        }
        let params = c.entry("params").or_insert_with(|| json!({}));
        if let Some(p) = params.as_object_mut() {
            if !p.contains_key("radius") {
                p.insert("radius".into(), json!(16.0));
            }
            if !p.contains_key("blur") {
                p.insert("blur".into(), json!(14.0));
            }
        }
    }
    let profile = obj.entry("profile").or_insert_with(|| json!({}));
    if let Some(p) = profile.as_object_mut() {
        if !p.contains_key("titleFontFamily")
            || p.get("titleFontFamily").and_then(|v| v.as_str()) == Some("")
        {
            p.insert("titleFontFamily".into(), json!("Outfit"));
        }
    }
    obj.insert(
        "renderStyleVersion".into(),
        json!(GUEST_THEME_RENDER_STYLE_VERSION),
    );
    out
}

fn bump_f64(map: &mut Map<String, Value>, key: &str, target: f64, legacy_cap: f64) {
    let cur = map.get(key).and_then(|v| v.as_f64()).unwrap_or(legacy_cap);
    if cur <= legacy_cap {
        map.insert(key.into(), json!(target));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn default_modern_hub_theme_matches_render_style_version() {
        let theme = default_modern_hub_theme("#3366FF");
        assert_eq!(
            theme.get("renderStyleVersion").and_then(|v| v.as_i64()),
            Some(2)
        );
        assert_eq!(theme.get("accent").and_then(|v| v.as_str()), Some("#3366FF"));
        assert_eq!(
            theme.pointer("/card/params/radius").and_then(|v| v.as_f64()),
            Some(16.0)
        );
    }

    #[test]
    fn modernize_light_bumps_radius_and_version() {
        let theme = json!({
            "dark": false,
            "card": { "id": "solid", "params": { "radius": 8, "shadow": 1 } },
            "profile": { "avatarSize": 72, "titleFontSize": 18 }
        });
        let out = modernize_theme_for_render(&theme);
        assert_eq!(
            out.get("renderStyleVersion").and_then(|v| v.as_i64()),
            Some(2)
        );
        let radius = out
            .pointer("/card/params/radius")
            .and_then(|v| v.as_f64())
            .unwrap_or(0.0);
        assert!(radius >= 16.0);
    }

    #[test]
    fn modernize_skips_when_version_current() {
        let theme = json!({
            "dark": false,
            "renderStyleVersion": 2,
            "card": { "params": { "radius": 8 } }
        });
        let out = modernize_theme_for_render(&theme);
        assert_eq!(
            out.pointer("/card/params/radius").and_then(|v| v.as_f64()),
            Some(8.0)
        );
    }
}
