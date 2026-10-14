use anyhow::{anyhow, Result};
use c35_proto::{ReqSitePreviewToken, ResSitePreviewToken};
use hmac::{Hmac, Mac};
use sha2::Sha256;
use sqlx::{PgPool, Row};
use subtle::ConstantTimeEq;

use crate::doc::site_doc_from_json;
use crate::grant::site_grant_check;
use crate::render::{page_html_render, post_detail_html_render, product_detail_html_render, render_etag};
use crate::site_draft::site_draft_prepare_commerce_grid_doc;

type HmacSha256 = Hmac<Sha256>;

const DEFAULT_TTL_SECS: i32 = 300;

fn preview_secret() -> String {
    std::env::var("C35_SITE_PREVIEW_SECRET")
        .or_else(|_| std::env::var("C35_SESSION_SECRET"))
        .unwrap_or_else(|_| "dev-site-preview".into())
}

fn sign_payload(site_iid: i64, exp_ms: i64) -> String {
    let payload = format!("{site_iid}:{exp_ms}");
    let mut mac = HmacSha256::new_from_slice(preview_secret().as_bytes()).expect("hmac key");
    mac.update(payload.as_bytes());
    hex::encode(mac.finalize().into_bytes())
}

pub fn site_preview_token_verify(site_iid: i64, token: &str) -> Result<bool> {
    let parts: Vec<&str> = token.split(':').collect();
    if parts.len() != 3 {
        return Ok(false);
    }
    let tok_site: i64 = parts[0].parse().map_err(|_| anyhow!("invalid token site"))?;
    let exp_ms: i64 = parts[1].parse().map_err(|_| anyhow!("invalid token exp"))?;
    let sig = parts[2];
    if tok_site != site_iid {
        return Ok(false);
    }
    let now_ms = chrono::Utc::now().timestamp_millis();
    if exp_ms <= now_ms {
        return Ok(false);
    }
    let expected = sign_payload(site_iid, exp_ms);
    Ok(expected.as_bytes().ct_eq(sig.as_bytes()).into())
}

pub async fn site_preview_token_issue(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    ttl_secs: i32,
) -> Result<(String, i64)> {
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    let ttl = if ttl_secs <= 0 { DEFAULT_TTL_SECS } else { ttl_secs };
    let exp_ms = chrono::Utc::now().timestamp_millis() + (ttl as i64) * 1000;
    let sig = sign_payload(site_iid, exp_ms);
    Ok((format!("{site_iid}:{exp_ms}:{sig}"), exp_ms))
}

pub async fn site_preview_token(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePreviewToken,
) -> Result<ResSitePreviewToken> {
    let (token, expires_ts_ms) =
        site_preview_token_issue(pool, caller_iid, req.site_iid, req.ttl_secs).await?;
    Ok(ResSitePreviewToken {
        token,
        expires_ts_ms,
    })
}

/// Live HTML from the **active published** doc snapshot (`site.publish.doc_json`), not `site.render` cache.
pub async fn site_published_html_render(
    pool: &PgPool,
    site_iid: i64,
    page_path: &str,
) -> Result<(Vec<u8>, String)> {
    let pub_row = sqlx::query(
        r#"
        SELECT doc_json FROM site.publish
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        ORDER BY published_ts DESC
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("published snapshot not found"))?;
    let doc_json: serde_json::Value = pub_row.get("doc_json");
    let site_name = sqlx::query(r#"SELECT name FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#)
        .bind(site_iid)
        .fetch_optional(pool)
        .await?
        .map(|r| r.get::<String, _>("name"))
        .unwrap_or_else(|| "Site".into());
    let mut doc = site_doc_from_json(&doc_json);
    site_draft_prepare_commerce_grid_doc(pool, site_iid, &mut doc).await;
    let path = if page_path.is_empty() { "/" } else { page_path };
    let html = page_html_render(pool, site_iid, &doc, path, &site_name).await?;
    let etag = render_etag(&html);
    Ok((html.into_bytes(), etag))
}

pub async fn site_draft_html_render(
    pool: &PgPool,
    site_iid: i64,
    page_path: &str,
) -> Result<(Vec<u8>, String)> {
    let draft_row = sqlx::query(
        r#"
        SELECT doc_json FROM site.draft
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("draft not found"))?;
    let doc_json: serde_json::Value = draft_row.get("doc_json");
    let name_row = sqlx::query(r#"SELECT name FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#)
        .bind(site_iid)
        .fetch_optional(pool)
        .await?;
    let site_name = name_row
        .map(|r| r.get::<String, _>("name"))
        .unwrap_or_else(|| "Site".into());
    let path = if page_path.is_empty() { "/" } else { page_path };
    if let Some(pid_str) = path.strip_prefix("/products/") {
        if let Ok(product_id) = pid_str.trim().parse::<i64>() {
            if product_id > 0 {
                if let Some(html) =
                    product_detail_html_render(pool, site_iid, product_id, &site_name).await?
                {
                    let etag = render_etag(&html);
                    return Ok((html.into_bytes(), etag));
                }
                return Err(anyhow!("product not found"));
            }
        }
    }
    if let Some(post_str) = path.strip_prefix("/posts/") {
        if let Ok(post_id) = post_str.trim().parse::<i64>() {
            if post_id > 0 {
                if let Some(html) = post_detail_html_render(pool, site_iid, post_id, &site_name).await?
                {
                    let etag = render_etag(&html);
                    return Ok((html.into_bytes(), etag));
                }
                return Err(anyhow!("post not found"));
            }
        }
    }
    let mut doc = site_doc_from_json(&doc_json);
    site_draft_prepare_commerce_grid_doc(pool, site_iid, &mut doc).await;
    let html = page_html_render(pool, site_iid, &doc, path, &site_name).await?;
    let etag = render_etag(&html);
    Ok((html.into_bytes(), etag))
}
