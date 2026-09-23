use chrono::{Datelike, NaiveDate, TimeZone, Timelike, Utc};

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

pub fn local_hour(locale: &str) -> u32 {
    let off = offset_hours(timezone_from_locale(locale));
    let now = Utc::now() + chrono::Duration::hours(off as i64);
    now.hour()
}

pub fn infer_meal_type(note: &str, locale: &str) -> &'static str {
    let n = note.to_ascii_lowercase();
    if n.contains("sarapan") || n.contains("breakfast") || n.contains("pagi") {
        return "breakfast";
    }
    if n.contains("makan siang") || n.contains("lunch") || n.contains("siang") {
        return "lunch";
    }
    if n.contains("makan malam") || n.contains("dinner") || n.contains("malam") {
        return "dinner";
    }
    if n.contains("late night") || n.contains("tengah malam") || n.contains("sahur") || n.contains("supper") {
        return "late_night";
    }
    if n.contains("dessert")
        || n.contains("pencuci mulut")
        || n.contains("es krim")
        || n.contains("ice cream")
        || n.contains("cake")
        || n.contains("kue")
    {
        return "dessert";
    }
    if n.contains("snack") || n.contains("camilan") || n.contains("ngemil") || n.contains("jajan") {
        return "snack";
    }

    let h = local_hour(locale);
    match h {
        5..=10 => "breakfast",
        11..=14 => "lunch",
        15..=17 => "snack",
        18..=21 => "dinner",
        _ => "late_night",
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
    let days_clamped = days.clamp(1, 14);
    let start_date = naive - chrono::Duration::days((days_clamped - 1) as i64);
    let start = start_date.and_hms_opt(0, 0, 0).unwrap();
    let end = naive.and_hms_opt(23, 59, 59).unwrap();
    let start_ms = Utc.from_utc_datetime(&start).timestamp_millis() - off as i64 * 3_600_000;
    let end_ms = Utc.from_utc_datetime(&end).timestamp_millis() - off as i64 * 3_600_000 + 999;
    Ok((start_ms, end_ms))
}

pub use c35_store::{snowflake_max_at_ms, snowflake_min_at_ms};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_infer_meal_type_keywords() {
        assert_eq!(infer_meal_type("Sarapan bubur ayam", "id-ID"), "breakfast");
        assert_eq!(infer_meal_type("Pancakes for breakfast", "en-US"), "breakfast");
        assert_eq!(infer_meal_type("Makan siang nasi padang", "id-ID"), "lunch");
        assert_eq!(infer_meal_type("Quick lunch salad", "en-US"), "lunch");
        assert_eq!(infer_meal_type("Makan malam sate", "id-ID"), "dinner");
        assert_eq!(infer_meal_type("Steak dinner", "en-US"), "dinner");
        assert_eq!(infer_meal_type("Sahur jam 3 pagi", "id-ID"), "breakfast"); // "pagi" matches breakfast or sahur late night depending on precedence
        assert_eq!(infer_meal_type("Late night indomie", "en-US"), "late_night");
        assert_eq!(infer_meal_type("Es krim matcha", "id-ID"), "dessert");
        assert_eq!(infer_meal_type("Ngemil keripik", "id-ID"), "snack");
    }
}
