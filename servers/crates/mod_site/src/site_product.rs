use std::collections::HashSet;

use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteProductDelete, ReqSiteProductList, ReqSiteProductPut, ReqSiteProductReorder,
    ResSiteProductDelete, ResSiteProductList, ResSiteProductPut, ResSiteProductReorder,
    SiteProduct, sync_push,
};
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::product_from_row;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

fn embed_ids_from_json(v: &serde_json::Value) -> Vec<i64> {
    v.as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|item| item.as_i64().or_else(|| item.as_str().and_then(|s| s.parse().ok())))
                .filter(|id| *id > 0)
                .collect()
        })
        .unwrap_or_default()
}

async fn product_embed_soft_delete_tx(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    site_iid: i64,
    product_id: i64,
    embed_ids: &[i64],
) -> Result<()> {
    if embed_ids.is_empty() {
        return Ok(());
    }
    sqlx::query(
        r#"
        UPDATE site.product_embed
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE site_iid = $1 AND product_id = $2 AND embed_id = ANY($3) AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .bind(embed_ids)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

async fn product_embed_reconcile_tx(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    site_iid: i64,
    product_id: i64,
    keep_embed_ids: &HashSet<i64>,
) -> Result<()> {
    let rows = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT embed_id FROM site.product_embed
        WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .fetch_all(&mut **tx)
    .await?;
    let to_delete: Vec<i64> = rows.into_iter().filter(|id| !keep_embed_ids.contains(id)).collect();
    product_embed_soft_delete_tx(tx, site_iid, product_id, &to_delete).await?;
    Ok(())
}

pub async fn site_product_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteProductList,
) -> Result<ResSiteProductList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let rows = sqlx::query(
        r#"
        SELECT site_iid, product_id, type, name, "desc", unit, sku, rev,
               can_sell, can_reserve, track_stock, stock_qty, price, pic, category,
               product_json, is_archived, sort_order, created_ts, updated_ts, deleted_ts
        FROM site.product
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY sort_order, product_id
        "#,
    )
    .bind(req.site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSiteProductList {
        products: rows.iter().map(product_from_row).collect(),
    })
}

pub async fn site_product_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteProductPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteProductPut> {
    let product = req
        .product
        .ok_or_else(|| anyhow!("product required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let product_id = if product.product_id > 0 {
        product.product_id
    } else {
        snowflake_id()
    };
    let product_json_raw: serde_json::Value = if product.product_json.is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&product.product_json).unwrap_or(serde_json::json!({}))
    };
    let had_embeds_key = product_json_raw.get("_embeds").is_some();
    let embeds = product_json_raw
        .get("_embeds")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    let embeds_deleted = embed_ids_from_json(
        product_json_raw
            .get("_embeds_deleted")
            .unwrap_or(&serde_json::Value::Null),
    );
    let product_json = {
        let stored = product_json_raw.clone();
        if let Some(obj) = stored.as_object() {
            let mut map = obj.clone();
            map.remove("_embeds");
            map.remove("_embeds_deleted");
            serde_json::Value::Object(map)
        } else {
            product_json_raw.clone()
        }
    };
    let search_text = format!("{} {} {}", product.name, product.sku, product.desc);
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.product (
            site_iid, product_id, owner_iid, type, name, "desc", unit, sku, rev,
            can_sell, can_reserve, track_stock, stock_qty, price, pic, category,
            product_json, search_text, sort_order, is_archived, created_ts, updated_ts
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9,
            $10, $11, $12, $13, $14, $15, $16,
            $17, $18, $19, $20, NOW(), NOW()
        )
        ON CONFLICT (site_iid, product_id) DO UPDATE SET
          type = EXCLUDED.type, name = EXCLUDED.name, "desc" = EXCLUDED.desc,
          unit = EXCLUDED.unit, sku = EXCLUDED.sku, rev = EXCLUDED.rev,
          can_sell = EXCLUDED.can_sell, can_reserve = EXCLUDED.can_reserve,
          track_stock = EXCLUDED.track_stock, stock_qty = EXCLUDED.stock_qty,
          price = EXCLUDED.price, pic = EXCLUDED.pic, category = EXCLUDED.category,
          product_json = EXCLUDED.product_json, search_text = EXCLUDED.search_text,
          sort_order = EXCLUDED.sort_order, is_archived = EXCLUDED.is_archived,
          updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .bind(owner_iid)
    .bind(product.r#type)
    .bind(&product.name)
    .bind(&product.desc)
    .bind(&product.unit)
    .bind(&product.sku)
    .bind(product.rev)
    .bind(product.can_sell)
    .bind(product.can_reserve)
    .bind(product.track_stock)
    .bind(product.stock_qty)
    .bind(product.price)
    .bind(&product.pic)
    .bind(&product.category)
    .bind(product_json)
    .bind(search_text)
    .bind(product.sort_order)
    .bind(product.is_archived)
    .execute(&mut *tx)
    .await?;
    for embed in &embeds {
        let embed_id = embed
            .get("embed_id")
            .and_then(|v| v.as_i64())
            .filter(|i| *i > 0)
            .unwrap_or_else(snowflake_id);
        let label = embed.get("label").and_then(|v| v.as_str()).unwrap_or("").trim();
        sqlx::query(
            r#"
            INSERT INTO site.product_embed (site_iid, embed_id, product_id, label, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, NOW(), NOW())
            ON CONFLICT (site_iid, embed_id) DO UPDATE SET
                product_id = EXCLUDED.product_id,
                label = EXCLUDED.label,
                updated_ts = NOW(),
                deleted_ts = NULL
            "#,
        )
        .bind(site_iid)
        .bind(embed_id)
        .bind(product_id)
        .bind(label)
        .execute(&mut *tx)
        .await?;
    }
    if !embeds_deleted.is_empty() {
        product_embed_soft_delete_tx(&mut tx, site_iid, product_id, &embeds_deleted).await?;
    }
    if had_embeds_key {
        let keep: HashSet<i64> = embeds
            .iter()
            .filter_map(|e| e.get("embed_id").and_then(|v| v.as_i64()).filter(|i| *i > 0))
            .collect();
        product_embed_reconcile_tx(&mut tx, site_iid, product_id, &keep).await?;
    }
    tx.commit().await?;
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteProduct(SiteProduct {
                site_iid,
                product_id,
                ..product
            }),
        );
    }
    Ok(ResSiteProductPut { product_id })
}

pub async fn site_product_delete(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteProductDelete,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteProductDelete> {
    let site_iid = req.site_iid;
    let product_id = req.product_id;
    if site_iid <= 0 || product_id <= 0 {
        return Err(anyhow!("site_iid and product_id required"));
    }
    let _owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let row = sqlx::query(
        r#"
        UPDATE site.product
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL
        RETURNING site_iid, product_id, type, name, "desc", unit, sku, rev,
                  can_sell, can_reserve, track_stock, stock_qty, price, pic, category,
                  product_json, is_archived, sort_order, created_ts, updated_ts, deleted_ts
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("product {product_id} not found or already deleted"))?;
    let deleted = product_from_row(&row);
    if let Some(tx) = out_tx {
        site_sync_push(tx, sync_push::Body::SiteProduct(deleted));
    }
    Ok(ResSiteProductDelete { product_id, ok: true })
}

pub async fn site_product_reorder(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteProductReorder,
) -> Result<ResSiteProductReorder> {
    let site_iid = req.site_iid;
    if site_iid <= 0 {
        return Err(anyhow!("site_iid required"));
    }
    let _owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    if req.entries.is_empty() {
        return Ok(ResSiteProductReorder { ok: true });
    }
    let mut tx = pool.begin().await?;
    for entry in &req.entries {
        if entry.product_id <= 0 {
            continue;
        }
        let updated = sqlx::query(
            r#"
            UPDATE site.product
            SET sort_order = $1, updated_ts = NOW()
            WHERE site_iid = $2 AND product_id = $3 AND deleted_ts IS NULL
            "#,
        )
        .bind(entry.sort_order)
        .bind(site_iid)
        .bind(entry.product_id)
        .execute(&mut *tx)
        .await?;
        if updated.rows_affected() == 0 {
            return Err(anyhow!("product {} not found", entry.product_id));
        }
    }
    tx.commit().await?;
    Ok(ResSiteProductReorder { ok: true })
}
