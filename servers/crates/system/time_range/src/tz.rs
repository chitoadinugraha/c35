use chrono::{DateTime, Duration, NaiveDate, TimeZone, Utc};
use chrono_tz::Tz;

pub fn parse_tz(tz: &str) -> Tz {
    let t = tz.trim();
    if t.is_empty() || t.eq_ignore_ascii_case("utc") {
        return Tz::UTC;
    }
    if let Ok(z) = t.parse::<Tz>() {
        return z;
    }
    match t.to_ascii_lowercase().as_str() {
        "asia/jakarta" | "wib" | "ict" | "+07" | "+7" => "Asia/Jakarta".parse().unwrap_or(Tz::UTC),
        "asia/singapore" => "Asia/Singapore".parse().unwrap_or(Tz::UTC),
        _ => Tz::UTC,
    }
}

pub fn timezone_default_from_locale(locale: &str) -> &'static str {
    let l = locale.trim().to_ascii_lowercase();
    if l.starts_with("id") {
        "Asia/Jakarta"
    } else {
        "UTC"
    }
}

pub fn local_day_bounds_utc(date: NaiveDate, tz: &Tz) -> Option<(DateTime<Utc>, DateTime<Utc>)> {
    let start_naive = date.and_hms_opt(0, 0, 0)?;
    let start = tz.from_local_datetime(&start_naive).single()?.with_timezone(&Utc);
    let end_date = date + Duration::days(1);
    let end_naive = end_date.and_hms_opt(0, 0, 0)? - Duration::milliseconds(1);
    let end = tz.from_local_datetime(&end_naive).single()?.with_timezone(&Utc);
    Some((start, end))
}

pub fn local_today(now_utc: DateTime<Utc>, tz: &Tz) -> NaiveDate {
    now_utc.with_timezone(tz).date_naive()
}
