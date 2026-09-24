mod fetch;
mod fetch_vendor;
mod fx_usd;
mod period;
mod pnl;
mod vendor_cost;

/// Serializes integration tests that mutate process env vars.
pub static TEST_ENV_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

pub use fetch::{
    cf_category_for_label, cf_from_env, cf_vendor_from_env, gcp_billing_config_from_env,
    gcp_classify_category, gcp_external_ref, gcp_from_env, gcp_lines_from_bq_rows,
    gcp_parse_bq_query_response, oci_external_ref, oci_from_env, oci_service_category,
    parse_cf_graphql_response, parse_cf_invoice_csv, parse_usage_response, wasabi_category,
    wasabi_external_ref, wasabi_from_env, wasabi_lines_from_api, wasabi_parse_billing_lines,
    wasabi_utilization_storage_gb, CfVendorSource, GcpBillingConfig, GcpBqRow, GcpVendorSource,
    OciConfig, OciVendorSource, WasabiConfig, WasabiVendorSource,
};
pub use fetch_vendor::{env_enabled, parse_finalize_days, VendorBillFetchTask, VendorBillSource};
pub use fx_usd::amount_to_usd;
pub use period::{
    vendor_bill_mtd_window, vendor_bill_prev_month_window, vendor_bill_should_finalize_today,
};
pub use pnl::{
    platform_pnl_query, pnl_ai_cogs_drift_pct, PlatformPnl, VendorCostBreakdown,
};
pub use vendor_cost::{
    parse_vendor_csv, vendor_cost_finalize_period, vendor_cost_upsert_batch, VendorCostLine,
};
