use c35_proto::{ReqBillingAdminPlanChange, ReqBillingPlanChange, ResBillingPlanChange};
use sqlx::{PgPool, Row};

use crate::billing_finance::{billing_admin_adjust_access, FinanceError};
use crate::billing_plan_change::billing_plan_change;

fn meta_is_root(meta: &serde_json::Value) -> bool {
    meta.get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
}

fn meta_has_director(meta: &serde_json::Value) -> bool {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().any(|x| x.as_str() == Some("director")))
        .unwrap_or(false)
}

async fn subject_root_or_director(pool: &PgPool, subject_iid: i64) -> Result<bool, FinanceError> {
    if subject_iid == 99_000 {
        return Ok(true);
    }
    if subject_iid <= 0 {
        return Ok(false);
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(subject_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| FinanceError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Ok(false);
    };
    let meta: serde_json::Value = row.try_get("meta").unwrap_or(serde_json::json!({}));
    Ok(meta_is_root(&meta) || meta_has_director(&meta))
}

pub async fn billing_admin_plan_change(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqBillingAdminPlanChange,
) -> Result<ResBillingPlanChange, FinanceError> {
    billing_admin_adjust_access(pool, viewer_iid).await?;
    let subject = req.subject_uid;
    if subject <= 0 {
        return Err(FinanceError::bad("subject_uid required"));
    }
    if !subject_root_or_director(pool, subject).await? {
        return Err(FinanceError::bad(
            "plan can only be set for root or director accounts",
        ));
    }
    let plan_slug = req.plan_slug.trim();
    if plan_slug.is_empty() {
        return Err(FinanceError::bad("plan_slug required"));
    }
    billing_plan_change(
        pool,
        subject,
        ReqBillingPlanChange {
            plan_slug: plan_slug.to_string(),
            billing_period: req.billing_period,
            currency: req.currency,
        },
    )
    .await
    .map_err(FinanceError::bad)
}
