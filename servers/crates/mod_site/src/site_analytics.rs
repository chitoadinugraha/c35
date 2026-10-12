//! Guest visitor analytics ingest (rollup-on-write). CSA `/api/analytics/ping` parity.

use anyhow::{bail, Result};
use chrono::{DateTime, NaiveDate, Utc};
use serde::Deserialize;
use sqlx::{PgPool, Row};
use sqlx::postgres::PgTransaction;

use crate::site_config::{site_capabilities_get, site_capability_enabled};
use crate::site_publish::{resolve_site_by_alien_id, site_published};

const MAX_ACTIVE_MS_PER_PING: i64 = 30 * 60 * 1000;
const REFERRER_MAX: usize = 512;
const UA_MAX: usize = 512;

#[derive(Debug, Clone, Deserialize)]
pub struct SiteAnalyticsPing {
    pub alien_id: String,
    pub session_id: String,
    pub path: String,
    pub visitor_id: String,
    pub referrer: Option<String>,
    pub active_duration_ms: i64,
    pub user_agent: Option<String>,
}

pub fn visitor_key_hash(visitor_id: &str) -> Result<String> {
    let v = visitor_id.trim();
    if v.is_empty() {
        bail!("visitor_id required");
    }
    Ok(blake3::hash(v.as_bytes()).to_hex().to_string())
}

pub fn session_key_hash(session_id: &str) -> String {
    let s = session_id.trim();
    if s.is_empty() {
        return String::new();
    }
    blake3::hash(s.as_bytes()).to_hex().to_string()
}

pub fn normalize_analytics_path(path: &str) -> String {
    let mut s = path.trim();
    if s.is_empty() {
        return "/".to_string();
    }
    if let Some(rest) = s.strip_prefix('#') {
        s = rest.trim_start_matches('/');
        if s.is_empty() {
            return "/".to_string();
        }
    }
    let out = if s.starts_with('/') {
        s.to_string()
    } else {
        format!("/{s}")
    };
    if out.len() > 256 {
        out.chars().take(256).collect()
    } else {
        out
    }
}

fn truncate_field(s: &str, max: usize) -> String {
    if s.len() <= max {
        return s.to_string();
    }
    s.chars().take(max).collect()
}

fn referrer_host(referrer: Option<&str>) -> String {
    let r = referrer.unwrap_or("").trim();
    if r.is_empty() {
        return String::new();
    }
    let rest = r
        .strip_prefix("https://")
        .or_else(|| r.strip_prefix("http://"))
        .unwrap_or("");
    if rest.is_empty() {
        return String::new();
    }
    rest.split('/')
        .next()
        .unwrap_or("")
        .split(':')
        .next()
        .unwrap_or("")
        .to_string()
}

pub async fn site_analytics_enabled(pool: &PgPool, site_iid: i64) -> bool {
    let caps = site_capabilities_get(pool, site_iid).await;
    site_capability_enabled(&caps, "analytics")
}

async fn site_tz(pool: &PgPool, site_iid: i64) -> String {
    let row = sqlx::query(
        r#"
        SELECT COALESCE(NULLIF(trim(tz), ''), 'Asia/Jakarta') AS tz
        FROM site.config
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.and_then(|r| r.try_get::<String, _>("tz").ok())
        .unwrap_or_else(|| "Asia/Jakarta".to_string())
}

pub async fn site_analytics_day_bucket(
    pool: &PgPool,
    site_iid: i64,
    at: DateTime<Utc>,
) -> Result<(NaiveDate, String)> {
    let tz = site_tz(pool, site_iid).await;
    let day: NaiveDate = sqlx::query_scalar(r#"SELECT ($1::timestamptz AT TIME ZONE $2)::date"#)
        .bind(at)
        .bind(&tz)
        .fetch_one(pool)
        .await?;
    Ok((day, tz))
}

async fn visitor_slot_index(pool: &PgPool, tz: &str, at: DateTime<Utc>) -> Result<i32> {
    let slot: i32 = sqlx::query_scalar(
        r#"
        SELECT LEAST(11, GREATEST(0, FLOOR(EXTRACT(HOUR FROM ($1::timestamptz AT TIME ZONE $2)) / 2)::int))
        "#,
    )
    .bind(at)
    .bind(tz)
    .fetch_one(pool)
    .await?;
    Ok(slot)
}

fn slots_parse(raw: &serde_json::Value) -> [i64; 12] {
    let mut out = [0i64; 12];
    if let Some(arr) = raw.as_array() {
        for (i, v) in arr.iter().take(12).enumerate() {
            out[i] = v.as_i64().unwrap_or(0).max(0);
        }
    }
    out
}

fn slots_to_json(slots: &[i64; 12]) -> serde_json::Value {
    serde_json::Value::Array(slots.iter().map(|n| serde_json::json!(n)).collect())
}

async fn bump_day_slots(
    tx: &mut PgTransaction<'_>,
    site_iid: i64,
    day: NaiveDate,
    is_new_visitor: bool,
    old_slot: Option<i32>,
    new_slot: i32,
    page_views_inc: i64,
    duration_inc: i64,
    unique_inc: i64,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO site.analytics_day (site_iid, day_bucket, page_views, unique_visitors, active_duration_ms, visitor_slots)
        VALUES ($1, $2, 0, 0, 0, '[]'::jsonb)
        ON CONFLICT (site_iid, day_bucket) DO NOTHING
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .execute(&mut **tx)
    .await?;

    let row = sqlx::query(
        r#"
        SELECT visitor_slots FROM site.analytics_day
        WHERE site_iid = $1 AND day_bucket = $2
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .fetch_one(&mut **tx)
    .await?;
    let slots_raw: serde_json::Value = row.get("visitor_slots");
    let mut slots = slots_parse(&slots_raw);
    let ns = new_slot.clamp(0, 11) as usize;
    if is_new_visitor {
        slots[ns] += 1;
    } else if let Some(os) = old_slot {
        let o = os.clamp(0, 11) as usize;
        if o != ns {
            slots[o] = (slots[o] - 1).max(0);
            slots[ns] += 1;
        }
    }

    sqlx::query(
        r#"
        UPDATE site.analytics_day
        SET page_views = page_views + $3,
            unique_visitors = unique_visitors + $4,
            active_duration_ms = active_duration_ms + $5,
            visitor_slots = $6,
            updated_ts = NOW()
        WHERE site_iid = $1 AND day_bucket = $2
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .bind(page_views_inc)
    .bind(unique_inc)
    .bind(duration_inc)
    .bind(slots_to_json(&slots))
    .execute(&mut **tx)
    .await?;
    Ok(())
}

pub async fn site_analytics_ping(
    pool: &PgPool,
    req: SiteAnalyticsPing,
    _client_ip: &str,
) -> Result<()> {
    let alien_id = req.alien_id.trim();
    if alien_id.is_empty() {
        bail!("alien_id required");
    }
    let site_iid = resolve_site_by_alien_id(pool, alien_id).await?;
    if !site_published(pool, site_iid).await? {
        bail!("site not published");
    }
    if !site_analytics_enabled(pool, site_iid).await {
        return Ok(());
    }

    let visitor_key = visitor_key_hash(&req.visitor_id)?;
    let session_key = session_key_hash(&req.session_id);
    let path = normalize_analytics_path(&req.path);
    let duration = req.active_duration_ms.clamp(0, MAX_ACTIVE_MS_PER_PING);
    let ref_host = truncate_field(&referrer_host(req.referrer.as_deref()), REFERRER_MAX);
    let _ua = truncate_field(req.user_agent.as_deref().unwrap_or(""), UA_MAX);
    let now = Utc::now();
    let (day, tz) = site_analytics_day_bucket(pool, site_iid, now).await?;
    let new_slot = visitor_slot_index(pool, &tz, now).await?;

    let mut tx = pool.begin().await?;

    let prev = sqlx::query(
        r#"
        SELECT last_seen_ts FROM site.analytics_visitor_day
        WHERE site_iid = $1 AND day_bucket = $2 AND visitor_key = $3
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .bind(&visitor_key)
    .fetch_optional(&mut *tx)
    .await?;

    let is_new = prev.is_none();
    let old_slot = if let Some(r) = prev {
        let ts: DateTime<Utc> = r.get("last_seen_ts");
        Some(visitor_slot_index(pool, &tz, ts).await?)
    } else {
        None
    };

    sqlx::query(
        r#"
        INSERT INTO site.analytics_visitor_day (
            site_iid, day_bucket, visitor_key, session_key,
            page_views, active_duration_ms, last_path, last_seen_ts, referrer_host
        )
        VALUES ($1, $2, $3, $4, 1, $5, $6, NOW(), $7)
        ON CONFLICT (site_iid, day_bucket, visitor_key) DO UPDATE SET
            session_key = EXCLUDED.session_key,
            page_views = site.analytics_visitor_day.page_views + 1,
            active_duration_ms = site.analytics_visitor_day.active_duration_ms + EXCLUDED.active_duration_ms,
            last_path = EXCLUDED.last_path,
            last_seen_ts = NOW(),
            referrer_host = CASE
                WHEN EXCLUDED.referrer_host <> '' THEN EXCLUDED.referrer_host
                ELSE site.analytics_visitor_day.referrer_host
            END,
            updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .bind(&visitor_key)
    .bind(&session_key)
    .bind(duration)
    .bind(&path)
    .bind(&ref_host)
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        r#"
        INSERT INTO site.analytics_path_day (site_iid, day_bucket, path, views)
        VALUES ($1, $2, $3, 1)
        ON CONFLICT (site_iid, day_bucket, path) DO UPDATE SET
            views = site.analytics_path_day.views + 1,
            updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .bind(&path)
    .execute(&mut *tx)
    .await?;

    bump_day_slots(
        &mut tx,
        site_iid,
        day,
        is_new,
        old_slot,
        new_slot,
        1,
        duration,
        if is_new { 1 } else { 0 },
    )
    .await?;

    tx.commit().await?;
    Ok(())
}

pub async fn site_analytics_link_click(
    pool: &PgPool,
    alien_id: &str,
    link_id: i64,
    visitor_id: &str,
) -> Result<()> {
    let alien_id = alien_id.trim();
    if alien_id.is_empty() {
        bail!("alien_id required");
    }
    if link_id <= 0 {
        bail!("link_id required");
    }
    let _ = visitor_key_hash(visitor_id)?;

    let site_iid = resolve_site_by_alien_id(pool, alien_id).await?;
    if !site_published(pool, site_iid).await? {
        bail!("site not published");
    }
    if !site_analytics_enabled(pool, site_iid).await {
        return Ok(());
    }

    let exists = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT 1 FROM site.link
        WHERE site_iid = $1 AND link_id = $2 AND deleted_ts IS NULL AND active = TRUE
        "#,
    )
    .bind(site_iid)
    .bind(link_id)
    .fetch_optional(pool)
    .await?;
    if exists.is_none() {
        bail!("link not found");
    }

    let now = Utc::now();
    let (day, _) = site_analytics_day_bucket(pool, site_iid, now).await?;

    sqlx::query(
        r#"
        INSERT INTO site.analytics_link_day (site_iid, day_bucket, link_id, clicks)
        VALUES ($1, $2, $3, 1)
        ON CONFLICT (site_iid, day_bucket, link_id) DO UPDATE SET
            clicks = site.analytics_link_day.clicks + 1,
            updated_ts = NOW()
        "#,
    )
    .bind(site_iid)
    .bind(day)
    .bind(link_id)
    .execute(pool)
    .await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn visitor_key_stable() {
        let a = visitor_key_hash("abc").unwrap();
        let b = visitor_key_hash("abc").unwrap();
        assert_eq!(a, b);
        assert_eq!(a.len(), 64);
    }

    #[test]
    fn normalize_path_defaults() {
        assert_eq!(normalize_analytics_path(""), "/");
        assert_eq!(normalize_analytics_path("about"), "/about");
        assert_eq!(normalize_analytics_path("/x"), "/x");
    }
}
