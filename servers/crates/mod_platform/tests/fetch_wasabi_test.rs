mod common;

use chrono::NaiveDate;
use c35_mod_fetch::FetchTask;
use c35_mod_platform::{
    wasabi_category, wasabi_external_ref, wasabi_from_env, wasabi_lines_from_api,
    wasabi_parse_billing_lines, wasabi_utilization_storage_gb, VendorBillSource, WasabiConfig,
    WasabiVendorSource,
};

fn window() -> (NaiveDate, NaiveDate) {
    (
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        NaiveDate::from_ymd_opt(2026, 9, 23).unwrap(),
    )
}

#[test]
fn wasabi_category_maps_storage_and_network() {
    assert_eq!(wasabi_category("Timed Active Storage"), "storage");
    assert_eq!(wasabi_category("Object Retention"), "storage");
    assert_eq!(wasabi_category("Outbound Data Transfer"), "network");
    assert_eq!(wasabi_category("Egress to Internet"), "network");
    assert_eq!(wasabi_category("API Requests"), "other");
}

#[test]
fn wasabi_external_ref_is_stable_per_category_window() {
    let a = wasabi_external_ref("storage", window());
    let b = wasabi_external_ref("storage", window());
    assert_eq!(a, b);
    assert_eq!(a, "wasabi:storage:2026-09-01:2026-09-23");
    assert_ne!(wasabi_external_ref("storage", window()), wasabi_external_ref("network", window()));
}

#[test]
fn wasabi_parse_billing_fixture_maps_storage_and_network() {
    let billing: serde_json::Value =
        serde_json::from_str(include_str!("fixtures/wasabi_billing.json")).expect("fixture");
    let lines = wasabi_parse_billing_lines(window(), &billing);
    assert_eq!(lines.len(), 2);

    let storage = lines.iter().find(|l| l.category == "storage").expect("storage");
    assert_eq!(storage.vendor, "wasabi");
    assert_eq!(storage.amount_native, 45.67);
    assert_eq!(storage.sku, "timed-active-storage");
    assert_eq!(storage.currency, "USD");
    assert_eq!(storage.source, "api");
    assert_eq!(storage.status, "estimated");

    let network = lines.iter().find(|l| l.category == "network").expect("network");
    assert_eq!(network.amount_native, 12.34);
    assert_eq!(network.external_ref, wasabi_external_ref("network", window()));
}

#[test]
fn wasabi_lines_from_api_enriches_storage_meta() {
    let billing: serde_json::Value =
        serde_json::from_str(include_str!("fixtures/wasabi_billing.json")).expect("billing");
    let utilization: serde_json::Value =
        serde_json::from_str(include_str!("fixtures/wasabi_utilization.json")).expect("utilization");
    let lines = wasabi_lines_from_api(window(), &billing, &utilization, "ap-southeast-1");
    assert_eq!(lines.len(), 2);
    let storage = lines.iter().find(|l| l.category == "storage").expect("storage");
    assert_eq!(storage.meta["storage_gb"], serde_json::json!(512.0));
    assert_eq!(
        wasabi_utilization_storage_gb(&utilization, "ap-southeast-1"),
        Some(512.0)
    );
}

#[test]
fn wasabi_config_from_env() {
    let _lock = common::env_lock();
    std::env::remove_var("WASABI_ACCESS_KEY");
    std::env::remove_var("WASABI_SECRET_KEY");
    std::env::remove_var("WASABI_REGION");
    assert!(WasabiConfig::from_env().is_none());
    assert!(WasabiVendorSource::from_env().is_none());

    std::env::set_var("WASABI_ACCESS_KEY", "test-access");
    std::env::set_var("WASABI_SECRET_KEY", "test-secret");
    let cfg = WasabiConfig::from_env().expect("config");
    assert_eq!(cfg.region, "ap-southeast-1");

    std::env::set_var("WASABI_REGION", "eu-central-1");
    let cfg = WasabiConfig::from_env().expect("config with region");
    assert_eq!(cfg.region, "eu-central-1");

    std::env::remove_var("WASABI_ACCESS_KEY");
    std::env::remove_var("WASABI_SECRET_KEY");
    std::env::remove_var("WASABI_REGION");
}

#[test]
fn wasabi_from_env_task() {
    let _lock = common::env_lock();
    std::env::remove_var("WASABI_VENDOR_BILL_ENABLED");
    std::env::remove_var("WASABI_ACCESS_KEY");
    std::env::remove_var("WASABI_SECRET_KEY");
    std::env::remove_var("WASABI_REGION");
    std::env::remove_var("VENDOR_BILL_STAGGER_MINS");
    assert!(wasabi_from_env().is_none());

    std::env::set_var("WASABI_VENDOR_BILL_ENABLED", "1");
    assert!(wasabi_from_env().is_none());

    std::env::set_var("WASABI_ACCESS_KEY", "test-access");
    std::env::set_var("WASABI_SECRET_KEY", "test-secret");
    std::env::set_var("WASABI_REGION", "ap-southeast-1");
    std::env::set_var("VENDOR_BILL_STAGGER_MINS", "0,15,30,45");

    let task = wasabi_from_env().expect("wasabi task");
    assert_eq!(task.name(), "vendor_bill_wasabi");
    assert_eq!(task.stagger_mins, 45);

    std::env::remove_var("WASABI_VENDOR_BILL_ENABLED");
    std::env::remove_var("WASABI_ACCESS_KEY");
    std::env::remove_var("WASABI_SECRET_KEY");
    std::env::remove_var("WASABI_REGION");
    std::env::remove_var("VENDOR_BILL_STAGGER_MINS");
}

#[test]
fn wasabi_vendor_source_exposes_vendor_id() {
    let source = WasabiVendorSource::new(WasabiConfig {
        access_key: "test".into(),
        secret_key: "secret".into(),
        region: "ap-southeast-1".into(),
    });
    assert_eq!(source.vendor(), "wasabi");
}
