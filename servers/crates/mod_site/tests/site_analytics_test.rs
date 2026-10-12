use c35_mod_site::{normalize_analytics_path, visitor_key_hash};

#[test]
fn visitor_key_stable() {
    let a = visitor_key_hash("abc").unwrap();
    let b = visitor_key_hash("abc").unwrap();
    assert_eq!(a, b);
    assert_eq!(a.len(), 64);
}

#[test]
fn visitor_key_requires_id() {
    assert!(visitor_key_hash("").is_err());
    assert!(visitor_key_hash("   ").is_err());
}

#[test]
fn normalize_path_defaults() {
    assert_eq!(normalize_analytics_path(""), "/");
    assert_eq!(normalize_analytics_path("about"), "/about");
    assert_eq!(normalize_analytics_path("/x"), "/x");
    assert_eq!(normalize_analytics_path("#/shop"), "/shop");
}
