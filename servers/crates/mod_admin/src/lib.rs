use c35_proto::{
    AdminUserHit, ReqAdminUserPut, ReqAdminUserSearch, ResAdminUserPut, ResAdminUserSearch,
};
use std::collections::HashSet;

mod admin_event;
mod log_admin;
mod log_report;
mod ops_peaks;
mod platform_pnl;

pub use admin_event::{admin_event_profile_updated, admin_event_referrer_updated, admin_event_roles_updated};
pub use log_admin::admin_log_list;
pub use log_report::admin_log_report;
pub use ops_peaks::admin_ops_peaks;
pub use platform_pnl::admin_platform_pnl;
use sqlx::{PgPool, Row};

#[derive(Debug)]
pub struct AdminError {
    pub status_code: i32,
    pub message: String,
}

impl AdminError {
    pub fn bad(msg: impl Into<String>) -> Self {
        Self {
            status_code: 400,
            message: msg.into(),
        }
    }

    pub fn forbidden() -> Self {
        Self {
            status_code: 403,
            message: "forbidden".to_string(),
        }
    }
}

fn meta_is_root(meta: &serde_json::Value) -> bool {
    meta.get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
}

pub async fn require_root(pool: &PgPool, viewer_iid: i64) -> Result<(), AdminError> {
    if viewer_iid == 99_000 {
        return Ok(());
    }
    if viewer_iid <= 0 {
        return Err(AdminError::forbidden());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Err(AdminError::forbidden());
    };
    let meta: serde_json::Value = row.try_get("meta").unwrap_or(serde_json::json!({}));
    if meta_is_root(&meta) {
        Ok(())
    } else {
        Err(AdminError::forbidden())
    }
}

fn meta_global_roles(meta: &serde_json::Value) -> HashSet<String> {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default()
}

fn meta_is_partner(meta: &serde_json::Value) -> bool {
    meta_global_roles(meta).contains("partner")
}

fn meta_is_director(meta: &serde_json::Value) -> bool {
    meta_global_roles(meta).contains("director")
}

async fn viewer_meta(pool: &PgPool, viewer_iid: i64) -> Result<serde_json::Value, AdminError> {
    if viewer_iid == 99_000 {
        return Ok(serde_json::json!({ "is_root": true, "global_roles": ["root"] }));
    }
    if viewer_iid <= 0 {
        return Err(AdminError::forbidden());
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true")
        .bind(viewer_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Err(AdminError::forbidden());
    };
    Ok(row.try_get("meta").unwrap_or(serde_json::json!({})))
}

pub async fn referral_tree_wide_access(pool: &PgPool, viewer_iid: i64) -> bool {
    viewer_meta(pool, viewer_iid).await.is_ok_and(|meta| {
        meta_is_root(&meta) || meta_is_partner(&meta) || meta_is_director(&meta)
    })
}

pub async fn require_referral_staff(pool: &PgPool, viewer_iid: i64) -> Result<(), AdminError> {
    let meta = viewer_meta(pool, viewer_iid).await?;
    if meta_is_root(&meta) || meta_is_partner(&meta) || meta_is_director(&meta) {
        Ok(())
    } else {
        Err(AdminError::forbidden())
    }
}

pub async fn require_admin(pool: &PgPool, viewer_iid: i64) -> Result<(), AdminError> {
    require_referral_staff(pool, viewer_iid).await
}

async fn require_root_actor(pool: &PgPool, viewer_iid: i64) -> Result<(), AdminError> {
    require_root(pool, viewer_iid).await
}

async fn require_root_or_director(pool: &PgPool, viewer_iid: i64) -> Result<(), AdminError> {
    let meta = viewer_meta(pool, viewer_iid).await?;
    if meta_is_root(&meta) || meta_is_director(&meta) {
        Ok(())
    } else {
        Err(AdminError::forbidden())
    }
}

const STAFF_ASSIGNABLE_ROLES: &[&str] = &["partner", "marketing", "finance"];
const ROOT_EXTRA_ROLES: &[&str] = &["director"];

fn normalize_role_list(roles: &[String]) -> Vec<String> {
    let mut out: Vec<String> = roles
        .iter()
        .map(|r| r.trim().to_lowercase())
        .filter(|r| !r.is_empty() && r != "root")
        .collect();
    out.sort();
    out.dedup();
    out
}

fn director_may_assign(roles: &[String]) -> Result<Vec<String>, AdminError> {
    let norm = normalize_role_list(roles);
    for r in &norm {
        if !STAFF_ASSIGNABLE_ROLES.contains(&r.as_str()) {
            return Err(AdminError::bad(format!("director cannot assign role: {r}")));
        }
    }
    Ok(norm)
}

fn root_may_assign(roles: &[String]) -> Result<Vec<String>, AdminError> {
    let norm = normalize_role_list(roles);
    for r in &norm {
        if !STAFF_ASSIGNABLE_ROLES.contains(&r.as_str()) && !ROOT_EXTRA_ROLES.contains(&r.as_str()) {
            return Err(AdminError::bad(format!("invalid role: {r}")));
        }
    }
    Ok(norm)
}

fn normalize_alien_id(raw: &str) -> String {
    raw.trim().trim_start_matches('@').to_lowercase()
}

fn alien_id_valid(alien_id: &str) -> bool {
    !alien_id.is_empty()
        && alien_id
            .chars()
            .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '-')
}

pub async fn admin_user_search(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminUserSearch,
) -> Result<ResAdminUserSearch, AdminError> {
    require_admin(pool, viewer_iid).await?;
    let q = req.query.trim();
    if q.is_empty() {
        return Ok(ResAdminUserSearch { users: vec![] });
    }
    let limit = req.limit.clamp(1, 50);
    let pattern = format!("%{}%", q.to_lowercase());
    let rows = sqlx::query(
        r#"
        SELECT i.id, i.name, COALESCE(i.pic, '') AS pic, COALESCE(i.alien_id, '') AS alien_id,
               COALESCE((
                 SELECT p.identifier FROM ai.identity_provider p
                 WHERE p.identity_iid = i.id AND p.kind IN ('password', 'google')
                 ORDER BY p.is_primary DESC
                 LIMIT 1
               ), COALESCE(i.meta->>'email', '')) AS email
        FROM ai.identity i
        WHERE i.kind = 'user' AND i.deleted_ts IS NULL
          AND (
            lower(i.name) LIKE $1
            OR lower(i.alien_id) LIKE $1
            OR CAST(i.id AS TEXT) = $2
            OR EXISTS (
              SELECT 1 FROM ai.identity_provider p
              WHERE p.identity_iid = i.id AND lower(p.identifier) LIKE $1
            )
          )
        ORDER BY i.name
        LIMIT $3
        "#,
    )
    .bind(&pattern)
    .bind(q)
    .bind(limit)
    .fetch_all(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    let users = rows
        .into_iter()
        .map(|r| {
            let alien_id: String = r.get("alien_id");
            let handle = if alien_id.is_empty() {
                "@user".into()
            } else {
                format!("@{alien_id}")
            };
            AdminUserHit {
                identity_id: r.get("id"),
                name: r.get("name"),
                email: r.get("email"),
                avatar_url: r.get("pic"),
                handle,
            }
        })
        .collect();
    Ok(ResAdminUserSearch { users })
}

async fn identity_exists(pool: &PgPool, iid: i64) -> Result<bool, AdminError> {
    let row = sqlx::query("SELECT 1 FROM ai.identity WHERE id = $1 AND kind = 'user' AND deleted_ts IS NULL")
        .bind(iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(row.is_some())
}

async fn alien_id_taken(pool: &PgPool, alien_id: &str, exclude: i64) -> Result<bool, AdminError> {
    let row = sqlx::query(
        "SELECT id FROM ai.identity WHERE LOWER(alien_id) = LOWER($1) AND id != $2 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(alien_id)
    .bind(exclude)
    .fetch_optional(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(row.is_some())
}

async fn email_taken(pool: &PgPool, email: &str, exclude: i64) -> Result<bool, AdminError> {
    let row = sqlx::query(
        r#"
        SELECT identity_iid FROM ai.identity_provider
        WHERE LOWER(identifier) = LOWER($1) AND identity_iid != $2
        LIMIT 1
        "#,
    )
    .bind(email)
    .bind(exclude)
    .fetch_optional(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(row.is_some())
}

async fn is_root_user(pool: &PgPool, iid: i64) -> Result<bool, AdminError> {
    if iid == 99_000 {
        return Ok(true);
    }
    let row = sqlx::query("SELECT meta FROM ai.identity WHERE id = $1")
        .bind(iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let Some(row) = row else {
        return Ok(false);
    };
    let meta: serde_json::Value = row.try_get("meta").unwrap_or(serde_json::json!({}));
    Ok(meta_is_root(&meta))
}

async fn descendant_ids(pool: &PgPool, root_iid: i64) -> Result<HashSet<i64>, AdminError> {
    let rows = sqlx::query(
        r#"
        WITH RECURSIVE downline AS (
            SELECT id FROM ai.identity WHERE referred_by_iid = $1
            UNION ALL
            SELECT i.id FROM ai.identity i
            JOIN downline d ON i.referred_by_iid = d.id
        )
        SELECT id FROM downline
        "#,
    )
    .bind(root_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(rows.into_iter().map(|r| r.get::<i64, _>("id")).collect())
}

pub async fn admin_user_put(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    viewer_iid: i64,
    req: ReqAdminUserPut,
) -> Result<ResAdminUserPut, AdminError> {
    let target = req.target_identity_id;
    if target <= 0 {
        return Err(AdminError::bad("target required"));
    }
    if !identity_exists(pool, target).await? {
        return Err(AdminError::bad("user not found"));
    }

    let profile_change = req.name.is_some()
        || req.handle.is_some()
        || req.avatar_url.is_some()
        || req.auth_email.is_some();
    let referrer_change = req.referred_by_uid.is_some();
    let roles_change = req.global_roles.is_some();

    if profile_change {
        require_root_actor(pool, viewer_iid).await?;
    }
    if referrer_change || roles_change {
        require_root_or_director(pool, viewer_iid).await?;
    }
    if !profile_change && !referrer_change && !roles_change {
        return Err(AdminError::bad("no changes"));
    }

    let target_row = sqlx::query(
        "SELECT meta, COALESCE(referred_by_iid, 0) AS referred_by FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(target)
    .fetch_optional(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    let Some(target_row) = target_row else {
        return Err(AdminError::bad("user not found"));
    };
    let target_meta: serde_json::Value = target_row.try_get("meta").unwrap_or(serde_json::json!({}));
    let roles_before: Vec<String> = meta_global_roles(&target_meta).into_iter().collect();
    let referred_before: i64 = target_row.get("referred_by");
    let referred_before_opt = if referred_before > 0 {
        Some(referred_before)
    } else {
        None
    };

    let mut profile_fields: Vec<&str> = Vec::new();
    let mut tx = pool.begin().await.map_err(|e| AdminError::bad(e.to_string()))?;

    if let Some(name) = req.name.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        sqlx::query("UPDATE ai.identity SET name = $2, updated_ts = NOW() WHERE id = $1")
            .bind(target)
            .bind(name)
            .execute(&mut *tx)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?;
        profile_fields.push("name");
    }

    if let Some(raw) = req.handle.as_ref() {
        let alien_id = normalize_alien_id(raw);
        if !alien_id_valid(&alien_id) {
            return Err(AdminError::bad("invalid handle"));
        }
        if alien_id_taken(pool, &alien_id, target).await? {
            return Err(AdminError::bad("handle taken"));
        }
        sqlx::query("UPDATE ai.identity SET alien_id = $2, updated_ts = NOW() WHERE id = $1")
            .bind(target)
            .bind(&alien_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?;
        profile_fields.push("handle");
    }

    if let Some(url) = req.avatar_url.as_ref() {
        sqlx::query("UPDATE ai.identity SET pic = $2, updated_ts = NOW() WHERE id = $1")
            .bind(target)
            .bind(url.trim())
            .execute(&mut *tx)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?;
        profile_fields.push("avatar");
    }

    if let Some(email) = req
        .auth_email
        .as_ref()
        .map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty())
    {
        if email_taken(pool, &email, target).await? {
            return Err(AdminError::bad("email taken"));
        }
        let updated = sqlx::query(
            r#"
            UPDATE ai.identity_provider
            SET identifier = $2, updated_ts = NOW()
            WHERE identity_iid = $1 AND kind IN ('password', 'google')
            "#,
        )
        .bind(target)
        .bind(&email)
        .execute(&mut *tx)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
        if updated.rows_affected() == 0 {
            return Err(AdminError::bad("no password/google provider to update"));
        }
        sqlx::query(
            r#"UPDATE ai.identity SET meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{email}', to_jsonb($2::text)), updated_ts = NOW() WHERE id = $1"#,
        )
        .bind(target)
        .bind(&email)
        .execute(&mut *tx)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
        profile_fields.push("email");
    }

    let mut referred_after_opt: Option<Option<i64>> = None;
    if req.referred_by_uid.is_some() {
        let parent = req.referred_by_uid.unwrap_or(0);
        if is_root_user(pool, target).await? {
            return Err(AdminError::bad("cannot change referrer for root user"));
        }
        if parent == target {
            return Err(AdminError::bad("cannot refer to self"));
        }
        if parent > 0 {
            if !identity_exists(pool, parent).await? {
                return Err(AdminError::bad("referrer not found"));
            }
            let downline = descendant_ids(pool, target).await?;
            if downline.contains(&parent) {
                return Err(AdminError::bad("referrer cycle"));
            }
            sqlx::query("UPDATE ai.identity SET referred_by_iid = $2, updated_ts = NOW() WHERE id = $1")
                .bind(target)
                .bind(parent)
                .execute(&mut *tx)
                .await
                .map_err(|e| AdminError::bad(e.to_string()))?;
            referred_after_opt = Some(Some(parent));
        } else {
            sqlx::query("UPDATE ai.identity SET referred_by_iid = NULL, updated_ts = NOW() WHERE id = $1")
                .bind(target)
                .execute(&mut *tx)
                .await
                .map_err(|e| AdminError::bad(e.to_string()))?;
            referred_after_opt = Some(None);
        }
    }

    let mut roles_after: Option<Vec<String>> = None;
    if let Some(patch) = req.global_roles.as_ref() {
        if is_root_user(pool, target).await? {
            return Err(AdminError::bad("cannot change roles for root user"));
        }
        let viewer_meta = viewer_meta(pool, viewer_iid).await?;
        let next = if meta_is_root(&viewer_meta) {
            root_may_assign(&patch.roles)?
        } else {
            director_may_assign(&patch.roles)?
        };
        roles_after = Some(next.clone());
        let roles_json = serde_json::to_value(&next).unwrap_or(serde_json::json!([]));
        sqlx::query(
            r#"UPDATE ai.identity SET meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{global_roles}', $2::jsonb), updated_ts = NOW() WHERE id = $1"#,
        )
        .bind(target)
        .bind(roles_json)
        .execute(&mut *tx)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    }

    tx.commit().await.map_err(|e| AdminError::bad(e.to_string()))?;

    if !profile_fields.is_empty() {
        admin_event_profile_updated(
            pool,
            nats,
            viewer_iid,
            target,
            &profile_fields,
        )
        .await;
    }
    if let Some(to) = referred_after_opt {
        admin_event_referrer_updated(pool, nats, viewer_iid, target, referred_before_opt, to).await;
    }
    if let Some(after) = roles_after {
        admin_event_roles_updated(pool, nats, viewer_iid, target, &roles_before, &after).await;
    }

    Ok(ResAdminUserPut {})
}
