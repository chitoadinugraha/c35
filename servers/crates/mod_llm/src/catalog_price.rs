/// Micro-USD per million tokens (µUSD/M). $0.15/M input => 150_000.
pub const DEFAULT_INPUT_MICRO_PER_M: i64 = 150_000;
pub const DEFAULT_OUTPUT_MICRO_PER_M: i64 = 600_000;

pub fn price_for_model_id(model: &str) -> Option<(i64, i64)> {
    let m = model.trim().to_ascii_lowercase();
    if m.is_empty() {
        return None;
    }
    if let Some((in_ppm, out_ppm)) = exact_price(&m) {
        return Some((in_ppm, out_ppm));
    }
    if m.contains("flash-lite") || m.contains("flash_lite") {
        return Some((75_000, 300_000));
    }
    if m.contains("flash") {
        return Some((DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M));
    }
    if m.contains("pro") {
        return Some((1_250_000, 5_000_000));
    }
    if m.starts_with("@cf/") {
        return Some((50_000, 150_000));
    }
    None
}

fn exact_price(model: &str) -> Option<(i64, i64)> {
    Some(match model {
        "gemini-2.5-flash" | "models/gemini-2.5-flash" => (DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M),
        "gemini-2.5-flash-lite" | "models/gemini-2.5-flash-lite" => (75_000, 300_000),
        "gemini-2.5-pro" | "models/gemini-2.5-pro" => (1_250_000, 5_000_000),
        "gemini-3.1-flash-lite" | "models/gemini-3.1-flash-lite" => (75_000, 300_000),
        "gemini-3-flash" | "models/gemini-3-flash" => (DEFAULT_INPUT_MICRO_PER_M, DEFAULT_OUTPUT_MICRO_PER_M),
        "gemini-3-pro" | "models/gemini-3-pro" => (1_250_000, 5_000_000),
        "@cf/meta/llama-3.1-8b-instruct" => (50_000, 150_000),
        _ => return None,
    })
}
