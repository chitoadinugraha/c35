use anyhow::{anyhow, Result};
use c35_proto::{
    Tx, TxAcc, TxDebtPayment, TxDiscount, TxInstallment, TxItem, TxItemReservation, TxItemSource,
    TxPayment, TxStock, TxTax,
};
use serde_json::{json, Value};

use crate::enum_map::{
    tx_acc_side_from_str, tx_acc_side_str, tx_debt_payment_method_from_str, tx_debt_payment_method_str,
    tx_fulfillment_from_str, tx_fulfillment_str, tx_input_mode_from_str, tx_input_mode_str,
    tx_input_source_from_str, tx_input_source_str, tx_order_pay_at_from_str, tx_order_pay_at_str,
    tx_payment_method_from_str, tx_payment_method_str, tx_state, tx_state_from_str, tx_state_str,
    tx_type, tx_type_from_str, tx_type_str,
};
use crate::tx_data::{tx_data_from_json, tx_data_to_json};

fn i64_field(v: &Value, key: &str) -> i64 {
    v.get(key).and_then(|x| x.as_i64()).unwrap_or(0)
}

fn i32_field(v: &Value, key: &str) -> i32 {
    v.get(key).and_then(|x| x.as_i64()).map(|n| n as i32).unwrap_or(0)
}

fn bool_field(v: &Value, key: &str) -> bool {
    v.get(key).and_then(|x| x.as_bool()).unwrap_or(false)
}

fn str_field(v: &Value, key: &str) -> String {
    v.get(key).and_then(|x| x.as_str()).unwrap_or("").to_string()
}

fn enum_i32<T>(v: &Value, key: &str, from_str: fn(&str) -> T, from_i32: fn(i32) -> T) -> i32
where
    T: Into<i32>,
{
    match v.get(key) {
        Some(Value::String(s)) => from_str(s).into(),
        Some(Value::Number(n)) => from_i32(n.as_i64().unwrap_or(0) as i32).into(),
        _ => from_str("").into(),
    }
}

fn tx_item_from_json(v: &Value) -> TxItem {
    let reservations = v
        .get("reservations")
        .and_then(|a| a.as_array())
        .map(|arr| {
            arr.iter()
                .map(|r| TxItemReservation {
                    res_id: i64_field(r, "res_id"),
                    product_id: i64_field(r, "product_id"),
                    qty: i32_field(r, "qty"),
                    duration_qty: i32_field(r, "duration_qty"),
                    note: str_field(r, "note"),
                    start_ts_ms: i64_field(r, "start_ts_ms"),
                    end_ts_ms: i64_field(r, "end_ts_ms"),
                    state: str_field(r, "state"),
                    is_no_show: bool_field(r, "is_no_show"),
                    is_unavailable: bool_field(r, "is_unavailable"),
                })
                .collect()
        })
        .unwrap_or_default();
    let sources = v
        .get("sources")
        .and_then(|a| a.as_array())
        .map(|arr| {
            arr.iter()
                .map(|s| TxItemSource {
                    src_id: i64_field(s, "src_id"),
                    obj_id: i64_field(s, "obj_id"),
                    product_id: i64_field(s, "product_id"),
                    qty: i32_field(s, "qty"),
                    note: str_field(s, "note"),
                })
                .collect()
        })
        .unwrap_or_default();
    TxItem {
        site_iid: i64_field(v, "site_iid"),
        tx_id: i64_field(v, "tx_id"),
        item_id: i64_field(v, "item_id"),
        product_id: i64_field(v, "product_id"),
        product_rev: i64_field(v, "product_rev"),
        price: i64_field(v, "price"),
        qty: i32_field(v, "qty"),
        note: str_field(v, "note"),
        batch_number: str_field(v, "batch_number"),
        serial_number: str_field(v, "serial_number"),
        fulfillment_state: enum_i32(
            v,
            "fulfillment_state",
            tx_fulfillment_from_str,
            |n| c35_proto::TxItemFulfillmentState::try_from(n).unwrap_or_default(),
        ),
        total_qty: i32_field(v, "total_qty"),
        total_price: i64_field(v, "total_price"),
        total_discount: i64_field(v, "total_discount"),
        total_tax: i64_field(v, "total_tax"),
        total_net: i64_field(v, "total_net"),
        total_paid: i64_field(v, "total_paid"),
        total_unpaid: i64_field(v, "total_unpaid"),
        reservations,
        sources,
    }
}

fn tx_item_to_json(i: &TxItem) -> Value {
    json!({
        "site_iid": i.site_iid,
        "tx_id": i.tx_id,
        "item_id": i.item_id,
        "product_id": i.product_id,
        "product_rev": i.product_rev,
        "price": i.price,
        "qty": i.qty,
        "note": i.note,
        "batch_number": i.batch_number,
        "serial_number": i.serial_number,
        "fulfillment_state": tx_fulfillment_str(c35_proto::TxItemFulfillmentState::try_from(i.fulfillment_state).unwrap_or_default()),
        "total_qty": i.total_qty,
        "total_price": i.total_price,
        "total_discount": i.total_discount,
        "total_tax": i.total_tax,
        "total_net": i.total_net,
        "total_paid": i.total_paid,
        "total_unpaid": i.total_unpaid,
        "reservations": i.reservations.iter().map(|r| json!({
            "res_id": r.res_id,
            "product_id": r.product_id,
            "qty": r.qty,
            "duration_qty": r.duration_qty,
            "note": r.note,
            "start_ts_ms": r.start_ts_ms,
            "end_ts_ms": r.end_ts_ms,
            "state": r.state,
            "is_no_show": r.is_no_show,
            "is_unavailable": r.is_unavailable,
        })).collect::<Vec<_>>(),
        "sources": i.sources.iter().map(|s| json!({
            "src_id": s.src_id,
            "obj_id": s.obj_id,
            "product_id": s.product_id,
            "qty": s.qty,
            "note": s.note,
        })).collect::<Vec<_>>(),
    })
}

fn tx_debt_payment_from_json(v: &Value) -> TxDebtPayment {
    TxDebtPayment {
        pay_id: i64_field(v, "pay_id"),
        ts_ms: i64_field(v, "ts_ms"),
        method: enum_i32(
            v,
            "method",
            tx_debt_payment_method_from_str,
            |n| c35_proto::TxDebtPaymentMethod::try_from(n).unwrap_or_default(),
        ),
        amount: i64_field(v, "amount"),
        note: str_field(v, "note"),
        overdue_interest: i64_field(v, "overdue_interest"),
        payment_json: v
            .get("payment_json")
            .map(|p| p.to_string())
            .filter(|s| !s.is_empty() && s != "null")
            .unwrap_or_default(),
    }
}

pub fn tx_debt_payment_json_parse(args: &Value) -> Result<TxDebtPayment> {
    if let Some(raw) = args.get("payment_json").and_then(|v| v.as_str()) {
        let v: Value = serde_json::from_str(raw).map_err(|e| anyhow!("invalid payment_json: {e}"))?;
        return Ok(tx_debt_payment_from_json(&v));
    }
    if let Some(p) = args.get("payment") {
        return Ok(tx_debt_payment_from_json(p));
    }
    Err(anyhow!("payment or payment_json is required"))
}

fn tx_debt_payment_to_json(p: &TxDebtPayment) -> Value {
    json!({
        "pay_id": p.pay_id,
        "ts_ms": p.ts_ms,
        "method": tx_debt_payment_method_str(c35_proto::TxDebtPaymentMethod::try_from(p.method).unwrap_or_default()),
        "amount": p.amount,
        "note": p.note,
        "overdue_interest": p.overdue_interest,
        "payment_json": p.payment_json,
    })
}

fn tx_installment_from_json(v: &Value) -> TxInstallment {
    let debt_payments = v
        .get("debt_payments")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_debt_payment_from_json).collect())
        .unwrap_or_default();
    TxInstallment {
        inst_id: i64_field(v, "inst_id"),
        due_ts_ms: i64_field(v, "due_ts_ms"),
        amount: i64_field(v, "amount"),
        note: str_field(v, "note"),
        is_paid: bool_field(v, "is_paid"),
        is_overdue: bool_field(v, "is_overdue"),
        debt_payments,
    }
}

fn tx_payment_from_json(v: &Value) -> TxPayment {
    let installments = v
        .get("installments")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_installment_from_json).collect())
        .unwrap_or_default();
    TxPayment {
        payment_id: i64_field(v, "payment_id"),
        method: enum_i32(
            v,
            "method",
            tx_payment_method_from_str,
            |n| c35_proto::TxPaymentMethod::try_from(n).unwrap_or_default(),
        ),
        ts_ms: i64_field(v, "ts_ms"),
        amount: i64_field(v, "amount"),
        note: str_field(v, "note"),
        from_wallet: str_field(v, "from_wallet"),
        to_wallet: str_field(v, "to_wallet"),
        debt_interest: i64_field(v, "debt_interest"),
        payment_json: v
            .get("payment_json")
            .map(|p| p.to_string())
            .filter(|s| !s.is_empty() && s != "null")
            .unwrap_or_default(),
        installments,
    }
}

fn tx_payment_to_json(p: &TxPayment) -> Value {
    json!({
        "payment_id": p.payment_id,
        "method": tx_payment_method_str(c35_proto::TxPaymentMethod::try_from(p.method).unwrap_or_default()),
        "ts_ms": p.ts_ms,
        "amount": p.amount,
        "note": p.note,
        "from_wallet": p.from_wallet,
        "to_wallet": p.to_wallet,
        "debt_interest": p.debt_interest,
        "payment_json": p.payment_json,
        "installments": p.installments.iter().map(|i| json!({
            "inst_id": i.inst_id,
            "due_ts_ms": i.due_ts_ms,
            "amount": i.amount,
            "note": i.note,
            "is_paid": i.is_paid,
            "is_overdue": i.is_overdue,
            "debt_payments": i.debt_payments.iter().map(tx_debt_payment_to_json).collect::<Vec<_>>(),
        })).collect::<Vec<_>>(),
    })
}

fn tx_acc_from_json(v: &Value) -> TxAcc {
    TxAcc {
        acc_id: i64_field(v, "acc_id"),
        acc_code: str_field(v, "acc_code"),
        ts_ms: i64_field(v, "ts_ms"),
        side: enum_i32(
            v,
            "side",
            tx_acc_side_from_str,
            |n| c35_proto::TxAccSide::try_from(n).unwrap_or_default(),
        ),
        amount: i64_field(v, "amount"),
        note: str_field(v, "note"),
        is_tx_generated: bool_field(v, "is_tx_generated"),
    }
}

fn tx_acc_to_json(a: &TxAcc) -> Value {
    json!({
        "acc_id": a.acc_id,
        "acc_code": a.acc_code,
        "ts_ms": a.ts_ms,
        "side": tx_acc_side_str(c35_proto::TxAccSide::try_from(a.side).unwrap_or_default()),
        "amount": a.amount,
        "note": a.note,
        "is_tx_generated": a.is_tx_generated,
    })
}

fn tx_stock_from_json(v: &Value) -> TxStock {
    TxStock {
        stock_id: i64_field(v, "stock_id"),
        product_id: i64_field(v, "product_id"),
        ts_ms: i64_field(v, "ts_ms"),
        obj_from_id: i64_field(v, "obj_from_id"),
        obj_to_id: i64_field(v, "obj_to_id"),
        qty: i32_field(v, "qty"),
        qty_signed: i32_field(v, "qty_signed"),
        direction: str_field(v, "direction"),
        note: str_field(v, "note"),
    }
}

fn tx_stock_to_json(s: &TxStock) -> Value {
    json!({
        "stock_id": s.stock_id,
        "product_id": s.product_id,
        "ts_ms": s.ts_ms,
        "obj_from_id": s.obj_from_id,
        "obj_to_id": s.obj_to_id,
        "qty": s.qty,
        "qty_signed": s.qty_signed,
        "direction": s.direction,
        "note": s.note,
    })
}

fn tx_tax_from_json(v: &Value) -> TxTax {
    TxTax {
        tax_id: i64_field(v, "tax_id"),
        tax_type: str_field(v, "tax_type"),
        amount: i64_field(v, "amount"),
        note: str_field(v, "note"),
    }
}

fn tx_discount_from_json(v: &Value) -> TxDiscount {
    TxDiscount {
        discount_id: i64_field(v, "discount_id"),
        discount_type: str_field(v, "discount_type"),
        amount: i64_field(v, "amount"),
        note: str_field(v, "note"),
    }
}

pub fn tx_from_json(v: &Value) -> Result<Tx> {
    let items = v
        .get("items")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_item_from_json).collect())
        .unwrap_or_default();
    let payments = v
        .get("payments")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_payment_from_json).collect())
        .unwrap_or_default();
    let accs = v
        .get("accs")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_acc_from_json).collect())
        .unwrap_or_default();
    let stocks = v
        .get("stocks")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_stock_from_json).collect())
        .unwrap_or_default();
    let taxes = v
        .get("taxes")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_tax_from_json).collect())
        .unwrap_or_default();
    let discounts = v
        .get("discounts")
        .and_then(|a| a.as_array())
        .map(|arr| arr.iter().map(tx_discount_from_json).collect())
        .unwrap_or_default();
    let tx_data = v.get("tx_data").and_then(tx_data_from_json);
    Ok(Tx {
        site_iid: i64_field(v, "site_iid"),
        tx_id: i64_field(v, "tx_id"),
        r#type: enum_i32(v, "type", tx_type_from_str, tx_type),
        state: enum_i32(v, "state", tx_state_from_str, tx_state),
        input_mode: enum_i32(v, "input_mode", tx_input_mode_from_str, |n| {
            c35_proto::TxInputMode::try_from(n).unwrap_or_default()
        }),
        input_source: enum_i32(v, "input_source", tx_input_source_from_str, |n| {
            c35_proto::TxInputSource::try_from(n).unwrap_or_default()
        }),
        is_archived: bool_field(v, "is_archived"),
        desc: str_field(v, "desc"),
        time_ts_ms: i64_field(v, "time_ts_ms"),
        created_by_iid: i64_field(v, "created_by_iid"),
        cancel_reason: str_field(v, "cancel_reason"),
        subject_contact_id: i64_field(v, "subject_contact_id"),
        subject_name: str_field(v, "subject_name"),
        subject_phone: str_field(v, "subject_phone"),
        subject_address: str_field(v, "subject_address"),
        cashier_name: str_field(v, "cashier_name"),
        store_id: i64_field(v, "store_id"),
        store_tgt_id: i64_field(v, "store_tgt_id"),
        delivery_state: str_field(v, "delivery_state"),
        obj_id: i64_field(v, "obj_id"),
        promo_code: str_field(v, "promo_code"),
        is_paid: bool_field(v, "is_paid"),
        is_task_assigned: bool_field(v, "is_task_assigned"),
        order_pay_at: enum_i32(v, "order_pay_at", tx_order_pay_at_from_str, |n| {
            c35_proto::TxOrderPayAt::try_from(n).unwrap_or_default()
        }),
        items_count: i64_field(v, "items_count"),
        items_qty: i64_field(v, "items_qty"),
        items_total: i64_field(v, "items_total"),
        debt_total: i64_field(v, "debt_total"),
        debt_paid: i64_field(v, "debt_paid"),
        debt_unpaid: i64_field(v, "debt_unpaid"),
        total_taxes: i64_field(v, "total_taxes"),
        total_discounts: i64_field(v, "total_discounts"),
        total_interest: i64_field(v, "total_interest"),
        total_paid: i64_field(v, "total_paid"),
        total_unpaid: i64_field(v, "total_unpaid"),
        total: i64_field(v, "total"),
        stock_line_count: i32_field(v, "stock_line_count"),
        stock_qty_in: i32_field(v, "stock_qty_in"),
        stock_qty_out: i32_field(v, "stock_qty_out"),
        acc_line_count: i32_field(v, "acc_line_count"),
        acc_sum: i64_field(v, "acc_sum"),
        acc_balanced: bool_field(v, "acc_balanced"),
        has_manual_lines: bool_field(v, "has_manual_lines"),
        tx_data,
        items,
        payments,
        accs,
        stocks,
        taxes,
        discounts,
        created_ts_ms: i64_field(v, "created_ts_ms"),
        updated_ts_ms: i64_field(v, "updated_ts_ms"),
        deleted_ts_ms: i64_field(v, "deleted_ts_ms"),
    })
}

pub fn tx_json_parse(args: &Value) -> Result<Tx> {
    if let Some(raw) = args.get("tx_json").and_then(|v| v.as_str()) {
        let v: Value = serde_json::from_str(raw).map_err(|e| anyhow!("invalid tx_json: {e}"))?;
        return tx_from_json(&v);
    }
    if let Some(tx) = args.get("tx") {
        return tx_from_json(tx);
    }
    Err(anyhow!("tx_json or tx is required"))
}

pub fn tx_to_json(tx: &Tx) -> Value {
    let mut out = serde_json::Map::new();
    out.insert("site_iid".into(), json!(tx.site_iid));
    out.insert("tx_id".into(), json!(tx.tx_id));
    out.insert("type".into(), json!(tx_type_str(tx_type(tx.r#type))));
    out.insert("state".into(), json!(tx_state_str(tx_state(tx.state))));
    out.insert(
        "input_mode".into(),
        json!(tx_input_mode_str(
            c35_proto::TxInputMode::try_from(tx.input_mode).unwrap_or_default()
        )),
    );
    out.insert(
        "input_source".into(),
        json!(tx_input_source_str(
            c35_proto::TxInputSource::try_from(tx.input_source).unwrap_or_default()
        )),
    );
    out.insert("is_archived".into(), json!(tx.is_archived));
    out.insert("desc".into(), json!(tx.desc));
    out.insert("time_ts_ms".into(), json!(tx.time_ts_ms));
    out.insert("created_by_iid".into(), json!(tx.created_by_iid));
    out.insert("cancel_reason".into(), json!(tx.cancel_reason));
    out.insert("subject_contact_id".into(), json!(tx.subject_contact_id));
    out.insert("subject_name".into(), json!(tx.subject_name));
    out.insert("subject_phone".into(), json!(tx.subject_phone));
    out.insert("subject_address".into(), json!(tx.subject_address));
    out.insert("cashier_name".into(), json!(tx.cashier_name));
    out.insert("store_id".into(), json!(tx.store_id));
    out.insert("store_tgt_id".into(), json!(tx.store_tgt_id));
    out.insert("delivery_state".into(), json!(tx.delivery_state));
    out.insert("obj_id".into(), json!(tx.obj_id));
    out.insert("promo_code".into(), json!(tx.promo_code));
    out.insert("is_paid".into(), json!(tx.is_paid));
    out.insert("is_task_assigned".into(), json!(tx.is_task_assigned));
    out.insert(
        "order_pay_at".into(),
        json!(tx_order_pay_at_str(
            c35_proto::TxOrderPayAt::try_from(tx.order_pay_at).unwrap_or_default()
        )),
    );
    out.insert("items_count".into(), json!(tx.items_count));
    out.insert("items_qty".into(), json!(tx.items_qty));
    out.insert("items_total".into(), json!(tx.items_total));
    out.insert("debt_total".into(), json!(tx.debt_total));
    out.insert("debt_paid".into(), json!(tx.debt_paid));
    out.insert("debt_unpaid".into(), json!(tx.debt_unpaid));
    out.insert("total_taxes".into(), json!(tx.total_taxes));
    out.insert("total_discounts".into(), json!(tx.total_discounts));
    out.insert("total_interest".into(), json!(tx.total_interest));
    out.insert("total_paid".into(), json!(tx.total_paid));
    out.insert("total_unpaid".into(), json!(tx.total_unpaid));
    out.insert("total".into(), json!(tx.total));
    out.insert("stock_line_count".into(), json!(tx.stock_line_count));
    out.insert("stock_qty_in".into(), json!(tx.stock_qty_in));
    out.insert("stock_qty_out".into(), json!(tx.stock_qty_out));
    out.insert("acc_line_count".into(), json!(tx.acc_line_count));
    out.insert("acc_sum".into(), json!(tx.acc_sum));
    out.insert("acc_balanced".into(), json!(tx.acc_balanced));
    out.insert("has_manual_lines".into(), json!(tx.has_manual_lines));
    if let Some(data) = tx.tx_data.as_ref() {
        out.insert("tx_data".into(), tx_data_to_json(data));
    }
    out.insert(
        "items".into(),
        Value::Array(tx.items.iter().map(tx_item_to_json).collect()),
    );
    out.insert(
        "payments".into(),
        Value::Array(tx.payments.iter().map(tx_payment_to_json).collect()),
    );
    out.insert(
        "accs".into(),
        Value::Array(tx.accs.iter().map(tx_acc_to_json).collect()),
    );
    out.insert(
        "stocks".into(),
        Value::Array(tx.stocks.iter().map(tx_stock_to_json).collect()),
    );
    out.insert(
        "taxes".into(),
        Value::Array(
            tx.taxes
                .iter()
                .map(|t| {
                    json!({
                        "tax_id": t.tax_id,
                        "tax_type": t.tax_type,
                        "amount": t.amount,
                        "note": t.note,
                    })
                })
                .collect(),
        ),
    );
    out.insert(
        "discounts".into(),
        Value::Array(
            tx.discounts
                .iter()
                .map(|d| {
                    json!({
                        "discount_id": d.discount_id,
                        "discount_type": d.discount_type,
                        "amount": d.amount,
                        "note": d.note,
                    })
                })
                .collect(),
        ),
    );
    out.insert("created_ts_ms".into(), json!(tx.created_ts_ms));
    out.insert("updated_ts_ms".into(), json!(tx.updated_ts_ms));
    out.insert("deleted_ts_ms".into(), json!(tx.deleted_ts_ms));
    Value::Object(out)
}

pub fn tx_result_json(tx: &Tx) -> Value {
    json!({
        "ok": true,
        "site_iid": tx.site_iid,
        "tx_id": tx.tx_id,
        "total": tx.total,
        "state": tx_state_str(tx_state(tx.state)),
        "tx": tx_to_json(tx),
    })
}
