use chrono::NaiveDate;
use c35_mod_platform::parse_vendor_csv;

fn period() -> (NaiveDate, NaiveDate) {
    (
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        NaiveDate::from_ymd_opt(2026, 9, 30).unwrap(),
    )
}

#[test]
fn parse_vendor_csv_cf_delegates_to_invoice_parser() {
    let bytes = include_bytes!("fixtures/cf_invoice.csv");
    let (start, end) = period();
    let lines = parse_vendor_csv("cf", bytes, start, end, "other", true).expect("parse cf");
    assert_eq!(lines.len(), 3);
    assert!(lines.iter().all(|l| l.period_start == start && l.period_end == end));
    assert!(lines.iter().all(|l| l.status == "finalized"));
    assert!(lines.iter().all(|l| l.external_ref.contains(":2026-09-01:")));
}

#[test]
fn parse_vendor_csv_generic_oci_maps_columns() {
    let csv = "sku,description,amount,currency,category\nOKE,Container Engine,100.50,USD,compute\n";
    let (start, end) = period();
    let lines = parse_vendor_csv("oci", csv.as_bytes(), start, end, "other", false).expect("parse");
    assert_eq!(lines.len(), 1);
    let line = &lines[0];
    assert_eq!(line.vendor, "oci");
    assert_eq!(line.sku, "OKE");
    assert_eq!(line.category, "compute");
    assert_eq!(line.amount_native, 100.5);
    assert_eq!(line.source, "csv");
    assert_eq!(line.status, "estimated");
    assert_eq!(line.period_start, start);
    assert!(line.external_ref.starts_with("oci:csv:OKE:2026-09-01:"));
}

#[test]
fn parse_vendor_csv_generic_infers_category_when_missing() {
    let csv = "description,amount,currency\nBlock Storage volumes,42.00,USD\n";
    let (start, end) = period();
    let lines = parse_vendor_csv("oci", csv.as_bytes(), start, end, "other", false).expect("parse");
    assert_eq!(lines.len(), 1);
    assert_eq!(lines[0].category, "storage");
}

#[test]
fn parse_vendor_csv_default_category_param() {
    let csv = "description,amount,currency\nMisc charge,1.00,USD\n";
    let (start, end) = period();
    let lines =
        parse_vendor_csv("wasabi", csv.as_bytes(), start, end, "network", false).expect("parse");
    assert_eq!(lines[0].category, "network");
}

#[test]
fn parse_vendor_csv_rejects_unknown_vendor() {
    let csv = "description,amount,currency\nx,1,USD\n";
    let (start, end) = period();
    let result = parse_vendor_csv("aws", csv.as_bytes(), start, end, "other", false);
    assert!(result.is_err(), "expected unsupported vendor error");
}

#[test]
fn parse_vendor_csv_gcp_classifies_ai() {
    let csv = "sku,description,amount,currency\nvertex,Vertex AI Gemini input,9.99,USD\n";
    let (start, end) = period();
    let lines = parse_vendor_csv("gcp", csv.as_bytes(), start, end, "other", true).expect("parse");
    assert_eq!(lines[0].category, "ai_api");
    assert_eq!(lines[0].status, "finalized");
}
