//! Archived phrase parsers (see `legacy/site_commerce/README.md`).

#[path = "../legacy/site_commerce/site_report.rs"]
mod site_report;

#[path = "../legacy/site_commerce/tx_browse.rs"]
mod tx_browse;

#[path = "../legacy/site_commerce/stock_report.rs"]
mod stock_report;

#[test]
fn legacy_stock_report_parse_mutasi() {
    let now = chrono::Utc::now();
    assert!(stock_report::stock_report_parse("mutasi stok bulan ini", now).is_some());
}

#[test]
fn legacy_tx_browse_parse_daftar() {
    assert!(tx_browse::tx_browse_parse("daftar transaksi hari ini").is_some());
}

#[test]
fn legacy_site_report_parse_mention() {
    let i = site_report::site_report_parse(
        "Berapa untung [@[@iid:101836119014211584]] hari ini ?",
    )
    .unwrap();
    assert_eq!(i.query_id, "tx.profit_summary");
    assert_eq!(i.range, "today");
}
