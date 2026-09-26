use c35_proto::{SiteContact, SiteDomain, SiteObject, SiteProduct};
use chrono::{DateTime, Utc};
use sqlx::Row;

fn ts_ms(t: Option<DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

pub fn product_from_row(r: &sqlx::postgres::PgRow) -> SiteProduct {
    SiteProduct {
        site_iid: r.get("site_iid"),
        product_id: r.get("product_id"),
        r#type: r.get("type"),
        name: r.get("name"),
        desc: r.get("desc"),
        unit: r.get("unit"),
        sku: r.get("sku"),
        rev: r.get("rev"),
        can_sell: r.get("can_sell"),
        can_reserve: r.get("can_reserve"),
        track_stock: r.get("track_stock"),
        stock_qty: r.get("stock_qty"),
        price: r.get("price"),
        pic: r.get("pic"),
        category: r.get("category"),
        product_json: r.get::<serde_json::Value, _>("product_json").to_string(),
        is_archived: r.get("is_archived"),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

pub fn contact_from_row(r: &sqlx::postgres::PgRow) -> SiteContact {
    SiteContact {
        site_iid: r.get("site_iid"),
        contact_id: r.get("contact_id"),
        name: r.get("name"),
        phone: r.get("phone"),
        email: r.get("email"),
        address: r.get("address"),
        note: r.get("note"),
        meta_json: r.get::<serde_json::Value, _>("meta_json").to_string(),
        is_archived: r.get("is_archived"),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

pub fn object_from_row(r: &sqlx::postgres::PgRow) -> SiteObject {
    SiteObject {
        id: r.get("id"),
        site_iid: r.get("site_iid"),
        client_id: r.get("client_id"),
        name: r.get("name"),
        code: r.get("code"),
        kind: r.get("kind"),
        product_id: r.get::<Option<i64>, _>("product_id").unwrap_or(0),
        can_order: r.get("can_order"),
        can_be_reserved: r.get("can_be_reserved"),
        is_active: r.get("is_active"),
        desc: r.get("desc"),
        pic: r.get("pic"),
        meta_json: r.get::<serde_json::Value, _>("meta_json").to_string(),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

pub fn domain_from_row(r: &sqlx::postgres::PgRow) -> SiteDomain {
    SiteDomain {
        id: r.get("id"),
        site_iid: r.get("site_iid"),
        hostname: r.get("hostname"),
        is_primary: r.get("is_primary"),
        tls_status: r.get("tls_status"),
        verified_ts_ms: ts_ms(r.get("verified_ts")),
        verify_token: r.get("verify_token"),
        verify_error: r.get("verify_error"),
        tls_error: r.get("tls_error"),
        last_verify_ts_ms: ts_ms(r.get("last_verify_ts")),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}
