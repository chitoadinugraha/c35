use std::collections::BTreeMap;

use anyhow::Result;
use serde_json::{json, Map, Value};
use sqlx::{PgPool, Row};

use crate::guest_product::pic_url;

#[derive(Clone, Debug)]
struct Palette {
    background: &'static str,
    surface: &'static str,
    on_surface: &'static str,
    muted: &'static str,
    primary: &'static str,
    outline: &'static str,
    dark: bool,
}

#[derive(Clone, Debug)]
pub struct ProfileDesign {
    pub show_avatar: bool,
    pub avatar_size: f64,
    pub avatar_outline_width: f64,
    pub avatar_outline_color: String,
    pub show_title: bool,
    pub title_font_size: f64,
    pub title_font_family: String,
    pub title_align: String,
    pub show_bio: bool,
    pub bio_font_size: f64,
    pub bio_font_family: String,
    pub bio_align: String,
    pub show_location: bool,
    pub show_hours: bool,
    pub hub_default_tab: String,
    pub hub_posts_preview_limit: i64,
}

#[derive(Clone, Debug)]
pub struct StripDesign {
    pub show_label: bool,
    pub slide_from: String,
    pub header_align: String,
    pub header: String,
    pub header_font_size: f64,
    pub header_font_family: String,
    pub item_align: String,
    pub item_mode: String,
}

#[derive(Clone, Debug)]
pub struct BlockCard {
    pub id: String,
    pub params: BTreeMap<String, f64>,
}

#[derive(Clone, Debug)]
pub struct CardChrome {
    pub id: String,
    pub radius_css: String,
    pub bg: String,
    pub border: String,
}

#[derive(Clone, Debug)]
pub struct FeaturedContact {
    pub id: i64,
    pub name: String,
    pub pic: String,
    pub featured: String,
}

#[derive(Clone, Debug)]
pub struct GuestDesign {
    pub accent: String,
    pub dark: bool,
    pub base: String,
    pub page_bg: String,
    pub fg: String,
    pub muted: String,
    pub card_radius: f64,
    pub card_bg: String,
    pub card_border: String,
    pub backdrop_id: String,
    pub background_type: String,
    pub background_color: String,
    pub background_url: String,
    pub card_id: String,
    pub card_params: BTreeMap<String, f64>,
    pub surface: String,
    pub outline: String,
    pub profile: ProfileDesign,
    pub product: Value,
    pub product_from_theme: bool,
    pub partners: StripDesign,
    pub clients: StripDesign,
    pub block_cards: BTreeMap<String, BlockCard>,
}

impl GuestDesign {
    pub fn from_theme_json(raw: &str) -> Self {
        let trimmed = raw.trim();
        if trimmed.is_empty() {
            return Self::from_value(&Value::Object(Map::new()));
        }
        match serde_json::from_str::<Value>(trimmed) {
            Ok(v) if v.is_object() => Self::from_value(&v),
            _ => Self::from_value(&Value::Object(Map::new())),
        }
    }

    pub fn from_value(theme: &Value) -> Self {
        let dark = theme.get("dark").and_then(|v| v.as_bool()).unwrap_or(false);
        let base_raw = theme
            .get("base")
            .and_then(|v| v.as_str())
            .unwrap_or("monochrome")
            .trim();
        let base = normalize_base(base_raw);
        let palette = palette_resolve(&base, dark);
        let accent_raw = theme.get("accent").and_then(|v| v.as_str()).unwrap_or("").trim();
        let accent = if accent_raw.is_empty() {
            format!("#{}", palette.primary)
        } else {
            accent_raw.to_string()
        };

        let background = theme.get("background");
        let background_type = normalize_background_type(
            background
                .and_then(|b| b.get("type"))
                .and_then(|v| v.as_str())
                .unwrap_or("none"),
        );
        let background_color = background
            .and_then(|b| b.get("color"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .trim()
            .to_string();
        let background_url = background
            .and_then(|b| b.get("url"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .trim()
            .to_string();
        let theme_bg = format!("#{}", palette.background);
        let page_bg = if background_type == "color" && !background_color.is_empty() {
            background_color.clone()
        } else {
            theme_bg
        };

        let card = theme.get("card");
        let card_id = normalize_card_id(
            card.and_then(|c| c.get("id")).and_then(|v| v.as_str()).unwrap_or("solid"),
        );
        let card_params = num_map(card.and_then(|c| c.get("params")));
        let surface = format!("#{}", palette.surface);
        let outline = format!("#{}", palette.outline);
        let (card_bg, card_border) = card_fill(&card_id, &surface, &outline);
        let card_radius = card_params
            .get("radius")
            .copied()
            .unwrap_or_else(|| default_radius(&card_id));

        let backdrop_id = normalize_backdrop_id(
            theme
                .get("backdrop")
                .and_then(|b| b.get("id"))
                .and_then(|v| v.as_str())
                .unwrap_or("none"),
        );

        let product_from_theme = theme.get("product").and_then(|v| v.as_object()).is_some();
        let product = product_value(theme.get("product"));

        let mut block_cards = BTreeMap::new();
        if let Some(blocks) = theme.get("blocks").and_then(|v| v.as_array()) {
            for item in blocks {
                let id = item.get("block").and_then(|v| v.as_str()).unwrap_or("").trim();
                if id.is_empty() {
                    continue;
                }
                let style = item
                    .get("cardStyleId")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .trim()
                    .to_string();
                block_cards.insert(
                    id.to_string(),
                    BlockCard {
                        id: if style == "none" {
                            "none".into()
                        } else if style.is_empty() {
                            String::new()
                        } else {
                            normalize_card_id(&style)
                        },
                        params: num_map(item.get("params")),
                    },
                );
            }
        }

        Self {
            accent,
            dark: palette.dark,
            base,
            page_bg,
            fg: format!("#{}", palette.on_surface),
            muted: format!("#{}", palette.muted),
            card_radius,
            card_bg,
            card_border,
            backdrop_id,
            background_type,
            background_color,
            background_url,
            card_id,
            card_params,
            surface,
            outline,
            profile: profile_from(theme.get("profile")),
            product,
            product_from_theme,
            partners: strip_from(theme.get("partners"), "Featured Partners"),
            clients: strip_from(theme.get("clients"), "Featured Clients"),
            block_cards,
        }
    }

    pub fn card_radius_css(&self) -> String {
        format_px(self.card_radius)
    }

    pub fn card_chrome(&self, block: &str) -> Option<CardChrome> {
        let (id, params) = if let Some(over) = self.block_cards.get(block) {
            if over.id == "none" {
                return None;
            }
            if over.id.is_empty() {
                (self.card_id.as_str(), &self.card_params)
            } else {
                (over.id.as_str(), &over.params)
            }
        } else {
            (self.card_id.as_str(), &self.card_params)
        };
        let radius = params
            .get("radius")
            .copied()
            .unwrap_or_else(|| default_radius(id));
        let (bg, border) = card_fill(id, &self.surface, &self.outline);
        Some(CardChrome {
            id: id.to_string(),
            radius_css: format_px(radius),
            bg,
            border,
        })
    }

    pub fn card_wrap(&self, block: &str) -> (String, String) {
        match self.card_chrome(block) {
            None => (String::new(), String::new()),
            Some(chrome) => (
                format!(
                    r#"<div class="card" data-card="{id}" style="--card-radius:{radius};--card-bg:{bg};--card-border:{border}">"#,
                    id = chrome.id,
                    radius = chrome.radius_css,
                    bg = chrome.bg,
                    border = chrome.border,
                ),
                "</div>".into(),
            ),
        }
    }

    pub fn to_value(&self) -> Value {
        let mut cards = Map::new();
        let mut blocks = Vec::new();
        for (block, card) in &self.block_cards {
            let params = num_map_value(&card.params);
            cards.insert(block.clone(), json!({ "id": card.id, "params": params.clone() }));
            blocks.push(json!({
                "block": block,
                "cardStyleId": card.id,
                "params": params,
            }));
        }
        json!({
            "accent": self.accent,
            "dark": self.dark,
            "base": self.base,
            "page_bg": self.page_bg,
            "fg": self.fg,
            "muted": self.muted,
            "card_radius": self.card_radius,
            "card_bg": self.card_bg,
            "card_border": self.card_border,
            "backdrop_id": self.backdrop_id,
            "surface": self.surface,
            "outline": self.outline,
            "background": {
                "type": self.background_type,
                "color": self.background_color,
                "url": self.background_url,
            },
            "card": {
                "id": self.card_id,
                "params": num_map_value(&self.card_params),
            },
            "profile": {
                "showAvatar": self.profile.show_avatar,
                "avatarSize": self.profile.avatar_size,
                "avatarOutlineWidth": self.profile.avatar_outline_width,
                "avatarOutlineColor": self.profile.avatar_outline_color,
                "showTitle": self.profile.show_title,
                "titleFontSize": self.profile.title_font_size,
                "titleFontFamily": self.profile.title_font_family,
                "titleAlign": self.profile.title_align,
                "showBio": self.profile.show_bio,
                "bioFontSize": self.profile.bio_font_size,
                "bioFontFamily": self.profile.bio_font_family,
                "bioAlign": self.profile.bio_align,
                "showLocation": self.profile.show_location,
                "showHours": self.profile.show_hours,
                "hubDefaultTab": self.profile.hub_default_tab,
                "hubPostsPreviewLimit": self.profile.hub_posts_preview_limit,
            },
            "product": self.product,
            "partners": strip_value(&self.partners),
            "clients": strip_value(&self.clients),
            "backdrop": {
                "id": self.backdrop_id,
                "params": {},
                "color": "",
            },
            "blocks": blocks,
            "block_cards": cards,
        })
    }
}

impl FeaturedContact {
    pub fn to_value(&self) -> Value {
        json!({
            "id": self.id,
            "name": self.name,
            "pic": self.pic,
            "featured": self.featured,
        })
    }
}

pub async fn featured_contacts_load(pool: &PgPool, site_iid: i64) -> Result<Vec<FeaturedContact>> {
    let rows = sqlx::query(
        r#"
        SELECT contact_id, name, meta_json
        FROM site.contact
        WHERE site_iid = $1
          AND deleted_ts IS NULL
          AND is_archived = FALSE
          AND meta_json->>'featured' IN ('partners', 'clients')
        ORDER BY name
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    let mut out = Vec::new();
    for row in rows {
        let id: i64 = row.get("contact_id");
        let name: String = row.get("name");
        let meta: Value = row.get("meta_json");
        if let Some(contact) = featured_contact_from_meta(id, &name, &meta) {
            out.push(contact);
        }
    }
    Ok(out)
}

pub fn featured_contact_from_meta(id: i64, name: &str, meta: &Value) -> Option<FeaturedContact> {
    let featured = meta.get("featured").and_then(|v| v.as_str()).unwrap_or("").trim();
    if featured != "partners" && featured != "clients" {
        return None;
    }
    let pic_raw = meta
        .get("pic")
        .or_else(|| meta.get("avatar"))
        .and_then(|v| v.as_str())
        .unwrap_or("");
    Some(FeaturedContact {
        id,
        name: name.to_string(),
        pic: pic_url(pic_raw),
        featured: featured.to_string(),
    })
}

fn strip_value(strip: &StripDesign) -> Value {
    json!({
        "showLabel": strip.show_label,
        "slideFrom": strip.slide_from,
        "headerAlign": strip.header_align,
        "header": strip.header,
        "headerFontSize": strip.header_font_size,
        "headerFontFamily": strip.header_font_family,
        "itemAlign": strip.item_align,
        "itemMode": strip.item_mode,
    })
}

fn num_map_value(map: &BTreeMap<String, f64>) -> Value {
    let mut params = Map::new();
    for (k, v) in map {
        params.insert(k.clone(), json!(v));
    }
    Value::Object(params)
}

fn profile_from(raw: Option<&Value>) -> ProfileDesign {
    let m = raw.and_then(|v| v.as_object());
    ProfileDesign {
        show_avatar: bool_or(m, "showAvatar", true),
        avatar_size: f64_or(m, "avatarSize", 40.0),
        avatar_outline_width: f64_or(m, "avatarOutlineWidth", 0.0),
        avatar_outline_color: str_or(m, "avatarOutlineColor", ""),
        show_title: bool_or(m, "showTitle", true),
        title_font_size: f64_or(m, "titleFontSize", 22.0),
        title_font_family: str_or(m, "titleFontFamily", ""),
        title_align: str_or(m, "titleAlign", "center"),
        show_bio: bool_or(m, "showBio", true),
        bio_font_size: f64_or(m, "bioFontSize", 13.0),
        bio_font_family: str_or(m, "bioFontFamily", ""),
        bio_align: str_or(m, "bioAlign", "center"),
        show_location: bool_or(m, "showLocation", true),
        show_hours: bool_or(m, "showHours", true),
        hub_default_tab: str_or(m, "hubDefaultTab", "shop"),
        hub_posts_preview_limit: f64_or(m, "hubPostsPreviewLimit", 0.0) as i64,
    }
}

fn strip_from(raw: Option<&Value>, default_header: &str) -> StripDesign {
    let m = raw.and_then(|v| v.as_object());
    let header = str_or(m, "header", "");
    let header = if header.trim().is_empty() {
        default_header.to_string()
    } else {
        header
    };
    StripDesign {
        show_label: bool_or(m, "showLabel", true),
        slide_from: str_or(m, "slideFrom", "left"),
        header_align: str_or(m, "headerAlign", "left"),
        header,
        header_font_size: f64_or(m, "headerFontSize", 14.0),
        header_font_family: str_or(m, "headerFontFamily", ""),
        item_align: str_or(m, "itemAlign", "left"),
        item_mode: normalize_item_mode(&str_or(m, "itemMode", "icon")),
    }
}

fn product_value(raw: Option<&Value>) -> Value {
    let m = raw.and_then(|v| v.as_object());
    json!({
        "titleFontSize": f64_or(m, "titleFontSize", 14.0),
        "titleFontWeight": str_or(m, "titleFontWeight", "w600"),
        "titleFontFamily": str_or(m, "titleFontFamily", ""),
        "titleItalic": bool_or(m, "titleItalic", false),
        "titleUnderline": bool_or(m, "titleUnderline", false),
        "titleColor": str_or(m, "titleColor", ""),
        "subtitleFontSize": f64_or(m, "subtitleFontSize", 12.0),
        "subtitleFontWeight": str_or(m, "subtitleFontWeight", "w400"),
        "subtitleFontFamily": str_or(m, "subtitleFontFamily", ""),
        "subtitleItalic": bool_or(m, "subtitleItalic", false),
        "subtitleUnderline": bool_or(m, "subtitleUnderline", false),
        "subtitleColor": str_or(m, "subtitleColor", ""),
        "priceFontSize": f64_or(m, "priceFontSize", 14.0),
        "priceFontWeight": str_or(m, "priceFontWeight", "w600"),
        "priceFontFamily": str_or(m, "priceFontFamily", ""),
        "priceItalic": bool_or(m, "priceItalic", false),
        "priceUnderline": bool_or(m, "priceUnderline", false),
        "priceColor": str_or(m, "priceColor", ""),
    })
}

fn bool_or(m: Option<&Map<String, Value>>, key: &str, default: bool) -> bool {
    m.and_then(|o| o.get(key)).and_then(|v| v.as_bool()).unwrap_or(default)
}

fn str_or(m: Option<&Map<String, Value>>, key: &str, default: &str) -> String {
    m.and_then(|o| o.get(key))
        .and_then(|v| v.as_str())
        .unwrap_or(default)
        .to_string()
}

fn f64_or(m: Option<&Map<String, Value>>, key: &str, default: f64) -> f64 {
    m.and_then(|o| o.get(key)).and_then(json_f64).unwrap_or(default)
}

fn json_f64(v: &Value) -> Option<f64> {
    v.as_f64().or_else(|| v.as_i64().map(|n| n as f64)).or_else(|| v.as_u64().map(|n| n as f64))
}

fn num_map(raw: Option<&Value>) -> BTreeMap<String, f64> {
    let mut out = BTreeMap::new();
    let Some(obj) = raw.and_then(|v| v.as_object()) else {
        return out;
    };
    for (k, v) in obj {
        if let Some(n) = json_f64(v) {
            out.insert(k.clone(), n);
        }
    }
    out
}

fn format_px(n: f64) -> String {
    if (n - n.round()).abs() < 0.001 {
        format!("{}px", n.round() as i64)
    } else {
        format!("{n}px")
    }
}

fn normalize_base(raw: &str) -> String {
    match raw {
        "" => "monochrome".into(),
        "rose" | "rose-gold" | "rosegold" => "rosegold".into(),
        other => other.to_string(),
    }
}

fn normalize_background_type(raw: &str) -> String {
    match raw.trim() {
        "color" => "color".into(),
        "image" => "image".into(),
        _ => "none".into(),
    }
}

fn normalize_backdrop_id(raw: &str) -> String {
    match raw.trim() {
        "glow" | "mesh" | "grain" | "diamond" | "aurora" | "none" => raw.trim().to_string(),
        _ => "none".into(),
    }
}

fn normalize_card_id(raw: &str) -> String {
    match raw.trim() {
        "outlined" | "elevated" | "flat" | "glass" | "solid" => raw.trim().to_string(),
        _ => "solid".into(),
    }
}

fn normalize_item_mode(raw: &str) -> String {
    match raw.trim() {
        "card" | "tile" => "card".into(),
        "icon_label" => "icon_label".into(),
        _ => "icon".into(),
    }
}

fn default_radius(id: &str) -> f64 {
    match id {
        "outlined" => 10.0,
        "elevated" | "glass" => 12.0,
        _ => 8.0,
    }
}

fn card_fill(id: &str, surface: &str, outline: &str) -> (String, String) {
    match id {
        "outlined" | "flat" => ("transparent".into(), outline.to_string()),
        _ => (surface.to_string(), outline.to_string()),
    }
}

fn palette_resolve(base: &str, prefer_dark: bool) -> Palette {
    let rows = palettes();
    let dark = rows.iter().find(|p| p.0 == base && p.1.dark);
    let light = rows.iter().find(|p| p.0 == base && !p.1.dark);
    let solo = rows.iter().find(|p| p.0 == base);
    let picked = if prefer_dark {
        dark.or(light).or(solo)
    } else {
        light.or(dark).or(solo)
    };
    picked.map(|p| p.1.clone()).unwrap_or_else(|| palettes()[0].1.clone())
}

fn palettes() -> Vec<(&'static str, Palette)> {
    vec![
        ("monochrome", pal(false, "F8F9FA", "FFFFFF", "1A1A1A", "444746", "000000", "C4C7C5")),
        ("monochrome", pal(true, "0F1012", "17181C", "E2E2E6", "C7C6CB", "FFFFFF", "44474E")),
        ("violet", pal(false, "F5F3FF", "FFFFFF", "1E1B4B", "4F46E5", "6D28D9", "DDD6FE")),
        ("violet", pal(true, "0D0A1A", "15112E", "E0E0FF", "C084FC", "C084FC", "3C2C77")),
        ("sunset", pal(false, "FFF7ED", "FFFFFF", "431407", "EA580C", "EA580C", "FED7AA")),
        ("sunset", pal(true, "180F0A", "27170F", "FDE8E3", "FB923C", "FB923C", "563321")),
        ("forest", pal(false, "F0FDF4", "FFFFFF", "052E16", "16A34A", "15803D", "BBF7D0")),
        ("forest", pal(true, "071510", "0F2218", "E2F5EA", "4ADE80", "4ADE80", "1F4030")),
        ("cyberpunk", pal(true, "05060B", "0B0D19", "FFFFFF", "FF007F", "00F0FF", "00F0FF")),
        ("retro", pal(false, "ECE3CA", "F4ECCF", "2E282A", "A4CBB4", "EF9995", "D97706")),
        ("synthwave", pal(true, "1A103C", "241854", "FFFFFF", "58C7F3", "E779C1", "E779C1")),
        ("aqua", pal(true, "0B2545", "134074", "FFFFFF", "FFE066", "09BECD", "09BECD")),
        ("coffee", pal(true, "201615", "2D1E1C", "F2E8DF", "AB7A5F", "AB7A5F", "AB7A5F")),
        ("nord", pal(false, "ECEFF4", "FFFFFF", "2E3440", "434C5E", "88C0D0", "88C0D0")),
        ("nord", pal(true, "2E3440", "3B4252", "ECEFF4", "D8DEE9", "88C0D0", "88C0D0")),
        ("luxury", pal(true, "09090B", "18181B", "FFFFFF", "F59E0B", "FFFFFF", "F59E0B")),
        ("sakura", pal(false, "FFF1F2", "FFFFFF", "4C0519", "BE123C", "EC4899", "F43F5E")),
        ("sakura", pal(true, "0F0A0C", "1C1216", "FFE4E6", "F472B6", "F472B6", "EC4899")),
        ("dracula", pal(true, "1E1F29", "282A36", "F8F8F2", "8BE9FD", "FF79C6", "BD93F9")),
        ("mint", pal(false, "F4FBF7", "FFFFFF", "062E1B", "059669", "059669", "10B981")),
        ("mint", pal(true, "05100B", "0D2218", "E6F7ED", "34D399", "34D399", "10B981")),
        ("lavender", pal(false, "FAF5FF", "FFFFFF", "2E1065", "7C3AED", "7C3AED", "8B5CF6")),
        ("lavender", pal(true, "0F0A1A", "1A112E", "F3E8FF", "A78BFA", "C084FC", "8B5CF6")),
        ("rosegold", pal(false, "FFF5F5", "FFFFFF", "4A1525", "C2185B", "B78494", "EC407A")),
        ("rosegold", pal(true, "1A0F13", "29181E", "FFF5F5", "F48FB1", "E5A9B8", "B78494")),
    ]
}

fn pal(
    dark: bool,
    background: &'static str,
    surface: &'static str,
    on_surface: &'static str,
    muted: &'static str,
    primary: &'static str,
    outline: &'static str,
) -> Palette {
    Palette {
        background,
        surface,
        on_surface,
        muted,
        primary,
        outline,
        dark,
    }
}
