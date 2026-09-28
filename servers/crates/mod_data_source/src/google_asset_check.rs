//! Pre-flight check for Google asset URLs (title, tabs, access).

use std::time::Duration;

use anyhow::{bail, Context, Result};
use reqwest::Client;
use serde_json::{json, Value};

use crate::config::SOURCE_KIND_GOOGLE_SHEET;
use crate::google_sheet::{
    config_merge_sheet_url, google_sheet_metadata, google_sheet_read_csv, parse_sheet_url, sheet_tab_title_or_index,
    GoogleSheetConfig,
};
use crate::google_url::{
    config_merge_doc_url, config_merge_slide_url, html_title_from_document, parse_google_doc_url, parse_google_slide_url,
    SOURCE_KIND_GOOGLE_DOC, SOURCE_KIND_GOOGLE_SLIDE,
};

#[derive(Clone, Debug)]
pub struct SheetTabInfo {
    pub title: String,
    pub gid: String,
}

#[derive(Clone, Debug)]
pub struct AssetCheckResult {
    pub title: String,
    pub config: Value,
    pub tabs: Vec<SheetTabInfo>,
}

pub async fn data_source_check_run(http: &Client, source_kind: &str, view_url: &str) -> Result<AssetCheckResult> {
    let url = view_url.trim();
    if url.is_empty() {
        bail!("url required");
    }
    match source_kind {
        SOURCE_KIND_GOOGLE_SHEET => google_sheet_check(http, url).await,
        SOURCE_KIND_GOOGLE_DOC => google_doc_check(http, url).await,
        SOURCE_KIND_GOOGLE_SLIDE => google_slide_check(http, url).await,
        other => bail!("unsupported source_kind: {other}"),
    }
}

async fn google_sheet_check(http: &Client, view_url: &str) -> Result<AssetCheckResult> {
    let parsed = parse_sheet_url(view_url)?;
    let mut config = json!({ "view_url": view_url });
    config_merge_sheet_url(&mut config, view_url)?;
    let (api_title, api_tabs) = google_sheet_metadata(http, &parsed.spreadsheet_id).await?;
    let cfg = GoogleSheetConfig {
        data_source_id: 0,
        name: String::new(),
        spreadsheet_id: parsed.spreadsheet_id.clone(),
        gid: parsed.gid.clone(),
        sheet_name: String::new(),
        write_allowed: true,
    };
    google_sheet_read_csv(http, &cfg)
        .await
        .context("cannot read sheet — share as Anyone with the link can view or invite the service account")?;
    let title = if !api_title.is_empty() {
        api_title
    } else {
        html_page_title(http, view_url)
            .await?
            .unwrap_or_else(|| "Google Sheet".to_string())
    };
    let tabs = if api_tabs.is_empty() {
        vec![SheetTabInfo {
            title: sheet_tab_title_or_index("", 0),
            gid: parsed.gid.clone(),
        }]
    } else {
        let mut tabs: Vec<SheetTabInfo> = api_tabs
            .into_iter()
            .enumerate()
            .map(|(i, (title, gid))| SheetTabInfo {
                title: sheet_tab_title_or_index(&title, i),
                gid,
            })
            .collect();
        tabs.sort_by(|a, b| {
            let ga: i64 = a.gid.parse().unwrap_or(0);
            let gb: i64 = b.gid.parse().unwrap_or(0);
            ga.cmp(&gb)
        });
        tabs
    };
    Ok(AssetCheckResult { title, config, tabs })
}

async fn google_doc_check(http: &Client, view_url: &str) -> Result<AssetCheckResult> {
    let document_id = parse_google_doc_url(view_url)?;
    let export_url = format!("https://docs.google.com/document/d/{}/export?format=txt", document_id);
    verify_public_fetch(http, &export_url)
        .await
        .context("cannot read document — share as Anyone with the link can view")?;
    let mut config = json!({ "sync_scope": "all" });
    config_merge_doc_url(&mut config, view_url)?;
    let title = html_page_title(http, view_url)
        .await?
        .unwrap_or_else(|| "Google Doc".to_string());
    Ok(AssetCheckResult {
        title,
        config,
        tabs: vec![],
    })
}

async fn google_slide_check(http: &Client, view_url: &str) -> Result<AssetCheckResult> {
    parse_google_slide_url(view_url)?;
    let mut config = json!({ "sync_scope": "all" });
    config_merge_slide_url(&mut config, view_url)?;
    let title = html_page_title(http, view_url)
        .await?
        .unwrap_or_else(|| "Google Slides".to_string());
    Ok(AssetCheckResult {
        title,
        config,
        tabs: vec![],
    })
}

async fn verify_public_fetch(http: &Client, url: &str) -> Result<()> {
    let res = http
        .get(url)
        .timeout(Duration::from_secs(8))
        .send()
        .await
        .context("fetch url")?
        .error_for_status()
        .context("fetch denied")?;
    let body = res.text().await.context("read body")?;
    if body.trim_start().starts_with("<!DOCTYPE") || body.trim_start().starts_with("<html") {
        bail!("returned HTML — check sharing settings");
    }
    Ok(())
}

async fn html_page_title(http: &Client, url: &str) -> Result<Option<String>> {
    let res = http.get(url).timeout(Duration::from_secs(8)).send().await;
    let res = match res {
        Ok(r) => r,
        Err(_) => return Ok(None),
    };
    let body = res.text().await.unwrap_or_default();
    Ok(html_title_from_document(&body))
}