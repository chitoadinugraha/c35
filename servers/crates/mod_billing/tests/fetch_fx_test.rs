use c35_mod_billing::{fx_change_bps, fx_markup_apply, fx_micro_from_idr};

#[test]
fn fx_markup_10_percent() {
    let published = fx_markup_apply(17_630.0, 1000);
    assert!((published - 19_393.0).abs() < 0.01);
}

#[test]
fn fx_micro_rounds() {
    assert_eq!(fx_micro_from_idr(19_393.0), 19_393_000_000);
}

#[test]
fn fx_change_bps_small_move() {
    assert!(fx_change_bps(17_630.0, 17_640.0) < 25);
}
