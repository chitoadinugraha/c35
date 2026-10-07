use anyhow::{anyhow, bail, Result};
use c35_store::snowflake_id;
use sqlx::PgPool;

use crate::grant::site_grant_check;

pub fn site_grant_role_staff_manage(role: &str) -> Result<&'static str> {
    match role.trim().to_lowercase().as_str() {
        "staff" => Ok("staff"),
        "manage" => Ok("manage"),
        _ => Err(anyhow!("role must be staff or manage")),
    }
}

pub async fn site_grantee_resolve(pool: &PgPool, grantee_iid: i64, grantee_alien_id: &str) -> Result<i64> {
    if grantee_iid > 0 {
        return Ok(grantee_iid);
    }
    let handle = grantee_alien_id.trim().trim_start_matches('@').to_lowercase();
    if handle.is_empty() {
        bail!("grantee_iid or grantee_alien_id required");
    }
    let id: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.identity
        WHERE deleted_ts IS NULL AND kind = 'user'
          AND (lower(alien_id) = $1 OR CAST(id AS TEXT) = $1)
        LIMIT 1
        "#,
    )
    .bind(&handle)
    .fetch_optional(pool)
    .await?;
    id.ok_or_else(|| anyhow!("user not found: {handle}"))
}

async fn grantee_user_check(pool: &PgPool, grantee_iid: i64) -> Result<()> {
    let kind: Option<String> = sqlx::query_scalar(
        "SELECT kind FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(grantee_iid)
    .fetch_optional(pool)
    .await?;
    if kind.as_deref() != Some("user") {
        bail!("grantee must be a user");
    }
    Ok(())
}

async fn site_grant_invalidate(pool: &PgPool, site_iid: i64, grantee_iid: i64) -> Result<()> {
    let _ = c35_mod_hint::hint_invalidate_for_asset(pool, site_iid).await;
    let _ = c35_mod_hint::mention_invalidate_for_asset(pool, site_iid).await;
    let _ = c35_mod_hint::hint_invalidate(pool, grantee_iid).await;
    let _ = c35_mod_hint::mention_invalidate(pool, grantee_iid).await;
    Ok(())
}

pub async fn site_grant_put(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    grantee_iid: i64,
    role: &str,
) -> Result<()> {
    let role = site_grant_role_staff_manage(role)?;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    if grantee_iid == owner_iid {
        bail!("site owner already has full access");
    }
    if grantee_iid == site_iid {
        bail!("invalid grantee");
    }
    grantee_user_check(pool, grantee_iid).await?;

    let existing_role: Option<String> = sqlx::query_scalar(
        r#"
        SELECT role FROM ai.identity_grant
        WHERE resource_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_optional(pool)
    .await?;
    if existing_role.as_deref() == Some("owner") {
        bail!("cannot change owner grant");
    }

    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, permissions, is_pinned, meta, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, '{}', false, '{}', NOW(), NOW())
        ON CONFLICT (resource_iid, grantee_iid) DO UPDATE SET
            role = EXCLUDED.role,
            deleted_ts = NULL,
            updated_ts = NOW()
        "#,
    )
    .bind(snowflake_id())
    .bind(site_iid)
    .bind(grantee_iid)
    .bind(role)
    .execute(pool)
    .await?;

    site_grant_invalidate(pool, site_iid, grantee_iid).await?;
    Ok(())
}

pub async fn site_grant_delete(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    grantee_iid: i64,
) -> Result<()> {
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    if grantee_iid == owner_iid {
        bail!("cannot revoke site owner access");
    }
    if grantee_iid == site_iid {
        bail!("invalid grantee");
    }

    let res = sqlx::query(
        r#"
        UPDATE ai.identity_grant
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE resource_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL AND role <> 'owner'
        "#,
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .execute(pool)
    .await?;
    if res.rows_affected() == 0 {
        bail!("grant not found");
    }

    site_grant_invalidate(pool, site_iid, grantee_iid).await?;
    Ok(())
}
