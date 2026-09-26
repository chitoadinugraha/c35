//! Cloudflare zone lookup, Email Sending onboard, Email Routing catch-all.

use serde::Deserialize;

const CF_API: &str = "https://api.cloudflare.com/client/v4";

#[derive(Clone)]
pub struct CfConfig {
    pub token: String,
}

impl CfConfig {
    pub fn from_env() -> Option<Self> {
        let token = std::env::var("CLOUDFLARE_API_TOKEN")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())?;
        Some(Self { token })
    }
}

#[derive(Debug, Deserialize)]
struct CfEnvelope<T> {
    success: bool,
    errors: Option<Vec<CfErr>>,
    result: Option<T>,
}

#[derive(Debug, Deserialize)]
struct CfErr {
    message: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CfZone {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Deserialize)]
struct CfSendingSubdomain {
    name: String,
    enabled: bool,
}

fn cf_err_msg(env: &CfEnvelope<impl std::fmt::Debug>) -> String {
    env.errors
        .as_ref()
        .and_then(|e| e.first())
        .and_then(|x| x.message.clone())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "Cloudflare API error".into())
}

async fn cf_request(
    client: &reqwest::Client,
    token: &str,
    method: reqwest::Method,
    url: &str,
    body: Option<serde_json::Value>,
) -> Result<reqwest::Response, String> {
    let mut req = client
        .request(method, url)
        .header("Authorization", format!("Bearer {token}"))
        .header("Content-Type", "application/json");
    if let Some(b) = body {
        req = req.json(&b);
    }
    req.send()
        .await
        .map_err(|e| e.to_string())?
        .error_for_status()
        .map_err(|e| e.to_string())
}

pub fn normalize_domain(raw: &str) -> String {
    let mut s = raw.trim().to_lowercase();
    if let Some(stripped) = s.strip_prefix("https://") {
        s = stripped.to_string();
    }
    if let Some(stripped) = s.strip_prefix("http://") {
        s = stripped.to_string();
    }
    s.split('/').next().unwrap_or("").trim().to_string()
}

pub async fn zone_lookup(cfg: &CfConfig, domain: &str) -> Result<CfZone, String> {
    let domain = normalize_domain(domain);
    if domain.is_empty() {
        return Err("domain required".into());
    }
    let client = reqwest::Client::builder()
        .user_agent("c35-mod_mail/1")
        .build()
        .map_err(|e| e.to_string())?;
    let mut url = reqwest::Url::parse(&format!("{CF_API}/zones")).map_err(|e| e.to_string())?;
    url.query_pairs_mut().append_pair("name", &domain);
    let resp = cf_request(&client, &cfg.token, reqwest::Method::GET, url.as_str(), None).await?;
    let env: CfEnvelope<Vec<CfZone>> = resp.json().await.map_err(|e| e.to_string())?;
    if !env.success {
        return Err(cf_err_msg(&env));
    }
    let zones = env.result.unwrap_or_default();
    let zone = zones
        .into_iter()
        .find(|z| z.name.eq_ignore_ascii_case(&domain))
        .or_else(|| {
            // CF may return parent zone for subdomains ΓÇö accept exact name match first.
            None
        });
    match zone {
        Some(z) => Ok(z),
        None => Err(format!(
            "domain not found in Cloudflare account: {domain}"
        )),
    }
}

pub async fn email_sending_ensure(
    cfg: &CfConfig,
    zone_id: &str,
    domain: &str,
) -> Result<(bool, String), String> {
    let domain = normalize_domain(domain);
    let client = reqwest::Client::builder()
        .user_agent("c35-mod_mail/1")
        .build()
        .map_err(|e| e.to_string())?;
    let list_url = format!("{CF_API}/zones/{zone_id}/email/sending/subdomains");
    let resp = cf_request(&client, &cfg.token, reqwest::Method::GET, &list_url, None).await?;
    let env: CfEnvelope<Vec<CfSendingSubdomain>> = resp.json().await.map_err(|e| e.to_string())?;
    if !env.success {
        return Err(cf_err_msg(&env));
    }
    for sub in env.result.unwrap_or_default() {
        if sub.name.eq_ignore_ascii_case(&domain) && sub.enabled {
            return Ok((true, "already enabled".into()));
        }
    }
    let body = serde_json::json!({ "name": domain });
    let post_url = format!("{CF_API}/zones/{zone_id}/email/sending/subdomains");
    let resp = cf_request(
        &client,
        &cfg.token,
        reqwest::Method::POST,
        &post_url,
        Some(body),
    )
    .await?;
    let env: CfEnvelope<CfSendingSubdomain> = resp.json().await.map_err(|e| e.to_string())?;
    if !env.success {
        return Err(cf_err_msg(&env));
    }
    let sub = env.result.unwrap_or(CfSendingSubdomain {
        name: domain.clone(),
        enabled: false,
    });
    if sub.enabled {
        Ok((true, "onboarded".into()))
    } else {
        Ok((false, "onboard requested but not yet enabled".into()))
    }
}

#[derive(Debug, Deserialize)]
struct CfCatchAllRule {
    enabled: Option<bool>,
    actions: Option<Vec<CfRoutingAction>>,
}

#[derive(Debug, Deserialize)]
struct CfRoutingAction {
    #[serde(rename = "type")]
    action_type: Option<String>,
    value: Option<Vec<String>>,
}

pub async fn routing_catch_all_worker_enabled(
    cfg: &CfConfig,
    zone_id: &str,
    worker_name: &str,
) -> Result<bool, String> {
    let client = reqwest::Client::builder()
        .user_agent("c35-mod_mail/1")
        .build()
        .map_err(|e| e.to_string())?;
    let url = format!("{CF_API}/zones/{zone_id}/email/routing/rules/catch_all");
    let resp = cf_request(&client, &cfg.token, reqwest::Method::GET, &url, None).await?;
    let env: CfEnvelope<CfCatchAllRule> = resp.json().await.map_err(|e| e.to_string())?;
    if !env.success {
        return Err(cf_err_msg(&env));
    }
    let rule = env.result.unwrap_or(CfCatchAllRule {
        enabled: None,
        actions: None,
    });
    if !rule.enabled.unwrap_or(false) {
        return Ok(false);
    }
    let actions = rule.actions.unwrap_or_default();
    for a in actions {
        if a.action_type.as_deref() == Some("worker") {
            let vals = a.value.unwrap_or_default();
            if vals.iter().any(|v| v == worker_name) {
                return Ok(true);
            }
        }
    }
    Ok(false)
}

pub async fn routing_catch_all_set_worker(
    cfg: &CfConfig,
    zone_id: &str,
    worker_name: &str,
) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .user_agent("c35-mod_mail/1")
        .build()
        .map_err(|e| e.to_string())?;
    if routing_catch_all_worker_enabled(cfg, zone_id, worker_name).await? {
        return Ok("already configured".into());
    }
    let body = serde_json::json!({
        "enabled": true,
        "matchers": [{ "type": "all" }],
        "actions": [{ "type": "worker", "value": [worker_name] }],
        "source": "api"
    });
    let url = format!("{CF_API}/zones/{zone_id}/email/routing/rules/catch_all");
    let resp = cf_request(
        &client,
        &cfg.token,
        reqwest::Method::PUT,
        &url,
        Some(body),
    )
    .await?;
    let env: CfEnvelope<CfCatchAllRule> = resp.json().await.map_err(|e| e.to_string())?;
    if !env.success {
        return Err(cf_err_msg(&env));
    }
    Ok("catch-all worker rule set".into())
}

pub fn receive_worker_name() -> String {
    std::env::var("MAIL_CF_RECEIVE_WORKER")
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "csa-mail-receive".to_string())
}
