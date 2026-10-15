//! Optional staff clock-in/out (site.presence_record). Never required app-wide.

use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSitePresenceClockIn, ReqSitePresenceClockOut, ReqSitePresenceContext, ReqSitePresenceRecordList,
    ResSitePresenceClockIn, ResSitePresenceClockOut, ResSitePresenceContext, ResSitePresenceRecordList,
    SitePresenceRecord, SitePresenceStaffContext,
};
use c35_store::snowflake_id;
use chrono::Utc;
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;
use crate::site_config::{site_capabilities_get, site_capability_enabled};
use crate::site_hr::site_member_shift_ids_normalize;
use crate::ts::ts_ms_opt;

struct OpenSession {
    session_id: String,
    clock_in_ms: i64,
    shift_id: String,
}

pub async fn site_presence_context(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePresenceContext,
) -> Result<ResSitePresenceContext> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    require_attendance_cap(pool, site_iid).await?;
    let shift_ids = member_shift_ids(pool, site_iid, caller_iid).await?;
    let open = open_session(pool, site_iid, caller_iid).await?;
    let can_clock_out = open.is_some();
    let can_clock_in = !can_clock_out;
    let (open_session_id, open_clock_in_ms) = match &open {
        Some(o) => (o.session_id.clone(), o.clock_in_ms),
        None => (String::new(), 0),
    };
    Ok(ResSitePresenceContext {
        context: Some(SitePresenceStaffContext {
            work_shift_ids: shift_ids,
            open_session_id,
            open_clock_in_ms,
            can_clock_in,
            can_clock_out,
            message: "Clock-in is optional. Use it only when your site tracks attendance.".into(),
        }),
    })
}

pub async fn site_presence_clock_in(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePresenceClockIn,
) -> Result<ResSitePresenceClockIn> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    require_attendance_cap(pool, site_iid).await?;
    if open_session(pool, site_iid, caller_iid).await?.is_some() {
        return Err(anyhow!("already clocked in"));
    }
    let shift_id = resolve_shift_id(pool, site_iid, caller_iid, req.shift_id.trim()).await?;
    let session_id = format!("ps_{}", snowflake_id());
    let record_id = snowflake_id();
    let at = Utc::now();
    sqlx::query(
        r#"
        INSERT INTO site.presence_record (
            record_id, site_iid, grantee_iid, shift_id, kind, at, session_id,
            attendance_method, status
        ) VALUES ($1, $2, $3, $4, 'clock_in', $5, $6, 'button', 'verified')
        "#,
    )
    .bind(record_id)
    .bind(site_iid)
    .bind(caller_iid)
    .bind(&shift_id)
    .bind(at)
    .bind(&session_id)
    .execute(pool)
    .await?;
    let record = presence_record_get(pool, record_id).await?;
    Ok(ResSitePresenceClockIn {
        record: Some(record),
        session_id,
    })
}

pub async fn site_presence_clock_out(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePresenceClockOut,
) -> Result<ResSitePresenceClockOut> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    require_attendance_cap(pool, site_iid).await?;
    let open = open_session(pool, site_iid, caller_iid)
        .await?
        .ok_or_else(|| anyhow!("no open session"))?;
    let at = Utc::now();
    let duration_min = ((at.timestamp_millis() - open.clock_in_ms) / 60_000).max(0) as i32;
    let record_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO site.presence_record (
            record_id, site_iid, grantee_iid, shift_id, kind, at, session_id,
            work_duration_min, attendance_method, status
        ) VALUES ($1, $2, $3, $4, 'clock_out', $5, $6, $7, 'button', 'verified')
        "#,
    )
    .bind(record_id)
    .bind(site_iid)
    .bind(caller_iid)
    .bind(&open.shift_id)
    .bind(at)
    .bind(&open.session_id)
    .bind(duration_min)
    .execute(pool)
    .await?;
    let record = presence_record_get(pool, record_id).await?;
    Ok(ResSitePresenceClockOut {
        record: Some(record),
        work_duration_min: duration_min,
    })
}

pub async fn site_presence_record_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePresenceRecordList,
) -> Result<ResSitePresenceRecordList> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    require_attendance_cap(pool, site_iid).await?;
    let grantee = if req.grantee_iid > 0 {
        req.grantee_iid
    } else {
        caller_iid
    };
    if grantee != caller_iid {
        let _ = site_grant_check(pool, caller_iid, site_iid, true).await?;
    }
    let limit = if req.limit > 0 { req.limit.min(100) } else { 50 };
    let rows = sqlx::query(
        r#"
        SELECT record_id, site_iid, grantee_iid, shift_id, kind, at, session_id,
               work_duration_min, attendance_method, status, reason
        FROM site.presence_record
        WHERE site_iid = $1 AND grantee_iid = $2
        ORDER BY at DESC
        LIMIT $3
        "#,
    )
    .bind(site_iid)
    .bind(grantee)
    .bind(limit as i64)
    .fetch_all(pool)
    .await?;
    Ok(ResSitePresenceRecordList {
        records: rows.iter().map(presence_record_from_row).collect(),
    })
}

async fn require_attendance_cap(pool: &PgPool, site_iid: i64) -> Result<()> {
    let caps = site_capabilities_get(pool, site_iid).await;
    if site_capability_enabled(&caps, "attendance") {
        Ok(())
    } else {
        Err(anyhow!("attendance not enabled for site"))
    }
}

async fn member_shift_ids(pool: &PgPool, site_iid: i64, grantee_iid: i64) -> Result<Vec<String>> {
    let rows = sqlx::query_scalar::<_, String>(
        "SELECT shift_id FROM site.member_shift WHERE site_iid = $1 AND grantee_iid = $2 ORDER BY shift_id",
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_all(pool)
    .await?;
    Ok(site_member_shift_ids_normalize(&rows))
}

async fn resolve_shift_id(
    pool: &PgPool,
    site_iid: i64,
    grantee_iid: i64,
    requested: &str,
) -> Result<String> {
    let ids = member_shift_ids(pool, site_iid, grantee_iid).await?;
    if !requested.is_empty() {
        if ids.iter().any(|id| id == requested) {
            return Ok(requested.to_string());
        }
        return Err(anyhow!("shift not assigned"));
    }
    if ids.len() == 1 {
        return Ok(ids[0].clone());
    }
    if ids.is_empty() {
        return Ok(String::new());
    }
    Ok(ids[0].clone())
}

async fn open_session(pool: &PgPool, site_iid: i64, grantee_iid: i64) -> Result<Option<OpenSession>> {
    let row = sqlx::query(
        r#"
        SELECT session_id, shift_id, at
        FROM site.presence_record
        WHERE site_iid = $1 AND grantee_iid = $2 AND kind = 'clock_in'
        ORDER BY at DESC
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_optional(pool)
    .await?;
    let Some(in_row) = row else {
        return Ok(None);
    };
    let session_id: String = in_row.get("session_id");
    if session_id.is_empty() {
        return Ok(None);
    }
    let has_out = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM site.presence_record
        WHERE site_iid = $1 AND grantee_iid = $2 AND session_id = $3 AND kind = 'clock_out'
        "#,
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .bind(&session_id)
    .fetch_one(pool)
    .await?;
    if has_out > 0 {
        return Ok(None);
    }
    Ok(Some(OpenSession {
        session_id,
        clock_in_ms: ts_ms_opt(Some(in_row.get("at"))),
        shift_id: in_row.get("shift_id"),
    }))
}

async fn presence_record_get(pool: &PgPool, record_id: i64) -> Result<SitePresenceRecord> {
    let row = sqlx::query(
        r#"
        SELECT record_id, site_iid, grantee_iid, shift_id, kind, at, session_id,
               work_duration_min, attendance_method, status, reason
        FROM site.presence_record WHERE record_id = $1
        "#,
    )
    .bind(record_id)
    .fetch_one(pool)
    .await?;
    Ok(presence_record_from_row(&row))
}

fn presence_record_from_row(r: &sqlx::postgres::PgRow) -> SitePresenceRecord {
    SitePresenceRecord {
        record_id: r.get("record_id"),
        site_iid: r.get("site_iid"),
        grantee_iid: r.get("grantee_iid"),
        shift_id: r.try_get("shift_id").unwrap_or_default(),
        kind: r.get("kind"),
        at_ms: ts_ms_opt(Some(r.get("at"))),
        session_id: r.try_get("session_id").unwrap_or_default(),
        work_duration_min: r.try_get::<Option<i32>, _>("work_duration_min").ok().flatten().unwrap_or(0),
        attendance_method: r.try_get("attendance_method").unwrap_or_else(|_| "button".into()),
        status: r.try_get("status").unwrap_or_else(|_| "verified".into()),
        reason: r.try_get("reason").unwrap_or_default(),
    }
}
