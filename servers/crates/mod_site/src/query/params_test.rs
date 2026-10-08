use super::*;
use chrono::{Datelike, Duration, NaiveDate, TimeZone, Timelike, Utc};
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

#[test]
fn query_time_range_explicit_bounds_win_over_range() {
    let params = json!({
        "range": "today",
        "time_from_ms": 1_700_000_000_000_i64,
        "time_to_ms": 1_700_000_060_000_i64
    });
    let (from, to) = query_time_range(&params).expect("explicit");
    assert_eq!(from.unwrap().timestamp_millis(), 1_700_000_000_000);
    assert_eq!(to.unwrap().timestamp_millis(), 1_700_000_060_000);
}

#[test]
fn query_time_range_unknown_and_empty_stay_unset() {
    for params in [json!({}), json!({ "range": "" }), json!({ "range": "yesterday" })] {
        let (from, to) = query_time_range(&params).expect("unset");
        assert!(from.is_none());
        assert!(to.is_none());
    }
}

#[test]
fn query_time_range_today_utc() {
    let (from, to) = query_time_range(&json!({ "range": "TODAY" })).expect("today");
    let (from, to) = (from.unwrap(), to.unwrap());
    let now = Utc::now();
    assert_eq!(from.date_naive(), now.date_naive());
    assert_midnight(from);
    assert_eq!(to, from + Duration::days(1) - Duration::milliseconds(1));
    assert!(from <= now && now <= to);
}

#[test]
fn query_time_range_this_week_iso_monday_utc() {
    let (from, to) = query_time_range(&json!({ "range": "This_Week" })).expect("week");
    let (from, to) = (from.unwrap(), to.unwrap());
    let now = Utc::now();
    assert_eq!(from.weekday(), chrono::Weekday::Mon);
    assert_midnight(from);
    assert_eq!(to, from + Duration::days(7) - Duration::milliseconds(1));
    assert_eq!(to.weekday(), chrono::Weekday::Sun);
    assert!(from <= now && now <= to);
}

#[test]
fn query_time_range_this_month_utc() {
    let (from, to) = query_time_range(&json!({ "range": "this_month" })).expect("month");
    let (from, to) = (from.unwrap(), to.unwrap());
    let now = Utc::now();
    assert_eq!(from.date_naive(), NaiveDate::from_ymd_opt(now.year(), now.month(), 1).unwrap());
    assert_midnight(from);
    let next = if now.month() == 12 {
        NaiveDate::from_ymd_opt(now.year() + 1, 1, 1).unwrap()
    } else {
        NaiveDate::from_ymd_opt(now.year(), now.month() + 1, 1).unwrap()
    };
    let next_start = Utc
        .from_utc_datetime(&next.and_hms_opt(0, 0, 0).unwrap());
    assert_eq!(to, next_start - Duration::milliseconds(1));
    assert!(from <= now && now <= to);
}

fn assert_midnight(t: chrono::DateTime<Utc>) {
    assert_eq!(t.hour(), 0);
    assert_eq!(t.minute(), 0);
    assert_eq!(t.second(), 0);
    assert_eq!(t.nanosecond(), 0);
}
