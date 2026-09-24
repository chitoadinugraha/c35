use c35_proto::{
    Tx, TxAcc, TxAccSide, TxDiscount, TxInstallment, TxPayment, TxPaymentMethod, TxStock, TxTax,
    TxType,
};
use chrono::Utc;
use std::collections::HashMap;

use crate::enum_map::{stock_direction_signed, tx_payment_method, tx_type};
use crate::ts::ts_from_ms;

const COA_CASH: &str = "1001";
const COA_BANK: &str = "1002";
const COA_EWALLET: &str = "1003";
const COA_AR: &str = "1100";
const COA_INVENTORY: &str = "1200";
const COA_INPUT_VAT: &str = "1400";
const COA_AP: &str = "2100";
const COA_TAX_PAYABLE: &str = "2200";
const COA_WITHHOLDING: &str = "2201";
const COA_REVENUE: &str = "4100";
const COA_SALES_DISCOUNT: &str = "4200";
const COA_PURCHASE_DISC: &str = "4210";
const COA_SALES_RETURNS: &str = "4300";
const COA_ROUNDING: &str = "6200";
const COA_INTEREST: &str = "7100";

struct AccLedger {
    amounts: HashMap<String, i64>,
    note: String,
}

impl AccLedger {
    fn new() -> Self {
        Self {
            amounts: HashMap::new(),
            note: String::new(),
        }
    }

    fn balance(&self) -> i64 {
        self.amounts.values().sum()
    }

    fn add(&mut self, code: &str, amount: i64) {
        if amount == 0 {
            return;
        }
        *self.amounts.entry(code.to_string()).or_insert(0) += amount;
    }

    fn build(&mut self, ts_ms: i64) -> Vec<TxAcc> {
        let sum = self.balance();
        if sum != 0 {
            self.add(COA_ROUNDING, -sum);
        }
        let mut out = Vec::new();
        for (code, amount) in &self.amounts {
            if *amount == 0 {
                continue;
            }
            let (side, amt) = if *amount < 0 {
                (TxAccSide::Credit, -amount)
            } else {
                (TxAccSide::Debit, *amount)
            };
            out.push(TxAcc {
                acc_code: code.clone(),
                ts_ms,
                side: side.into(),
                amount: amt,
                note: self.note.clone(),
                is_tx_generated: true,
                ..Default::default()
            });
        }
        out
    }
}

/// Recompute derived tx fields before persist or preview.
pub fn tx_finalize(tx: &mut Tx) {
    let ts_ms = tx_time_ms(tx);
    tx_compute_items(tx);
    tx_compute_totals(tx);
    tx_compute_standalone_debt(tx);
    tx_compute_debt_installments(tx, ts_ms);
    tx_compute_stock(tx, ts_ms);
    tx_compute_accs(tx, ts_ms);
    tx_compute_acc_meta(tx);
}

fn tx_time_ms(tx: &Tx) -> i64 {
    if tx.time_ts_ms > 0 {
        return tx.time_ts_ms;
    }
    if tx.created_ts_ms > 0 {
        return tx.created_ts_ms;
    }
    Utc::now().timestamp_millis()
}

fn tx_compute_items(tx: &mut Tx) {
    for item in &mut tx.items {
        let duration_multiplier: i64 = if !item.reservations.is_empty() {
            item.reservations
                .iter()
                .map(|r| r.duration_qty.max(1) as i64)
                .sum::<i64>()
                .max(1)
        } else {
            1
        };
        let gross = item.price * (item.qty as i64) * duration_multiplier;
        item.total_qty = item.qty * (duration_multiplier as i32);
        item.total_price = gross;
        if item.total_discount == 0 && item.total_tax == 0 {
            item.total_net = gross;
        }
        let _allocated: i32 = item.sources.iter().map(|s| s.qty).sum();
    }
}

fn tx_compute_totals(tx: &mut Tx) {
    let mut count = 0i64;
    let mut qty = 0i64;
    let mut items_total = 0i64;
    for item in &tx.items {
        count += 1;
        qty += item.qty as i64;
        let net = if item.total_net != 0 {
            item.total_net
        } else {
            item.price * item.qty as i64
        };
        items_total += net;
    }
    tx.items_count = count;
    tx.items_qty = qty;
    tx.items_total = items_total;

    let tax_sum = tx.taxes.iter().map(|t| t.amount).sum();
    let disc_sum = tx.discounts.iter().map(|d| d.amount).sum();
    tx.total_taxes = tax_sum;
    tx.total_discounts = disc_sum;

    let mut paid = 0i64;
    let mut debt_total = 0i64;
    let mut debt_paid = 0i64;
    let mut interest = 0i64;
    for p in &tx.payments {
        paid += p.amount;
        if tx_payment_method(p.method) != TxPaymentMethod::Debt {
            continue;
        }
        interest += p.debt_interest;
        for inst in &p.installments {
            debt_total += inst.amount;
            debt_paid += inst_paid(inst);
        }
    }
    tx.total_paid = paid;
    tx.total_interest = interest;
    tx.debt_total = debt_total;
    tx.debt_paid = debt_paid;
    tx.debt_unpaid = debt_total - debt_paid;
    tx.is_paid = tx.debt_unpaid <= 0;
    let net = items_total + tax_sum - disc_sum + interest;
    tx.total = net;
    let unpaid = (net - paid).max(0);
    tx.total_unpaid = unpaid;
}

fn tx_compute_standalone_debt(tx: &mut Tx) {
    let ty = tx_type(tx.r#type);
    if !matches!(ty, TxType::DebtPayable | TxType::DebtReceivable) {
        return;
    }
    if tx.debt_total > 0 {
        return;
    }
    let total = tx.total;
    if total <= 0 {
        return;
    }
    tx.debt_total = total;
    tx.debt_unpaid = (total - tx.debt_paid).max(0);
    tx.is_paid = tx.debt_unpaid <= 0;
}

fn inst_paid(inst: &TxInstallment) -> i64 {
    inst.debt_payments.iter().map(|p| p.amount).sum()
}

fn tx_compute_debt_installments(tx: &mut Tx, ts_ms: i64) {
    let now = ts_from_ms(ts_ms).unwrap_or_else(Utc::now);
    for p in &mut tx.payments {
        if tx_payment_method(p.method) != TxPaymentMethod::Debt {
            continue;
        }
        let due_default = if p.ts_ms > 0 { p.ts_ms } else { ts_ms };
        for inst in &mut p.installments {
            if inst.due_ts_ms == 0 {
                inst.due_ts_ms = due_default;
            }
            let paid = inst_paid(inst);
            inst.is_paid = inst.amount > 0 && paid >= inst.amount;
            inst.is_overdue = !inst.is_paid
                && inst.due_ts_ms > 0
                && ts_from_ms(inst.due_ts_ms).map(|d| d < now).unwrap_or(false);
        }
    }
}

fn tx_compute_stock(tx: &mut Tx, ts_ms: i64) {
    tx.stocks.clear();
    let ty = tx_type(tx.r#type);
    let store = tx.store_id;
    match ty {
        TxType::Sale | TxType::ReturnSale | TxType::Reservation => {
            let dir = if ty == TxType::ReturnSale { "in" } else { "out" };
            tx_append_item_stocks(tx, ts_ms, store, dir);
        }
        TxType::ReturnPurchase => {
            tx_append_item_stocks(tx, ts_ms, store, "out");
        }
        TxType::Purchase | TxType::Inventory => {
            for item in &tx.items {
                if item.qty == 0 {
                    continue;
                }
                let obj_to = item.sources.first().map(|s| s.obj_id).unwrap_or(store);
                tx.stocks.push(TxStock {
                    product_id: item.product_id,
                    ts_ms,
                    obj_to_id: obj_to,
                    qty: item.qty,
                    direction: "in".into(),
                    qty_signed: item.qty,
                    ..Default::default()
                });
            }
        }
        TxType::Transfer | TxType::Ship => {
            for item in &tx.items {
                if item.qty == 0 {
                    continue;
                }
                tx.stocks.push(TxStock {
                    product_id: item.product_id,
                    ts_ms,
                    obj_from_id: store,
                    obj_to_id: tx.store_tgt_id,
                    qty: item.qty,
                    direction: "transfer".into(),
                    qty_signed: 0,
                    ..Default::default()
                });
            }
        }
        TxType::Adjustment => {
            for item in &tx.items {
                if item.qty == 0 {
                    continue;
                }
                let (dir, qty) = if item.qty < 0 {
                    ("out", -item.qty)
                } else {
                    ("in", item.qty)
                };
                tx.stocks.push(TxStock {
                    product_id: item.product_id,
                    ts_ms,
                    obj_from_id: store,
                    qty,
                    direction: dir.into(),
                    qty_signed: stock_direction_signed(dir, qty),
                    ..Default::default()
                });
            }
        }
        _ => {}
    }
    let mut qty_in = 0i32;
    let mut qty_out = 0i32;
    for s in &mut tx.stocks {
        match s.direction.as_str() {
            "in" => qty_in += s.qty,
            "out" => qty_out += s.qty,
            "transfer" => {
                qty_out += s.qty;
                qty_in += s.qty;
            }
            _ => {}
        }
        s.qty_signed = stock_direction_signed(&s.direction, s.qty);
    }
    tx.stock_line_count = tx.stocks.len() as i32;
    tx.stock_qty_in = qty_in;
    tx.stock_qty_out = qty_out;
}

fn tx_append_item_stocks(tx: &mut Tx, ts_ms: i64, store: i64, dir: &str) {
    for item in &tx.items {
        if item.qty == 0 {
            continue;
        }
        if !item.sources.is_empty() {
            for src in &item.sources {
                if src.qty == 0 {
                    continue;
                }
                tx.stocks.push(TxStock {
                    product_id: item.product_id,
                    ts_ms,
                    obj_from_id: src.obj_id,
                    qty: src.qty,
                    direction: dir.into(),
                    qty_signed: stock_direction_signed(dir, src.qty),
                    ..Default::default()
                });
            }
            continue;
        }
        tx.stocks.push(TxStock {
            product_id: item.product_id,
            ts_ms,
            obj_from_id: store,
            qty: item.qty,
            direction: dir.into(),
            qty_signed: stock_direction_signed(dir, item.qty),
            ..Default::default()
        });
    }
}

fn tx_compute_accs(tx: &mut Tx, ts_ms: i64) {
    let manual: Vec<TxAcc> = tx
        .accs
        .iter()
        .filter(|a| !a.is_tx_generated)
        .cloned()
        .collect();
    let ty = tx_type(tx.r#type);
    if tx_acc_skip_generated(&manual, ty) {
        tx.accs = manual;
        return;
    }
    let gross = tx_items_gross(tx);
    let generated = tx_compute_generated_accs(tx, gross, ts_ms);
    tx.accs = manual;
    tx.accs.extend(generated);
}

fn tx_acc_skip_generated(manual: &[TxAcc], ty: TxType) -> bool {
    if manual.is_empty() {
        return false;
    }
    match ty {
        TxType::Payment | TxType::Receipt => tx_manual_accs_balanced(manual),
        _ => false,
    }
}

fn tx_manual_accs_balanced(accs: &[TxAcc]) -> bool {
    if accs.len() < 2 {
        return false;
    }
    accs.iter().map(acc_signed_amount).sum::<i64>() == 0
}

pub fn acc_signed_amount(a: &TxAcc) -> i64 {
    let side = TxAccSide::try_from(a.side).unwrap_or(TxAccSide::Unspecified);
    if side == TxAccSide::Credit {
        -a.amount
    } else {
        a.amount
    }
}

fn tx_items_gross(tx: &Tx) -> i64 {
    tx.items
        .iter()
        .map(|item| {
            if item.total_price != 0 {
                item.total_price
            } else {
                item.price * item.qty as i64
            }
        })
        .sum()
}

fn tx_compute_generated_accs(tx: &Tx, gross: i64, ts_ms: i64) -> Vec<TxAcc> {
    let ty = tx_type(tx.r#type);
    match ty {
        TxType::Payment => return tx_acc_cash_movement(tx, ts_ms, false),
        TxType::Receipt => return tx_acc_cash_movement(tx, ts_ms, true),
        TxType::DebtReceivable => {
            let amount = tx_debt_principal(tx);
            if amount > 0 {
                let mut ledger = AccLedger::new();
                ledger.note = tx_acc_generated_note(tx);
                tx_acc_standalone_debt_receivable(&mut ledger, amount);
                return ledger.build(ts_ms);
            }
            return vec![];
        }
        TxType::DebtPayable => {
            let amount = tx_debt_principal(tx);
            if amount > 0 {
                let mut ledger = AccLedger::new();
                ledger.note = tx_acc_generated_note(tx);
                tx_acc_standalone_debt_payable(&mut ledger, amount);
                return ledger.build(ts_ms);
            }
            return vec![];
        }
        _ => {}
    }
    let mut ledger = AccLedger::new();
    ledger.note = tx_acc_generated_note(tx);
    match ty {
        TxType::Sale | TxType::ReturnSale | TxType::Reservation => {
            tx_acc_sale_or_return(tx, &mut ledger, gross, ty == TxType::ReturnSale);
        }
        TxType::Purchase | TxType::ReturnPurchase => {
            tx_acc_purchase(tx, &mut ledger, gross, ty == TxType::ReturnPurchase);
        }
        _ => {
            if gross != 0 {
                tx_acc_revenue_line(&mut ledger, gross, false, false);
            }
        }
    }
    ledger.build(ts_ms)
}

fn tx_acc_generated_note(tx: &Tx) -> String {
    let ty = tx_type(tx.r#type);
    let label = tx_acc_type_label(ty);
    let subject = tx.subject_name.trim();
    let base = if subject.is_empty() {
        label.clone()
    } else {
        format!("{} {} {}", label, tx_acc_subject_prep(ty), subject)
    };
    let desc = tx.desc.trim();
    if desc.is_empty() || desc.eq_ignore_ascii_case(&base) || desc.eq_ignore_ascii_case(subject) {
        base
    } else {
        format!("{} · {}", base, desc)
    }
}

fn tx_acc_type_label(ty: TxType) -> String {
    match ty {
        TxType::Sale => "Penjualan".into(),
        TxType::Purchase => "Pembelian".into(),
        TxType::Transfer => "Transfer".into(),
        TxType::Adjustment => "Penyesuaian".into(),
        TxType::ReturnSale => "Retur Jual".into(),
        TxType::ReturnPurchase => "Retur Beli".into(),
        TxType::Reservation => "Reservasi".into(),
        TxType::Ship => "Kirim".into(),
        TxType::Payment => "Pembayaran".into(),
        TxType::Receipt => "Penerimaan".into(),
        TxType::DebtPayable => "Hutang".into(),
        TxType::DebtReceivable => "Piutang".into(),
        TxType::Inventory => "Persediaan".into(),
        _ => "Transaksi".into(),
    }
}

fn tx_acc_subject_prep(ty: TxType) -> &'static str {
    match ty {
        TxType::Purchase | TxType::ReturnPurchase | TxType::Receipt => "dari",
        _ => "ke",
    }
}

fn tx_acc_sale_or_return(tx: &Tx, ledger: &mut AccLedger, gross: i64, is_return: bool) {
    if gross != 0 {
        tx_acc_revenue_line(ledger, gross, is_return, false);
    }
    for d in &tx.discounts {
        ledger_add_discount(ledger, d, false);
    }
    for t in &tx.taxes {
        ledger_add_tax(ledger, t, false);
    }
    tx_acc_payments(tx, ledger, !is_return);
    tx_balance_unpaid(tx, ledger, false, is_return);
    for p in &tx.payments {
        if tx_payment_method(p.method) != TxPaymentMethod::Debt || p.debt_interest == 0 {
            continue;
        }
        let interest = p.debt_interest;
        ledger.add(&tx_payment_acc_code(p), bool_sign(is_return, interest));
        ledger.add(COA_INTEREST, bool_sign(!is_return, interest));
    }
}

fn tx_acc_purchase(tx: &Tx, ledger: &mut AccLedger, gross: i64, is_return: bool) {
    if gross != 0 {
        let amt = if is_return { -gross } else { gross };
        ledger.add(COA_INVENTORY, amt);
    }
    for d in &tx.discounts {
        if is_return {
            ledger.add(COA_PURCHASE_DISC, d.amount);
        } else {
            ledger_add_discount(ledger, d, true);
        }
    }
    for t in &tx.taxes {
        if is_return {
            let code = tx_tax_acc_code(t, true);
            let sign = if code == COA_INPUT_VAT { 1 } else { -1 };
            ledger.add(code, -t.amount * sign);
        } else {
            ledger_add_tax(ledger, t, true);
        }
    }
    tx_acc_payments(tx, ledger, is_return);
    tx_balance_unpaid(tx, ledger, true, is_return);
}

fn tx_debt_principal(tx: &Tx) -> i64 {
    if tx.debt_total > 0 {
        return tx.debt_total;
    }
    let sum = tx
        .payments
        .iter()
        .filter(|p| tx_payment_method(p.method) == TxPaymentMethod::Debt)
        .map(|p| p.amount)
        .sum();
    if sum > 0 {
        return sum;
    }
    tx.total
}

fn tx_acc_standalone_debt_receivable(ledger: &mut AccLedger, amount: i64) {
    tx_acc_revenue_line(ledger, amount, false, false);
    ledger.add(COA_AR, amount);
}

fn tx_acc_standalone_debt_payable(ledger: &mut AccLedger, amount: i64) {
    ledger.add(COA_INVENTORY, amount);
    ledger.add(COA_AP, -amount);
}

fn tx_balance_unpaid(_tx: &Tx, ledger: &mut AccLedger, purchase: bool, is_return: bool) {
    let remaining = ledger.balance();
    if remaining == 0 {
        return;
    }
    if purchase {
        ledger.add(COA_AP, bool_sign(is_return, remaining));
    } else {
        ledger.add(COA_AR, bool_sign(is_return, remaining));
    }
}

fn tx_acc_revenue_line(ledger: &mut AccLedger, gross: i64, is_return: bool, purchase: bool) {
    if purchase {
        return;
    }
    let code = if is_return { COA_SALES_RETURNS } else { COA_REVENUE };
    ledger.add(code, bool_sign(is_return, gross));
}

fn tx_acc_payments(tx: &Tx, ledger: &mut AccLedger, inflow: bool) {
    for p in &tx.payments {
        if p.amount == 0 {
            continue;
        }
        let amt = if inflow { p.amount } else { -p.amount };
        ledger.add(&tx_payment_acc_code(p), amt);
    }
}

fn bool_sign(is_return: bool, amount: i64) -> i64 {
    if is_return { amount } else { -amount }
}

fn ledger_add_tax(ledger: &mut AccLedger, t: &TxTax, purchase: bool) {
    let code = tx_tax_acc_code(t, purchase);
    let sign = if purchase && code == COA_INPUT_VAT { 1 } else { -1 };
    ledger.add(code, t.amount * sign);
}

fn ledger_add_discount(ledger: &mut AccLedger, d: &TxDiscount, purchase: bool) {
    let code = if purchase { COA_PURCHASE_DISC } else { COA_SALES_DISCOUNT };
    let amt = if purchase { -d.amount } else { d.amount };
    ledger.add(code, amt);
}

fn tx_tax_acc_code(t: &TxTax, purchase: bool) -> &'static str {
    let typ = t.tax_type.to_lowercase();
    if typ.contains("pph") || typ.contains("withhold") {
        return COA_WITHHOLDING;
    }
    if typ.contains("masukan") || typ.contains("input") {
        return COA_INPUT_VAT;
    }
    if purchase {
        COA_INPUT_VAT
    } else {
        COA_TAX_PAYABLE
    }
}

fn tx_acc_cash_movement(tx: &Tx, ts_ms: i64, receipt: bool) -> Vec<TxAcc> {
    let amount = tx_cash_movement_amount(tx);
    if amount <= 0 {
        return vec![];
    }
    let mut ledger = AccLedger::new();
    ledger.note = tx_acc_generated_note(tx);
    let cash_code = tx_cash_acc_code(tx);
    if receipt {
        ledger.add(&cash_code, amount);
        ledger.add(COA_AR, -amount);
    } else {
        ledger.add(COA_AP, amount);
        ledger.add(&cash_code, -amount);
    }
    ledger.build(ts_ms)
}

fn tx_cash_movement_amount(tx: &Tx) -> i64 {
    for p in &tx.payments {
        if tx_payment_method(p.method) != TxPaymentMethod::Debt && p.amount > 0 {
            return p.amount;
        }
    }
    if tx.total > 0 {
        return tx.total;
    }
    tx_debt_principal(tx)
}

fn tx_cash_acc_code(tx: &Tx) -> String {
    tx.payments
        .iter()
        .find(|p| p.amount != 0)
        .map(tx_payment_acc_code)
        .unwrap_or_else(|| COA_CASH.to_string())
}

fn tx_payment_acc_code(p: &TxPayment) -> String {
    match tx_payment_method(p.method) {
        TxPaymentMethod::Cash => COA_CASH.to_string(),
        TxPaymentMethod::Card | TxPaymentMethod::Transfer => COA_BANK.to_string(),
        TxPaymentMethod::Qris => COA_EWALLET.to_string(),
        TxPaymentMethod::Debt => COA_AR.to_string(),
        _ => COA_CASH.to_string(),
    }
}

fn tx_compute_acc_meta(tx: &mut Tx) {
    let mut sum = 0i64;
    let mut manual = 0i32;
    for acc in &tx.accs {
        sum += acc_signed_amount(acc);
        if !acc.is_tx_generated {
            manual += 1;
        }
    }
    tx.acc_line_count = tx.accs.len() as i32;
    tx.acc_sum = sum;
    tx.acc_balanced = sum == 0;
    tx.has_manual_lines = manual > 0;
}

pub fn tx_preview_coa_names(accs: &[TxAcc]) -> HashMap<String, String> {
    static LABELS: &[(&str, &str)] = &[
        (COA_CASH, "Kas"),
        (COA_BANK, "Bank"),
        (COA_EWALLET, "E-Wallet"),
        (COA_AR, "Piutang"),
        (COA_INVENTORY, "Persediaan"),
        (COA_INPUT_VAT, "PPN Masukan"),
        (COA_AP, "Hutang"),
        (COA_TAX_PAYABLE, "PPN Keluaran"),
        (COA_REVENUE, "Pendapatan"),
        (COA_SALES_DISCOUNT, "Diskon Penjualan"),
        (COA_SALES_RETURNS, "Retur Penjualan"),
        (COA_ROUNDING, "Pembulatan"),
        (COA_INTEREST, "Bunga"),
    ];
    let mut out = HashMap::new();
    for acc in accs {
        let code = acc.acc_code.trim();
        if code.is_empty() || out.contains_key(code) {
            continue;
        }
        let name = LABELS
            .iter()
            .find(|(c, _)| *c == code)
            .map(|(_, n)| n.to_string())
            .unwrap_or_else(|| code.to_string());
        out.insert(code.to_string(), name);
    }
    out
}

#[cfg(test)]
pub fn tx_finalize_test_sale() -> Tx {
    use c35_proto::{TxItem, TxState};
    let mut tx = Tx {
        site_iid: 1,
        r#type: i32::from(TxType::Sale),
        state: i32::from(TxState::Ok),
        store_id: 10,
        items: vec![TxItem {
            product_id: 100,
            price: 5000,
            qty: 2,
            ..Default::default()
        }],
        payments: vec![TxPayment {
            method: i32::from(TxPaymentMethod::Cash),
            amount: 10000,
            ..Default::default()
        }],
        ..Default::default()
    };
    tx_finalize(&mut tx);
    tx
}
