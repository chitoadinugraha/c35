//! Owner-scoped lookup of past chats. Summaries stay on `chat.search`; exact lines on `chat.messages`.
//! Timestamps are formatted in the user's timezone. Rows stay UTC.

use chrono::{DateTime, NaiveDate, TimeZone, Utc};
use chrono_tz::Tz;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::prompt::time::time_timezone_resolve;

const SEARCH_LIMIT_DEFAULT: i64 = 5;
const SEARCH_LIMIT_MAX: i64 = 8;
const MESSAGE_LIMIT_DEFAULT: i64 = 12;
const MESSAGE_LIMIT_MAX: i64 = 20;
const SNIPPET_CHARS: usize = 400;
const MESSAGE_CHARS: usize = 1200;
const FALLBACK_MESSAGES: i64 = 4;

const STOPWORDS: &[&str] = &[
    "when", "did", "do", "does", "what", "which", "where", "who", "how", "i", "you", "we", "our", "me", "my",
    "to", "the", "a", "an", "ask", "asked", "say", "said", "tell", "told", "about", "based", "on", "of", "for",
    "conversation", "chat", "remember", "yesterday", "today", "exact", "words", "word", "quote", "please",
    "kapan", "saya", "aku", "kamu", "kita", "yang", "untuk", "minta", "bilang", "tanya", "ingat", "percakapan",
    "obrolan", "tentang", "kemarin", "hari", "ini", "itu", "dari", "dengan", "apa", "apakah", "tolong", "dong",
    "ya", "kan", "our", "based",
];

pub struct ChatHistoryQuery {
    pub owner_iid: i64,
    pub current_chat_id: i64,
    pub query: String,
    pub since: String,
    pub until: String,
    pub chat_id: i64,
    pub limit: i64,
    pub locale: String,
    pub user_text: String,
}

pub fn chat_like_escape(s: &str) -> String {
    s.replace(['\\', '%', '_'], "")
}

pub fn chat_text_clip(s: &str, max: usize) -> String {
    let s = s.trim();
    let count = s.chars().count();
    if count <= max {
        return s.to_string();
    }
    let clipped: String = s.chars().take(max).collect();
    format!("{clipped}…")
}

fn is_stopword(token: &str) -> bool {
    STOPWORDS.iter().any(|w| w.eq_ignore_ascii_case(token))
}

pub fn chat_query_tokens(query: &str) -> Vec<String> {
    let raw: Vec<String> = query
        .split_whitespace()
        .map(|t| t.trim_matches(|c: char| !c.is_alphanumeric()).to_string())
        .filter(|t| t.chars().count() >= 2)
        .collect();
    let kept: Vec<String> = raw.iter().filter(|t| !is_stopword(t)).cloned().collect();
    let tokens = if kept.is_empty() { raw } else { kept };
    tokens.into_iter().map(|t| format!("%{}%", chat_like_escape(&t))).collect()
}

pub fn chat_time_label(ts: DateTime<Utc>, tz_name: &str) -> String {
    let tz_name = tz_name.trim();
    if let Ok(tz) = tz_name.parse::<Tz>() {
        return ts.with_timezone(&tz).format("%A, %d %B %Y, %H:%M %Z").to_string();
    }
    ts.format("%A, %d %B %Y, %H:%M UTC").to_string()
}

fn parse_local_day(raw: &str) -> Result<NaiveDate, String> {
    let raw = raw.trim();
    if raw.is_empty() {
        return Err("empty".into());
    }
    NaiveDate::parse_from_str(raw, "%Y-%m-%d").map_err(|_| format!("date must be YYYY-MM-DD, got {raw}"))
}

fn day_start_utc(tz: Tz, day: NaiveDate) -> Result<DateTime<Utc>, String> {
    tz.from_local_datetime(&day.and_hms_opt(0, 0, 0).ok_or("bad day")?)
        .single()
        .map(|local| local.with_timezone(&Utc))
        .ok_or_else(|| format!("cannot place {day} in timezone"))
}

pub fn chat_local_range(tz_name: &str, since: &str, until: &str) -> Result<(Option<DateTime<Utc>>, Option<DateTime<Utc>>), String> {
    let tz: Tz = tz_name.parse().unwrap_or(chrono_tz::UTC);
    let start = if since.trim().is_empty() {
        None
    } else {
        Some(day_start_utc(tz, parse_local_day(since)?)?)
    };
    let end = if until.trim().is_empty() {
        None
    } else {
        let day = parse_local_day(until)?;
        let next = day.succ_opt().ok_or("date overflow")?;
        Some(day_start_utc(tz, next)?)
    };
    Ok((start, end))
}

async fn owner_tz(pool: &PgPool, owner_iid: i64, locale: &str, user_text: &str) -> String {
    let row = sqlx::query("SELECT COALESCE(tz, '') AS tz, COALESCE(locale, '') AS locale FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(owner_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
    let (tz, loc) = row
        .map(|r| {
            (
                r.try_get::<String, _>("tz").unwrap_or_default(),
                r.try_get::<String, _>("locale").unwrap_or_default(),
            )
        })
        .unwrap_or_default();
    let locale = if locale.trim().is_empty() { loc } else { locale.to_string() };
    time_timezone_resolve(&tz, &locale, user_text)
}

fn msg_json(id: i64, role: &str, content: &str, ts: DateTime<Utc>, tz_name: &str, max: usize) -> Value {
    json!({
        "id": id.to_string(),
        "role": role,
        "time": chat_time_label(ts, tz_name),
        "text": chat_text_clip(content, max),
    })
}

async fn recent_messages(pool: &PgPool, owner_iid: i64, chat_id: i64, tz_name: &str) -> Vec<Value> {
    let rows = sqlx::query(
        r#"
        SELECT id, role, content, created_ts
        FROM ai.chat_msg
        WHERE chat_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        ORDER BY created_ts DESC
        LIMIT $3
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .bind(FALLBACK_MESSAGES)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.into_iter()
        .rev()
        .filter_map(|r| {
            let ts: DateTime<Utc> = r.try_get("created_ts").ok()?;
            let id: i64 = r.try_get("id").ok()?;
            let role: String = r.try_get("role").unwrap_or_default();
            let content: String = r.try_get("content").unwrap_or_default();
            Some(msg_json(id, &role, &content, ts, tz_name, SNIPPET_CHARS))
        })
        .collect()
}

pub async fn chat_search(pool: &PgPool, q: &ChatHistoryQuery) -> Result<Value, String> {
    let tz_name = owner_tz(pool, q.owner_iid, &q.locale, &q.user_text).await;
    let (since, until) = chat_local_range(&tz_name, &q.since, &q.until)?;
    let patterns = chat_query_tokens(&q.query);
    let limit = if q.limit <= 0 { SEARCH_LIMIT_DEFAULT } else { q.limit.clamp(1, SEARCH_LIMIT_MAX) };
    let rows = sqlx::query(
        r#"
        SELECT c.id, c.title, COALESCE(c.context_summary, '') AS context_summary, c.last_msg_ts,
               s.id AS snippet_id, s.role AS snippet_role, s.content AS snippet_content, s.created_ts AS snippet_ts
        FROM ai.chat c
        LEFT JOIN LATERAL (
            SELECT m.id, m.role, m.content, m.created_ts
            FROM ai.chat_msg m
            WHERE m.chat_id = c.id AND m.owner_iid = $1 AND m.deleted_ts IS NULL
              AND (CARDINALITY($2::text[]) = 0 OR m.content ILIKE ALL($2))
              AND ($3::timestamptz IS NULL OR m.created_ts >= $3)
              AND ($4::timestamptz IS NULL OR m.created_ts < $4)
            ORDER BY CASE WHEN m.role = 'user' THEN 0 ELSE 1 END, m.created_ts DESC
            LIMIT 1
        ) s ON TRUE
        WHERE c.owner_iid = $1 AND c.deleted_ts IS NULL
          AND (
            CARDINALITY($2::text[]) = 0
            OR c.title ILIKE ALL($2)
            OR COALESCE(c.context_summary, '') ILIKE ALL($2)
            OR s.content IS NOT NULL
          )
          AND (
            $3::timestamptz IS NULL AND $4::timestamptz IS NULL
            OR c.last_msg_ts >= COALESCE($3, '-infinity'::timestamptz) AND c.last_msg_ts < COALESCE($4, 'infinity'::timestamptz)
            OR s.created_ts IS NOT NULL
          )
        ORDER BY COALESCE(s.created_ts, c.last_msg_ts) DESC
        LIMIT $5
        "#,
    )
    .bind(q.owner_iid)
    .bind(&patterns)
    .bind(since)
    .bind(until)
    .bind(limit)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;

    let mut chats = Vec::new();
    for r in rows {
        let id: i64 = r.try_get("id").map_err(|e| e.to_string())?;
        let title: String = r.try_get("title").unwrap_or_else(|_| "Chat".into());
        let summary: String = r.try_get("context_summary").unwrap_or_default();
        let last_ts: DateTime<Utc> = r.try_get("last_msg_ts").map_err(|e| e.to_string())?;
        let mut item = json!({
            "chat_id": id.to_string(),
            "title": title,
            "time": chat_time_label(last_ts, &tz_name),
            "current": id == q.current_chat_id,
            "summary": chat_text_clip(&summary, MESSAGE_CHARS),
        });
        if let (Ok(sid), Ok(role), Ok(content), Ok(ts)) = (
            r.try_get::<i64, _>("snippet_id"),
            r.try_get::<String, _>("snippet_role"),
            r.try_get::<String, _>("snippet_content"),
            r.try_get::<DateTime<Utc>, _>("snippet_ts"),
        ) {
            if sid != 0 && !content.trim().is_empty() {
                item["snippet"] = msg_json(sid, &role, &content, ts, &tz_name, SNIPPET_CHARS);
            }
        }
        if summary.trim().is_empty() {
            item["messages"] = json!(recent_messages(pool, q.owner_iid, id, &tz_name).await);
        }
        chats.push(item);
    }
    Ok(json!({
        "ok": true,
        "tz": tz_name,
        "count": chats.len(),
        "chats": chats,
    }))
}

pub async fn chat_messages(pool: &PgPool, q: &ChatHistoryQuery) -> Result<Value, String> {
    let chat_id = if q.chat_id > 0 { q.chat_id } else { q.current_chat_id };
    if chat_id <= 0 {
        return Ok(json!({ "ok": false, "error": "chat_id required" }));
    }
    let tz_name = owner_tz(pool, q.owner_iid, &q.locale, &q.user_text).await;
    let (since, until) = chat_local_range(&tz_name, &q.since, &q.until)?;
    let title: Option<String> = sqlx::query_scalar(
        "SELECT title FROM ai.chat WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(chat_id)
    .bind(q.owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(title) = title else {
        return Ok(json!({ "ok": false, "error": "chat not found" }));
    };
    let patterns = chat_query_tokens(&q.query);
    let limit = if q.limit <= 0 { MESSAGE_LIMIT_DEFAULT } else { q.limit.clamp(1, MESSAGE_LIMIT_MAX) };
    let newest_first = patterns.is_empty() && since.is_none() && until.is_none();
    let rows = if newest_first {
        sqlx::query(
            r#"
            SELECT id, role, content, created_ts
            FROM ai.chat_msg
            WHERE chat_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
            ORDER BY created_ts DESC
            LIMIT $3
            "#,
        )
        .bind(chat_id)
        .bind(q.owner_iid)
        .bind(limit)
        .fetch_all(pool)
        .await
        .map_err(|e| e.to_string())?
    } else {
        sqlx::query(
            r#"
            SELECT id, role, content, created_ts
            FROM ai.chat_msg
            WHERE chat_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
              AND (CARDINALITY($3::text[]) = 0 OR content ILIKE ALL($3))
              AND ($4::timestamptz IS NULL OR created_ts >= $4)
              AND ($5::timestamptz IS NULL OR created_ts < $5)
            ORDER BY created_ts ASC
            LIMIT $6
            "#,
        )
        .bind(chat_id)
        .bind(q.owner_iid)
        .bind(&patterns)
        .bind(since)
        .bind(until)
        .bind(limit)
        .fetch_all(pool)
        .await
        .map_err(|e| e.to_string())?
    };
    let mut messages: Vec<Value> = rows
        .into_iter()
        .filter_map(|r| {
            let ts: DateTime<Utc> = r.try_get("created_ts").ok()?;
            let id: i64 = r.try_get("id").ok()?;
            let role: String = r.try_get("role").unwrap_or_default();
            let content: String = r.try_get("content").unwrap_or_default();
            Some(msg_json(id, &role, &content, ts, &tz_name, MESSAGE_CHARS))
        })
        .collect();
    if newest_first {
        messages.reverse();
    }
    Ok(json!({
        "ok": true,
        "tz": tz_name,
        "chat_id": chat_id.to_string(),
        "title": title,
        "count": messages.len(),
        "messages": messages,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    #[test]
    fn jakarta_label_is_local_afternoon() {
        let ts = Utc.with_ymd_and_hms(2026, 10, 3, 8, 0, 0).unwrap();
        let label = chat_time_label(ts, "Asia/Jakarta");
        assert!(label.contains("15:00"), "{label}");
        assert!(label.contains("03 October 2026"), "{label}");
        assert!(label.contains("WIB"), "{label}");
    }

    #[test]
    fn question_words_drop_out_of_search_tokens() {
        let tokens = chat_query_tokens("when did I ask you to remove product A");
        assert!(tokens.iter().any(|t| t.to_ascii_lowercase().contains("remove")), "{tokens:?}");
        assert!(tokens.iter().any(|t| t.to_ascii_lowercase().contains("product")), "{tokens:?}");
        assert!(!tokens.iter().any(|t| t.to_ascii_lowercase().contains("when")), "{tokens:?}");
    }

    #[test]
    fn local_range_until_is_inclusive_day() {
        let (start, end) = chat_local_range("Asia/Jakarta", "2026-10-03", "2026-10-03").unwrap();
        let start = start.unwrap();
        let end = end.unwrap();
        assert_eq!(start, Utc.with_ymd_and_hms(2026, 10, 2, 17, 0, 0).unwrap());
        assert_eq!(end, Utc.with_ymd_and_hms(2026, 10, 3, 17, 0, 0).unwrap());
    }

    #[test]
    fn bad_date_is_rejected() {
        assert!(chat_local_range("Asia/Jakarta", "yesterday", "").is_err());
    }
}
