use std::path::Path;

use c35_mod_site::guest_design::{FeaturedContact, GuestDesign};
use c35_mod_site::render::{block_html_render, guest_shell_html, ProductRow};
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
        }],
        &caps,
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
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
    );
    let html = guest_shell_html(
        &design,
        &format!("{profile}{links}{product}{partners}{clients}"),
    );

    assert!(html.contains("--accent:#E11D48"));
    assert!(html.contains("--page-bg:#111111"));
    assert!(html.contains("data-backdrop=\"glow\""));
    assert!(html.contains("backdrop-glow"));

    let profile_html = section(&html, "profile");
    assert!(profile_html.contains("data-guest=\"profile\""));
    assert!(!profile_html.contains("<img"));
    assert!(profile_html.contains("Rose Atelier"));

    let link_html = section(&html, "link");
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
    assert_eq!(boot["design"]["card"]["id"], "solid");
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
