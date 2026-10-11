use serde_json::Value;

/// Legacy / editor sentinel: show "Contact Us" instead of a numeric price.
pub const GUEST_PRODUCT_PRICE_CONTACT: i64 = -1;

pub fn format_idr(amount: i64) -> String {
    let neg = amount < 0;
    let mut s = amount.abs().to_string();
    let mut out = String::new();
    while s.len() > 3 {
        let split = s.len() - 3;
        out = format!(".{}{}", &s[split..], out);
        s.truncate(split);
    }
    out = format!("{s}{out}");
    if neg {
        format!("-Rp {out}")
    } else {
        format!("Rp {out}")
    }
}

pub fn guest_product_price_label(price: i64) -> String {
    if price == GUEST_PRODUCT_PRICE_CONTACT {
        return "Contact Us".to_string();
    }
    if price <= 0 {
        return String::new();
    }
    format_idr(price)
}

pub fn guest_product_can_add_to_cart(price: i64) -> bool {
    price > 0
}

/// `grid` (default) or `list`.
pub fn product_grid_display(props: &Value, meta: &Value) -> &'static str {
    let raw = props
        .get("display")
        .and_then(|x| x.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty());
    if let Some(d) = raw {
        if d.eq_ignore_ascii_case("list") {
            return "list";
        }
        if d.eq_ignore_ascii_case("grid") || d.eq_ignore_ascii_case("card") {
            return "grid";
        }
    }
    let meta_raw = meta
        .get("catalog_display")
        .and_then(|x| x.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty());
    if meta_raw.is_some_and(|d| d.eq_ignore_ascii_case("list")) {
        return "list";
    }
    "grid"
}

fn pic_hash_only(pic: &str) -> String {
    let p = pic.trim();
    if p.is_empty() {
        return String::new();
    }
    if p.starts_with("http://") || p.starts_with("https://") {
        return p.to_string();
    }
    let path = p.strip_prefix("/fs/").unwrap_or(p);
    path.split('?').next().unwrap_or(path).to_string()
}

/// Catalog grid / list cells.
pub fn pic_url_thumb(pic: &str) -> String {
    let h = pic_hash_only(pic);
    if h.is_empty() {
        return String::new();
    }
    if h.starts_with("http://") || h.starts_with("https://") {
        return h;
    }
    format!("/fs/{}?v=thumb", h)
}

/// Product detail and image lightbox.
pub fn pic_url_display(pic: &str) -> String {
    let h = pic_hash_only(pic);
    if h.is_empty() {
        return String::new();
    }
    if h.starts_with("http://") || h.starts_with("https://") {
        return h;
    }
    format!("/fs/{}?v=small", h)
}

pub fn pic_url(pic: &str) -> String {
    pic_url_thumb(pic)
}
