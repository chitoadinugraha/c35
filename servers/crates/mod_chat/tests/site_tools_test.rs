use c35_mod_chat::{
    block_props_allowed, site_at_tokens, validate_block, validate_object_keys, validate_sitedoc, BLOCK_TYPES,
    META_KEYS, THEME_KEYS,
};
use serde_json::json;

#[test]
fn block_types_catalog_non_empty() {
    assert!(BLOCK_TYPES.contains(&"hero"));
    assert!(BLOCK_TYPES.contains(&"product_grid"));
    assert_eq!(block_props_allowed("hero").len(), 6);
}

#[test]
fn validate_hero_block_ok() {
    let block = json!({
        "id": "b1",
        "type": "hero",
        "props": { "title": "Welcome", "subtitle": "Shop now", "pic": "/fs/abc" }
    });
    assert!(validate_block(&block).is_ok());
}

#[test]
fn validate_block_rejects_unknown_type() {
    let block = json!({
        "id": "b1",
        "type": "carousel",
        "props": {}
    });
    let err = validate_block(&block).unwrap_err().to_string();
    assert!(err.contains("unknown block type"));
}

#[test]
fn validate_block_rejects_unknown_prop() {
    let block = json!({
        "id": "b1",
        "type": "hero",
        "props": { "title": "Hi", "backgroundColor": "#f00" }
    });
    let err = validate_block(&block).unwrap_err().to_string();
    assert!(err.contains("unknown block.props key"));
}

#[test]
fn validate_block_requires_id_and_props() {
    assert!(validate_block(&json!({ "type": "hero", "props": {} })).is_err());
    assert!(validate_block(&json!({ "id": "b1", "type": "hero" })).is_err());
}

#[test]
fn validate_sitedoc_ok() {
    let doc = json!({
        "pages": [{
            "path": "/",
            "title": "Home",
            "blocks": [
                { "id": "b1", "type": "hero", "props": { "title": "Warung" } },
                { "id": "b2", "type": "product_grid", "props": { "filter": "recommended" } }
            ]
        }],
        "theme": { "accent": "#ff0000", "font": "sans" },
        "meta": { "seo_title": "Warung Siti" }
    });
    assert!(validate_sitedoc(&doc).is_ok());
}

#[test]
fn validate_sitedoc_rejects_unknown_theme_key() {
    let doc = json!({
        "pages": [{ "path": "/", "title": "Home", "blocks": [] }],
        "theme": { "accent": "#f00", "custom_css": "bad" }
    });
    let err = validate_sitedoc(&doc).unwrap_err().to_string();
    assert!(err.contains("unknown theme key"));
}

#[test]
fn validate_object_keys_theme_meta_catalog() {
    let theme = json!({ "accent": "#000" }).as_object().unwrap().clone();
    validate_object_keys(&theme, THEME_KEYS, "theme").unwrap();
    let meta = json!({ "seo_title": "x" }).as_object().unwrap().clone();
    validate_object_keys(&meta, META_KEYS, "meta").unwrap();
}

#[test]
fn validate_sitedoc_nested_block_error_path() {
    let doc = json!({
        "pages": [{
            "path": "/",
            "title": "Home",
            "blocks": [{ "id": "b1", "type": "spacer", "props": { "size": "lg", "width": "full" } }]
        }]
    });
    let err = validate_sitedoc(&doc).unwrap_err().to_string();
    assert!(err.contains("pages[0].blocks[0]"));
    assert!(err.contains("unknown block.props key"));
}

#[test]
fn site_at_tokens_extracts_alien_id() {
    let tokens = site_at_tokens("@warung-siti make hero red and @warung-siti again");
    assert_eq!(tokens, vec!["warung-siti"]);
}
