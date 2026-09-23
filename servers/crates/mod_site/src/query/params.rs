use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
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

pub fn query_time_range(params: &Value) -> Result<(Option<DateTime<Utc>>, Option<DateTime<Utc>>)> {
    let from_ms = query_param_i64(params, "time_from_ms", 0);
    let to_ms = query_param_i64(params, "time_to_ms", 0);
    if from_ms > 0 && to_ms > 0 && from_ms > to_ms {
        bail!("time_from_ms must be <= time_to_ms");
    }
    Ok((ts_from_ms(from_ms), ts_from_ms(to_ms)))
}

#[cfg(test)]
#[path = "params_test.rs"]
mod params_test;
