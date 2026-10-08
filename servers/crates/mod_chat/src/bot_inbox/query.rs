use std::collections::HashMap;

use anyhow::{anyhow, bail, Result};
use chrono::{DateTime, Duration, NaiveDate, TimeZone, Utc};
use chrono_tz::Tz;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::bot_peer::{bot_access_verify, BOT_APP_CHANNEL_ID};

use super::channel_platform::{
    bot_channel_platform_map, channel_id_platform, platform_display_label,
};

#[derive(Debug, Clone)]
struct ChannelCount {
    platform: String,
    label: String,
    count: i64,
}

fn tz_resolve(params: &Value) -> Tz {
    params
        .get("tz")
        .and_then(|v| v.as_str())
        .and_then(|s| s.parse().ok())
        .unwrap_or_else(|| "Asia/Jakarta".parse().expect("Asia/Jakarta"))
}

fn day_bounds_utc(tz: Tz, day: NaiveDate) -> (DateTime<Utc>, DateTime<Utc>) {
    let start_local = tz
        .from_local_datetime(&day.and_hms_opt(0, 0, 0).unwrap())
        .single();
    let end_local = tz
        .from_local_datetime(&(day + Duration::days(1)).and_hms_opt(0, 0, 0).unwrap())
        .single();
    match (start_local, end_local) {
        (Some(s), Some(e)) => (s.with_timezone(&Utc), e.with_timezone(&Utc)),
        _ => {
            let s = Utc.from_utc_datetime(&day.and_hms_opt(0, 0, 0).unwrap());
            let e = Utc.from_utc_datetime(&(day + Duration::days(1)).and_hms_opt(0, 0, 0).unwrap());
            (s, e)
        }
    }
}

fn exclude_app(params: &Value) -> bool {
    params
        .get("exclude_app")
        .and_then(|v| v.as_bool())
        .unwrap_or(true)
}

fn aggregate_by_platform(
    rows: Vec<(String, i64)>,
    platform_map: &HashMap<String, String>,
) -> (Vec<ChannelCount>, i64) {
    let mut by_platform: HashMap<String, i64> = HashMap::new();
    for (channel_id, count) in rows {
        let platform = channel_id_platform(&channel_id, platform_map);
        *by_platform.entry(platform).or_insert(0) += count;
    }
    let mut channels: Vec<ChannelCount> = by_platform
        .into_iter()
        .map(|(platform, count)| {
            let label = platform_display_label(&platform).to_string();
            ChannelCount {
                platform,
                label,
                count,
            }
        })
        .collect();
    channels.sort_by(|a, b| {
        b.count
            .cmp(&a.count)
            .then_with(|| a.platform.cmp(&b.platform))
    });
    let total = channels.iter().map(|c| c.count).sum();
    (channels, total)
}

pub async fn bot_inbox_query_run(
    pool: &PgPool,
    caller_iid: i64,
    bot_iid: i64,
    query_id: &str,
    params_json: &str,
) -> Result<Value> {
    bot_access_verify(pool, caller_iid, bot_iid).await?;
    let params: Value = if params_json.trim().is_empty() {
        json!({})
    } else {
        serde_json::from_str(params_json)?
    };
    match query_id {
        "stats_today" => stats_today(pool, bot_iid, &params).await,
        "stats_daily_avg" => stats_daily_avg(pool, bot_iid, &params).await,
        "top_questions" => top_questions(pool, bot_iid, &params).await,
        "peer_messages" => peer_messages(pool, bot_iid, &params).await,
        other => bail!("unknown bot.inbox query_id: {other}"),
    }
}

async fn stats_today(pool: &PgPool, bot_iid: i64, params: &Value) -> Result<Value> {
    let tz = tz_resolve(params);
    let today = Utc::now().with_timezone(&tz).date_naive();
    let (start, end) = day_bounds_utc(tz, today);
    let exclude = exclude_app(params);
    let rows = sqlx::query(
        r#"
        SELECT c.channel_id, COUNT(*)::bigint AS cnt
        FROM ai.chat_msg m
        JOIN ai.chat c ON c.id = m.chat_id
        WHERE c.kind = 'bot_peer'
          AND c.bot_iid = $1
          AND c.deleted_ts IS NULL
          AND m.deleted_ts IS NULL
          AND m.role = 'user'
          AND m.source = 'external'
          AND m.created_ts >= $2
          AND m.created_ts < $3
          AND ($4::bool IS FALSE OR c.channel_id <> $5)
        GROUP BY c.channel_id
        "#,
    )
    .bind(bot_iid)
    .bind(start)
    .bind(end)
    .bind(exclude)
    .bind(BOT_APP_CHANNEL_ID)
    .fetch_all(pool)
    .await?;
    let raw: Vec<(String, i64)> = rows
        .iter()
        .map(|r| (r.get::<String, _>("channel_id"), r.get::<i64, _>("cnt")))
        .collect();
    let platform_map = bot_channel_platform_map(pool, bot_iid).await?;
    let (channels, total) = aggregate_by_platform(raw, &platform_map);
    Ok(json!({
        "ok": true,
        "query_id": "stats_today",
        "day": today.to_string(),
        "tz": tz.to_string(),
        "metric": "user_messages",
        "exclude_app": exclude,
        "channels": channels.iter().map(|c| json!({
            "platform": c.platform,
            "label": c.label,
            "count": c.count,
        })).collect::<Vec<_>>(),
        "total": total,
        "show_total": channels.len() > 1,
    }))
}

async fn stats_daily_avg(pool: &PgPool, bot_iid: i64, params: &Value) -> Result<Value> {
    let days = params
        .get("days")
        .and_then(|v| v.as_i64())
        .unwrap_or(30)
        .clamp(1, 365) as i32;
    let exclude = exclude_app(params);
    let until = Utc::now().date_naive();
    let since = until - Duration::days(days as i64);
    let rows = sqlx::query(
        r#"
        SELECT day, SUM(user_msg_count)::bigint AS total
        FROM ai.bot_inbox_day
        WHERE bot_iid = $1
          AND day >= $2
          AND day < $3
          AND ($4::bool IS FALSE OR channel_id <> $5)
        GROUP BY day
        ORDER BY day ASC
        "#,
    )
    .bind(bot_iid)
    .bind(since)
    .bind(until)
    .bind(exclude)
    .bind(BOT_APP_CHANNEL_ID)
    .fetch_all(pool)
    .await?;
    let daily: Vec<i64> = rows.iter().map(|r| r.get::<i64, _>("total")).collect();
    let days_with_data = daily.len();
    let sum: i64 = daily.iter().sum();
    let avg = if days_with_data > 0 {
        (sum as f64) / (days_with_data as f64)
    } else {
        0.0
    };
    Ok(json!({
        "ok": true,
        "query_id": "stats_daily_avg",
        "days_window": days,
        "since": since.to_string(),
        "until": until.to_string(),
        "exclude_app": exclude,
        "metric": "user_messages",
        "days_with_data": days_with_data,
        "total_messages": sum,
        "avg_messages_per_day": avg,
    }))
}

async fn top_questions(pool: &PgPool, bot_iid: i64, params: &Value) -> Result<Value> {
    let days = params
        .get("days")
        .and_then(|v| v.as_i64())
        .unwrap_or(30)
        .clamp(1, 365) as i32;
    let limit = params
        .get("limit")
        .and_then(|v| v.as_i64())
        .unwrap_or(20)
        .clamp(1, 50) as i64;
    let exclude = exclude_app(params);
    let until = Utc::now().date_naive();
    let since = until - Duration::days(days as i64);
    let rows = sqlx::query(
        r#"
        SELECT fingerprint, MAX(sample_text) AS sample_text, SUM(count)::bigint AS total
        FROM ai.bot_inbox_question
        WHERE bot_iid = $1
          AND day >= $2
          AND day <= $3
          AND ($4::bool IS FALSE OR channel_id <> $5)
        GROUP BY fingerprint
        ORDER BY total DESC, fingerprint ASC
        LIMIT $6
        "#,
    )
    .bind(bot_iid)
    .bind(since)
    .bind(until)
    .bind(exclude)
    .bind(BOT_APP_CHANNEL_ID)
    .bind(limit)
    .fetch_all(pool)
    .await?;
    let questions: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "count": r.get::<i64, _>("total"),
                "sample_text": r.get::<String, _>("sample_text"),
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "query_id": "top_questions",
        "since": since.to_string(),
        "until": until.to_string(),
        "exclude_app": exclude,
        "questions": questions,
    }))
}

async fn peer_messages(pool: &PgPool, bot_iid: i64, params: &Value) -> Result<Value> {
    let tz = tz_resolve(params);
    let day = params
        .get("day")
        .and_then(|v| v.as_str())
        .and_then(|s| NaiveDate::parse_from_str(s, "%Y-%m-%d").ok())
        .unwrap_or_else(|| Utc::now().with_timezone(&tz).date_naive());
    let (start, end) = day_bounds_utc(tz, day);
    let peer = params
        .get("peer")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty());
    let limit = params
        .get("limit")
        .and_then(|v| v.as_i64())
        .unwrap_or(50)
        .clamp(1, 100) as i64;
    let exclude = exclude_app(params);
    let rows = if peer.is_some() {
        let peer_pat = format!("%{}%", peer.unwrap().to_lowercase());
        sqlx::query(
            r#"
            SELECT m.id, m.created_ts, c.channel_id, c.peer_name, c.peer_key,
                   left(m.content, 400) AS preview
            FROM ai.chat_msg m
            JOIN ai.chat c ON c.id = m.chat_id
            WHERE c.kind = 'bot_peer'
              AND c.bot_iid = $1
              AND c.deleted_ts IS NULL
              AND m.deleted_ts IS NULL
              AND m.role = 'user'
              AND m.source = 'external'
              AND m.created_ts >= $2
              AND m.created_ts < $3
              AND ($4::bool IS FALSE OR c.channel_id <> $5)
              AND (
                lower(c.peer_name) LIKE $6
                OR lower(c.peer_key) LIKE $6
              )
            ORDER BY m.created_ts DESC, m.id DESC
            LIMIT $7
            "#,
        )
        .bind(bot_iid)
        .bind(start)
        .bind(end)
        .bind(exclude)
        .bind(BOT_APP_CHANNEL_ID)
        .bind(peer_pat)
        .bind(limit)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT m.id, m.created_ts, c.channel_id, c.peer_name, c.peer_key,
                   left(m.content, 400) AS preview
            FROM ai.chat_msg m
            JOIN ai.chat c ON c.id = m.chat_id
            WHERE c.kind = 'bot_peer'
              AND c.bot_iid = $1
              AND c.deleted_ts IS NULL
              AND m.deleted_ts IS NULL
              AND m.role = 'user'
              AND m.source = 'external'
              AND m.created_ts >= $2
              AND m.created_ts < $3
              AND ($4::bool IS FALSE OR c.channel_id <> $5)
            ORDER BY m.created_ts DESC, m.id DESC
            LIMIT $6
            "#,
        )
        .bind(bot_iid)
        .bind(start)
        .bind(end)
        .bind(exclude)
        .bind(BOT_APP_CHANNEL_ID)
        .bind(limit)
        .fetch_all(pool)
        .await?
    };
    let platform_map = bot_channel_platform_map(pool, bot_iid).await?;
    let messages: Vec<Value> = rows
        .iter()
        .map(|r| {
            let channel_id: String = r.get("channel_id");
            let platform = channel_id_platform(&channel_id, &platform_map);
            json!({
                "id": r.get::<i64, _>("id"),
                "created_ts": r.get::<DateTime<Utc>, _>("created_ts").to_rfc3339(),
                "peer_name": r.get::<String, _>("peer_name"),
                "peer_key": r.get::<String, _>("peer_key"),
                "platform": platform,
                "platform_label": platform_display_label(&platform),
                "preview": r.get::<String, _>("preview"),
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "query_id": "peer_messages",
        "day": day.to_string(),
        "tz": tz.to_string(),
        "peer": peer,
        "exclude_app": exclude,
        "messages": messages,
    }))
}

pub fn bot_iid_from_params(mention_bots: &[i64], params: &Value) -> Result<i64> {
    if let Some(iid) = params
        .get("bot_iid")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
    {
        return Ok(iid);
    }
    match mention_bots.len() {
        0 => Err(anyhow!("bot_iid is required — mention @bot")),
        1 => Ok(mention_bots[0]),
        _ => bail!("bot_iid is required — multiple bots mentioned"),
    }
}
