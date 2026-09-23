use c35_mod_tx::acc_signed_amount;
use c35_proto::{TxAcc, TxAccSide, TxType};

#[test]
fn tx_type_roundtrip() {
    use c35_mod_tx::enum_map::{tx_type_from_str, tx_type_str};
    assert_eq!(tx_type_from_str("sale"), TxType::Sale);
    assert_eq!(tx_type_str(TxType::DebtReceivable), "debt_receivable");
}

#[test]
fn acc_signed_amount_debit_credit() {
    let debit = TxAcc {
        side: i32::from(TxAccSide::Debit),
        amount: 100,
        ..Default::default()
    };
    let credit = TxAcc {
        side: i32::from(TxAccSide::Credit),
        amount: 100,
        ..Default::default()
    };
    assert_eq!(acc_signed_amount(&debit), 100);
    assert_eq!(acc_signed_amount(&credit), -100);
}
