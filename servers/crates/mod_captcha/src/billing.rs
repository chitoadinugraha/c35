//! Captcha solve wholesale (USD). Live rates from fetcher → `ai.config`; compile-time fallback.

use c35_mod_billing::billing_to_retail_usd;

use crate::rates_cache::captcha_rates_wholesale_usd;
use crate::types::CaptchaKind;

/// reCAPTCHA v2 — $2.99 / 1000 (compile-time fallback).
pub const WHOLESALE_RECAPTCHA_V2_USD: f64 = 0.002_99;
/// reCAPTCHA v3 — $2.99 / 1000
pub const WHOLESALE_RECAPTCHA_V3_USD: f64 = 0.002_99;
/// hCaptcha — $2.99 / 1000
pub const WHOLESALE_HCAPTCHA_USD: f64 = 0.002_99;
/// Image captcha — $0.50 / 1000
pub const WHOLESALE_IMAGE_USD: f64 = 0.000_5;

pub fn compiled_wholesale_usd(kind: CaptchaKind) -> f64 {
    match kind {
        CaptchaKind::RecaptchaV2 => WHOLESALE_RECAPTCHA_V2_USD,
        CaptchaKind::RecaptchaV3 => WHOLESALE_RECAPTCHA_V3_USD,
        CaptchaKind::Hcaptcha => WHOLESALE_HCAPTCHA_USD,
        CaptchaKind::Image => WHOLESALE_IMAGE_USD,
    }
}

pub fn captcha_wholesale_usd(kind: CaptchaKind) -> f64 {
    captcha_rates_wholesale_usd(kind).unwrap_or_else(|| compiled_wholesale_usd(kind))
}

pub fn captcha_retail_usd(kind: CaptchaKind) -> f64 {
    billing_to_retail_usd(captcha_wholesale_usd(kind))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn retail_is_markup() {
        let w = captcha_wholesale_usd(CaptchaKind::RecaptchaV2);
        let r = captcha_retail_usd(CaptchaKind::RecaptchaV2);
        assert!((r - w * 1.5).abs() < 1e-9);
    }
}
