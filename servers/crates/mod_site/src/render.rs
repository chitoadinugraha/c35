use anyhow::{anyhow, Result};
use c35_proto::SiteDoc;
use serde_json::Value;
use sqlx::{PgPool, Row};

use crate::doc::site_doc_from_json;

pub struct ProductRow {
    pub product_id: i64,
    pub name: String,
    pub desc: String,
    pub price: i64,
    pub pic: String,
    pub category: String,
}

pub async fn product_rows_for_grid(
    pool: &PgPool,
    site_iid: i64,
    filter: &str,
    category: &str,
    limit: i32,
) -> Result<Vec<ProductRow>> {
    let lim = if limit <= 0 { 24 } else { limit.min(100) };
    let rows = if filter == "recommended" {
        sqlx::query(
            r#"
            SELECT product_id, name, "desc", price, pic, category
            FROM site.product
            WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE
              AND can_sell = TRUE AND recommended_guest = TRUE
            ORDER BY sort_order, product_id
            LIMIT $2
            "#,
        )
        .bind(site_iid)
        .bind(lim)
        .fetch_all(pool)
        .await?
    } else if !category.is_empty() {
        sqlx::query(
            r#"
            SELECT product_id, name, "desc", price, pic, category
            FROM site.product
            WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE
              AND can_sell = TRUE AND category = $2
            ORDER BY sort_order, product_id
            LIMIT $3
            "#,
        )
        .bind(site_iid)
        .bind(category)
        .bind(lim)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT product_id, name, "desc", price, pic, category
            FROM site.product
            WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE
              AND can_sell = TRUE
            ORDER BY sort_order, product_id
            LIMIT $2
            "#,
        )
        .bind(site_iid)
        .bind(lim)
        .fetch_all(pool)
        .await?
    };
    Ok(rows
        .iter()
        .map(|r| ProductRow {
            product_id: r.get("product_id"),
            name: r.get("name"),
            desc: r.get("desc"),
            price: r.get("price"),
            pic: r.get("pic"),
            category: r.get("category"),
        })
        .collect())
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

fn pic_url(pic: &str) -> String {
    let p = pic.trim();
    if p.is_empty() {
        return String::new();
    }
    if p.starts_with("http://") || p.starts_with("https://") || p.starts_with("/fs/") {
        return p.to_string();
    }
    format!("/fs/{}?v=thumb", p)
}

fn block_html(block_type: &str, props: &Value, products: &[ProductRow]) -> String {
    match block_type {
        "hero" => {
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let subtitle = props.get("subtitle").and_then(|x| x.as_str()).unwrap_or("");
            let pic = props.get("pic").and_then(|x| x.as_str()).unwrap_or("");
            let cta = props.get("cta").and_then(|x| x.as_str()).unwrap_or("");
            let cta_url = props.get("cta_url").and_then(|x| x.as_str()).unwrap_or("#");
            let bg = if pic.is_empty() {
                String::new()
            } else {
                format!(
                    r#"<div class="hero-bg"><img src="{}" alt="" loading="lazy"/></div>"#,
                    esc(&pic_url(pic))
                )
            };
            let btn = if cta.is_empty() {
                String::new()
            } else {
                format!(r#"<a class="hero-cta" href="{}">{}</a>"#, esc(cta_url), esc(cta))
            };
            format!(
                r#"<section class="block hero">{bg}<div class="hero-inner"><h1>{}</h1><p>{}</p>{}</div></section>"#,
                esc(title),
                esc(subtitle),
                btn
            )
        }
        "markdown" => {
            let content = props
                .get("content")
                .or_else(|| props.get("body"))
                .and_then(|x| x.as_str())
                .unwrap_or("");
            format!(
                r#"<section class="block markdown"><div class="md">{}</div></section>"#,
                esc(content).replace('\n', "<br/>")
            )
        }
        "image" => {
            let pic = props.get("pic").and_then(|x| x.as_str()).unwrap_or("");
            let alt = props.get("alt").and_then(|x| x.as_str()).unwrap_or("");
            let caption = props.get("caption").and_then(|x| x.as_str()).unwrap_or("");
            let cap = if caption.is_empty() {
                String::new()
            } else {
                format!(r#"<figcaption>{}</figcaption>"#, esc(caption))
            };
            format!(
                r#"<section class="block image"><figure><img src="{}" alt="{}" loading="lazy"/>{}</figure></section>"#,
                esc(&pic_url(pic)),
                esc(alt),
                cap
            )
        }
        "spacer" => {
            let h = props
                .get("height")
                .or_else(|| props.get("size"))
                .and_then(|x| x.as_i64())
                .unwrap_or(24);
            format!(r#"<div class="block spacer" style="height:{}px"></div>"#, h)
        }
        "product_grid" => {
            let cards = products
                .iter()
                .map(|p| {
                    let img = if p.pic.is_empty() {
                        String::new()
                    } else {
                        format!(
                            r#"<img src="{}" alt="" loading="lazy"/>"#,
                            esc(&pic_url(&p.pic))
                        )
                    };
                    format!(
                        "<article class=\"product-card\"><a href=\"#p{pid}\">{img}<h3>{name}</h3><p>{desc}</p><span class=\"price\">{price}</span></a></article>",
                        pid = p.product_id,
                        img = img,
                        name = esc(&p.name),
                        desc = esc(&p.desc),
                        price = p.price
                    )
                })
                .collect::<Vec<_>>()
                .join("");
            format!(
                r#"<section class="block product-grid"><div class="grid">{}</div></section>"#,
                cards
            )
        }
        _ => String::new(),
    }
}

pub async fn page_html_render(
    pool: &PgPool,
    site_iid: i64,
    doc: &SiteDoc,
    page_path: &str,
    site_name: &str,
) -> Result<String> {
    let page = doc
        .pages
        .iter()
        .find(|p| p.path == page_path || (page_path == "/" && p.path == "/"))
        .or_else(|| doc.pages.first())
        .ok_or_else(|| anyhow!("page not found"))?;
    let theme: Value = if doc.theme_json.is_empty() {
        Value::Object(Default::default())
    } else {
        serde_json::from_str(&doc.theme_json).unwrap_or(Value::Object(Default::default()))
    };
    let accent = theme
        .get("accent")
        .and_then(|x| x.as_str())
        .unwrap_or("#2563eb");
    let mut body = String::new();
    for block in &page.blocks {
        let props: Value = if block.props_json.is_empty() {
            Value::Object(Default::default())
        } else {
            serde_json::from_str(&block.props_json).unwrap_or(Value::Object(Default::default()))
        };
        let products = if block.r#type == "product_grid" {
            let filter = props.get("filter").and_then(|x| x.as_str()).unwrap_or("all");
            let category = props.get("category").and_then(|x| x.as_str()).unwrap_or("");
            let limit = props.get("limit").and_then(|x| x.as_i64()).unwrap_or(24) as i32;
            product_rows_for_grid(pool, site_iid, filter, category, limit).await?
        } else {
            vec![]
        };
        body.push_str(&block_html(&block.r#type, &props, &products));
    }
    Ok(format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{} — {}</title><style>
:root{{--accent:{accent};}}
body{{margin:0;font-family:system-ui,sans-serif;background:#fafafa;color:#111}}
.wrap{{max-width:960px;margin:0 auto;padding:24px 16px}}
.block{{margin:0 0 24px}}
.hero{{position:relative;border-radius:12px;overflow:hidden;background:linear-gradient(135deg,var(--accent),#111);color:#fff;padding:48px 24px}}
.hero-inner{{position:relative;z-index:1}}
.hero-bg img{{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.35}}
.product-grid .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px}}
.product-card{{background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08)}}
.product-card img{{width:100%;aspect-ratio:1;object-fit:cover;display:block}}
.product-card a{{display:block;padding:12px;text-decoration:none;color:inherit}}
.md{{line-height:1.6}}
</style></head><body><main class="wrap">{body}</main></body></html>"#,
        esc(&page.title),
        esc(site_name),
        body = body
    ))
}

pub async fn publish_doc_render(
    pool: &PgPool,
    site_iid: i64,
    doc_json: &Value,
    site_name: &str,
) -> Result<Vec<(String, String)>> {
    let doc = site_doc_from_json(doc_json);
    let mut out = Vec::new();
    for page in &doc.pages {
        let key = crate::doc::render_key_for_page(&page.path);
        let html = page_html_render(pool, site_iid, &doc, &page.path, site_name).await?;
        out.push((key, html));
    }
    if out.is_empty() {
        let html = page_html_render(pool, site_iid, &doc, "/", site_name).await?;
        out.push(("html:/".into(), html));
    }
    Ok(out)
}

pub fn render_etag(html: &str) -> String {
    blake3::hash(html.as_bytes()).to_hex().to_string()
}

pub fn render_offline_html(name: &str) -> String {
    format!(
        r#"<!DOCTYPE html><html><head><meta charset="utf-8"/><title>{}</title></head><body><main style="font-family:system-ui;text-align:center;padding:48px"><h1>{}</h1><p>This site is not published yet.</p></main></body></html>"#,
        esc(name),
        esc(name)
    )
}
