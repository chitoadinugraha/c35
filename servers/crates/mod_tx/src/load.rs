use anyhow::{anyhow, Result};
use c35_proto::Tx;
use sqlx::{PgPool, Row};
use std::collections::HashMap;

use crate::rows::{
    tx_acc_from_row, tx_debt_payment_from_row, tx_discount_from_row, tx_header_from_row,
    tx_installment_from_row, tx_item_from_row, tx_item_reservation_from_row, tx_item_source_from_row,
    tx_payment_from_row, tx_stock_from_row, tx_tax_from_row,
};

const TX_HEADER_SQL: &str = r#"
    SELECT site_iid, tx_id, owner_iid, ty, state, input_mode, input_source,
           is_archived, "desc", time_ts, created_by_iid, cancel_reason,
           subject_contact_id, subject_name, subject_phone, subject_address, cashier_name,
           store_id, store_tgt_id, delivery_state, obj_id, promo_code,
           is_paid, is_task_assigned, order_pay_at,
           items_count, items_qty, items_total,
           debt_total, debt_paid, debt_unpaid,
           total_taxes, total_discounts, total_interest, total_paid, total_unpaid, total,
           stock_line_count, stock_qty_in, stock_qty_out,
           acc_line_count, acc_sum, acc_balanced, has_manual_lines,
           tx_data_json, created_ts, updated_ts, deleted_ts
    FROM site.tx
    WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
"#;

pub async fn tx_load(pool: &PgPool, site_iid: i64, tx_id: i64) -> Result<Option<Tx>> {
    let row = sqlx::query(TX_HEADER_SQL)
        .bind(site_iid)
        .bind(tx_id)
        .fetch_optional(pool)
        .await?;
    let Some(row) = row else {
        return Ok(None);
    };
    let mut tx = tx_header_from_row(&row);
    tx_children_attach(pool, site_iid, tx_id, &mut tx).await?;
    Ok(Some(tx))
}

pub async fn tx_children_attach(
    pool: &PgPool,
    site_iid: i64,
    tx_id: i64,
    tx: &mut Tx,
) -> Result<()> {
    let items = sqlx::query(
        r#"
        SELECT site_iid, tx_id, item_id, owner_iid, obj_id, product_id, product_rev, price, qty, note,
               batch_number, serial_number, fulfillment_state,
               total_qty, total_price, total_discount, total_tax, total_net,
               total_paid, total_unpaid
        FROM site.tx_item
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        ORDER BY item_id
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    let mut item_map: HashMap<i64, c35_proto::TxItem> = HashMap::new();
    for r in &items {
        let item = tx_item_from_row(r);
        item_map.insert(item.item_id, item);
    }
    if !item_map.is_empty() {
        let sources = sqlx::query(
            r#"
            SELECT site_iid, tx_id, item_id, src_id, obj_id, product_id, qty, note
            FROM site.tx_item_source
            WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .fetch_all(pool)
        .await?;
        for r in &sources {
            let item_id: i64 = r.get("item_id");
            if let Some(item) = item_map.get_mut(&item_id) {
                item.sources.push(tx_item_source_from_row(r));
            }
        }
        let reservations = sqlx::query(
            r#"
            SELECT site_iid, tx_id, item_id, res_id, product_id, qty, duration_qty, note,
                   start_ts, end_ts, state, is_no_show, is_unavailable
            FROM site.tx_item_reservation
            WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .fetch_all(pool)
        .await?;
        for r in &reservations {
            let item_id: i64 = r.get("item_id");
            if let Some(item) = item_map.get_mut(&item_id) {
                item.reservations.push(tx_item_reservation_from_row(r));
            }
        }
    }
    tx.items = item_map.into_values().collect();

    let payments = sqlx::query(
        r#"
        SELECT site_iid, tx_id, payment_id, method, ts, amount, note,
               from_wallet, to_wallet, debt_interest, payment_json
        FROM site.tx_payment
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        ORDER BY payment_id
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    let mut pay_map: HashMap<i64, c35_proto::TxPayment> = HashMap::new();
    for r in &payments {
        let p = tx_payment_from_row(r);
        pay_map.insert(p.payment_id, p);
    }
    if !pay_map.is_empty() {
        let installments = sqlx::query(
            r#"
            SELECT site_iid, tx_id, payment_id, inst_id, due_ts, amount, note, is_paid, is_overdue
            FROM site.tx_installment
            WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .fetch_all(pool)
        .await?;
        let mut inst_map: HashMap<(i64, i64), c35_proto::TxInstallment> = HashMap::new();
        for r in &installments {
            let payment_id: i64 = r.get("payment_id");
            let inst = tx_installment_from_row(r);
            inst_map.insert((payment_id, inst.inst_id), inst);
        }
        let debt_pays = sqlx::query(
            r#"
            SELECT site_iid, tx_id, payment_id, inst_id, pay_id, ts, method, amount, note,
                   overdue_interest, payment_json
            FROM site.tx_debt_payment
            WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .fetch_all(pool)
        .await?;
        for r in &debt_pays {
            let payment_id: i64 = r.get("payment_id");
            let inst_id: i64 = r.get("inst_id");
            if let Some(inst) = inst_map.get_mut(&(payment_id, inst_id)) {
                inst.debt_payments.push(tx_debt_payment_from_row(r));
            }
        }
        for ((payment_id, _), inst) in inst_map {
            if let Some(p) = pay_map.get_mut(&payment_id) {
                p.installments.push(inst);
            }
        }
    }
    tx.payments = pay_map.into_values().collect();

    let accs = sqlx::query(
        r#"
        SELECT site_iid, tx_id, acc_id, acc_code, ts, side, amount, note, is_tx_generated
        FROM site.tx_acc
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        ORDER BY acc_id
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    tx.accs = accs.iter().map(tx_acc_from_row).collect();

    let stocks = sqlx::query(
        r#"
        SELECT site_iid, tx_id, stock_id, product_id, ts, obj_from_id, obj_to_id,
               qty, qty_signed, direction, note
        FROM site.tx_stock
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        ORDER BY stock_id
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    tx.stocks = stocks.iter().map(tx_stock_from_row).collect();

    let taxes = sqlx::query(
        r#"
        SELECT site_iid, tx_id, tax_id, tax_type, amount, note
        FROM site.tx_tax
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        ORDER BY tax_id
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    tx.taxes = taxes.iter().map(tx_tax_from_row).collect();

    let discounts = sqlx::query(
        r#"
        SELECT site_iid, tx_id, discount_id, discount_type, amount, note
        FROM site.tx_discount
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        ORDER BY discount_id
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    tx.discounts = discounts.iter().map(tx_discount_from_row).collect();

    Ok(())
}

pub async fn tx_stocks_load(
    pool: &PgPool,
    site_iid: i64,
    tx_id: i64,
) -> Result<Vec<c35_proto::TxStock>> {
    let rows = sqlx::query(
        r#"
        SELECT site_iid, tx_id, stock_id, product_id, ts, obj_from_id, obj_to_id,
               qty, qty_signed, direction, note
        FROM site.tx_stock
        WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(tx_stock_from_row).collect())
}

pub async fn tx_require(pool: &PgPool, site_iid: i64, tx_id: i64) -> Result<Tx> {
    tx_load(pool, site_iid, tx_id)
        .await?
        .ok_or_else(|| anyhow!("tx not found"))
}
