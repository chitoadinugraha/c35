use c35_mod_tx::tx_finalize;
use c35_proto::{Tx, TxItem, TxPayment, TxPaymentMethod, TxState, TxType};

#[test]
fn sale_finalize_totals_and_stock() {
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
    assert_eq!(tx.items_count, 1);
    assert_eq!(tx.items_qty, 2);
    assert_eq!(tx.items_total, 10000);
    assert_eq!(tx.total, 10000);
    assert_eq!(tx.total_paid, 10000);
    assert!(tx.is_paid);
    assert_eq!(tx.stock_line_count, 1);
    assert_eq!(tx.stock_qty_out, 2);
    assert_eq!(tx.stocks[0].direction, "out");
    assert_eq!(tx.stocks[0].qty_signed, -2);
    assert!(tx.acc_balanced);
}

#[test]
fn purchase_finalize_stock_in() {
    let mut tx = Tx {
        r#type: i32::from(TxType::Purchase),
        state: i32::from(TxState::Ok),
        store_id: 5,
        items: vec![TxItem {
            product_id: 50,
            price: 3000,
            qty: 4,
            ..Default::default()
        }],
        ..Default::default()
    };
    tx_finalize(&mut tx);
    assert_eq!(tx.stock_line_count, 1);
    assert_eq!(tx.stock_qty_in, 4);
    assert_eq!(tx.stocks[0].direction, "in");
}
