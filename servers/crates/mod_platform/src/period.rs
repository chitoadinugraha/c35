use chrono::{DateTime, Datelike, Duration, FixedOffset, NaiveDate, Utc};

fn vendor_bill_tz() -> FixedOffset {
    let name = std::env::var("VENDOR_BILL_TZ")
        .unwrap_or_else(|_| "Asia/Jakarta".into())
        .trim()
        .to_ascii_lowercase();
    let secs = match name.as_str() {
        "asia/jakarta" | "wib" | "ict" | "+07" | "+7" => 7 * 3600,
        "utc" => 0,
        _ => 7 * 3600,
    };
    FixedOffset::east_opt(secs).expect("vendor bill tz offset")
}

fn local_date(now: DateTime<Utc>) -> NaiveDate {
    now.with_timezone(&vendor_bill_tz()).date_naive()
}

/// MTD window: 1st of current month through yesterday (vendor bill timezone).
pub fn vendor_bill_mtd_window(now: DateTime<Utc>) -> (NaiveDate, NaiveDate) {
    let today = local_date(now);
    let period_start = today.with_day(1).expect("month start");
    let period_end = today - Duration::days(1);
    (period_start, period_end)
}

/// Full previous calendar month in vendor bill timezone.
pub fn vendor_bill_prev_month_window(now: DateTime<Utc>) -> (NaiveDate, NaiveDate) {
    let today = local_date(now);
    let first_this = today.with_day(1).expect("month start");
    let period_end = first_this - Duration::days(1);
    let period_start = period_end.with_day(1).expect("prev month start");
    (period_start, period_end)
}

pub fn vendor_bill_should_finalize_today(now: DateTime<Utc>, finalize_days: &[u32]) -> bool {
    let day = local_date(now).day();
    finalize_days.contains(&day)
}
