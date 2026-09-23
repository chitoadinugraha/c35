use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteDomainList, ReqSiteDomainPut, ResSiteDomainList, ResSiteDomainPut, SiteDomain, sync_push,
};
use chrono::Utc;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::domain_from_row;
use crate::sync_push::site_sync_push;
use crate::tls_sync::{domain_tls_ensure, domain_tls_status_sync};
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub fn normalize_hostname(host: &str) -> String {
    host.trim()
        .split(':')
        .next()
        .unwrap_or("")
        .trim()
        .to_lowercase()
        .trim_end_matches('.')
        .to_string()
}

fn verify_token_new() -> String {
    blake3::hash(c35_store::snowflake_id().to_string().as_bytes())
        .to_hex()
        .to_string()
}

pub async fn site_domain_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDomainList,
) -> Result<ResSiteDomainList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let rows = sqlx::query(
        r#"
        SELECT id, site_iid, hostname, is_primary, tls_status, verified_ts,
               verify_token, created_ts, updated_ts, deleted_ts
        FROM site.domain
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY is_primary DESC, hostname
        "#,
    )
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSiteDomainList {
        domains: rows.iter().map(domain_from_row).collect(),
    })
}

pub async fn site_domain_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDomainPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteDomainPut> {
    let domain = req.domain.ok_or_else(|| anyhow!("domain required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let hostname = normalize_hostname(&domain.hostname);
    if hostname.is_empty() {
        return Err(anyhow!("hostname required"));
    }
    let id = if domain.id > 0 { domain.id } else { snowflake_id() };
    let verify_token = if domain.verify_token.is_empty() {
        verify_token_new()
    } else {
        domain.verify_token.clone()
    };
    let tls_status = if domain.tls_status.is_empty() {
        "pending".to_string()
    } else {
        domain.tls_status.clone()
    };
    let verified_ts = if domain.verified_ts_ms > 0 {
        Some(
            chrono::DateTime::from_timestamp_millis(domain.verified_ts_ms)
                .unwrap_or_else(Utc::now),
        )
    } else {
        None
    };
    let mut tx = pool.begin().await?;
    if domain.is_primary {
        sqlx::query(
            r#"
            UPDATE site.domain SET is_primary = FALSE, updated_ts = NOW()
            WHERE site_iid = $1 AND deleted_ts IS NULL AND id <> $2
            "#,
        )
        .bind(site_iid)
        .bind(id)
        .execute(&mut *tx)
        .await?;
    }
    sqlx::query(
        r#"
        INSERT INTO site.domain (
            id, site_iid, owner_iid, hostname, is_primary, verify_token,
            verified_ts, tls_status, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
          hostname = EXCLUDED.hostname, is_primary = EXCLUDED.is_primary,
          verify_token = EXCLUDED.verify_token, verified_ts = EXCLUDED.verified_ts,
          tls_status = EXCLUDED.tls_status, updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(id)
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&hostname)
    .bind(domain.is_primary)
    .bind(&verify_token)
    .bind(verified_ts)
    .bind(&tls_status)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    if verified_ts.is_some() {
        let status = domain_tls_ensure(&hostname).await;
        domain_tls_status_sync(pool, id, &status).await;
    }
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteDomain(SiteDomain {
                id,
                site_iid,
                hostname,
                is_primary: domain.is_primary,
                tls_status,
                verified_ts_ms: domain.verified_ts_ms,
                verify_token,
                updated_ts_ms: Utc::now().timestamp_millis(),
                ..Default::default()
            }),
        );
    }
    Ok(ResSiteDomainPut { id })
}

pub async fn domain_site_id_verified(pool: &PgPool, host: &str) -> Result<Option<i64>> {
    let hostname = normalize_hostname(host);
    if hostname.is_empty() {
        return Ok(None);
    }
    let row = sqlx::query(
        r#"
        SELECT site_iid FROM site.domain
        WHERE LOWER(hostname) = $1 AND deleted_ts IS NULL AND verified_ts IS NOT NULL
        LIMIT 1
        "#,
    )
    .bind(&hostname)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| r.get("site_iid")))
}
