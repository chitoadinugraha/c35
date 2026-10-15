use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteGuestMemberMerge, ReqSiteGuestOrderList, ResSiteGuestMemberMerge, ResSiteGuestOrderList,
    SiteGuestOrderSummary,
};
use sqlx::{PgPool, Row};

use crate::guest_order::guest_site_owner;
use crate::guest_tx_meta::{guest_tx_buyer_user_iid, guest_tx_meta_merge, guest_tx_visitor_id};

pub async fn guest_order_list(
    pool: &PgPool,
    req: ReqSiteGuestOrderList,
    buyer_user_iid: i64,
) -> Result<ResSiteGuestOrderList> {
    let site_iid = req.site_iid;
    if site_iid <= 0 || buyer_user_iid <= 0 {
        return Err(anyhow!("site_iid and auth required"));
    }
    let _ = guest_site_owner(pool, site_iid).await?;
    let rows = sqlx::query(
        r#"
        SELECT tx_id, state, total, time_ts, tx_data_json
        FROM site.tx
        WHERE site_iid = $1 AND deleted_ts IS NULL AND input_source = 'web'
          AND (tx_data_json->'guest'->>'buyer_user_iid')::bigint = $2
        ORDER BY time_ts DESC
        LIMIT 50
        "#,
    )
    .bind(site_iid)
    .bind(buyer_user_iid)
    .fetch_all(pool)
    .await?;

    let orders = rows
        .iter()
        .map(|r| {
            let state: String = r.get("state");
            SiteGuestOrderSummary {
                tx_id: r.get("tx_id"),
                state: state.clone(),
                total: r.get("total"),
                time_ts_ms: r
                    .get::<chrono::DateTime<chrono::Utc>, _>("time_ts")
                    .timestamp_millis(),
                progress_label: guest_progress_label(&state),
            }
        })
        .collect();

    Ok(ResSiteGuestOrderList { orders })
}

pub async fn guest_member_merge(
    pool: &PgPool,
    req: ReqSiteGuestMemberMerge,
    buyer_user_iid: i64,
) -> Result<ResSiteGuestMemberMerge> {
    let site_iid = req.site_iid;
    if site_iid <= 0 || buyer_user_iid <= 0 {
        return Err(anyhow!("site_iid and auth required"));
    }
    let _ = guest_site_owner(pool, site_iid).await?;
    let visitor = req.visitor_id.trim();
    let mut merged = 0i32;
    for tx_id in &req.order_ids {
        if *tx_id <= 0 {
            continue;
        }
        let row = sqlx::query(
            r#"SELECT tx_data_json, input_source FROM site.tx WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL"#,
        )
        .bind(site_iid)
        .bind(*tx_id)
        .fetch_optional(pool)
        .await?;
        let Some(row) = row else { continue };
        let src: String = row.get("input_source");
        if src != "web" {
            continue;
        }
        let data: serde_json::Value = row.get("tx_data_json");
        let existing_buyer = guest_tx_buyer_user_iid(&data);
        if existing_buyer > 0 && existing_buyer != buyer_user_iid {
            continue;
        }
        let tx_visitor = guest_tx_visitor_id(&data);
        if !visitor.is_empty() && !tx_visitor.is_empty() && tx_visitor != visitor {
            continue;
        }
        let merged_json = guest_tx_meta_merge(&data, buyer_user_iid, visitor);
        let n = sqlx::query(
            r#"UPDATE site.tx SET tx_data_json = $3::jsonb, updated_ts = NOW()
               WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL"#,
        )
        .bind(site_iid)
        .bind(*tx_id)
        .bind(merged_json)
        .execute(pool)
        .await?
        .rows_affected();
        if n > 0 {
            merged += 1;
        }
    }
    Ok(ResSiteGuestMemberMerge { merged_count: merged })
}

fn guest_progress_label(state: &str) -> String {
    match state {
        "waiting_payment" => "Menunggu pembayaran".into(),
        "pending" => "Diproses".into(),
        "ok" => "Selesai".into(),
        "cancelled" => "Dibatalkan".into(),
        _ => "Diproses".into(),
    }
}

pub async fn guest_order_get_allowed(
    pool: &PgPool,
    site_iid: i64,
    tx_id: i64,
    buyer_user_iid: Option<i64>,
    visitor_id: Option<&str>,
) -> Result<bool> {
    let row = sqlx::query(
        r#"SELECT input_source, tx_data_json FROM site.tx WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .bind(tx_id)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(false);
    };
    let src: String = row.get("input_source");
    if src != "web" {
        return Ok(false);
    }
    let data: serde_json::Value = row.get("tx_data_json");
    let buyer = guest_tx_buyer_user_iid(&data);
    if buyer > 0 {
        return Ok(buyer_user_iid == Some(buyer));
    }
    let vid = guest_tx_visitor_id(&data);
    if vid.is_empty() {
        return Ok(true);
    }
    Ok(visitor_id.map(|v| v.trim() == vid).unwrap_or(false))
}
