use anyhow::{anyhow, Result};
use c35_mod_site::site_sync_push;
use c35_proto::{sync_push, ReqTxPut, ResTxPut, TxState, WsRes};
use c35_store::snowflake_id;
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::finalize::tx_finalize;
use crate::tx_owner_resolve::tx_owner_resolve;
use crate::load::{tx_load, tx_stocks_load};
use crate::persist::{tx_acc_counts, tx_children_del, tx_children_put, tx_header_put};
use crate::stock_apply::product_stock_apply;

pub async fn tx_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqTxPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResTxPut> {
    let mut tx = req.tx.ok_or_else(|| anyhow!("tx required"))?;
    let site_iid = if tx.site_iid > 0 {
        tx.site_iid
    } else {
        return Err(anyhow!("site_iid required"));
    };
    let owner_iid = tx_owner_resolve(pool, caller_iid, site_iid, true).await?;
    let old_stocks = if tx.tx_id > 0 {
        tx_stocks_load(pool, site_iid, tx.tx_id).await?
    } else {
        vec![]
    };
    let has_existing = if tx.tx_id > 0 {
        tx_load(pool, site_iid, tx.tx_id).await?.is_some()
    } else {
        false
    };
    if tx.tx_id == 0 {
        tx.tx_id = snowflake_id();
    }
    tx.site_iid = site_iid;
    if !has_existing && tx.created_by_iid == 0 {
        tx.created_by_iid = caller_iid;
    }
    tx_finalize(&mut tx);
    let (generated_count, manual_count) = tx_acc_counts(&tx);
    let mut db = pool.begin().await?;
    tx_children_del(&mut db, site_iid, tx.tx_id).await?;
    tx_header_put(&mut db, owner_iid, &tx, generated_count, manual_count).await?;
    tx_children_put(&mut db, &mut tx).await?;
    let state = TxState::try_from(tx.state).unwrap_or(TxState::Ok);
    if state == TxState::Ok {
        product_stock_apply(&mut db, site_iid, &old_stocks, &tx.stocks).await?;
    }
    db.commit().await?;
    let saved = tx_load(pool, site_iid, tx.tx_id).await?;
    if let Some(out) = out_tx {
        if let Some(tx) = &saved {
            site_sync_push(out, sync_push::Body::Tx(tx.clone()));
        }
    }
    Ok(ResTxPut { tx: saved })
}
