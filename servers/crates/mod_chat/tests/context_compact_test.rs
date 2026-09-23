use c35_mod_chat::context_compact::{should_compact, summary_merge};

#[test]
fn should_compact_over_threshold() {
    assert!(should_compact("alienai", 10_000, 5_000, 80_000, 2_000));
    assert!(!should_compact("alienai", 1_000, 500, 5_000, 500));
}

#[test]
fn summary_merge_preserves_both() {
    let m = summary_merge("user likes IDR", "decided to use site ABC");
    assert!(m.contains("IDR"));
    assert!(m.contains("ABC"));
}
