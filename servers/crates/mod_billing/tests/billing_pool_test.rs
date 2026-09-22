//! Unit tests for IDR pool deduct math (no database).

use c35_mod_billing::{
    pool_alien_deduct_idr, pool_alien_deduct_usd, pool_apply_deduct, pool_deduct_apply,
    pool_deduct_idr, pool_frontier_deduct_idr, pool_frontier_deduct_usd, pool_limits_from_multiplier,
    pool_remaining_ok, pool_usd_to_idr, PoolSnapshot, ALIEN_POOL_USD_IN_PER_1M,
    ALIEN_POOL_USD_OUT_PER_1M, LITE_ALIEN_POOL_IDR, LITE_FRONTIER_POOL_IDR, POOL_ALIEN,
    POOL_FRONTIER, SIGNUP_TRIAL_ALIEN_IDR, SIGNUP_TRIAL_FRONTIER_IDR,
};

const FX_MICRO: i64 = 17_630_000_000;

#[test]
fn alien_pool_rate_constants() {
    assert_eq!(ALIEN_POOL_USD_IN_PER_1M, 1.50);
    assert_eq!(ALIEN_POOL_USD_OUT_PER_1M, 7.00);
}

#[test]
fn alien_deduct_usd_10k_in_2k_out() {
    let usd = pool_alien_deduct_usd(10_000, 2_000);
    assert!((usd - 0.029).abs() < 1e-9);
}

#[test]
fn alien_deduct_idr_at_fx() {
    let idr = pool_alien_deduct_idr(10_000, 2_000, FX_MICRO);
    let expected = pool_usd_to_idr(0.029, FX_MICRO);
    assert!((idr - expected).abs() < 0.01);
}

#[test]
fn frontier_deduct_applies_retail_markup() {
    let wholesale = 0.012;
    let usd = pool_frontier_deduct_usd(wholesale);
    assert!((usd - 0.018).abs() < 1e-9);
    let idr = pool_frontier_deduct_idr(wholesale, FX_MICRO);
    assert!((idr - pool_usd_to_idr(0.018, FX_MICRO)).abs() < 0.01);
}

#[test]
fn lite_pool_reference_amounts() {
    assert_eq!(LITE_ALIEN_POOL_IDR, 100_000.0);
    assert_eq!(LITE_FRONTIER_POOL_IDR, 20_000.0);
}

#[test]
fn signup_trial_is_quarter_lite() {
    let (alien, frontier) = pool_limits_from_multiplier(0.25);
    assert_eq!(alien, SIGNUP_TRIAL_ALIEN_IDR);
    assert_eq!(frontier, SIGNUP_TRIAL_FRONTIER_IDR);
    assert_eq!(alien, 25_000.0);
    assert_eq!(frontier, 5_000.0);
}

#[test]
fn pool_deduct_alien_drains_alien_first() {
    let snap = PoolSnapshot {
        alien_used_idr: 90_000.0,
        alien_limit_idr: 100_000.0,
        frontier_used_idr: 0.0,
        frontier_limit_idr: 20_000.0,
    };
    let applied = pool_deduct_apply(&snap, 15_000.0, true);
    assert_eq!(applied.alien_deduct_idr, 10_000.0);
    assert_eq!(applied.frontier_deduct_idr, 0.0);
    assert_eq!(applied.wallet_overflow_idr, 5_000.0);
    assert_eq!(applied.alien_used_idr, 100_000.0);
}

#[test]
fn pool_deduct_idr_routes_alien_and_frontier() {
    let (alien_kind, alien_idr) = pool_deduct_idr(true, 10_000, 2_000, 0, 0, FX_MICRO);
    assert_eq!(alien_kind, POOL_ALIEN);
    assert!((alien_idr - pool_alien_deduct_idr(10_000, 2_000, FX_MICRO)).abs() < 0.01);

    let (frontier_kind, frontier_idr) =
        pool_deduct_idr(false, 10_000, 2_000, 300_000, 2_500_000, FX_MICRO);
    assert_eq!(frontier_kind, POOL_FRONTIER);
    assert!(frontier_idr > 0.0);
}

#[test]
fn pool_apply_deduct_respects_limit() {
    assert!(pool_remaining_ok(0.0, 100_000.0, 25_000.0));
    assert!(!pool_remaining_ok(90_000.0, 100_000.0, 25_000.0));
    let (used, ok) = pool_apply_deduct(10_000.0, 100_000.0, 5_000.0);
    assert!(ok);
    assert!((used - 15_000.0).abs() < 1e-9);
}

#[test]
fn pool_deduct_frontier_drains_frontier_pool() {
    let snap = PoolSnapshot {
        alien_used_idr: 0.0,
        alien_limit_idr: 100_000.0,
        frontier_used_idr: 15_000.0,
        frontier_limit_idr: 20_000.0,
    };
    let applied = pool_deduct_apply(&snap, 8_000.0, false);
    assert_eq!(applied.alien_deduct_idr, 0.0);
    assert_eq!(applied.frontier_deduct_idr, 5_000.0);
    assert_eq!(applied.wallet_overflow_idr, 3_000.0);
    assert_eq!(applied.frontier_used_idr, 20_000.0);
}
