use chrono::{Datelike, NaiveDate, TimeZone, Utc};

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
    multi_day_bounds_ms(day_id, 1, locale)
}

pub fn multi_day_bounds_ms(day_id: &str, days: i32, locale: &str) -> anyhow::Result<(i64, i64)> {
    let naive = NaiveDate::parse_from_str(day_id, "%Y-%m-%d")?;
    let off = offset_hours(timezone_from_locale(locale));
    let days_clamped = days.clamp(1, 30);
    let start_date = naive - chrono::Duration::days((days_clamped - 1) as i64);
    let start = start_date.and_hms_opt(0, 0, 0).unwrap();
    let end = naive.and_hms_opt(23, 59, 59).unwrap();
    let start_ms = Utc.from_utc_datetime(&start).timestamp_millis() - off as i64 * 3_600_000;
    let end_ms = Utc.from_utc_datetime(&end).timestamp_millis() - off as i64 * 3_600_000 + 999;
    Ok((start_ms, end_ms))
}

pub use c35_store::{snowflake_max_at_ms, snowflake_min_at_ms};

pub fn period_label(day_id: &str, locale: &str) -> String {
    let today = today_day_id(locale);
    let yesterday = resolve_day_id("yesterday", locale);
    let id = locale.to_lowercase().starts_with("id");
    if day_id == today {
        return if id { "Hari ini".into() } else { "Today".into() };
    }
    if day_id == yesterday {
        return if id { "Kemarin".into() } else { "Yesterday".into() };
    }
    day_id.to_string()
}
