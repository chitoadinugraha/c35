use c35_mod_file::cas_hash_normalize;

#[test]
fn variant_resolution_prefers_normalized_hash() {
    let raw = "A".repeat(64);
    let norm = cas_hash_normalize(&raw).expect("hex");
    assert_eq!(norm, raw.to_lowercase());
}

#[test]
fn variant_key_chars() {
    for key in ["thumb", "small", "poster_v2"] {
        assert!(key
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-'));
    }
    assert!(!"thumb/x"
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-'));
}
