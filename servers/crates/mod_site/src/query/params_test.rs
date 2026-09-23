use super::*;
use serde_json::json;

#[test]
fn query_param_i64_from_number_and_string() {
    let params = json!({ "time_from_ms": 1_700_000_000_000_i64, "x": "42" });
    assert_eq!(query_param_i64(&params, "time_from_ms", 0), 1_700_000_000_000);
    assert_eq!(query_param_i64(&params, "x", 0), 42);
    assert_eq!(query_param_i64(&params, "missing", 7), 7);
}

#[test]
fn query_param_i32_low_qty_max() {
    let params = json!({ "low_qty_max": "10" });
    assert_eq!(query_param_i32(&params, "low_qty_max", 5), 10);
}

#[test]
fn query_param_bool_parses_strings() {
    let params = json!({ "all_tracked": "yes", "off": "false" });
    assert!(query_param_bool(&params, "all_tracked", false));
    assert!(!query_param_bool(&params, "off", true));
}

#[test]
fn query_time_range_optional_bounds() {
    let params = json!({});
    let (from, to) = query_time_range(&params).expect("empty range");
    assert!(from.is_none());
    assert!(to.is_none());
}

#[test]
fn query_time_range_rejects_inverted_bounds() {
    let params = json!({ "time_from_ms": 2000, "time_to_ms": 1000 });
    assert!(query_time_range(&params).is_err());
}

#[test]
fn query_time_range_parses_ms() {
    let params = json!({ "time_from_ms": 1_700_000_000_000_i64 });
    let (from, to) = query_time_range(&params).expect("from only");
    assert!(from.is_some());
    assert!(to.is_none());
}
