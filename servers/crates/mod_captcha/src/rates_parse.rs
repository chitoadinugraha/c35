use std::collections::HashMap;

use anyhow::{anyhow, Result};

const MIN_USD: f64 = 1e-6;
const MAX_USD: f64 = 1.0;

pub fn parse_pricing_html(html: &str) -> Result<HashMap<String, f64>> {
    let lower = html.to_ascii_lowercase();
    let mut out = HashMap::new();
    let labels: [(&str, &[&str]); 4] = [
        ("recaptcha_v2", &["recaptcha v2", "recaptcha-v2", "recaptcha v 2"]),
        ("recaptcha_v3", &["recaptcha v3", "recaptcha-v3", "recaptcha v 3"]),
        ("hcaptcha", &["hcaptcha", "h-captcha"]),
        ("image", &["image captcha", "normal captcha", "simple captcha"]),
    ];
    for (key, patterns) in labels {
        let mut found = None;
        for pat in patterns {
            if let Some(pos) = lower.find(pat) {
                if let Some(usd) = extract_usd_per_solve_near(html, pos) {
                    found = Some(usd);
                    break;
                }
            }
        }
        if let Some(usd) = found {
            out.insert(key.to_string(), usd);
        }
    }
    if out.len() < 2 {
        return Err(anyhow!("captcha_rates_parse_failed: too few kinds parsed"));
    }
    Ok(out)
}

fn extract_usd_per_solve_near(html: &str, label_start: usize) -> Option<f64> {
    let end = (label_start + 1200).min(html.len());
    let slice = html.get(label_start..end)?;
    let slice_lower = slice.to_ascii_lowercase();
    let dollar = slice.find('$')?;
    let amount = parse_dollar_amount(slice.get(dollar + 1..)?)?;
    if amount <= 0.0 {
        return None;
    }
    let per_1k = slice_lower.contains("/ 1000")
        || slice_lower.contains("/1000")
        || slice_lower.contains("per 1000")
        || slice_lower.contains("per1000")
        || slice_lower.contains("1,000")
        || slice_lower.contains("1000 captcha");
    let per_solve = if per_1k { amount / 1000.0 } else { amount };
    if per_solve < MIN_USD || per_solve > MAX_USD {
        return None;
    }
    Some(per_solve)
}

fn parse_dollar_amount(s: &str) -> Option<f64> {
    let mut n = String::new();
    for c in s.chars().take(12) {
        if c.is_ascii_digit() || c == '.' {
            n.push(c);
        } else if !n.is_empty() {
            break;
        }
    }
    if n.is_empty() {
        return None;
    }
    n.parse().ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fixture_pricing_sample() {
        let html = include_str!("../tests/fixtures/2captcha_pricing_sample.html");
        let m = parse_pricing_html(html).expect("parse");
        assert!((m["recaptcha_v2"] - 0.002_99).abs() < 1e-6);
        assert!((m["recaptcha_v3"] - 0.002_99).abs() < 1e-6);
        assert!((m["hcaptcha"] - 0.002_99).abs() < 1e-6);
        assert!((m["image"] - 0.000_5).abs() < 1e-6);
    }
}
