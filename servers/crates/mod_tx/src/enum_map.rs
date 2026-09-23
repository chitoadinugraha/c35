use c35_proto::{
    TxAccSide, TxDebtPaymentMethod, TxInputMode, TxInputSource, TxItemFulfillmentState,
    TxOrderPayAt, TxPaymentMethod, TxState, TxType,
};

pub fn tx_type_str(t: TxType) -> &'static str {
    match t {
        TxType::Sale => "sale",
        TxType::Purchase => "purchase",
        TxType::Transfer => "transfer",
        TxType::Adjustment => "adjustment",
        TxType::ReturnSale => "return_sale",
        TxType::ReturnPurchase => "return_purchase",
        TxType::Reservation => "reservation",
        TxType::Ship => "ship",
        TxType::Payment => "payment",
        TxType::Receipt => "receipt",
        TxType::DebtPayable => "debt_payable",
        TxType::DebtReceivable => "debt_receivable",
        TxType::Inventory => "inventory",
        _ => "sale",
    }
}

pub fn tx_type_from_str(s: &str) -> TxType {
    match s {
        "sale" => TxType::Sale,
        "purchase" => TxType::Purchase,
        "transfer" => TxType::Transfer,
        "adjustment" => TxType::Adjustment,
        "return_sale" => TxType::ReturnSale,
        "return_purchase" => TxType::ReturnPurchase,
        "reservation" => TxType::Reservation,
        "ship" => TxType::Ship,
        "payment" => TxType::Payment,
        "receipt" => TxType::Receipt,
        "debt_payable" => TxType::DebtPayable,
        "debt_receivable" => TxType::DebtReceivable,
        "inventory" => TxType::Inventory,
        _ => TxType::Unspecified,
    }
}

pub fn tx_state_str(s: TxState) -> &'static str {
    match s {
        TxState::Ok => "ok",
        TxState::Draft => "draft",
        TxState::Pending => "pending",
        TxState::WaitingPayment => "waiting_payment",
        TxState::Cancelled => "cancelled",
    }
}

pub fn tx_state_from_str(s: &str) -> TxState {
    match s {
        "ok" => TxState::Ok,
        "draft" => TxState::Draft,
        "pending" => TxState::Pending,
        "waiting_payment" => TxState::WaitingPayment,
        "cancelled" => TxState::Cancelled,
        _ => TxState::Ok,
    }
}

pub fn tx_input_mode_str(m: TxInputMode) -> &'static str {
    match m {
        TxInputMode::Normal => "normal",
        TxInputMode::Accounting => "accounting",
        TxInputMode::Sell => "sell",
        TxInputMode::Purchase => "purchase",
        _ => "normal",
    }
}

pub fn tx_input_mode_from_str(s: &str) -> TxInputMode {
    match s {
        "normal" => TxInputMode::Normal,
        "accounting" => TxInputMode::Accounting,
        "sell" => TxInputMode::Sell,
        "purchase" => TxInputMode::Purchase,
        _ => TxInputMode::Normal,
    }
}

pub fn tx_input_source_str(s: TxInputSource) -> &'static str {
    match s {
        TxInputSource::Manual => "manual",
        TxInputSource::Web => "web",
        TxInputSource::Ai => "ai",
        TxInputSource::Api => "api",
        _ => "manual",
    }
}

pub fn tx_input_source_from_str(s: &str) -> TxInputSource {
    match s {
        "manual" => TxInputSource::Manual,
        "web" => TxInputSource::Web,
        "ai" => TxInputSource::Ai,
        "api" => TxInputSource::Api,
        _ => TxInputSource::Manual,
    }
}

pub fn tx_payment_method_str(m: TxPaymentMethod) -> &'static str {
    match m {
        TxPaymentMethod::Cash => "cash",
        TxPaymentMethod::Card => "card",
        TxPaymentMethod::Transfer => "transfer",
        TxPaymentMethod::Qris => "qris",
        TxPaymentMethod::Debt => "debt",
        TxPaymentMethod::Wallet => "wallet",
        _ => "cash",
    }
}

pub fn tx_payment_method_from_str(s: &str) -> TxPaymentMethod {
    match s {
        "cash" => TxPaymentMethod::Cash,
        "card" => TxPaymentMethod::Card,
        "transfer" => TxPaymentMethod::Transfer,
        "qris" => TxPaymentMethod::Qris,
        "debt" => TxPaymentMethod::Debt,
        "wallet" => TxPaymentMethod::Wallet,
        _ => TxPaymentMethod::Unspecified,
    }
}

pub fn tx_type(v: i32) -> TxType {
    TxType::try_from(v).unwrap_or(TxType::Unspecified)
}

pub fn tx_state(v: i32) -> TxState {
    TxState::try_from(v).unwrap_or(TxState::Ok)
}

pub fn tx_payment_method(v: i32) -> TxPaymentMethod {
    TxPaymentMethod::try_from(v).unwrap_or(TxPaymentMethod::Unspecified)
}

pub fn tx_debt_payment_method_str(m: TxDebtPaymentMethod) -> &'static str {
    match m {
        TxDebtPaymentMethod::Cash => "cash",
        TxDebtPaymentMethod::Card => "card",
        TxDebtPaymentMethod::Transfer => "transfer",
        TxDebtPaymentMethod::Qris => "qris",
        TxDebtPaymentMethod::Wallet => "wallet",
        _ => "cash",
    }
}

pub fn tx_debt_payment_method_from_str(s: &str) -> TxDebtPaymentMethod {
    match s {
        "cash" => TxDebtPaymentMethod::Cash,
        "card" => TxDebtPaymentMethod::Card,
        "transfer" => TxDebtPaymentMethod::Transfer,
        "qris" => TxDebtPaymentMethod::Qris,
        "wallet" => TxDebtPaymentMethod::Wallet,
        _ => TxDebtPaymentMethod::Unspecified,
    }
}

pub fn tx_acc_side_str(s: TxAccSide) -> &'static str {
    match s {
        TxAccSide::Debit => "debit",
        TxAccSide::Credit => "credit",
        _ => "debit",
    }
}

pub fn tx_acc_side_from_str(s: &str) -> TxAccSide {
    match s {
        "debit" => TxAccSide::Debit,
        "credit" => TxAccSide::Credit,
        _ => TxAccSide::Unspecified,
    }
}

pub fn tx_fulfillment_from_str(s: &str) -> TxItemFulfillmentState {
    match s {
        "pending" => TxItemFulfillmentState::TxItemFulfillmentPending,
        "in_progress" => TxItemFulfillmentState::TxItemFulfillmentInProgress,
        "done" => TxItemFulfillmentState::TxItemFulfillmentDone,
        _ => TxItemFulfillmentState::TxItemFulfillmentUnspecified,
    }
}

pub fn tx_fulfillment_str(s: TxItemFulfillmentState) -> &'static str {
    match s {
        TxItemFulfillmentState::TxItemFulfillmentPending => "pending",
        TxItemFulfillmentState::TxItemFulfillmentInProgress => "in_progress",
        TxItemFulfillmentState::TxItemFulfillmentDone => "done",
        _ => "",
    }
}

pub fn tx_order_pay_at_str(v: TxOrderPayAt) -> &'static str {
    match v {
        TxOrderPayAt::Cashier => "cashier",
        TxOrderPayAt::Table => "table",
        _ => "",
    }
}

pub fn tx_order_pay_at_from_str(s: &str) -> TxOrderPayAt {
    match s {
        "cashier" => TxOrderPayAt::Cashier,
        "table" => TxOrderPayAt::Table,
        _ => TxOrderPayAt::Unspecified,
    }
}

pub fn stock_direction_signed(direction: &str, qty: i32) -> i32 {
    match direction {
        "in" => qty,
        "out" => -qty,
        "transfer" => 0,
        _ => qty,
    }
}
