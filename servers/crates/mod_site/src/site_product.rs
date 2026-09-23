use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteProductList, ReqSiteProductPut, ResSiteProductList, ResSiteProductPut, SiteProduct,
    sync_push,
};
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::product_from_row;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

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
               product_json, is_archived, created_ts, updated_ts, deleted_ts
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
    let product_json: serde_json::Value = if product.product_json.is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&product.product_json).unwrap_or(serde_json::json!({}))
    };
    let search_text = format!("{} {} {}", product.name, product.sku, product.desc);
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.product (
            site_iid, product_id, owner_iid, type, name, "desc", unit, sku, rev,
            can_sell, can_reserve, track_stock, stock_qty, price, pic, category,
            product_json, search_text, is_archived, created_ts, updated_ts
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9,
            $10, $11, $12, $13, $14, $15, $16,
            $17, $18, $19, NOW(), NOW()
        )
        ON CONFLICT (site_iid, product_id) DO UPDATE SET
          type = EXCLUDED.type, name = EXCLUDED.name, "desc" = EXCLUDED.desc,
          unit = EXCLUDED.unit, sku = EXCLUDED.sku, rev = EXCLUDED.rev,
          can_sell = EXCLUDED.can_sell, can_reserve = EXCLUDED.can_reserve,
          track_stock = EXCLUDED.track_stock, stock_qty = EXCLUDED.stock_qty,
          price = EXCLUDED.price, pic = EXCLUDED.pic, category = EXCLUDED.category,
          product_json = EXCLUDED.product_json, search_text = EXCLUDED.search_text,
          is_archived = EXCLUDED.is_archived, updated_ts = NOW(), deleted_ts = NULL
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
    .bind(product.is_archived)
    .execute(&mut *tx)
    .await?;
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
