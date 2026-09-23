use anyhow::{anyhow, Result};
use c35_mod_site::site_published;
use c35_proto::{
    ReqSiteGuestOrderGet, ReqSiteGuestOrderPut, ResSiteGuestOrderGet, ResSiteGuestOrderPut,
    Tx, TxInputMode, TxInputSource, TxItem, TxState, TxType,
};
use c35_store::snowflake_id;
use chrono::Utc;
use sqlx::{PgPool, Row};

use crate::finalize::tx_finalize;
use crate::load::tx_load;
use crate::persist::{tx_acc_counts, tx_children_del, tx_children_put, tx_header_put};
use crate::stock_apply::product_stock_apply;

pub async fn guest_order_put(pool: &PgPool, req: ReqSiteGuestOrderPut) -> Result<ResSiteGuestOrderPut> {
    let site_iid = req.site_iid;
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let owner_iid = guest_site_owner(pool, site_iid).await?;
    let mut tx = req.tx.ok_or_else(|| anyhow!("tx required"))?;
    if tx.tx_id > 0 {
        return Err(anyhow!("guest orders cannot update existing tx"));
    }
    guest_order_reprice(pool, site_iid, &mut tx).await?;
    guest_order_normalize(site_iid, &mut tx);
    tx_finalize(&mut tx);
    let (generated_count, manual_count) = tx_acc_counts(&tx);
    let mut db = pool.begin().await?;
    tx_children_del(&mut db, site_iid, tx.tx_id).await?;
    tx_header_put(&mut db, owner_iid, &tx, generated_count, manual_count).await?;
    tx_children_put(&mut db, &mut tx).await?;
    let state = TxState::try_from(tx.state).unwrap_or(TxState::WaitingPayment);
    if state == TxState::Ok {
        product_stock_apply(&mut db, site_iid, &[], &tx.stocks).await?;
    }
    db.commit().await?;
    let saved = tx_load(pool, site_iid, tx.tx_id).await?;
    Ok(ResSiteGuestOrderPut { tx: saved })
}

pub async fn guest_order_get(pool: &PgPool, req: ReqSiteGuestOrderGet) -> Result<ResSiteGuestOrderGet> {
    let site_iid = req.site_iid;
    if site_iid <= 0 || req.tx_id <= 0 {
        return Err(anyhow!("site_iid and tx_id required"));
    }
    let _ = guest_site_owner(pool, site_iid).await?;
    let tx = tx_load(pool, site_iid, req.tx_id).await?;
    let tx = tx.filter(|t| t.input_source == i32::from(TxInputSource::Web));
    Ok(ResSiteGuestOrderGet { tx })
}

async fn guest_site_owner(pool: &PgPool, site_iid: i64) -> Result<i64> {
    if !site_published(pool, site_iid).await? {
        return Err(anyhow!("site not published"));
    }
    let row = sqlx::query(
        r#"
        SELECT owner_iid FROM ai.identity
        WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    Ok(row.get("owner_iid"))
}

fn guest_order_normalize(site_iid: i64, tx: &mut Tx) {
    tx.tx_id = snowflake_id();
    tx.site_iid = site_iid;
    tx.r#type = i32::from(TxType::Sale);
    tx.state = i32::from(TxState::WaitingPayment);
    tx.input_mode = i32::from(TxInputMode::Sell);
    tx.input_source = i32::from(TxInputSource::Web);
    tx.is_task_assigned = true;
    if tx.time_ts_ms == 0 {
        tx.time_ts_ms = Utc::now().timestamp_millis();
    }
    if tx.created_ts_ms == 0 {
        tx.created_ts_ms = tx.time_ts_ms;
    }
}

async fn guest_order_reprice(pool: &PgPool, site_iid: i64, tx: &mut Tx) -> Result<()> {
    if tx.subject_name.trim().is_empty() {
        return Err(anyhow!("subject_name required"));
    }
    if tx.items.is_empty() {
        return Err(anyhow!("items required"));
    }
    for item in &mut tx.items {
        guest_item_reprice(pool, site_iid, item).await?;
    }
    Ok(())
}

async fn guest_item_reprice(pool: &PgPool, site_iid: i64, item: &mut TxItem) -> Result<()> {
    if item.product_id <= 0 {
        return Err(anyhow!("product_id required"));
    }
    if item.qty <= 0 {
        item.qty = 1;
    }
    let row = sqlx::query(
        r#"
        SELECT name, price, rev, can_sell
        FROM site.product
        WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL AND is_archived = FALSE
        "#,
    )
    .bind(site_iid)
    .bind(item.product_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("product not found: {}", item.product_id))?;
    let can_sell: bool = row.get("can_sell");
    if !can_sell {
        return Err(anyhow!("product not for sale: {}", item.product_id));
    }
    if item.price <= 0 {
        item.price = row.get("price");
    }
    item.product_rev = row.get("rev");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use c35_proto::TxItem;

    #[test]
    fn guest_order_normalize_sets_defaults() {
        let mut tx = Tx {
            site_iid: 99,
            subject_name: "Guest".into(),
            items: vec![TxItem {
                product_id: 1,
                qty: 2,
                price: 5000,
                ..Default::default()
            }],
            ..Default::default()
        };
        guest_order_normalize(42, &mut tx);
        assert_eq!(tx.site_iid, 42);
        assert!(tx.tx_id > 0);
        assert_eq!(tx.r#type, i32::from(TxType::Sale));
        assert_eq!(tx.state, i32::from(TxState::WaitingPayment));
        assert_eq!(tx.input_source, i32::from(TxInputSource::Web));
        assert!(tx.is_task_assigned);
    }
}
