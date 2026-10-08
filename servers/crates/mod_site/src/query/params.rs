use anyhow::{bail, Result};
use chrono::{Datelike, DateTime, Duration, NaiveDate, TimeZone, Utc};
use serde_json::Value;

use crate::ts::ts_from_ms;

pub fn query_param_i64(params: &Value, key: &str, default: i64) -> i64 {
    params
        .get(key)
        .and_then(|v| v.as_i64().or_else(|| v.as_str()?.parse().ok()))
        .unwrap_or(default)
}

pub fn query_param_i32(params: &Value, key: &str, default: i32) -> i32 {
    params
        .get(key)
        .and_then(|v| v.as_i64().map(|n| n as i32).or_else(|| v.as_str()?.parse().ok()))
        .unwrap_or(default)
}

pub fn query_param_bool(params: &Value, key: &str, default: bool) -> bool {
    params
        .get(key)
        .and_then(|v| {
            v.as_bool()
                .or_else(|| match v.as_str()? {
                    "1" | "true" | "yes" => Some(true),
                    "0" | "false" | "no" => Some(false),
                    _ => None,
                })
        })
        .unwrap_or(default)
}

pub fn query_param_str<'a>(params: &'a Value, key: &str, default: &'a str) -> &'a str {
    params
        .get(key)
        .and_then(|v| v.as_str())
        .map(str::trim)
        .unwrap_or(default)
}

pub fn query_param_str_vec(params: &Value, key: &str) -> Vec<String> {
    if let Some(arr) = params.get(key).and_then(|v| v.as_array()) {
        return arr
            .iter()
            .filter_map(|v| v.as_str())
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(String::from)
            .collect();
    }
    if let Some(single) = params.get(key).and_then(|v| v.as_str()) {
        let s = single.trim();
        if !s.is_empty() {
            return vec![s.to_string()];
        }
    }
    Vec::new()
}


pub fn query_time_range(params: &Value) -> Result<(Option<DateTime<Utc>>, Option<DateTime<Utc>>)> {
    let from_ms = query_param_i64(params, "time_from_ms", 0);
    let to_ms = query_param_i64(params, "time_to_ms", 0);
    if from_ms > 0 || to_ms > 0 {
        if from_ms > 0 && to_ms > 0 && from_ms > to_ms {
            bail!("time_from_ms must be <= time_to_ms");
        }
        return Ok((ts_from_ms(from_ms), ts_from_ms(to_ms)));
    }
    let range = query_param_str(params, "range", "").to_ascii_lowercase();
    Ok(match named_utc_range(&range) {
        Some((from, to)) => (Some(from), Some(to)),
        None => (None, None),
    })
}

/// UTC calendar window for `today` / `this_week` / `this_month`.
/// Upper bound is the next boundary minus 1ms so SQL `time_ts <= $3` stays inclusive.
fn named_utc_range(range: &str) -> Option<(DateTime<Utc>, DateTime<Utc>)> {
    let today = Utc::now().date_naive();
    let (start_date, next_boundary) = match range {
        "today" => (today, today + Duration::days(1)),
        "this_week" => {
            let monday = today - Duration::days(today.weekday().num_days_from_monday() as i64);
            (monday, monday + Duration::days(7))
        }
        "this_month" => {
            let start = NaiveDate::from_ymd_opt(today.year(), today.month(), 1)?;
            let next = if today.month() == 12 {
                NaiveDate::from_ymd_opt(today.year() + 1, 1, 1)?
            } else {
                NaiveDate::from_ymd_opt(today.year(), today.month() + 1, 1)?
            };
            (start, next)
        }
        _ => return None,
    };
    let from = utc_midnight(start_date)?;
    let to = utc_midnight(next_boundary)? - Duration::milliseconds(1);
    Some((from, to))
}

fn utc_midnight(date: NaiveDate) -> Option<DateTime<Utc>> {
    date.and_hms_opt(0, 0, 0)
        .map(|naive| Utc.from_utc_datetime(&naive))
}

#[cfg(test)]
#[path = "params_test.rs"]
mod params_test;
