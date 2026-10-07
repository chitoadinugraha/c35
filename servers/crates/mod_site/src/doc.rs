use anyhow::{anyhow, Result};
use c35_proto::{SiteBlock, SiteDoc, SitePage};
use serde_json::Value;

pub const BLOCK_TYPES_V1: &[&str] = &[
    "hero",
    "markdown",
    "image",
    "gallery",
    "links",
    "product_grid",
    "contact_form",
    "map",
    "hours",
    "queue",
    "hub_profile",
    "social_feed",
    "order_track",
    "embed",
    "spacer",
    "custom_html",
];

pub fn site_doc_to_json(doc: &SiteDoc) -> Result<Value> {
    let pages: Vec<Value> = doc
        .pages
        .iter()
        .map(|p| {
            let blocks: Vec<Value> = p
                .blocks
                .iter()
                .map(|b| {
                    let props: Value = if b.props_json.is_empty() {
                        Value::Object(Default::default())
                    } else {
                        serde_json::from_str(&b.props_json).unwrap_or(Value::Object(Default::default()))
                    };
                    serde_json::json!({
                        "id": b.id,
                        "type": b.r#type,
                        "props": props,
                    })
                })
                .collect();
            serde_json::json!({
                "path": p.path,
                "title": p.title,
                "blocks": blocks,
            })
        })
        .collect();
    let theme: Value = if doc.theme_json.is_empty() {
        Value::Object(Default::default())
    } else {
        serde_json::from_str(&doc.theme_json).unwrap_or(Value::Object(Default::default()))
    };
    let meta: Value = if doc.meta_json.is_empty() {
        Value::Object(Default::default())
    } else {
        serde_json::from_str(&doc.meta_json).unwrap_or(Value::Object(Default::default()))
    };
    Ok(serde_json::json!({
        "pages": pages,
        "theme": theme,
        "meta": meta,
    }))
}

pub fn site_doc_from_json(v: &Value) -> SiteDoc {
    let pages = v
        .get("pages")
        .and_then(|x| x.as_array())
        .map(|arr| {
            arr.iter()
                .map(|p| {
                    let blocks = p
                        .get("blocks")
                        .and_then(|x| x.as_array())
                        .map(|bs| {
                            bs.iter()
                                .map(|b| SiteBlock {
                                    id: b.get("id").and_then(|x| x.as_str()).unwrap_or("").into(),
                                    r#type: b.get("type").and_then(|x| x.as_str()).unwrap_or("").into(),
                                    props_json: b
                                        .get("props")
                                        .map(|props| props.to_string())
                                        .unwrap_or_else(|| "{}".into()),
                                })
                                .collect()
                        })
                        .unwrap_or_default();
                    SitePage {
                        path: p.get("path").and_then(|x| x.as_str()).unwrap_or("/").into(),
                        title: p.get("title").and_then(|x| x.as_str()).unwrap_or("").into(),
                        blocks,
                    }
                })
                .collect()
        })
        .unwrap_or_default();
    SiteDoc {
        pages,
        theme_json: v
            .get("theme")
            .map(|x| x.to_string())
            .unwrap_or_else(|| "{}".into()),
        meta_json: v
            .get("meta")
            .map(|x| x.to_string())
            .unwrap_or_else(|| "{}".into()),
    }
}

pub fn site_doc_validate(doc: &SiteDoc) -> Result<()> {
    for page in &doc.pages {
        if page.path.is_empty() {
            return Err(anyhow!("page path required"));
        }
        for block in &page.blocks {
            if block.id.is_empty() {
                return Err(anyhow!("block id required"));
            }
            if !BLOCK_TYPES_V1.iter().any(|t| *t == block.r#type) {
                return Err(anyhow!("unsupported block type: {}", block.r#type));
            }
            let props: Value = if block.props_json.is_empty() {
                Value::Object(Default::default())
            } else {
                serde_json::from_str(&block.props_json)
                    .map_err(|e| anyhow!("invalid props_json: {e}"))?
            };
            block_props_validate(&block.r#type, &props)?;
        }
    }
    Ok(())
}

fn block_props_validate(block_type: &str, props: &Value) -> Result<()> {
    let obj = props
        .as_object()
        .ok_or_else(|| anyhow!("block props must be object"))?;
    match block_type {
        "hero" => {
            for k in obj.keys() {
                if !matches!(
                    k.as_str(),
                    "title" | "subtitle" | "pic" | "cta" | "cta_url" | "cta_label" | "cta_href" | "align"
                ) {
                    return Err(anyhow!("hero: unknown prop {k}"));
                }
            }
        }
        "markdown" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "content" | "body" | "align") {
                    return Err(anyhow!("markdown: unknown prop {k}"));
                }
            }
        }
        "image" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "pic" | "alt" | "caption" | "href") {
                    return Err(anyhow!("image: unknown prop {k}"));
                }
            }
        }
        "gallery" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "pics" | "columns" | "title") {
                    return Err(anyhow!("gallery: unknown prop {k}"));
                }
            }
        }
        "links" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "links" | "items" | "title") {
                    return Err(anyhow!("links: unknown prop {k}"));
                }
            }
        }
        "product_grid" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "filter" | "category" | "limit" | "page_size" | "columns") {
                    return Err(anyhow!("product_grid: unknown prop {k}"));
                }
            }
        }
        "contact_form" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "title" | "fields" | "submit_label") {
                    return Err(anyhow!("contact_form: unknown prop {k}"));
                }
            }
        }
        "map" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "lat" | "lng" | "zoom" | "address") {
                    return Err(anyhow!("map: unknown prop {k}"));
                }
            }
        }
        "hours" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "hours" | "schedule" | "title") {
                    return Err(anyhow!("hours: unknown prop {k}"));
                }
            }
        }
        "queue" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "title" | "mode" | "label" | "queue_id") {
                    return Err(anyhow!("queue: unknown prop {k}"));
                }
            }
        }
        "hub_profile" => {
            for k in obj.keys() {
                if !matches!(
                    k.as_str(),
                    "title" | "subtitle" | "pic" | "location_label" | "location_href" | "show_hours"
                ) {
                    return Err(anyhow!("hub_profile: unknown prop {k}"));
                }
            }
        }
        "social_feed" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "title" | "limit") {
                    return Err(anyhow!("social_feed: unknown prop {k}"));
                }
            }
            if let Some(limit) = obj.get("limit").and_then(|x| x.as_i64()) {
                if limit < 1 || limit > 20 {
                    return Err(anyhow!("social_feed: limit must be 1..20"));
                }
            }
        }
        "order_track" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "title" | "hint") {
                    return Err(anyhow!("order_track: unknown prop {k}"));
                }
            }
        }
        "embed" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "url" | "height" | "title") {
                    return Err(anyhow!("embed: unknown prop {k}"));
                }
            }
        }
        "spacer" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "height" | "size") {
                    return Err(anyhow!("spacer: unknown prop {k}"));
                }
            }
        }
        "custom_html" => {
            for k in obj.keys() {
                if !matches!(k.as_str(), "html") {
                    return Err(anyhow!("custom_html: unknown prop {k}"));
                }
            }
        }
        _ => return Err(anyhow!("unsupported block type: {block_type}")),
    }
    Ok(())
}

pub fn render_key_for_page(path: &str) -> String {
    let p = path.trim();
    if p.is_empty() || p == "/" {
        "html:/".into()
    } else {
        format!(
            "html:{}",
            if p.starts_with('/') {
                p.to_string()
            } else {
                format!("/{p}")
            }
        )
    }
}
