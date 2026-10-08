use c35_mod_site::{product_icon_id, product_icon_kind_from_rules, product_icon_name_key};

#[test]
fn name_key_strips_size_and_temperature() {
    assert_eq!(product_icon_name_key("Es Kopi Susu"), "kopi susu");
    assert_eq!(product_icon_name_key("Kopi Susu Panas"), "kopi susu");
    assert_eq!(product_icon_name_key("Large Iced Latte 500ml"), "latte");
}

#[test]
fn rules_prefer_specific_kind_over_drink() {
    assert_eq!(product_icon_kind_from_rules("kopi susu"), Some("coffee"));
    assert_eq!(
        product_icon_kind_from_rules(&product_icon_name_key("Es Teh")),
        Some("tea")
    );
    assert_eq!(product_icon_kind_from_rules("burger keju"), Some("burger"));
    assert_eq!(
        product_icon_kind_from_rules("nasi goreng spesial"),
        Some("rice")
    );
    assert_eq!(product_icon_id("coffee"), "mdi:coffee");
    assert_eq!(product_icon_id("nope"), "mdi:shopping");
}

#[test]
fn rules_miss_non_food() {
    assert_eq!(product_icon_kind_from_rules("kursi kayu"), None);
}

#[test]
fn rules_match_tokens_not_substrings() {
    assert_eq!(product_icon_kind_from_rules("steak"), Some("meat"));
    assert_eq!(product_icon_kind_from_rules("kopi susu"), Some("coffee"));
    assert_eq!(
        product_icon_kind_from_rules(&product_icon_name_key("Es Krim")),
        Some("ice_cream")
    );
}


#[test]
fn empty_pic_card_inlines_coffee_svg() {
    use c35_mod_site::render::{product_card_html, ProductRow};
    let row = ProductRow {
        product_id: 1,
        name: "Kopi".into(),
        desc: String::new(),
        price: 10000,
        pic: String::new(),
        category: String::new(),
        sort_order: 0,
        can_reserve: false,
        duration_value: 1,
        duration_unit: "day".into(),
        reservation_unit_selection: "system".into(),
        icon: "mdi:coffee".into(),
    };
    let html = product_card_html(&row, None);
    assert!(html.contains("class=\"product-ph\""));
    assert!(html.contains("M2 21h18v-2H2"));
    assert!(!html.contains("<img"));
    let photo = ProductRow {
        pic: "abc".into(),
        icon: "mdi:coffee".into(),
        ..row
    };
    let html = product_card_html(&photo, None);
    assert!(html.contains("<img"));
    assert!(!html.contains("product-ph"));
}
