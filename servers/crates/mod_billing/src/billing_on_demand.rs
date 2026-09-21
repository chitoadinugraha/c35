/// Pure on-demand billing math (allowance vs wallet, FX, holds). Unit-tested.
pub const DEFAULT_HOLD_USD: f64 = 0.05;

pub fn usd_to_native(cost_usd: f64, micro_per_usd: i64) -> f64 {
    if cost_usd <= 0.0 || micro_per_usd <= 0 {
        return 0.0;
    }
    cost_usd * micro_per_usd as f64 / 1_000_000.0
}

pub fn native_to_usd(amount_native: f64, micro_per_usd: i64) -> f64 {
    if amount_native <= 0.0 || micro_per_usd <= 0 {
        return 0.0;
    }
    amount_native * 1_000_000.0 / micro_per_usd as f64
}

pub fn wallet_available_native(balance_native: f64, held_native: f64) -> f64 {
    (balance_native - held_native).max(0.0)
}

pub fn allowance_remaining(allow_5h_used: f64, allow_5h_limit: f64, allow_weekly_used: f64, allow_weekly_limit: f64) -> f64 {
    let r5 = (allow_5h_limit - allow_5h_used).max(0.0);
    let rw = (allow_weekly_limit - allow_weekly_used).max(0.0);
    r5.min(rw)
}

/// USD portion of `cost_usd` that must come from wallet after allowance.
pub fn on_demand_usd(cost_usd: f64, allowance_rem: f64) -> f64 {
    (cost_usd - allowance_rem).max(0.0)
}

pub fn hold_amounts(
    hold_usd: f64,
    allowance_rem: f64,
    currency: &str,
    micro_per_usd: i64,
) -> (f64, f64) {
    let need_usd = on_demand_usd(hold_usd, allowance_rem);
    if need_usd <= 0.0 {
        return (0.0, 0.0);
    }
    if currency.eq_ignore_ascii_case("IDR") {
        (0.0, usd_to_native(need_usd, micro_per_usd))
    } else {
        (need_usd, 0.0)
    }
}

pub fn gate_can_start(
    allowance_rem: f64,
    balance_native: f64,
    held_native: f64,
    hold_native: f64,
) -> bool {
    if allowance_rem > 0.0 {
        return true;
    }
    if hold_native <= 0.0 {
        return balance_native > 0.0 || held_native > 0.0;
    }
    wallet_available_native(balance_native, held_native) >= hold_native
}

/// After turn: wallet debit in native currency; returns (held_release_usd, held_release_idr).
pub fn settle_hold(
    held_usd: f64,
    held_idr: f64,
    wallet_charge_usd: f64,
    wallet_charge_idr: f64,
) -> (f64, f64, f64, f64) {
    let deduct_usd = wallet_charge_usd.min(held_usd);
    let deduct_idr = wallet_charge_idr.min(held_idr);
    let release_usd = held_usd - deduct_usd;
    let release_idr = held_idr - deduct_idr;
    (deduct_usd, deduct_idr, release_usd, release_idr)
}

pub fn wallet_charge_native(
    cost_usd: f64,
    allowance_rem: f64,
    currency: &str,
    micro_per_usd: i64,
) -> (f64, f64) {
    let need_usd = on_demand_usd(cost_usd, allowance_rem);
    hold_amounts(need_usd, 0.0, currency, micro_per_usd)
}

#[cfg(test)]
mod tests {
    use super::*;

    const FX: i64 = 17_630_000_000;

    #[test]
    fn usd_to_native_idr() {
        let idr = usd_to_native(1.0, FX);
        assert!((idr - 17_630.0).abs() < 0.01);
    }

    #[test]
    fn allowance_covers_no_hold() {
        let (usd, idr) = hold_amounts(DEFAULT_HOLD_USD, 0.10, "IDR", FX);
        assert_eq!(usd, 0.0);
        assert_eq!(idr, 0.0);
    }

    #[test]
    fn on_demand_hold_idr_when_allowance_exhausted() {
        let (usd, idr) = hold_amounts(DEFAULT_HOLD_USD, 0.0, "IDR", FX);
        assert_eq!(usd, 0.0);
        assert!((idr - usd_to_native(DEFAULT_HOLD_USD, FX)).abs() < 0.01);
    }

    #[test]
    fn on_demand_hold_usd_wallet() {
        let (usd, idr) = hold_amounts(0.02, 0.0, "USD", FX);
        assert!((usd - 0.02).abs() < 1e-9);
        assert_eq!(idr, 0.0);
    }

    #[test]
    fn gate_blocks_when_wallet_insufficient() {
        assert!(!gate_can_start(0.0, 100.0, 95.0, 10.0));
        assert!(gate_can_start(0.0, 100.0, 80.0, 10.0));
    }

    #[test]
    fn gate_allows_with_allowance_even_zero_balance() {
        assert!(gate_can_start(0.05, 0.0, 0.0, 0.0));
    }

    #[test]
    fn settle_releases_unused_hold() {
        let (du, di, ru, ri) = settle_hold(0.05, 881.5, 0.01, 176.3);
        assert!((du - 0.01).abs() < 1e-9);
        assert!((di - 176.3).abs() < 0.01);
        assert!((ru - 0.04).abs() < 1e-9);
        assert!((ri - 705.2).abs() < 0.1);
    }

    #[test]
    fn on_demand_partial_allowance() {
        assert!((on_demand_usd(0.08, 0.03) - 0.05).abs() < 1e-9);
        assert_eq!(on_demand_usd(0.02, 0.05), 0.0);
    }

    #[test]
    fn wallet_available_never_negative() {
        assert_eq!(wallet_available_native(10.0, 15.0), 0.0);
    }

    #[test]
    fn native_usd_roundtrip() {
        let idr = usd_to_native(0.05, FX);
        let back = native_to_usd(idr, FX);
        assert!((back - 0.05).abs() < 0.0001);
    }

    #[test]
    fn concurrent_holds_sum_reduces_available() {
        let balance = 50_000.0;
        let hold1 = 20_000.0;
        let hold2 = 20_000.0;
        let avail_after_first = wallet_available_native(balance, hold1);
        assert!((avail_after_first - 30_000.0).abs() < 0.01);
        assert!(gate_can_start(0.0, balance, hold1, 15_000.0));
        assert!(!gate_can_start(0.0, balance, hold1 + hold2, 15_000.0));
    }
}
