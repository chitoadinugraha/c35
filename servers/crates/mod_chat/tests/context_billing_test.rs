use c35_mod_chat::ContextBillingExtra;

#[test]
fn total_extra_sums() {
    let mut b = ContextBillingExtra::default();
    b.compaction_cost_usd = 0.002;
    b.memory_extract_cost_usd = 0.001;
    assert!((b.total_extra_usd() - 0.003).abs() < 1e-9);
}
