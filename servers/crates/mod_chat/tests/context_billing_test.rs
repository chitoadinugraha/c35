use c35_mod_chat::ContextBillingExtra;

#[test]
fn total_extra_sums() {
    let mut b = ContextBillingExtra::default();
    b.compaction_cost_usd = 0.002;
    b.memory_extract_cost_usd = 0.001;
    assert!((b.total_extra_usd() - 0.003).abs() < 1e-9);
}

#[test]
fn doc_ocr_extra_rolls_into_total_and_meta() {
    let mut b = ContextBillingExtra::default();
    b.doc_ocr_cost_usd = 0.01;
    b.doc_ocr_pages = 1;
    assert!((b.total_extra_usd() - 0.01).abs() < 1e-9);
    let meta = b.to_log_meta();
    assert!(meta.get("doc_ocr_cost_usd").is_some());
    assert!(meta.get("compaction_cost_usd").is_some());

    let zero = ContextBillingExtra::default();
    assert_eq!(zero.to_log_meta(), serde_json::json!({}));
}
