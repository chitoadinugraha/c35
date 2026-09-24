mod common;

use chrono::NaiveDate;
use c35_mod_fetch::FetchTask;
use c35_mod_platform::{
    oci_external_ref, oci_from_env, oci_service_category, parse_usage_response, OciConfig,
    OciVendorSource, VendorBillSource,
};

const COMPARTMENT: &str = "ocid1.compartment.oc1..testcompartment";

fn with_env<F: FnOnce()>(f: F) {
    let _guard = common::env_lock();
    f();
}

fn window() -> (NaiveDate, NaiveDate) {
    (
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        NaiveDate::from_ymd_opt(2026, 9, 23).unwrap(),
    )
}

#[test]
fn oci_service_category_maps_infra_services() {
    assert_eq!(oci_service_category("Compute"), "compute");
    assert_eq!(oci_service_category("Container Engine for Kubernetes"), "compute");
    assert_eq!(oci_service_category("Block Storage"), "storage");
    assert_eq!(oci_service_category("Object Storage"), "storage");
    assert_eq!(oci_service_category("Virtual Cloud Network"), "network");
    assert_eq!(oci_service_category("Load Balancer"), "network");
    assert_eq!(oci_service_category("Logging Analytics"), "other");
}

#[test]
fn oci_external_ref_is_stable_per_service_sku_day() {
    let day = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
    let a = oci_external_ref(COMPARTMENT, "Compute", "VM.Standard.E4.Flex", day);
    let b = oci_external_ref(COMPARTMENT, "Compute", "VM.Standard.E4.Flex", day);
    let c = oci_external_ref(COMPARTMENT, "Compute", "VM.Standard.E4.Flex", day + chrono::Days::new(1));
    assert_eq!(a, b);
    assert_ne!(a, c);
    assert_eq!(a.len(), 64);
}

#[test]
fn parse_usage_response_maps_fixture_to_vendor_lines() {
    let fixture = include_str!("fixtures/oci_usage_summary.json");
    let lines = parse_usage_response(fixture, COMPARTMENT, window(), "estimated").expect("parse");
    assert_eq!(lines.len(), 4, "zero-amount rows are skipped");

    let compute = lines
        .iter()
        .find(|l| l.category == "compute")
        .expect("compute line");
    assert_eq!(compute.vendor, "oci");
    assert_eq!(compute.amount_native, 42.5);
    assert_eq!(compute.currency, "USD");
    assert_eq!(compute.period_start, NaiveDate::from_ymd_opt(2026, 9, 1).unwrap());
    assert_eq!(compute.period_end, compute.period_start);
    assert!(!compute.external_ref.is_empty());
    assert_eq!(
        compute.external_ref,
        oci_external_ref(COMPARTMENT, "Compute", "VM.Standard.E4.Flex", compute.period_start)
    );

    assert!(lines.iter().any(|l| l.category == "storage"));
    assert!(lines.iter().any(|l| l.category == "network"));
    assert!(lines.iter().any(|l| l.category == "other"));
}

#[test]
fn oci_from_env_returns_none_without_credentials() {
    with_env(|| {
        for key in [
            "OCI_VENDOR_BILL_ENABLED",
            "OCI_TENANCY_OCID",
            "OCI_USER_OCID",
            "OCI_FINGERPRINT",
            "OCI_COMPARTMENT_OCID",
            "OCI_PRIVATE_KEY",
            "OCI_PRIVATE_KEY_PATH",
        ] {
            std::env::remove_var(key);
        }
        assert!(OciVendorSource::from_env().is_none());
        assert!(oci_from_env().is_none());
    });
}

#[test]
fn oci_from_env_wraps_source_when_enabled_and_configured() {
    with_env(|| {
        std::env::remove_var("OCI_PRIVATE_KEY_PATH");
        std::env::set_var("OCI_VENDOR_BILL_ENABLED", "1");
        std::env::set_var("OCI_TENANCY_OCID", "ocid1.tenancy.oc1..test");
        std::env::set_var("OCI_USER_OCID", "ocid1.user.oc1..test");
        std::env::set_var("OCI_FINGERPRINT", "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99");
        std::env::set_var("OCI_COMPARTMENT_OCID", COMPARTMENT);
        std::env::set_var(
            "OCI_PRIVATE_KEY",
            include_str!("fixtures/oci_test_key.pem"),
        );

        let source = OciVendorSource::from_env().expect("configured OCI source");
        assert_eq!(source.vendor(), "oci");

        let task = oci_from_env().expect("oci fetch task");
        assert_eq!(task.name(), "vendor_bill_oci");

        for key in [
            "OCI_VENDOR_BILL_ENABLED",
            "OCI_TENANCY_OCID",
            "OCI_USER_OCID",
            "OCI_FINGERPRINT",
            "OCI_COMPARTMENT_OCID",
            "OCI_PRIVATE_KEY",
        ] {
            std::env::remove_var(key);
        }
    });
}

#[test]
fn oci_config_from_env_reads_region_default() {
    with_env(|| {
        std::env::remove_var("OCI_REGION");
        std::env::remove_var("OCI_PRIVATE_KEY_PATH");
        std::env::set_var("OCI_TENANCY_OCID", "ocid1.tenancy.oc1..test");
        std::env::set_var("OCI_USER_OCID", "ocid1.user.oc1..test");
        std::env::set_var("OCI_FINGERPRINT", "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99");
        std::env::set_var("OCI_COMPARTMENT_OCID", COMPARTMENT);
        std::env::set_var(
            "OCI_PRIVATE_KEY",
            include_str!("fixtures/oci_test_key.pem"),
        );

        let config = OciConfig::from_env().expect("config");
        assert_eq!(config.region, "ap-southeast-1");

        for key in [
            "OCI_TENANCY_OCID",
            "OCI_USER_OCID",
            "OCI_FINGERPRINT",
            "OCI_COMPARTMENT_OCID",
            "OCI_PRIVATE_KEY",
        ] {
            std::env::remove_var(key);
        }
    });
}

#[test]
fn oci_vendor_source_new_parses_pem() {
    let config = OciConfig {
        tenancy_ocid: "ocid1.tenancy.oc1..test".into(),
        user_ocid: "ocid1.user.oc1..test".into(),
        fingerprint: "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99".into(),
        private_key_pem: include_str!("fixtures/oci_test_key.pem").into(),
        region: "ap-southeast-1".into(),
        compartment_ocid: COMPARTMENT.into(),
    };
    let source = OciVendorSource::new(config).expect("new source");
    assert_eq!(source.vendor(), "oci");
}
