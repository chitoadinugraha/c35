/// Micro-USD per million tokens (µUSD/M). $0.15/M input => 150_000.
const DEFAULT_INPUT_MICRO_PER_M: i64 = 150_000;
const DEFAULT_OUTPUT_MICRO_PER_M: i64 = 600_000;

fn token_cost_usd(tokens_in: i32, tokens_out: i32, in_ppm: i64, out_ppm: i64) -> f64 {
    let in_cost = tokens_in as f64 * in_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    let out_cost = tokens_out as f64 * out_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    in_cost + out_cost
}

fn price_for_model(model: &str) -> (i64, i64) {
    let m = model.trim().to_ascii_lowercase();
    match m.as_str() {
        "alienai" | "auto" | "" | "local" => (75_000, 300_000),
        "gemini-3.1-flash-lite" | "models/gemini-3.1-flash-lite" => (75_000, 300_000),
        "gemini-3.5-flash-lite" | "models/gemini-3.5-flash-lite" => (75_000, 300_000),
        "gemini-3.8-flash-lite" | "models/gemini-3.8-flash-lite" => (75_000, 300_000),
        "gemini-2.5-flash" | "models/gemini-2.5-flash" => (DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M),
        _ if m.contains("flash-lite") || m.contains("flash_lite") => (75_000, 300_000),
        _ if m.contains("flash") => (DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M),
        _ if m.contains("pro") => (1_250_000, 5_000_000),
        _ => (DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M),
    }
}

pub fn model_cost_usd(model: &str, tokens_in: i32, tokens_out: i32) -> f64 {
    if model.trim().eq_ignore_ascii_case("local") || (tokens_in == 0 && tokens_out == 0) {
        return 0.0;
    }
    let (in_ppm, out_ppm) = super::catalog_price(model).unwrap_or_else(|| price_for_model(model));
    token_cost_usd(tokens_in, tokens_out, in_ppm, out_ppm)
}
