use chrono::{DateTime, Utc};
use c35_proto::{MailDomain, MailDomainSetupStep};
use sqlx::{PgPool, Row};

use crate::access::is_mail_admin;
use crate::cloudflare::{CfConfig, normalize_domain, receive_worker_name};

pub fn parse_email_domain(address: &str) -> Option<String> {
    let addr = address.trim();
    let at = addr.rfind('@')?;
    let domain = addr[at + 1..].trim();
    if domain.is_empty() {
        return None;
    }
    Some(normalize_domain(domain))
}

pub async fn domain_allowed(pool: &PgPool, hostname: &str) -> Result<bool, String> {
    let h = normalize_domain(hostname);
    sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM mail.domain WHERE lower(hostname) = lower($1))")
        .bind(&h)
        .fetch_one(pool)
        .await
        .map_err(|e| e.to_string())
}

pub async fn default_hostname(pool: &PgPool) -> String {
    if let Ok(Some(d)) = sqlx::query_scalar::<_, String>(
        "SELECT hostname FROM mail.domain WHERE hostname = 'alienai.id'",
    )
    .fetch_optional(pool)
    .await
    {
        return d;
    }
    sqlx::query_scalar("SELECT hostname FROM mail.domain ORDER BY hostname LIMIT 1")
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
        .unwrap_or_else(|| "alienai.id".to_string())
}

pub async fn list_admin(pool: &PgPool, viewer_iid: i64) -> Result<Vec<MailDomain>, String> {
    if !is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let rows = sqlx::query(
        "SELECT hostname, zone_id, sending_enabled, routing_enabled, setup_error, created_ts FROM mail.domain ORDER BY hostname",
    )
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(rows.iter().map(row_to_proto).collect())
}

pub async fn add_admin(pool: &PgPool, viewer_iid: i64, raw: &str) -> Result<MailDomain, String> {
    if !is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let hostname = normalize_domain(raw);
    if hostname.is_empty() || !hostname.contains('.') {
        return Err("invalid domain".into());
    }
    let cfg = CfConfig::from_env().ok_or_else(|| "CLOUDFLARE_API_TOKEN not configured".to_string())?;
    let sync = sync_cf(&cfg, &hostname).await;
    if sync.zone_id.is_empty() {
        return Err(sync.error_summary);
    }
    sqlx::query(
        "INSERT INTO mail.domain (hostname, zone_id, sending_enabled, routing_enabled, setup_error) VALUES ($1,$2,$3,$4,$5)",
    )
    .bind(&hostname)
    .bind(&sync.zone_id)
    .bind(sync.sending_enabled)
    .bind(sync.routing_enabled)
    .bind(&sync.error_summary)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    let row = sqlx::query(
        "SELECT hostname, zone_id, sending_enabled, routing_enabled, setup_error, created_ts FROM mail.domain WHERE hostname = $1",
    )
    .bind(&hostname)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut d = row_to_proto(&row);
    d.setup_steps = sync.steps;
    Ok(d)
}

pub async fn fix_admin(pool: &PgPool, viewer_iid: i64, raw: &str) -> Result<MailDomain, String> {
    if !is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let hostname = normalize_domain(raw);
    if hostname.is_empty() {
        return Err("hostname required".into());
    }
    let exists: bool = sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM mail.domain WHERE lower(hostname) = lower($1))")
        .bind(&hostname)
        .fetch_one(pool)
        .await
        .map_err(|e| e.to_string())?;
    if !exists {
        return Err(format!("domain not registered: {hostname}"));
    }
    let cfg = CfConfig::from_env().ok_or_else(|| "CLOUDFLARE_API_TOKEN not configured".to_string())?;
    let sync = sync_cf(&cfg, &hostname).await;
    sqlx::query(
        "UPDATE mail.domain SET zone_id = $2, sending_enabled = $3, routing_enabled = $4, setup_error = $5, updated_ts = NOW() WHERE lower(hostname) = lower($1)",
    )
    .bind(&hostname)
    .bind(&sync.zone_id)
    .bind(sync.sending_enabled)
    .bind(sync.routing_enabled)
    .bind(&sync.error_summary)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    let row = sqlx::query(
        "SELECT hostname, zone_id, sending_enabled, routing_enabled, setup_error, created_ts FROM mail.domain WHERE lower(hostname) = lower($1)",
    )
    .bind(&hostname)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut d = row_to_proto(&row);
    d.setup_steps = sync.steps;
    Ok(d)
}

/// Site-domain mail result. `mail_status` is `ready` or `failed`.
pub struct MailOnboard {
    pub mail_status: String,
    pub mail_error: String,
}

/// True when the registrable zone for `hostname` is in the Cloudflare account.
/// Missing `CLOUDFLARE_API_TOKEN` is an error. An empty zone list is `Ok(false)`.
pub async fn zone_in_cloudflare(hostname: &str) -> Result<bool, String> {
    let cfg = CfConfig::from_env().ok_or_else(|| "CLOUDFLARE_API_TOKEN not configured".to_string())?;
    let apex = zone_apex(hostname);
    match crate::cloudflare::zone_lookup(&cfg, &apex).await {
        Ok(_) => Ok(true),
        Err(e) if cf_zone_missing(&e) => Ok(false),
        Err(e) => Err(e),
    }
}

/// Email Sending + Routing for a site hostname. Does not require a mail admin.
/// Does not insert `mail.mailbox`.
pub async fn onboard_zone_for_site(pool: &PgPool, hostname: &str) -> Result<MailOnboard, String> {
    let hostname = normalize_domain(hostname);
    if hostname.is_empty() || !hostname.contains('.') {
        return Err("invalid domain".into());
    }
    let existing = sqlx::query(
        "SELECT sending_enabled, routing_enabled FROM mail.domain WHERE lower(hostname) = lower($1)",
    )
    .bind(&hostname)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if let Some(row) = &existing {
        let sending: bool = row.get("sending_enabled");
        let routing: bool = row.get("routing_enabled");
        if sending && routing {
            return Ok(mail_ready());
        }
    }
    let cfg = CfConfig::from_env().ok_or_else(|| "CLOUDFLARE_API_TOKEN not configured".to_string())?;
    let apex = zone_apex(&hostname);
    let zone = match crate::cloudflare::zone_lookup(&cfg, &apex).await {
        Ok(z) => z,
        Err(e) if cf_zone_missing(&e) => {
            return Ok(MailOnboard {
                mail_status: "failed".into(),
                mail_error: "The zone is not in the Cloudflare account.".into(),
            });
        }
        Err(e) => return Err(e),
    };
    let mut errors = Vec::new();
    let sending_ok = match crate::cloudflare::email_sending_ensure(&cfg, &zone.id, &hostname).await {
        Ok((ok, detail)) => {
            if !ok {
                errors.push(detail);
            }
            ok
        }
        Err(e) => {
            errors.push(e);
            false
        }
    };
    let worker = receive_worker_name();
    let routing_ok = match crate::cloudflare::routing_catch_all_set_worker(&cfg, &zone.id, &worker).await {
        Ok(_) => true,
        Err(e) => {
            errors.push(e);
            false
        }
    };
    let error_summary = errors.join("; ");
    if existing.is_some() {
        sqlx::query(
            "UPDATE mail.domain SET zone_id = $2, sending_enabled = $3, routing_enabled = $4, setup_error = $5, updated_ts = NOW() WHERE lower(hostname) = lower($1)",
        )
        .bind(&hostname)
        .bind(&zone.id)
        .bind(sending_ok)
        .bind(routing_ok)
        .bind(&error_summary)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    } else {
        sqlx::query(
            "INSERT INTO mail.domain (hostname, zone_id, sending_enabled, routing_enabled, setup_error) VALUES ($1,$2,$3,$4,$5)",
        )
        .bind(&hostname)
        .bind(&zone.id)
        .bind(sending_ok)
        .bind(routing_ok)
        .bind(&error_summary)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    }
    if sending_ok && routing_ok {
        Ok(mail_ready())
    } else {
        Ok(MailOnboard {
            mail_status: "failed".into(),
            mail_error: if error_summary.is_empty() {
                "Email sending or routing is not enabled.".into()
            } else {
                error_summary
            },
        })
    }
}

fn mail_ready() -> MailOnboard {
    MailOnboard {
        mail_status: "ready".into(),
        mail_error: String::new(),
    }
}

fn cf_zone_missing(err: &str) -> bool {
    err.starts_with("domain not found in Cloudflare account")
}

/// Registrable zone name passed to `GET /zones?name=`.
fn zone_apex(hostname: &str) -> String {
    let host = normalize_domain(hostname).trim_matches('.').to_string();
    let labels: Vec<&str> = host.split('.').filter(|s| !s.is_empty()).collect();
    if labels.len() <= 2 {
        return labels.join(".");
    }
    let last2 = format!("{}.{}", labels[labels.len() - 2], labels[labels.len() - 1]);
    if multi_part_suffix(&last2) && labels.len() >= 3 {
        return format!(
            "{}.{}.{}",
            labels[labels.len() - 3],
            labels[labels.len() - 2],
            labels[labels.len() - 1]
        );
    }
    last2
}

fn multi_part_suffix(suffix: &str) -> bool {
    const SUFFIXES: &[&str] = &[
        "co.id", "or.id", "ac.id", "go.id", "sch.id", "web.id", "my.id", "biz.id", "des.id", "co.uk",
        "org.uk", "ac.uk", "gov.uk", "com.au", "net.au", "org.au", "edu.au", "co.jp", "ne.jp", "or.jp",
        "com.br", "com.sg", "com.mx", "co.nz", "co.za", "com.my",
    ];
    SUFFIXES.iter().any(|s| *s == suffix)
}

struct Sync {
    zone_id: String,
    sending_enabled: bool,
    routing_enabled: bool,
    steps: Vec<MailDomainSetupStep>,
    error_summary: String,
}

async fn sync_cf(cfg: &CfConfig, hostname: &str) -> Sync {
    let mut steps = Vec::new();
    let mut errors = Vec::new();
    let zone = match crate::cloudflare::zone_lookup(cfg, hostname).await {
        Ok(z) => {
            steps.push(step("zone", "ok", format!("zone {}", z.id)));
            z
        }
        Err(e) => {
            steps.push(step("zone", "error", e.clone()));
            return Sync { zone_id: String::new(), sending_enabled: false, routing_enabled: false, steps, error_summary: e };
        }
    };
    let (sending_ok, _) = match crate::cloudflare::email_sending_ensure(cfg, &zone.id, hostname).await {
        Ok((ok, d)) => {
            steps.push(step("sending", if ok { "ok" } else { "error" }, d.clone()));
            (ok, d)
        }
        Err(e) => {
            steps.push(step("sending", "error", e.clone()));
            errors.push(e);
            (false, String::new())
        }
    };
    let worker = receive_worker_name();
    let routing_ok = match crate::cloudflare::routing_catch_all_set_worker(cfg, &zone.id, &worker).await {
        Ok(d) => {
            steps.push(step("routing", "ok", format!("{d} ({worker})")));
            true
        }
        Err(e) => {
            steps.push(step("routing", "error", e.clone()));
            errors.push(e);
            false
        }
    };
    Sync {
        zone_id: zone.id,
        sending_enabled: sending_ok,
        routing_enabled: routing_ok,
        steps,
        error_summary: errors.join("; "),
    }
}

fn step(key: &str, status: &str, detail: String) -> MailDomainSetupStep {
    MailDomainSetupStep { key: key.into(), status: status.into(), detail }
}

fn row_to_proto(row: &sqlx::postgres::PgRow) -> MailDomain {
    let created_ts: DateTime<Utc> = row.get("created_ts");
    MailDomain {
        hostname: row.get("hostname"),
        zone_id: row.get("zone_id"),
        sending_enabled: row.get("sending_enabled"),
        routing_enabled: row.get("routing_enabled"),
        created_ts_ms: created_ts.timestamp_millis(),
        setup_steps: Vec::new(),
        error_summary: row.get("setup_error"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_email_domain_from_address() {
        assert_eq!(
            parse_email_domain("  Ada@Shop.Example.COM ").as_deref(),
            Some("shop.example.com")
        );
        assert_eq!(parse_email_domain("no-at"), None);
        assert_eq!(parse_email_domain("local@"), None);
        assert_eq!(parse_email_domain("a@b.co.id").as_deref(), Some("b.co.id"));
    }

    #[test]
    fn zone_apex_is_registrable_name() {
        assert_eq!(zone_apex("Example.COM"), "example.com");
        assert_eq!(zone_apex("www.shop.example.com"), "example.com");
        assert_eq!(zone_apex("a.b.example.co.id"), "example.co.id");
        assert_eq!(zone_apex("shop.example.co.uk"), "example.co.uk");
    }
}
