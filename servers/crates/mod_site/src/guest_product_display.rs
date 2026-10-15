use serde_json::Value;

use crate::guest_i18n::{guest_layout_mode, GuestI18n};

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
    guest_product_price_label_i18n(price, &GuestI18n::english())
}

pub fn guest_product_price_label_i18n(price: i64, i18n: &GuestI18n) -> String {
    if price == GUEST_PRODUCT_PRICE_CONTACT {
        return i18n.price_contact().to_string();
    }
    if price <= 0 {
        return String::new();
    }
    format_idr(price)
}

pub fn guest_product_can_add_to_cart(price: i64) -> bool {
    price > 0
}

/// `grid` or `list` (store layout defaults to list when unset).
pub fn product_grid_display(props: &Value, meta: &Value, product_count: usize) -> &'static str {
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
    if meta_raw.is_some_and(|d| d.eq_ignore_ascii_case("grid") || d.eq_ignore_ascii_case("card")) {
        return "grid";
    }
    if guest_layout_mode(meta, product_count) == "store" {
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

/// Guest-facing stock line when `stock_show_to_customer` is set (CSA / editor parity).
pub fn guest_product_stock_customer_label(
    show_to_customer: bool,
    stock_qty: Option<i64>,
    stock_unit: &str,
    stock_show_max_qty: i64,
) -> Option<String> {
    if !show_to_customer {
        return None;
    }
    let Some(qty) = stock_qty.filter(|q| *q > 0) else {
        return None;
    };
    let unit = stock_unit.trim();
    let unit_suffix = if unit.is_empty() {
        String::new()
    } else {
        format!(" {}", unit)
    };
    let display = if stock_show_max_qty > 0 && qty > stock_show_max_qty {
        format!("{}+", stock_show_max_qty)
    } else {
        qty.to_string()
    };
    Some(format!("Stock: {display}{unit_suffix}"))
}
