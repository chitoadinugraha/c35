//! Date and format parse for closed stock reports (`inst.site.stock_report`).

use chrono::{Datelike, Duration, NaiveDate, TimeZone, Utc};

#[derive(Debug, Clone, PartialEq)]
pub struct StockReportIntent {
    pub query_id: &'static str,
    pub q: String,
    pub time_from_ms: i64,
    pub time_to_ms: i64,
    pub formats: Vec<StockReportFormat>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum StockReportFormat {
    Table,
    Pdf,
    Xlsx,
    Slides,
    Gsheet,
}

const CARD_NEEDLES: &[&[&str]] = &[&["kartu", "stok"], &["stock", "card"]];
const LIST_NEEDLES: &[&[&str]] = &[
    &["daftar", "stok"],
    &["stock", "list"],
    &["list", "stok"],
    &["semua", "stok"],
];
const MOVEMENT_NEEDLES: &[&[&str]] = &[
    &["mutasi"],
    &["masuk", "keluar"],
    &["in", "and", "out"],
    &["barang", "masuk"],
    &["barang", "keluar"],
    &["stock", "movement"],
    &["laporan", "stok"],
];

/// Closed stock-report intent. `None` when the text has no report needle
/// (`berapa stok` is a catalog lookup, not a report).
pub fn stock_report_parse(text: &str, now: chrono::DateTime<Utc>) -> Option<StockReportIntent> {
    let tokens = tokenize(text);
    if tokens.is_empty() {
        return None;
    }

    let card = phrase_spans(&tokens, CARD_NEEDLES);
    let list = phrase_spans(&tokens, LIST_NEEDLES);
    let movement = phrase_spans(&tokens, MOVEMENT_NEEDLES);
    let query_id = if !card.is_empty() {
        "tx.stock_card"
    } else if !list.is_empty() {
        "tx.stock_list"
    } else if !movement.is_empty() {
        "tx.stock_movement"
    } else {
        return None;
    };

    let mut used = vec![false; tokens.len()];
    for &(start, end) in card.iter().chain(list.iter()).chain(movement.iter()) {
        for slot in &mut used[start..end] {
            *slot = true;
        }
    }

    let mut formats = vec![StockReportFormat::Table];
    let mut i = 0;
    while i < tokens.len() {
        if tokens[i] == "google"
            && tokens
                .get(i + 1)
                .is_some_and(|next| next == "sheet" || next == "sheets")
        {
            push_format(&mut formats, StockReportFormat::Gsheet);
            used[i] = true;
            used[i + 1] = true;
            i += 2;
            continue;
        }
        if let Some(fmt) = format_word(&tokens[i]) {
            push_format(&mut formats, fmt);
            used[i] = true;
        }
        i += 1;
    }

    let mut month_hits: Vec<(u32, Option<i32>)> = Vec::new();
    let mut i = 0;
    while i < tokens.len() {
        if i + 1 < tokens.len()
            && ((tokens[i] == "bulan" && tokens[i + 1] == "ini")
                || (tokens[i] == "this" && tokens[i + 1] == "month"))
        {
            used[i] = true;
            used[i + 1] = true;
            i += 2;
            continue;
        }
        if let Some(month) = month_num(&tokens[i]) {
            let year = tokens.get(i + 1).and_then(|tok| parse_year(tok));
            mark_month_context(&tokens, &mut used, i, year.is_some());
            month_hits.push((month, year));
            if year.is_some() {
                i += 2;
                continue;
            }
        }
        i += 1;
    }

    let (time_from_ms, time_to_ms) = if query_id == "tx.stock_list" {
        (0, 0)
    } else {
        window_ms(&month_hits, now)
    };

    let q = tokens
        .iter()
        .enumerate()
        .filter(|(idx, _)| !used[*idx])
        .map(|(_, tok)| tok.as_str())
        .collect::<Vec<_>>()
        .join(" ");

    Some(StockReportIntent {
        query_id,
        q,
        time_from_ms,
        time_to_ms,
        formats,
    })
}

fn tokenize(text: &str) -> Vec<String> {
    text.split_whitespace()
        .map(|word| {
            word.trim_matches(|c: char| !c.is_alphanumeric())
                .to_lowercase()
        })
        .filter(|word| !word.is_empty())
        .collect()
}

fn phrase_spans(tokens: &[String], needles: &[&[&str]]) -> Vec<(usize, usize)> {
    let mut spans = Vec::new();
    for phrase in needles {
        let n = phrase.len();
        if n == 0 || tokens.len() < n {
            continue;
        }
        let mut i = 0;
        while i + n <= tokens.len() {
            let hit = tokens[i..i + n]
                .iter()
                .zip(phrase.iter())
                .all(|(tok, needle)| tok == needle);
            if hit {
                spans.push((i, i + n));
                i += n;
            } else {
                i += 1;
            }
        }
    }
    spans
}

fn format_word(token: &str) -> Option<StockReportFormat> {
    match token {
        "pdf" => Some(StockReportFormat::Pdf),
        "excel" | "xlsx" | "spreadsheet" => Some(StockReportFormat::Xlsx),
        "gsheet" => Some(StockReportFormat::Gsheet),
        "presentasi" | "slide" | "slides" | "presentation" => Some(StockReportFormat::Slides),
        _ => None,
    }
}

fn push_format(formats: &mut Vec<StockReportFormat>, fmt: StockReportFormat) {
    if !formats.contains(&fmt) {
        formats.push(fmt);
    }
}

fn mark_month_context(tokens: &[String], used: &mut [bool], idx: usize, has_year: bool) {
    used[idx] = true;
    let mut j = idx;
    if j > 0 && tokens[j - 1] == "bulan" {
        used[j - 1] = true;
        j -= 1;
    }
    if j > 0 && matches!(tokens[j - 1].as_str(), "dari" | "from" | "since") {
        used[j - 1] = true;
    }
    if has_year {
        used[idx + 1] = true;
    }
}

fn window_ms(month_hits: &[(u32, Option<i32>)], now: chrono::DateTime<Utc>) -> (i64, i64) {
    if let Some(&(month, Some(year))) = month_hits.iter().find(|(_, year)| year.is_some()) {
        return calendar_month_ms(year, month);
    }
    if let Some(&(month, _)) = month_hits.first() {
        let start = NaiveDate::from_ymd_opt(now.year(), month, 1).expect("month start");
        let tomorrow = now.date_naive() + Duration::days(1);
        return (utc_midnight_ms(start), utc_midnight_ms(tomorrow) - 1);
    }
    named_utc_range("this_month", now).expect("this_month")
}

/// UTC calendar window for `today` / `this_week` / `this_month`.
/// Upper bound is the next boundary minus 1ms so SQL `time_ts <= $n` stays inclusive.
fn named_utc_range(range: &str, now: chrono::DateTime<Utc>) -> Option<(i64, i64)> {
    let today = now.date_naive();
    let (start_date, next_boundary) = match range {
        "today" => (today, today + Duration::days(1)),
        "this_week" => {
            let monday = today - Duration::days(today.weekday().num_days_from_monday() as i64);
            (monday, monday + Duration::days(7))
        }
        "this_month" => {
            let start = NaiveDate::from_ymd_opt(today.year(), today.month(), 1)?;
            let next = if today.month() == 12 {
                NaiveDate::from_ymd_opt(today.year() + 1, 1, 1)?
            } else {
                NaiveDate::from_ymd_opt(today.year(), today.month() + 1, 1)?
            };
            (start, next)
        }
        _ => return None,
    };
    Some((
        utc_midnight_ms(start_date),
        utc_midnight_ms(next_boundary) - 1,
    ))
}

fn calendar_month_ms(year: i32, month: u32) -> (i64, i64) {
    let start = NaiveDate::from_ymd_opt(year, month, 1).expect("month start");
    let next = if month == 12 {
        NaiveDate::from_ymd_opt(year + 1, 1, 1).expect("next year")
    } else {
        NaiveDate::from_ymd_opt(year, month + 1, 1).expect("next month")
    };
    (utc_midnight_ms(start), utc_midnight_ms(next) - 1)
}

fn utc_midnight_ms(date: NaiveDate) -> i64 {
    let naive = date.and_hms_opt(0, 0, 0).expect("midnight");
    Utc.from_utc_datetime(&naive).timestamp_millis()
}

fn parse_year(token: &str) -> Option<i32> {
    if token.len() == 4 && token.chars().all(|c| c.is_ascii_digit()) {
        token
            .parse::<i32>()
            .ok()
            .filter(|year| (1900..=2100).contains(year))
    } else {
        None
    }
}

fn month_num(token: &str) -> Option<u32> {
    Some(match token {
        "januari" | "january" => 1,
        "februari" | "february" => 2,
        "maret" | "march" => 3,
        "april" => 4,
        "mei" | "may" => 5,
        "juni" | "june" => 6,
        "juli" | "july" => 7,
        "agustus" | "august" => 8,
        "september" => 9,
        "oktober" | "october" => 10,
        "november" => 11,
        "desember" | "december" => 12,
        _ => return None,
    })
}

#[cfg(test)]
mod stock_report_parse {
    use super::*;

    #[test]
    fn january_movement_pdf_parses() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 12, 0, 0).unwrap();
        let intent = stock_report_parse(
            "generate pdf report of all item in and out from january",
            now,
        )
        .unwrap();
        assert_eq!(intent.query_id, "tx.stock_movement");
        assert!(intent.formats.contains(&StockReportFormat::Pdf));
        assert!(intent.formats.contains(&StockReportFormat::Table));
        let from = Utc.timestamp_millis_opt(intent.time_from_ms).unwrap();
        assert_eq!((from.year(), from.month(), from.day()), (2026, 1, 1));
        let end_of_today =
            Utc.with_ymd_and_hms(2026, 10, 9, 0, 0, 0).unwrap() - Duration::milliseconds(1);
        assert_eq!(intent.time_to_ms, end_of_today.timestamp_millis());
    }

    #[test]
    fn bare_stok_is_not_a_report() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 0, 0, 0).unwrap();
        assert!(stock_report_parse("berapa stok susu", now).is_none());
    }

    #[test]
    fn stock_card_needs_the_phrase() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 0, 0, 0).unwrap();
        let intent = stock_report_parse("kartu stok indomie dari januari excel", now).unwrap();
        assert_eq!(intent.query_id, "tx.stock_card");
        assert_eq!(intent.q, "indomie");
        assert!(intent.formats.contains(&StockReportFormat::Xlsx));
        assert!(intent.formats.contains(&StockReportFormat::Table));
    }

    #[test]
    fn this_month_parses() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 15, 0, 0).unwrap();
        let from = Utc.with_ymd_and_hms(2026, 10, 1, 0, 0, 0).unwrap();
        let to = Utc.with_ymd_and_hms(2026, 11, 1, 0, 0, 0).unwrap() - Duration::milliseconds(1);

        let bulan_ini = stock_report_parse("laporan stok bulan ini", now).unwrap();
        assert_eq!(bulan_ini.query_id, "tx.stock_movement");
        assert_eq!(bulan_ini.time_from_ms, from.timestamp_millis());
        assert_eq!(bulan_ini.time_to_ms, to.timestamp_millis());

        let this_month = stock_report_parse("stock movement this month", now).unwrap();
        assert_eq!(this_month.time_from_ms, from.timestamp_millis());
        assert_eq!(this_month.time_to_ms, to.timestamp_millis());

        let no_date = stock_report_parse("mutasi", now).unwrap();
        assert_eq!(no_date.query_id, "tx.stock_movement");
        assert_eq!(no_date.time_from_ms, from.timestamp_millis());
        assert_eq!(no_date.time_to_ms, to.timestamp_millis());
    }

    #[test]
    fn januari_2025_parses() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 12, 0, 0).unwrap();
        let from = Utc.with_ymd_and_hms(2025, 1, 1, 0, 0, 0).unwrap();
        let to = Utc.with_ymd_and_hms(2025, 2, 1, 0, 0, 0).unwrap() - Duration::milliseconds(1);

        let id = stock_report_parse("kartu stok indomie januari 2025", now).unwrap();
        assert_eq!(id.query_id, "tx.stock_card");
        assert_eq!(id.q, "indomie");
        assert_eq!(id.time_from_ms, from.timestamp_millis());
        assert_eq!(id.time_to_ms, to.timestamp_millis());

        let en = stock_report_parse("stock card indomie january 2025", now).unwrap();
        assert_eq!(en.q, "indomie");
        assert_eq!(en.time_from_ms, from.timestamp_millis());
        assert_eq!(en.time_to_ms, to.timestamp_millis());
    }

    #[test]
    fn presentasi_parses() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 0, 0, 0).unwrap();
        let intent = stock_report_parse("laporan stok presentasi", now).unwrap();
        assert_eq!(intent.query_id, "tx.stock_movement");
        assert!(intent.formats.contains(&StockReportFormat::Slides));
        assert!(intent.formats.contains(&StockReportFormat::Table));

        let slide = stock_report_parse("mutasi slide", now).unwrap();
        assert!(slide.formats.contains(&StockReportFormat::Slides));
        let presentation = stock_report_parse("stock movement presentation", now).unwrap();
        assert!(presentation.formats.contains(&StockReportFormat::Slides));
    }

    #[test]
    fn list_ignores_window() {
        let now = Utc.with_ymd_and_hms(2026, 10, 8, 12, 0, 0).unwrap();
        let intent = stock_report_parse("daftar stok dari januari pdf", now).unwrap();
        assert_eq!(intent.query_id, "tx.stock_list");
        assert_eq!((intent.time_from_ms, intent.time_to_ms), (0, 0));
        assert!(intent.formats.contains(&StockReportFormat::Pdf));
        assert!(intent.formats.contains(&StockReportFormat::Table));
    }
}
