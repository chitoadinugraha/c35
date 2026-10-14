use c35_mod_site::{
    guest_product_can_add_to_cart, guest_product_price_label, guest_product_stock_customer_label,
    product_grid_display, GUEST_PRODUCT_PRICE_CONTACT,
};
use serde_json::json;

#[test]
fn guest_product_price_contact_us() {
    assert_eq!(guest_product_price_label(GUEST_PRODUCT_PRICE_CONTACT), "Contact us");
    assert_eq!(guest_product_price_label(0), "");
    assert_eq!(guest_product_price_label(50_000), "Rp 50.000");
    assert!(!guest_product_can_add_to_cart(GUEST_PRODUCT_PRICE_CONTACT));
    assert!(!guest_product_can_add_to_cart(0));
    assert!(guest_product_can_add_to_cart(1));
}

#[test]
fn guest_product_stock_customer_label_unit_and_cap() {
    assert_eq!(
        guest_product_stock_customer_label(true, Some(12), "kg", 9),
        Some("Stock: 9+ kg".into())
    );
    assert_eq!(guest_product_stock_customer_label(false, Some(3), "pcs", 0), None);
}

#[test]
fn product_grid_display_defaults_grid() {
    assert_eq!(product_grid_display(&json!({}), &json!({})), "grid");
    assert_eq!(product_grid_display(&json!({"display": "list"}), &json!({})), "list");
    assert_eq!(
        product_grid_display(&json!({}), &json!({"catalog_display": "list"})),
        "list"
    );
}
