use anyhow::{anyhow, Result};
use c35_proto::{ReqSiteBootGet, ResSiteBootGet, SiteBootMode, SiteLink};
use serde_json::{json, Map, Value};
use sqlx::{PgPool, Row};

use crate::doc::site_doc_from_json;
use crate::grant::site_grant_check;
use crate::guest_product::{
    guest_product_list, product_grid_page_size, product_row_json, product_rows_for_grid,
};
use crate::site_config::site_capabilities_get;
use crate::site_link::site_link_boot_rows;
use crate::product_design::product_design_from_site_meta;
use crate::commerce_boot::{commerce_boot_build, order_progress_steps_json};
use crate::site_post::{post_boot_summary_json, site_post_boot_summaries};

fn avatar_url(pic: &str) -> String {
    let p = pic.trim();
    if p.is_empty() {
        return String::new();
    }
    if p.starts_with("http://") || p.starts_with("https://") || p.starts_with("/fs/") {
        return p.to_string();
    }
    format!("/fs/{}?v=thumb", p)
}

fn mode_label(mode: SiteBootMode) -> &'static str {
    match mode {
        SiteBootMode::Published => "published",
        SiteBootMode::Draft | SiteBootMode::Unspecified => "draft",
    }
}

fn link_boot_json(link: &SiteLink) -> Value {
    json!({
        "link_id": link.link_id,
        "sort_order": link.sort_order,
        "label": link.label,
        "url": link.url,
        "icon": link.icon,
        "is_pinned": link.is_pinned,
    })
}

pub fn site_boot_json_assemble(
    site_iid: i64,
    name: &str,
    alien_id: &str,
    pic: &str,
    mode: SiteBootMode,
    doc_json: &Value,
    capabilities: &Value,
    product_preload: Map<String, Value>,
    product_preload_meta: Map<String, Value>,
    links: &[SiteLink],
    posts_preload: &[Value],
) -> Value {
    let theme = doc_json.get("theme").cloned().unwrap_or_else(|| json!({}));
    let meta = doc_json.get("meta").cloned().unwrap_or_else(|| json!({}));
    let product_design = product_design_from_site_meta(&meta).unwrap_or_else(|| json!({}));
    let pages = doc_json.get("pages").cloned().unwrap_or_else(|| json!([]));
    json!({
        "site_id": site_iid,
        "site_iid": site_iid,
        "name": name,
        "alien_id": alien_id,
        "avatar_url": avatar_url(pic),
        "mode": mode_label(mode),
        "meta": meta,
        "product_design": product_design,
        "theme": theme,
        "pages": pages,
        "capabilities": capabilities,
        "product_preload": product_preload,
        "product_preload_meta": product_preload_meta,
        "links": links.iter().map(link_boot_json).collect::<Vec<_>>(),
        "posts_preload": posts_preload,
    })
}

async fn product_preload_for_doc(pool: &PgPool, site_iid: i64, doc_json: &Value) -> Result<Map<String, Value>> {
    let doc = site_doc_from_json(doc_json);
    let mut out = Map::new();
    for page in &doc.pages {
        for block in &page.blocks {
            if block.r#type != "product_grid" {
                continue;
            }
            let props: Value = if block.props_json.is_empty() {
                json!({})
            } else {
                serde_json::from_str(&block.props_json).unwrap_or_else(|_| json!({}))
            };
            let filter = props.get("filter").and_then(|x| x.as_str()).unwrap_or("all");
            let category = props.get("category").and_then(|x| x.as_str()).unwrap_or("");
            let limit = product_grid_page_size(&props);
            let rows = product_rows_for_grid(pool, site_iid, filter, category, limit).await?;
            let items: Vec<Value> = rows.iter().map(product_row_json).collect();
            out.insert(block.id.clone(), Value::Array(items));
        }
    }
    Ok(out)
}

async fn product_preload_meta_for_doc(pool: &PgPool, site_iid: i64, doc_json: &Value) -> Result<Map<String, Value>> {
    let doc = site_doc_from_json(doc_json);
    let mut out = Map::new();
    for page in &doc.pages {
        for block in &page.blocks {
            if block.r#type != "product_grid" {
                continue;
            }
            let props: Value = if block.props_json.is_empty() {
                json!({})
            } else {
                serde_json::from_str(&block.props_json).unwrap_or_else(|_| json!({}))
            };
            let filter = props.get("filter").and_then(|x| x.as_str()).unwrap_or("all");
            let category = props.get("category").and_then(|x| x.as_str()).unwrap_or("");
            let page_size = product_grid_page_size(&props);
            let listed =
                guest_product_list(pool, site_iid, filter, category, "", page_size).await?;
            if !listed.next_cursor.is_empty() {
                out.insert(
                    block.id.clone(),
                    json!({ "next_cursor": listed.next_cursor }),
                );
            }
        }
    }
    Ok(out)
}

async fn load_doc_json(pool: &PgPool, site_iid: i64, mode: SiteBootMode) -> Result<Value> {
    match mode {
        SiteBootMode::Published => {
            let row = sqlx::query(
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
            Ok(row.get("doc_json"))
        }
        SiteBootMode::Draft | SiteBootMode::Unspecified => {
            let row = sqlx::query(
                r#"
                SELECT doc_json FROM site.draft
                WHERE site_iid = $1 AND deleted_ts IS NULL
                "#,
            )
            .bind(site_iid)
            .fetch_optional(pool)
            .await?;
            Ok(row
                .map(|r| r.get("doc_json"))
                .unwrap_or_else(|| json!({ "pages": [], "theme": {}, "meta": {} })))
        }
    }
}

pub async fn site_boot_get(pool: &PgPool, caller_iid: i64, req: ReqSiteBootGet) -> Result<ResSiteBootGet> {
    if req.site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let mode_raw = SiteBootMode::try_from(req.mode).unwrap_or(SiteBootMode::Unspecified);
    let mode = if mode_raw == SiteBootMode::Unspecified {
        SiteBootMode::Draft
    } else {
        mode_raw
    };
    let id_row = sqlx::query(
        r#"
        SELECT alien_id, name, pic FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(req.site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site identity not found"))?;
    let alien_id: String = id_row.get("alien_id");
    let name: String = id_row.get("name");
    let pic: String = id_row.get::<Option<String>, _>("pic").unwrap_or_default();
    let doc_json = load_doc_json(pool, req.site_iid, mode).await?;
    let capabilities = site_capabilities_get(pool, req.site_iid).await;
    let product_preload = product_preload_for_doc(pool, req.site_iid, &doc_json).await?;
    let product_preload_meta =
        product_preload_meta_for_doc(pool, req.site_iid, &doc_json).await?;
    let links = site_link_boot_rows(pool, req.site_iid).await?;
    let posts = site_post_boot_summaries(pool, req.site_iid).await?;
    let posts_preload: Vec<Value> = posts.iter().map(post_boot_summary_json).collect();
    let meta = doc_json.get("meta").cloned().unwrap_or_else(|| json!({}));
    let commerce_boot = commerce_boot_build(pool, req.site_iid, &meta).await?;
    let boot = site_boot_json_assemble(
        req.site_iid,
        &name,
        &alien_id,
        &pic,
        mode,
        &doc_json,
        &capabilities,
        product_preload,
        product_preload_meta,
        &links,
        &posts_preload,
    );
    let boot = if let Some(obj) = boot.as_object() {
        let mut m = obj.clone();
        m.insert("commerce_boot".into(), commerce_boot);
        m.insert("order_progress_steps".into(), order_progress_steps_json());
        Value::Object(m)
    } else {
        boot
    };
    Ok(ResSiteBootGet {
        boot_json: boot.to_string(),
    })
}
