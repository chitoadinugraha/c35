use c35_mod_site::{
    guest_layout_mode, guest_layout_page_max_css, guest_product_price_label_i18n, GuestI18n,
    GUEST_PRODUCT_PRICE_CONTACT,
};
use serde_json::json;

#[test]
fn guest_i18n_indonesian_default() {
    let i18n = GuestI18n::from_meta(&json!({}));
    assert_eq!(guest_product_price_label_i18n(GUEST_PRODUCT_PRICE_CONTACT, &i18n), "Hubungi kami");
    assert_eq!(i18n.tile_contact_cta(), "Hubungi");
}

#[test]
fn guest_i18n_english_meta() {
    let i18n = GuestI18n::from_meta(&json!({"lang": "en"}));
    assert_eq!(guest_product_price_label_i18n(GUEST_PRODUCT_PRICE_CONTACT, &i18n), "Contact us");
}

#[test]
fn guest_layout_auto_store() {
    assert_eq!(guest_layout_mode(&json!({}), 9), "store");
    assert_eq!(guest_layout_mode(&json!({}), 3), "hub");
    assert_eq!(guest_layout_mode(&json!({"guest_layout": "store"}), 0), "store");
}

#[test]
fn guest_layout_hub_max_width() {
    assert_eq!(guest_layout_page_max_css("hub"), "600px");
    assert_eq!(guest_layout_page_max_css("store"), "min(1040px, 100%)");
}
