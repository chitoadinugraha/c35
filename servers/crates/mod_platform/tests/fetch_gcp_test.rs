mod common;

use chrono::NaiveDate;
use c35_mod_fetch::FetchTask;
use c35_mod_platform::{
    gcp_billing_config_from_env, gcp_classify_category, gcp_external_ref, gcp_from_env,
    gcp_lines_from_bq_rows, gcp_parse_bq_query_response, GcpVendorSource, VendorBillSource,
};

const BQ_FIXTURE: &str = include_str!("fixtures/gcp_bq_query_response.json");

const GCP_ENV_KEYS: &[&str] = &[
    "GCP_VENDOR_BILL_ENABLED",
    "GCP_BILLING_PROJECT_ID",
    "GCP_BILLING_DATASET",
    "GCP_BILLING_TABLE",
    "GOOGLE_APPLICATION_CREDENTIALS_JSON",
    "VENDOR_BILL_STAGGER_MINS",
];

struct EnvGuard {
    _lock: std::sync::MutexGuard<'static, ()>,
    saved: Vec<(&'static str, Option<String>)>,
}

impl EnvGuard {
    fn clear(keys: &[&'static str]) -> Self {
        let saved = keys
            .iter()
            .map(|key| {
                let prev = std::env::var(key).ok();
                std::env::remove_var(key);
                (*key, prev)
            })
            .collect();
        Self {
            _lock: common::env_lock(),
            saved,
        }
    }

    fn set(key: &'static str, value: &str) {
        std::env::set_var(key, value);
    }
}

impl Drop for EnvGuard {
    fn drop(&mut self) {
        for (key, prev) in &self.saved {
            match prev {
                Some(v) => std::env::set_var(key, v),
                None => std::env::remove_var(key),
            }
        }
    }
}

fn window() -> (NaiveDate, NaiveDate) {
    (
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        NaiveDate::from_ymd_opt(2026, 9, 23).unwrap(),
    )
}

#[test]
fn gcp_classify_category_maps_services() {
    assert_eq!(
        gcp_classify_category("Vertex AI", "Gemini 1.5 Pro Input"),
        "ai_api"
    );
    assert_eq!(
        gcp_classify_category("Cloud Speech-to-Text", "Standard Audio"),
        "ai_api"
    );
    assert_eq!(
        gcp_classify_category("Compute Engine", "N1 Predefined Instance Core"),
        "compute"
    );
    assert_eq!(
        gcp_classify_category("Kubernetes Engine", "Zonal Cluster Management"),
        "compute"
    );
    assert_eq!(
        gcp_classify_category("Cloud Storage", "Standard Storage US"),
        "storage"
    );
    assert_eq!(
        gcp_classify_category("Compute Engine", "Persistent Disk SSD"),
        "storage"
    );
    assert_eq!(
        gcp_classify_category("Networking", "Network Internet Egress"),
        "network"
    );
    assert_eq!(
        gcp_classify_category("Cloud DNS", "Managed Zone"),
        "other"
    );
}

#[test]
fn gcp_external_ref_is_stable_blake3_hash() {
    let start = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
    let end = NaiveDate::from_ymd_opt(2026, 9, 23).unwrap();
    let a = gcp_external_ref("Compute Engine", "N1 Core", start, end);
    let b = gcp_external_ref("Compute Engine", "N1 Core", start, end);
    assert_eq!(a, b);
    assert_eq!(a.len(), 64);
    assert_ne!(
        gcp_external_ref("Compute Engine", "N1 Core", start, end),
        gcp_external_ref("Compute Engine", "N1 Ram", start, end)
    );
}

#[test]
fn gcp_parse_fixture_rows() {
    let body = serde_json::from_str(BQ_FIXTURE).expect("fixture json");
    let rows = gcp_parse_bq_query_response(&body).expect("parse fixture");
    assert_eq!(rows.len(), 4);
    assert_eq!(rows[0].service_description, "Vertex AI");
    assert_eq!(rows[0].sku_description, "Gemini 1.5 Pro Input");
    assert!((rows[0].total_cost - 25.5).abs() < 0.001);
}

#[test]
fn gcp_lines_from_fixture_rows() {
    let body = serde_json::from_str(BQ_FIXTURE).expect("fixture json");
    let rows = gcp_parse_bq_query_response(&body).expect("parse fixture");
    let lines = gcp_lines_from_bq_rows(&rows, window());
    assert_eq!(lines.len(), 4);
    assert_eq!(lines[0].vendor, "gcp");
    assert_eq!(lines[0].category, "ai_api");
    assert_eq!(lines[0].currency, "USD");
    assert_eq!(lines[0].source, "api");
    assert_eq!(lines[0].status, "estimated");
    assert!(!lines[0].external_ref.is_empty());
    let compute = lines
        .iter()
        .find(|l| l.category == "compute")
        .expect("compute line");
    assert_eq!(compute.sku, "N1 Predefined Instance Core");
}

#[test]
fn gcp_env_config_and_from_env_factory() {
    let _guard = EnvGuard::clear(GCP_ENV_KEYS);
    assert!(gcp_billing_config_from_env().is_none());
    assert!(gcp_from_env().is_none());

    EnvGuard::set("GCP_VENDOR_BILL_ENABLED", "1");
    assert!(gcp_from_env().is_none());

    EnvGuard::set("GCP_BILLING_PROJECT_ID", "billing-proj");
    EnvGuard::set("GCP_BILLING_DATASET", "billing_export");
    EnvGuard::set("GCP_BILLING_TABLE", "gcp_billing_export_v1_XXXX");
    EnvGuard::set(
        "GOOGLE_APPLICATION_CREDENTIALS_JSON",
        r#"{"client_email":"sa@test.iam.gserviceaccount.com","private_key":"x"}"#,
    );
    let cfg = gcp_billing_config_from_env().expect("config");
    assert_eq!(cfg.project_id, "billing-proj");
    assert_eq!(cfg.dataset, "billing_export");
    assert_eq!(cfg.table, "gcp_billing_export_v1_XXXX");

    EnvGuard::set("VENDOR_BILL_STAGGER_MINS", "0,15,30,45");
    let task = gcp_from_env().expect("gcp task");
    assert_eq!(task.name(), "vendor_bill_gcp");
    assert_eq!(task.stagger_mins, 15);
}

#[test]
fn gcp_vendor_source_exposes_vendor_id() {
    assert_eq!(GcpVendorSource::default().vendor(), "gcp");
}
