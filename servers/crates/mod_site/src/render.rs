use anyhow::{anyhow, Result};
use c35_proto::{SiteDoc, SiteLink, SitePost};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::commerce_boot::{commerce_boot_build, order_progress_steps_json, site_published_meta_json};
use crate::doc::site_doc_from_json;
use crate::product_design::{
    product_card_price_style, product_card_subtitle_style, product_card_title_style,
    product_design_from_site_meta,
};
use crate::guest_design::{featured_contacts_load, FeaturedContact, GuestDesign, ProfileDesign};
use crate::link_platform_icon::link_platform_icon_html;
use crate::guest_product::{
    guest_product_get, guest_product_list, guest_product_sell_ids, product_grid_page_size,
};
use crate::guest_product_display::{
    guest_product_can_add_to_cart, guest_product_price_label, pic_url, pic_url_display,
    product_grid_display,
};
use crate::product_icon_svg::product_icon_svg;
use crate::site_link::site_link_boot_rows;
use crate::site_post::{site_post_boot_summaries, site_post_get_storefront};

pub use crate::guest_product::{product_row_json, ProductRow};

pub struct ProductGridCtx {
    pub site_iid: i64,
    pub block_id: String,
    pub next_cursor: String,
}

fn product_placeholder_html(icon: &str) -> String {
    let svg = product_icon_svg(icon);
    let svg = if svg.is_empty() {
        product_icon_svg("mdi:shopping")
    } else {
        svg
    };
    format!(r#"<div class="product-ph" aria-hidden="true">{svg}</div>"#)
}

pub fn product_card_html(p: &ProductRow, product_design: Option<&Value>) -> String {
    let img = if p.pic.is_empty() {
        product_placeholder_html(&p.icon)
    } else {
        format!(
            r#"<img class="guest-pic-thumb" src="{}" alt="" loading="lazy" data-pic-display="{}" role="button" tabindex="0"/>"#,
            esc(&pic_url(&p.pic)),
            esc_attr(&pic_url_display(&p.pic)),
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
    let reserve_attr = product_reserve_attrs(p);
    let action = product_purchase_button(p);
    let stock = product_stock_line(p);
    format!(
        r#"<article class="product-card guest-product-tile" data-pid="{pid}"{reserve_attr}><div class="guest-product-thumb-wrap">{img}<span class="guest-tile-cart-badge" hidden aria-hidden="true"></span></div><div class="product-info"><h3{title_attr}>{name}</h3><p{subtitle_attr}>{desc}</p>{stock}<div class="product-bottom"><span class="price"{price_attr}>{price_str}</span>{action}</div></div></article>"#,
        pid = p.product_id,
        reserve_attr = reserve_attr,
        img = img,
        title_attr = title_attr,
        name = esc(&p.name),
        subtitle_attr = subtitle_attr,
        desc = esc(&p.desc),
        stock = stock,
        price_attr = price_attr,
        price_str = esc(&guest_product_price_label(p.price)),
        action = action,
    )
}

pub fn product_list_row_html(p: &ProductRow, product_design: Option<&Value>) -> String {
    let img = if p.pic.is_empty() {
        product_placeholder_html(&p.icon)
    } else {
        format!(
            r#"<img class="guest-pic-thumb" src="{}" alt="" loading="lazy" data-pic-display="{}" role="button" tabindex="0"/>"#,
            esc(&pic_url(&p.pic)),
            esc_attr(&pic_url_display(&p.pic)),
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
    let reserve_attr = product_reserve_attrs(p);
    let action = product_purchase_button(p);
    let stock = product_stock_line(p);
    let price_str = guest_product_price_label(p.price);
    let price_html = if price_str.is_empty() {
        String::new()
    } else {
        format!(r#"<span class="price"{price_attr}>{price}</span>"#, price_attr = price_attr, price = esc(&price_str))
    };
    format!(
        r#"<article class="product-list-row guest-product-tile" data-pid="{pid}"{reserve_attr}><div class="product-list-thumb">{img}<span class="guest-tile-cart-badge" hidden aria-hidden="true"></span></div><div class="product-list-body"><h3{title_attr}>{name}</h3><p{subtitle_attr}>{desc}</p>{stock}</div><div class="product-list-trail">{price_html}{action}</div></article>"#,
        pid = p.product_id,
        reserve_attr = reserve_attr,
        img = img,
        title_attr = title_attr,
        name = esc(&p.name),
        subtitle_attr = subtitle_attr,
        desc = esc(&p.desc),
        stock = stock,
        price_html = price_html,
        action = action,
    )
}

fn product_stock_line(p: &ProductRow) -> String {
    if !p.stock_show_to_customer {
        return String::new();
    }
    let Some(n) = p.stock_qty else {
        return String::new();
    };
    format!(r#"<p class="product-stock">Stock: {n}</p>"#)
}

fn product_reserve_attrs(p: &ProductRow) -> String {
    if !p.can_reserve {
        return String::new();
    }
    format!(
        r#" data-can-reserve="1" data-name="{}" data-price="{}" data-pic="{}" data-duration-value="{}" data-duration-unit="{}" data-unit-selection="{}""#,
        esc(&p.name),
        p.price,
        esc(&pic_url(&p.pic)),
        p.duration_value.max(1),
        esc(&p.duration_unit),
        esc(&p.reservation_unit_selection),
    )
}

fn product_purchase_button(p: &ProductRow) -> String {
    format!(
        r#"<button type="button" class="guest-product-info-btn" data-product-info="{}" aria-label="Detail">&#9432;</button>"#,
        p.product_id
    )
}

fn product_detail_actions(p: &ProductRow) -> String {
    if p.can_reserve {
        return format!(
            r#"<button type="button" class="guest-reserve-btn" data-reserve-product="{}">Reservasi</button>"#,
            p.product_id
        );
    }
    if !guest_product_can_add_to_cart(p.price) {
        return String::new();
    }
    format!(
        r#"<button type="button" class="guest-add-btn" onclick="c35GuestCart.add({}, '{}', {}, '{}')">+ Pesan</button>"#,
        p.product_id,
        esc_js(&p.name),
        p.price,
        esc_js(&pic_url(&p.pic)),
    )
}

/// Product detail article. Reservable products show Reservasi and omit + Pesan.
pub fn product_detail_article_html(p: &ProductRow) -> String {
    let img = if p.pic.is_empty() {
        product_placeholder_html(&p.icon)
    } else {
        format!(
            r#"<img class="guest-pic-thumb product-detail-pic" src="{}" alt="" loading="lazy" data-pic-display="{}" role="button" tabindex="0"/>"#,
            esc(&pic_url(&p.pic)),
            esc_attr(&pic_url_display(&p.pic)),
        )
    };
    format!(
        r#"<article class="product-detail block" data-guest="site_product" data-pid="{pid}"{reserve_attr}>{img}<h1>{name}</h1><p>{desc}</p>{stock}<p class="price">{price_str}</p>{action}</article>"#,
        pid = p.product_id,
        reserve_attr = product_reserve_attrs(p),
        img = img,
        name = esc(&p.name),
        desc = esc(&p.desc),
        price_str = esc(&guest_product_price_label(p.price)),
        stock = product_stock_line(p),
        action = product_detail_actions(p),
    )
}

fn featured_strip_html(
    guest: &str,
    kind: &str,
    strip: &crate::guest_design::StripDesign,
    design: &GuestDesign,
    featured: &[FeaturedContact],
) -> String {
    let block_id = if kind == "partners" {
        "partners_display"
    } else {
        "clients_display"
    };
    let (card_open, card_close) = design.card_wrap(block_id);
    let mode = strip.item_mode.as_str();
    let items = featured
        .iter()
        .filter(|c| c.featured == kind)
        .map(|c| strip_item_html(c, mode, strip.show_label))
        .collect::<Vec<_>>()
        .join("");
    let align = css_align(&strip.item_align, "left");
    let header_align = css_align(&strip.header_align, "left");
    format!(
        r#"<section class="block featured-strip" data-guest="{guest}" data-item-mode="{mode}" data-align="{align}" data-slide="{slide}">{card_open}<h2 class="strip-header" style="text-align:{header_align};font-size:{size}{family}">{header}</h2><ul class="strip-items" style="text-align:{align}">{items}</ul>{card_close}</section>"#,
        guest = guest,
        mode = mode,
        align = align,
        slide = esc(strip.slide_from.as_str()),
        card_open = card_open,
        header_align = header_align,
        size = css_px(strip.header_font_size),
        family = family_decl(&strip.header_font_family),
        header = esc(&strip.header),
        items = items,
        card_close = card_close,
    )
}

fn strip_item_html(contact: &FeaturedContact, mode: &str, show_label: bool) -> String {
    let img = if contact.pic.is_empty() {
        String::new()
    } else {
        format!(
            r#"<img src="{}" alt="" loading="lazy"/>"#,
            esc(&contact.pic)
        )
    };
    let show_name = show_label && mode != "icon";
    let label = if show_name {
        format!(r#"<span class="strip-label">{}</span>"#, esc(&contact.name))
    } else {
        String::new()
    };
    let mode_class = match mode {
        "card" => "strip-item strip-card card",
        "icon_label" => "strip-item strip-icon-label",
        _ => "strip-item strip-icon",
    };
    format!(
        r#"<li class="{mode_class}" data-id="{id}">{img}{label}</li>"#,
        mode_class = mode_class,
        id = contact.id,
        img = img,
        label = label,
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

fn link_icon_id(item: &Value) -> &str {
    item.get("icon")
        .and_then(|x| x.as_str())
        .filter(|s| !s.trim().is_empty())
        .unwrap_or("website")
}

fn link_row_html(
    label: &str,
    url: &str,
    icon_id: &str,
    design: &GuestDesign,
    link_id: Option<i64>,
) -> String {
    if label.is_empty() {
        return String::new();
    }
    let href = if url.trim().is_empty() { "#" } else { url };
    let icon = link_platform_icon_html(icon_id);
    let (card_open, card_close) = design.card_wrap("link");
    let link_id_attr = link_id
        .filter(|id| *id > 0)
        .map(|id| format!(r#" data-link-id="{id}""#))
        .unwrap_or_default();
    format!(
        r#"<li class="guest-link-row" data-guest="link"{link_id_attr}>{card_open}<a class="guest-link-list" href="{href}" rel="noopener noreferrer">{icon}<span class="guest-link-label">{label}</span></a>{card_close}</li>"#,
        link_id_attr = link_id_attr,
        card_open = card_open,
        href = esc(href),
        icon = icon,
        label = esc(label),
        card_close = card_close,
    )
}

fn link_item_html(item: &Value, design: &GuestDesign) -> String {
    let label = item
        .get("label")
        .or_else(|| item.get("title"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    let url = item
        .get("url")
        .or_else(|| item.get("href"))
        .and_then(|x| x.as_str())
        .unwrap_or("");
    link_row_html(label, url, link_icon_id(item), design, None)
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

fn link_hub_html(link: &SiteLink, design: &GuestDesign) -> String {
    let label = link.label.trim();
    let url = link.url.trim();
    if label.is_empty() && url.is_empty() {
        return String::new();
    }
    let display = if label.is_empty() { url } else { label };
    let icon = if link.icon.trim().is_empty() {
        "website"
    } else {
        link.icon.trim()
    };
    link_row_html(display, url, icon, design, Some(link.link_id))
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

fn hub_hours_compact_html(meta: &Value) -> String {
    use crate::guest_schedule::{hours_panel_rows, schedule_status, slots_from_meta};
    let slots = slots_from_meta(meta);
    if slots.is_empty() {
        return String::new();
    }
    let (open, label) = schedule_status(&slots);
    let status_class = if open { "is-open" } else { "is-closed" };
    let panel = hours_panel_rows(&slots)
        .iter()
        .map(|(day, open_t, close_t)| {
            format!(
                r#"<div class="guest-hub-hours-row"><strong>{day}</strong> {open_t} – {close_t}</div>"#,
                day = esc(day),
                open_t = esc(open_t),
                close_t = esc(close_t),
            )
        })
        .collect::<Vec<_>>()
        .join("");
    format!(
        r#"<div class="hub-hours-compact"><details class="guest-hub-hours-chip"><summary><span class="guest-hub-hours-icon" aria-hidden="true">&#9201;</span><span class="guest-hub-hours-status {status_class}">{label}</span></summary><div class="guest-hub-hours-panel">{panel}</div></details></div>"#,
        status_class = esc_attr(status_class),
        label = esc(&label),
        panel = panel,
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

pub fn guest_root_css(design: &GuestDesign) -> String {
    let p = &design.profile;
    let prod = &design.product;
    let product_title = prod
        .get("titleFontSize")
        .and_then(|v| v.as_f64())
        .unwrap_or(14.0);
    let product_subtitle = prod
        .get("subtitleFontSize")
        .and_then(|v| v.as_f64())
        .unwrap_or(12.0);
    let product_price = prod
        .get("priceFontSize")
        .and_then(|v| v.as_f64())
        .unwrap_or(13.0);
    format!(
        ":root{{--accent:{accent};--page-bg:{page_bg};--fg:{fg};--muted:{muted};--card-radius:{radius};--card-bg:{card_bg};--card-border:{card_border};--hub-title-size:{hub_title};--hub-bio-size:{hub_bio};--hub-avatar-size:{hub_avatar};--product-title-size:{product_title};--product-subtitle-size:{product_subtitle};--product-price-size:{product_price};}}",
        accent = design.accent,
        page_bg = design.page_bg,
        fg = design.fg,
        muted = design.muted,
        radius = design.card_radius_css(),
        card_bg = design.card_bg,
        card_border = design.card_border,
        hub_title = css_px(p.title_font_size),
        hub_bio = css_px(p.bio_font_size),
        hub_avatar = css_px(p.avatar_size),
        product_title = css_px(product_title),
        product_subtitle = css_px(product_subtitle),
        product_price = css_px(product_price),
    )
}

pub fn guest_shell_html(design: &GuestDesign, inner: &str) -> String {
    let image = page_bg_image_html(design);
    format!(
        r#"<style>{root}</style><body data-backdrop="{bd}" class="backdrop-{bd} guest-storefront" style="background-color:{page_bg};color:{fg}">{image}<main class="wrap guest-page-main">{inner}</main></body>"#,
        root = guest_root_css(design),
        bd = design.backdrop_id,
        page_bg = design.page_bg,
        fg = design.fg,
        image = image,
        inner = inner,
    )
}

fn page_bg_image_html(design: &GuestDesign) -> String {
    if design.background_type != "image" {
        return String::new();
    }
    let url = pic_url(&design.background_url);
    if url.is_empty() {
        return String::new();
    }
    format!(
        r#"<div class="page-bg-image" style="background-image:url('{}')"></div>"#,
        esc(&url)
    )
}

fn css_px(n: f64) -> String {
    if (n - n.round()).abs() < 0.001 {
        format!("{}px", n.round() as i64)
    } else {
        format!("{n}px")
    }
}

fn css_align(raw: &str, fallback: &str) -> String {
    match raw.trim() {
        "left" | "right" | "center" | "start" | "end" => raw.trim().to_string(),
        _ => fallback.to_string(),
    }
}

fn family_decl(family: &str) -> String {
    let f = family.trim();
    if f.is_empty() {
        String::new()
    } else {
        format!(";font-family:{f}")
    }
}

/// Standalone `hero` block (Flutter `GuestSiteHeroBlock` defaults — not theme `profile` flags).
fn flutter_hero_profile() -> ProfileDesign {
    ProfileDesign {
        show_avatar: true,
        avatar_size: 72.0,
        avatar_outline_width: 0.0,
        avatar_outline_color: String::new(),
        show_title: true,
        title_font_size: 18.0,
        title_font_family: String::new(),
        title_align: "center".into(),
        show_bio: true,
        bio_font_size: 12.0,
        bio_font_family: String::new(),
        bio_align: "center".into(),
        show_location: false,
        show_hours: false,
        hub_default_tab: String::new(),
        hub_posts_preview_limit: 0,
    }
}

fn profile_pic_url(props: &Value, site_meta: &Value) -> String {
    let pic_prop = props.get("pic").and_then(|x| x.as_str()).unwrap_or("").trim();
    let pic_fallback = site_meta
        .get("avatar_url")
        .and_then(|x| x.as_str())
        .unwrap_or("")
        .trim();
    if pic_prop.is_empty() {
        pic_fallback.to_string()
    } else {
        pic_prop.to_string()
    }
}

async fn site_identity_pic(pool: &PgPool, site_iid: i64) -> String {
    sqlx::query(
        r#"SELECT COALESCE(pic, '') AS pic FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .map(|r| r.get::<String, _>("pic"))
    .unwrap_or_default()
}

/// Favicon URL: explicit `meta.favicon`, then `meta.avatar_url`, hub `pic`, then identity `pic`.
pub fn guest_site_favicon_url(site_meta: &Value, doc: &SiteDoc, identity_pic: &str) -> String {
    for key in ["favicon", "avatar_url"] {
        if let Some(raw) = site_meta.get(key).and_then(|x| x.as_str()) {
            let t = raw.trim();
            if !t.is_empty() {
                return pic_url(t);
            }
        }
    }
    for page in &doc.pages {
        for block in &page.blocks {
            if block.r#type != "hub_profile" {
                continue;
            }
            let props: Value = if block.props_json.is_empty() {
                Value::Object(Default::default())
            } else {
                serde_json::from_str(&block.props_json)
                    .unwrap_or(Value::Object(Default::default()))
            };
            let pic = profile_pic_url(&props, site_meta);
            if !pic.is_empty() {
                return pic_url(&pic);
            }
        }
    }
    let id_pic = identity_pic.trim();
    if !id_pic.is_empty() {
        return pic_url(id_pic);
    }
    String::new()
}

pub fn guest_favicon_head_markup(favicon_url: &str) -> String {
    let url = favicon_url.trim();
    if url.is_empty() {
        return String::new();
    }
    let href = esc_attr(url);
    format!(
        r#"<link rel="icon" href="{href}" sizes="any"/><link rel="apple-touch-icon" href="{href}"/>"#,
        href = href
    )
}

fn guest_hub_hero_inner_html(
    props: &Value,
    profile: &ProfileDesign,
    design: &GuestDesign,
    site_meta: &Value,
) -> String {
    let title = props.get("title").and_then(|x| x.as_str()).unwrap_or("");
    let subtitle = props.get("subtitle").and_then(|x| x.as_str()).unwrap_or("");
    let pic_use = profile_pic_url(props, site_meta);
    let cta = props
        .get("cta_label")
        .or_else(|| props.get("cta"))
        .and_then(|x| x.as_str())
        .unwrap_or("Hubungi Kami");
    let avatar = if !profile.show_avatar || pic_use.is_empty() {
        String::new()
    } else {
        let mut style = format!(
            "width:{size};height:{size}",
            size = css_px(profile.avatar_size)
        );
        if profile.avatar_outline_width > 0.0 {
            let color = if profile.avatar_outline_color.trim().is_empty() {
                design.accent.as_str()
            } else {
                profile.avatar_outline_color.trim()
            };
            style.push_str(&format!(
                ";outline:{} solid {color}",
                css_px(profile.avatar_outline_width)
            ));
        }
        format!(
            r#"<img class="hub-avatar guest-hub-avatar" src="{}" alt="" style="{}" loading="lazy"/>"#,
            esc(&pic_url(&pic_use)),
            esc_attr(&style)
        )
    };
    let title_html = if profile.show_title {
        format!(
            r#"<h1 class="guest-hub-title" style="font-size:{size};text-align:{align}{family}">{title}</h1>"#,
            size = css_px(profile.title_font_size),
            align = css_align(&profile.title_align, "center"),
            family = family_decl(&profile.title_font_family),
            title = esc(title),
        )
    } else {
        String::new()
    };
    let bio_html = if profile.show_bio && !subtitle.trim().is_empty() {
        format!(
            r#"<p class="guest-hub-bio" style="font-size:{size};text-align:{align}{family}">{bio}</p>"#,
            size = css_px(profile.bio_font_size),
            align = css_align(&profile.bio_align, "center"),
            family = family_decl(&profile.bio_font_family),
            bio = esc(subtitle),
        )
    } else {
        String::new()
    };
    let cta_html = format!(
        r#"<div class="guest-hub-cta"><span>{}</span></div>"#,
        esc(cta)
    );
    format!(
        "{avatar}{title_html}{bio_html}{cta_html}",
        avatar = avatar,
        title_html = title_html,
        bio_html = bio_html,
        cta_html = cta_html,
    )
}

pub fn block_html_render(
    block_type: &str,
    props: &Value,
    products: &[ProductRow],
    _caps: &Value,
    grid_ctx: Option<&ProductGridCtx>,
    site_iid: i64,
    hub_links: &[SiteLink],
    hub_posts: &[SitePost],
    product_design: Option<&Value>,
    design: &GuestDesign,
    featured: &[FeaturedContact],
    site_meta: &Value,
) -> String {
    match block_type {
        "hero" => {
            let inner = guest_hub_hero_inner_html(props, &flutter_hero_profile(), design, site_meta);
            format!(
                r#"<section class="block hero" data-guest="hero"><div class="guest-hub-hero hub-profile">{inner}</div></section>"#,
                inner = inner,
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
            let typography = if design.product_from_theme {
                Some(&design.product)
            } else {
                product_design
            };
            let display = product_grid_display(props, site_meta);
            let items = if display == "list" {
                products
                    .iter()
                    .map(|p| product_list_row_html(p, typography))
                    .collect::<Vec<_>>()
                    .join("")
            } else {
                products
                    .iter()
                    .map(|p| product_card_html(p, typography))
                    .collect::<Vec<_>>()
                    .join("")
            };
            let layout_class = if display == "list" { "list" } else { "grid" };
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
            let (card_open, card_close) = design.card_wrap("site_product");
            let grid_title = props
                .get("title")
                .and_then(|x| x.as_str())
                .filter(|s| !s.trim().is_empty())
                .unwrap_or("Katalog & Layanan");
            let heading = format!(r#"<h2 class="product-grid-title">{}</h2>"#, esc(grid_title));
            format!(
                r#"<section class="block product-grid" data-guest="site_product" data-display="{display}" data-block-id="{bid}" data-site-iid="{sid}" data-filter="{filter}" data-category="{category}" data-next-cursor="{cursor}">{heading}{card_open}<div class="{layout_class}">{items}</div>{load_more}{card_close}</section>"#,
                display = esc(display),
                bid = esc(block_id),
                sid = site_iid,
                filter = esc(filter),
                category = esc(category),
                cursor = esc(next_cursor),
                layout_class = layout_class,
                card_open = card_open,
                items = items,
                load_more = load_more,
                card_close = card_close,
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
                    .map(|item| link_item_html(item, design))
                    .filter(|s| !s.is_empty())
                    .collect::<Vec<_>>()
                    .join("")
            } else {
                hub_links
                    .iter()
                    .map(|link| link_hub_html(link, design))
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
                format!(r#"<h2 class="links-block-title">{}</h2>"#, esc(title))
            };
            format!(
                r#"<section class="block links-block" data-guest="link">{heading}<ul class="guest-links-list">{lis}</ul></section>"#,
                heading = heading,
                lis = lis,
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
                r#"<section class="block contact-form" data-guest="form">{heading}<form class="contact-form" action='#contact' method='post' onsubmit="event.preventDefault(); c35GuestLead.submit(this);">{inputs}<button type="submit">{}</button></form></section>"#,
                esc(submit)
            )
        }
        "map" => {
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
                r#"<section class="block hours" data-guest="hours">{heading}<table class="hours"><tbody>{}</tbody></table></section>"#,
                rows
            )
        }
        "hub_profile" => {
            let location_label = props.get("location_label").and_then(|x| x.as_str()).unwrap_or("");
            let show_hours = props.get("show_hours").and_then(|x| x.as_bool()).unwrap_or(false);
            let profile = &design.profile;
            let inner = guest_hub_hero_inner_html(props, profile, design, site_meta);
            let location_html = if profile.show_location && !location_label.trim().is_empty() {
                format!(
                    r#"<div class="hub-location"><span class="hub-location-icon" aria-hidden="true">&#128205;</span><span class="hub-location-label">{}</span></div>"#,
                    esc(location_label.trim())
                )
            } else {
                String::new()
            };
            let hours_html = if profile.show_hours && show_hours {
                hub_hours_compact_html(site_meta)
            } else {
                String::new()
            };
            format!(
                r#"<section class="block hub-profile" data-guest="profile"><div class="guest-hub-hero hub-profile">{inner}</div>{location_html}{hours_html}</section>"#,
                inner = inner,
                location_html = location_html,
                hours_html = hours_html
            )
        }
        "partners_display" => featured_strip_html("partners", "partners", &design.partners, design, featured),
        "clients_display" => featured_strip_html("clients", "clients", &design.clients, design, featured),
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
                r#"<section class="block order-track" data-guest="order" data-site-iid="{site_iid}"><h3>{title}</h3>{hint_html}<label><span>No. pesanan</span><input type="text" name="tx_id" class="order-track-tx" inputmode="numeric" /></label><button type="button" class="guest-order-poll-btn" onclick="c35GuestOrder.poll(this)">Cek status</button><div class="order-track-status"></div></section>"#,
                site_iid = site_iid,
                title = esc(title),
                hint_html = hint_html
            )
        }
        "queue" => {
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
    let design = GuestDesign::from_theme_json(&doc.theme_json);
    let featured = featured_contacts_load(pool, site_iid).await?;
    let caps = site_capabilities(pool, site_iid).await;
    let hub_links = site_link_boot_rows(pool, site_iid).await?;
    let hub_posts = site_post_boot_summaries(pool, site_iid).await?;
    let site_meta: Value = if doc.meta_json.is_empty() {
        Value::Object(Default::default())
    } else {
        serde_json::from_str(&doc.meta_json).unwrap_or(Value::Object(Default::default()))
    };
    let product_design = product_design_from_site_meta(&site_meta);
    let doc_title = site_doc_html_title(site_name, &site_meta, &page.title);
    let hub_shows_hours = page.blocks.iter().any(|b| {
        if b.r#type != "hub_profile" {
            return false;
        }
        let props: Value = if b.props_json.is_empty() {
            Value::Object(Default::default())
        } else {
            serde_json::from_str(&b.props_json).unwrap_or(Value::Object(Default::default()))
        };
        props.get("show_hours").and_then(|x| x.as_bool()).unwrap_or(false)
    });
    let mut body = String::new();
    for block in &page.blocks {
        if block.r#type == "hours" && hub_shows_hours {
            continue;
        }
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
            &design,
            &featured,
            &site_meta,
        ));
    }
    let root = guest_root_css(&design);
    let image = page_bg_image_html(&design);
    let identity_pic = site_identity_pic(pool, site_iid).await;
    let favicon_tags = guest_favicon_head_markup(&guest_site_favicon_url(&site_meta, doc, &identity_pic));
    Ok(format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{}</title>{favicon}<style>
{root}
body{{margin:0;font-family:system-ui,sans-serif;background-color:var(--page-bg);color:var(--fg);padding-bottom:0}}
.wrap{{max-width:720px;margin:0 auto;padding:0 16px 88px;box-sizing:border-box}}
.block{{margin:0 0 24px}}
.hero{{position:relative;border-radius:12px;overflow:hidden;background:linear-gradient(135deg,var(--accent),#111);color:#fff;padding:48px 24px}}
.hero-inner{{position:relative;z-index:1}}
.hero-bg img{{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.35}}
.product-grid .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px}}
.product-grid .list{{display:flex;flex-direction:column;gap:8px}}
.product-list-row{{display:flex;gap:10px;align-items:flex-start;padding:12px;background:var(--card-bg,#fff);border-radius:12px;border:1px solid var(--card-border,#eee)}}
.product-list-thumb{{flex:0 0 56px;width:56px;height:56px;border-radius:8px;overflow:hidden}}
.product-list-thumb img,.product-list-thumb .product-ph{{width:56px;height:56px;object-fit:cover}}
.product-list-body{{flex:1;min-width:0}}
.product-list-body h3{{margin:0;font-size:14px;font-weight:600}}
.product-list-body p{{margin:4px 0 0;font-size:12px;color:var(--muted,#666);line-height:1.35}}
.product-list-trail{{display:flex;flex-direction:column;align-items:flex-end;gap:4px}}
.guest-pic-thumb{{cursor:zoom-in}}
.product-card{{background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08);display:flex;flex-direction:column}}
.product-card img{{width:100%;aspect-ratio:1;object-fit:cover;display:block}}
.product-card .product-ph{{width:100%;aspect-ratio:1;display:flex;align-items:center;justify-content:center;background:#f4f4f5}}
.product-card .product-ph svg{{width:28%;height:28%}}
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
.hub-chips{{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-top:12px}}
.hub-chip{{display:inline-flex;align-items:center;padding:6px 10px;border-radius:999px;background:#fff;border:1px solid #e5e5e5;font-size:12px;color:#333;text-decoration:none}}
.hub-chip-muted{{color:#666}}
.order-track label{{display:block;margin:12px 0}}
.order-track input{{width:100%;padding:8px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box}}
.product-detail .price{{font-size:14px;font-weight:700;margin:8px 0}}
.product-detail-pic{{width:100%;max-height:280px;object-fit:cover;border-radius:8px;margin-bottom:12px}}
.product-reserve-placeholder{{margin-top:16px;padding:12px;background:#fff;border-radius:8px;color:#666;font-size:14px}}
.embed iframe{{display:block;border-radius:8px}}
.md{{line-height:1.6}}
</style><link rel="stylesheet" href="/static/site-guest/site-guest.v1.css"/></head><body data-backdrop="{bd}" class="backdrop-{bd} guest-storefront">{image}<main class="wrap guest-page-main">{body}</main>
<div id="c35-guest-cart-bar" data-guest="cart" class="guest-cart" style="display:none;">
  <div class="guest-cart-meta">
    <div class="guest-cart-total" id="c35-cart-total">Rp 0</div>
    <div class="guest-cart-count" id="c35-cart-count">0 item</div>
  </div>
  <button type="button" class="guest-cart-btn" onclick="c35GuestCart.pesan()">Pesan</button>
</div>
<div id="c35-guest-modal" class="guest-modal-backdrop" style="display:none;" aria-hidden="true"></div>
<div id="c35-guest-toast" class="guest-toast" style="display:none;"></div>
<button type="button" id="c35-guest-orders-chip" class="guest-orders-chip" style="display:none;" onclick="c35GuestOrders.open()">Pesanan saya</button>
{client_js}</body></html>"#,
        esc(&doc_title),
        favicon = favicon_tags,
        root = root,
        bd = design.backdrop_id,
        image = image,
        body = body,
        client_js = guest_client_script_tags(pool, site_iid, &theme_effects(&doc.theme_json)).await
    ))
}

fn site_doc_html_title(site_name: &str, meta: &Value, page_title: &str) -> String {
    let tagline = meta
        .get("tagline")
        .or_else(|| meta.get("seo_desc"))
        .and_then(|x| x.as_str())
        .unwrap_or("")
        .trim();
    if !tagline.is_empty() {
        return format!("{} — {}", site_name.trim(), tagline);
    }
    let page = page_title.trim();
    if !page.is_empty() && page != site_name.trim() {
        return format!("{} — {}", site_name.trim(), page);
    }
    site_name.trim().to_string()
}

fn theme_effects(theme_json: &str) -> Value {
    let theme: Value = serde_json::from_str(theme_json).unwrap_or(Value::Null);
    theme.get("effects").cloned().unwrap_or_else(|| json!([]))
}

async fn guest_client_script_tags(pool: &PgPool, site_iid: i64, effects: &Value) -> String {
    let meta = site_published_meta_json(pool, site_iid).await;
    let commerce = commerce_boot_build(pool, site_iid, &meta)
        .await
        .unwrap_or_else(|_| serde_json::json!({}));
    let guest = serde_json::json!({
        "site_iid": site_iid,
        "site_id": site_iid,
        "api_base": "",
        "commerce_boot": commerce,
        "order_progress_steps": order_progress_steps_json(),
    });
    let raw = serde_json::to_string(&guest).unwrap_or_else(|_| "{}".into());
    guest_client_script_markup(&raw, effects)
}

/// Page script tags. `site-guest.v1.js` is always included.
/// `site-guest.effects.v1.js` and `window.__SITE_BOOT__.effects` are included only when
/// `effects` is an array with at least one object whose `presetId` or `preset_id` is a
/// non-empty string and whose `active` is not `false`.
pub fn guest_client_script_markup(guest_json: &str, effects: &Value) -> String {
    let guest_safe = guest_json.replace("</", "<\\/");
    let v1 = r#"<script defer src="/static/site-guest/site-guest.v1.js"></script>"#;
    if !effects_script_enabled(effects) {
        return format!(
            r#"<script>window.__SITE_GUEST__={guest_safe};window.__SITE_BOOT__={{}};</script>{v1}"#
        );
    }
    let effects_raw = serde_json::to_string(effects).unwrap_or_else(|_| "[]".into());
    let effects_safe = effects_raw.replace("</", "<\\/");
    format!(
        r#"<script>window.__SITE_GUEST__={guest_safe};window.__SITE_BOOT__={{"effects":{effects_safe}}};</script>{v1}<script defer src="/static/site-guest/site-guest.effects.v1.js"></script>"#
    )
}

fn effects_script_enabled(effects: &Value) -> bool {
    let Some(rows) = effects.as_array() else {
        return false;
    };
    rows.iter().any(effect_row_loads_script)
}

const RUNNABLE_OVERLAY_PRESETS: &[&str] = &[
    "falling-hearts",
    "rain-shower",
    "snow-fall",
    "floating-bubbles",
    "thunderstorm",
    "fireworks",
    "starry-night",
    "drifting-clouds",
    "matrix-rain",
    "sakura-petals",
    "moonlight",
    "autumn-leaves",
];

fn overlay_effect_preset_canonical(raw: &str) -> Option<&'static str> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }
    if RUNNABLE_OVERLAY_PRESETS.contains(&trimmed) {
        return RUNNABLE_OVERLAY_PRESETS
            .iter()
            .find(|p| **p == trimmed)
            .copied();
    }
    let dashed = trimmed.replace('_', "-");
    RUNNABLE_OVERLAY_PRESETS
        .iter()
        .find(|p| **p == dashed)
        .copied()
}

fn effect_row_loads_script(row: &Value) -> bool {
    let Some(obj) = row.as_object() else {
        return false;
    };
    if obj.get("active").and_then(|v| v.as_bool()) == Some(false) {
        return false;
    }
    let preset = obj
        .get("presetId")
        .or_else(|| obj.get("preset_id"))
        .and_then(|v| v.as_str())
        .unwrap_or("");
    overlay_effect_preset_canonical(preset).is_some()
}


const GUEST_STOREFRONT_EXTRA_CSS: &str = r#"
body.guest-storefront{{position:relative;padding-bottom:0}}
.guest-page-main{{position:relative;z-index:1;max-width:720px;margin:0 auto;padding:0 16px 88px;box-sizing:border-box}}
.product-detail h1{{margin:12px 0 6px;font-size:16px;font-weight:700}}
.product-detail p{{margin:0 0 8px;font-size:13px;line-height:1.4;color:var(--muted,#666)}}
.social-post h1{{margin:12px 0 8px;font-size:16px;font-weight:700}}
.social-post .post-caption{{color:var(--muted,#666);font-size:13px}}
.social-post .post-body{{font-size:13px;line-height:1.45}}
.social-post .post-thumb{{width:100%;max-height:280px;object-fit:cover;border-radius:8px;margin-bottom:12px}}
.guest-post-carousel{{margin-bottom:12px}}
"#;

fn post_media_paths(post: &SitePost) -> Vec<String> {
    let media = if post.media_json.is_empty() {
        json!([])
    } else {
        serde_json::from_str(&post.media_json).unwrap_or(json!([]))
    };
    let mut paths = Vec::new();
    if let Some(arr) = media.as_array() {
        for item in arr {
            if let Some(src) = item.get("src").and_then(|v| v.as_str()) {
                let t = src.trim();
                if !t.is_empty() {
                    paths.push(t.to_string());
                }
            }
        }
    }
    if paths.is_empty() && !post.thumb.trim().is_empty() {
        paths.push(post.thumb.trim().to_string());
    }
    paths
}

fn post_detail_media_html(paths: &[String]) -> String {
    if paths.is_empty() {
        return String::new();
    }
    if paths.len() == 1 {
        let pic = &paths[0];
        return format!(
            r#"<img class="guest-pic-thumb post-thumb" src="{}" alt="" loading="lazy" data-pic-display="{}" role="button" tabindex="0"/>"#,
            esc(&pic_url(pic)),
            esc_attr(&pic_url_display(pic)),
        );
    }
    let slides = paths
        .iter()
        .enumerate()
        .map(|(i, pic)| {
            format!(
                r#"<div class="guest-post-carousel-slide" data-index="{i}" style="display:{disp}"><img class="guest-pic-thumb" src="{thumb}" alt="" loading="lazy" data-pic-display="{display}" role="button" tabindex="0"/></div>"#,
                i = i,
                disp = if i == 0 { "block" } else { "none" },
                thumb = esc(&pic_url(pic)),
                display = esc_attr(&pic_url_display(pic)),
            )
        })
        .collect::<Vec<_>>()
        .join("");
    let dots = paths
        .iter()
        .enumerate()
        .map(|(i, _)| {
            format!(
                r#"<button type="button" class="guest-post-carousel-dot{active}" aria-label="Slide {n}" data-index="{i}"></button>"#,
                active = if i == 0 { " is-active" } else { "" },
                n = i + 1,
                i = i,
            )
        })
        .collect::<Vec<_>>()
        .join("");
    format!(
        r#"<div class="guest-post-carousel" data-guest="post_carousel">{slides}<div class="guest-post-carousel-dots">{dots}</div></div>"#,
        slides = slides,
        dots = dots,
    )
}

/// Post detail article (carousel when multiple `media_json` images).
pub fn post_detail_article_html(post: &SitePost) -> String {
    let paths = post_media_paths(post);
    let media = post_detail_media_html(&paths);
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
    format!(
        r#"<article class="social-post" data-guest="social_post" data-post-id="{pid}">{media}<h1>{title}</h1>{caption}{body}</article>"#,
        pid = post.post_id,
        media = media,
        title = esc(&post.title),
        caption = caption,
        body = body_text,
    )
}

async fn published_site_doc(pool: &PgPool, site_iid: i64) -> SiteDoc {
    if let Ok(Some(row)) = sqlx::query(
        r#"
        SELECT doc_json FROM site.publish
        WHERE site_iid = $1 AND is_active = TRUE AND deleted_ts IS NULL
        ORDER BY published_ts DESC
        LIMIT 1
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    {
        let v: Value = row.get("doc_json");
        return site_doc_from_json(&v);
    }
    if let Ok(Some(row)) = sqlx::query(
        r#"SELECT doc_json FROM site.draft WHERE site_iid = $1 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    {
        let v: Value = row.get("doc_json");
        return site_doc_from_json(&v);
    }
    site_doc_from_json(&json!({ "pages": [], "theme": {}, "meta": {} }))
}

async fn guest_storefront_page_html(
    pool: &PgPool,
    site_iid: i64,
    _site_name: &str,
    doc: &SiteDoc,
    document_title: &str,
    body: &str,
) -> Result<String> {
    let design = GuestDesign::from_theme_json(&doc.theme_json);
    let root = guest_root_css(&design);
    let image = page_bg_image_html(&design);
    let effects = theme_effects(&doc.theme_json);
    let client_js = guest_client_script_tags(pool, site_iid, &effects).await;
    let site_meta: Value = if doc.meta_json.is_empty() {
        Value::Object(Default::default())
    } else {
        serde_json::from_str(&doc.meta_json).unwrap_or(Value::Object(Default::default()))
    };
    let identity_pic = site_identity_pic(pool, site_iid).await;
    let favicon_tags = guest_favicon_head_markup(&guest_site_favicon_url(&site_meta, doc, &identity_pic));
    Ok(format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{}</title>{favicon}<style>
{root}
{extra}
body{{margin:0;font-family:system-ui,sans-serif;background-color:var(--page-bg);color:var(--fg);padding-bottom:0}}
.wrap{{max-width:720px;margin:0 auto;padding:0 16px 88px;box-sizing:border-box}}
</style><link rel="stylesheet" href="/static/site-guest/site-guest.v1.css"/></head><body data-backdrop="{bd}" class="backdrop-{bd} guest-storefront">{image}<main class="wrap guest-page-main">{body}</main>
<div id="c35-guest-cart-bar" data-guest="cart" class="guest-cart" style="display:none;">
  <div class="guest-cart-meta">
    <div class="guest-cart-total" id="c35-cart-total">Rp 0</div>
    <div class="guest-cart-count" id="c35-cart-count">0 item</div>
  </div>
  <button type="button" class="guest-cart-btn" onclick="c35GuestCart.pesan()">Pesan</button>
</div>
<div id="c35-guest-modal" class="guest-modal-backdrop" style="display:none;" aria-hidden="true"></div>
<div id="c35-guest-toast" class="guest-toast" style="display:none;"></div>
<button type="button" id="c35-guest-orders-chip" class="guest-orders-chip" style="display:none;" onclick="c35GuestOrders.open()">Pesanan saya</button>
{client_js}</body></html>"#,
        esc(document_title),
        favicon = favicon_tags,
        root = root,
        extra = GUEST_STOREFRONT_EXTRA_CSS,
        bd = design.backdrop_id,
        image = image,
        body = body,
        client_js = client_js,
    ))
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
    let mut row = detail.row;
    row.can_reserve = detail.can_reserve;
    let body = product_detail_article_html(&row);
    let doc = published_site_doc(pool, site_iid).await;
    let title = format!("{} — {}", row.name.trim(), site_name.trim());
    let html = guest_storefront_page_html(pool, site_iid, site_name, &doc, &title, &body).await?;
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
    let article = post_detail_article_html(&post);
    let doc = published_site_doc(pool, site_iid).await;
    let title = format!("{} — {}", post.title.trim(), site_name.trim());
    let html = guest_storefront_page_html(pool, site_iid, site_name, &doc, &title, &article).await?;
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

/// Black alien head from `assets/icons/alien_receipt.svg` (transparent background).
const ALIEN_RECEIPT_ICON_SVG: &str = r#"<svg class="powered-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" fill-rule="evenodd" d="M12 3c4.97 0 9 3.58 9 8s-6 10-9 10s-9-5.58-9-10s4.03-8 9-8m-1.69 7.93C9.29 9.29 7.47 8.58 6.25 9.34s-1.38 2.71-.36 4.35c1.03 1.64 2.85 2.35 4.07 1.59c1.22-.78 1.37-2.71.35-4.35m3.38 0c-1.02 1.64-.87 3.57.35 4.35c1.22.76 3.04.05 4.07-1.59c1.02-1.64.86-3.59-.36-4.35s-3.04-.05-4.06 1.59M12 17.75c-2 0-2.5-.75-2.5-.75c0 .03.5 2 2.5 2s2.5-2 2.5-2s-.5.75-2.5.75"/></svg>"#;

/// Shared HTML footer: Powered by [icon] alienai.id (tappable label on screen HTML).
pub fn html_powered_by_alienai_footer() -> String {
    format!(
        r#"<p class="powered-by"><span class="powered-muted">Powered by</span>{icon}<a class="powered-brand" href="https://alienai.id" rel="noopener noreferrer">alienai.id</a></p>"#,
        icon = ALIEN_RECEIPT_ICON_SVG,
    )
}

pub fn render_offline_html(name: &str) -> String {
    let powered = html_powered_by_alienai_footer();
    format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{title} — alienai.id</title><style>
:root{{--accent:#F97316;--muted:#71717a;--card:#fff;--border:#e4e4e7}}
*{{box-sizing:border-box}}
body{{margin:0;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:32px 20px;font-family:system-ui,-apple-system,sans-serif;color:#18181b;background:linear-gradient(165deg,#fff7ed 0%,#fafafa 45%,#f4f4f5 100%}}
.card{{width:100%;max-width:420px;background:var(--card);border:1px solid var(--border);border-radius:16px;padding:32px 28px;text-align:center;box-shadow:0 4px 24px rgba(24,24,27,.06)}}
.site-title{{margin:0 0 12px;font-size:1.75rem;font-weight:700;color:var(--accent);letter-spacing:-.02em}}
.badge{{display:inline-block;margin:0 0 16px;padding:4px 10px;border-radius:999px;font-size:12px;font-weight:600;color:#9a3412;background:#ffedd5;border:1px solid #fed7aa}}
.lead{{margin:0;font-size:15px;line-height:1.5;color:var(--muted)}}
.powered-by{{display:flex;align-items:center;justify-content:center;gap:5px;margin:28px 0 0;font-size:13px}}
.powered-muted{{color:#a1a1aa;font-weight:300}}
.powered-icon{{width:14px;height:14px;color:#525252;flex-shrink:0}}
.powered-brand{{color:#525252;font-weight:700;text-decoration:none}}
.powered-brand:hover{{text-decoration:underline}}
@media print{{.powered-brand{{text-decoration:none;color:inherit}}}}
</style></head><body>
<main class="card"><h1 class="site-title">{title}</h1><p class="badge">Draft</p><p class="lead">This site is not published yet. Check back soon or ask the owner to publish from Alien AI.</p></main>
{powered}
</body></html>"#,
        title = esc(name),
        powered = powered,
    )
}
