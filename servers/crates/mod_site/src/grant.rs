use anyhow::{anyhow, Result};
use sqlx::{PgPool, Row};

/// Role rank for site ACL: owner > manage > staff.
pub fn site_role_rank(role: &str) -> i32 {
    match role {
        "owner" => 3,
        "manage" => 2,
        "staff" => 1,
        _ => 0,
    }
}

pub fn site_role_allows(role: &str, write: bool) -> bool {
    if write {
        site_role_rank(role) >= site_role_rank("manage")
    } else {
        site_role_rank(role) >= site_role_rank("staff")
    }
}

/// Returns owner_iid when caller may access site_iid.
pub async fn site_grant_check(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    write: bool,
) -> Result<i64> {
    let row = sqlx::query(
        r#"
        SELECT i.owner_iid, g.role
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.kind = 'site' AND i.deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;
    let owner_iid: i64 = row.get("owner_iid");
    if owner_iid == caller_iid {
        return Ok(owner_iid);
    }
    let role: Option<String> = row.try_get("role").ok().flatten();
    let role = role.as_deref().unwrap_or("");
    if site_role_allows(role, write) {
        return Ok(owner_iid);
    }
    Err(anyhow!("forbidden"))
}

/// Site iids the caller owns or holds a non-deleted grant on, excluding archived grants.
pub async fn site_granted_iids(pool: &PgPool, caller_iid: i64) -> Result<Vec<i64>> {
    let rows = sqlx::query(
        r#"
        SELECT i.id
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL
          AND (i.owner_iid = $1 OR g.grantee_iid IS NOT NULL)
          AND (g.grantee_iid IS NULL OR g.meta IS NULL OR COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0)
        ORDER BY i.id
        "#,
    )
    .bind(caller_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows.iter().map(|r| r.get("id")).collect())
}
