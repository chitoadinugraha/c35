use c35_mod_billing::{billing_cost_usd, billing_cost_wholesale_usd, RETAIL_MARKUP};

#[test]
fn wholesale_times_markup_equals_retail_for_frontier_model() {
    let model = "gemini-2.5-flash-lite";
    let tokens_in = 10_000;
    let tokens_out = 2_000;
    let wholesale = billing_cost_wholesale_usd(model, tokens_in, tokens_out);
    let retail = billing_cost_usd(model, tokens_in, tokens_out);
    assert!(wholesale > 0.0);
    assert!((wholesale * RETAIL_MARKUP - retail).abs() < 1e-12);
}

#[test]
fn alienai_cost_matches_locked_pool_rates() {
    let retail = billing_cost_usd("alienai", 10_000, 2_000);
    assert!((retail - 0.029).abs() < 1e-9);
    let wholesale = billing_cost_wholesale_usd("alienai", 10_000, 2_000);
    // 10k * 0.075 / 1M + 2k * 0.30 / 1M = 0.00075 + 0.0006 = 0.00135
    assert!((wholesale - 0.00135).abs() < 1e-9);
}
