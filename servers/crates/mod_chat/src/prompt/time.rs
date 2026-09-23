use chrono::{DateTime, Duration, Utc};

pub const TIME_INST: &str =
    "[CURRENT TIME] For questions about today's date, time, or day of week, answer from the timestamp below. Do not call web.search for this.";

pub fn time_timezone_from_locale(locale: &str) -> &'static str {
    let l = locale.trim().to_ascii_lowercase();
    if l.starts_with("id") { "Asia/Jakarta" } else { "UTC" }
}

pub fn time_timezone_resolve(locale: &str, user: &str) -> &'static str {
    if locale_prefers_indonesian(user, locale) {
        return "Asia/Jakarta";
    }
    time_timezone_from_locale(locale)
}

pub fn time_timezone_offset(tz: &str) -> i32 {
    match tz.trim().to_ascii_lowercase().as_str() {
        "asia/jakarta" | "wib" | "ict" | "+07" | "+7" => 7,
        "utc" | "" => 0,
        _ => 0,
    }
}

fn now_line(now: &DateTime<Utc>, offset_hours: i32, label: &str) -> String {
    let local = *now + Duration::hours(offset_hours as i64);
    format!(
        "Now: {}, {} {}",
        local.format("%A"),
        local.format("%d %B %Y, %H:%M"),
        label
    )
}

pub fn time_prompt_block(timezone: &str) -> String {
    let now_utc = Utc::now();
    let tz = timezone.trim();
    let offset = time_timezone_offset(tz);
    let label = if !tz.is_empty() && !tz.eq_ignore_ascii_case("utc") {
        tz
    } else if offset == 0 {
        "UTC"
    } else {
        tz
    };
    let now = now_line(&now_utc, offset, label);
    format!("{TIME_INST}\n\n{now}")
}

fn locale_prefers_indonesian(user: &str, locale: &str) -> bool {
    if locale.trim().to_ascii_lowercase().starts_with("id") {
        return true;
    }
    let u = user.to_ascii_lowercase();
    ["hari apa", "hari ini", "jam berapa", "tanggal", "sekarang hari", "pukul berapa", "waktu sekarang"]
        .iter()
        .any(|k| u.contains(k))
}

pub fn user_asks_time(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    ["hari apa", "hari ini", "what day", "tanggal", "jam berapa", "what time", "what date", "sekarang hari", "pukul berapa", "waktu sekarang"]
        .iter()
        .any(|k| t.contains(k))
}

pub fn time_prompt_prepend(block: &str, base: &str) -> String {
    let block = block.trim();
    if block.is_empty() {
        return base.to_string();
    }
    if base.trim().is_empty() {
        return block.to_string();
    }
    format!("{block}\n\n{base}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_asks_time_matches_indonesian_day_question() {
        assert!(user_asks_time("sekarang hari apa ?"));
        assert!(user_asks_time("Sekarang jam berapa?"));
        assert!(user_asks_time("what day is it today?"));
        assert!(!user_asks_time("buatkan gambar kucing"));
    }

    #[test]
    fn time_prompt_block_includes_now_line() {
        let block = time_prompt_block("Asia/Jakarta");
        assert!(block.contains(TIME_INST));
        assert!(block.contains("Now:"));
        assert!(block.contains("Asia/Jakarta"));
    }

    #[test]
    fn time_timezone_resolve_prefers_indonesian_user_text() {
        assert_eq!(time_timezone_resolve("en", "sekarang hari apa ?"), "Asia/Jakarta");
    }
}
