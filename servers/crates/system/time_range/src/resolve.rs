use anyhow::{bail, Result};
use chrono::{Datelike, DateTime, Duration, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::tz::{local_day_bounds_utc, local_today, parse_tz};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DateRangeWire {
    #[serde(default)]
    pub range: String,
    #[serde(default)]
    pub time_from_ms: i64,
    #[serde(default)]
    pub time_to_ms: i64,
    #[serde(default)]
    pub date_from: String,
    #[serde(default)]
    pub date_to: String,
    #[serde(default)]
    pub tz: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct DateRangeResolved {
    pub from: Option<DateTime<Utc>>,
    pub to: Option<DateTime<Utc>>,
    pub range_key: String,
    pub tz: String,
}

pub fn range_key_normalize(raw: &str) -> String {
    let r = raw.trim().to_ascii_lowercase().replace(' ', "_");
    match r.as_str() {
        "" => String::new(),
        "month_to_date" | "bulan_ini" => "mtd".into(),
        other => other.to_string(),
    }
}

fn param_i64(params: &Value, key: &str, default: i64) -> i64 {
    params
        .get(key)
        .and_then(|v| v.as_i64().or_else(|| v.as_str()?.parse().ok()))
        .unwrap_or(default)
}

fn param_str(params: &Value, key: &str) -> String {
    params
        .get(key)
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(String::from)
        .unwrap_or_default()
}

pub fn wire_from_params(params: &Value) -> DateRangeWire {
    DateRangeWire {
        range: param_str(params, "range"),
        time_from_ms: param_i64(params, "time_from_ms", 0),
        time_to_ms: param_i64(params, "time_to_ms", 0),
        date_from: param_str(params, "date_from"),
        date_to: param_str(params, "date_to"),
        tz: param_str(params, "tz"),
    }
}

fn ts_from_ms(ms: i64) -> Option<DateTime<Utc>> {
    if ms <= 0 {
        return None;
    }
    DateTime::from_timestamp_millis(ms)
}

pub fn named_range_at(
    range: &str,
    now: DateTime<Utc>,
    tz_id: &str,
) -> Option<(DateTime<Utc>, DateTime<Utc>)> {
    let key = range_key_normalize(range);
    if key.is_empty() {
        return None;
    }
    let tz = parse_tz(tz_id);
    let today = local_today(now, &tz);

    let (start_date, end_inclusive) = match key.as_str() {
        "today" => return local_day_bounds_utc(today, &tz),
        "yesterday" => {
            let y = today - Duration::days(1);
            return local_day_bounds_utc(y, &tz);
        }
        "this_week" => {
            let monday = today - Duration::days(today.weekday().num_days_from_monday() as i64);
            let sunday = monday + Duration::days(6);
            (monday, sunday)
        }
        "last_week" => {
            let monday_this = today - Duration::days(today.weekday().num_days_from_monday() as i64);
            let monday_last = monday_this - Duration::days(7);
            let sunday_last = monday_last + Duration::days(6);
            (monday_last, sunday_last)
        }
        "this_month" => {
            let start = NaiveDate::from_ymd_opt(today.year(), today.month(), 1)?;
            let next = month_start_next(today)?;
            let end = next - Duration::days(1);
            (start, end)
        }
        "last_month" => {
            let this_start = NaiveDate::from_ymd_opt(today.year(), today.month(), 1)?;
            let prev_end = this_start - Duration::days(1);
            let start = NaiveDate::from_ymd_opt(prev_end.year(), prev_end.month(), 1)?;
            (start, prev_end)
        }
        "mtd" | "ytd" => {
            let start = if key == "ytd" {
                NaiveDate::from_ymd_opt(today.year(), 1, 1)?
            } else {
                NaiveDate::from_ymd_opt(today.year(), today.month(), 1)?
            };
            (start, today)
        }
        _ => return None,
    };

    let (from, _) = local_day_bounds_utc(start_date, &tz)?;
    let (_, to) = local_day_bounds_utc(end_inclusive, &tz)?;
    Some((from, to))
}

fn month_start_next(today: NaiveDate) -> Option<NaiveDate> {
    if today.month() == 12 {
        NaiveDate::from_ymd_opt(today.year() + 1, 1, 1)
    } else {
        NaiveDate::from_ymd_opt(today.year(), today.month() + 1, 1)
    }
}

pub fn date_range_from_params_at(
    params: &Value,
    now: DateTime<Utc>,
    default_tz: &str,
) -> Result<DateRangeResolved> {
    let wire = wire_from_params(params);
    date_range_resolve(&wire, now, default_tz)
}

pub fn date_range_from_params(params: &Value, default_tz: &str) -> Result<DateRangeResolved> {
    date_range_from_params_at(params, Utc::now(), default_tz)
}

pub fn date_range_resolve(
    wire: &DateRangeWire,
    now: DateTime<Utc>,
    default_tz: &str,
) -> Result<DateRangeResolved> {
    let tz = if wire.tz.is_empty() {
        default_tz.trim()
    } else {
        wire.tz.as_str()
    };
    let tz = if tz.is_empty() { "UTC" } else { tz };

    if wire.time_from_ms > 0 || wire.time_to_ms > 0 {
        if wire.time_from_ms > 0 && wire.time_to_ms > 0 && wire.time_from_ms > wire.time_to_ms {
            bail!("time_from_ms must be <= time_to_ms");
        }
        return Ok(DateRangeResolved {
            from: ts_from_ms(wire.time_from_ms),
            to: ts_from_ms(wire.time_to_ms),
            range_key: String::new(),
            tz: tz.to_string(),
        });
    }

    if !wire.date_from.is_empty() || !wire.date_to.is_empty() {
        let tz_parsed = parse_tz(tz);
        let from_date = if wire.date_from.is_empty() {
            None
        } else {
            Some(NaiveDate::parse_from_str(&wire.date_from, "%Y-%m-%d")?)
        };
        let to_date = if wire.date_to.is_empty() {
            None
        } else {
            Some(NaiveDate::parse_from_str(&wire.date_to, "%Y-%m-%d")?)
        };
        if let (Some(a), Some(b)) = (from_date, to_date) {
            if a > b {
                bail!("date_from must be <= date_to");
            }
        }
        let from = from_date
            .and_then(|d| local_day_bounds_utc(d, &tz_parsed).map(|(a, _)| a));
        let to = to_date
            .and_then(|d| local_day_bounds_utc(d, &tz_parsed).map(|(_, b)| b));
        return Ok(DateRangeResolved {
            from,
            to,
            range_key: String::new(),
            tz: tz.to_string(),
        });
    }

    let key = range_key_normalize(&wire.range);
    if key.is_empty() {
        return Ok(DateRangeResolved {
            from: None,
            to: None,
            range_key: String::new(),
            tz: tz.to_string(),
        });
    }

    if let Some((from, to)) = named_range_at(&key, now, tz) {
        return Ok(DateRangeResolved {
            from: Some(from),
            to: Some(to),
            range_key: key,
            tz: tz.to_string(),
        });
    }

    Ok(DateRangeResolved {
        from: None,
        to: None,
        range_key: String::new(),
        tz: tz.to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    #[test]
    fn explicit_ms_wins() {
        let params = serde_json::json!({
            "range": "today",
            "time_from_ms": 1_700_000_000_000_i64,
        });
        let r = date_range_from_params_at(&params, Utc::now(), "UTC").expect("ok");
        assert_eq!(r.range_key, "");
        assert!(r.from.is_some());
    }

    #[test]
    fn today_jakarta_uses_local_calendar_day() {
        let now = Utc.with_ymd_and_hms(2026, 10, 9, 18, 0, 0).unwrap();
        let (from, to) = named_range_at("today", now, "Asia/Jakarta").unwrap();
        let local = from.with_timezone(&parse_tz("Asia/Jakarta"));
        assert_eq!(local.day(), 10);
        assert!(to > from);
    }

    #[test]
    fn mtd_ends_today_not_month_end() {
        let now = Utc.with_ymd_and_hms(2026, 10, 15, 12, 0, 0).unwrap();
        let (from, to) = named_range_at("mtd", now, "UTC").unwrap();
        assert_eq!(to.with_timezone(&parse_tz("UTC")).day(), 15);
        assert_eq!(from.day(), 1);
    }

    #[test]
    fn normalize_month_to_date() {
        assert_eq!(range_key_normalize("month_to_date"), "mtd");
    }

    #[test]
    fn unknown_range_is_unbounded() {
        let params = serde_json::json!({ "range": "not_a_range" });
        let r = date_range_from_params_at(&params, Utc::now(), "UTC").expect("ok");
        assert!(r.from.is_none() && r.to.is_none());
    }
}
