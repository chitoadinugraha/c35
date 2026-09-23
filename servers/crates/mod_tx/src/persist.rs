use anyhow::Result;
use c35_proto::Tx;
use c35_store::snowflake_id;
use sqlx::postgres::PgConnection;

use crate::enum_map::{
    tx_acc_side_str, tx_debt_payment_method_str, tx_fulfillment_str, tx_input_mode_str,
    tx_input_source_str, tx_order_pay_at_str, tx_payment_method_str, tx_state_str, tx_type_str,
};
use crate::ts::ts_from_ms;

pub async fn tx_children_del(conn: &mut PgConnection, site_iid: i64, tx_id: i64) -> Result<()> {
    let queries = [
        "DELETE FROM site.tx_debt_payment WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_installment WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_item_reservation WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_item_source WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_item WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_payment WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_acc WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_stock WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_tax WHERE site_iid = $1 AND tx_id = $2",
        "DELETE FROM site.tx_discount WHERE site_iid = $1 AND tx_id = $2",
    ];
    for q in queries {
        sqlx::query(q).bind(site_iid).bind(tx_id).execute(&mut *conn).await?;
    }
    Ok(())
}

pub async fn tx_header_put(
    conn: &mut PgConnection,
    owner_iid: i64,
    tx: &Tx,
    generated_count: i32,
    manual_count: i32,
) -> Result<()> {
    let ty = c35_proto::TxType::try_from(tx.r#type).unwrap_or(c35_proto::TxType::Unspecified);
    let state = c35_proto::TxState::try_from(tx.state).unwrap_or(c35_proto::TxState::Ok);
    let input_mode =
        c35_proto::TxInputMode::try_from(tx.input_mode).unwrap_or(c35_proto::TxInputMode::Normal);
    let input_source = c35_proto::TxInputSource::try_from(tx.input_source)
        .unwrap_or(c35_proto::TxInputSource::Manual);
    let order_pay_at =
        c35_proto::TxOrderPayAt::try_from(tx.order_pay_at).unwrap_or(c35_proto::TxOrderPayAt::Unspecified);
    let tx_data_json = if let Some(data) = &tx.tx_data {
        crate::tx_data::tx_data_to_json(data)
    } else {
        serde_json::json!({})
    };
    let time_ts = ts_from_ms(tx.time_ts_ms).unwrap_or_else(chrono::Utc::now);
    let cancel_reason = if tx.cancel_reason.is_empty() {
        None
    } else {
        Some(tx.cancel_reason.clone())
    };
    let created_by = if tx.created_by_iid > 0 {
        Some(tx.created_by_iid)
    } else {
        None
    };
    sqlx::query(
        r#"
        INSERT INTO site.tx (
            site_iid, tx_id, owner_iid, ty, state, input_mode, input_source,
            is_archived, "desc", time_ts, created_by_iid, cancel_reason,
            subject_contact_id, subject_name, subject_phone, subject_address, cashier_name,
            store_id, store_tgt_id, delivery_state, obj_id, promo_code,
            is_paid, is_task_assigned, order_pay_at,
            items_count, items_qty, items_total,
            debt_total, debt_paid, debt_unpaid,
            total_taxes, total_discounts, total_interest, total_paid, total_unpaid, total,
            stock_line_count, stock_qty_in, stock_qty_out,
            acc_line_count, acc_sum, acc_balanced, has_manual_lines,
            generated_count, manual_count, tx_data_json, created_ts, updated_ts
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7,
            $8, $9, $10, $11, $12,
            $13, $14, $15, $16, $17,
            $18, $19, $20, $21, $22,
            $23, $24, $25,
            $26, $27, $28,
            $29, $30, $31,
            $32, $33, $34, $35, $36, $37,
            $38, $39, $40,
            $41, $42, $43, $44,
            $45, $46, $47, NOW(), NOW()
        )
        ON CONFLICT (site_iid, tx_id) DO UPDATE SET
            owner_iid = EXCLUDED.owner_iid, ty = EXCLUDED.ty, state = EXCLUDED.state,
            input_mode = EXCLUDED.input_mode, input_source = EXCLUDED.input_source,
            is_archived = EXCLUDED.is_archived, "desc" = EXCLUDED."desc",
            time_ts = EXCLUDED.time_ts, created_by_iid = EXCLUDED.created_by_iid,
            cancel_reason = EXCLUDED.cancel_reason,
            subject_contact_id = EXCLUDED.subject_contact_id, subject_name = EXCLUDED.subject_name,
            subject_phone = EXCLUDED.subject_phone, subject_address = EXCLUDED.subject_address,
            cashier_name = EXCLUDED.cashier_name,
            store_id = EXCLUDED.store_id, store_tgt_id = EXCLUDED.store_tgt_id,
            delivery_state = EXCLUDED.delivery_state, obj_id = EXCLUDED.obj_id,
            promo_code = EXCLUDED.promo_code,
            is_paid = EXCLUDED.is_paid, is_task_assigned = EXCLUDED.is_task_assigned,
            order_pay_at = EXCLUDED.order_pay_at,
            items_count = EXCLUDED.items_count, items_qty = EXCLUDED.items_qty,
            items_total = EXCLUDED.items_total,
            debt_total = EXCLUDED.debt_total, debt_paid = EXCLUDED.debt_paid,
            debt_unpaid = EXCLUDED.debt_unpaid,
            total_taxes = EXCLUDED.total_taxes, total_discounts = EXCLUDED.total_discounts,
            total_interest = EXCLUDED.total_interest, total_paid = EXCLUDED.total_paid,
            total_unpaid = EXCLUDED.total_unpaid, total = EXCLUDED.total,
            stock_line_count = EXCLUDED.stock_line_count, stock_qty_in = EXCLUDED.stock_qty_in,
            stock_qty_out = EXCLUDED.stock_qty_out,
            acc_line_count = EXCLUDED.acc_line_count, acc_sum = EXCLUDED.acc_sum,
            acc_balanced = EXCLUDED.acc_balanced, has_manual_lines = EXCLUDED.has_manual_lines,
            generated_count = EXCLUDED.generated_count, manual_count = EXCLUDED.manual_count,
            tx_data_json = EXCLUDED.tx_data_json, updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(tx.site_iid)
    .bind(tx.tx_id)
    .bind(owner_iid)
    .bind(tx_type_str(ty))
    .bind(tx_state_str(state))
    .bind(tx_input_mode_str(input_mode))
    .bind(tx_input_source_str(input_source))
    .bind(tx.is_archived)
    .bind(&tx.desc)
    .bind(time_ts)
    .bind(created_by)
    .bind(cancel_reason)
    .bind(tx.subject_contact_id)
    .bind(&tx.subject_name)
    .bind(&tx.subject_phone)
    .bind(&tx.subject_address)
    .bind(&tx.cashier_name)
    .bind(tx.store_id)
    .bind(tx.store_tgt_id)
    .bind(&tx.delivery_state)
    .bind(tx.obj_id)
    .bind(&tx.promo_code)
    .bind(tx.is_paid)
    .bind(tx.is_task_assigned)
    .bind(tx_order_pay_at_str(order_pay_at))
    .bind(tx.items_count)
    .bind(tx.items_qty)
    .bind(tx.items_total)
    .bind(tx.debt_total)
    .bind(tx.debt_paid)
    .bind(tx.debt_unpaid)
    .bind(tx.total_taxes)
    .bind(tx.total_discounts)
    .bind(tx.total_interest)
    .bind(tx.total_paid)
    .bind(tx.total_unpaid)
    .bind(tx.total)
    .bind(tx.stock_line_count)
    .bind(tx.stock_qty_in)
    .bind(tx.stock_qty_out)
    .bind(tx.acc_line_count)
    .bind(tx.acc_sum)
    .bind(tx.acc_balanced)
    .bind(tx.has_manual_lines)
    .bind(generated_count)
    .bind(manual_count)
    .bind(tx_data_json)
    .execute(&mut *conn)
    .await?;
    Ok(())
}

pub async fn tx_children_put(conn: &mut PgConnection, tx: &mut Tx) -> Result<()> {
    let site_iid = tx.site_iid;
    let tx_id = tx.tx_id;
    tx_items_ensure_ids(tx);
    for item in &tx.items {
        let fulfillment = c35_proto::TxItemFulfillmentState::try_from(item.fulfillment_state)
            .unwrap_or(c35_proto::TxItemFulfillmentState::TxItemFulfillmentUnspecified);
        let item_owner_iid = if item.owner_iid > 0 { item.owner_iid } else { site_iid };
        sqlx::query(
            r#"
            INSERT INTO site.tx_item (
                site_iid, tx_id, item_id, owner_iid, obj_id, product_id, product_rev, price, qty, note,
                batch_number, serial_number, fulfillment_state,
                total_qty, total_price, total_discount, total_tax, total_net,
                total_paid, total_unpaid, created_ts, updated_ts
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
                $11, $12, $13,
                $14, $15, $16, $17, $18,
                $19, $20, NOW(), NOW()
            )
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .bind(item.item_id)
        .bind(item_owner_iid)
        .bind(item.obj_id)
        .bind(item.product_id)
        .bind(item.product_rev)
        .bind(item.price)
        .bind(item.qty)
        .bind(&item.note)
        .bind(&item.batch_number)
        .bind(&item.serial_number)
        .bind(tx_fulfillment_str(fulfillment))
        .bind(item.total_qty)
        .bind(item.total_price)
        .bind(item.total_discount)
        .bind(item.total_tax)
        .bind(item.total_net)
        .bind(item.total_paid)
        .bind(item.total_unpaid)
        .execute(&mut *conn)
        .await?;
        for src in &item.sources {
            let src_id = if src.src_id > 0 { src.src_id } else { snowflake_id() };
            sqlx::query(
                r#"
                INSERT INTO site.tx_item_source (
                    site_iid, tx_id, item_id, src_id, obj_id, product_id, qty, note, created_ts, updated_ts
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
                "#,
            )
            .bind(site_iid)
            .bind(tx_id)
            .bind(item.item_id)
            .bind(src_id)
            .bind(src.obj_id)
            .bind(src.product_id)
            .bind(src.qty)
            .bind(&src.note)
            .execute(&mut *conn)
            .await?;
        }
        for res in &item.reservations {
            let res_id = if res.res_id > 0 { res.res_id } else { snowflake_id() };
            sqlx::query(
                r#"
                INSERT INTO site.tx_item_reservation (
                    site_iid, tx_id, item_id, res_id, product_id, qty, duration_qty, note,
                    start_ts, end_ts, state, is_no_show, is_unavailable, created_ts, updated_ts
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NOW())
                "#,
            )
            .bind(site_iid)
            .bind(tx_id)
            .bind(item.item_id)
            .bind(res_id)
            .bind(res.product_id)
            .bind(res.qty)
            .bind(res.duration_qty)
            .bind(&res.note)
            .bind(ts_from_ms(res.start_ts_ms))
            .bind(ts_from_ms(res.end_ts_ms))
            .bind(&res.state)
            .bind(res.is_no_show)
            .bind(res.is_unavailable)
            .execute(&mut *conn)
            .await?;
        }
    }
    for p in &mut tx.payments {
        let payment_id = if p.payment_id > 0 { p.payment_id } else { snowflake_id() };
        p.payment_id = payment_id;
        let method = c35_proto::TxPaymentMethod::try_from(p.method)
            .unwrap_or(c35_proto::TxPaymentMethod::Unspecified);
        let payment_json: serde_json::Value = if p.payment_json.is_empty() {
            serde_json::json!({})
        } else {
            serde_json::from_str(&p.payment_json).unwrap_or(serde_json::json!({}))
        };
        sqlx::query(
            r#"
            INSERT INTO site.tx_payment (
                site_iid, tx_id, payment_id, method, ts, amount, note,
                from_wallet, to_wallet, debt_interest, payment_json, created_ts, updated_ts
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .bind(payment_id)
        .bind(tx_payment_method_str(method))
        .bind(ts_from_ms(p.ts_ms).unwrap_or_else(chrono::Utc::now))
        .bind(p.amount)
        .bind(&p.note)
        .bind(&p.from_wallet)
        .bind(&p.to_wallet)
        .bind(p.debt_interest)
        .bind(payment_json)
        .execute(&mut *conn)
        .await?;
        for inst in &mut p.installments {
            let inst_id = if inst.inst_id > 0 { inst.inst_id } else { snowflake_id() };
            inst.inst_id = inst_id;
            sqlx::query(
                r#"
                INSERT INTO site.tx_installment (
                    site_iid, tx_id, payment_id, inst_id, due_ts, amount, note,
                    is_paid, is_overdue, created_ts, updated_ts
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
                "#,
            )
            .bind(site_iid)
            .bind(tx_id)
            .bind(payment_id)
            .bind(inst_id)
            .bind(ts_from_ms(inst.due_ts_ms))
            .bind(inst.amount)
            .bind(&inst.note)
            .bind(inst.is_paid)
            .bind(inst.is_overdue)
            .execute(&mut *conn)
            .await?;
            for dp in &mut inst.debt_payments {
                let pay_id = if dp.pay_id > 0 { dp.pay_id } else { snowflake_id() };
                dp.pay_id = pay_id;
                let dp_method = c35_proto::TxDebtPaymentMethod::try_from(dp.method)
                    .unwrap_or(c35_proto::TxDebtPaymentMethod::Unspecified);
                let dp_json: serde_json::Value = if dp.payment_json.is_empty() {
                    serde_json::json!({})
                } else {
                    serde_json::from_str(&dp.payment_json).unwrap_or(serde_json::json!({}))
                };
                sqlx::query(
                    r#"
                    INSERT INTO site.tx_debt_payment (
                        site_iid, tx_id, payment_id, inst_id, pay_id, ts, method, amount, note,
                        overdue_interest, payment_json, is_paid, is_overdue, created_ts, updated_ts
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NOW())
                    "#,
                )
                .bind(site_iid)
                .bind(tx_id)
                .bind(payment_id)
                .bind(inst_id)
                .bind(pay_id)
                .bind(ts_from_ms(dp.ts_ms).unwrap_or_else(chrono::Utc::now))
                .bind(tx_debt_payment_method_str(dp_method))
                .bind(dp.amount)
                .bind(&dp.note)
                .bind(dp.overdue_interest)
                .bind(dp_json)
                .bind(dp.amount > 0)
                .bind(false)
                .execute(&mut *conn)
                .await?;
            }
        }
    }
    for acc in &mut tx.accs {
        let acc_id = if acc.acc_id > 0 { acc.acc_id } else { snowflake_id() };
        acc.acc_id = acc_id;
        let side = c35_proto::TxAccSide::try_from(acc.side).unwrap_or(c35_proto::TxAccSide::Unspecified);
        sqlx::query(
            r#"
            INSERT INTO site.tx_acc (
                site_iid, tx_id, acc_id, acc_code, ts, side, amount, note, is_tx_generated, created_ts, updated_ts
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .bind(acc_id)
        .bind(&acc.acc_code)
        .bind(ts_from_ms(acc.ts_ms).unwrap_or_else(chrono::Utc::now))
        .bind(tx_acc_side_str(side))
        .bind(acc.amount)
        .bind(&acc.note)
        .bind(acc.is_tx_generated)
        .execute(&mut *conn)
        .await?;
    }
    for stock in &mut tx.stocks {
        let stock_id = if stock.stock_id > 0 { stock.stock_id } else { snowflake_id() };
        stock.stock_id = stock_id;
        sqlx::query(
            r#"
            INSERT INTO site.tx_stock (
                site_iid, tx_id, stock_id, product_id, ts, obj_from_id, obj_to_id,
                qty, qty_signed, direction, note, created_ts, updated_ts
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .bind(stock_id)
        .bind(stock.product_id)
        .bind(ts_from_ms(stock.ts_ms).unwrap_or_else(chrono::Utc::now))
        .bind(stock.obj_from_id)
        .bind(stock.obj_to_id)
        .bind(stock.qty)
        .bind(stock.qty_signed)
        .bind(&stock.direction)
        .bind(&stock.note)
        .execute(&mut *conn)
        .await?;
    }
    for tax in &mut tx.taxes {
        let tax_id = if tax.tax_id > 0 { tax.tax_id } else { snowflake_id() };
        tax.tax_id = tax_id;
        sqlx::query(
            r#"
            INSERT INTO site.tx_tax (site_iid, tx_id, tax_id, tax_type, amount, note, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .bind(tax_id)
        .bind(&tax.tax_type)
        .bind(tax.amount)
        .bind(&tax.note)
        .execute(&mut *conn)
        .await?;
    }
    for disc in &mut tx.discounts {
        let discount_id = if disc.discount_id > 0 { disc.discount_id } else { snowflake_id() };
        disc.discount_id = discount_id;
        sqlx::query(
            r#"
            INSERT INTO site.tx_discount (site_iid, tx_id, discount_id, discount_type, amount, note, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
            "#,
        )
        .bind(site_iid)
        .bind(tx_id)
        .bind(discount_id)
        .bind(&disc.discount_type)
        .bind(disc.amount)
        .bind(&disc.note)
        .execute(&mut *conn)
        .await?;
    }
    Ok(())
}

fn tx_items_ensure_ids(tx: &mut Tx) {
    for item in &mut tx.items {
        if item.item_id == 0 {
            item.item_id = snowflake_id();
        }
    }
}

pub fn tx_acc_counts(tx: &Tx) -> (i32, i32) {
    let mut generated = 0i32;
    let mut manual = 0i32;
    for acc in &tx.accs {
        if acc.is_tx_generated {
            generated += 1;
        } else {
            manual += 1;
        }
    }
    (generated, manual)
}

