use anyhow::Result;
use chrono::{DateTime, Utc};
use sqlx::{PgPool, Row};
use std::collections::HashSet;

/// Half-open overlap: an existing window overlaps the request when
/// `existing_start < requested_end` and `existing_end > requested_start`.
pub fn reservation_windows_overlap(
    existing_start: i64,
    existing_end: i64,
    requested_start: i64,
    requested_end: i64,
) -> bool {
    existing_start < requested_end && existing_end > requested_start
}

pub fn units_left(linked_objects: i64, overlapping_qty: i64) -> i64 {
    if linked_objects <= 0 {
        0
    } else {
        (linked_objects - overlapping_qty).max(0)
    }
}

pub fn availability_ok(units_available: i64, units: i64, start_ts_ms: i64, end_ts_ms: i64) -> bool {
    units_available >= units && units >= 1 && end_ts_ms > start_ts_ms
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FreeObject {
    pub id: i64,
    pub name: String,
    pub code: String,
    pub pic: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Availability {
    pub ok: bool,
    pub units_available: i64,
    pub free_objects: Vec<FreeObject>,
}

impl Availability {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "ok": self.ok,
            "units_available": self.units_available,
            "free_objects": self.free_objects.iter().map(|o| {
                serde_json::json!({
                    "id": o.id,
                    "name": o.name,
                    "code": o.code,
                    "pic": o.pic,
                })
            }).collect::<Vec<_>>(),
        })
    }
}

pub async fn guest_reservation_availability(
    pool: &PgPool,
    site_iid: i64,
    product_id: i64,
    start_ts_ms: i64,
    end_ts_ms: i64,
    units: i64,
) -> Result<Availability> {
    if site_iid <= 0 || product_id <= 0 {
        return Ok(Availability {
            ok: false,
            units_available: 0,
            free_objects: Vec::new(),
        });
    }

    let objects = sqlx::query(
        r#"
        SELECT id, name, code, pic
        FROM site.object
        WHERE site_iid = $1
          AND product_id = $2
          AND deleted_ts IS NULL
          AND is_active
          AND can_be_reserved
        ORDER BY sort_order, id
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .fetch_all(pool)
    .await?;

    let linked = objects.len() as i64;
    let (overlapping_qty, busy) =
        overlapping_reservation_load(pool, site_iid, product_id, start_ts_ms, end_ts_ms).await?;
    let units_available = units_left(linked, overlapping_qty);
    let free_objects = objects
        .iter()
        .filter(|r| {
            let id: i64 = r.get("id");
            !busy.contains(&id)
        })
        .map(|r| {
            let pic: String = r.get("pic");
            FreeObject {
                id: r.get("id"),
                name: r.get("name"),
                code: r.get("code"),
                pic: crate::guest_product::pic_url(&pic),
            }
        })
        .collect();

    Ok(Availability {
        ok: availability_ok(units_available, units, start_ts_ms, end_ts_ms),
        units_available,
        free_objects,
    })
}

/// `site.tx.state` is VARCHAR. Cancelled rows use the string `cancelled`
/// (`chk_tx_state`), the same value `mod_tx` writes via `tx_state_str`.
async fn overlapping_reservation_load(
    pool: &PgPool,
    site_iid: i64,
    product_id: i64,
    start_ts_ms: i64,
    end_ts_ms: i64,
) -> Result<(i64, HashSet<i64>)> {
    let (Some(start), Some(end)) = (
        DateTime::<Utc>::from_timestamp_millis(start_ts_ms),
        DateTime::<Utc>::from_timestamp_millis(end_ts_ms),
    ) else {
        return Ok((0, HashSet::new()));
    };

    let rows = sqlx::query(
        r#"
        SELECT r.site_object_id, r.qty
        FROM site.tx_item_reservation r
        JOIN site.tx t
          ON t.site_iid = r.site_iid AND t.tx_id = r.tx_id
        LEFT JOIN site.tx_item i
          ON i.site_iid = r.site_iid AND i.tx_id = r.tx_id AND i.item_id = r.item_id
        WHERE r.site_iid = $1
          AND r.deleted_ts IS NULL
          AND t.deleted_ts IS NULL
          AND t.state <> 'cancelled'
          AND (i.item_id IS NULL OR i.deleted_ts IS NULL)
          AND (r.product_id = $2 OR (r.product_id = 0 AND i.product_id = $2))
          AND r.start_ts < $4
          AND r.end_ts > $3
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .bind(start)
    .bind(end)
    .fetch_all(pool)
    .await?;

    let mut qty_sum = 0i64;
    let mut busy = HashSet::new();
    for row in &rows {
        let qty: i32 = row.get("qty");
        qty_sum += i64::from(qty.max(0));
        let object_id: i64 = row.get("site_object_id");
        if object_id > 0 {
            busy.insert(object_id);
        }
    }
    Ok((qty_sum, busy))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn half_open_windows_overlap_on_shared_interior_only() {
        assert!(reservation_windows_overlap(0, 10, 9, 12));
        assert!(reservation_windows_overlap(0, 10, 0, 10));
        assert!(reservation_windows_overlap(2, 4, 0, 10));
        assert!(reservation_windows_overlap(0, 10, 2, 4));
        assert!(!reservation_windows_overlap(0, 10, 10, 20));
        assert!(!reservation_windows_overlap(10, 20, 0, 10));
        assert!(!reservation_windows_overlap(0, 5, 5, 9));
        assert!(!reservation_windows_overlap(20, 30, 0, 10));
    }

    #[test]
    fn units_left_floors_and_zero_linked_objects_are_unavailable() {
        assert_eq!(units_left(0, 0), 0);
        assert_eq!(units_left(0, 4), 0);
        assert_eq!(units_left(3, 1), 2);
        assert_eq!(units_left(3, 5), 0);
        assert_eq!(units_left(3, 0), 3);
    }

    #[test]
    fn availability_ok_requires_capacity_and_a_forward_window() {
        assert!(availability_ok(3, 2, 1_000, 2_000));
        assert!(!availability_ok(1, 2, 1_000, 2_000));
        assert!(!availability_ok(3, 0, 1_000, 2_000));
        assert!(!availability_ok(3, 1, 2_000, 2_000));
        assert!(!availability_ok(3, 1, 3_000, 2_000));
        assert!(!availability_ok(0, 1, 1_000, 2_000));
    }
}
