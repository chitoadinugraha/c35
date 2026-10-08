//! Buy a hostname on Cloudflare Registrar, then attach it to the site.

use anyhow::{anyhow, Result};
use c35_mod_billing::{domain_purchase_debit, domain_purchase_mark, domain_purchase_refund};
use c35_mod_mail::{ensure_site_mailbox, onboard_zone_for_site, zone_in_cloudflare};
use c35_proto::{
    ReqSiteDomainBuy, ReqSiteDomainCheck, ReqSiteDomainPut, ReqSiteDomainSearch, ReqSiteDomainVerify,
    ResSiteDomainBuy, ResSiteDomainCheck, ResSiteDomainSearch, SiteDomain, SiteDomainSearchHit, WsRes,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};
use tokio::sync::mpsc;

use crate::cloudflare_registrar::{cf_dns_cname_grey, cf_domain_check, cf_domain_register, cf_domain_search, DomainHit};
use crate::dns_verify::normalize_hostname;
use crate::grant::site_grant_check;
use crate::http::host_is_primary;
use crate::rows::domain_from_row;
use crate::site_domain::{site_domain_put, site_domain_verify_checked};

/// `unavailable` when the name cannot be registered.
/// `missing_price` when the quote is empty or not a positive amount.
/// Otherwise `(amount, currency)` with currency uppercased.
pub fn buy_quote_ok(hit: &DomainHit) -> Result<(f64, String), &'static str> {
    if !hit.registrable {
        return Err("unavailable");
    }
    let cost = hit.registration_cost.trim();
    let amount: f64 = cost.parse().unwrap_or(f64::NAN);
    if !amount.is_finite() || amount <= 0.0 {
        return Err("missing_price");
    }
    let currency = hit.currency.trim().to_uppercase();
    if currency.len() != 3 || !currency.bytes().all(|b| b.is_ascii_uppercase()) {
        return Err("missing_price");
    }
    Ok((amount, currency))
}

fn hit_proto(h: DomainHit) -> SiteDomainSearchHit {
    SiteDomainSearchHit {
        name: h.name,
        registrable: h.registrable,
        reason: h.reason,
        registration_cost: h.registration_cost,
        currency: h.currency,
    }
}

pub async fn site_domain_search(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDomainSearch,
) -> Result<ResSiteDomainSearch> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let hits = cf_domain_search(&req.query, 10).await.map_err(|e| anyhow!(e))?;
    Ok(ResSiteDomainSearch {
        hits: hits.into_iter().map(hit_proto).collect(),
    })
}

pub async fn site_domain_check(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDomainCheck,
) -> Result<ResSiteDomainCheck> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let hits = cf_domain_check(&req.hostnames).await.map_err(|e| anyhow!(e))?;
    Ok(ResSiteDomainCheck {
        hits: hits.into_iter().map(hit_proto).collect(),
    })
}

pub async fn site_domain_buy(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteDomainBuy,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteDomainBuy> {
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let hostname = normalize_hostname(&req.hostname);
    if hostname.is_empty() {
        return Err(anyhow!("hostname required"));
    }
    if host_is_primary(&hostname) {
        return Err(anyhow!("cannot buy a primary platform host"));
    }

    let hits = cf_domain_check(std::slice::from_ref(&hostname))
        .await
        .map_err(|e| anyhow!(e))?;
    let hit = hits
        .iter()
        .find(|h| h.name == hostname)
        .or_else(|| hits.first())
        .ok_or_else(|| anyhow!("unavailable"))?;
    let (amount, currency) = buy_quote_ok(hit).map_err(|e| anyhow!(e))?;

    let order_id = snowflake_id();
    if let Err(e) = domain_purchase_debit(
        pool,
        order_id,
        owner_iid,
        site_iid,
        &hostname,
        &currency,
        amount,
    )
    .await
    {
        if e == "insufficient_balance" {
            return Ok(ResSiteDomainBuy {
                domain: None,
                error: "insufficient_balance".into(),
            });
        }
        return Err(anyhow!(e));
    }

    let reg = match cf_domain_register(&hostname).await {
        Ok(reg) => reg,
        Err(e) => {
            if let Err(re) = domain_purchase_refund(pool, order_id).await {
                tracing::warn!("domain purchase refund {order_id} failed: {re}");
            }
            return Ok(ResSiteDomainBuy {
                domain: None,
                error: e,
            });
        }
    };

    let cname_error = match cf_dns_cname_grey(&reg.zone_id, &hostname).await {
        Ok(()) => String::new(),
        Err(e) => e,
    };
    domain_purchase_mark(pool, order_id, "registered", &reg.zone_id, &cname_error)
        .await
        .map_err(|e| anyhow!(e))?;

    let put = site_domain_put(
        pool,
        caller_iid,
        ReqSiteDomainPut {
            site_iid,
            domain: Some(SiteDomain {
                hostname: hostname.clone(),
                tls_status: "pending".into(),
                source: "bought".into(),
                ..Default::default()
            }),
        },
        out_tx,
    )
    .await?;

    let _verify = site_domain_verify_checked(
        pool,
        ReqSiteDomainVerify {
            site_iid,
            domain_id: put.id,
            force_tls: false,
        },
        out_tx,
    )
    .await?;
    domain_mail_after_verify(pool, site_iid, put.id).await?;

    let domain = load_domain(pool, site_iid, put.id).await?;
    Ok(ResSiteDomainBuy {
        domain: Some(domain),
        error: cname_error,
    })
}

async fn load_domain(pool: &PgPool, site_iid: i64, domain_id: i64) -> Result<SiteDomain> {
    let row = sqlx::query(
        r#"
        SELECT id, site_iid, hostname, is_primary, tls_status, verified_ts,
               verify_token, verify_error, tls_error, last_verify_ts,
               source, mail_status, mail_error,
               created_ts, updated_ts, deleted_ts
        FROM site.domain
        WHERE id = $1 AND site_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("domain not found"))?;
    Ok(domain_from_row(&row))
}

async fn write_mail(
    pool: &PgPool,
    site_iid: i64,
    domain_id: i64,
    mail_status: &str,
    mail_error: &str,
) -> Result<()> {
    sqlx::query(
        r#"
        UPDATE site.domain
        SET mail_status = $3, mail_error = $4, updated_ts = NOW()
        WHERE id = $1 AND site_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(site_iid)
    .bind(mail_status)
    .bind(mail_error)
    .execute(pool)
    .await?;
    Ok(())
}

/// Onboard mail after DNS verify. Bought zones always try. BYO only when Cloudflare already has the zone.
pub async fn domain_mail_after_verify(pool: &PgPool, site_iid: i64, domain_id: i64) -> Result<()> {
    let row = sqlx::query(
        r#"
        SELECT hostname, source, owner_iid, verified_ts
        FROM site.domain
        WHERE id = $1 AND site_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(());
    };
    if row.get::<Option<chrono::DateTime<chrono::Utc>>, _>("verified_ts").is_none() {
        return Ok(());
    }
    let source: String = row.get("source");
    let hostname: String = row.get("hostname");
    let owner_iid: i64 = row.get("owner_iid");

    if source == "byo" {
        match zone_in_cloudflare(&hostname).await {
            Ok(false) => return Ok(()),
            Ok(true) => {}
            Err(e) => {
                write_mail(pool, site_iid, domain_id, "failed", &e).await?;
                return Ok(());
            }
        }
    } else if source != "bought" {
        return Ok(());
    }

    let onboard = match onboard_zone_for_site(pool, &hostname).await {
        Ok(o) => o,
        Err(e) => {
            write_mail(pool, site_iid, domain_id, "failed", &e).await?;
            return Ok(());
        }
    };

    if onboard.mail_status == "ready" {
        let alien_id: Option<String> =
            sqlx::query_scalar("SELECT alien_id FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
                .bind(site_iid)
                .fetch_optional(pool)
                .await?;
        let Some(alien_id) = alien_id.filter(|s| !s.trim().is_empty()) else {
            write_mail(pool, site_iid, domain_id, "failed", "alien_id missing").await?;
            return Ok(());
        };
        let address = format!("{}@{}", alien_id.trim(), hostname);
        if let Err(e) = ensure_site_mailbox(pool, owner_iid, site_iid, &address).await {
            write_mail(pool, site_iid, domain_id, "failed", &e).await?;
            return Ok(());
        }
    }

    write_mail(
        pool,
        site_iid,
        domain_id,
        &onboard.mail_status,
        &onboard.mail_error,
    )
    .await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn hit(registrable: bool, cost: &str, currency: &str) -> DomainHit {
        DomainHit {
            name: "example.com".into(),
            registrable,
            reason: String::new(),
            registration_cost: cost.into(),
            currency: currency.into(),
        }
    }

    #[test]
    fn buy_quote_ok_unavailable() {
        assert_eq!(buy_quote_ok(&hit(false, "12.00", "USD")).unwrap_err(), "unavailable");
    }

    #[test]
    fn buy_quote_ok_missing_price() {
        assert_eq!(buy_quote_ok(&hit(true, "", "USD")).unwrap_err(), "missing_price");
        assert_eq!(buy_quote_ok(&hit(true, "nope", "USD")).unwrap_err(), "missing_price");
        assert_eq!(buy_quote_ok(&hit(true, "0", "USD")).unwrap_err(), "missing_price");
    }

    #[test]
    fn buy_quote_ok_parses_usd() {
        let (amount, currency) = buy_quote_ok(&hit(true, "12.00", "usd")).unwrap();
        assert_eq!(amount, 12.0);
        assert_eq!(currency, "USD");
    }
}
