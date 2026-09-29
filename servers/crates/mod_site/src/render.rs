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

fn format_currency(amount: i64) -> String {
    let s = amount.to_string();
    let mut out = String::new();
    let len = s.len();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (len - i) % 3 == 0 {
            out.push('.');
        }
        out.push(c);
    }
    format!("Rp {}", out)
}

fn esc_js(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('\'', "\\'")
        .replace('"', "\\\"")
        .replace('\r', "")
        .replace('\n', " ")
}

async fn site_capabilities(pool: &PgPool, site_iid: i64) -> Value {
    sqlx::query_scalar::<_, Value>(
        "SELECT capabilities_json FROM site.config WHERE site_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .unwrap_or_else(|| Value::Object(Default::default()))
}

fn capability_enabled(caps: &Value, key: &str) -> bool {
    caps.get(key).and_then(|v| v.as_bool()).unwrap_or(true)
}

fn strip_script_tags(html: &str) -> String {
    let lower = html.to_ascii_lowercase();
    let mut out = String::with_capacity(html.len());
    let mut i = 0;
    while i < html.len() {
        if lower[i..].starts_with("<script") {
            if let Some(end) = lower[i..].find("</script>") {
                i += end + "</script>".len();
                continue;
            }
            break;
        }
        let ch = html[i..].chars().next().unwrap();
        out.push(ch);
        i += ch.len_utf8();
    }
    out
}

fn link_item_html(item: &Value) -> String {
    let label = item
        .get("label")
        .or_else(|| item.get("title"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let url = item
        .get("url")
        .or_else(|| item.get("href"))
        .and_then(|x| x.as_str())
        .unwrap_or("#");
    if label.is_empty() {
        return String::new();
    }
    format!(
        r#"<li><a href="{}" rel="noopener noreferrer">{}</a></li>"#,
        esc(url),
        esc(label)
    )
}

fn contact_field_html(field: &Value) -> String {
    let label = field
        .get("label")
        .or_else(|| field.get("name"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let name = field.get("name").and_then(|x| x.as_str()).unwrap_or(label);
    let field_type = field.get("type").and_then(|x| x.as_str()).unwrap_or("text");
    if label.is_empty() && name.is_empty() {
        return String::new();
    }
    format!(
        r#"<label><span>{}</span><input type="{}" name="{}" /></label>"#,
        esc(label),
        esc(field_type),
        esc(name)
    )
}

fn hours_row_html(row: &Value) -> String {
    let day = row
        .get("day")
        .or_else(|| row.get("label"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let open = row
        .get("open")
        .or_else(|| row.get("from"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let close = row
        .get("close")
        .or_else(|| row.get("to"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    if day.is_empty() {
        return String::new();
    }
    format!(
        r#"<tr><td>{}</td><td>{} – {}</td></tr>"#,
        esc(day),
        esc(open),
        esc(close)
    )
}

pub fn block_html_render(
    block_type: &str,
    props: &Value,
    products: &[ProductRow],
    caps: &Value,
) -> String {
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
                        r#"<article class="product-card" data-pid="{pid}">{img}<div class="product-info"><h3>{name}</h3><p>{desc}</p><div class="product-bottom"><span class="price">{price_str}</span><button type="button" class="guest-add-btn" onclick="c35GuestCart.add({pid}, '{name_esc}', {price}, '{pic_esc}')">+ Pesan</button></div></div></article>"#,
                        pid = p.product_id,
                        img = img,
                        name = esc(&p.name),
                        desc = esc(&p.desc),
                        price_str = esc(&format_currency(p.price)),
                        name_esc = esc_js(&p.name),
                        price = p.price,
                        pic_esc = esc_js(&pic_url(&p.pic)),
                    )
                })
                .collect::<Vec<_>>()
                .join("");
            format!(
                r#"<section class="block product-grid"><div class="grid">{}</div></section>"#,
                cards
            )
        }
        "gallery" => {
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let pics = props
                .get("pics")
                .and_then(|x| x.as_array())
                .cloned()
                .unwrap_or_default();
            let imgs = pics
                .iter()
                .filter_map(|p| p.as_str())
                .map(|pic| {
                    format!(
                        r#"<img src="{}" alt="" loading="lazy"/>"#,
                        esc(&pic_url(pic))
                    )
                })
                .collect::<Vec<_>>()
                .join("");
            let heading = if title.is_empty() {
                String::new()
            } else {
                format!(r#"<h2>{}</h2>"#, esc(title))
            };
            format!(
                r#"<section class="block gallery">{heading}<div class="gallery">{}</div></section>"#,
                imgs
            )
        }
        "links" => {
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let items = props
                .get("links")
                .or_else(|| props.get("items"))
                .and_then(|x| x.as_array())
                .cloned()
                .unwrap_or_default();
            let lis = items
                .iter()
                .map(link_item_html)
                .collect::<Vec<_>>()
                .join("");
            let heading = if title.is_empty() {
                String::new()
            } else {
                format!(r#"<h2>{}</h2>"#, esc(title))
            };
            format!(
                r#"<section class="block links">{heading}<ul class="links">{}</ul></section>"#,
                lis
            )
        }
        "contact_form" => {
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let submit = props
                .get("submit_label")
                .and_then(|x| x.as_str())
                .unwrap_or("Kirim Pesan");
            let fields = props
                .get("fields")
                .and_then(|x| x.as_array())
                .cloned()
                .unwrap_or_default();
            let inputs = if fields.is_empty() {
                r#"<label><span>Nama Lengkap</span><input type="text" name="name" required placeholder="Nama Anda" /></label>
<label><span>WhatsApp / No. HP</span><input type="text" name="contact" required placeholder="08... atau email@..." /></label>
<label><span>Pesan / Permintaan</span><input type="text" name="message" placeholder="Tuliskan pesan..." /></label>"#.to_string()
            } else {
                fields.iter().map(contact_field_html).collect::<Vec<_>>().join("")
            };
            let heading = if title.is_empty() {
                String::new()
            } else {
                format!(r#"<h2>{}</h2>"#, esc(title))
            };
            format!(
                r#"<section class="block contact-form">{heading}<form class="contact-form" action='#contact' method='post' onsubmit="event.preventDefault(); c35GuestLead.submit(this);">{inputs}<button type="submit">{}</button></form></section>"#,
                esc(submit)
            )
        }
        "map" => {
            if !capability_enabled(caps, "booking") {
                return String::new();
            }
            let lat = props.get("lat").and_then(|x| x.as_f64()).unwrap_or(0.0);
            let lng = props.get("lng").and_then(|x| x.as_f64()).unwrap_or(0.0);
            let address = props.get("address").and_then(|x| x.as_str()).unwrap_or("");
            let zoom = props.get("zoom").and_then(|x| x.as_i64()).unwrap_or(14);
            let map_url = format!("https://www.openstreetmap.org/?mlat={lat}&mlon={lng}#map={zoom}/{lat}/{lng}");
            let label = if address.is_empty() {
                format!("{lat}, {lng}")
            } else {
                address.to_string()
            };
            format!(
                r#"<section class="block map"><div class="map"><a href="{}" rel="noopener noreferrer">{}</a></div></section>"#,
                esc(&map_url),
                esc(&label)
            )
        }
        "hours" => {
            if !capability_enabled(caps, "booking") {
                return String::new();
            }
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let schedule = props
                .get("hours")
                .or_else(|| props.get("schedule"))
                .and_then(|x| x.as_array())
                .cloned()
                .unwrap_or_default();
            let rows = schedule
                .iter()
                .map(hours_row_html)
                .collect::<Vec<_>>()
                .join("");
            let heading = if title.is_empty() {
                String::new()
            } else {
                format!(r#"<h2>{}</h2>"#, esc(title))
            };
            format!(
                r#"<section class="block hours">{heading}<table class="hours"><tbody>{}</tbody></table></section>"#,
                rows
            )
        }
        "queue" => {
            if !capability_enabled(caps, "queue") {
                return String::new();
            }
            let title = props
                .get("title")
                .or_else(|| props.get("label"))
                .and_then(|x| x.as_str())
                .unwrap_or("Queue");
            let mode = props.get("mode").and_then(|x| x.as_str()).unwrap_or("");
            let mode_html = if mode.is_empty() {
                String::new()
            } else {
                format!(r#"<p class="queue-mode">{}</p>"#, esc(mode))
            };
            format!(
                r#"<section class="block queue"><div class="queue"><h3>{}</h3>{}</div></section>"#,
                esc(title),
                mode_html
            )
        }
        "embed" => {
            let url = props.get("url").and_then(|x| x.as_str()).unwrap_or("");
            if url.is_empty() {
                return String::new();
            }
            let height = props.get("height").and_then(|x| x.as_i64()).unwrap_or(400);
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let title_attr = if title.is_empty() {
                String::new()
            } else {
                format!(r#" title="{}""#, esc(title))
            };
            format!(
                r#"<section class="block embed"><iframe sandbox="" src="{}"{title_attr} style="height:{height}px;width:100%;border:0" loading="lazy"></iframe></section>"#,
                esc(url),
                title_attr = title_attr,
                height = height
            )
        }
        "custom_html" => {
            let raw = props.get("html").and_then(|x| x.as_str()).unwrap_or("");
            let safe = strip_script_tags(raw);
            format!(r#"<section class="block custom-html"><div class="custom-html">{}</div></section>"#, safe)
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
    let caps = site_capabilities(pool, site_iid).await;
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
        body.push_str(&block_html_render(&block.r#type, &props, &products, &caps));
    }
    Ok(format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{} — {}</title><style>
:root{{--accent:{accent};}}
body{{margin:0;font-family:system-ui,sans-serif;background:#fafafa;color:#111;padding-bottom:80px}}
.wrap{{max-width:960px;margin:0 auto;padding:24px 16px}}
.block{{margin:0 0 24px}}
.hero{{position:relative;border-radius:12px;overflow:hidden;background:linear-gradient(135deg,var(--accent),#111);color:#fff;padding:48px 24px}}
.hero-inner{{position:relative;z-index:1}}
.hero-bg img{{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.35}}
.product-grid .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px}}
.product-card{{background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08);display:flex;flex-direction:column}}
.product-card img{{width:100%;aspect-ratio:1;object-fit:cover;display:block}}
.product-card .product-info{{padding:12px;display:flex;flex-direction:column;flex:1}}
.product-card h3{{margin:0 0 6px;font-size:15px;font-weight:600}}
.product-card p{{margin:0 0 10px;font-size:13px;color:#666;line-height:1.4;flex:1}}
.product-bottom{{display:flex;align-items:center;justify-content:space-between;gap:8px}}
.product-bottom .price{{font-weight:700;color:var(--accent);font-size:14px}}
.guest-add-btn{{background:var(--accent);color:#fff;border:0;border-radius:6px;padding:6px 12px;font-size:12px;font-weight:600;cursor:pointer}}
.guest-add-btn:hover{{opacity:.88}}
.gallery{{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px}}
.gallery img{{width:100%;aspect-ratio:1;object-fit:cover;border-radius:8px}}
.links{{list-style:none;padding:0;margin:0}}
.links li{{margin:8px 0}}
.contact-form label{{display:block;margin:0 0 12px}}
.contact-form input, .contact-form textarea{{width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box;font-family:inherit}}
.contact-form button[type="submit"]{{background:var(--accent);color:#fff;border:0;padding:10px 18px;border-radius:6px;font-weight:600;cursor:pointer}}
.hours{{width:100%;border-collapse:collapse}}
.hours td{{padding:6px 8px;border-bottom:1px solid #eee}}
.map a{{color:var(--accent)}}
.queue{{padding:16px;background:#fff;border-radius:8px}}
.embed iframe{{display:block;border-radius:8px}}
.md{{line-height:1.6}}
.guest-cart-bar{{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:#18181b;color:#fff;padding:10px 18px;border-radius:999px;display:flex;align-items:center;gap:16px;box-shadow:0 8px 30px rgba(0,0,0,.25);z-index:100;cursor:pointer}}
.guest-cart-count{{background:var(--accent);color:#fff;width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}}
.guest-cart-total{{font-weight:700;font-size:14px}}
.guest-cart-btn{{background:var(--accent);color:#fff;border:0;padding:6px 14px;border-radius:999px;font-size:13px;font-weight:600;cursor:pointer}}
.guest-modal-backdrop{{position:fixed;inset:0;background:rgba(0,0,0,.6);backdrop-filter:blur(2px);z-index:200;display:flex;align-items:flex-end;justify-content:center}}
@media (min-width:640px){{.guest-modal-backdrop{{align-items:center}}}}
.guest-modal-sheet{{background:#fff;color:#111;width:100%;max-width:480px;max-height:90vh;border-radius:16px 16px 0 0;overflow-y:auto;padding:20px;box-shadow:0 20px 40px rgba(0,0,0,.3);display:flex;flex-direction:column;gap:16px}}
@media (min-width:640px){{.guest-modal-sheet{{border-radius:16px}}}}
.guest-sheet-head{{display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #eee;padding-bottom:12px}}
.guest-sheet-head h3{{margin:0;font-size:17px}}
.guest-close-btn{{background:transparent;border:0;font-size:20px;cursor:pointer;color:#888}}
.guest-cart-list{{display:flex;flex-direction:column;gap:10px;max-height:240px;overflow-y:auto}}
.guest-cart-item{{display:flex;align-items:center;justify-content:space-between;gap:10px;padding-bottom:8px;border-bottom:1px dashed #eee}}
.guest-item-title{{font-weight:600;font-size:13px}}
.guest-item-price{{font-size:12px;color:#666}}
.guest-qty-stepper{{display:flex;align-items:center;gap:8px}}
.guest-qty-btn{{width:28px;height:28px;border-radius:6px;border:1px solid #ddd;background:#fafafa;font-size:14px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center}}
.guest-field label{{display:block;margin-bottom:4px;font-size:12px;font-weight:600;color:#444}}
.guest-field input, .guest-field select, .guest-field textarea{{width:100%;padding:9px 12px;border:1px solid #ddd;border-radius:8px;box-sizing:border-box;font-family:inherit;font-size:13px}}
.guest-submit-btn{{background:var(--accent);color:#fff;border:0;padding:12px;border-radius:10px;font-size:15px;font-weight:700;cursor:pointer;width:100%}}
.guest-submit-btn:hover{{opacity:.9}}
.guest-toast{{position:fixed;top:20px;left:50%;transform:translateX(-50%);background:#18181b;color:#fff;padding:10px 18px;border-radius:8px;font-size:13px;z-index:300;box-shadow:0 4px 16px rgba(0,0,0,.2)}}
</style></head><body><main class="wrap">{body}</main>
<div id="c35-guest-cart-bar" class="guest-cart-bar" style="display:none;" onclick="c35GuestCart.openModal()">
  <div class="guest-cart-count" id="c35-cart-count">0</div>
  <div class="guest-cart-total" id="c35-cart-total">Rp 0</div>
  <button type="button" class="guest-cart-btn">Lihat Pesanan</button>
</div>
<div id="c35-guest-modal" class="guest-modal-backdrop" style="display:none;" onclick="if(event.target===this)c35GuestCart.closeModal()">
  <div class="guest-modal-sheet" id="c35-modal-content"></div>
</div>
<div id="c35-guest-toast" class="guest-toast" style="display:none;"></div>
{client_js}</body></html>"#,
        esc(&page.title),
        esc(site_name),
        body = body,
        client_js = guest_client_js(site_iid)
    ))
}

fn guest_client_js(site_iid: i64) -> String {
    format!(r#"<script>
(function() {{
  const SITE_IID = {site_iid};
  const STORAGE_KEY = 'c35_cart_' + SITE_IID;

  function formatIdr(amount) {{
    const s = Math.round(amount || 0).toString();
    let out = '';
    for (let i = 0; i < s.length; i++) {{
      if (i > 0 && (s.length - i) % 3 === 0) out += '.';
      out += s[i];
    }}
    return 'Rp ' + out;
  }}

  function showToast(msg) {{
    const el = document.getElementById('c35-guest-toast');
    if (!el) return;
    el.textContent = msg;
    el.style.display = 'block';
    setTimeout(() => {{ el.style.display = 'none'; }}, 3000);
  }}

  window.c35GuestCart = {{
    items: [],
    init() {{
      try {{
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) this.items = JSON.parse(raw) || [];
      }} catch (e) {{ this.items = []; }}
      this.render();
    }},
    save() {{
      try {{ localStorage.setItem(STORAGE_KEY, JSON.stringify(this.items)); }} catch (e) {{}}
      this.render();
    }},
    add(pid, name, price, pic) {{
      const found = this.items.find(i => i.pid === pid);
      if (found) {{
        found.qty += 1;
      }} else {{
        this.items.push({{ pid, name, price, pic, qty: 1, note: '' }});
      }}
      this.save();
      showToast('"' + name + '" ditambahkan ke keranjang');
    }},
    updateQty(pid, delta) {{
      const idx = this.items.findIndex(i => i.pid === pid);
      if (idx >= 0) {{
        this.items[idx].qty += delta;
        if (this.items[idx].qty <= 0) {{
          this.items.splice(idx, 1);
        }}
        this.save();
        this.renderModal();
      }}
    }},
    clear() {{
      this.items = [];
      this.save();
    }},
    count() {{
      return this.items.reduce((acc, i) => acc + (i.qty || 0), 0);
    }},
    total() {{
      return this.items.reduce((acc, i) => acc + ((i.price || 0) * (i.qty || 0)), 0);
    }},
    render() {{
      const bar = document.getElementById('c35-guest-cart-bar');
      const countEl = document.getElementById('c35-cart-count');
      const totalEl = document.getElementById('c35-cart-total');
      if (!bar) return;
      const count = this.count();
      if (count > 0) {{
        bar.style.display = 'flex';
        if (countEl) countEl.textContent = count;
        if (totalEl) totalEl.textContent = formatIdr(this.total());
      }} else {{
        bar.style.display = 'none';
      }}
    }},
    openModal() {{
      const modal = document.getElementById('c35-guest-modal');
      if (!modal) return;
      this.renderModal();
      modal.style.display = 'flex';
    }},
    closeModal() {{
      const modal = document.getElementById('c35-guest-modal');
      if (modal) modal.style.display = 'none';
    }},
    renderModal() {{
      const content = document.getElementById('c35-modal-content');
      if (!content) return;
      if (this.items.length === 0) {{
        content.innerHTML = '<div class="guest-sheet-head"><h3>Keranjang Pesanan</h3><button type="button" class="guest-close-btn" onclick="c35GuestCart.closeModal()">&times;</button></div><p style="text-align:center;color:#666;padding:24px 0;">Keranjang belanja Anda masih kosong.</p>';
        return;
      }}
      let listHtml = '';
      for (const item of this.items) {{
        listHtml += '<div class="guest-cart-item"><div><div class="guest-item-title">' + item.name + '</div><div class="guest-item-price">' + formatIdr(item.price) + ' &times; ' + item.qty + ' = <strong>' + formatIdr(item.price * item.qty) + '</strong></div></div><div class="guest-qty-stepper"><button type="button" class="guest-qty-btn" onclick="c35GuestCart.updateQty(' + item.pid + ', -1)">−</button><span>' + item.qty + '</span><button type="button" class="guest-qty-btn" onclick="c35GuestCart.updateQty(' + item.pid + ', 1)">+</button></div></div>';
      }}
      content.innerHTML = '<div class="guest-sheet-head"><h3>Checkout Pesanan</h3><button type="button" class="guest-close-btn" onclick="c35GuestCart.closeModal()">&times;</button></div><div class="guest-cart-list">' + listHtml + '</div><div style="display:flex;justify-content:space-between;font-weight:700;font-size:15px;padding-top:8px;border-top:1px solid #eee;"><span>Total</span><span style="color:var(--accent);">' + formatIdr(this.total()) + '</span></div><form onsubmit="event.preventDefault(); c35GuestCart.submitOrder(this);" style="display:flex;flex-direction:column;gap:12px;"><div class="guest-field"><label>Nama Pemesan *</label><input type="text" name="customer_name" required placeholder="Nama Anda" /></div><div class="guest-field"><label>No. WhatsApp / HP *</label><input type="tel" name="customer_phone" required placeholder="08..." /></div><div class="guest-field"><label>Meja / Kamar / Alamat (opsional)</label><input type="text" name="fulfillment_info" placeholder="Contoh: Meja 3 / Kamar 12 / Takeaway" /></div><div class="guest-field"><label>Metode Pembayaran</label><select name="payment_method"><option value="cash">Bayar di Tempat / Kasir (Cash)</option><option value="qris">QRIS</option><option value="transfer">Transfer Bank</option></select></div><div class="guest-field"><label>Catatan Pesanan</label><input type="text" name="note" placeholder="Contoh: Jangan terlalu manis, es dipisah" /></div><button type="submit" class="guest-submit-btn" id="c35-btn-submit-order">Kirim Pesanan (' + formatIdr(this.total()) + ')</button></form>';
    }},
    async submitOrder(form) {{
      const btn = document.getElementById('c35-btn-submit-order');
      if (btn) {{ btn.disabled = true; btn.textContent = 'Memproses Pesanan…'; }}
      const fd = new FormData(form);
      const name = fd.get('customer_name') || '';
      const phone = fd.get('customer_phone') || '';
      const fulfillment = fd.get('fulfillment_info') || '';
      const payMethod = fd.get('payment_method') || 'cash';
      const note = fd.get('note') || '';

      const totalAmount = this.total();
      const payload = {{
        site_iid: SITE_IID,
        customer_name: name,
        customer_phone: phone,
        note: (note ? note + ' ' : '') + (fulfillment ? '[' + fulfillment + ']' : ''),
        tx: {{
          site_iid: SITE_IID,
          type: 'sale',
          state: 'pending',
          total: totalAmount,
          customer_name: name,
          customer_phone: phone,
          note: note,
          items: this.items.map(i => ({{
            product_id: i.pid,
            name: i.name,
            price: i.price,
            qty: i.qty,
            subtotal: i.price * i.qty,
            note: i.note || ''
          }})),
          payments: [{{
            method: payMethod,
            amount: totalAmount
          }}]
        }}
      }};

      const apiBase = (location.hostname === 'alienai.id' || location.hostname.endsWith('.alienai.id'))
        ? 'https://api.alienai.id'
        : '';
      const targetUrl = apiBase + '/v1/site/guest-order/put';

      try {{
        const resp = await fetch(targetUrl, {{
          method: 'POST',
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(payload)
        }});
        if (!resp.ok) {{
          const errText = await resp.text();
          throw new Error(errText || 'Gagal memproses pesanan');
        }}
        const resData = await resp.json();
        const txId = resData && resData.tx ? (resData.tx.tx_id || resData.tx.id) : '';
        this.clear();
        this.renderReceipt(txId, name, totalAmount, payMethod);
      }} catch (err) {{
        alert('Gagal mengirim pesanan: ' + err.message);
        if (btn) {{ btn.disabled = false; btn.textContent = 'Kirim Pesanan'; }}
      }}
    }},
    renderReceipt(txId, name, total, payMethod) {{
      const content = document.getElementById('c35-modal-content');
      if (!content) return;
      content.innerHTML = '<div class="guest-sheet-head"><h3>Pesanan Berhasil! 🎉</h3><button type="button" class="guest-close-btn" onclick="c35GuestCart.closeModal()">&times;</button></div><div style="text-align:center;padding:16px 0;"><div style="font-size:42px;margin-bottom:8px;">✅</div><h4 style="margin:0 0 6px;font-size:17px;">Terima kasih, ' + name + '!</h4><p style="color:#666;font-size:13px;margin:0 0 16px;">Pesanan Anda telah kami terima dan sedang diproses.</p><div style="background:#fafafa;border:1px solid #eee;border-radius:12px;padding:14px;text-align:left;font-size:13px;display:flex;flex-direction:column;gap:6px;">' + (txId ? '<div><strong>No. Pesanan:</strong> #' + txId + '</div>' : '') + '<div><strong>Total Pembayaran:</strong> ' + formatIdr(total) + '</div><div><strong>Metode:</strong> ' + payMethod.toUpperCase() + '</div><div><strong>Status:</strong> Menunggu Konfirmasi Toko</div></div></div><button type="button" class="guest-submit-btn" onclick="c35GuestCart.closeModal()">Tutup</button>';
    }}
  }};

  window.c35GuestLead = {{
    async submit(form) {{
      const btn = form.querySelector('button[type="submit"]');
      if (btn) {{ btn.disabled = true; btn.textContent = 'Mengirim…'; }}
      const fd = new FormData(form);
      const name = fd.get('name') || '';
      const contact = fd.get('contact') || '';
      const message = fd.get('message') || '';

      const payload = {{
        site_iid: SITE_IID,
        name: name,
        contact_val: contact,
        message: message
      }};

      const apiBase = (location.hostname === 'alienai.id' || location.hostname.endsWith('.alienai.id'))
        ? 'https://api.alienai.id'
        : '';
      const targetUrl = apiBase + '/v1/site/guest-contact/put';

      try {{
        const resp = await fetch(targetUrl, {{
          method: 'POST',
          headers: {{ 'Content-Type': 'application/json' }},
          body: JSON.stringify(payload)
        }});
        if (!resp.ok) {{
          const errText = await resp.text();
          throw new Error(errText || 'Gagal mengirim pesan');
        }}
        form.reset();
        showToast('Terima kasih! Pesan Anda telah kami terima.');
        if (btn) {{ btn.disabled = false; btn.textContent = 'Terkirim ✓'; }}
      }} catch (err) {{
        alert('Gagal mengirim pesan: ' + err.message);
        if (btn) {{ btn.disabled = false; btn.textContent = 'Kirim Pesan'; }}
      }}
    }}
  }};

  document.addEventListener('DOMContentLoaded', () => {{
    c35GuestCart.init();
  }});
  if (document.readyState === 'interactive' || document.readyState === 'complete') {{
    c35GuestCart.init();
  }}
}})();
</script>"#, site_iid = site_iid)
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
