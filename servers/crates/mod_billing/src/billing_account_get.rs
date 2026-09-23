use c35_ctx::Ctx;
use c35_proto::BillingAccount;
use c35_wire::{WireErr, WireResult};
use sqlx::Row;

pub async fn billing_account_get(ctx: &Ctx, billing_iid: i64) -> WireResult<BillingAccount> {
    let iid = if billing_iid != 0 {
        billing_iid
    } else {
        ctx.caller_iid
    };

    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, name,
               balance_usd::float8 AS balance_usd,
               balance_idr::float8 AS balance_idr,
               plan_tier,
               alien_allow_5h_used::float8 AS alien_allow_5h_used,
               alien_allow_5h_limit::float8 AS alien_allow_5h_limit,
               alien_allow_weekly_used::float8 AS alien_allow_weekly_used,
               alien_allow_weekly_limit::float8 AS alien_allow_weekly_limit,
               window_5h_start, window_weekly_start,
               billing_currency, fx_micro_per_usd,
               commission_available_usd::float8 AS commission_available_usd,
               commission_earned_usd::float8 AS commission_earned_usd,
               commission_available_idr::float8 AS commission_available_idr,
               commission_earned_idr::float8 AS commission_earned_idr,
               meta, created_ts, updated_ts
        FROM ai.billing_account
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(iid)
    .fetch_optional(&ctx.pool)
    .await
    .map_err(|e| WireErr::Internal(e.to_string()))?;

    let Some(row) = row else {
        return Ok(BillingAccount {
            id: iid,
            owner_iid: ctx.caller_iid,
            name: "Personal".into(),
            ..Default::default()
        });
    };

    let w5: chrono::DateTime<chrono::Utc> = row.get("window_5h_start");
    let ww: chrono::DateTime<chrono::Utc> = row.get("window_weekly_start");
    let created: chrono::DateTime<chrono::Utc> = row.get("created_ts");
    let updated: chrono::DateTime<chrono::Utc> = row.get("updated_ts");

    Ok(BillingAccount {
        id: row.get("id"),
        owner_iid: row.get("owner_iid"),
        name: row.get("name"),
        balance_usd: row.get("balance_usd"),
        balance_idr: row.get("balance_idr"),
        plan_tier: row.get("plan_tier"),
        alien_allow_5h_used: row.get("alien_allow_5h_used"),
        alien_allow_5h_limit: row.get("alien_allow_5h_limit"),
        alien_allow_weekly_used: row.get("alien_allow_weekly_used"),
        alien_allow_weekly_limit: row.get("alien_allow_weekly_limit"),
        window_5h_start_ms: w5.timestamp_millis(),
        window_weekly_start_ms: ww.timestamp_millis(),
        billing_currency: row.get("billing_currency"),
        fx_micro_per_usd: crate::fx_live::fx_live_micro_per_usd(),
        commission_available_usd: row.get("commission_available_usd"),
        commission_earned_usd: row.get("commission_earned_usd"),
        commission_available_idr: row.get("commission_available_idr"),
        commission_earned_idr: row.get("commission_earned_idr"),
        meta_json: row
            .try_get::<serde_json::Value, _>("meta")
            .ok()
            .map(|v| v.to_string())
            .unwrap_or_else(|| "{}".into()),
        created_ts_ms: created.timestamp_millis(),
        updated_ts_ms: updated.timestamp_millis(),
        ..Default::default()
    })
}
