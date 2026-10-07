use c35_mod_site::site_handle_normalize;

#[test]
fn site_handle_rejects_pure_digits() {
    assert!(site_handle_normalize("12345").is_err());
}

#[test]
fn site_handle_accepts_slug() {
    assert_eq!(site_handle_normalize("Kopi Senja").unwrap(), "kopi-senja");
}

#[test]
fn site_handle_min_length() {
    assert!(site_handle_normalize("ab").is_err());
}
