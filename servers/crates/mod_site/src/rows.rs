use c35_proto::{SiteContact, SiteDomain, SiteGrant, SiteLink, SiteObject, SitePost, SiteProduct, SiteQueue};
use chrono::{DateTime, Utc};
use sqlx::Row;

fn ts_ms(t: Option<DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

/// `site.product.type` is SMALLINT in Postgres; proto uses int32.
pub(crate) fn col_i32_smallint(r: &sqlx::postgres::PgRow, name: &str) -> i32 {
    i32::from(r.get::<i16, _>(name))
}

pub(crate) fn col_text(r: &sqlx::postgres::PgRow, name: &str) -> String {
    r.get::<Option<String>, _>(name).unwrap_or_default()
}

pub fn product_from_row(r: &sqlx::postgres::PgRow) -> SiteProduct {
    SiteProduct {
        site_iid: r.get("site_iid"),
        product_id: r.get("product_id"),
        r#type: col_i32_smallint(r, "type"),
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
        pic: col_text(r, "pic"),
        category: r.get("category"),
        product_json: r.get::<serde_json::Value, _>("product_json").to_string(),
        is_archived: r.get("is_archived"),
        sort_order: r.get("sort_order"),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

pub fn post_from_row(r: &sqlx::postgres::PgRow) -> SitePost {
    SitePost {
        site_iid: r.get("site_iid"),
        post_id: r.get("post_id"),
        sort_order: r.get("sort_order"),
        title: r.get("title"),
        caption: r.get("caption"),
        body: r.get("body"),
        media_json: r.get::<serde_json::Value, _>("media_json").to_string(),
        on_storefront: r.get("on_storefront"),
        thumb: r.get("thumb"),
        feed_kind: r.get("feed_kind"),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

pub fn link_from_row(r: &sqlx::postgres::PgRow) -> SiteLink {
    SiteLink {
        site_iid: r.get("site_iid"),
        link_id: r.get("link_id"),
        sort_order: r.get("sort_order"),
        label: r.get("label"),
        url: r.get("url"),
        icon: r.get("icon"),
        is_pinned: r.get("is_pinned"),
        active: r.get("active"),
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
        pic: col_text(r, "pic"),
        meta_json: r.get::<serde_json::Value, _>("meta_json").to_string(),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

pub fn grant_from_row(r: &sqlx::postgres::PgRow) -> SiteGrant {
    SiteGrant {
        site_iid: r.get("site_iid"),
        grantee_iid: r.get("grantee_iid"),
        grantee_alien_id: r.get("grantee_alien_id"),
        grantee_name: r.get("grantee_name"),
        role: r.get("role"),
        created_ts_ms: ts_ms(Some(r.get("created_ts"))),
        updated_ts_ms: ts_ms(Some(r.get("updated_ts"))),
    }
}

pub fn queue_from_row(r: &sqlx::postgres::PgRow) -> SiteQueue {
    SiteQueue {
        site_iid: r.get("site_iid"),
        queue_id: r.get("queue_id"),
        owner_iid: r.get("owner_iid"),
        name: r.get("name"),
        mode: r.get("mode"),
        prefix: r.get("prefix"),
        last_ticket_no: r.get("last_ticket_no"),
        serving_ticket_no: r.get("serving_ticket_no"),
        is_active: r.get("is_active"),
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
