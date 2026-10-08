use anyhow::{bail, Result};
use c35_proto::{ReqSiteHandlePut, ResSiteHandlePut};
use sqlx::{PgPool, Row};

use crate::grant::site_grant_check;
use crate::platform_site::platform_site_handle_assign_check;
use crate::slug::{site_slug_ensure_unique, site_slug_generate};

const HANDLE_MIN_LEN: usize = 3;
const HANDLE_MAX_LEN: usize = 48;

pub fn site_handle_normalize(raw: &str) -> Result<String> {
    let clean = site_slug_generate(raw.trim());
    if clean.len() < HANDLE_MIN_LEN {
        bail!("handle must be at least {HANDLE_MIN_LEN} characters");
    }
    if clean.len() > HANDLE_MAX_LEN {
        bail!("handle must be at most {HANDLE_MAX_LEN} characters");
    }
    if clean.chars().all(|c| c.is_ascii_digit()) {
        bail!("handle cannot be only numbers; pick a memorable name");
    }
    if !clean
        .chars()
        .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-' || c == '_')
    {
        bail!("invalid handle characters");
    }
    Ok(clean)
}

async fn handle_conflicts_with_site_id(pool: &PgPool, handle: &str, site_iid: i64) -> Result<()> {
    if let Ok(num) = handle.parse::<i64>() {
        if num == site_iid {
            bail!("choose a memorable handle, not your site ID number");
        }
        let row = sqlx::query(
            r#"SELECT 1 FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL"#,
        )
        .bind(num)
        .fetch_optional(pool)
        .await?;
        if row.is_some() {
            bail!("handle '{handle}' conflicts with another site's ID");
        }
    }
    Ok(())
}

pub async fn site_handle_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteHandlePut,
) -> Result<ResSiteHandlePut> {
    let site_iid = req.site_iid;
    if site_iid <= 0 {
        bail!("site_iid required");
    }
    let _ = site_grant_check(pool, caller_iid, site_iid, false).await?;
    let clean = site_handle_normalize(&req.new_alien_id)?;
    let current_row = sqlx::query(
        "SELECT alien_id FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let current_alien = current_row
        .and_then(|r| r.try_get::<Option<String>, _>("alien_id").ok().flatten())
        .unwrap_or_default();
    platform_site_handle_assign_check(&current_alien, &clean)?;
    handle_conflicts_with_site_id(pool, &clean, site_iid).await?;
    let unique_slug = site_slug_ensure_unique(pool, &clean, Some(site_iid)).await?;
    if unique_slug != clean {
        bail!(
            "Handle '@{clean}' is already taken. Try '@{unique_slug}' or another name."
        );
    }

    let mut tx = pool.begin().await?;
    sqlx::query("UPDATE ai.identity SET alien_id = $1, updated_ts = NOW() WHERE id = $2")
        .bind(&unique_slug)
        .bind(site_iid)
        .execute(&mut *tx)
        .await?;

    sqlx::query(
        "UPDATE site.config SET alien_id_changed_ts = NOW(), updated_ts = NOW() WHERE site_iid = $1",
    )
    .bind(site_iid)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    let _ = c35_mod_hint::hint_invalidate_for_asset(pool, site_iid).await;
    let _ = c35_mod_hint::mention_invalidate_for_asset(pool, site_iid).await;

    Ok(ResSiteHandlePut {
        site_iid,
        alien_id: unique_slug.clone(),
        url: format!("alienai.id/{unique_slug}"),
    })
}
