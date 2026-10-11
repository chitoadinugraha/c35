use c35_proto::{ReqDeviceEgressLease, ResDeviceEgressLease};
use c35_store::PgPool;
use chrono::{Duration as ChronoDuration, Utc};
use rand::Rng;
use sqlx::types::Json;
use sqlx::Row;

use super::allowlist::DEFAULT_HOSTS;
use crate::remote_signaling::device_remote_allowed;

fn secret_hash(password: &str) -> String {
    blake3::hash(password.as_bytes()).to_hex().to_string()
}

fn random_password() -> String {
    let mut rng = rand::thread_rng();
    let bytes: [u8; 24] = rng.gen();
    base64::Engine::encode(&base64::engine::general_purpose::URL_SAFE_NO_PAD, bytes)
}

pub struct LeaseContext {
    #[allow(dead_code)]
    pub lease_id: i64,
    pub device_iid: i64,
    #[allow(dead_code)]
    pub owner_iid: i64,
    pub allow_hosts: Vec<String>,
}

pub async fn device_egress_lease_mint(
    pool: &PgPool,
    owner_iid: i64,
    req: ReqDeviceEgressLease,
    allow_hosts: Option<Vec<String>>,
) -> Result<ResDeviceEgressLease, String> {
    let device_iid = req.device_iid;
    if device_iid <= 0 {
        return Err("device_iid required".into());
    }
    device_remote_allowed(pool, owner_iid, device_iid).await?;

    let ttl = if req.ttl_sec == 0 {
        600
    } else {
        req.ttl_sec.clamp(60, 3600)
    };
    let lease_id = c35_store::snowflake_id();
    let password = random_password();
    let hash = secret_hash(&password);
    let expires = Utc::now() + ChronoDuration::seconds(ttl as i64);
    let hosts = allow_hosts.unwrap_or_default();
    let allow_json = Json(hosts);

    sqlx::query(
        r#"
        INSERT INTO ai.device_egress_lease
            (lease_id, device_iid, owner_iid, req_id, secret_hash, allow_hosts_json, expires_ts)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        "#,
    )
    .bind(lease_id)
    .bind(device_iid)
    .bind(owner_iid)
    .bind(req.req_id.trim())
    .bind(&hash)
    .bind(allow_json)
    .bind(expires)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let proxy_url = std::env::var("C35_EGRESS_PROXY_PUBLIC_URL")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "https://proxy.alienai.id:443".to_string());

    Ok(ResDeviceEgressLease {
        proxy_url,
        username: lease_id.to_string(),
        password,
        expires_ts_ms: expires.timestamp_millis(),
        device_iid,
    })
}

pub async fn lease_validate_basic_auth(
    pool: &PgPool,
    username: &str,
    password: &str,
) -> Result<LeaseContext, String> {
    let lease_id: i64 = username.trim().parse().map_err(|_| "invalid proxy credentials")?;
    let row = sqlx::query(
        r#"
        SELECT device_iid, owner_iid, secret_hash, allow_hosts_json, expires_ts, revoked_ts
        FROM ai.device_egress_lease
        WHERE lease_id = $1
        "#,
    )
    .bind(lease_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "invalid proxy credentials".to_string())?;

    if row
        .try_get::<Option<chrono::DateTime<Utc>>, _>("revoked_ts")
        .ok()
        .flatten()
        .is_some()
    {
        return Err("lease revoked".into());
    }
    let expires: chrono::DateTime<Utc> = row.try_get("expires_ts").map_err(|e| e.to_string())?;
    if expires < Utc::now() {
        return Err("lease expired".into());
    }
    let hash: String = row.try_get("secret_hash").map_err(|e| e.to_string())?;
    if hash != secret_hash(password) {
        return Err("invalid proxy credentials".into());
    }
    let allow_hosts: Vec<String> = row
        .try_get::<Json<Vec<String>>, _>("allow_hosts_json")
        .map(|j| j.0)
        .unwrap_or_else(|_| DEFAULT_HOSTS.iter().map(|s| s.to_string()).collect());

    Ok(LeaseContext {
        lease_id,
        device_iid: row.try_get("device_iid").map_err(|e| e.to_string())?,
        owner_iid: row.try_get("owner_iid").map_err(|e| e.to_string())?,
        allow_hosts,
    })
}

pub fn egress_enabled() -> bool {
    std::env::var("C35_EGRESS_PROXY_ENABLED")
        .map(|v| v == "1" || v.eq_ignore_ascii_case("true"))
        .unwrap_or(false)
}

pub fn egress_listen_addr() -> String {
    std::env::var("C35_EGRESS_PROXY_ADDR")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "0.0.0.0:8443".to_string())
}
