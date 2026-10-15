use std::path::Path;

use c35_mod_site::guest_design::{guest_accent_resolve, FeaturedContact, GuestDesign, GUEST_DEFAULT_ACCENT};
use c35_mod_site::site_assistant_boot_extras;
use c35_mod_site::GuestI18n;
use c35_mod_site::render::{
    block_html_render, guest_hub_catalog_tabs_html, guest_hub_initial_tab, guest_root_css,
    guest_shell_html, ProductRow,
};
use c35_mod_site::site_boot_json_assemble;
use c35_proto::SiteBootMode;
use serde_json::json;

fn fixture_theme() -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/guest_design_min.json");
    std::fs::read_to_string(path).expect("guest_design_min.json")
}

fn section<'a>(html: &'a str, guest: &str) -> &'a str {
    let marker = format!("data-guest=\"{guest}\"");
    let start = html.find(&marker).unwrap_or_else(|| panic!("missing {marker}"));
    let rest = &html[start..];
    let end = rest.find("</section>").unwrap_or_else(|| panic!("unclosed {guest}"));
    &rest[..end]
}

#[test]
fn guest_accent_resolve_meta_primary_when_theme_empty() {
    assert_eq!(guest_accent_resolve(&json!({}), &json!({})), GUEST_DEFAULT_ACCENT);
    assert_eq!(
        guest_accent_resolve(&json!({}), &json!({"primary_color": "#3366FF"})),
        "#3366FF"
    );
    assert_eq!(
        guest_accent_resolve(&json!({"accent": "#ff0000"}), &json!({"primary_color": "#3366FF"})),
        "#ff0000"
    );
    let design = GuestDesign::from_theme_meta(&json!({}), &json!({"primary_color": "#3366FF"}));
    assert_eq!(design.accent, "#3366FF");
}

#[test]
fn guest_design_legacy_accent_keeps_defaults() {
    let design = GuestDesign::from_theme_json(r##"{"accent":"#ff0000"}"##);
    assert_eq!(design.accent, "#ff0000");
    assert!(!design.dark);
    assert_eq!(design.backdrop_id, "none");
    assert_eq!(design.card_id, "solid");
    assert_eq!(design.background_type, "none");
    assert_eq!(design.page_bg, "#F8F9FA");
    assert!(design.profile.show_avatar);
    assert!(design.profile.show_title);
    assert!(design.profile.show_bio);
    assert!(design.profile.show_location);
    assert!(design.profile.show_hours);
}

#[test]
fn guest_design_fixture_renders_tokens_blocks_and_strips() {
    let raw = fixture_theme();
    let design = GuestDesign::from_theme_json(&raw);
    assert_eq!(design.accent, "#E11D48");
    assert!(design.dark);
    assert_eq!(design.base, "rosegold");
    assert_eq!(design.page_bg, "#111111");
    assert_eq!(design.backdrop_id, "glow");
    assert_eq!(design.card_id, "solid");
    assert!(!design.profile.show_avatar);
    assert!(design.profile.show_title);
    assert_eq!(design.block_cards.get("link").map(|c| c.id.as_str()), Some("none"));
    assert_eq!(design.partners.header, "Featured Partners");
    assert_eq!(design.clients.header, "Featured Clients");

    let caps = json!({});
    let profile = block_html_render(
        "hub_profile",
        &json!({
            "title": "Rose Atelier",
            "subtitle": "Florist",
            "pic": "avatar-pic",
            "location_label": "Jakarta",
            "show_hours": true
        }),
        &[],
        &caps,
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({
            "open_hours": [{
                "startDay": 0,
                "startMin": 540,
                "endDay": 0,
                "endMin": 1020
            }]
        }),
    );
    assert!(
        profile.contains("guest-hub-hours-primary") || profile.contains("guest-hub-hours-chip"),
        "hub hours CTA from meta.open_hours: {profile}"
    );
    let links = block_html_render(
        "links",
        &json!({ "links": [{ "label": "Shop", "url": "https://example.com" }] }),
        &[],
        &caps,
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    let product = block_html_render(
        "product_grid",
        &json!({}),
        &[ProductRow {
            product_id: 7,
            name: "Bouquet".into(),
            desc: "Seasonal".into(),
            price: 120000,
            pic: "".into(),
            category: "".into(),
            sort_order: 0,
            can_reserve: false,
            duration_value: 0,
            duration_unit: String::new(),
            reservation_unit_selection: String::new(),
            reservation_inventory_mode: "capacity".into(),
            reservation_capacity: 1,
            reservation_hold_ttl_seconds: 3600,
            icon: String::new(),
            pics: vec![],
            stock_show_to_customer: false,
            stock_qty: None,
            stock_unit: String::new(),
            stock_show_max_qty: 0,
        }],
        &caps,
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    let featured = [FeaturedContact {
        id: 42,
        name: "Northwind".into(),
        pic: "/fs/north?v=thumb".into(),
        featured: "partners".into(),
    }];
    let partners = block_html_render(
        "partners_display",
        &json!({}),
        &[],
        &caps,
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &featured,
        &json!({}),
    );
    let clients = block_html_render(
        "clients_display",
        &json!({}),
        &[],
        &caps,
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &featured,
        &json!({}),
    );
    let html = guest_shell_html(
        &design,
        &format!("{profile}{links}{product}{partners}{clients}"),
    );

    assert!(html.contains("--accent:#E11D48"));
    assert!(html.contains("--page-bg:#111111"));
    assert!(html.contains("--theme-base:"));
    assert!(html.contains("--guest-tone:"));
    assert!(html.contains("data-backdrop=\"glow\""));
    assert!(html.contains("backdrop-glow"));
    assert!(html.contains("guest-backdrop"));
    assert!(html.contains("guest-backdrop-preset--glow"));

    let profile_html = section(&html, "profile");
    assert!(profile_html.contains("data-guest=\"profile\""));
    assert!(!profile_html.contains("<img"));
    assert!(profile_html.contains("Rose Atelier"));
    assert!(profile_html.contains("guest-hub-cta"));

    let link_html = section(&html, "link");
    assert!(link_html.contains("guest-link-list"));
    assert!(link_html.contains("guest-link-label"));
    assert!(!link_html.contains("class=\"card\""));
    assert!(!link_html.contains(" card"));

    let product_html = section(&html, "site_product");
    assert!(product_html.contains("font-size:22px"));
    assert!(product_html.contains("class=\"card\""));

    let partners_html = section(&html, "partners");
    assert!(partners_html.contains("Featured Partners"));
    assert_eq!(partners_html.matches("strip-item strip-").count(), 1);
    assert!(partners_html.contains("Northwind") || partners_html.contains("strip-item"));

    let clients_html = section(&html, "clients");
    assert!(clients_html.contains("Featured Clients"));
    assert_eq!(clients_html.matches("strip-item strip-").count(), 0);
}

#[test]
fn guest_root_css_includes_typography_tokens() {
    let design = GuestDesign::from_theme_json(&fixture_theme());
    let css = guest_root_css(&design);
    assert!(css.contains("--hub-title-size:"));
    assert!(css.contains("--hub-bio-size:"));
    assert!(css.contains("--hub-avatar-size:"));
    assert!(css.contains("--product-title-size:"));
    assert!(css.contains("--product-subtitle-size:"));
    assert!(css.contains("--product-price-size:"));
    assert!(css.contains("--card-shadow:"));
    assert!(css.contains("--product-title-transform:"));
    assert!(css.contains("--card-padding:"));
    assert!(css.contains("--card-blur:"));
    assert!(css.contains("--card-opacity:"));
    assert!(css.contains("--card-tint-strength:"));
    assert!(css.contains("--theme-base:"));
    assert!(css.contains("--surface:"));
    assert!(css.contains("--outline:"));
    assert!(css.contains("--guest-tone:"));
    assert!(css.contains("--backdrop-intensity:"));
    assert!(css.contains("--backdrop-softness:"));
    assert!(css.contains("--backdrop-scale:"));
}

#[test]
fn guest_root_css_backdrop_params_from_theme() {
    let design = GuestDesign::from_theme_json(
        r##"{"accent":"#ff0000","backdrop":{"id":"glow","params":{"intensity":0.8,"scale":1.2}}}"##,
    );
    let css = guest_root_css(&design);
    assert!(css.contains("--backdrop-intensity:0.8"));
    assert!(css.contains("--backdrop-scale:1.2"));
}

#[test]
fn guest_assistant_boot_extras_caps_knowledge() {
    let meta = json!({
        "ai_assistant": {
            "chat_enabled": true,
            "call_enabled": true,
            "chat_placeholder": "Hi",
            "chat_intro": "Welcome",
        },
        "knowledge": [
            {"title": "Hours", "content": "9-5"},
            {"title": "", "content": ""},
        ],
    });
    let boot = site_assistant_boot_extras(&meta);
    assert_eq!(boot["ai_assistant"]["chat_enabled"], true);
    assert_eq!(boot["ai_assistant"]["call_enabled"], true);
    assert_eq!(boot["knowledge"].as_array().unwrap().len(), 1);
    assert_eq!(boot["knowledge"][0]["title"], "Hours");
}

#[test]
fn guest_design_boot_json_fields() {
    let theme: serde_json::Value = serde_json::from_str(&fixture_theme()).unwrap();
    let contact = FeaturedContact {
        id: 42,
        name: "Northwind".into(),
        pic: "/fs/north?v=thumb".into(),
        featured: "partners".into(),
    };
    let boot = site_boot_json_assemble(
        9,
        "Rose",
        "rose",
        "",
        SiteBootMode::Draft,
        &json!({ "pages": [], "theme": theme, "meta": {} }),
        &json!({}),
        serde_json::Map::new(),
        serde_json::Map::new(),
        &[],
        &[],
        &[contact],
    );
    assert_eq!(boot["design"]["accent"], "#E11D48");
    assert_eq!(boot["design"]["dark"], true);
    assert_eq!(boot["design"]["base"], "rosegold");
    assert_eq!(boot["design"]["page_bg"], "#111111");
    assert_eq!(boot["design"]["backdrop_id"], "glow");
    assert_eq!(boot["design"]["card"]["id"], "glass");
    assert_eq!(
        boot["theme"].get("renderStyleVersion").and_then(|v| v.as_i64()),
        Some(2)
    );
    assert_eq!(boot["design"]["profile"]["showAvatar"], false);
    assert_eq!(boot["design"]["profile"]["showTitle"], true);
    assert_eq!(boot["design"]["product"]["titleFontSize"].as_f64(), Some(22.0));
    assert_eq!(boot["design"]["partners"]["header"], "Featured Partners");
    assert_eq!(boot["design"]["clients"]["header"], "Featured Clients");
    assert_eq!(boot["design"]["block_cards"]["link"]["id"], "none");
    assert_eq!(boot["featured_contacts"][0]["id"].as_i64(), Some(42));
    assert_eq!(boot["featured_contacts"][0]["name"], "Northwind");
    assert_eq!(boot["featured_contacts"][0]["pic"], "/fs/north?v=thumb");
    assert_eq!(boot["featured_contacts"][0]["featured"], "partners");
}

#[test]
fn guest_shell_emits_wrap_backdrop_and_storefront() {
    let design = GuestDesign::from_theme_json(&fixture_theme());
    let html = guest_shell_html(&design, "<section></section>");
    assert!(html.contains("class=\"wrap guest-page-main\""));
    assert!(html.contains("guest-storefront"));
    assert!(html.contains("guest-backdrop"));
    assert!(html.contains("data-backdrop=\"glow\""));
}

#[test]
fn guest_hub_initial_tab_respects_profile_default() {
    let posts_design = GuestDesign::from_theme_json(r##"{"profile":{"hubDefaultTab":"posts"}}"##);
    assert_eq!(guest_hub_initial_tab(&posts_design, true, true), "posts");
    let shop_design = GuestDesign::from_theme_json(r##"{"profile":{"hubDefaultTab":"shop"}}"##);
    assert_eq!(guest_hub_initial_tab(&shop_design, true, true), "shop");
    assert_eq!(guest_hub_initial_tab(&shop_design, true, false), "shop");
    assert_eq!(guest_hub_initial_tab(&posts_design, false, true), "posts");
}

#[test]
fn guest_hub_catalog_tabs_posts_default_hides_shop_panel() {
    let design = GuestDesign::from_theme_json(r##"{"profile":{"hubDefaultTab":"posts"}}"##);
    let tab = guest_hub_initial_tab(&design, true, true);
    let html = guest_hub_catalog_tabs_html(
        r#"<section class="product-grid" data-guest="site_product">shop</section>"#,
        r#"<li class="post-card">p</li>"#,
        tab,
        &GuestI18n::english(),
    );
    assert!(html.contains("data-guest=\"hub_catalog\""));
    assert!(html.contains("data-hub-panel=\"shop\" role=\"tabpanel\" hidden"));
    assert!(html.contains("data-hub-tab=\"posts\" role=\"tab\" aria-selected=\"true\""));
    assert!(!html.contains("data-hub-panel=\"posts\" role=\"tabpanel\" hidden"));
}

#[test]
fn guest_atmosphere_none_includes_accent_wash() {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/guest_atmosphere_none_light.json");
    let raw = std::fs::read_to_string(path).expect("guest_atmosphere_none_light.json");
    let design = GuestDesign::from_theme_json(&raw);
    assert_eq!(design.backdrop_id, "none");
    let html = guest_shell_html(&design, "");
    assert!(html.contains("guest-backdrop"));
    assert!(html.contains("guest-backdrop-color"));
    assert!(html.contains("guest-backdrop-accent"));
    assert!(!html.contains("guest-backdrop-preset--"));
}

#[test]
fn guest_atmosphere_preset_matrix_emits_preset_layer() {
    for id in ["glow", "mesh", "grain", "diamond", "aurora"] {
        let theme = format!(r##"{{"accent":"#E11D48","dark":true,"backdrop":{{"id":"{id}"}}}}"##);
        let design = GuestDesign::from_theme_json(&theme);
        let html = guest_shell_html(&design, "");
        assert!(
            html.contains(&format!("guest-backdrop-preset--{id}")),
            "missing preset layer for {id}"
        );
        assert!(
            !html.contains("guest-backdrop-accent"),
            "accent wash should not appear for preset {id}"
        );
    }
}