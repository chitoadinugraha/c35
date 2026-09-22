use crate::billing_cost::RETAIL_MARKUP;
use crate::billing_on_demand::usd_to_native;

/// Locked Alien AI pool rates (USD per 1M tokens).
pub const ALIEN_POOL_USD_IN_PER_1M: f64 = 1.50;
pub const ALIEN_POOL_USD_OUT_PER_1M: f64 = 7.00;

pub const POOL_ALIEN: &str = "alien";
pub const POOL_FRONTIER: &str = "frontier";

fn usd_from_ppm(tokens_in: i32, tokens_out: i32, in_ppm: i64, out_ppm: i64) -> f64 {
    let in_cost = tokens_in as f64 * in_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    let out_cost = tokens_out as f64 * out_ppm as f64 / 1_000_000.0 / 1_000_000.0;
    in_cost + out_cost
}

/// Returns (`pool_kind`, `idr_amount`) for one LLM turn.
pub fn pool_deduct_idr(
    model_is_alien: bool,
    tokens_in: i32,
    tokens_out: i32,
    wholesale_in_ppm: i64,
    wholesale_out_ppm: i64,
    fx_micro_per_usd: i64,
) -> (&'static str, f64) {
    let cost_usd = if model_is_alien {
        pool_alien_deduct_usd(tokens_in, tokens_out)
    } else {
        pool_frontier_deduct_usd(usd_from_ppm(tokens_in, tokens_out, wholesale_in_ppm, wholesale_out_ppm))
    };
    let kind = if model_is_alien { POOL_ALIEN } else { POOL_FRONTIER };
    (kind, usd_to_native(cost_usd, fx_micro_per_usd))
}

pub fn pool_remaining_ok(used_idr: f64, limit_idr: f64, deduct_idr: f64) -> bool {
    if deduct_idr <= 0.0 {
        return true;
    }
    (limit_idr - used_idr).max(0.0) + 1e-6 >= deduct_idr
}

/// Apply `deduct_idr` to `used_idr` when within `limit_idr`. Returns (`new_used`, `ok`).
pub fn pool_apply_deduct(used_idr: f64, limit_idr: f64, deduct_idr: f64) -> (f64, bool) {
    if !pool_remaining_ok(used_idr, limit_idr, deduct_idr) {
        return (used_idr, false);
    }
    (used_idr + deduct_idr, true)
}

/// Lite tier monthly pool caps (IDR) — 1× reference.
pub const LITE_ALIEN_POOL_IDR: f64 = 100_000.0;
pub const LITE_FRONTIER_POOL_IDR: f64 = 20_000.0;

pub const SIGNUP_TRIAL_ALIEN_IDR: f64 = LITE_ALIEN_POOL_IDR * 0.25;
pub const SIGNUP_TRIAL_FRONTIER_IDR: f64 = LITE_FRONTIER_POOL_IDR * 0.25;

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct PoolSnapshot {
    pub alien_used_idr: f64,
    pub alien_limit_idr: f64,
    pub frontier_used_idr: f64,
    pub frontier_limit_idr: f64,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct PoolDeductApplied {
    pub alien_deduct_idr: f64,
    pub frontier_deduct_idr: f64,
    pub wallet_overflow_idr: f64,
    pub alien_used_idr: f64,
    pub frontier_used_idr: f64,
}

pub fn pool_usd_to_idr(usd: f64, micro_per_usd: i64) -> f64 {
    usd * (micro_per_usd as f64 / 1_000_000.0)
}

pub fn pool_alien_deduct_usd(tokens_in: i32, tokens_out: i32) -> f64 {
    (tokens_in as f64 / 1_000_000.0) * ALIEN_POOL_USD_IN_PER_1M
        + (tokens_out as f64 / 1_000_000.0) * ALIEN_POOL_USD_OUT_PER_1M
}

pub fn pool_frontier_deduct_usd(wholesale_usd: f64) -> f64 {
    wholesale_usd * RETAIL_MARKUP
}

pub fn pool_alien_deduct_idr(tokens_in: i32, tokens_out: i32, micro_per_usd: i64) -> f64 {
    pool_usd_to_idr(pool_alien_deduct_usd(tokens_in, tokens_out), micro_per_usd)
}

pub fn pool_frontier_deduct_idr(wholesale_usd: f64, micro_per_usd: i64) -> f64 {
    pool_usd_to_idr(pool_frontier_deduct_usd(wholesale_usd), micro_per_usd)
}

pub fn pool_limits_from_multiplier(multiplier: f64) -> (f64, f64) {
    (
        LITE_ALIEN_POOL_IDR * multiplier,
        LITE_FRONTIER_POOL_IDR * multiplier,
    )
}

fn pool_take(used: f64, limit: f64, want: f64) -> (f64, f64) {
    let rem = (limit - used).max(0.0);
    let take = want.min(rem);
    (take, want - take)
}

/// Apply a pool charge: alien pool for alienai, frontier pool for pinned models.
pub fn pool_deduct_apply(
    snap: &PoolSnapshot,
    charge_idr: f64,
    use_alien_pool: bool,
) -> PoolDeductApplied {
    let (alien_deduct, overflow) = if use_alien_pool {
        pool_take(snap.alien_used_idr, snap.alien_limit_idr, charge_idr)
    } else {
        (0.0, charge_idr)
    };
    let (frontier_deduct, wallet_overflow) = if use_alien_pool {
        (0.0, overflow)
    } else {
        pool_take(snap.frontier_used_idr, snap.frontier_limit_idr, charge_idr)
    };
    PoolDeductApplied {
        alien_deduct_idr: alien_deduct,
        frontier_deduct_idr: frontier_deduct,
        wallet_overflow_idr: wallet_overflow,
        alien_used_idr: snap.alien_used_idr + alien_deduct,
        frontier_used_idr: snap.frontier_used_idr + frontier_deduct,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const FX: i64 = 17_630_000_000;

    #[test]
    fn pool_deduct_idr_alien_turn() {
        let (kind, idr) = pool_deduct_idr(true, 10_000, 2_000, 0, 0, FX);
        assert_eq!(kind, POOL_ALIEN);
        assert!((idr - pool_alien_deduct_idr(10_000, 2_000, FX)).abs() < 0.01);
    }

    #[test]
    fn pool_deduct_idr_frontier_turn() {
        let (kind, idr) = pool_deduct_idr(false, 10_000, 2_000, 300_000, 2_500_000, FX);
        assert_eq!(kind, POOL_FRONTIER);
        let wholesale = usd_from_ppm(10_000, 2_000, 300_000, 2_500_000);
        assert!((idr - pool_frontier_deduct_idr(wholesale, FX)).abs() < 0.01);
    }

    #[test]
    fn pool_remaining_and_apply() {
        assert!(pool_remaining_ok(0.0, 100_000.0, 25_000.0));
        assert!(!pool_remaining_ok(90_000.0, 100_000.0, 25_000.0));
        let (used, ok) = pool_apply_deduct(10_000.0, 100_000.0, 5_000.0);
        assert!(ok);
        assert!((used - 15_000.0).abs() < 1e-9);
    }
}
