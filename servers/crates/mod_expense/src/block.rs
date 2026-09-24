use serde_json::{json, Value};

use super::copy::{expense_log_coach, expense_log_headline};
use super::fingerprint::expense_total_minor;
use super::types::{ExpenseGlance, ExpenseReceipt};

pub fn expense_receipt_block(receipt: &ExpenseReceipt, locale: &str) -> Value {
    let total = expense_total_minor(&receipt.items);
    let headline = if receipt.headline.is_empty() {
        expense_log_headline(receipt.saved, receipt.duplicate && !receipt.saved, &receipt.items, total, locale)
    } else {
        receipt.headline.clone()
    };
    let coach = if receipt.coach.is_empty() {
        expense_log_coach(
            receipt.saved,
            total,
            receipt.today.after_minor,
            receipt.duplicate && receipt.saved,
            locale,
        )
    } else {
        receipt.coach.clone()
    };
    json!({
        "kind": "expense.receipt",
        "collapsed": true,
        "body": {
            "tx_id": receipt.tx_id,
            "headline": headline,
            "subtitle": receipt.subtitle,
            "coach": coach,
            "total_minor": receipt.total_minor,
            "currency": receipt.currency,
            "saved": receipt.saved,
            "duplicate": receipt.duplicate,
            "duplicate_reason": receipt.duplicate_reason,
            "photo_hash": receipt.photo_hash,
            "payment_method": receipt.payment_method,
            "items": receipt.items,
            "today": receipt.today,
            "editable": true,
            "can_edit_name": true,
            "can_edit_qty": true,
            "can_edit_price": true,
            "qty_mode": "stepper",
        },
    })
}

pub fn expense_glance_block(glance: &ExpenseGlance) -> Value {
    json!({
        "kind": "expense.glance",
        "collapsed": false,
        "body": glance,
    })
}

pub fn receipt_with_items(
    tx_id: i64,
    headline: &str,
    subtitle: &str,
    photo_hash: &str,
    payment_method: &str,
    items: Vec<super::types::ExpenseItem>,
) -> ExpenseReceipt {
    let total = expense_total_minor(&items);
    ExpenseReceipt {
        tx_id: tx_id.to_string(),
        headline: headline.to_string(),
        subtitle: subtitle.to_string(),
        coach: String::new(),
        total_minor: total,
        currency: super::types::DEFAULT_CURRENCY.into(),
        saved: false,
        duplicate: false,
        duplicate_reason: String::new(),
        photo_hash: photo_hash.to_string(),
        payment_method: payment_method.to_string(),
        items,
        today: super::types::ExpenseTodaySummary::default(),
    }
}
