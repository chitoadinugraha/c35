use chrono::{DateTime, Duration, Utc};
use chrono_tz::Tz;

pub const TIME_INST: &str =
    "[CURRENT TIME] For questions about today's date, time, or day of week, answer from the timestamp below. Do not call web.search for this.";

pub const LOCATION_INST: &str =
    "[USER LOCATION] Use for local recommendations (food, cinema, weather, shops, events). When the user asks about nearby options without naming another place, prefer this city in your answer and include it in web.search queries for local weather, cinema, or 'near me' lookups.";

pub fn time_timezone_from_locale(locale: &str) -> &'static str {
    let l = locale.trim().to_ascii_lowercase();
    if l.starts_with("id") {
        "Asia/Jakarta"
    } else {
        "UTC"
    }
}

pub fn time_timezone_resolve(user_tz: &str, locale: &str, user: &str) -> String {
    let tz = user_tz.trim();
    if !tz.is_empty() && !tz.eq_ignore_ascii_case("utc") {
        return tz.to_string();
    }
    if locale_prefers_indonesian(user, locale) {
        return "Asia/Jakarta".into();
    }
    time_timezone_from_locale(locale).to_string()
}

pub fn time_timezone_offset(tz: &str) -> i32 {
    match tz.trim().to_ascii_lowercase().as_str() {
        "asia/jakarta" | "wib" | "ict" | "+07" | "+7" => 7,
        "asia/singapore" | "asia/kuala_lumpur" => 8,
        "asia/tokyo" | "jst" => 9,
        "europe/london" | "gmt" | "bst" => 0,
        "europe/berlin" | "cet" => 1,
        "america/new_york" | "est" | "edt" => -5,
        "america/los_angeles" | "pst" | "pdt" => -8,
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
    let tz_label = timezone.trim();
    let now = if let Ok(tz) = tz_label.parse::<Tz>() {
        format!("Now: {}", now_utc.with_timezone(&tz).format("%A, %d %B %Y, %H:%M %Z"))
    } else {
        let offset = time_timezone_offset(tz_label);
        let label = if !tz_label.is_empty() && !tz_label.eq_ignore_ascii_case("utc") {
            tz_label
        } else if offset == 0 {
            "UTC"
        } else {
            tz_label
        };
        now_line(&now_utc, offset, label)
    };
    let tz_note = if tz_label.is_empty() { "UTC" } else { tz_label };
    format!("{TIME_INST}\n\n{now} ({tz_note})")
}

pub fn location_prompt_block(city: &str, region: &str, country: &str) -> String {
    let city = city.trim();
    if city.is_empty() {
        return String::new();
    }
    let mut parts = vec![city.to_string()];
    if !region.trim().is_empty() {
        parts.push(region.trim().to_string());
    }
    if !country.trim().is_empty() {
        parts.push(country.trim().to_ascii_uppercase());
    }
    format!("{LOCATION_INST}\n\nUser location (approximate): {}", parts.join(", "))
}

fn locale_prefers_indonesian(user: &str, locale: &str) -> bool {
    if locale.trim().to_ascii_lowercase().starts_with("id") {
        return true;
    }
    let u = user.to_ascii_lowercase();
    [
        "hari apa",
        "hari ini",
        "jam berapa",
        "tanggal",
        "sekarang hari",
        "pukul berapa",
        "waktu sekarang",
    ]
    .iter()
    .any(|k| u.contains(k))
}

fn web_lookup_blocks_time_strip(t: &str) -> bool {
    [
        "search", "cari ", "google ", "berita", "latest ", "news ", "film", "bioskop", "cinema", "jadwal",
        "tayang", "nonton", "cuaca", "harga ", "showtime", "jadwal nonton",
    ]
    .iter()
    .any(|k| t.contains(k))
}

pub fn user_asks_time(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    if food_recap_blocks_time_strip(&t) || web_lookup_blocks_time_strip(&t) {
        return false;
    }
    [
        "hari apa",
        "hari ini",
        "what day",
        "tanggal",
        "jam berapa",
        "what time",
        "what date",
        "sekarang hari",
        "pukul berapa",
        "waktu sekarang",
    ]
    .iter()
    .any(|k| t.contains(k))
}

fn food_recap_blocks_time_strip(t: &str) -> bool {
    if [
        "makan",
        "dimakan",
        "konsumsi",
        "what did i eat",
        "food history",
        "meal recap",
        "riwayat makan",
    ]
    .iter()
    .any(|k| t.contains(k))
    {
        return true;
    }
    t.contains("apa aja yang aku makan") || t.contains("apa yang aku makan")
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

pub fn prompt_context_prepend(time_block: &str, location_block: &str, base: &str) -> String {
    let mut out = base.to_string();
    if !location_block.trim().is_empty() {
        out = time_prompt_prepend(location_block, &out);
    }
    if !time_block.trim().is_empty() {
        out = time_prompt_prepend(time_block, &out);
    }
    out
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
        assert!(!user_asks_time("apa aja yang aku makan hari ini?"));
        assert!(!user_asks_time("riwayat makan kemarin"));
        assert!(!user_asks_time("film apa saja di bioskop malang hari ini ?"));
    }

    #[test]
    fn time_prompt_block_includes_now_line() {
        let block = time_prompt_block("Asia/Jakarta");
        assert!(block.contains(TIME_INST));
        assert!(block.contains("Now:"));
        assert!(block.contains("Asia/Jakarta"));
    }

    #[test]
    fn time_timezone_resolve_prefers_user_tz() {
        assert_eq!(
            time_timezone_resolve("America/New_York", "id-ID", "hello"),
            "America/New_York"
        );
    }

    #[test]
    fn time_timezone_resolve_prefers_indonesian_user_text() {
        assert_eq!(time_timezone_resolve("", "en", "sekarang hari apa ?"), "Asia/Jakarta");
    }

    #[test]
    fn location_prompt_block_formats_city() {
        let block = location_prompt_block("Malang", "East Java", "ID");
        assert!(block.contains(LOCATION_INST));
        assert!(block.contains("Malang"));
        assert!(block.contains("East Java"));
    }
}
