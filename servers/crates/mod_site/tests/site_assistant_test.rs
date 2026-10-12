use c35_mod_site::{
    site_assistant_boot_extras, site_assistant_capabilities_merge, site_boot_json_assemble,
    site_guest_ai_assistant_public, site_guest_knowledge_public,
};
use c35_proto::SiteBootMode;
use serde_json::json;

#[test]
fn site_assistant_capabilities_merge_injects_bot_iid() {
    let caps = json!({ "commerce": true });
    let merged = site_assistant_capabilities_merge(&caps, 9001);
    assert_eq!(merged["commerce"], true);
    assert_eq!(merged["assistant_bot_iid"], 9001);
    let unchanged = site_assistant_capabilities_merge(&caps, 0);
    assert!(unchanged.get("assistant_bot_iid").is_none());
}

#[test]
fn site_guest_knowledge_public_caps_items_and_chars() {
    let mut rows = Vec::new();
    for i in 0..60 {
        rows.push(json!({
            "id": format!("k{i}"),
            "title": "T",
            "content": "x".repeat(600),
        }));
    }
    let meta = json!({ "knowledge": rows });
    let out = site_guest_knowledge_public(&meta);
    let arr = out.as_array().unwrap();
    assert!(arr.len() <= 50);
    let total_chars: usize = arr
        .iter()
        .map(|r| {
            r["title"].as_str().unwrap_or("").len() + r["content"].as_str().unwrap_or("").len()
        })
        .sum();
    assert!(total_chars <= 32_500);
}

#[test]
fn site_guest_ai_assistant_public_reads_meta() {
    let meta = json!({
        "ai_assistant": {
            "chat_enabled": false,
            "call_enabled": true,
            "chat_placeholder": "Hi"
        }
    });
    let ai = site_guest_ai_assistant_public(&meta);
    assert_eq!(ai["chat_enabled"], false);
    assert_eq!(ai["call_enabled"], true);
    assert_eq!(ai["chat_placeholder"], "Hi");
}

#[test]
fn site_boot_json_includes_guest_ai_extras() {
    let doc = json!({
        "pages": [],
        "theme": {},
        "meta": {
            "ai_assistant": { "chat_enabled": true, "call_enabled": false },
            "knowledge": [{ "id": "1", "title": "Hours", "content": "9-5" }]
        }
    });
    let boot = site_boot_json_assemble(
        7,
        "Cafe",
        "cafe",
        "",
        SiteBootMode::Published,
        &doc,
        &json!({}),
        serde_json::Map::new(),
        serde_json::Map::new(),
        &[],
        &[],
        &[],
    );
    let extras = site_assistant_boot_extras(doc.get("meta").unwrap());
    for (k, v) in extras {
        assert_eq!(boot[k], v);
    }
    assert_eq!(boot["knowledge"][0]["title"], "Hours");
    assert_eq!(boot["ai_assistant"]["chat_enabled"], true);
}
