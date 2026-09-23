use anyhow::Result;
use c35_mod_site::grant::site_grant_check;
use c35_proto::{ReqTxGet, ResTxGet};
use sqlx::PgPool;

use crate::load::tx_load;

pub async fn tx_get(pool: &PgPool, caller_iid: i64, req: ReqTxGet) -> Result<ResTxGet> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let tx = tx_load(pool, req.site_iid, req.tx_id).await?;
    Ok(ResTxGet { tx })
}
