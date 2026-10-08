//! Site HR - work shifts, member face enroll, presence locations (CSA parity).

use anyhow::{bail, Result};
use c35_proto::{
    ReqSiteMemberFaceDel, ReqSiteMemberFaceList, ReqSiteMemberFacePut, ReqSitePresenceLocationList,
    ReqSitePresenceLocationPut, ReqSiteWorkShiftList, ReqSiteWorkShiftPut, ResSiteMemberFaceDel,
    ResSiteMemberFaceList, ResSiteMemberFacePut, ResSitePresenceLocationList, ResSitePresenceLocationPut,
    ResSiteWorkShiftList, ResSiteWorkShiftPut, SiteMemberFacePhoto, SitePresenceLatLng, SitePresenceLocation,
    SiteWorkShift, SiteWorkShiftSlot,
};
use c35_store::snowflake_id;
use chrono::{DateTime, Utc};
use serde_json::json;
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;

fn ts_ms(t: Option<DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

fn attendance_method_ok(method: &str) -> bool {
    matches!(
        method,
        "button" | "gps" | "gps_selfie" | "gps_selfie_face" | "cctv_walkby"
    )
}

/// Trim / drop empty / dedupe shift ids (stable sort).
pub fn site_member_shift_ids_normalize(shift_ids: &[String]) -> Vec<String> {
    let mut ids: Vec<String> = shift_ids
        .iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    ids.sort();
    ids.dedup();
    ids
}

/// Replace site.member_shift for (site, grantee). Empty list clears. Unknown shift_id errors.
pub async fn site_member_shift_sync(
    pool: &PgPool,
    site_iid: i64,
    grantee_iid: i64,
    work_shift_ids: &[String],
) -> Result<()> {
    let ids = site_member_shift_ids_normalize(work_shift_ids);
    if !ids.is_empty() {
        let found: i64 = sqlx::query_scalar(
            r#"
            SELECT COUNT(*)::bigint FROM site.work_shift
            WHERE site_iid = $1 AND deleted_ts IS NULL AND shift_id = ANY($2)
            "#,
        )
        .bind(site_iid)
        .bind(&ids)
        .fetch_one(pool)
        .await?;
        if found != ids.len() as i64 {
            bail!("unknown work_shift_id for site");
        }
    }

    let mut tx = pool.begin().await?;
    sqlx::query("DELETE FROM site.member_shift WHERE site_iid = $1 AND grantee_iid = $2")
        .bind(site_iid)
        .bind(grantee_iid)
        .execute(&mut *tx)
        .await?;
    for sid in &ids {
        sqlx::query(
            "INSERT INTO site.member_shift (site_iid, grantee_iid, shift_id) VALUES ($1, $2, $3)",
        )
        .bind(site_iid)
        .bind(grantee_iid)
        .bind(sid)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(())
}

/// On grant delete: remove member_shift rows; soft-delete member_face if any.
pub async fn site_member_hr_cleanup(pool: &PgPool, site_iid: i64, grantee_iid: i64) -> Result<()> {
    sqlx::query("DELETE FROM site.member_shift WHERE site_iid = $1 AND grantee_iid = $2")
        .bind(site_iid)
        .bind(grantee_iid)
        .execute(pool)
        .await?;
    sqlx::query(
        r#"
        UPDATE site.member_face
        SET deleted_ts = NOW(), updated_ts = NOW(), is_active = FALSE
        WHERE site_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn site_work_shift_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteWorkShiftList,
) -> Result<ResSiteWorkShiftList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    Ok(ResSiteWorkShiftList {
        shifts: site_work_shifts_load(pool, req.site_iid).await?,
    })
}

pub async fn site_work_shift_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteWorkShiftPut,
) -> Result<ResSiteWorkShiftPut> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let site_iid = req.site_iid;
    let shifts = req.shifts;
    let mut tx = pool.begin().await?;

    let keep: Vec<String> = shifts
        .iter()
        .map(|s| s.id.trim().to_string())
        .filter(|id| !id.is_empty())
        .collect();

    if keep.is_empty() {
        sqlx::query(
            r#"
            UPDATE site.work_shift
            SET deleted_ts = NOW(), updated_ts = NOW(), is_active = false
            WHERE site_iid = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .execute(&mut *tx)
        .await?;
        sqlx::query(r#"DELETE FROM site.member_shift WHERE site_iid = $1"#)
            .bind(site_iid)
            .execute(&mut *tx)
            .await?;
    } else {
        sqlx::query(
            r#"
            UPDATE site.work_shift
            SET deleted_ts = NOW(), updated_ts = NOW(), is_active = false
            WHERE site_iid = $1 AND deleted_ts IS NULL AND NOT (shift_id = ANY($2))
            "#,
        )
        .bind(site_iid)
        .bind(&keep)
        .execute(&mut *tx)
        .await?;
        sqlx::query(
            r#"
            DELETE FROM site.member_shift
            WHERE site_iid = $1 AND NOT (shift_id = ANY($2))
            "#,
        )
        .bind(site_iid)
        .bind(&keep)
        .execute(&mut *tx)
        .await?;
    }

    for (sort, shift) in shifts.into_iter().enumerate() {
        let shift_id = shift.id.trim();
        if shift_id.is_empty() {
            continue;
        }
        let method = shift.attendance_method.trim();
        let method = if attendance_method_ok(method) {
            method
        } else {
            "button"
        };
        sqlx::query(
            r#"
            INSERT INTO site.work_shift (
                site_iid, shift_id, name, attendance_method, is_active, sort_order,
                created_ts, updated_ts, deleted_ts
            ) VALUES ($1, $2, $3, $4, true, $5, NOW(), NOW(), NULL)
            ON CONFLICT (site_iid, shift_id) DO UPDATE SET
                name = EXCLUDED.name,
                attendance_method = EXCLUDED.attendance_method,
                is_active = true,
                sort_order = EXCLUDED.sort_order,
                updated_ts = NOW(),
                deleted_ts = NULL
            "#,
        )
        .bind(site_iid)
        .bind(shift_id)
        .bind(shift.name.trim())
        .bind(method)
        .bind(sort as i32)
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            r#"DELETE FROM site.work_shift_slot WHERE site_iid = $1 AND shift_id = $2"#,
        )
        .bind(site_iid)
        .bind(shift_id)
        .execute(&mut *tx)
        .await?;

        for slot in shift.slots {
            let slot_id = slot.id.trim();
            if slot_id.is_empty() {
                continue;
            }
            sqlx::query(
                r#"
                INSERT INTO site.work_shift_slot
                    (site_iid, shift_id, slot_id, start_day, start_min, end_day, end_min)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                "#,
            )
            .bind(site_iid)
            .bind(shift_id)
            .bind(slot_id)
            .bind(slot.start_day.clamp(0, 6))
            .bind(slot.start_min.clamp(0, 1439))
            .bind(slot.end_day.clamp(0, 6))
            .bind(slot.end_min.clamp(0, 1439))
            .execute(&mut *tx)
            .await?;
        }
    }

    tx.commit().await?;
    Ok(ResSiteWorkShiftPut { ok: true })
}

pub(crate) async fn site_work_shifts_load(
    pool: &PgPool,
    site_iid: i64,
) -> Result<Vec<SiteWorkShift>> {
    let shift_rows = sqlx::query(
        r#"
        SELECT shift_id, name, attendance_method, created_ts, updated_ts, deleted_ts
        FROM site.work_shift
        WHERE site_iid = $1 AND deleted_ts IS NULL AND is_active
        ORDER BY sort_order, shift_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;

    let mut shifts = Vec::with_capacity(shift_rows.len());
    for row in shift_rows {
        let shift_id: String = row.try_get("shift_id")?;
        let name: String = row.try_get("name")?;
        let attendance_method: String = row.try_get("attendance_method")?;
        let created_ts: DateTime<Utc> = row.try_get("created_ts")?;
        let updated_ts: DateTime<Utc> = row.try_get("updated_ts")?;
        let deleted_ts: Option<DateTime<Utc>> = row.try_get("deleted_ts")?;
        let slot_rows = sqlx::query(
            r#"
            SELECT slot_id, start_day, start_min, end_day, end_min
            FROM site.work_shift_slot
            WHERE site_iid = $1 AND shift_id = $2
            ORDER BY start_day, start_min, slot_id
            "#,
        )
        .bind(site_iid)
        .bind(&shift_id)
        .fetch_all(pool)
        .await?;
        let slots = slot_rows
            .into_iter()
            .map(|s| {
                Ok(SiteWorkShiftSlot {
                    id: s.try_get("slot_id")?,
                    start_day: s.try_get("start_day")?,
                    start_min: s.try_get("start_min")?,
                    end_day: s.try_get("end_day")?,
                    end_min: s.try_get("end_min")?,
                })
            })
            .collect::<Result<Vec<_>>>()?;
        shifts.push(SiteWorkShift {
            site_iid,
            id: shift_id,
            name,
            attendance_method,
            slots,
            created_ts_ms: ts_ms(Some(created_ts)),
            updated_ts_ms: ts_ms(Some(updated_ts)),
            deleted_ts_ms: ts_ms(deleted_ts),
        });
    }
    Ok(shifts)
}

// ================================= Member face (site.member_face)

fn face_url(file_hash: &str) -> String {
    if file_hash.is_empty() {
        String::new()
    } else {
        format!("/fs/{file_hash}")
    }
}

fn face_photo_from_row(row: &sqlx::postgres::PgRow) -> Result<SiteMemberFacePhoto> {
    let face_id: i64 = row.try_get("face_id")?;
    let file_hash: String = row.try_get("file_hash")?;
    let embedding: Vec<f32> = row.try_get("embedding").unwrap_or_default();
    let pose: String = row.try_get("pose").unwrap_or_default();
    let grantee_iid: i64 = row.try_get("grantee_iid")?;
    let created_ts: DateTime<Utc> = row.try_get("created_ts")?;
    let updated_ts: DateTime<Utc> = row.try_get("updated_ts")?;
    let deleted_ts: Option<DateTime<Utc>> = row.try_get("deleted_ts")?;
    Ok(SiteMemberFacePhoto {
        id: face_id.to_string(),
        url: face_url(&file_hash),
        embedding,
        file_hash,
        pose,
        grantee_iid,
        created_ts_ms: ts_ms(Some(created_ts)),
        updated_ts_ms: ts_ms(Some(updated_ts)),
        deleted_ts_ms: ts_ms(deleted_ts),
    })
}

pub async fn site_member_face_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteMemberFaceList,
) -> Result<ResSiteMemberFaceList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let rows = if req.grantee_iid > 0 {
        sqlx::query(
            r#"
            SELECT face_id, grantee_iid, file_hash, embedding, pose, created_ts, updated_ts, deleted_ts
            FROM site.member_face
            WHERE site_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL AND is_active
            ORDER BY sort_order, face_id
            "#,
        )
        .bind(req.site_iid)
        .bind(req.grantee_iid)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT face_id, grantee_iid, file_hash, embedding, pose, created_ts, updated_ts, deleted_ts
            FROM site.member_face
            WHERE site_iid = $1 AND deleted_ts IS NULL AND is_active
            ORDER BY grantee_iid, sort_order, face_id
            "#,
        )
        .bind(req.site_iid)
        .fetch_all(pool)
        .await?
    };
    let faces = rows.iter().map(face_photo_from_row).collect::<Result<Vec<_>>>()?;
    Ok(ResSiteMemberFaceList { faces })
}

pub async fn site_member_face_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteMemberFacePut,
) -> Result<ResSiteMemberFacePut> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let site_iid = req.site_iid;
    let grantee_iid = req.grantee_iid;
    if site_iid <= 0 || grantee_iid <= 0 {
        bail!("site_iid and grantee_iid required");
    }
    let file_hash = req.file_hash.trim().to_lowercase();
    if file_hash.is_empty() {
        bail!("file_hash required");
    }
    if file_hash.len() != 64 || !file_hash.chars().all(|c| c.is_ascii_hexdigit()) {
        bail!("file_hash must be 64-char blake3 hex");
    }
    let pose = req.pose.trim().to_string();
    let face_id = snowflake_id();
    let empty_emb: Vec<f32> = vec![];
    let sort_order: i32 = sqlx::query_scalar(
        r#"
        SELECT COALESCE(MAX(sort_order), -1) + 1
        FROM site.member_face
        WHERE site_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_one(pool)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.member_face (
            face_id, site_iid, grantee_iid, file_hash, embedding, model_version, pose,
            is_active, sort_order, created_by_iid, created_ts, updated_ts, deleted_ts
        ) VALUES ($1, $2, $3, $4, $5, 'none', $6, true, $7, $8, NOW(), NOW(), NULL)
        "#,
    )
    .bind(face_id)
    .bind(site_iid)
    .bind(grantee_iid)
    .bind(&file_hash)
    .bind(&empty_emb)
    .bind(&pose)
    .bind(sort_order)
    .bind(caller_iid)
    .execute(pool)
    .await?;
    let row = sqlx::query(
        r#"
        SELECT face_id, grantee_iid, file_hash, embedding, pose, created_ts, updated_ts, deleted_ts
        FROM site.member_face WHERE face_id = $1
        "#,
    )
    .bind(face_id)
    .fetch_one(pool)
    .await?;
    Ok(ResSiteMemberFacePut {
        face: Some(face_photo_from_row(&row)?),
    })
}

pub async fn site_member_face_del(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteMemberFaceDel,
) -> Result<ResSiteMemberFaceDel> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let face_id: i64 = req
        .face_id
        .trim()
        .parse()
        .map_err(|_| anyhow::anyhow!("invalid face_id"))?;
    if req.site_iid <= 0 || req.grantee_iid <= 0 || face_id <= 0 {
        bail!("site_iid, grantee_iid, and face_id required");
    }
    let n = sqlx::query(
        r#"
        UPDATE site.member_face
        SET deleted_ts = NOW(), updated_ts = NOW(), is_active = FALSE
        WHERE face_id = $1 AND site_iid = $2 AND grantee_iid = $3 AND deleted_ts IS NULL
        "#,
    )
    .bind(face_id)
    .bind(req.site_iid)
    .bind(req.grantee_iid)
    .execute(pool)
    .await?
    .rows_affected();
    if n == 0 {
        bail!("face not found");
    }
    Ok(ResSiteMemberFaceDel { ok: true })
}

// ================================= Presence locations (site.presence_location)

fn presence_polygon_to_json(polygon: &[SitePresenceLatLng]) -> serde_json::Value {
    json!(polygon
        .iter()
        .map(|p| json!({ "lat": p.lat, "lng": p.lng }))
        .collect::<Vec<_>>())
}

fn presence_polygon_from_json(v: &serde_json::Value) -> Vec<SitePresenceLatLng> {
    v.as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|p| {
                    Some(SitePresenceLatLng {
                        lat: p.get("lat")?.as_f64()?,
                        lng: p.get("lng")?.as_f64()?,
                    })
                })
                .collect()
        })
        .unwrap_or_default()
}

pub async fn site_presence_location_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePresenceLocationList,
) -> Result<ResSitePresenceLocationList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let rows = sqlx::query(
        r#"
        SELECT location_id, name, polygon, created_ts, updated_ts, deleted_ts
        FROM site.presence_location
        WHERE site_iid = $1 AND deleted_ts IS NULL AND is_active
        ORDER BY sort_order, location_id
        "#,
    )
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    let mut locations = Vec::with_capacity(rows.len());
    for row in rows {
        let id: String = row.try_get("location_id")?;
        let name: String = row.try_get("name")?;
        let polygon_json: serde_json::Value = row.try_get("polygon")?;
        let created_ts: DateTime<Utc> = row.try_get("created_ts")?;
        let updated_ts: DateTime<Utc> = row.try_get("updated_ts")?;
        let deleted_ts: Option<DateTime<Utc>> = row.try_get("deleted_ts")?;
        locations.push(SitePresenceLocation {
            site_iid: req.site_iid,
            id,
            name,
            polygon: presence_polygon_from_json(&polygon_json),
            created_ts_ms: ts_ms(Some(created_ts)),
            updated_ts_ms: ts_ms(Some(updated_ts)),
            deleted_ts_ms: ts_ms(deleted_ts),
        });
    }
    Ok(ResSitePresenceLocationList { locations })
}

pub async fn site_presence_location_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePresenceLocationPut,
) -> Result<ResSitePresenceLocationPut> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let site_iid = req.site_iid;
    let locations = req.locations;
    let mut tx = pool.begin().await?;
    let keep: Vec<String> = locations
        .iter()
        .map(|l| l.id.trim().to_string())
        .filter(|id| !id.is_empty())
        .collect();
    if keep.is_empty() {
        sqlx::query(
            r#"
            UPDATE site.presence_location
            SET deleted_ts = NOW(), updated_ts = NOW(), is_active = false
            WHERE site_iid = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .execute(&mut *tx)
        .await?;
    } else {
        sqlx::query(
            r#"
            UPDATE site.presence_location
            SET deleted_ts = NOW(), updated_ts = NOW(), is_active = false
            WHERE site_iid = $1 AND deleted_ts IS NULL AND NOT (location_id = ANY($2))
            "#,
        )
        .bind(site_iid)
        .bind(&keep)
        .execute(&mut *tx)
        .await?;
    }
    for (sort, loc) in locations.into_iter().enumerate() {
        let location_id = loc.id.trim();
        if location_id.is_empty() {
            continue;
        }
        let polygon = presence_polygon_to_json(&loc.polygon);
        sqlx::query(
            r#"
            INSERT INTO site.presence_location (
                site_iid, location_id, name, polygon, is_active, sort_order,
                created_ts, updated_ts, deleted_ts
            ) VALUES ($1, $2, $3, $4, true, $5, NOW(), NOW(), NULL)
            ON CONFLICT (site_iid, location_id) DO UPDATE SET
                name = EXCLUDED.name,
                polygon = EXCLUDED.polygon,
                is_active = true,
                sort_order = EXCLUDED.sort_order,
                updated_ts = NOW(),
                deleted_ts = NULL
            "#,
        )
        .bind(site_iid)
        .bind(location_id)
        .bind(loc.name.trim())
        .bind(polygon)
        .bind(sort as i32)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(ResSitePresenceLocationPut { ok: true })
}
