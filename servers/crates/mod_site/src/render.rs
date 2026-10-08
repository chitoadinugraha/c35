use anyhow::{anyhow, Result};
use c35_proto::{SiteDoc, SiteLink, SitePost};
use serde_json::Value;
use sqlx::PgPool;

use crate::doc::site_doc_from_json;
use crate::product_design::{
    product_card_price_style, product_card_subtitle_style, product_card_title_style,
    product_design_from_site_meta,
};
use crate::guest_product::{
    guest_product_get, guest_product_list, guest_product_sell_ids, pic_url, product_grid_page_size,
};
use crate::site_link::site_link_boot_rows;
use crate::site_post::{site_post_boot_summaries, site_post_get_storefront};

pub use crate::guest_product::{product_row_json, ProductRow};

pub struct ProductGridCtx {
    pub site_iid: i64,
    pub block_id: String,
    pub next_cursor: String,
}

pub fn product_card_html(p: &ProductRow, product_design: Option<&Value>) -> String {
    let img = if p.pic.is_empty() {
        String::new()
    } else {
        format!(
            r#"<img src="{}" alt="" loading="lazy"/>"#,
            esc(&pic_url(&p.pic))
        )
    };
    let title_style = product_card_title_style(product_design);
    let subtitle_style = product_card_subtitle_style(product_design);
    let price_style = product_card_price_style(product_design);
    let title_attr = if title_style.is_empty() {
        String::new()
    } else {
        format!(r#" style="{}""#, esc_attr(&title_style))
    };
    let subtitle_attr = if subtitle_style.is_empty() {
        String::new()
    } else {
        format!(r#" style="{}""#, esc_attr(&subtitle_style))
    };
    let price_attr = if price_style.is_empty() {
        String::new()
    } else {
        format!(r#" style="{}""#, esc_attr(&price_style))
    };
    format!(
        r#"<article class="product-card" data-pid="{pid}">{img}<div class="product-info"><h3{title_attr}>{name}</h3><p{subtitle_attr}>{desc}</p><div class="product-bottom"><span class="price"{price_attr}>{price_str}</span><button type="button" class="guest-add-btn" onclick="c35GuestCart.add({pid}, '{name_esc}', {price}, '{pic_esc}')">+ Pesan</button></div></div></article>"#,
        pid = p.product_id,
        img = img,
        title_attr = title_attr,
        name = esc(&p.name),
        subtitle_attr = subtitle_attr,
        desc = esc(&p.desc),
        price_attr = price_attr,
        price_str = esc(&format_currency(p.price)),
        name_esc = esc_js(&p.name),
        price = p.price,
        pic_esc = esc_js(&pic_url(&p.pic)),
    )
}

fn esc_attr(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('"', "&quot;")
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
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
        r#"<li data-guest="link"><a href="{}" rel="noopener noreferrer">{}</a></li>"#,
        esc(url),
        esc(label)
    )
}

fn post_feed_card_html(post: &SitePost) -> String {
    let title = post.title.trim();
    if title.is_empty() {
        return String::new();
    }
    let caption = post.caption.trim();
    let thumb = if post.thumb.is_empty() {
        String::new()
    } else {
        format!(
            r#"<img class="social-feed-thumb" src="{}" alt="" loading="lazy"/>"#,
            esc(&pic_url(&post.thumb))
        )
    };
    let caption_html = if caption.is_empty() {
        String::new()
    } else {
        format!(r#"<p class="social-feed-caption">{}</p>"#, esc(caption))
    };
    format!(
        r#"<li class="social-feed-item" data-guest="social_post" data-post-id="{pid}"><a href="posts/{pid}">{thumb}<div class="social-feed-text"><h3>{title}</h3>{caption_html}</div></a></li>"#,
        pid = post.post_id,
        thumb = thumb,
        title = esc(title),
        caption_html = caption_html
    )
}

fn link_hub_html(link: &SiteLink) -> String {
    let label = link.label.trim();
    let url = link.url.trim();
    if label.is_empty() && url.is_empty() {
        return String::new();
    }
    let display = if label.is_empty() { url } else { label };
    format!(
        r#"<li data-guest="link" data-link-id="{}"><a href="{}" rel="noopener noreferrer">{}</a></li>"#,
        link.link_id,
        esc(if url.is_empty() { "#" } else { url }),
        esc(display)
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
    grid_ctx: Option<&ProductGridCtx>,
    site_iid: i64,
    hub_links: &[SiteLink],
    hub_posts: &[SitePost],
    product_design: Option<&Value>,
) -> String {
    match block_type {
        "hero" => {
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let subtitle = props.get("subtitle").and_then(|x| x.as_str()).unwrap_or("");
            let pic = props.get("pic").and_then(|x| x.as_str()).unwrap_or("");
            let cta = props
                .get("cta")
                .or_else(|| props.get("cta_label"))
                .and_then(|x| x.as_str())
                .unwrap_or("");
            let cta_url = props
                .get("cta_url")
                .or_else(|| props.get("cta_href"))
                .and_then(|x| x.as_str())
                .unwrap_or("#");
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
            let filter = props.get("filter").and_then(|x| x.as_str()).unwrap_or("all");
            let category = props.get("category").and_then(|x| x.as_str()).unwrap_or("");
            let cards = products
                .iter()
                .map(|p| product_card_html(p, product_design))
                .collect::<Vec<_>>()
                .join("");
            let (site_iid, block_id, next_cursor) = grid_ctx
                .map(|g| (g.site_iid, g.block_id.as_str(), g.next_cursor.as_str()))
                .unwrap_or((0, "", ""));
            let load_more = if next_cursor.is_empty() {
                String::new()
            } else {
                format!(
                    r#"<button type="button" class="guest-load-more-btn" onclick="c35GuestCatalog.loadMore(this)">Muat lebih banyak</button>"#
                )
            };
            format!(
                r#"<section class="block product-grid" data-block-id="{bid}" data-site-iid="{sid}" data-filter="{filter}" data-category="{category}" data-next-cursor="{cursor}"><div class="grid">{cards}</div>{load_more}</section>"#,
                bid = esc(block_id),
                sid = site_iid,
                filter = esc(filter),
                category = esc(category),
                cursor = esc(next_cursor),
                cards = cards,
                load_more = load_more,
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
            let lis = if !items.is_empty() {
                items
                    .iter()
                    .map(link_item_html)
                    .filter(|s| !s.is_empty())
                    .collect::<Vec<_>>()
                    .join("")
            } else {
                hub_links
                    .iter()
                    .map(link_hub_html)
                    .filter(|s| !s.is_empty())
                    .collect::<Vec<_>>()
                    .join("")
            };
            if lis.is_empty() {
                return String::new();
            }
            let heading = if title.is_empty() {
                String::new()
            } else {
                format!(r#"<h2>{}</h2>"#, esc(title))
            };
            format!(
                r#"<section class="block links" data-guest="link">{heading}<ul class="links">{}</ul></section>"#,
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
        "hub_profile" => {
            let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
            let subtitle = props.get("subtitle").and_then(|x| x.as_str()).unwrap_or("");
            let pic = props.get("pic").and_then(|x| x.as_str()).unwrap_or("");
            let avatar = if pic.is_empty() {
                String::new()
            } else {
                format!(
                    r#"<img class="hub-avatar" src="{}" alt="" loading="lazy"/>"#,
                    esc(&pic_url(pic))
                )
            };
            format!(
                r#"<section class="block hub-profile"><div class="hub-profile">{avatar}<h1>{}</h1><p>{}</p></div></section>"#,
                esc(title),
                esc(subtitle)
            )
        }
        "social_feed" => {
            let title = props
                .get("title")
                .and_then(|x| x.as_str())
                .unwrap_or("Update");
            let limit = props
                .get("limit")
                .and_then(|x| x.as_i64())
                .unwrap_or(20)
                .clamp(1, 20) as usize;
            let items = hub_posts
                .iter()
                .take(limit)
                .map(post_feed_card_html)
                .filter(|s| !s.is_empty())
                .collect::<Vec<_>>()
                .join("");
            if items.is_empty() {
                return String::new();
            }
            format!(
                r#"<section class="block social-feed" data-guest="social_feed"><h2>{title}</h2><ul class="social-feed-list">{items}</ul></section>"#,
                title = esc(title),
                items = items
            )
        }
        "order_track" => {
            let title = props
                .get("title")
                .and_then(|x| x.as_str())
                .unwrap_or("Lacak pesanan");
            let hint = props.get("hint").and_then(|x| x.as_str()).unwrap_or("");
            let hint_html = if hint.is_empty() {
                String::new()
            } else {
                format!(r#"<p class="order-track-hint">{}</p>"#, esc(hint))
            };
            format!(
                r#"<section class="block order-track" data-site-iid="{site_iid}"><h3>{title}</h3>{hint_html}<label><span>No. pesanan</span><input type="text" name="tx_id" class="order-track-tx" inputmode="numeric" /></label><button type="button" class="guest-order-poll-btn" onclick="c35GuestOrder.poll(this)">Cek status</button><div class="order-track-status"></div></section>"#,
                site_iid = site_iid,
                title = esc(title),
                hint_html = hint_html
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
                .unwrap_or("Antrian");
            let mode = props.get("mode").and_then(|x| x.as_str()).unwrap_or("");
            let queue_id = props.get("queue_id").and_then(|x| x.as_i64()).unwrap_or(0);
            let mode_html = if mode.is_empty() {
                String::new()
            } else {
                format!(r#"<p class="queue-mode">{}</p>"#, esc(mode))
            };
            format!(
                r#"<section class="block queue" data-site-iid="{site_iid}" data-queue-id="{queue_id}"><div class="queue"><h3>{title}</h3>{mode_html}<p class="queue-status" id="c35-queue-status"></p><button type="button" class="guest-queue-btn" onclick="c35GuestQueue.take(this)">Ambil nomor</button></div></section>"#,
                site_iid = site_iid,
                queue_id = queue_id,
                title = esc(title),
                mode_html = mode_html
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
    let hub_links = site_link_boot_rows(pool, site_iid).await?;
    let hub_posts = site_post_boot_summaries(pool, site_iid).await?;
    let site_meta: Value = if doc.meta_json.is_empty() {
        Value::Object(Default::default())
    } else {
        serde_json::from_str(&doc.meta_json).unwrap_or(Value::Object(Default::default()))
    };
    let product_design = product_design_from_site_meta(&site_meta);
    let mut body = String::new();
    for block in &page.blocks {
        let props: Value = if block.props_json.is_empty() {
            Value::Object(Default::default())
        } else {
            serde_json::from_str(&block.props_json).unwrap_or(Value::Object(Default::default()))
        };
        let (products, grid_ctx) = if block.r#type == "product_grid" {
            let filter = props.get("filter").and_then(|x| x.as_str()).unwrap_or("all");
            let category = props.get("category").and_then(|x| x.as_str()).unwrap_or("");
            let page_size = product_grid_page_size(&props);
            let listed =
                guest_product_list(pool, site_iid, filter, category, "", page_size).await?;
            let ctx = ProductGridCtx {
                site_iid,
                block_id: block.id.clone(),
                next_cursor: listed.next_cursor,
            };
            (listed.items, Some(ctx))
        } else {
            (vec![], None)
        };
        body.push_str(&block_html_render(
            &block.r#type,
            &props,
            &products,
            &caps,
            grid_ctx.as_ref(),
            site_iid,
            &hub_links,
            &hub_posts,
            product_design.as_ref(),
        ));
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
.guest-load-more-btn{{display:block;margin:16px auto 0;background:var(--card-bg);color:var(--text);border:1px solid var(--card-border);border-radius:8px;padding:10px 20px;font-size:14px;font-weight:600;cursor:pointer}}
.guest-load-more-btn:hover{{border-color:var(--accent);color:var(--accent)}}
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
.guest-queue-btn,.guest-order-poll-btn{{background:var(--accent);color:#fff;border:0;border-radius:6px;padding:8px 14px;font-weight:600;cursor:pointer;margin-top:8px}}
.hub-profile{{text-align:center;padding:24px 16px}}
.hub-avatar{{width:96px;height:96px;border-radius:50%;object-fit:cover;margin:0 auto 12px;display:block}}
.order-track label{{display:block;margin:12px 0}}
.order-track input{{width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box}}
.product-detail .price{{font-size:20px;font-weight:700;color:var(--accent);margin:12px 0}}
.product-reserve-placeholder{{margin-top:16px;padding:12px;background:#fff;border-radius:8px;color:#666;font-size:14px}}
.embed iframe{{display:block;border-radius:8px}}
.md{{line-height:1.6}}
</style><link rel="stylesheet" href="/static/site-guest/site-guest.v1.css"/></head><body><main class="wrap">{body}</main>
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
        client_js = guest_client_assets(site_iid)
    ))
}

fn guest_client_assets(site_iid: i64) -> String {
    format!(
        r#"<script>window.__SITE_GUEST__={{site_iid:{site_iid},api_base:""}};</script><script defer src="/static/site-guest/site-guest.v1.js"></script>"#,
        site_iid = site_iid
    )
}


pub async fn product_detail_html_render(
    pool: &PgPool,
    site_iid: i64,
    product_id: i64,
    site_name: &str,
) -> Result<Option<String>> {
    let detail = match guest_product_get(pool, site_iid, product_id).await? {
        Some(d) => d,
        None => return Ok(None),
    };
    let p = &detail.row;
    let img = if p.pic.is_empty() {
        String::new()
    } else {
        format!(
            r#"<img src="{}" alt="" loading="lazy" class="product-detail-pic"/>"#,
            esc(&pic_url(&p.pic))
        )
    };
    let reserve = if detail.can_reserve {
        r#"<div class="product-reserve-placeholder" data-reserve="1">Reservasi — pilih tanggal di aplikasi (segera).</div>"#
    } else {
        ""
    };
    let body = format!(
        r#"<article class="product-detail" data-pid="{pid}">{img}<h1>{name}</h1><p>{desc}</p><p class="price">{price_str}</p>{reserve}<button type="button" class="guest-add-btn" onclick="c35GuestCart.add({pid}, '{name_esc}', {price_num}, '{pic_esc}')">+ Pesan</button></article>"#,
        pid = p.product_id,
        img = img,
        name = esc(&p.name),
        desc = esc(&p.desc),
        price_str = esc(&format_currency(p.price)),
        reserve = reserve,
        name_esc = esc_js(&p.name),
        price_num = p.price,
        pic_esc = esc_js(&pic_url(&p.pic)),
    );
    let html = format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{} — {}</title><link rel="stylesheet" href="/static/site-guest/site-guest.v1.css"/><style>:root{{--accent:#2563eb}}body{{margin:0;font-family:system-ui,sans-serif;background:#fafafa}}.wrap{{max-width:720px;margin:0 auto;padding:24px 16px}}</style></head><body><main class="wrap">{body}</main>{client_js}</body></html>"#,
        esc(&p.name),
        esc(site_name),
        body = body,
        client_js = guest_client_assets(site_iid)
    );
    Ok(Some(html))
}

pub async fn post_detail_html_render(
    pool: &PgPool,
    site_iid: i64,
    post_id: i64,
    site_name: &str,
) -> Result<Option<String>> {
    let post = site_post_get_storefront(pool, site_iid, post_id).await?;
    let post = match post {
        Some(p) => p,
        None => return Ok(None),
    };
    let thumb = if post.thumb.is_empty() {
        String::new()
    } else {
        format!(
            r#"<img src="{}" alt="" loading="lazy" class="post-thumb"/>"#,
            esc(&pic_url(&post.thumb))
        )
    };
    let body_text = if post.body.is_empty() {
        String::new()
    } else {
        format!(
            r#"<div class="post-body">{}</div>"#,
            esc(&post.body).replace('\n', "<br/>")
        )
    };
    let caption = if post.caption.is_empty() {
        String::new()
    } else {
        format!(r#"<p class="post-caption">{}</p>"#, esc(&post.caption))
    };
    let article = format!(
        r#"<article class="social-post" data-guest="social_post" data-post-id="{pid}">{thumb}<h1>{title}</h1>{caption}{body}</article>"#,
        pid = post.post_id,
        thumb = thumb,
        title = esc(&post.title),
        caption = caption,
        body = body_text
    );
    let html = format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{} — {}</title><link rel="stylesheet" href="/static/site-guest/site-guest.v1.css"/><style>:root{{--accent:#2563eb}}body{{margin:0;font-family:system-ui,sans-serif;background:#fafafa}}.wrap{{max-width:720px;margin:0 auto;padding:24px 16px}}</style></head><body><main class="wrap">{body}</main>{client_js}</body></html>"#,
        esc(&post.title),
        esc(site_name),
        body = article,
        client_js = guest_client_assets(site_iid)
    );
    Ok(Some(html))
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
    let product_ids = guest_product_sell_ids(pool, site_iid, 200).await?;
    for product_id in product_ids {
        if let Some(html) = product_detail_html_render(pool, site_iid, product_id, site_name).await? {
            out.push((format!("html:/products/{}", product_id), html));
        }
    }
    let post_ids = crate::site_post::site_post_storefront_ids(pool, site_iid).await?;
    for post_id in post_ids {
        if let Some(html) = post_detail_html_render(pool, site_iid, post_id, site_name).await? {
            out.push((format!("html:/posts/{}", post_id), html));
        }
    }
    Ok(out)
}

pub fn render_etag(html: &str) -> String {
    blake3::hash(html.as_bytes()).to_hex().to_string()
}

pub fn render_offline_html(name: &str) -> String {
    format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{title} — AlienAI</title><style>:root{{--accent:#F97316}}body{{margin:0;font-family:system-ui,sans-serif;background:#fafafa;color:#111}}main{{max-width:480px;margin:0 auto;text-align:center;padding:48px 24px}}h1{{color:var(--accent)}}</style></head><body><main><h1>{title}</h1><p>This site is not published yet.</p><p style="color:#666;font-size:13px">Powered by AlienAI</p></main></body></html>"#,
        title = esc(name)
    )
}
