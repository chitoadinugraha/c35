//! Dual-wallet charge helpers (legacy billing_account USD + IDR legs).

pub fn billing_wallet_use_idr(billing_currency: &str) -> bool {
    billing_currency.trim().eq_ignore_ascii_case("IDR")
}

pub fn billing_wallet_after_charge(
    billing_currency: &str,
    balance_usd: f64,
    balance_idr: f64,
    charge_usd: f64,
    charge_idr: f64,
) -> Result<(f64, f64), String> {
    if billing_wallet_use_idr(billing_currency) {
        if balance_idr + 0.001 < charge_idr {
            return Err("insufficient unreserved balance".into());
        }
        Ok((balance_usd, balance_idr - charge_idr))
    } else {
        if balance_usd + 0.0000001 < charge_usd {
            return Err("insufficient unreserved balance".into());
        }
        Ok((balance_usd - charge_usd, balance_idr))
    }
}

pub fn billing_wallet_available(
    billing_currency: &str,
    balance_usd: f64,
    balance_idr: f64,
    held_usd: f64,
    held_idr: f64,
) -> f64 {
    if billing_wallet_use_idr(billing_currency) {
        (balance_idr - held_idr).max(0.0)
    } else {
        (balance_usd - held_usd).max(0.0)
    }
}
