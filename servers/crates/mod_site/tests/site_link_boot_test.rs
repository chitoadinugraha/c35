use c35_mod_site::site_boot_json_assemble;
use c35_proto::{SiteBootMode, SiteLink};
use serde_json::json;

#[test]
fn site_boot_json_assemble_orders_links() {
    let links = [
        SiteLink {
            site_iid: 1,
            link_id: 20,
            sort_order: 2,
            label: "Second".into(),
            url: "https://b.example".into(),
            icon: "".into(),
            is_pinned: false,
            active: true,
            ..Default::default()
        },
        SiteLink {
            site_iid: 1,
            link_id: 10,
            sort_order: 1,
            label: "First".into(),
            url: "https://a.example".into(),
            icon: "iconify://mdi:web".into(),
            is_pinned: true,
            active: true,
            ..Default::default()
        },
    ];
    let boot = site_boot_json_assemble(
        1,
        "Hub",
        "hub",
        "",
        SiteBootMode::Published,
        &json!({ "pages": [], "theme": {}, "meta": {} }),
        &json!({}),
        serde_json::Map::new(),
        serde_json::Map::new(),
        &links,
        &[],
        &[],
    );
    let arr = boot["links"].as_array().expect("links array");
    assert_eq!(arr.len(), 2);
    assert_eq!(arr[0]["label"], "Second");
    assert_eq!(arr[1]["is_pinned"], true);
    assert_eq!(arr[1]["icon"], "iconify://mdi:web");
}
