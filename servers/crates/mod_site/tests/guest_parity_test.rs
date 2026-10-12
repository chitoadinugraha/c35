use std::fs;
use std::path::{Path, PathBuf};

use c35_mod_site::guest_design::GuestDesign;
use c35_mod_site::render::{block_html_render, product_detail_article_html, ProductRow};
use c35_mod_site::site_boot_json_assemble;
use c35_proto::{SiteBootMode, SitePost};
use serde::Deserialize;
use serde_json::{json, Value};

fn fixtures_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures")
}

fn guest_design_min_theme() -> String {
    fs::read_to_string(fixtures_dir().join("guest_design_min.json"))
        .expect("guest_design_min.json")
}

#[derive(Debug, Deserialize)]
struct ParityHubPost {
    post_id: i64,
    #[serde(default)]
    title: String,
    #[serde(default)]
    caption: String,
    #[serde(default)]
    body: String,
}

impl ParityHubPost {
    fn to_site_post(&self) -> SitePost {
        SitePost {
            post_id: self.post_id,
            title: self.title.clone(),
            caption: self.caption.clone(),
            body: self.body.clone(),
            ..Default::default()
        }
    }
}

#[derive(Debug, Deserialize)]
struct ParityFixture {
    block_type: String,
    expected_data_guest: String,
    props: Value,
    #[serde(default)]
    hub_posts: Vec<ParityHubPost>,
    #[serde(default)]
    assert_contains: Vec<String>,
    #[serde(default)]
    assert_not_contains: Vec<String>,
}

fn parity_fixture_paths() -> Vec<PathBuf> {
    let dir = fixtures_dir();
    let mut paths: Vec<PathBuf> = fs::read_dir(&dir)
        .expect("fixtures dir")
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| {
            p.file_name()
                .and_then(|n| n.to_str())
                .map(|n| n.starts_with("guest_parity_") && n.ends_with(".json"))
                .unwrap_or(false)
        })
        .collect();
    paths.sort();
    paths
}

fn render_parity_block(fixture: &ParityFixture, design: &GuestDesign) -> String {
    let hub_posts: Vec<SitePost> = fixture.hub_posts.iter().map(|p| p.to_site_post()).collect();
    block_html_render(
        &fixture.block_type,
        &fixture.props,
        &[],
        &json!({}),
        None,
        1,
        &[],
        &hub_posts,
        None,
        design,
        &[],
        &json!({}),
    )
}

fn assert_parity_fixture(name: &str, fixture: &ParityFixture, html: &str) {
    let marker = format!("data-guest=\"{}\"", fixture.expected_data_guest);
    assert!(
        html.contains(&marker),
        "{name}: expected {marker} in HTML"
    );
    for needle in &fixture.assert_contains {
        assert!(html.contains(needle), "{name}: missing `{needle}`");
    }
    for needle in &fixture.assert_not_contains {
        assert!(!html.contains(needle), "{name}: must not contain `{needle}`");
    }
}

#[test]
fn parity_fixtures_from_json_match_data_guest() {
    let theme = guest_design_min_theme();
    let design = GuestDesign::from_theme_json(&theme);
    for path in parity_fixture_paths() {
        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("fixture");
        let raw = fs::read_to_string(&path).expect("read fixture");
        let fixture: ParityFixture = serde_json::from_str(&raw).expect("parse fixture");
        let html = render_parity_block(&fixture, &design);
        assert_parity_fixture(name, &fixture, &html);
    }
}

#[test]
fn parity_hero_block_uses_guest_hub_hero() {
    let design = GuestDesign::from_theme_json("{}");
    let html = block_html_render(
        "hero",
        &json!({"title": "Hello", "subtitle": "World"}),
        &[],
        &json!({}),
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    assert!(html.contains("data-guest=\"hero\""));
    assert!(html.contains("guest-hub-hero"));
    assert!(!html.contains("hero-cta"));
}

#[test]
fn parity_golden_natepaperie_hub_block_types() {
    let path = fixtures_dir().join("golden/natepaperie_hub.json");
    let doc: Value = serde_json::from_str(&fs::read_to_string(path).expect("natepaperie_hub"))
        .expect("parse natepaperie_hub");
    let blocks = doc["blocks"].as_array().expect("blocks array");
    let types: Vec<&str> = blocks
        .iter()
        .filter_map(|b| b.get("type").and_then(|t| t.as_str()))
        .collect();
    assert_eq!(
        types,
        [
            "hub_profile",
            "hours",
            "links",
            "social_feed",
            "product_grid"
        ]
    );
    assert_eq!(doc["alien_id"], "natepaperie");
}

#[test]
fn parity_boot_json_has_guest_site_boot_keys() {
    let theme: Value = serde_json::from_str(&guest_design_min_theme()).unwrap();
    let doc = json!({
        "pages": [{
            "path": "/",
            "title": "Home",
            "blocks": [{ "id": "g1", "type": "product_grid", "props": { "filter": "all" } }]
        }],
        "theme": theme,
        "meta": { "seo_title": "Parity" }
    });
    let boot = site_boot_json_assemble(
        42,
        "Parity",
        "parity-demo",
        "",
        SiteBootMode::Draft,
        &doc,
        &json!({ "commerce": true }),
        serde_json::Map::new(),
        serde_json::Map::new(),
        &[],
        &[],
        &[],
    );
    const KEYS: &[&str] = &[
        "site_id",
        "site_iid",
        "name",
        "alien_id",
        "avatar_url",
        "mode",
        "meta",
        "product_design",
        "theme",
        "pages",
        "capabilities",
        "product_preload",
        "product_preload_meta",
        "links",
        "posts_preload",
        "design",
        "effects",
        "featured_contacts",
    ];
    for key in KEYS {
        assert!(boot.get(key).is_some(), "boot missing key `{key}`");
    }
    assert!(boot["design"].is_object());
    assert!(boot["pages"].as_array().unwrap().len() == 1);
}

#[test]
fn parity_hub_profile_location_not_link() {
    let design = GuestDesign::from_theme_json("{}");
    let html = block_html_render(
        "hub_profile",
        &json!({
            "title": "Demo",
            "subtitle": "Bio",
            "location_label": "Jakarta",
            "show_hours": false
        }),
        &[],
        &json!({}),
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    assert!(html.contains("hub-location"));
    assert!(!html.contains("hub-chip"));
    assert!(!html.contains("<a class=\"hub-chip\""));
}

#[test]
fn parity_product_grid_default_title_and_tile() {
    let design = GuestDesign::from_theme_json("{}");
    let html = block_html_render(
        "product_grid",
        &json!({}),
        &[],
        &json!({}),
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    assert!(html.contains("product-grid-title"));
    assert!(html.contains("Katalog &amp; Layanan"));
}

#[test]
fn parity_product_detail_article_matches_preview_shape() {
    let html = product_detail_article_html(&ProductRow {
        product_id: 9,
        name: "Latte".into(),
        desc: "Hot".into(),
        price: 28000,
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
        icon: "mdi:coffee".into(),
        stock_show_to_customer: true,
        stock_qty: Some(3),
    });
    assert!(html.contains("data-guest=\"site_product\""));
    assert!(html.contains("Stock: 3"));
    assert!(html.contains("guest-add-btn"));
    assert!(html.contains("Rp 28.000"));
}

#[test]
fn parity_hub_profile_hero_cta_and_location() {
    let design = GuestDesign::from_theme_json("{}");
    let html = block_html_render(
        "hub_profile",
        &json!({
            "title": "Demo Hub",
            "subtitle": "Bio line",
            "location_label": "Jakarta",
            "show_hours": false
        }),
        &[],
        &json!({}),
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    assert!(html.contains("guest-hub-hero"));
    assert!(html.contains("guest-hub-cta"));
    assert!(html.contains("Hubungi Kami"));
    assert!(html.contains("hub-location"));
}

#[test]
fn parity_links_row_icon_and_label() {
    let design = GuestDesign::from_theme_json("{}");
    let html = block_html_render(
        "links",
        &json!({
            "title": "Follow",
            "links": [{ "label": "Shop", "url": "https://example.com", "icon": "website" }]
        }),
        &[],
        &json!({}),
        None,
        1,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    assert!(html.contains("guest-link-list"));
    assert!(html.contains("guest-link-platform-icon"));
    assert!(html.contains("guest-link-label"));
    assert!(html.contains("links-block-title"));
}

#[test]
fn parity_shell_cart_inset_in_css() {
    let css_path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../../clients/web/static/site-guest/site-guest.v1.css");
    let css = fs::read_to_string(css_path).expect("site-guest.v1.css");
    assert!(css.contains(".guest-page-main"));
    assert!(css.contains("padding: 0 16px 88px"));
    assert!(css.contains("max-width: 720px"));
}

#[test]
fn parity_order_track_data_guest() {
    let design = GuestDesign::from_theme_json("{}");
    let html = block_html_render(
        "order_track",
        &json!({}),
        &[],
        &json!({}),
        None,
        99,
        &[],
        &[],
        None,
        &design,
        &[],
        &json!({}),
    );
    assert!(html.contains("data-guest=\"order\""));
}
