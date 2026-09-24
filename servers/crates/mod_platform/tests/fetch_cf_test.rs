use chrono::NaiveDate;
use c35_mod_platform::{
    cf_category_for_label, cf_from_env, parse_cf_graphql_response, parse_cf_invoice_csv,
    VendorBillSource,
};
use serde_json::Value;

fn window() -> (NaiveDate, NaiveDate) {
    (
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        NaiveDate::from_ymd_opt(2026, 9, 23).unwrap(),
    )
}

#[test]
fn cf_category_for_label_maps_products() {
    assert_eq!(cf_category_for_label("Workers AI inference"), "ai_api");
    assert_eq!(cf_category_for_label("AI Gateway requests"), "ai_api");
    assert_eq!(cf_category_for_label("DNS Standard"), "dns");
    assert_eq!(cf_category_for_label("Domain Registrar"), "dns");
    assert_eq!(cf_category_for_label("Zero Trust seats"), "network");
    assert_eq!(cf_category_for_label("Cloudflare Tunnel"), "network");
    assert_eq!(cf_category_for_label("Workers Paid plan"), "other");
}

#[test]
fn parse_cf_graphql_response_maps_fixture_to_vendor_lines() {
    let fixture = include_str!("fixtures/cf_graphql_response.json");
    let body: Value = serde_json::from_str(fixture).expect("fixture json");
    let lines = parse_cf_graphql_response(&body, window());
    assert!(!lines.is_empty());

    let workers = lines
        .iter()
        .find(|l| l.sku == "workers-ai" && l.source == "api")
        .expect("workers ai line");
    assert_eq!(workers.vendor, "cf");
    assert_eq!(workers.category, "ai_api");
    assert_eq!(workers.period_start, NaiveDate::from_ymd_opt(2026, 9, 1).unwrap());
    assert!((workers.amount_native - 1.1).abs() < 1e-9); // 100k neurons * 0.011 / 1000
    assert_eq!(workers.status, "estimated");

    let gateway = lines
        .iter()
        .find(|l| l.sku == "ai-gateway")
        .expect("ai gateway line");
    assert_eq!(gateway.category, "ai_api");
    assert_eq!(gateway.meta["requests"].as_f64(), Some(1200.0));

    let dns = lines
        .iter()
        .find(|l| l.category == "dns" && l.source == "api")
        .expect("dns billing line");
    assert_eq!(dns.amount_native, 4.5);
    assert_eq!(dns.external_ref, "cf:dns:dns-dns-queries:2026-09-01");

    let ai_billing = lines
        .iter()
        .find(|l| l.sku.contains("workers") && l.source == "api" && l.amount_native == 1.25)
        .expect("workers ai billing metric");
    assert_eq!(ai_billing.category, "ai_api");
}

#[test]
fn parse_cf_invoice_csv_maps_fixture_rows() {
    let bytes = include_bytes!("fixtures/cf_invoice.csv");
    let lines = parse_cf_invoice_csv(bytes).expect("parse csv");
    assert_eq!(lines.len(), 3);

    let ai = lines
        .iter()
        .find(|l| l.description.contains("Workers AI"))
        .expect("workers ai csv");
    assert_eq!(ai.vendor, "cf");
    assert_eq!(ai.category, "ai_api");
    assert_eq!(ai.amount_native, 12.34);
    assert_eq!(ai.currency, "USD");
    assert_eq!(ai.source, "csv");
    assert_eq!(ai.status, "finalized");
    assert_eq!(ai.period_start, NaiveDate::from_ymd_opt(2026, 8, 1).unwrap());
    assert_eq!(ai.period_end, NaiveDate::from_ymd_opt(2026, 8, 31).unwrap());
    assert!(ai.external_ref.starts_with("cf:csv:"));

    let dns = lines.iter().find(|l| l.category == "dns").expect("dns csv");
    assert_eq!(dns.amount_native, 5.0);

    let network = lines
        .iter()
        .find(|l| l.category == "network")
        .expect("network csv");
    assert_eq!(network.amount_native, 8.5);
}

#[test]
fn parse_cf_invoice_csv_accepts_flexible_headers() {
    let csv = "Product,Total,Curr\nAI Gateway usage,3.50,usd\n";
    let lines = parse_cf_invoice_csv(csv.as_bytes()).expect("parse");
    assert_eq!(lines.len(), 1);
    assert_eq!(lines[0].category, "ai_api");
    assert_eq!(lines[0].amount_native, 3.5);
    assert_eq!(lines[0].currency, "USD");
}

#[test]
fn cf_from_env_returns_none_without_credentials() {
    for key in ["CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID"] {
        std::env::remove_var(key);
    }
    assert!(cf_from_env().is_none());

    std::env::set_var("CLOUDFLARE_ACCOUNT_ID", "redacted-account-id");
    std::env::remove_var("CLOUDFLARE_API_TOKEN");
    assert!(cf_from_env().is_none());

    std::env::set_var("CLOUDFLARE_API_TOKEN", "redacted-token");
    let source = cf_from_env().expect("configured source");
    assert_eq!(source.vendor(), "cf");

    for key in ["CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID"] {
        std::env::remove_var(key);
    }
}
