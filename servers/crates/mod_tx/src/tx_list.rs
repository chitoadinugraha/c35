use anyhow::Result;
use crate::tx_owner_resolve::tx_owner_resolve;
use c35_proto::{ReqTxList, ResTxList, TxState, TxType};
use sqlx::PgPool;

use crate::enum_map::{tx_state_str, tx_type_str};
use crate::rows::tx_header_from_row;
use crate::ts::ts_from_ms;

pub async fn tx_list(pool: &PgPool, caller_iid: i64, req: ReqTxList) -> Result<ResTxList> {
    let _ = tx_owner_resolve(pool, caller_iid, req.site_iid, false).await?;
    let limit = if req.limit > 0 { req.limit.min(200) } else { 50 };
    let mut q = String::from(
        r#"
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
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    );
    let mut bind_idx = 2i32;
    if !req.include_archived {
        q.push_str(" AND is_archived = FALSE");
    }
    if TxType::try_from(req.r#type).unwrap_or(TxType::Unspecified) != TxType::Unspecified {
        q.push_str(&format!(" AND ty = ${}", bind_idx));
        bind_idx += 1;
    }
    if req.state > 0 {
        q.push_str(&format!(" AND state = ${}", bind_idx));
        bind_idx += 1;
    }
    if req.subject_contact_id > 0 {
        q.push_str(&format!(" AND subject_contact_id = ${}", bind_idx));
        bind_idx += 1;
    }
    if req.time_from_ms > 0 {
        q.push_str(&format!(" AND time_ts >= ${}", bind_idx));
        bind_idx += 1;
    }
    if req.time_to_ms > 0 {
        q.push_str(&format!(" AND time_ts <= ${}", bind_idx));
        bind_idx += 1;
    }
    if req.open_only {
        q.push_str(" AND ty = 'sale' AND state IN ('ok', 'pending', 'waiting_payment')");
    }
    if !req.q.is_empty() {
        q.push_str(&format!(" AND \"desc\" ILIKE ${}", bind_idx));
        bind_idx += 1;
    }
    if req.after_tx_id > 0 {
        q.push_str(&format!(" AND tx_id > ${}", bind_idx));
        bind_idx += 1;
    }
    q.push_str(&format!(" ORDER BY tx_id LIMIT ${}", bind_idx));

    let mut query = sqlx::query(&q).bind(req.site_iid);
    if TxType::try_from(req.r#type).unwrap_or(TxType::Unspecified) != TxType::Unspecified {
        let ty = TxType::try_from(req.r#type).unwrap_or(TxType::Unspecified);
        query = query.bind(tx_type_str(ty));
    }
    if req.state > 0 {
        let st = TxState::try_from(req.state).unwrap_or(TxState::Ok);
        query = query.bind(tx_state_str(st));
    }
    if req.subject_contact_id > 0 {
        query = query.bind(req.subject_contact_id);
    }
    if req.time_from_ms > 0 {
        query = query.bind(ts_from_ms(req.time_from_ms).unwrap_or_else(chrono::Utc::now));
    }
    if req.time_to_ms > 0 {
        query = query.bind(ts_from_ms(req.time_to_ms).unwrap_or_else(chrono::Utc::now));
    }
    if !req.q.is_empty() {
        query = query.bind(format!("%{}%", req.q));
    }
    if req.after_tx_id > 0 {
        query = query.bind(req.after_tx_id);
    }
    query = query.bind(limit);

    let rows = query.fetch_all(pool).await?;
    Ok(ResTxList {
        txs: rows.iter().map(tx_header_from_row).collect(),
    })
}
