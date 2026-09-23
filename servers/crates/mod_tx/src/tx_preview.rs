use anyhow::{anyhow, Result};
use c35_mod_site::grant::site_grant_check;
use c35_proto::{ReqTxPreview, ResTxPreview, TxState};
use sqlx::PgPool;

use crate::finalize::{tx_finalize, tx_preview_coa_names};

pub async fn tx_preview(pool: &PgPool, caller_iid: i64, req: ReqTxPreview) -> Result<ResTxPreview> {
    let mut tx = req.tx.ok_or_else(|| anyhow!("tx required"))?;
    let site_iid = if tx.site_iid > 0 {
        tx.site_iid
    } else {
        return Err(anyhow!("site_iid required"));
    };
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    tx.site_iid = site_iid;
    let state = TxState::try_from(tx.state).unwrap_or(TxState::Ok);
    if state == TxState::Draft {
        tx.state = i32::from(TxState::Ok);
    }
    tx_finalize(&mut tx);
    let coa_name = tx_preview_coa_names(&tx.accs);
    Ok(ResTxPreview { tx: Some(tx), coa_name })
}
