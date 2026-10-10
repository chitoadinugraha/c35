use anyhow::Result;
use chrono::{DateTime, Utc};
use serde_json::Value;

use c35_time_range::{date_range_from_params_at, named_range_at as shared_named_range_at};

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

fn default_tz_from_params(params: &Value) -> &str {
    let tz = query_param_str(params, "tz", "");
    if tz.is_empty() { "UTC" } else { tz }
}

pub fn query_time_range(params: &Value) -> Result<(Option<DateTime<Utc>>, Option<DateTime<Utc>>)> {
    let resolved = date_range_from_params_at(params, Utc::now(), default_tz_from_params(params))?;
    Ok((resolved.from, resolved.to))
}

/// Named window in UTC calendar (legacy). Prefer `named_range_at` with explicit tz via params.
pub fn named_utc_range_at(
    range: &str,
    now: DateTime<Utc>,
) -> Option<(DateTime<Utc>, DateTime<Utc>)> {
    shared_named_range_at(range, now, "UTC")
}

#[cfg(test)]
#[path = "params_test.rs"]
mod params_test;
