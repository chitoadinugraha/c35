use chrono::{DateTime, Datelike, NaiveDate, TimeZone, Utc};
use chrono_tz::Tz;
use c35_proto::{
    AdminUserReferrerBrief, AdminUserRegistrationRow, ReqAdminUserRegistrationsList,
    ResAdminUserRegistrationsList,
};
use sqlx::{PgPool, Row};

use crate::{require_referral_staff, AdminError};

const EMAIL_SUBQUERY: &str = r#"
COALESCE((
  SELECT p.identifier FROM ai.identity_provider p
  WHERE p.identity_iid = i.id AND p.kind IN ('password', 'google')
  ORDER BY p.is_primary DESC
  LIMIT 1
), COALESCE(i.meta->>'email', ''))
"#;

pub fn registration_window(
    tz_name: &str,
    preset: &str,
    since: &str,
    until: &str,
) -> Result<(DateTime<Utc>, DateTime<Utc>, String), AdminError> {
    let tz: Tz = tz_name.trim().parse().unwrap_or(chrono_tz::UTC);
    let tz_label = tz.name().to_string();

    let preset = preset.trim().to_lowercase();
    if !preset.is_empty() {
        let now = Utc::now().with_timezone(&tz);
        let today = now.date_naive();
        let (start_day, end_day) = match preset.as_str() {
            "today" => (today, today.succ_opt().ok_or_else(|| AdminError::bad("date overflow"))?),
            "yesterday" => {
                let y = today.pred_opt().ok_or_else(|| AdminError::bad("date overflow"))?;
                (y, today)
            }
            "this_week" => {
                let weekday = today.weekday().num_days_from_monday();
                let monday = today
                    .checked_sub_days(chrono::Days::new(weekday as u64))
                    .ok_or_else(|| AdminError::bad("date overflow"))?;
                let next_monday = monday
                    .checked_add_days(chrono::Days::new(7))
                    .ok_or_else(|| AdminError::bad("date overflow"))?;
                (monday, next_monday)
            }
            "last_week" => {
                let weekday = today.weekday().num_days_from_monday();
                let this_monday = today
                    .checked_sub_days(chrono::Days::new(weekday as u64))
                    .ok_or_else(|| AdminError::bad("date overflow"))?;
                let last_monday = this_monday
                    .checked_sub_days(chrono::Days::new(7))
                    .ok_or_else(|| AdminError::bad("date overflow"))?;
                (last_monday, this_monday)
            }
            "this_month" => {
                let first = NaiveDate::from_ymd_opt(today.year(), today.month(), 1)
                    .ok_or_else(|| AdminError::bad("bad month"))?;
                let next = if today.month() == 12 {
                    NaiveDate::from_ymd_opt(today.year() + 1, 1, 1)
                } else {
                    NaiveDate::from_ymd_opt(today.year(), today.month() + 1, 1)
                }
                .ok_or_else(|| AdminError::bad("bad month"))?;
                (first, next)
            }
            "last_month" => {
                let (y, m) = if today.month() == 1 {
                    (today.year() - 1, 12u32)
                } else {
                    (today.year(), today.month() - 1)
                };
                let first = NaiveDate::from_ymd_opt(y, m, 1).ok_or_else(|| AdminError::bad("bad month"))?;
                let this_first = NaiveDate::from_ymd_opt(today.year(), today.month(), 1)
                    .ok_or_else(|| AdminError::bad("bad month"))?;
                (first, this_first)
            }
            other => return Err(AdminError::bad(format!("unknown preset: {other}"))),
        };
        let start = day_start_utc(tz, start_day)?;
        let end = day_start_utc(tz, end_day)?;
        return Ok((start, end, tz_label));
    }

    if since.trim().is_empty() && until.trim().is_empty() {
        return Err(AdminError::bad("preset or since/until required"));
    }
    let start = if since.trim().is_empty() {
        DateTime::from_timestamp(0, 0).unwrap_or_else(Utc::now)
    } else {
        let day = parse_day(since)?;
        day_start_utc(tz, day)?
    };
    let end = if until.trim().is_empty() {
        Utc::now() + chrono::Duration::days(1)
    } else {
        let day = parse_day(until)?;
        let next = day.succ_opt().ok_or_else(|| AdminError::bad("date overflow"))?;
        day_start_utc(tz, next)?
    };
    if end <= start {
        return Err(AdminError::bad("until must be on or after since"));
    }
    Ok((start, end, tz_label))
}

fn parse_day(raw: &str) -> Result<NaiveDate, AdminError> {
    NaiveDate::parse_from_str(raw.trim(), "%Y-%m-%d")
        .map_err(|_| AdminError::bad(format!("date must be YYYY-MM-DD, got {}", raw.trim())))
}

fn day_start_utc(tz: Tz, day: NaiveDate) -> Result<DateTime<Utc>, AdminError> {
    let local = day
        .and_hms_opt(0, 0, 0)
        .ok_or_else(|| AdminError::bad("bad day"))?;
    tz.from_local_datetime(&local)
        .single()
        .map(|dt| dt.with_timezone(&Utc))
        .ok_or_else(|| AdminError::bad(format!("cannot place {day} in timezone")))
}

async fn viewer_timezone(pool: &PgPool, viewer_iid: i64, override_tz: &str) -> String {
    if !override_tz.trim().is_empty() {
        return override_tz.trim().to_string();
    }
    let row = sqlx::query("SELECT COALESCE(tz, '') AS tz FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
    row.and_then(|r| r.try_get::<String, _>("tz").ok())
        .filter(|t| !t.trim().is_empty())
        .unwrap_or_else(|| "Asia/Jakarta".to_string())
}

fn ts_ms(ts: DateTime<Utc>) -> i64 {
    ts.timestamp_millis()
}

fn row_referrer(ref_id: i64, ref_name: &str, ref_alien: &str) -> Option<AdminUserReferrerBrief> {
    if ref_id <= 0 {
        return None;
    }
    Some(AdminUserReferrerBrief {
        identity_id: ref_id,
        name: ref_name.to_string(),
        alien_id: ref_alien.to_string(),
    })
}

pub async fn admin_user_registrations_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminUserRegistrationsList,
) -> Result<ResAdminUserRegistrationsList, AdminError> {
    require_referral_staff(pool, viewer_iid).await?;

    let tz_name = viewer_timezone(pool, viewer_iid, &req.timezone).await;
    let (start, end, tz_used) =
        registration_window(&tz_name, &req.preset, &req.since, &req.until)?;
    let referred_by = req.referred_by_uid.max(0);
    let limit = req.limit.clamp(1, 100);
    let cursor_ts = req.after_registered_ts_ms;
    let cursor_id = req.after_identity_id;

    if req.count_only {
        let count: i64 = if referred_by > 0 {
            sqlx::query_scalar(
                r#"
                SELECT COUNT(*)::bigint FROM ai.identity i
                WHERE i.kind = 'user' AND i.deleted_ts IS NULL
                  AND i.created_ts >= $1 AND i.created_ts < $2
                  AND i.referred_by_iid = $3
                "#,
            )
            .bind(start)
            .bind(end)
            .bind(referred_by)
            .fetch_one(pool)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?
        } else {
            sqlx::query_scalar(
                r#"
                SELECT COUNT(*)::bigint FROM ai.identity i
                WHERE i.kind = 'user' AND i.deleted_ts IS NULL
                  AND i.created_ts >= $1 AND i.created_ts < $2
                "#,
            )
            .bind(start)
            .bind(end)
            .fetch_one(pool)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?
        };
        return Ok(ResAdminUserRegistrationsList {
            count,
            users: vec![],
            timezone_used: tz_used,
            window_start_ms: ts_ms(start),
            window_end_ms: ts_ms(end),
            has_more: false,
        });
    }

    let fetch_limit = (limit + 1) as i64;
    let list_sql = |extra_filter: &str| {
        format!(
            r#"
            SELECT i.id, i.name, COALESCE(i.alien_id, '') AS alien_id, i.created_ts,
                   COALESCE(i.referred_by_iid, 0) AS referred_by_iid,
                   COALESCE(r.name, '') AS ref_name, COALESCE(r.alien_id, '') AS ref_alien_id,
                   {EMAIL_SUBQUERY} AS email
            FROM ai.identity i
            LEFT JOIN ai.identity r ON r.id = i.referred_by_iid AND r.deleted_ts IS NULL
            WHERE i.kind = 'user' AND i.deleted_ts IS NULL
              AND i.created_ts >= $1 AND i.created_ts < $2
              {extra_filter}
            ORDER BY i.created_ts DESC, i.id DESC
            LIMIT $lim
            "#,
        )
    };

    let rows = if referred_by > 0 && cursor_ts > 0 && cursor_id > 0 {
        let sql = list_sql(
            "AND i.referred_by_iid = $3 AND (i.created_ts < $4 OR (i.created_ts = $4 AND i.id < $5))",
        )
        .replace("$lim", "$6");
        sqlx::query(&sql)
            .bind(start)
            .bind(end)
            .bind(referred_by)
            .bind(DateTime::<Utc>::from_timestamp_millis(cursor_ts).unwrap_or(start))
            .bind(cursor_id)
            .bind(fetch_limit)
            .fetch_all(pool)
            .await
    } else if referred_by > 0 {
        let sql = list_sql("AND i.referred_by_iid = $3").replace("$lim", "$4");
        sqlx::query(&sql)
            .bind(start)
            .bind(end)
            .bind(referred_by)
            .bind(fetch_limit)
            .fetch_all(pool)
            .await
    } else if cursor_ts > 0 && cursor_id > 0 {
        let sql = list_sql("AND (i.created_ts < $3 OR (i.created_ts = $3 AND i.id < $4))")
            .replace("$lim", "$5");
        sqlx::query(&sql)
            .bind(start)
            .bind(end)
            .bind(DateTime::<Utc>::from_timestamp_millis(cursor_ts).unwrap_or(start))
            .bind(cursor_id)
            .bind(fetch_limit)
            .fetch_all(pool)
            .await
    } else {
        let sql = list_sql("").replace("$lim", "$3");
        sqlx::query(&sql)
            .bind(start)
            .bind(end)
            .bind(fetch_limit)
            .fetch_all(pool)
            .await
    }
    .map_err(|e| AdminError::bad(e.to_string()))?;

    let has_more = rows.len() as i32 > limit;
    let take = rows.len().min(limit as usize);
    let users: Vec<AdminUserRegistrationRow> = rows
        .into_iter()
        .take(take)
        .map(|r| {
            let alien_id: String = r.get("alien_id");
            let handle = if alien_id.is_empty() {
                "@user".into()
            } else {
                format!("@{alien_id}")
            };
            let ref_id: i64 = r.get("referred_by_iid");
            let created: DateTime<Utc> = r.get("created_ts");
            AdminUserRegistrationRow {
                identity_id: r.get("id"),
                name: r.get("name"),
                handle,
                email: r.get("email"),
                registered_ts_ms: ts_ms(created),
                referred_by: row_referrer(
                    ref_id,
                    &r.get::<String, _>("ref_name"),
                    &r.get::<String, _>("ref_alien_id"),
                ),
            }
        })
        .collect();

    Ok(ResAdminUserRegistrationsList {
        count: users.len() as i64,
        users,
        timezone_used: tz_used,
        window_start_ms: ts_ms(start),
        window_end_ms: ts_ms(end),
        has_more,
    })
}

#[cfg(test)]
mod tests {
    use super::registration_window;

    #[test]
    fn preset_today_has_positive_window() {
        let (start, end, _) =
            registration_window("Asia/Jakarta", "today", "", "").expect("today");
        assert!(end > start);
    }

    #[test]
    fn since_until_day_range() {
        let (start, end, _) =
            registration_window("UTC", "", "2026-10-01", "2026-10-01").expect("range");
        assert_eq!((end - start).num_days(), 1);
    }
}
