use anyhow::{anyhow, Result};
use c35_mod_site::grant::site_grant_check;
use c35_proto::{ReqTxDebtPay, ReqTxPut, ResTxDebtPay, TxDebtPayment, TxPaymentMethod, WsRes};

use crate::enum_map::tx_payment_method;
use chrono::Utc;
use c35_store::snowflake_id;
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::load::tx_require;
use crate::tx_put::tx_put;

pub async fn tx_debt_pay(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqTxDebtPay,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResTxDebtPay> {
    let payment = req.payment.ok_or_else(|| anyhow!("payment required"))?;
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let mut tx = tx_require(pool, req.site_iid, req.tx_id).await?;
    let mut payment = payment;
    if payment.ts_ms == 0 {
        payment.ts_ms = Utc::now().timestamp_millis();
    }
    let applied = apply_debt_payment(&mut tx, payment)?;
    if !applied {
        return Err(anyhow!("no open debt installment"));
    }
    let res = tx_put(pool, caller_iid, ReqTxPut { tx: Some(tx) }, out_tx).await?;
    Ok(ResTxDebtPay { tx: res.tx })
}

fn apply_debt_payment(tx: &mut c35_proto::Tx, payment: TxDebtPayment) -> Result<bool> {
    let mut applied = false;
    for p in &mut tx.payments {
        if tx_payment_method(p.method) != TxPaymentMethod::Debt {
            continue;
        }
        for inst in &mut p.installments {
            let paid = inst.debt_payments.iter().map(|d| d.amount).sum::<i64>();
            let remaining = inst.amount - paid;
            if remaining <= 0 {
                continue;
            }
            let pay = if payment.amount > 0 {
                payment.amount.min(remaining)
            } else {
                return Err(anyhow!("amount required"));
            };
            let mut dp = payment.clone();
            dp.amount = pay;
            if dp.pay_id == 0 {
                dp.pay_id = snowflake_id();
            }
            inst.debt_payments.push(dp);
            applied = true;
            break;
        }
        if applied {
            break;
        }
    }
    Ok(applied)
}
