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

use crate::access::config_write_allowed;
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
    pub write_allowed: bool,
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

#[derive(Deserialize)]
struct SpreadsheetGetResponse {
    properties: Option<SpreadsheetProperties>,
    sheets: Option<Vec<SheetEntry>>,
}

#[derive(Deserialize)]
struct SpreadsheetProperties {
    title: Option<String>,
}

#[derive(Deserialize)]
struct SheetEntry {
    properties: Option<SheetProperties>,
}

#[derive(Deserialize)]
struct SheetProperties {
    title: Option<String>,
    sheet_id: Option<i64>,
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
        .map(|g| normalize_sheet_gid(&g))
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

/// GID query/hash values may include trailing fragment junk (e.g. `0#gid=0`).
pub fn normalize_sheet_gid(raw: &str) -> String {
    let raw = raw.trim();
    let digits: String = raw.chars().take_while(|c| c.is_ascii_digit() || *c == '-').collect();
    if digits.is_empty() {
        "0".to_string()
    } else {
        digits
    }
}

pub fn is_placeholder_sheet_tab_title(title: &str) -> bool {
    let t = title.trim();
    if t.is_empty() {
        return true;
    }
    let lower = t.to_ascii_lowercase();
    lower == "sheet"
        || lower.starts_with("gid ")
        || lower.starts_with("sheet (gid")
        || lower.starts_with("tab (gid")
}

pub fn sheet_tab_title_or_index(raw: &str, index: usize) -> String {
    let t = raw.trim();
    if !is_placeholder_sheet_tab_title(t) {
        return t.to_string();
    }
    format!("Sheet{}", index + 1)
}

/// True when the tab title is a UI guess (not authoritative from Sheets API).
pub fn is_guess_sheet_tab_title(title: &str) -> bool {
    let t = title.trim();
    if t.is_empty() || is_placeholder_sheet_tab_title(t) {
        return true;
    }
    let lower = t.to_ascii_lowercase();
    if !lower.starts_with("sheet") {
        return false;
    }
    let rest = lower["sheet".len()..].trim();
    rest.is_empty() || rest.chars().all(|c| c.is_ascii_digit())
}

/// Quote a tab name for Sheets API A1 notation (spaces/special chars need single quotes).
pub fn sheet_a1_tab_quote(tab: &str) -> String {
    let t = tab.trim();
    if t.is_empty() {
        return t.to_string();
    }
    let simple = t
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_');
    if simple {
        return t.to_string();
    }
    format!("'{}'", t.replace('\'', "''"))
}

pub fn sheet_a1_range(tab: &str, cell_range: &str) -> String {
    let r = cell_range.trim();
    if r.contains('!') {
        return r.to_string();
    }
    format!("{}!{}", sheet_a1_tab_quote(tab), r)
}

fn tab_title_for_gid(tabs: &[(String, String)], gid: &str) -> Option<String> {
    tabs
        .iter()
        .find(|(_, g)| g == gid)
        .map(|(title, _)| title.trim().to_string())
        .filter(|t| !t.is_empty())
}

async fn google_sheet_tab_resolve(api: &SheetsApi, cfg: &GoogleSheetConfig) -> Result<String> {
    if let Ok((_, tabs)) = spreadsheet_metadata_api(api, &cfg.spreadsheet_id).await {
        if let Some(title) = tab_title_for_gid(&tabs, &cfg.gid) {
            if !is_guess_sheet_tab_title(&title) {
                return Ok(title);
            }
            if title != cfg.sheet_name.trim() {
                return Ok(title);
            }
        }
    }
    let stored = sheet_tab_name(cfg);
    if stored == "Sheet 1" {
        return Ok("Sheet1".to_string());
    }
    Ok(stored)
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
        write_allowed: config_write_allowed(config),
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

pub async fn google_sheet_metadata(http: &Client, spreadsheet_id: &str) -> Result<(String, Vec<(String, String)>)> {
    if let Ok(Some(api)) = sheets_api() {
        if let Ok((title, tabs)) = spreadsheet_metadata_api(api.as_ref(), spreadsheet_id).await {
            return Ok((title, tabs));
        }
    }
    let view_url = format!("https://docs.google.com/spreadsheets/d/{}/edit", spreadsheet_id);
    let res = http
        .get(&view_url)
        .timeout(Duration::from_secs(8))
        .send()
        .await;
    if let Ok(res) = res {
        if let Ok(body) = res.text().await {
            let tabs = sheets_tabs_from_html(&body);
            if let Some(title) = crate::google_url::html_title_from_document(&body) {
                return Ok((title, tabs));
            }
            if !tabs.is_empty() {
                return Ok((String::new(), tabs));
            }
        }
    }
    Ok((String::new(), vec![]))
}

/// Best-effort tab list from the public spreadsheet HTML bootstrap JSON.
pub fn sheets_tabs_from_html(html: &str) -> Vec<(String, String)> {
    let mut out = Vec::new();
    let mut seen = std::collections::HashSet::new();
    let needle = "\"sheetId\":";
    let mut pos = 0;
    while let Some(rel) = html[pos..].find(needle) {
        let idx = pos + rel;
        let after = &html[idx + needle.len()..];
        let gid: String = after
            .trim_start()
            .chars()
            .take_while(|c| c.is_ascii_digit() || *c == '-')
            .collect();
        if gid.is_empty() {
            pos = idx + needle.len();
            continue;
        }
        let window_start = idx.saturating_sub(280);
        let window_end = (idx + 400).min(html.len());
        let window = &html[window_start..window_end];
        let forward = &after[..after.len().min(400)];
        let sheet_id_pos_in_window = idx - window_start;
        let tab_index = out.len();
        let title = tab_title_from_fragment(forward, window, sheet_id_pos_in_window)
            .map(|t| sheet_tab_title_or_index(&t, tab_index))
            .unwrap_or_else(|| sheet_tab_title_or_index("", tab_index));
        if seen.insert(gid.clone()) {
            out.push((title, gid));
        }
        pos = idx + needle.len();
    }
    out.sort_by(|a, b| {
        let ga: i64 = a.1.parse().unwrap_or(0);
        let gb: i64 = b.1.parse().unwrap_or(0);
        ga.cmp(&gb)
    });
    out
}

fn tab_title_from_fragment(forward: &str, window: &str, sheet_id_pos_in_window: usize) -> Option<String> {
    json_string_after_key(forward, "title")
        .or_else(|| json_string_after_key(forward, "name"))
        .or_else(|| json_string_before_key(window, "title", sheet_id_pos_in_window))
        .or_else(|| json_string_before_key(window, "name", sheet_id_pos_in_window))
        .filter(|t| !t.is_empty())
}

fn json_string_after_key(s: &str, key: &str) -> Option<String> {
    for sep in [":\"", ": \""] {
        let pat = format!("\"{key}\"{sep}");
        let Some(start) = s.find(&pat) else { continue };
        let rest = &s[start + pat.len()..];
        let end = rest.find('"')?;
        let val = rest[..end].trim();
        if !val.is_empty() {
            return Some(decode_json_string_escapes(val));
        }
    }
    None
}

fn json_string_before_key(s: &str, key: &str, before_pos: usize) -> Option<String> {
    let slice = &s[..before_pos.min(s.len())];
    for sep in [":\"", ": \""] {
        let pat = format!("\"{key}\"{sep}");
        let Some(start) = slice.rfind(&pat) else { continue };
        let rest = &slice[start + pat.len()..];
        let end = rest.find('"')?;
        let val = rest[..end].trim();
        if !val.is_empty() {
            return Some(decode_json_string_escapes(val));
        }
    }
    None
}

fn decode_json_string_escapes(raw: &str) -> String {
    let mut out = String::with_capacity(raw.len());
    let mut chars = raw.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\\' {
            match chars.next() {
                Some('u') => {
                    let hex: String = chars.by_ref().take(4).collect();
                    if hex.len() == 4 {
                        if let Ok(code) = u32::from_str_radix(&hex, 16) {
                            if let Some(ch) = char::from_u32(code) {
                                out.push(ch);
                                continue;
                            }
                        }
                    }
                    out.push('\\');
                    out.push('u');
                    out.push_str(&hex);
                    continue;
                }
                Some('"') => out.push('"'),
                Some('\\') => out.push('\\'),
                Some('n') => out.push('\n'),
                Some('t') => out.push('\t'),
                Some(other) => {
                    out.push('\\');
                    out.push(other);
                }
                None => out.push('\\'),
            }
            continue;
        }
        out.push(c);
    }
    out
}

async fn spreadsheet_metadata_api(api: &SheetsApi, spreadsheet_id: &str) -> Result<(String, Vec<(String, String)>)> {
    let token = access_token(api).await?;
    let url = format!(
        "https://sheets.googleapis.com/v4/spreadsheets/{}?fields=properties.title,sheets.properties(title,sheetId)",
        spreadsheet_id
    );
    let res = api
        .http
        .get(&url)
        .bearer_auth(&token)
        .send()
        .await
        .context("sheets metadata request")?
        .error_for_status()
        .context("sheets metadata denied")?
        .json::<SpreadsheetGetResponse>()
        .await
        .context("parse sheets metadata")?;
    let title = res.properties.and_then(|p| p.title).unwrap_or_default();
    let tabs = res
        .sheets
        .unwrap_or_default()
        .into_iter()
        .enumerate()
        .filter_map(|(i, s)| {
            let p = s.properties?;
            let gid = p.sheet_id.map(|id| id.to_string()).filter(|g| !g.is_empty())?;
            let raw = p.title.unwrap_or_default();
            Some((sheet_tab_title_or_index(&raw, i), gid))
        })
        .collect();
    Ok((title, tabs))
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
    let tab = google_sheet_tab_resolve(api.as_ref(), cfg).await?;
    let full_range = sheet_a1_range(&tab, range);
    values_put(api.as_ref(), &cfg.spreadsheet_id, &full_range, vec![row]).await
}

pub async fn google_sheet_write_append(cfg: &GoogleSheetConfig, row: Vec<String>) -> Result<Value> {
    let api = sheets_api()?.context("Google Sheets write unavailable — service account not configured")?;
    let tab = google_sheet_tab_resolve(api.as_ref(), cfg).await?;
    let range = sheet_a1_range(&tab, "A1");
    values_append(api.as_ref(), &cfg.spreadsheet_id, &range, vec![row]).await
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
    if let Ok(json) = std::env::var("GOOGLE_APPLICATION_CREDENTIALS_JSON") {
        if !json.trim().is_empty() {
            let sa: ServiceAccount = serde_json::from_str(&json).context("parse service account json")?;
            return Ok(Some(sheets_api_from_account(sa)?));
        }
    }
    let path = std::env::var("GOOGLE_SERVICE_ACCOUNT_PATH")
        .or_else(|_| std::env::var("FIREBASE_SERVICE_ACCOUNT_PATH"))
        .ok()
        .filter(|s| !s.trim().is_empty());
    if let Some(path) = path {
        let raw = std::fs::read_to_string(Path::new(&path))
            .with_context(|| format!("read service account at {}", path))?;
        let sa: ServiceAccount = serde_json::from_str(&raw).context("parse service account json")?;
        return Ok(Some(sheets_api_from_account(sa)?));
    }
    Ok(None)
}

fn sheets_api_from_account(sa: ServiceAccount) -> Result<Arc<SheetsApi>> {
    Ok(Arc::new(SheetsApi {
        client_email: sa.client_email,
        encoding_key: EncodingKey::from_rsa_pem(sa.private_key.as_bytes())
            .context("parse service account private key")?,
        http: Client::new(),
        access: Mutex::new(CachedToken {
            value: String::new(),
            expires_at: Instant::now(),
        }),
    }))
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
    range_a1: &str,
    values: Vec<Vec<String>>,
) -> Result<Value> {
    let token = access_token(api).await?;
    let url = format!(
        "https://sheets.googleapis.com/v4/spreadsheets/{}/values/{}:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS",
        spreadsheet_id,
        urlencoding::encode(range_a1)
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

    #[test]
    fn normalize_sheet_gid_strips_trailing_fragment() {
        assert_eq!(normalize_sheet_gid("0#gid=0"), "0");
        assert_eq!(normalize_sheet_gid("42"), "42");
    }

    #[test]
    fn sheets_tabs_from_html_parses_titles() {
        let html = r#"{"sheetId":0,"title":"Sheet1"},{"sheetId":123456,"title":"Sales"}"#;
        let tabs = sheets_tabs_from_html(html);
        assert!(tabs.iter().any(|(t, g)| t == "Sheet1" && g == "0"));
        assert!(tabs.iter().any(|(t, g)| t == "Sales" && g == "123456"));
    }

    #[test]
    fn sheets_tabs_from_html_title_before_sheet_id() {
        let html = r#"{"title":"Stock List","sheetId":0,"index":0}"#;
        let tabs = sheets_tabs_from_html(html);
        assert_eq!(tabs.len(), 1);
        assert_eq!(tabs[0].0, "Stock List");
        assert_eq!(tabs[0].1, "0");
    }

    #[test]
    fn sheet_a1_range_quotes_spaces() {
        assert_eq!(sheet_a1_range("Sheet 1", "B2"), "'Sheet 1'!B2");
        assert_eq!(sheet_a1_range("Sheet1", "B2"), "Sheet1!B2");
        assert_eq!(sheet_a1_range("Stock List", "A2:C2"), "'Stock List'!A2:C2");
    }

    #[test]
    fn is_guess_sheet_tab_title_detects_placeholders() {
        assert!(is_guess_sheet_tab_title("Sheet 1"));
        assert!(is_guess_sheet_tab_title("Sheet1"));
        assert!(!is_guess_sheet_tab_title("Menu"));
    }

    #[tokio::test]
    #[ignore = "live Google Sheets write — set GOOGLE_APPLICATION_CREDENTIALS_JSON"]
    async fn gsheet_write_update_live_smoke() {
        let _ = load_sheets_api().expect("load api");
        let cfg = GoogleSheetConfig {
            data_source_id: 0,
            name: "smoke".into(),
            spreadsheet_id: "10irW_az5QXTV62A2YmHbfZLFofAQNQ9Xdr8XYgA6ge0".into(),
            gid: "0".into(),
            sheet_name: "Sheet 1".into(),
            write_allowed: true,
        };
        google_sheet_write_update(&cfg, "Z99", vec!["c35-write-test".into()])
            .await
            .expect("write probe cell");
    }
}
