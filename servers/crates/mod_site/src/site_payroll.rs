//! Optional payroll compensation rows (rates). Pay runs deferred.

use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSitePayrollCompensationList, ReqSitePayrollCompensationPut, ResSitePayrollCompensationList,
    ResSitePayrollCompensationPut, SitePayrollCompensation,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;
use crate::site_config::{site_capabilities_get, site_capability_enabled};

pub async fn site_payroll_compensation_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePayrollCompensationList,
) -> Result<ResSitePayrollCompensationList> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, true).await?;
    require_attendance_cap(pool, site_iid).await?;
    let rows = sqlx::query(
        r#"
        SELECT comp_id, site_iid, grantee_iid, pay_basis, amount, shift_id,
               effective_from::text, label, is_active
        FROM site.payroll_compensation
        WHERE site_iid = $1 AND deleted_ts IS NULL
        ORDER BY grantee_iid, effective_from DESC
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    Ok(ResSitePayrollCompensationList {
        items: rows.iter().map(comp_from_row).collect(),
    })
}

pub async fn site_payroll_compensation_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSitePayrollCompensationPut,
) -> Result<ResSitePayrollCompensationPut> {
    let site_iid = req.site_iid;
    let _ = site_grant_check(pool, caller_iid, site_iid, true).await?;
    require_attendance_cap(pool, site_iid).await?;
    let item = req.item.ok_or_else(|| anyhow!("item required"))?;
    if item.grantee_iid <= 0 {
        return Err(anyhow!("grantee_iid required"));
    }
    let basis = item.pay_basis.trim().to_ascii_lowercase();
    if basis != "monthly" && basis != "hourly" {
        return Err(anyhow!("pay_basis must be monthly or hourly"));
    }
    let comp_id = if item.comp_id > 0 { item.comp_id } else { snowflake_id() };
    let effective = if item.effective_from.trim().is_empty() {
        chrono::Utc::now().date_naive().to_string()
    } else {
        item.effective_from.trim().to_string()
    };
    sqlx::query(
        r#"
        INSERT INTO site.payroll_compensation (
            comp_id, site_iid, grantee_iid, pay_basis, amount, shift_id,
            effective_from, label, is_active, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7::date, $8, $9, NOW(), NOW())
        ON CONFLICT (comp_id) DO UPDATE SET
            grantee_iid = EXCLUDED.grantee_iid,
            pay_basis = EXCLUDED.pay_basis,
            amount = EXCLUDED.amount,
            shift_id = EXCLUDED.shift_id,
            effective_from = EXCLUDED.effective_from,
            label = EXCLUDED.label,
            is_active = EXCLUDED.is_active,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(comp_id)
    .bind(site_iid)
    .bind(item.grantee_iid)
    .bind(&basis)
    .bind(item.amount)
    .bind(item.shift_id.trim())
    .bind(&effective)
    .bind(item.label.trim())
    .bind(item.is_active)
    .execute(pool)
    .await?;
    Ok(ResSitePayrollCompensationPut { comp_id })
}

async fn require_attendance_cap(pool: &PgPool, site_iid: i64) -> Result<()> {
    let caps = site_capabilities_get(pool, site_iid).await;
    if site_capability_enabled(&caps, "attendance") {
        Ok(())
    } else {
        Err(anyhow!("attendance not enabled for site"))
    }
}

fn comp_from_row(r: &sqlx::postgres::PgRow) -> SitePayrollCompensation {
    SitePayrollCompensation {
        comp_id: r.get("comp_id"),
        site_iid: r.get("site_iid"),
        grantee_iid: r.get("grantee_iid"),
        pay_basis: r.get("pay_basis"),
        amount: r.get("amount"),
        shift_id: r.try_get("shift_id").unwrap_or_default(),
        effective_from: r.try_get("effective_from").unwrap_or_default(),
        label: r.try_get("label").unwrap_or_default(),
        is_active: r.get("is_active"),
    }
}
