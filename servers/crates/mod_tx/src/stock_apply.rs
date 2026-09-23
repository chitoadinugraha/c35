use anyhow::Result;
use c35_proto::TxStock;
use sqlx::postgres::PgConnection;
use std::collections::HashMap;

use crate::enum_map::stock_direction_signed;

pub async fn product_stock_apply(
    conn: &mut PgConnection,
    site_iid: i64,
    old_stocks: &[TxStock],
    new_stocks: &[TxStock],
) -> Result<()> {
    let old_d = stock_counter_deltas(old_stocks);
    let new_d = stock_counter_deltas(new_stocks);
    let mut product_ids: HashMap<i64, i64> = HashMap::new();
    for d in old_d.values() {
        for pid in d.keys() {
            product_ids.insert(*pid, 0);
        }
    }
    for d in new_d.values() {
        for pid in d.keys() {
            product_ids.insert(*pid, 0);
        }
    }
    if product_ids.is_empty() {
        return Ok(());
    }
    let can_reserve = product_can_reserve_map(conn, site_iid, &product_ids.keys().copied().collect::<Vec<_>>()).await?;
    for product_id in product_ids.keys() {
        if can_reserve.get(product_id).copied().unwrap_or(false) {
            continue;
        }
        let old_qty = old_d.get(&0).and_then(|m| m.get(product_id)).copied().unwrap_or(0);
        let new_qty = new_d.get(&0).and_then(|m| m.get(product_id)).copied().unwrap_or(0);
        let delta = new_qty - old_qty;
        if delta == 0 {
            continue;
        }
        sqlx::query(
            r#"
            UPDATE site.product
            SET stock_qty = stock_qty + $3, updated_ts = NOW()
            WHERE site_iid = $1 AND product_id = $2 AND track_stock = TRUE AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .bind(product_id)
        .bind(delta as i32)
        .execute(&mut *conn)
        .await?;
    }
    Ok(())
}

async fn product_can_reserve_map(
    conn: &mut PgConnection,
    site_iid: i64,
    product_ids: &[i64],
) -> Result<HashMap<i64, bool>> {
    if product_ids.is_empty() {
        return Ok(HashMap::new());
    }
    let mut out = HashMap::new();
    for pid in product_ids {
        let row = sqlx::query_scalar::<_, bool>(
            "SELECT can_reserve FROM site.product WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL",
        )
        .bind(site_iid)
        .bind(pid)
        .fetch_optional(&mut *conn)
        .await?;
        out.insert(*pid, row.unwrap_or(false));
    }
    Ok(out)
}

fn stock_counter_deltas(stocks: &[TxStock]) -> HashMap<i64, HashMap<i64, i64>> {
    let mut out: HashMap<i64, HashMap<i64, i64>> = HashMap::new();
    for s in stocks {
        if s.product_id == 0 || s.qty == 0 {
            continue;
        }
        let signed = if s.qty_signed != 0 {
            s.qty_signed as i64
        } else {
            stock_direction_signed(&s.direction, s.qty) as i64
        };
        stock_counter_add(&mut out, 0, s.product_id, signed);
        match s.direction.as_str() {
            "in" => stock_counter_add(&mut out, s.obj_to_id, s.product_id, s.qty as i64),
            "out" => stock_counter_add(&mut out, s.obj_from_id, s.product_id, -(s.qty as i64)),
            "transfer" => {
                stock_counter_add(&mut out, s.obj_from_id, s.product_id, -(s.qty as i64));
                stock_counter_add(&mut out, s.obj_to_id, s.product_id, s.qty as i64);
            }
            _ => {}
        }
    }
    out
}

fn stock_counter_add(m: &mut HashMap<i64, HashMap<i64, i64>>, obj_id: i64, product_id: i64, delta: i64) {
    m.entry(obj_id).or_default().entry(product_id).and_modify(|v| *v += delta).or_insert(delta);
}
