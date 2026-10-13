use c35_proto::{Tx, TxItemFulfillmentState, TxState, TxType};

/// Cashier-only sites: `pending` is not a valid terminal processing state.
pub fn tx_coerce_sale_without_fulfillment(tx: &mut Tx) {
    if TxType::try_from(tx.r#type) != Ok(TxType::Sale) {
        return;
    }
    if TxState::try_from(tx.state) != Ok(TxState::Pending) {
        return;
    }
    tx.state = i32::from(TxState::Ok);
    for item in &mut tx.items {
        item.fulfillment_state = i32::from(TxItemFulfillmentState::TxItemFulfillmentDone);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use c35_proto::TxItem;

    #[test]
    fn pending_sale_coerces_to_ok() {
        let mut tx = Tx {
            r#type: i32::from(TxType::Sale),
            state: i32::from(TxState::Pending),
            items: vec![TxItem {
                fulfillment_state: i32::from(TxItemFulfillmentState::TxItemFulfillmentUnspecified),
                ..Default::default()
            }],
            ..Default::default()
        };
        tx_coerce_sale_without_fulfillment(&mut tx);
        assert_eq!(tx.state, i32::from(TxState::Ok));
        assert_eq!(
            tx.items[0].fulfillment_state,
            i32::from(TxItemFulfillmentState::TxItemFulfillmentDone)
        );
    }
}
