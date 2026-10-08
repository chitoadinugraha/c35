use anyhow::{anyhow, Result};
use c35_proto::{ResSiteGuestProductList, SiteGuestProductItem};
use serde_json::Value;
use sqlx::{PgPool, Row};

use crate::rows::col_text;

pub struct ProductRow {
    pub product_id: i64,
    pub name: String,
    pub desc: String,
    pub price: i64,
    pub pic: String,
    pub category: String,
    pub sort_order: i32,
    pub can_reserve: bool,
    pub duration_value: i64,
    pub duration_unit: String,
    pub reservation_unit_selection: String,
    pub icon: String,
}

fn guest_icon_svg(p: &ProductRow) -> &'static str {
    if !p.pic.trim().is_empty() {
        return "";
    }
    let svg = crate::product_icon_svg::product_icon_svg(&p.icon);
    if svg.is_empty() {
        crate::product_icon_svg::product_icon_svg("mdi:shopping")
    } else {
        svg
    }
}

pub fn product_row_json(p: &ProductRow) -> Value {
    serde_json::json!({
        "product_id": p.product_id,
        "name": p.name,
        "desc": p.desc,
        "price": p.price,
        "pic": pic_url(&p.pic),
        "icon": p.icon,
        "icon_svg": guest_icon_svg(p),
        "category": p.category,
        "can_reserve": p.can_reserve,
        "duration_value": p.duration_value,
        "duration_unit": p.duration_unit,
        "reservation_unit_selection": p.reservation_unit_selection,
    })
}

/// Duration and unit-selection fields from `site.product.product_json`.
/// Same rules as `siteProductExtrasRead` in `site_product_json.dart`.
/// Invalid JSON, or a value that is not an object, uses the defaults.
pub fn reservation_fields_from_product_json(raw: &str) -> (i64, String, String) {
    let parsed = serde_json::from_str::<Value>(raw).ok();
    let map = parsed.as_ref().and_then(|v| v.as_object());
    let Some(map) = map else {
        return reservation_field_defaults();
    };
    let duration_value = map
        .get("duration_value")
        .and_then(json_num_to_int)
        .filter(|n| *n > 0)
        .unwrap_or(1);
    let unit_raw = map
        .get("duration_unit")
        .map(json_trim_string)
        .unwrap_or_default();
    let duration_unit = if unit_raw.is_empty() {
        "day".to_string()
    } else {
        unit_raw
    };
    let selection_raw = map
        .get("reservation_unit_selection")
        .map(json_trim_string)
        .unwrap_or_default();
    let reservation_unit_selection = if selection_raw == "guest_picks" {
        "guest_picks".to_string()
    } else {
        "system".to_string()
    };
    (duration_value, duration_unit, reservation_unit_selection)
}

fn reservation_field_defaults() -> (i64, String, String) {
    (1, "day".to_string(), "system".to_string())
}

fn json_num_to_int(v: &Value) -> Option<i64> {
    match v {
        Value::Number(n) => n
            .as_i64()
            .or_else(|| n.as_f64().map(|f| f.trunc() as i64)),
        _ => None,
    }
}

fn json_trim_string(v: &Value) -> String {
    match v {
        Value::String(s) => s.trim().to_string(),
        Value::Null => String::new(),
        other => other.to_string(),
    }
}

fn reservation_fields_from_json_value(v: &Value) -> (i64, String, String) {
    reservation_fields_from_product_json(&v.to_string())
}

fn product_row_from_pg(r: &sqlx::postgres::PgRow) -> ProductRow {
    let product_json: Value = r.get("product_json");
    let (duration_value, duration_unit, reservation_unit_selection) =
        reservation_fields_from_json_value(&product_json);
    ProductRow {
        product_id: r.get("product_id"),
        name: r.get("name"),
        desc: r.get("desc"),
        price: r.get("price"),
        pic: col_text(r, "pic"),
        category: r.get("category"),
        sort_order: r.get("sort_order"),
        can_reserve: r.get("can_reserve"),
        duration_value,
        duration_unit,
        reservation_unit_selection,
        icon: String::new(),
    }
}

pub fn pic_url(pic: &str) -> String {
    let p = pic.trim();
    if p.is_empty() {
        return String::new();
    }
    if p.starts_with("http://") || p.starts_with("https://") || p.starts_with("/fs/") {
        return p.to_string();
    }
    format!("/fs/{}?v=thumb", p)
}

pub struct GuestProductListResult {
    pub items: Vec<ProductRow>,
    pub next_cursor: String,
}

pub fn product_grid_page_size(props: &Value) -> i32 {
    let page_size = props.get("page_size").and_then(|x| x.as_i64());
    let limit = props.get("limit").and_then(|x| x.as_i64());
    let raw = page_size.or(limit).unwrap_or(24) as i32;
    if raw <= 0 {
        24
    } else {
        raw.min(48)
    }
}

pub fn product_cursor_encode(sort_order: i32, product_id: i64) -> String {
    format!("{sort_order}:{product_id}")
}

pub fn product_cursor_decode(cursor: &str) -> Result<Option<(i32, i64)>> {
    let c = cursor.trim();
    if c.is_empty() {
        return Ok(None);
    }
    let (sort, pid) = c
        .split_once(':')
        .ok_or_else(|| anyhow!("invalid product cursor"))?;
    let sort_order: i32 = sort
        .parse()
        .map_err(|_| anyhow!("invalid product cursor sort_order"))?;
    let product_id: i64 = pid
        .parse()
        .map_err(|_| anyhow!("invalid product cursor product_id"))?;
    Ok(Some((sort_order, product_id)))
}

pub fn guest_product_limit_clamp(limit: i32) -> i32 {
    if limit <= 0 {
        24
    } else {
        limit.min(48)
    }
}

pub async fn guest_product_list(
    pool: &PgPool,
    site_iid: i64,
    filter: &str,
    category: &str,
    cursor: &str,
    limit: i32,
) -> Result<GuestProductListResult> {
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let lim = guest_product_limit_clamp(limit);
    let keyset = product_cursor_decode(cursor)?;
    let rows = fetch_product_rows(pool, site_iid, filter, category, keyset, lim + 1).await?;
    let has_more = rows.len() > lim as usize;
    let page: Vec<ProductRow> = if has_more {
        rows.into_iter().take(lim as usize).collect()
    } else {
        rows
    };
    let next_cursor = if has_more {
        let last = page.last().expect("has_more implies non-empty page");
        product_cursor_encode(last.sort_order, last.product_id)
    } else {
        String::new()
    };
    let mut page = page;
    fill_row_icons(pool, &mut page).await;
    Ok(GuestProductListResult {
        items: page,
        next_cursor,
    })
}

async fn fill_row_icons(pool: &PgPool, rows: &mut [ProductRow]) {
    let pairs: Vec<(String, String)> = rows.iter().map(|p| (p.pic.clone(), p.name.clone())).collect();
    let icons = crate::product_icon::product_icon_ids(pool, &pairs).await;
    for (row, icon) in rows.iter_mut().zip(icons) {
        row.icon = icon;
    }
}

pub async fn product_rows_for_grid(
    pool: &PgPool,
    site_iid: i64,
    filter: &str,
    category: &str,
    limit: i32,
) -> Result<Vec<ProductRow>> {
    let res = guest_product_list(pool, site_iid, filter, category, "", limit).await?;
    Ok(res.items)
}

pub fn guest_product_list_to_proto(res: &GuestProductListResult) -> ResSiteGuestProductList {
    ResSiteGuestProductList {
        items: res
            .items
            .iter()
            .map(|p| SiteGuestProductItem {
                product_id: p.product_id,
                name: p.name.clone(),
                desc: p.desc.clone(),
                price: p.price,
                pic: pic_url(&p.pic),
                category: p.category.clone(),
                icon: p.icon.clone(),
            })
            .collect(),
        next_cursor: res.next_cursor.clone(),
    }
}

async fn fetch_product_rows(
    pool: &PgPool,
    site_iid: i64,
    filter: &str,
    category: &str,
    keyset: Option<(i32, i64)>,
    limit: i32,
) -> Result<Vec<ProductRow>> {
    let lim = limit.max(1);
    let rows = if filter == "recommended" {
        if let Some((sort_order, product_id)) = keyset {
            sqlx::query(
                r#"
                SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
                FROM site.product
                WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE
                  AND can_sell = TRUE AND recommended_guest = TRUE
                  AND (sort_order, product_id) > ($2, $3)
                ORDER BY sort_order, product_id
                LIMIT $4
                "#,
            )
            .bind(site_iid)
            .bind(sort_order)
            .bind(product_id)
            .bind(lim)
            .fetch_all(pool)
            .await?
        } else {
            sqlx::query(
                r#"
                SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
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
        }
    } else if !category.is_empty() {
        if let Some((sort_order, product_id)) = keyset {
            sqlx::query(
                r#"
                SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
                FROM site.product
                WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE
                  AND can_sell = TRUE AND category = $2
                  AND (sort_order, product_id) > ($3, $4)
                ORDER BY sort_order, product_id
                LIMIT $5
                "#,
            )
            .bind(site_iid)
            .bind(category)
            .bind(sort_order)
            .bind(product_id)
            .bind(lim)
            .fetch_all(pool)
            .await?
        } else {
            sqlx::query(
                r#"
                SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
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
        }
    } else if let Some((sort_order, product_id)) = keyset {
        sqlx::query(
            r#"
            SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
            FROM site.product
            WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE
              AND can_sell = TRUE
              AND (sort_order, product_id) > ($2, $3)
            ORDER BY sort_order, product_id
            LIMIT $4
            "#,
        )
        .bind(site_iid)
        .bind(sort_order)
        .bind(product_id)
        .bind(lim)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
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
    Ok(rows.iter().map(product_row_from_pg).collect())
}

pub struct GuestProductDetail {
    pub row: ProductRow,
    pub can_reserve: bool,
}

pub async fn guest_product_get(
    pool: &PgPool,
    site_iid: i64,
    product_id: i64,
) -> Result<Option<GuestProductDetail>> {
    if site_iid <= 0 || product_id <= 0 {
        return Ok(None);
    }
    let row = sqlx::query(
        r#"
        SELECT product_id, name, "desc", price, pic, category, sort_order, can_reserve, product_json
        FROM site.product
        WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL AND is_archived = FALSE
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .fetch_optional(pool)
    .await?;
    let Some(r) = row else {
        return Ok(None);
    };
    let mut product = product_row_from_pg(&r);
    fill_row_icons(pool, std::slice::from_mut(&mut product)).await;
    let can_reserve = product.can_reserve;
    Ok(Some(GuestProductDetail {
        row: product,
        can_reserve,
    }))
}

pub async fn guest_product_sell_ids(pool: &PgPool, site_iid: i64, limit: i32) -> Result<Vec<i64>> {
    if site_iid <= 0 {
        return Ok(vec![]);
    }
    let lim = limit.clamp(1, 500);
    let rows = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT product_id FROM site.product
        WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = FALSE AND can_sell = TRUE
        ORDER BY sort_order, product_id
        LIMIT $2
        "#,
    )
    .bind(site_iid)
    .bind(lim)
    .fetch_all(pool)
    .await?;
    Ok(rows)
}

#[cfg(test)]
mod tests {
    use super::reservation_fields_from_product_json;

    #[test]
    fn product_json_reservation_fields() {
        let (duration, unit, selection) = reservation_fields_from_product_json(
            r#"{"duration_unit":"hour","reservation_unit_selection":"guest_picks"}"#,
        );
        assert_eq!(duration, 1);
        assert_eq!(unit, "hour");
        assert_eq!(selection, "guest_picks");

        let (duration, unit, selection) = reservation_fields_from_product_json("{}");
        assert_eq!(duration, 1);
        assert_eq!(unit, "day");
        assert_eq!(selection, "system");

        let (duration, unit, selection) = reservation_fields_from_product_json("not-json");
        assert_eq!(duration, 1);
        assert_eq!(unit, "day");
        assert_eq!(selection, "system");
    }
}