use c35_proto::{
    Tx, TxAcc, TxDebtPayment, TxDiscount, TxInstallment, TxItem, TxItemReservation, TxItemSource,
    TxPayment, TxStock, TxTax,
};
use sqlx::Row;

use crate::enum_map::{
    tx_acc_side_from_str, tx_debt_payment_method_from_str, tx_fulfillment_from_str,
    tx_input_mode_from_str, tx_input_source_from_str, tx_order_pay_at_from_str,
    tx_payment_method_from_str, tx_state_from_str, tx_type_from_str,
};
use crate::ts::ts_ms;

pub fn tx_header_from_row(r: &sqlx::postgres::PgRow) -> Tx {
    let tx_data_json: serde_json::Value = r.get("tx_data_json");
    let tx_data = crate::tx_data::tx_data_from_json(&tx_data_json);
    Tx {
        site_iid: r.get("site_iid"),
        tx_id: r.get("tx_id"),
        r#type: i32::from(tx_type_from_str(&r.get::<String, _>("ty"))),
        state: i32::from(tx_state_from_str(&r.get::<String, _>("state"))),
        input_mode: i32::from(tx_input_mode_from_str(&r.get::<String, _>("input_mode"))),
        input_source: i32::from(tx_input_source_from_str(&r.get::<String, _>("input_source"))),
        is_archived: r.get("is_archived"),
        desc: r.get("desc"),
        time_ts_ms: ts_ms(Some(r.get("time_ts"))),
        created_by_iid: r.get::<Option<i64>, _>("created_by_iid").unwrap_or(0),
        cancel_reason: r.get::<Option<String>, _>("cancel_reason").unwrap_or_default(),
        subject_contact_id: r.get("subject_contact_id"),
        subject_name: r.get("subject_name"),
        subject_phone: r.get("subject_phone"),
        subject_address: r.get("subject_address"),
        cashier_name: r.get("cashier_name"),
        store_id: r.get("store_id"),
        store_tgt_id: r.get("store_tgt_id"),
        delivery_state: r.get("delivery_state"),
        obj_id: r.get("obj_id"),
        promo_code: r.get("promo_code"),
        is_paid: r.get("is_paid"),
        is_task_assigned: r.get("is_task_assigned"),
        order_pay_at: i32::from(tx_order_pay_at_from_str(&r.get::<String, _>("order_pay_at"))),
        items_count: r.get("items_count"),
        items_qty: r.get("items_qty"),
        items_total: r.get("items_total"),
        debt_total: r.get("debt_total"),
        debt_paid: r.get("debt_paid"),
        debt_unpaid: r.get("debt_unpaid"),
        total_taxes: r.get("total_taxes"),
        total_discounts: r.get("total_discounts"),
        total_interest: r.get("total_interest"),
        total_paid: r.get("total_paid"),
        total_unpaid: r.get("total_unpaid"),
        total: r.get("total"),
        stock_line_count: r.get("stock_line_count"),
        stock_qty_in: r.get("stock_qty_in"),
        stock_qty_out: r.get("stock_qty_out"),
        acc_line_count: r.get("acc_line_count"),
        acc_sum: r.get("acc_sum"),
        acc_balanced: r.get("acc_balanced"),
        has_manual_lines: r.get("has_manual_lines"),
        tx_data,
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        ..Default::default()
    }
}

pub fn tx_item_from_row(r: &sqlx::postgres::PgRow) -> TxItem {
    TxItem {
        site_iid: r.get("site_iid"),
        tx_id: r.get("tx_id"),
        item_id: r.get("item_id"),
        product_id: r.get("product_id"),
        product_rev: r.get("product_rev"),
        price: r.get("price"),
        qty: r.get("qty"),
        note: r.get("note"),
        batch_number: r.get("batch_number"),
        serial_number: r.get("serial_number"),
        fulfillment_state: i32::from(tx_fulfillment_from_str(&r.get::<String, _>("fulfillment_state"))),
        total_qty: r.get("total_qty"),
        total_price: r.get("total_price"),
        total_discount: r.get("total_discount"),
        total_tax: r.get("total_tax"),
        total_net: r.get("total_net"),
        total_paid: r.get("total_paid"),
        total_unpaid: r.get("total_unpaid"),
        ..Default::default()
    }
}

pub fn tx_item_source_from_row(r: &sqlx::postgres::PgRow) -> TxItemSource {
    TxItemSource {
        src_id: r.get("src_id"),
        obj_id: r.get("obj_id"),
        product_id: r.get("product_id"),
        qty: r.get("qty"),
        note: r.get("note"),
    }
}

pub fn tx_item_reservation_from_row(r: &sqlx::postgres::PgRow) -> TxItemReservation {
    TxItemReservation {
        res_id: r.get("res_id"),
        product_id: r.get("product_id"),
        qty: r.get("qty"),
        duration_qty: r.get("duration_qty"),
        note: r.get("note"),
        start_ts_ms: ts_ms(r.get("start_ts")),
        end_ts_ms: ts_ms(r.get("end_ts")),
        state: r.get("state"),
        is_no_show: r.get("is_no_show"),
        is_unavailable: r.get("is_unavailable"),
    }
}

pub fn tx_payment_from_row(r: &sqlx::postgres::PgRow) -> TxPayment {
    let payment_json: serde_json::Value = r.get("payment_json");
    TxPayment {
        payment_id: r.get("payment_id"),
        method: i32::from(tx_payment_method_from_str(&r.get::<String, _>("method"))),
        ts_ms: ts_ms(Some(r.get("ts"))),
        amount: r.get("amount"),
        note: r.get("note"),
        from_wallet: r.get("from_wallet"),
        to_wallet: r.get("to_wallet"),
        debt_interest: r.get("debt_interest"),
        payment_json: payment_json.to_string(),
        ..Default::default()
    }
}

pub fn tx_installment_from_row(r: &sqlx::postgres::PgRow) -> TxInstallment {
    TxInstallment {
        inst_id: r.get("inst_id"),
        due_ts_ms: ts_ms(r.get("due_ts")),
        amount: r.get("amount"),
        note: r.get("note"),
        is_paid: r.get("is_paid"),
        is_overdue: r.get("is_overdue"),
        ..Default::default()
    }
}

pub fn tx_debt_payment_from_row(r: &sqlx::postgres::PgRow) -> TxDebtPayment {
    let payment_json: serde_json::Value = r.get("payment_json");
    TxDebtPayment {
        pay_id: r.get("pay_id"),
        ts_ms: ts_ms(Some(r.get("ts"))),
        method: i32::from(tx_debt_payment_method_from_str(&r.get::<String, _>("method"))),
        amount: r.get("amount"),
        note: r.get("note"),
        overdue_interest: r.get("overdue_interest"),
        payment_json: payment_json.to_string(),
    }
}

pub fn tx_acc_from_row(r: &sqlx::postgres::PgRow) -> TxAcc {
    TxAcc {
        acc_id: r.get("acc_id"),
        acc_code: r.get("acc_code"),
        ts_ms: ts_ms(Some(r.get("ts"))),
        side: i32::from(tx_acc_side_from_str(&r.get::<String, _>("side"))),
        amount: r.get("amount"),
        note: r.get("note"),
        is_tx_generated: r.get("is_tx_generated"),
    }
}

pub fn tx_stock_from_row(r: &sqlx::postgres::PgRow) -> TxStock {
    TxStock {
        stock_id: r.get("stock_id"),
        product_id: r.get("product_id"),
        ts_ms: ts_ms(Some(r.get("ts"))),
        obj_from_id: r.get("obj_from_id"),
        obj_to_id: r.get("obj_to_id"),
        qty: r.get("qty"),
        qty_signed: r.get("qty_signed"),
        direction: r.get("direction"),
        note: r.get("note"),
    }
}

pub fn tx_tax_from_row(r: &sqlx::postgres::PgRow) -> TxTax {
    TxTax {
        tax_id: r.get("tax_id"),
        tax_type: r.get("tax_type"),
        amount: r.get("amount"),
        note: r.get("note"),
    }
}

pub fn tx_discount_from_row(r: &sqlx::postgres::PgRow) -> TxDiscount {
    TxDiscount {
        discount_id: r.get("discount_id"),
        discount_type: r.get("discount_type"),
        amount: r.get("amount"),
        note: r.get("note"),
    }
}
