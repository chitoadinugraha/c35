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
               alien_allow_5h_used::float8 AS alien_allow_5h_used,
               alien_allow_5h_limit::float8 AS alien_allow_5h_limit,
               alien_allow_weekly_used::float8 AS alien_allow_weekly_used,
               alien_allow_weekly_limit::float8 AS alien_allow_weekly_limit,
               commission_available_usd::float8 AS commission_available_usd,
               commission_earned_usd::float8 AS commission_earned_usd,
               commission_available_idr::float8 AS commission_available_idr,
               commission_earned_idr::float8 AS commission_earned_idr,
               window_5h_start, window_weekly_start, updated_ts
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

    let account_id: i64 = row.get("id");
    let updated: chrono::DateTime<chrono::Utc> = row.get("updated_ts");
    let w5: chrono::DateTime<chrono::Utc> = row.get("window_5h_start");
    let ww: chrono::DateTime<chrono::Utc> = row.get("window_weekly_start");

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
        alien_allow_5h_used: row.get("alien_allow_5h_used"),
        alien_allow_5h_limit: row.get("alien_allow_5h_limit"),
        alien_allow_weekly_used: row.get("alien_allow_weekly_used"),
        alien_allow_weekly_limit: row.get("alien_allow_weekly_limit"),
        window_5h_start_ms: w5.timestamp_millis(),
        window_weekly_start_ms: ww.timestamp_millis(),
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
                format!("c35.user.{owner_iid}.balance"),
                balance.encode_to_vec().into(),
            )
            .await;
        let _ = nats
            .publish(
                format!("c35.user.{owner_iid}.quota"),
                quota.encode_to_vec().into(),
            )
            .await;
        let _ = nats
            .publish(
                format!("c35.user.{owner_iid}.commission"),
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
