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
