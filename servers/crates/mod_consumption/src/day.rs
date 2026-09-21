use chrono::{Datelike, NaiveDate, TimeZone, Utc};

const EPOCH_MS: i64 = 1_704_067_200_000;
const SHIFT: i64 = 22;

pub fn timezone_from_locale(locale: &str) -> &'static str {
    let l = locale.trim().to_ascii_lowercase();
    if l.starts_with("id") { "Asia/Jakarta" } else { "UTC" }
}

pub fn offset_hours(tz: &str) -> i32 {
    match tz.trim().to_ascii_lowercase().as_str() {
        "asia/jakarta" | "wib" | "ict" | "+07" | "+7" => 7,
        _ => 0,
    }
}

pub fn today_day_id(locale: &str) -> String {
    let off = offset_hours(timezone_from_locale(locale));
    let now = Utc::now() + chrono::Duration::hours(off as i64);
    format!("{}-{:02}-{:02}", now.year(), now.month(), now.day())
}

pub fn resolve_day_id(day_id: &str, locale: &str) -> String {
    let d = day_id.trim().to_ascii_lowercase();
    if d.is_empty() || d == "today" {
        return today_day_id(locale);
    }
    if d == "yesterday" {
        let off = offset_hours(timezone_from_locale(locale));
        let now = Utc::now() + chrono::Duration::hours(off as i64);
        let y = now - chrono::Duration::days(1);
        return format!("{}-{:02}-{:02}", y.year(), y.month(), y.day());
    }
    day_id.trim().to_string()
}

pub fn day_bounds_ms(day_id: &str, locale: &str) -> anyhow::Result<(i64, i64)> {
    let naive = NaiveDate::parse_from_str(day_id, "%Y-%m-%d")?;
    let off = offset_hours(timezone_from_locale(locale));
    let start = naive.and_hms_opt(0, 0, 0).unwrap();
    let end = naive.and_hms_opt(23, 59, 59).unwrap();
    let start_ms = Utc.from_utc_datetime(&start).timestamp_millis() - off as i64 * 3_600_000;
    let end_ms = Utc.from_utc_datetime(&end).timestamp_millis() - off as i64 * 3_600_000 + 999;
    Ok((start_ms, end_ms))
}

pub fn snowflake_min_at_ms(ms: i64) -> i64 {
    ((ms.saturating_sub(EPOCH_MS)).max(0)) << SHIFT
}

pub fn snowflake_max_at_ms(ms: i64) -> i64 {
    snowflake_min_at_ms(ms) | ((1_i64 << SHIFT) - 1)
}
