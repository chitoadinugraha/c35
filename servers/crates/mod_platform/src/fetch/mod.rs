mod cf;
mod gcp;
mod oci;
mod wasabi;

use crate::fetch_vendor::{env_enabled, VendorBillFetchTask};

pub use cf::{
    cf_category_for_label, cf_from_env, parse_cf_graphql_response, parse_cf_invoice_csv,
    CfVendorSource,
};
pub use gcp::{
    gcp_billing_config_from_env, gcp_classify_category, gcp_external_ref,
    gcp_lines_from_bq_rows, gcp_parse_bq_query_response, GcpBillingConfig, GcpBqRow,
    GcpVendorSource,
};
pub use oci::{oci_external_ref, oci_service_category, parse_usage_response, OciConfig, OciVendorSource};
pub use wasabi::{
    wasabi_category, wasabi_external_ref, wasabi_lines_from_api, wasabi_parse_billing_lines,
    wasabi_utilization_storage_gb, WasabiConfig, WasabiVendorSource,
};

fn vendor_stagger_mins(vendor: &str) -> u64 {
    let vendors = ["oci", "gcp", "cf", "wasabi"];
    let idx = vendors.iter().position(|v| *v == vendor).unwrap_or(0);
    std::env::var("VENDOR_BILL_STAGGER_MINS")
        .unwrap_or_else(|_| "0,15,30,45".into())
        .split(',')
        .nth(idx)
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(0)
}

pub fn oci_from_env() -> Option<VendorBillFetchTask> {
    if !env_enabled("OCI_VENDOR_BILL_ENABLED") {
        return None;
    }
    let source = OciVendorSource::from_env()?;
    Some(VendorBillFetchTask::new(
        Box::new(source),
        vendor_stagger_mins("oci"),
    ))
}

pub fn cf_vendor_from_env() -> Option<VendorBillFetchTask> {
    if !env_enabled("CF_VENDOR_BILL_ENABLED") {
        return None;
    }
    let source = cf_from_env()?;
    Some(VendorBillFetchTask::new(
        Box::new(source),
        vendor_stagger_mins("cf"),
    ))
}

pub fn gcp_from_env() -> Option<VendorBillFetchTask> {
    if !env_enabled("GCP_VENDOR_BILL_ENABLED") {
        return None;
    }
    let source = GcpVendorSource::from_env()?;
    Some(VendorBillFetchTask::new(
        Box::new(source),
        vendor_stagger_mins("gcp"),
    ))
}

pub fn wasabi_from_env() -> Option<VendorBillFetchTask> {
    if !env_enabled("WASABI_VENDOR_BILL_ENABLED") {
        return None;
    }
    let source = WasabiVendorSource::from_env()?;
    Some(VendorBillFetchTask::new(
        Box::new(source),
        vendor_stagger_mins("wasabi"),
    ))
}
