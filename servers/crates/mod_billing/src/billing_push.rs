use c35_nats::{
    user_app_subject_balance, user_app_subject_commission, user_app_subject_quota,
};
use c35_proto::{BillingPushBalance, BillingPushCommission, BillingPushQuota, WsRes, ws_res};
use prost::Message;
use sqlx::{PgPool, Row};

pub async fn billing_notify_owner(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    out_tx: Option<&tokio::sync::mpsc::UnboundedSender<WsRes>>,
) {
    let row = sqlx::query(
        r#"
        SELECT id, balance_usd::float8 AS balance_usd, balance_idr::float8 AS balance_idr,
               billing_currency,
               commission_available_usd::float8 AS commission_available_usd,
               commission_earned_usd::float8 AS commission_earned_usd,
               commission_available_idr::float8 AS commission_available_idr,
               commission_earned_idr::float8 AS commission_earned_idr,
               updated_ts
        FROM ai.billing_account
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    let Some(row) = row else { return };

    let freemium = crate::billing_freemium::billing_freemium_wire(pool, owner_iid).await;
    let profile_row = sqlx::query(
        r#"
        SELECT trial_expires_ts, plan_expires_ts,
               COALESCE(alien_allow_5h_used::float8, 0.0) AS alien_allow_5h_used,
               COALESCE(alien_allow_5h_limit::float8, 0.0) AS alien_allow_5h_limit,
               COALESCE(alien_allow_weekly_used::float8, 0.0) AS alien_allow_weekly_used,
               COALESCE(alien_allow_weekly_limit::float8, 0.0) AS alien_allow_weekly_limit,
               COALESCE(frontier_allow_5h_used::float8, 0.0) AS frontier_allow_5h_used,
               COALESCE(frontier_allow_5h_limit::float8, 0.0) AS frontier_allow_5h_limit,
               COALESCE(frontier_allow_weekly_used::float8, 0.0) AS frontier_allow_weekly_used,
               COALESCE(frontier_allow_weekly_limit::float8, 0.0) AS frontier_allow_weekly_limit,
               window_5h_start, window_weekly_start,
               pool_period_start
        FROM ai.billing_profile
        WHERE owner_iid = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    let account_id: i64 = row.get("id");
    let updated: chrono::DateTime<chrono::Utc> = row.get("updated_ts");
    let w5 = profile_row
        .as_ref()
        .map(|r| r.get::<chrono::DateTime<chrono::Utc>, _>("window_5h_start"))
        .unwrap_or_else(|| updated);
    let ww = profile_row
        .as_ref()
        .map(|r| r.get::<chrono::DateTime<chrono::Utc>, _>("window_weekly_start"))
        .unwrap_or_else(|| updated);

    let currency: String = row.get("billing_currency");
    let balance_usd: f64 = row.get("balance_usd");
    let balance_idr: f64 = row.get("balance_idr");
    let primary_balance = if currency.eq_ignore_ascii_case("IDR") { balance_idr } else { balance_usd };
    let balance = BillingPushBalance {
        billing_account_id: account_id,
        balance_usd,
        balance_idr,
        updated_ts_ms: updated.timestamp_millis(),
        wallet_id: account_id,
        currency: currency.clone(),
        balance: primary_balance,
    };
    let quota = BillingPushQuota {
        alien_allow_5h_used: profile_row.as_ref().map(|r| r.get("alien_allow_5h_used")).unwrap_or(0.0),
        alien_allow_5h_limit: profile_row.as_ref().map(|r| r.get("alien_allow_5h_limit")).unwrap_or(0.0),
        alien_allow_weekly_used: profile_row.as_ref().map(|r| r.get("alien_allow_weekly_used")).unwrap_or(0.0),
        alien_allow_weekly_limit: profile_row.as_ref().map(|r| r.get("alien_allow_weekly_limit")).unwrap_or(0.0),
        window_5h_start_ms: w5.timestamp_millis(),
        window_weekly_start_ms: ww.timestamp_millis(),
        alien_pool_limit_idr: 0.0,
        alien_pool_used_idr: 0.0,
        frontier_pool_limit_idr: 0.0,
        frontier_pool_used_idr: 0.0,
        pool_period_start_ms: profile_row.as_ref().and_then(|r| r.get::<Option<chrono::DateTime<chrono::Utc>>, _>("pool_period_start")).map(|t| t.timestamp_millis()).unwrap_or(0),
        trial_expires_ts_ms: profile_row.as_ref().and_then(|r| r.get::<Option<chrono::DateTime<chrono::Utc>>, _>("trial_expires_ts")).map(|t| t.timestamp_millis()).unwrap_or(0),
        freemium_active: freemium.active,
        freemium_msgs_used: freemium.msgs_used,
        freemium_msgs_limit: freemium.msgs_limit,
        freemium_tokens_used: freemium.tokens_used,
        freemium_tokens_limit: freemium.tokens_limit,
        plan_expires_ts_ms: profile_row.as_ref().and_then(|r| r.get::<Option<chrono::DateTime<chrono::Utc>>, _>("plan_expires_ts")).map(|t| t.timestamp_millis()).unwrap_or(0),
        frontier_allow_5h_used: profile_row.as_ref().map(|r| r.get("frontier_allow_5h_used")).unwrap_or(0.0),
        frontier_allow_5h_limit: profile_row.as_ref().map(|r| r.get("frontier_allow_5h_limit")).unwrap_or(0.0),
        frontier_allow_weekly_used: profile_row.as_ref().map(|r| r.get("frontier_allow_weekly_used")).unwrap_or(0.0),
        frontier_allow_weekly_limit: profile_row.as_ref().map(|r| r.get("frontier_allow_weekly_limit")).unwrap_or(0.0),
    };
    let commission = BillingPushCommission {
        commission_available_usd: row.get("commission_available_usd"),
        commission_earned_usd: row.get("commission_earned_usd"),
        commission_available_idr: row.get("commission_available_idr"),
        commission_earned_idr: row.get("commission_earned_idr"),
    };

    if let Some(nats) = nats {
        let _ = nats
            .publish(
                user_app_subject_balance(owner_iid),
                balance.encode_to_vec().into(),
            )
            .await;
        let _ = nats
            .publish(
                user_app_subject_quota(owner_iid),
                quota.encode_to_vec().into(),
            )
            .await;
        let _ = nats
            .publish(
                user_app_subject_commission(owner_iid),
                commission.encode_to_vec().into(),
            )
            .await;
    }

    if let Some(out_tx) = out_tx {
        let _ = out_tx.send(WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::BillingBalance(balance.clone())),
        });
        let _ = out_tx.send(WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::BillingQuota(quota.clone())),
        });
        let _ = out_tx.send(WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::BillingCommission(commission.clone())),
        });
    }
}
