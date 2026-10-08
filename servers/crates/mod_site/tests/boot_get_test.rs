use c35_mod_site::site_boot_json_assemble;
use c35_proto::SiteBootMode;
use serde_json::json;

#[test]
fn site_boot_json_assemble_includes_pages_and_capabilities() {
    let doc = json!({
        "pages": [{
            "path": "/",
            "title": "Home",
            "blocks": [{ "id": "g1", "type": "product_grid", "props": { "filter": "all" } }]
        }],
        "theme": { "accent": "#2563eb" },
        "meta": {
            "seo_title": "Shop",
            "product_design": { "titleFontSize": 18, "titleColor": "#111111" }
        }
    });
    let caps = json!({ "commerce": true });
    let boot = site_boot_json_assemble(
        42,
        "Warung",
        "warung-bu-siti",
        "pic123",
        SiteBootMode::Draft,
        &doc,
        &caps,
        serde_json::Map::new(),
        serde_json::Map::new(),
        &[],
        &[],
    );
    assert_eq!(boot["site_id"], 42);
    assert_eq!(boot["name"], "Warung");
    assert_eq!(boot["alien_id"], "warung-bu-siti");
    assert_eq!(boot["avatar_url"], "/fs/pic123?v=thumb");
    assert_eq!(boot["mode"], "draft");
    assert_eq!(boot["capabilities"]["commerce"], true);
    assert_eq!(boot["pages"].as_array().unwrap().len(), 1);
    assert_eq!(boot["theme"]["accent"], "#2563eb");
    assert_eq!(boot["meta"]["seo_title"], "Shop");
    assert_eq!(boot["product_design"]["titleFontSize"], 18);
    assert_eq!(boot["product_design"]["titleColor"], "#111111");
    assert!(boot["product_preload"].is_object());
    assert!(boot["links"].as_array().unwrap().is_empty());
}
