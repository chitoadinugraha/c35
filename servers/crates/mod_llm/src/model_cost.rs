use crate::llm_catalog::catalog_price;

fn token_cost_usd(tokens_in: i32, tokens_out: i32, in_ppm: i64, out_ppm: i64) -> f64 {
    let in_cost = tokens_in as f64 * in_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    let out_cost = tokens_out as f64 * out_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    in_cost + out_cost
}

pub fn model_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    if model.trim().eq_ignore_ascii_case("local") || (tokens_in == 0 && tokens_out == 0) {
        return 0.0;
    }
    let Some((in_ppm, out_ppm)) = catalog_price(model)
        .or_else(|| crate::catalog_price::price_for_model_id(model))
    else {
        tracing::warn!(model, "model_cost_usd: unknown model, billing 0");
        return 0.0;
    };
    token_cost_usd(tokens_in, tokens_out, in_ppm, out_ppm)
}
