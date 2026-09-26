use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteDomainList, ReqSiteDomainPut, ReqSiteDomainVerify, ResSiteDomainList, ResSiteDomainPut,
    ResSiteDomainVerify, SiteDomain, sync_push,
};
use chrono::Utc;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::dns_verify::{dns_cname_points_to, domain_cname_target};
use crate::grant::site_grant_check;
use crate::http::host_is_primary;
use crate::rows::domain_from_row;
use crate::sync_push::site_sync_push;
use crate::tls_sync::{domain_tls_ensure, domain_tls_status_sync};
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub use crate::dns_verify::normalize_hostname;

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
               verify_token, verify_error, tls_error, last_verify_ts,
               created_ts, updated_ts, deleted_ts
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
    let mut tls_status = if domain.tls_status.is_empty() {
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
    let last_verify_ts = if domain.last_verify_ts_ms > 0 {
        Some(
            chrono::DateTime::from_timestamp_millis(domain.last_verify_ts_ms)
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
            verified_ts, tls_status, verify_error, tls_error, last_verify_ts,
            created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
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
    .bind(&domain.verify_error)
    .bind(&domain.tls_error)
    .bind(last_verify_ts)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    if verified_ts.is_some() {
        let info = domain_tls_ensure(&hostname, false).await;
        domain_tls_status_sync(pool, id, &info).await;
        tls_status = info.status.as_str().to_string();
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

pub async fn site_domain_verify(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDomainVerify,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteDomainVerify> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let domain_id = req.domain_id;
    if domain_id <= 0 {
        return Ok(ResSiteDomainVerify {
            dns_verified: false,
            error: "domain_id required".into(),
            tls_status: String::new(),
        });
    }
    let row = sqlx::query(
        r#"
        SELECT id, site_iid, hostname, is_primary, tls_status, verified_ts, verify_token
        FROM site.domain
        WHERE id = $1 AND site_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let row = row.ok_or_else(|| anyhow!("domain not found"))?;
    let hostname: String = row.get("hostname");
    let hostname = normalize_hostname(&hostname);
    if hostname.is_empty() {
        return Ok(ResSiteDomainVerify {
            dns_verified: false,
            error: "invalid hostname".into(),
            tls_status: String::new(),
        });
    }
    if host_is_primary(&hostname) {
        return Ok(ResSiteDomainVerify {
            dns_verified: false,
            error: "cannot verify a primary platform host".into(),
            tls_status: String::new(),
        });
    }
    let now = Utc::now();
    let already_verified = row.get::<Option<chrono::DateTime<Utc>>, _>("verified_ts").is_some();
    if req.force_tls && already_verified {
        let info = domain_tls_ensure(&hostname, true).await;
        domain_tls_status_sync(pool, domain_id, &info).await;
        let tls_status = info.status.as_str().to_string();
        return Ok(ResSiteDomainVerify {
            dns_verified: true,
            error: String::new(),
            tls_status,
        });
    }
    let target = domain_cname_target();
    let (dns_verified, verify_error) = match dns_cname_points_to(&hostname, &target).await {
        Ok(true) => (true, String::new()),
        Ok(false) => (
            false,
            format!(
                "CNAME record not found. Point your domain to {target} and try again."
            ),
        ),
        Err(e) => (false, format!("DNS lookup failed: {e}")),
    };
    sqlx::query(
        r#"
        UPDATE site.domain SET
            verified_ts = CASE WHEN $3 THEN $4 ELSE verified_ts END,
            verify_error = $5,
            last_verify_ts = $4,
            updated_ts = NOW()
        WHERE id = $1 AND site_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(site_iid)
    .bind(dns_verified)
    .bind(now)
    .bind(&verify_error)
    .execute(pool)
    .await?;
    let mut tls_status = row.get::<String, _>("tls_status");
    if dns_verified {
        let info = domain_tls_ensure(&hostname, false).await;
        domain_tls_status_sync(pool, domain_id, &info).await;
        tls_status = info.status.as_str().to_string();
    }
    let verified_ts_ms = if dns_verified {
        now.timestamp_millis()
    } else {
        0
    };
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteDomain(SiteDomain {
                id: domain_id,
                site_iid,
                hostname,
                is_primary: row.get("is_primary"),
                tls_status: tls_status.clone(),
                verified_ts_ms,
                verify_token: row.get("verify_token"),
                updated_ts_ms: now.timestamp_millis(),
                ..Default::default()
            }),
        );
    }
    Ok(ResSiteDomainVerify {
        dns_verified,
        error: verify_error,
        tls_status,
    })
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
