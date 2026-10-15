use crate::llm_catalog::catalog_price_full;

fn token_cost_with_cache_usd(
    tokens_in: i32,
    tokens_out: i32,
    cached_tokens: i32,
    in_ppm: i64,
    out_ppm: i64,
    cache_ppm: i64,
) -> f64 {
    let regular_in = (tokens_in - cached_tokens).max(0);
    let cached_in = cached_tokens.min(tokens_in).max(0);
    let in_cost = regular_in as f64 * in_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    let cache_cost = cached_in as f64 * cache_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    let out_cost = tokens_out as f64 * out_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    in_cost + cache_cost + out_cost
}

pub fn model_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    model_cost_with_cache_usd(model, tokens_in, tokens_out, 0)
}

pub fn model_cost_with_cache_usd(
    model: &str,
    tokens_in: i32,
    tokens_out: i32,
    cached_tokens: i32,
) -> f64 {
    if model.trim().eq_ignore_ascii_case("local")
        || (tokens_in == 0 && tokens_out == 0 && cached_tokens == 0)
    {
        return 0.0;
    }
    let Some((in_ppm, out_ppm, cache_ppm)) = catalog_price_full(model) else {
        tracing::warn!(model, "model_cost_usd: unknown model, billing 0");
        return 0.0;
    };
    token_cost_with_cache_usd(tokens_in, tokens_out, cached_tokens, in_ppm, out_ppm, cache_ppm)
}
