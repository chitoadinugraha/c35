use anyhow::{anyhow, Result};
use c35_mod_site::grant::site_grant_check;
use sqlx::PgPool;

/// Personal ledger: when site_iid == caller_iid, verify user identity and grant access.
/// Otherwise delegate to site_grant_check.
pub async fn tx_owner_resolve(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    write: bool,
) -> Result<i64> {
    if site_iid == caller_iid {
        let exists = sqlx::query_scalar::<_, i64>(
            "SELECT id FROM ai.identity WHERE id = $1 AND kind = 'user' AND deleted_ts IS NULL",
        )
        .bind(caller_iid)
        .fetch_optional(pool)
        .await?;
        if exists.is_none() {
            return Err(anyhow!("user not found"));
        }
        return Ok(caller_iid);
    }
    site_grant_check(pool, caller_iid, site_iid, write).await
}
