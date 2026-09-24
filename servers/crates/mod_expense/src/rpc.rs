use c35_proto::{ReqExpensePut, ResExpensePut};
use serde_json::json;
use sqlx::PgPool;

use crate::{
    block::expense_receipt_block,
    store::{expense_delete, expense_update},
    types::ExpenseItem,
};

pub async fn expense_put_rpc(
    pool: &PgPool,
    owner_iid: i64,
    locale: &str,
    req: ReqExpensePut,
) -> Result<ResExpensePut, String> {
    let tx_id = req.tx_id;
    if tx_id <= 0 {
        return Err("tx_id required".into());
    }

    if req.deleted_ts_ms > 0 {
        let deleted = expense_delete(pool, owner_iid, tx_id).await?;
        if !deleted {
            return Err("expense not found or already deleted".into());
        }
        return Ok(ResExpensePut {
            tx_id,
            blocks_json: "[]".into(),
        });
    }

    let items: Vec<ExpenseItem> = req
        .items
        .iter()
        .map(|i| {
            let qty = i.qty.max(0.01);
            let price_minor = i.price_minor.max(0);
            let total_minor = if i.total_minor > 0 {
                i.total_minor
            } else {
                (price_minor as f64 * qty as f64).round() as i64
            };
            ExpenseItem {
                name: i.name.clone(),
                name_id: if i.name_id.trim().is_empty() {
                    i.name.clone()
                } else {
                    i.name_id.clone()
                },
                qty,
                obj_id: i.obj_id,
                price_minor,
                total_minor,
            }
        })
        .collect();

    if items.is_empty() {
        return Err("items required".into());
    }

    let receipt = expense_update(pool, owner_iid, tx_id, &items, locale).await?;
    let block = expense_receipt_block(&receipt, locale);

    Ok(ResExpensePut {
        tx_id,
        blocks_json: serde_json::to_string(&json!([block])).unwrap_or_else(|_| "[]".into()),
    })
}
