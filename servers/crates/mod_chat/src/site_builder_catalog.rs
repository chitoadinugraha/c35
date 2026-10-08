use anyhow::Result;
use serde_json::{json, Value};

use crate::compose::site_builder_bootstrap_catalog;
use crate::tools::builtin::site::site_product_put_exec;
use crate::tools::ToolContext;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CatalogProductRow {
    pub name: String,
    pub price: i64,
}

fn digits_only_amount(raw: &str) -> i64 {
    let t = raw.trim().replace(',', ".");
    let mut num = String::new();
    let mut saw_dot = false;
    for c in t.chars() {
        if c.is_ascii_digit() {
            num.push(c);
        } else if c == '.' && !saw_dot {
            saw_dot = true;
            num.push(c);
        }
    }
    if num.is_empty() {
        return 0;
    }
    num.parse::<f64>().map(|f| f.round() as i64).unwrap_or(0)
}

fn parse_idr_price_token(raw: &str) -> i64 {
    let compact = raw.trim().to_lowercase().replace(' ', "");
    if compact.is_empty() {
        return 0;
    }
    if let Some(stem) = compact.strip_suffix("rb").or_else(|| compact.strip_suffix('k')) {
        let base = digits_only_amount(stem);
        return if base > 0 { base * 1000 } else { 0 };
    }
    if let Some(stem) = compact
        .strip_suffix("jt")
        .or_else(|| compact.strip_suffix("juta"))
        .or_else(|| compact.strip_suffix('m'))
    {
        let base = digits_only_amount(stem);
        return if base > 0 { base * 1_000_000 } else { 0 };
    }
    if compact.contains("ribu") {
        let base = digits_only_amount(&compact.replace("ribu", ""));
        return if base > 0 { base * 1000 } else { 0 };
    }
    digits_only_amount(&compact)
}

fn catalog_segment_rows(segment: &str) -> Vec<CatalogProductRow> {
    let seg = segment.trim();
    if seg.is_empty() {
        return vec![];
    }
    let lower = seg.to_lowercase();
    let Some(harga_idx) = lower.rfind(" harga ") else {
        return vec![];
    };
    let name = seg[..harga_idx].trim();
    let price_raw = seg[harga_idx + " harga ".len()..].trim();
    if name.is_empty() {
        return vec![];
    }
    let price = parse_idr_price_token(price_raw);
    if price <= 0 {
        return vec![];
    }
    vec![CatalogProductRow {
        name: name.to_string(),
        price,
    }]
}

/// Parse `produk … harga …` segments from a one-shot site + POS prompt (comma-separated list).
pub fn site_builder_catalog_parse(text: &str) -> Vec<CatalogProductRow> {
    let lower = text.to_lowercase();
    let tail = lower
        .find("produk")
        .map(|i| text[i + "produk".len()..].trim())
        .unwrap_or(text);
    let tail = tail
        .trim_start_matches(|c: char| c == ':' || c == ',' || c == ' ')
        .trim_start_matches("dengan")
        .trim();
    if tail.is_empty() {
        return vec![];
    }
    let mut out = Vec::new();
    for part in tail.split(',') {
        let part = part.trim().trim_start_matches("dan").trim();
        for row in catalog_segment_rows(part) {
            if !out.iter().any(|r: &CatalogProductRow| r.name.eq_ignore_ascii_case(&row.name)) {
                out.push(row);
            }
        }
    }
    out
}

pub async fn site_builder_catalog_seed_if_needed(
    ctx: &ToolContext,
    site_iid: i64,
    user_text: &str,
) -> Result<Vec<Value>> {
    if !site_builder_bootstrap_catalog(user_text) {
        return Ok(vec![]);
    }
    let rows = site_builder_catalog_parse(user_text);
    if rows.is_empty() {
        return Ok(vec![]);
    }
    let mut created = Vec::with_capacity(rows.len());
    for row in rows {
        let args = json!({
            "site_iid": site_iid.to_string(),
            "name": row.name,
            "price": row.price,
            "can_sell": true,
        });
        let res = site_product_put_exec(ctx, &args).await?;
        created.push(res);
    }
    Ok(created)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_pos_bootstrap_prompt_three_products() {
        let text = "buat situs testing test-site dengan fitur POS, dengan produk indomie harga 20rb,mie goreng harga 15rb, es teh harga 10rb";
        let rows = site_builder_catalog_parse(text);
        assert_eq!(rows.len(), 3);
        assert_eq!(rows[0].name, "indomie");
        assert_eq!(rows[0].price, 20_000);
        assert_eq!(rows[1].name, "mie goreng");
        assert_eq!(rows[1].price, 15_000);
        assert_eq!(rows[2].name, "es teh");
        assert_eq!(rows[2].price, 10_000);
    }

    #[test]
    fn parse_idr_rb_and_ribu() {
        assert_eq!(parse_idr_price_token("20rb"), 20_000);
        assert_eq!(parse_idr_price_token("15 ribu"), 15_000);
    }
}
