use anyhow::{anyhow, Result};
use c35_mod_site::{
    reservation_windows_overlap, site_published, Availability,
};
use c35_proto::{
    ReqSiteGuestOrderGet, ReqSiteGuestOrderPut, ResSiteGuestOrderGet, ResSiteGuestOrderPut,
    Tx, TxInputMode, TxInputSource, TxItem, TxState, TxType,
};
use c35_store::snowflake_id;
use chrono::Utc;
use sqlx::{PgPool, Row};

use crate::finalize::tx_finalize;
use crate::load::tx_load;
use crate::persist::{tx_acc_counts, tx_children_del, tx_children_put, tx_header_put};
use crate::stock_apply::product_stock_apply;

pub async fn guest_order_put(pool: &PgPool, req: ReqSiteGuestOrderPut) -> Result<ResSiteGuestOrderPut> {
    let site_iid = req.site_iid;
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let owner_iid = guest_site_owner(pool, site_iid).await?;
    let mut tx = req.tx.ok_or_else(|| anyhow!("tx required"))?;
    if tx.tx_id > 0 {
        return Err(anyhow!("guest orders cannot update existing tx"));
    }
    guest_order_reprice(pool, site_iid, &mut tx).await?;
    guest_order_normalize(site_iid, &mut tx);
    tx_finalize(&mut tx);
    let (generated_count, manual_count) = tx_acc_counts(&tx);
    let mut db = pool.begin().await?;
    tx_children_del(&mut db, site_iid, tx.tx_id).await?;
    tx_header_put(&mut db, owner_iid, &tx, generated_count, manual_count).await?;
    tx_children_put(&mut db, &mut tx).await?;
    let state = TxState::try_from(tx.state).unwrap_or(TxState::WaitingPayment);
    if state == TxState::Ok {
        product_stock_apply(&mut db, site_iid, &[], &tx.stocks).await?;
    }
    db.commit().await?;
    let saved = tx_load(pool, site_iid, tx.tx_id).await?;
    Ok(ResSiteGuestOrderPut { tx: saved })
}

pub async fn guest_order_get(pool: &PgPool, req: ReqSiteGuestOrderGet) -> Result<ResSiteGuestOrderGet> {
    let site_iid = req.site_iid;
    if site_iid <= 0 || req.tx_id <= 0 {
        return Err(anyhow!("site_iid and tx_id required"));
    }
    let _ = guest_site_owner(pool, site_iid).await?;
    let tx = tx_load(pool, site_iid, req.tx_id).await?;
    let tx = tx.filter(|t| t.input_source == i32::from(TxInputSource::Web));
    Ok(ResSiteGuestOrderGet { tx })
}

async fn guest_site_owner(pool: &PgPool, site_iid: i64) -> Result<i64> {
    if !site_published(pool, site_iid).await? {
        return Err(anyhow!("site not published"));
    }
    let row = sqlx::query(
        r#"
        SELECT owner_iid FROM ai.identity
        WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    Ok(row.get("owner_iid"))
}

fn guest_order_normalize(site_iid: i64, tx: &mut Tx) {
    tx.tx_id = snowflake_id();
    tx.site_iid = site_iid;
    tx.r#type = i32::from(TxType::Sale);
    tx.state = i32::from(TxState::WaitingPayment);
    tx.input_mode = i32::from(TxInputMode::Sell);
    tx.input_source = i32::from(TxInputSource::Web);
    tx.is_task_assigned = true;
    if tx.time_ts_ms == 0 {
        tx.time_ts_ms = Utc::now().timestamp_millis();
    }
    if tx.created_ts_ms == 0 {
        tx.created_ts_ms = tx.time_ts_ms;
    }
}

struct ReservationHold {
    product_id: i64,
    start_ts_ms: i64,
    end_ts_ms: i64,
    site_object_id: i64,
    qty: i32,
}

async fn guest_order_reprice(pool: &PgPool, site_iid: i64, tx: &mut Tx) -> Result<()> {
    if tx.subject_name.trim().is_empty() {
        return Err(anyhow!("subject_name required"));
    }
    if tx.items.is_empty() {
        return Err(anyhow!("items required"));
    }
    let mut holds = Vec::new();
    for item in &mut tx.items {
        guest_item_reprice(pool, site_iid, item, &mut holds).await?;
    }
    Ok(())
}

async fn guest_item_reprice(
    pool: &PgPool,
    site_iid: i64,
    item: &mut TxItem,
    holds: &mut Vec<ReservationHold>,
) -> Result<()> {
    if item.product_id <= 0 {
        return Err(anyhow!("product_id required"));
    }
    if !item.reservations.is_empty() {
        let billable = crate::finalize::reservation_billable_qty(&item.reservations);
        if billable < 1 || billable > i64::from(i32::MAX) {
            return Err(anyhow!("reservation qty required"));
        }
        item.qty = billable as i32;
    } else if item.qty <= 0 {
        item.qty = 1;
    }
    let row = sqlx::query(
        r#"
        SELECT name, price, rev, can_sell, can_reserve
        FROM site.product
        WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL AND is_archived = FALSE
        "#,
    )
    .bind(site_iid)
    .bind(item.product_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("product not found: {}", item.product_id))?;
    let can_sell: bool = row.get("can_sell");
    let can_reserve: bool = row.get("can_reserve");
    if !item.reservations.is_empty() && !can_reserve {
        return Err(anyhow!("product cannot be reserved: {}", item.product_id));
    }
    if !can_sell {
        return Err(anyhow!("product not for sale: {}", item.product_id));
    }
    if item.price <= 0 {
        item.price = row.get("price");
    }
    item.product_rev = row.get("rev");
    if item.reservations.is_empty() {
        return Ok(());
    }
    let product_id = item.product_id;
    for res in &item.reservations {
        if res.end_ts_ms <= res.start_ts_ms {
            return Err(anyhow!("reservation end must be after start"));
        }
        if res.qty < 1 {
            return Err(anyhow!("reservation qty required"));
        }
        let avail = c35_mod_site::guest_reservation_availability(
            pool,
            site_iid,
            product_id,
            res.start_ts_ms,
            res.end_ts_ms,
            i64::from(res.qty),
        )
        .await?;
        let (free_ids, units_available) =
            availability_after_holds(&avail, product_id, res.start_ts_ms, res.end_ts_ms, holds);
        guest_reservation_slot_ok(res.site_object_id, res.qty, &free_ids, units_available)?;
        holds.push(ReservationHold {
            product_id,
            start_ts_ms: res.start_ts_ms,
            end_ts_ms: res.end_ts_ms,
            site_object_id: res.site_object_id,
            qty: res.qty,
        });
    }
    Ok(())
}

fn availability_after_holds(
    avail: &Availability,
    product_id: i64,
    start_ts_ms: i64,
    end_ts_ms: i64,
    holds: &[ReservationHold],
) -> (Vec<i64>, i64) {
    let mut free_ids: Vec<i64> = avail.free_objects.iter().map(|o| o.id).collect();
    let mut units_available = avail.units_available;
    for hold in holds {
        if hold.product_id != product_id {
            continue;
        }
        if !reservation_windows_overlap(hold.start_ts_ms, hold.end_ts_ms, start_ts_ms, end_ts_ms) {
            continue;
        }
        if hold.site_object_id > 0 {
            free_ids.retain(|id| *id != hold.site_object_id);
        }
        units_available = (units_available - i64::from(hold.qty)).max(0);
    }
    (free_ids, units_available)
}

fn guest_reservation_slot_ok(
    site_object_id: i64,
    qty: i32,
    free_object_ids: &[i64],
    units_available: i64,
) -> Result<()> {
    if qty < 1 {
        return Err(anyhow!("reservation qty required"));
    }
    if site_object_id > 0 {
        if !free_object_ids.contains(&site_object_id) {
            return Err(anyhow!("reservation unit is not available"));
        }
        return Ok(());
    }
    if units_available < i64::from(qty) {
        return Err(anyhow!("not enough units available"));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use c35_proto::TxItem;

    #[test]
    fn guest_order_normalize_sets_defaults() {
        let mut tx = Tx {
            site_iid: 99,
            subject_name: "Guest".into(),
            items: vec![TxItem {
                product_id: 1,
                qty: 2,
                price: 5000,
                ..Default::default()
            }],
            ..Default::default()
        };
        guest_order_normalize(42, &mut tx);
        assert_eq!(tx.site_iid, 42);
        assert!(tx.tx_id > 0);
        assert_eq!(tx.r#type, i32::from(TxType::Sale));
        assert_eq!(tx.state, i32::from(TxState::WaitingPayment));
        assert_eq!(tx.input_source, i32::from(TxInputSource::Web));
        assert!(tx.is_task_assigned);
    }

    #[test]
    fn reservation_billable_qty_sums_qty_times_duration() {
        use c35_proto::TxItemReservation;
        let rows = vec![
            TxItemReservation {
                qty: 2,
                duration_qty: 3,
                ..Default::default()
            },
            TxItemReservation {
                qty: 1,
                duration_qty: 0,
                ..Default::default()
            },
        ];
        assert_eq!(crate::finalize::reservation_billable_qty(&rows), 7);
    }

    #[test]
    fn slot_check_covers_guest_picked_and_system_assigned() {
        let free = vec![101, 102];
        assert!(guest_reservation_slot_ok(101, 1, &free, 2).is_ok());
        assert!(guest_reservation_slot_ok(109, 1, &free, 2).is_err());
        assert!(guest_reservation_slot_ok(0, 2, &free, 2).is_ok());
        assert!(guest_reservation_slot_ok(0, 3, &free, 2).is_err());
    }

    #[test]
    fn earlier_hold_blocks_the_same_unit_and_reduces_the_pool() {
        let avail = Availability {
            ok: true,
            units_available: 2,
            free_objects: vec![
                c35_mod_site::FreeObject {
                    id: 101,
                    name: "A".into(),
                    code: "A".into(),
                    pic: String::new(),
                },
                c35_mod_site::FreeObject {
                    id: 102,
                    name: "B".into(),
                    code: "B".into(),
                    pic: String::new(),
                },
            ],
        };
        let holds = vec![ReservationHold {
            product_id: 7,
            start_ts_ms: 1_000,
            end_ts_ms: 2_000,
            site_object_id: 101,
            qty: 1,
        }];
        let (free_ids, units) = availability_after_holds(&avail, 7, 1_500, 2_500, &holds);
        assert!(!free_ids.contains(&101));
        assert!(free_ids.contains(&102));
        assert_eq!(units, 1);
        assert!(guest_reservation_slot_ok(101, 1, &free_ids, units).is_err());
        assert!(guest_reservation_slot_ok(0, 1, &free_ids, units).is_ok());
        assert!(guest_reservation_slot_ok(0, 2, &free_ids, units).is_err());
    }
}
