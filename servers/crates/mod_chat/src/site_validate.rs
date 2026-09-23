use anyhow::{anyhow, bail, Result};
use serde_json::{Map, Value};

pub const BLOCK_TYPES: &[&str] = &[
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
    "embed",
    "spacer",
    "custom_html",
];

pub fn block_props_allowed(block_type: &str) -> &'static [&'static str] {
    match block_type {
        "hero" => &["title", "subtitle", "pic", "cta_label", "cta_href", "align"],
        "markdown" => &["content", "align"],
        "image" => &["pic", "alt", "caption", "href"],
        "gallery" => &["pics", "columns", "title"],
        "links" => &["links", "title"],
        "product_grid" => &["filter", "category", "limit", "columns"],
        "contact_form" => &["title", "fields", "submit_label"],
        "map" => &["lat", "lng", "zoom", "address"],
        "hours" => &["hours", "title"],
        "queue" => &["title", "mode"],
        "embed" => &["url", "height", "title"],
        "spacer" => &["size", "height"],
        "custom_html" => &["html"],
        _ => &[],
    }
}

pub const THEME_KEYS: &[&str] = &["accent", "font", "layout", "background", "text_color"];
pub const META_KEYS: &[&str] = &["seo_title", "seo_desc", "favicon", "og_image"];

pub fn validate_object_keys(obj: &Map<String, Value>, allowed: &[&str], label: &str) -> Result<()> {
    for key in obj.keys() {
        if !allowed.contains(&key.as_str()) {
            return Err(anyhow!("unknown {label} key: {key}"));
        }
    }
    Ok(())
}

pub fn validate_block(block: &Value) -> Result<()> {
    let obj = block
        .as_object()
        .ok_or_else(|| anyhow!("block must be an object"))?;
    let id = obj.get("id").and_then(|v| v.as_str()).unwrap_or("").trim();
    if id.is_empty() {
        bail!("block.id is required");
    }
    let block_type = obj.get("type").and_then(|v| v.as_str()).unwrap_or("").trim();
    if block_type.is_empty() {
        bail!("block.type is required");
    }
    if !BLOCK_TYPES.contains(&block_type) {
        bail!("unknown block type: {block_type}");
    }
    let allowed = block_props_allowed(block_type);
    if allowed.is_empty() {
        bail!("block type has no prop schema: {block_type}");
    }
    let props = obj
        .get("props")
        .ok_or_else(|| anyhow!("block.props is required"))?;
    let props_obj = props
        .as_object()
        .ok_or_else(|| anyhow!("block.props must be an object"))?;
    validate_object_keys(props_obj, allowed, "block.props")?;
    Ok(())
}

pub fn validate_sitedoc(doc: &Value) -> Result<()> {
    let root = doc
        .as_object()
        .ok_or_else(|| anyhow!("doc must be an object"))?;
    let pages = root
        .get("pages")
        .ok_or_else(|| anyhow!("doc.pages is required"))?;
    let pages_arr = pages
        .as_array()
        .ok_or_else(|| anyhow!("doc.pages must be an array"))?;
    for (i, page) in pages_arr.iter().enumerate() {
        let page_obj = page
            .as_object()
            .ok_or_else(|| anyhow!("pages[{i}] must be an object"))?;
        let path = page_obj.get("path").and_then(|v| v.as_str()).unwrap_or("").trim();
        if path.is_empty() {
            bail!("pages[{i}].path is required");
        }
        let blocks = page_obj
            .get("blocks")
            .ok_or_else(|| anyhow!("pages[{i}].blocks is required"))?;
        let blocks_arr = blocks
            .as_array()
            .ok_or_else(|| anyhow!("pages[{i}].blocks must be an array"))?;
        for (j, block) in blocks_arr.iter().enumerate() {
            validate_block(block).map_err(|e| anyhow!("pages[{i}].blocks[{j}]: {e}"))?;
        }
    }
    if let Some(theme) = root.get("theme") {
        let theme_obj = theme
            .as_object()
            .ok_or_else(|| anyhow!("doc.theme must be an object"))?;
        validate_object_keys(theme_obj, THEME_KEYS, "theme")?;
    }
    if let Some(meta) = root.get("meta") {
        let meta_obj = meta
            .as_object()
            .ok_or_else(|| anyhow!("doc.meta must be an object"))?;
        validate_object_keys(meta_obj, META_KEYS, "meta")?;
    }
    Ok(())
}
