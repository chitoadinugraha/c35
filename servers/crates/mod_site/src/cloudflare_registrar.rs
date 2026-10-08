//! Cloudflare Registrar search and check. Credentials come from the environment only.

use serde::Deserialize;

const CF_API: &str = "https://api.cloudflare.com/client/v4";
const NOT_CONFIGURED: &str = "cloudflare registrar is not configured";

#[derive(Debug, Clone, PartialEq)]
pub struct DomainHit {
    pub name: String,
    pub registrable: bool,
    pub reason: String,
    pub registration_cost: String,
    pub currency: String,
}

/// `(token, account_id)` from `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.
pub fn registrar_config() -> Result<(String, String), String> {
    let token = env_nonempty("CLOUDFLARE_API_TOKEN")?;
    let account_id = env_nonempty("CLOUDFLARE_ACCOUNT_ID")?;
    Ok((token, account_id))
}

fn env_nonempty(key: &str) -> Result<String, String> {
    std::env::var(key)
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .ok_or_else(|| NOT_CONFIGURED.to_string())
}

fn cf_http() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .user_agent("c35-mod_site-registrar/1")
        .build()
        .map_err(|e| e.to_string())
}

#[derive(Debug, Deserialize)]
struct CfEnvelope {
    success: bool,
    errors: Option<Vec<CfErr>>,
    result: Option<serde_json::Value>,
}

#[derive(Debug, Deserialize)]
struct CfErr {
    message: Option<String>,
}

#[derive(Debug, Deserialize)]
struct CfDomainList {
    domains: Option<Vec<CfDomainHit>>,
}

#[derive(Debug, Deserialize)]
struct CfDomainHit {
    name: Option<String>,
    registrable: Option<bool>,
    availability: Option<String>,
    reason: Option<String>,
    currency: Option<String>,
    registration_cost: Option<serde_json::Value>,
    price: Option<serde_json::Value>,
    pricing: Option<CfPricing>,
}

#[derive(Debug, Deserialize)]
struct CfPricing {
    currency: Option<String>,
    registration_cost: Option<serde_json::Value>,
}

fn cf_err_msg(env: &CfEnvelope) -> String {
    env.errors
        .as_ref()
        .and_then(|e| e.first())
        .and_then(|x| x.message.clone())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "Cloudflare API error".into())
}

fn json_cost(v: Option<&serde_json::Value>) -> String {
    match v {
        Some(serde_json::Value::String(s)) => s.trim().to_string(),
        Some(serde_json::Value::Number(n)) => n.to_string(),
        _ => String::new(),
    }
}

fn hit_from_cf(d: CfDomainHit) -> Option<DomainHit> {
    let name = d.name?.trim().to_lowercase();
    if name.is_empty() {
        return None;
    }
    let registrable = match d.registrable {
        Some(v) => v,
        None => matches!(
            d.availability.as_deref().map(|s| s.trim().to_ascii_lowercase()).as_deref(),
            Some("available") | Some("registrable")
        ),
    };
    let (currency, registration_cost) = match d.pricing {
        Some(p) => (
            p.currency.unwrap_or_else(|| d.currency.unwrap_or_default()),
            {
                let cost = json_cost(p.registration_cost.as_ref());
                if cost.is_empty() {
                    json_cost(d.price.as_ref())
                } else {
                    cost
                }
            },
        ),
        None => (
            d.currency.unwrap_or_default(),
            {
                let cost = json_cost(d.registration_cost.as_ref());
                if cost.is_empty() {
                    json_cost(d.price.as_ref())
                } else {
                    cost
                }
            },
        ),
    };
    Some(DomainHit {
        name,
        registrable,
        reason: d.reason.unwrap_or_default(),
        registration_cost,
        currency,
    })
}

fn hits_from_result(result: Option<serde_json::Value>) -> Result<Vec<DomainHit>, String> {
    let Some(result) = result else {
        return Ok(Vec::new());
    };
    let domains = if result.is_array() {
        serde_json::from_value::<Vec<CfDomainHit>>(result).map_err(|e| e.to_string())?
    } else {
        serde_json::from_value::<CfDomainList>(result)
            .map_err(|e| e.to_string())?
            .domains
            .unwrap_or_default()
    };
    Ok(domains.into_iter().filter_map(hit_from_cf).collect())
}

async fn cf_parse(res: reqwest::Response) -> Result<Vec<DomainHit>, String> {
    let body: CfEnvelope = res.json().await.map_err(|e| e.to_string())?;
    if !body.success {
        return Err(cf_err_msg(&body));
    }
    hits_from_result(body.result)
}

pub async fn cf_domain_search(query: &str, limit: u32) -> Result<Vec<DomainHit>, String> {
    let (token, account_id) = registrar_config()?;
    let q = query.trim();
    if q.is_empty() {
        return Err("query is empty".into());
    }
    let limit = limit.clamp(1, 25);
    let mut url = reqwest::Url::parse(&format!(
        "{CF_API}/accounts/{account_id}/registrar/domain-search"
    ))
    .map_err(|e| e.to_string())?;
    url.query_pairs_mut()
        .append_pair("query", q)
        .append_pair("limit", &limit.to_string());
    let res = cf_http()?
        .get(url)
        .bearer_auth(&token)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let mut hits = cf_parse(res).await?;
    hits.truncate(limit as usize);
    Ok(hits)
}

pub struct CfRegistration {
    pub zone_id: String,
}

fn find_zone_id(v: &serde_json::Value) -> Option<String> {
    match v {
        serde_json::Value::Object(map) => {
            for key in ["zone_id", "zoneId"] {
                if let Some(s) = map.get(key).and_then(|x| x.as_str()) {
                    let s = s.trim();
                    if !s.is_empty() {
                        return Some(s.to_string());
                    }
                }
            }
            map.values().find_map(find_zone_id)
        }
        serde_json::Value::Array(items) => items.iter().find_map(find_zone_id),
        _ => None,
    }
}

async fn cf_zone_id_by_name(token: &str, hostname: &str) -> Result<String, String> {
    let mut url = reqwest::Url::parse(&format!("{CF_API}/zones")).map_err(|e| e.to_string())?;
    url.query_pairs_mut().append_pair("name", hostname);
    let res = cf_http()?
        .get(url)
        .bearer_auth(token)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: CfEnvelope = res.json().await.map_err(|e| e.to_string())?;
    if !body.success {
        return Err(cf_err_msg(&body));
    }
    let id = body
        .result
        .as_ref()
        .and_then(|v| v.as_array())
        .and_then(|rows| rows.first())
        .and_then(|row| row.get("id"))
        .and_then(|id| id.as_str())
        .unwrap_or("")
        .trim()
        .to_string();
    Ok(id)
}

/// Register `hostname` on Cloudflare Registrar. `zone_id` comes from the POST body, or `GET /zones?name=`.
pub async fn cf_domain_register(hostname: &str) -> Result<CfRegistration, String> {
    let (token, account_id) = registrar_config()?;
    let hostname = hostname.trim().to_lowercase();
    if hostname.is_empty() {
        return Err("hostname required".into());
    }
    let url = format!("{CF_API}/accounts/{account_id}/registrar/domains");
    let res = cf_http()?
        .post(url)
        .bearer_auth(&token)
        .json(&serde_json::json!({
            "name": hostname,
            "auto_renew": true,
            "privacy": true
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: CfEnvelope = res.json().await.map_err(|e| e.to_string())?;
    if !body.success {
        return Err(cf_err_msg(&body));
    }
    let mut zone_id = body.result.as_ref().and_then(find_zone_id).unwrap_or_default();
    if zone_id.is_empty() {
        zone_id = cf_zone_id_by_name(&token, &hostname).await?;
    }
    Ok(CfRegistration { zone_id })
}

/// Grey-cloud CNAME: `proxied` false, content `domain_cname_target()`, TTL automatic.
pub async fn cf_dns_cname_grey(zone_id: &str, hostname: &str) -> Result<(), String> {
    let (token, _) = registrar_config()?;
    let zone_id = zone_id.trim();
    if zone_id.is_empty() {
        return Err("zone_id required".into());
    }
    let hostname = hostname.trim().to_lowercase();
    if hostname.is_empty() {
        return Err("hostname required".into());
    }
    let url = format!("{CF_API}/zones/{zone_id}/dns_records");
    let res = cf_http()?
        .post(url)
        .bearer_auth(&token)
        .json(&serde_json::json!({
            "type": "CNAME",
            "name": hostname,
            "content": crate::dns_verify::domain_cname_target(),
            "proxied": false,
            "ttl": 1
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: CfEnvelope = res.json().await.map_err(|e| e.to_string())?;
    if !body.success {
        return Err(cf_err_msg(&body));
    }
    Ok(())
}

pub async fn cf_domain_check(domains: &[String]) -> Result<Vec<DomainHit>, String> {
    let (token, account_id) = registrar_config()?;
    let names: Vec<String> = domains
        .iter()
        .map(|d| d.trim().to_lowercase())
        .filter(|d| !d.is_empty())
        .take(20)
        .collect();
    if names.is_empty() {
        return Err("No domains to check".into());
    }
    let url = format!("{CF_API}/accounts/{account_id}/registrar/domain-check");
    let res = cf_http()?
        .post(url)
        .bearer_auth(&token)
        .json(&serde_json::json!({ "domains": names }))
        .send()
        .await
        .map_err(|e| e.to_string())?;
    cf_parse(res).await
}

#[cfg(test)]
mod tests {
    use super::*;

    struct EnvGuard {
        token: Option<String>,
        account: Option<String>,
    }

    impl EnvGuard {
        fn capture() -> Self {
            Self {
                token: std::env::var("CLOUDFLARE_API_TOKEN").ok(),
                account: std::env::var("CLOUDFLARE_ACCOUNT_ID").ok(),
            }
        }
    }

    impl Drop for EnvGuard {
        fn drop(&mut self) {
            restore("CLOUDFLARE_API_TOKEN", self.token.take());
            restore("CLOUDFLARE_ACCOUNT_ID", self.account.take());
        }
    }

    fn restore(key: &str, val: Option<String>) {
        match val {
            Some(v) => std::env::set_var(key, v),
            None => std::env::remove_var(key),
        }
    }

    #[test]
    fn registrar_config_fails_when_either_env_unset() {
        let _guard = EnvGuard::capture();

        std::env::remove_var("CLOUDFLARE_API_TOKEN");
        std::env::remove_var("CLOUDFLARE_ACCOUNT_ID");
        let err = registrar_config().expect_err("both unset");
        assert!(err.contains("cloudflare registrar is not configured"), "{err}");

        std::env::set_var("CLOUDFLARE_API_TOKEN", "tok");
        std::env::remove_var("CLOUDFLARE_ACCOUNT_ID");
        let err = registrar_config().expect_err("account unset");
        assert!(err.contains("cloudflare registrar is not configured"), "{err}");

        std::env::remove_var("CLOUDFLARE_API_TOKEN");
        std::env::set_var("CLOUDFLARE_ACCOUNT_ID", "acct");
        let err = registrar_config().expect_err("token unset");
        assert!(err.contains("cloudflare registrar is not configured"), "{err}");

        std::env::set_var("CLOUDFLARE_API_TOKEN", "   ");
        std::env::set_var("CLOUDFLARE_ACCOUNT_ID", "");
        let err = registrar_config().expect_err("blank values");
        assert!(err.contains("cloudflare registrar is not configured"), "{err}");
    }
}
