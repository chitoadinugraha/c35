use chrono::Utc;
use c35_proto::{
    ReqSync, ResSync, SiteConfig, SiteContact, SiteDraft, SiteObject, SiteProduct,
    SiteProductEmbed, SyncCollectionCursor,
};
use sqlx::{PgPool, Row};

use crate::doc::site_doc_from_json;
use crate::rows::domain_from_row;
use crate::site_ids::site_ids_for_caller;
use crate::ts::{ts_ms, ts_ms_opt};

const SITE_COLLECTIONS: &[&str] = &[
    "site_draft",
    "site_config",
    "site_domain",
    "site_product",
    "site_product_embed",
    "site_contact",
    "site_object",
];

fn wants(collections: &[String], name: &str) -> bool {
    collections.is_empty() || collections.iter().any(|c| c == name)
}

fn cursor(name: &str, max_ts: i64, count: usize, limit: usize) -> SyncCollectionCursor {
    SyncCollectionCursor {
        name: name.into(),
        max_updated_ts_ms: max_ts,
        caught_up: count < limit,
    }
}

pub async fn sync_pull(pool: &PgPool, caller_iid: i64, req: ReqSync) -> ResSync {
    let since_ms = req.since_ms;
    let limit = if req.limit_per_collection <= 0 {
        500
    } else {
        req.limit_per_collection.min(2000) as i64
    };
    let site_ids = site_ids_for_caller(pool, caller_iid).await;
    let collections = req.collections.clone();
    let now_ms = Utc::now().timestamp_millis();

    let mut res = ResSync {
        since_ms,
        server_time_ms: now_ms,
        cursors: vec![],
        ..Default::default()
    };

    if site_ids.is_empty() {
        return res;
    }

    if wants(&collections, "site_draft") {
        let rows = sqlx::query(
            r#"
            SELECT site_iid, owner_iid, doc_json, created_ts, updated_ts, deleted_ts
            FROM site.draft
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let doc_json: serde_json::Value = r.get("doc_json");
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_drafts.push(SiteDraft {
                site_iid: r.get("site_iid"),
                owner_iid: r.get("owner_iid"),
                doc: Some(site_doc_from_json(&doc_json)),
                created_ts_ms: ts_ms(r.get("created_ts")),
                updated_ts_ms: updated,
                deleted_ts_ms: ts_ms_opt(r.get("deleted_ts")),
            });
        }
        res.cursors.push(cursor("site_draft", max_ts, rows.len(), limit as usize));
    }

    if wants(&collections, "site_config") {
        let rows = sqlx::query(
            r#"
            SELECT site_iid, owner_iid, published_version_id, inventory_costing_method, tz,
                   payroll_policy_json, presence_policy_json, capabilities_json,
                   alien_id_changed_ts, created_ts, updated_ts, deleted_ts
            FROM site.config
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_configs.push(SiteConfig {
                site_iid: r.get("site_iid"),
                owner_iid: r.get("owner_iid"),
                published_version_id: r
                    .try_get::<Option<String>, _>("published_version_id")
                    .ok()
                    .flatten()
                    .unwrap_or_default(),
                inventory_costing_method: r.get("inventory_costing_method"),
                tz: r.get("tz"),
                payroll_policy_json: r.get::<serde_json::Value, _>("payroll_policy_json").to_string(),
                presence_policy_json: r.get::<serde_json::Value, _>("presence_policy_json").to_string(),
                capabilities_json: r.get::<serde_json::Value, _>("capabilities_json").to_string(),
                alien_id_changed_ts_ms: ts_ms(r.get("alien_id_changed_ts")),
                created_ts_ms: ts_ms(r.get("created_ts")),
                updated_ts_ms: updated,
                deleted_ts_ms: ts_ms_opt(r.get("deleted_ts")),
            });
        }
        res.cursors.push(cursor("site_config", max_ts, rows.len(), limit as usize));
    }

    if wants(&collections, "site_domain") {
        let rows = sqlx::query(
            r#"
            SELECT id, site_iid, hostname, is_primary, tls_status, verify_token, verified_ts,
                   created_ts, updated_ts, deleted_ts
            FROM site.domain
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_domains.push(domain_from_row(r));
        }
        res.cursors.push(cursor("site_domain", max_ts, rows.len(), limit as usize));
    }

    if wants(&collections, "site_product") {
        let rows = sqlx::query(
            r#"
            SELECT site_iid, product_id, type, name, "desc", unit, sku, rev,
                   can_sell, can_reserve, track_stock, stock_qty, price, pic, category,
                   product_json, is_archived, created_ts, updated_ts, deleted_ts
            FROM site.product
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_products.push(SiteProduct {
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
                created_ts_ms: ts_ms(r.get("created_ts")),
                updated_ts_ms: updated,
                deleted_ts_ms: ts_ms_opt(r.get("deleted_ts")),
            });
        }
        res.cursors.push(cursor("site_product", max_ts, rows.len(), limit as usize));
    }

    if wants(&collections, "site_product_embed") {
        let rows = sqlx::query(
            r#"
            SELECT site_iid, embed_id, product_id, label, created_ts, updated_ts, deleted_ts
            FROM site.product_embed
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_product_embeds.push(SiteProductEmbed {
                site_iid: r.get("site_iid"),
                embed_id: r.get("embed_id"),
                product_id: r.get("product_id"),
                label: r.get("label"),
                created_ts_ms: ts_ms(r.get("created_ts")),
                updated_ts_ms: updated,
                deleted_ts_ms: ts_ms_opt(r.get("deleted_ts")),
            });
        }
        res.cursors.push(cursor("site_product_embed", max_ts, rows.len(), limit as usize));
    }

    if wants(&collections, "site_contact") {
        let rows = sqlx::query(
            r#"
            SELECT site_iid, contact_id, name, phone, email, address, note, meta_json,
                   is_archived, created_ts, updated_ts, deleted_ts
            FROM site.contact
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_contacts.push(SiteContact {
                site_iid: r.get("site_iid"),
                contact_id: r.get("contact_id"),
                name: r.get("name"),
                phone: r.get("phone"),
                email: r.get("email"),
                address: r.get("address"),
                note: r.get("note"),
                meta_json: r.get::<serde_json::Value, _>("meta_json").to_string(),
                is_archived: r.get("is_archived"),
                created_ts_ms: ts_ms(r.get("created_ts")),
                updated_ts_ms: updated,
                deleted_ts_ms: ts_ms_opt(r.get("deleted_ts")),
            });
        }
        res.cursors.push(cursor("site_contact", max_ts, rows.len(), limit as usize));
    }

    if wants(&collections, "site_object") {
        let rows = sqlx::query(
            r#"
            SELECT id, site_iid, client_id, name, code, kind, product_id,
                   can_order, can_be_reserved, is_active, "desc", pic, meta_json,
                   created_ts, updated_ts, deleted_ts
            FROM site.object
            WHERE site_iid = ANY($1::bigint[])
              AND updated_ts > to_timestamp($2::double precision / 1000.0)
            ORDER BY updated_ts ASC
            LIMIT $3
            "#,
        )
        .bind(&site_ids)
        .bind(since_ms)
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        let mut max_ts = since_ms;
        for r in &rows {
            let updated = ts_ms(r.get("updated_ts"));
            max_ts = max_ts.max(updated);
            res.site_objects.push(SiteObject {
                id: r.get("id"),
                site_iid: r.get("site_iid"),
                client_id: r.get("client_id"),
                name: r.get("name"),
                code: r.get("code"),
                kind: r.get("kind"),
                product_id: r.try_get("product_id").ok().flatten().unwrap_or(0),
                can_order: r.get("can_order"),
                can_be_reserved: r.get("can_be_reserved"),
                is_active: r.get("is_active"),
                desc: r.get("desc"),
                pic: r.get("pic"),
                meta_json: r.get::<serde_json::Value, _>("meta_json").to_string(),
                created_ts_ms: ts_ms(r.get("created_ts")),
                updated_ts_ms: updated,
                deleted_ts_ms: ts_ms_opt(r.get("deleted_ts")),
            });
        }
        res.cursors.push(cursor("site_object", max_ts, rows.len(), limit as usize));
    }

    if collections.is_empty() {
        for name in SITE_COLLECTIONS {
            if !res.cursors.iter().any(|c| c.name == *name) {
                res.cursors.push(SyncCollectionCursor {
                    name: (*name).into(),
                    max_updated_ts_ms: since_ms,
                    caught_up: true,
                });
            }
        }
    }

    res
}
