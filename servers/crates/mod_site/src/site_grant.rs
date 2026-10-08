use anyhow::{anyhow, bail, Result};
use c35_proto::{
    ReqSiteGrantDelete, ReqSiteGrantList, ReqSiteGrantPut, ReqSiteTransferOwnership,
    ResSiteGrantDelete, ResSiteGrantList, ResSiteGrantPut, ResSiteTransferOwnership, SiteGrant,
};
use c35_store::snowflake_id;
use sqlx::PgPool;

use crate::grant::site_grant_check;
use crate::rows::grant_from_row;

/// Email for a grantee: primary identity_provider kind=email, else meta.email.
const SITE_GRANT_EMAIL_SQL: &str = r#"
COALESCE((
  SELECT p.identifier FROM ai.identity_provider p
  WHERE p.identity_iid = i.id AND p.kind = 'email' AND p.deleted_ts IS NULL
    AND btrim(p.identifier) <> ''
  ORDER BY p.is_primary DESC, p.updated_ts DESC
  LIMIT 1
), COALESCE(i.meta->>'email', ''))
"#;

/// Prepend synthetic owner when missing; mark existing owner grant as is_owner.
pub fn site_grant_list_ensure_owner(mut grants: Vec<SiteGrant>, owner: SiteGrant) -> Vec<SiteGrant> {
    if owner.grantee_iid <= 0 {
        return grants;
    }
    if let Some(g) = grants
        .iter_mut()
        .find(|g| g.grantee_iid == owner.grantee_iid || g.role == "owner")
    {
        g.is_owner = true;
        if g.role != "owner" {
            g.role = "owner".into();
        }
        return grants;
    }
    let mut out = Vec::with_capacity(grants.len() + 1);
    out.push(owner);
    out.append(&mut grants);
    out
}

/// Writable grant roles for site_grant_put: staff | manage | guest (not owner).
pub fn site_grant_role_writable(role: &str) -> Result<&'static str> {
    match role.trim().to_lowercase().as_str() {
        "staff" => Ok("staff"),
        "manage" => Ok("manage"),
        "guest" => Ok("guest"),
        _ => Err(anyhow!("role must be staff, manage, or guest")),
    }
}

/// Thin wrapper kept for older callers; same as [`site_grant_role_writable`].
pub fn site_grant_role_staff_manage(role: &str) -> Result<&'static str> {
    site_grant_role_writable(role)
}

/// Resolve grantee: iid > 0, else email (identity_provider / meta), else alien_id / numeric id.
pub async fn site_grantee_resolve(
    pool: &PgPool,
    grantee_iid: i64,
    grantee_alien_id: &str,
    grantee_email: &str,
) -> Result<i64> {
    if grantee_iid > 0 {
        return Ok(grantee_iid);
    }
    let email = grantee_email.trim().to_lowercase();
    if !email.is_empty() {
        let id: Option<i64> = sqlx::query_scalar(
            r#"
            SELECT identity_iid FROM ai.identity_provider
            WHERE kind = 'email' AND deleted_ts IS NULL AND LOWER(identifier) = $1
            LIMIT 1
            "#,
        )
        .bind(&email)
        .fetch_optional(pool)
        .await?;
        if let Some(id) = id {
            return Ok(id);
        }
        let id: Option<i64> = sqlx::query_scalar(
            r#"
            SELECT id FROM ai.identity
            WHERE deleted_ts IS NULL AND kind = 'user'
              AND LOWER(meta->>'email') = $1
            LIMIT 1
            "#,
        )
        .bind(&email)
        .fetch_optional(pool)
        .await?;
        return id.ok_or_else(|| anyhow!("user not found: {email}"));
    }
    let handle = grantee_alien_id.trim().trim_start_matches('@').to_lowercase();
    if handle.is_empty() {
        bail!("grantee_iid, grantee_alien_id, or grantee_email required");
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

async fn site_grant_owner_row(pool: &PgPool, site_iid: i64, owner_iid: i64) -> Result<Option<SiteGrant>> {
    if owner_iid <= 0 {
        return Ok(None);
    }
    let email_sql = SITE_GRANT_EMAIL_SQL;
    let sql = format!(
        r#"
        SELECT $1::bigint AS site_iid, i.id AS grantee_iid, 'owner'::text AS role,
               i.created_ts, i.updated_ts,
               COALESCE(i.alien_id, '') AS grantee_alien_id,
               COALESCE(i.name, '') AS grantee_name,
               {email_sql} AS grantee_email,
               COALESCE(i.pic, '') AS grantee_pic,
               COALESCE((
                 SELECT array_agg(ms.shift_id ORDER BY ms.shift_id)
                 FROM site.member_shift ms
                 WHERE ms.site_iid = $1 AND ms.grantee_iid = i.id
               ), ARRAY[]::text[]) AS work_shift_ids,
               TRUE AS is_owner
        FROM ai.identity i
        WHERE i.id = $2 AND i.deleted_ts IS NULL
        "#
    );
    let row = sqlx::query(&sql)
        .bind(site_iid)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await?;
    Ok(row.as_ref().map(grant_from_row))
}

pub async fn site_grant_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteGrantList,
) -> Result<ResSiteGrantList> {
    let owner_iid = site_grant_check(pool, caller_iid, req.site_iid, true).await?;
    let email_sql = SITE_GRANT_EMAIL_SQL;
    let sql = format!(
        r#"
        SELECT g.resource_iid AS site_iid, g.grantee_iid, g.role,
               g.created_ts, g.updated_ts,
               COALESCE(i.alien_id, '') AS grantee_alien_id,
               COALESCE(i.name, '') AS grantee_name,
               {email_sql} AS grantee_email,
               COALESCE(i.pic, '') AS grantee_pic,
               COALESCE((
                 SELECT array_agg(ms.shift_id ORDER BY ms.shift_id)
                 FROM site.member_shift ms
                 WHERE ms.site_iid = g.resource_iid AND ms.grantee_iid = g.grantee_iid
               ), ARRAY[]::text[]) AS work_shift_ids,
               (g.role = 'owner' OR g.grantee_iid = $2) AS is_owner
        FROM ai.identity_grant g
        JOIN ai.identity i ON i.id = g.grantee_iid AND i.deleted_ts IS NULL
        WHERE g.resource_iid = $1 AND g.deleted_ts IS NULL
          AND g.role IN ('staff', 'manage', 'guest', 'owner')
        ORDER BY g.updated_ts DESC, g.grantee_iid
        "#
    );
    let rows = sqlx::query(&sql)
        .bind(req.site_iid)
        .bind(owner_iid)
        .fetch_all(pool)
        .await?;
    let grants = rows.iter().map(grant_from_row).collect::<Vec<_>>();
    let owner = site_grant_owner_row(pool, req.site_iid, owner_iid)
        .await?
        .unwrap_or(SiteGrant {
            site_iid: req.site_iid,
            grantee_iid: owner_iid,
            role: "owner".into(),
            is_owner: true,
            ..Default::default()
        });
    Ok(ResSiteGrantList {
        grants: site_grant_list_ensure_owner(grants, owner),
    })
}

pub async fn site_grant_put_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteGrantPut,
) -> Result<ResSiteGrantPut> {
    let grantee_iid = site_grantee_resolve(
        pool,
        req.grantee_iid,
        &req.grantee_alien_id,
        &req.grantee_email,
    )
    .await?;
    // prost repeated is always present: every RPC put replaces member_shift (empty = clear).
    site_grant_put(
        pool,
        caller_iid,
        req.site_iid,
        grantee_iid,
        &req.role,
        Some(req.work_shift_ids.as_slice()),
    )
    .await?;
    Ok(ResSiteGrantPut {
        grantee_iid,
        ok: true,
    })
}

pub async fn site_grant_delete_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteGrantDelete,
) -> Result<ResSiteGrantDelete> {
    site_grant_delete(pool, caller_iid, req.site_iid, req.grantee_iid).await?;
    Ok(ResSiteGrantDelete {
        grantee_iid: req.grantee_iid,
        ok: true,
    })
}

/// Upsert grant. When `work_shift_ids` is `Some`, replace member_shift (empty slice clears).
/// Chat tool passes `None` unless args contain the `work_shift_ids` key; RPC always passes `Some`.
pub async fn site_grant_put(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    grantee_iid: i64,
    role: &str,
    work_shift_ids: Option<&[String]>,
) -> Result<()> {
    let role = site_grant_role_writable(role)?;
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

    // Validate shifts before mutating grant so unknown ids fail cleanly.
    if let Some(ids) = work_shift_ids {
        let normalized = crate::site_hr::site_member_shift_ids_normalize(ids);
        if !normalized.is_empty() {
            let found: i64 = sqlx::query_scalar(
                r#"
                SELECT COUNT(*)::bigint FROM site.work_shift
                WHERE site_iid = $1 AND deleted_ts IS NULL AND shift_id = ANY($2)
                "#,
            )
            .bind(site_iid)
            .bind(&normalized)
            .fetch_one(pool)
            .await?;
            if found != normalized.len() as i64 {
                bail!("unknown work_shift_id for site");
            }
        }
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

    if let Some(ids) = work_shift_ids {
        crate::site_hr::site_member_shift_sync(pool, site_iid, grantee_iid, ids).await?;
    }

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

    crate::site_hr::site_member_hr_cleanup(pool, site_iid, grantee_iid).await?;
    site_grant_invalidate(pool, site_iid, grantee_iid).await?;
    Ok(())
}

/// Transfer site ownership to an existing non-deleted grant member.
/// Caller must be current `ai.identity.owner_iid`. Previous owner → manage; target → owner.
pub async fn site_transfer_ownership(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    target_iid: i64,
) -> Result<()> {
    if site_iid <= 0 {
        bail!("site_iid required");
    }
    if target_iid <= 0 {
        bail!("target_iid required");
    }

    let owner_iid: Option<i64> = sqlx::query_scalar(
        "SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?;
    let owner_iid = owner_iid.ok_or_else(|| anyhow!("site not found"))?;
    if caller_iid != owner_iid {
        bail!("only site owner can transfer ownership");
    }
    if target_iid == owner_iid {
        bail!("target is already the owner");
    }
    grantee_user_check(pool, target_iid).await?;

    let target_role: Option<String> = sqlx::query_scalar(
        r#"
        SELECT role FROM ai.identity_grant
        WHERE resource_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL
          AND role IN ('staff', 'manage', 'guest', 'owner')
        "#,
    )
    .bind(site_iid)
    .bind(target_iid)
    .fetch_optional(pool)
    .await?;
    if target_role.is_none() {
        bail!("target must already be a site member");
    }

    let mut tx = pool.begin().await?;

    sqlx::query(
        "UPDATE ai.identity SET owner_iid = $1, updated_ts = NOW() WHERE id = $2 AND kind = 'site'",
    )
    .bind(target_iid)
    .bind(site_iid)
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        "UPDATE site.config SET owner_iid = $1, updated_ts = NOW() WHERE site_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(target_iid)
    .bind(site_iid)
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, permissions, is_pinned, meta, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'manage', '{}', false, '{}', NOW(), NOW())
        ON CONFLICT (resource_iid, grantee_iid) DO UPDATE SET
            role = 'manage',
            deleted_ts = NULL,
            updated_ts = NOW()
        "#,
    )
    .bind(snowflake_id())
    .bind(site_iid)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, permissions, is_pinned, meta, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'owner', '{}', false, '{}', NOW(), NOW())
        ON CONFLICT (resource_iid, grantee_iid) DO UPDATE SET
            role = 'owner',
            deleted_ts = NULL,
            updated_ts = NOW()
        "#,
    )
    .bind(snowflake_id())
    .bind(site_iid)
    .bind(target_iid)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    site_grant_invalidate(pool, site_iid, owner_iid).await?;
    site_grant_invalidate(pool, site_iid, target_iid).await?;
    Ok(())
}

pub async fn site_transfer_ownership_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteTransferOwnership,
) -> Result<ResSiteTransferOwnership> {
    site_transfer_ownership(pool, caller_iid, req.site_iid, req.target_iid).await?;
    Ok(ResSiteTransferOwnership {
        new_owner_iid: req.target_iid,
        ok: true,
    })
}
