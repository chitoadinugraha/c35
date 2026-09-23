use anyhow::{anyhow, Result};
use sqlx::PgPool;

use crate::tx_owner_resolve::tx_owner_resolve;

pub async fn tx_delete(pool: &PgPool, caller_iid: i64, site_iid: i64, tx_id: i64) -> Result<bool> {
    let owner_iid = tx_owner_resolve(pool, caller_iid, site_iid, true).await?;
    if tx_id <= 0 {
        return Err(anyhow!("tx_id required"));
    }
    let mut db = pool.begin().await?;
    let n = sqlx::query(
        "UPDATE site.tx SET deleted_ts = NOW(), updated_ts = NOW()
         WHERE site_iid = $1 AND tx_id = $2 AND owner_iid = $3 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(tx_id)
    .bind(owner_iid)
    .execute(&mut *db)
    .await?
    .rows_affected();
    if n == 0 {
        db.rollback().await?;
        return Ok(false);
    }
    let child_tables = [
        "site.tx_item",
        "site.tx_payment",
        "site.tx_acc",
        "site.tx_stock",
        "site.tx_tax",
        "site.tx_discount",
    ];
    for table in child_tables {
        sqlx::query(&format!(
            "UPDATE {table} SET deleted_ts = NOW(), updated_ts = NOW()
             WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL"
        ))
        .bind(site_iid)
        .bind(tx_id)
        .execute(&mut *db)
        .await?;
    }
    db.commit().await?;
    Ok(true)
}
