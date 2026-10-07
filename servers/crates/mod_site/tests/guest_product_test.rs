use c35_mod_site::{
    product_cursor_decode, product_cursor_encode, product_grid_page_size,
};
use serde_json::json;

#[test]
fn product_cursor_roundtrip() {
    let enc = product_cursor_encode(10, 99_001);
    assert_eq!(enc, "10:99001");
    let (sort, pid) = product_cursor_decode(&enc).unwrap().unwrap();
    assert_eq!(sort, 10);
    assert_eq!(pid, 99_001);
    assert!(product_cursor_decode("").unwrap().is_none());
}

#[test]
fn product_cursor_rejects_invalid() {
    assert!(product_cursor_decode("bad").is_err());
    assert!(product_cursor_decode("1").is_err());
}

#[test]
fn product_grid_page_size_defaults_and_clamps() {
    assert_eq!(product_grid_page_size(&json!({})), 24);
    assert_eq!(product_grid_page_size(&json!({"page_size": 12})), 12);
    assert_eq!(product_grid_page_size(&json!({"limit": 30})), 30);
    assert_eq!(product_grid_page_size(&json!({"page_size": 100})), 48);
    assert_eq!(product_grid_page_size(&json!({"page_size": 0})), 24);
}
