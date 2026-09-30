use c35_mod_billing::{
    billing_deduct_allowance, billing_reservation_refund, billing_reservation_settle,
};
use sqlx::PgPool;
use tracing::warn;

pub async fn task_run_log_rollup(pool: &PgPool, owner_iid: i64, run_id: i64) -> (i32, i32, f64) {
    let prefix = format!("task_run.{run_id}.%");
    let row = sqlx::query_as::<_, (Option<i64>, Option<i64>, Option<f64>)>(
        r#"
        SELECT COALESCE(SUM(tokens_in), 0)::bigint,
               COALESCE(SUM(tokens_out), 0)::bigint,
               COALESCE(SUM(cost_usd), 0)::float8
        FROM ai.log
        WHERE owner_iid = $1 AND req_id LIKE $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(prefix)
    .fetch_one(pool)
    .await
    .unwrap_or((Some(0), Some(0), Some(0.0)));
    (
        row.0.unwrap_or(0) as i32,
        row.1.unwrap_or(0) as i32,
        row.2.unwrap_or(0.0),
    )
}

pub async fn task_run_metrics_persist(
    pool: &PgPool,
    run_id: i64,
    owner_iid: i64,
    duration_ms: i64,
) -> (i32, i32, f64) {
    let (tokens_in, tokens_out, cost_usd) = task_run_log_rollup(pool, owner_iid, run_id).await;
    let _ = sqlx::query(
        r#"
        UPDATE ai.task_run
        SET tokens_in = $2, tokens_out = $3, cost_usd = $4, duration_ms = $5, updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(run_id)
    .bind(tokens_in)
    .bind(tokens_out)
    .bind(cost_usd)
    .bind(duration_ms)
    .execute(pool)
    .await;
    (tokens_in, tokens_out, cost_usd)
}

pub async fn task_run_billing_settle(pool: &PgPool, owner_iid: i64, req_id: &str, cost_usd: f64) {
    if req_id.trim().is_empty() {
        return;
    }
    if cost_usd <= 0.0 {
        if let Err(e) = billing_reservation_refund(pool, req_id).await {
            warn!(owner_iid, req_id, "task_run billing refund: {e}");
        }
        return;
    }
    let row_after = match billing_deduct_allowance(pool, owner_iid, cost_usd).await {
        Ok(r) => r,
        Err(e) => {
            warn!(owner_iid, req_id, "task_run billing deduct: {e}");
            return;
        }
    };
    let acct = sqlx::query_as::<_, (String, String, i64)>(
        "SELECT balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(row_after.id)
    .fetch_one(pool)
    .await;
    if let Ok(acct) = acct {
        let balance_idr = acct.0.parse().unwrap_or(0.0);
        if let Err(e) = billing_reservation_settle(
            pool,
            owner_iid,
            &row_after,
            req_id,
            cost_usd,
            balance_idr,
            &acct.1,
            acct.2,
        )
        .await
        {
            warn!(owner_iid, req_id, "task_run billing settle: {e}");
        }
    }
}
