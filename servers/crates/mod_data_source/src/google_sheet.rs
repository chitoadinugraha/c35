//! Google Sheets — public CSV export + optional service account bearer / Sheets API writes.

use std::path::Path;
use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::{bail, Context, Result};
use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio::sync::Mutex;

use crate::config::SOURCE_KIND_GOOGLE_SHEET;
use crate::store::DataSourceRow;

const GOOGLE_SCOPES: &str =
    "https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive.file";
const TOKEN_URL: &str = "https://oauth2.googleapis.com/token";

#[derive(Clone, Debug)]
pub struct GoogleSheetConfig {
    pub data_source_id: i64,
    pub name: String,
    pub spreadsheet_id: String,
    pub gid: String,
    pub sheet_name: String,
}

#[derive(Clone, Debug)]
pub struct ParsedSheetUrl {
    pub spreadsheet_id: String,
    pub gid: String,
}

struct SheetsApi {
    client_email: String,
    encoding_key: EncodingKey,
    http: Client,
    access: Mutex<CachedToken>,
}

struct CachedToken {
    value: String,
    expires_at: Instant,
}

#[derive(Deserialize)]
struct ServiceAccount {
    client_email: String,
    private_key: String,
}

#[derive(Serialize)]
struct JwtClaims<'a> {
    iss: &'a str,
    scope: &'a str,
    aud: &'a str,
    iat: u64,
    exp: u64,
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

use std::sync::OnceLock;

static API: OnceLock<Option<Arc<SheetsApi>>> = OnceLock::new();

pub fn parse_sheet_url(url: &str) -> Result<ParsedSheetUrl> {
    let url = url.trim();
    if url.is_empty() {
        bail!("empty sheet url");
    }
    let spreadsheet_id = extract_between(url, "/d/", "/")
        .or_else(|| extract_between(url, "/d/", "?"))
        .or_else(|| extract_between(url, "/d/", "#"))
        .or_else(|| {
            if url.len() > 20 && !url.contains('/') {
                Some(url.to_string())
            } else {
                None
            }
        })
        .filter(|s| !s.is_empty())
        .context("parse spreadsheet_id from url")?;
    let gid = extract_query_param(url, "gid")
        .or_else(|| extract_hash_param(url, "gid"))
        .unwrap_or_else(|| "0".to_string());
    Ok(ParsedSheetUrl {
        spreadsheet_id,
        gid,
    })
}

fn extract_between(s: &str, start: &str, end: &str) -> Option<String> {
    let pos = s.find(start)?;
    let rest = &s[pos + start.len()..];
    let end_pos = rest.find(end).unwrap_or(rest.len());
    let id = rest[..end_pos].trim();
    if id.is_empty() {
        None
    } else {
        Some(id.to_string())
    }
}

fn extract_query_param(url: &str, key: &str) -> Option<String> {
    let q = url.split('?').nth(1)?;
    for part in q.split('&') {
        let mut kv = part.splitn(2, '=');
        if kv.next() == Some(key) {
            return kv.next().map(|v| v.trim().to_string()).filter(|s| !s.is_empty());
        }
    }
    None
}

fn extract_hash_param(url: &str, key: &str) -> Option<String> {
    let h = url.split('#').nth(1)?;
    for part in h.split('&') {
        let mut kv = part.splitn(2, '=');
        if kv.next() == Some(key) {
            return kv.next().map(|v| v.trim().to_string()).filter(|s| !s.is_empty());
        }
    }
    None
}

pub fn sheet_tab_name(cfg: &GoogleSheetConfig) -> String {
    if !cfg.sheet_name.is_empty() {
        return cfg.sheet_name.clone();
    }
    if cfg.gid != "0" && !cfg.gid.is_empty() {
        return format!("gid{}", cfg.gid);
    }
    "Sheet1".to_string()
}

pub fn google_sheet_config_from_row(row: &DataSourceRow) -> Result<GoogleSheetConfig> {
    if row.source_kind != SOURCE_KIND_GOOGLE_SHEET {
        bail!("expected google_sheet source_kind");
    }
    let config = &row.config;
    let spreadsheet_id = config
        .get("spreadsheet_id")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .context("config.spreadsheet_id missing")?;
    let gid = config
        .get("gid")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("0")
        .to_string();
    let sheet_name = config
        .get("sheet_name")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .unwrap_or("")
        .to_string();
    Ok(GoogleSheetConfig {
        data_source_id: row.id,
        name: row.name.clone(),
        spreadsheet_id: spreadsheet_id.to_string(),
        gid,
        sheet_name,
    })
}

pub fn config_merge_sheet_url(config: &mut Value, view_url: &str) -> Result<()> {
    let parsed = parse_sheet_url(view_url)?;
    if let Some(obj) = config.as_object_mut() {
        if !obj.contains_key("spreadsheet_id") || obj.get("spreadsheet_id").and_then(|v| v.as_str()).unwrap_or("").is_empty() {
            obj.insert("spreadsheet_id".into(), json!(parsed.spreadsheet_id));
        }
        if !obj.contains_key("gid") || obj.get("gid").and_then(|v| v.as_str()).unwrap_or("").is_empty() {
            obj.insert("gid".into(), json!(parsed.gid));
        }
        obj.insert("view_url".into(), json!(view_url.trim()));
    }
    Ok(())
}

pub async fn google_sheet_read_csv(http: &Client, cfg: &GoogleSheetConfig) -> Result<String> {
    let url = format!(
        "https://docs.google.com/spreadsheets/d/{}/export?format=csv&gid={}",
        cfg.spreadsheet_id,
        cfg.gid
    );
    let mut req = http.get(&url);
    if let Ok(Some(api)) = sheets_api() {
        if let Ok(token) = access_token(&api).await {
            req = req.bearer_auth(token);
        }
    }
    let res = req
        .timeout(Duration::from_secs(5))
        .send()
        .await
        .context("fetch sheet csv export")?
        .error_for_status()
        .context("sheet csv export denied — share as Anyone with the link can view or invite the service account")?;
    let ct = res
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_lowercase();
    let body = res.text().await.context("read sheet csv body")?;
    if ct.contains("text/html")
        || body.trim_start().starts_with("<!DOCTYPE")
        || body.trim_start().starts_with("<html")
    {
        bail!("sheet csv export returned HTML — share as Anyone with the link can view or invite the service account");
    }
    Ok(body)
}

pub async fn google_sheet_write_update(cfg: &GoogleSheetConfig, range: &str, row: Vec<String>) -> Result<Value> {
    let api = sheets_api()?.context("Google Sheets write unavailable — service account not configured")?;
    let tab = sheet_tab_name(cfg);
    let full_range = if range.contains('!') {
        range.to_string()
    } else {
        format!("{}!{}", tab, range)
    };
    values_put(api.as_ref(), &cfg.spreadsheet_id, &full_range, vec![row]).await
}

pub async fn google_sheet_write_append(cfg: &GoogleSheetConfig, row: Vec<String>) -> Result<Value> {
    let api = sheets_api()?.context("Google Sheets write unavailable — service account not configured")?;
    let tab = sheet_tab_name(cfg);
    values_append(api.as_ref(), &cfg.spreadsheet_id, &tab, vec![row]).await
}

fn sheets_api() -> Result<Option<Arc<SheetsApi>>> {
    Ok(API
        .get_or_init(|| match load_sheets_api() {
            Ok(v) => v,
            Err(e) => {
                tracing::warn!("[data_source:gsheet] service account unavailable: {e:#}");
                None
            }
        })
        .clone())
}

fn load_sheets_api() -> Result<Option<Arc<SheetsApi>>> {
    let path = std::env::var("GOOGLE_SERVICE_ACCOUNT_PATH")
        .or_else(|_| std::env::var("FIREBASE_SERVICE_ACCOUNT_PATH"))
        .ok()
        .filter(|s| !s.trim().is_empty());
    let Some(path) = path else {
        return Ok(None);
    };
    let raw = std::fs::read_to_string(Path::new(&path))
        .with_context(|| format!("read service account at {}", path))?;
    let sa: ServiceAccount = serde_json::from_str(&raw).context("parse service account json")?;
    Ok(Some(Arc::new(SheetsApi {
        client_email: sa.client_email,
        encoding_key: EncodingKey::from_rsa_pem(sa.private_key.as_bytes())
            .context("parse service account private key")?,
        http: Client::new(),
        access: Mutex::new(CachedToken {
            value: String::new(),
            expires_at: Instant::now(),
        }),
    })))
}

async fn access_token(api: &SheetsApi) -> Result<String> {
    {
        let cached = api.access.lock().await;
        if !cached.value.is_empty() && cached.expires_at > Instant::now() {
            return Ok(cached.value.clone());
        }
    }
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let claims = JwtClaims {
        iss: &api.client_email,
        scope: GOOGLE_SCOPES,
        aud: TOKEN_URL,
        iat: now,
        exp: now + 3600,
    };
    let assertion = encode(&Header::new(Algorithm::RS256), &claims, &api.encoding_key)
        .context("sign sheets jwt")?;
    let res = api
        .http
        .post(TOKEN_URL)
        .form(&[
            ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
            ("assertion", assertion.as_str()),
        ])
        .send()
        .await
        .context("request google access token")?
        .error_for_status()
        .context("google access token http error")?
        .json::<TokenResponse>()
        .await
        .context("parse google access token")?;
    let expires_at = Instant::now() + Duration::from_secs(res.expires_in.saturating_sub(60));
    let mut cached = api.access.lock().await;
    cached.value = res.access_token.clone();
    cached.expires_at = expires_at;
    Ok(res.access_token)
}

async fn values_put(api: &SheetsApi, spreadsheet_id: &str, range: &str, values: Vec<Vec<String>>) -> Result<Value> {
    let token = access_token(api).await?;
    let url = format!(
        "https://sheets.googleapis.com/v4/spreadsheets/{}/values/{}?valueInputOption=USER_ENTERED",
        spreadsheet_id,
        urlencoding::encode(range)
    );
    let res = api
        .http
        .put(&url)
        .bearer_auth(&token)
        .json(&json!({ "values": values }))
        .send()
        .await
        .context("sheets values update request")?;
    let status = res.status();
    let body = res.text().await.unwrap_or_default();
    if !status.is_success() {
        bail!(
            "sheets update failed (HTTP {}): {} — share the sheet as Anyone with the link can edit",
            status,
            body.chars().take(300).collect::<String>()
        );
    }
    serde_json::from_str(&body).context("parse sheets update response")
}

async fn values_append(
    api: &SheetsApi,
    spreadsheet_id: &str,
    sheet_name: &str,
    values: Vec<Vec<String>>,
) -> Result<Value> {
    let token = access_token(api).await?;
    let range = format!("{}!A1", sheet_name);
    let url = format!(
        "https://sheets.googleapis.com/v4/spreadsheets/{}/values/{}:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS",
        spreadsheet_id,
        urlencoding::encode(&range)
    );
    let res = api
        .http
        .post(&url)
        .bearer_auth(&token)
        .json(&json!({ "values": values }))
        .send()
        .await
        .context("sheets values append request")?;
    let status = res.status();
    let body = res.text().await.unwrap_or_default();
    if !status.is_success() {
        bail!(
            "sheets append failed (HTTP {}): {} — share the sheet as Anyone with the link can edit",
            status,
            body.chars().take(300).collect::<String>()
        );
    }
    serde_json::from_str(&body).context("parse sheets append response")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_sheet_url_extracts_id_and_gid() {
        let u = "https://docs.google.com/spreadsheets/d/abc123XYZ/edit#gid=42";
        let p = parse_sheet_url(u).unwrap();
        assert_eq!(p.spreadsheet_id, "abc123XYZ");
        assert_eq!(p.gid, "42");
    }

    #[test]
    fn parse_sheet_url_query_gid() {
        let u = "https://docs.google.com/spreadsheets/d/abc/edit?gid=7";
        let p = parse_sheet_url(u).unwrap();
        assert_eq!(p.spreadsheet_id, "abc");
        assert_eq!(p.gid, "7");
    }
}
