use c35_proto::{
    AdminUserHit, ReqAdminUserPut, ReqAdminUserSearch, ResAdminUserPut, ResAdminUserSearch,
};
use std::collections::HashSet;

mod log_admin;
mod log_report;
mod ops_peaks;
mod platform_pnl;

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

fn meta_is_partner(meta: &serde_json::Value) -> bool {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().any(|x| x.as_str() == Some("partner")))
        .unwrap_or(false)
}

pub async fn require_admin(pool: &PgPool, viewer_iid: i64) -> Result<(), AdminError> {
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
    if meta_is_root(&meta) || meta_is_partner(&meta) {
        Ok(())
    } else {
        Err(AdminError::forbidden())
    }
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
    viewer_iid: i64,
    req: ReqAdminUserPut,
) -> Result<ResAdminUserPut, AdminError> {
    require_admin(pool, viewer_iid).await?;
    let target = req.target_identity_id;
    if target <= 0 {
        return Err(AdminError::bad("target required"));
    }
    if !identity_exists(pool, target).await? {
        return Err(AdminError::bad("user not found"));
    }
    let mut tx = pool.begin().await.map_err(|e| AdminError::bad(e.to_string()))?;

    if let Some(name) = req.name.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        sqlx::query("UPDATE ai.identity SET name = $2, updated_ts = NOW() WHERE id = $1")
            .bind(target)
            .bind(name)
            .execute(&mut *tx)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?;
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
    }

    if let Some(url) = req.avatar_url.as_ref() {
        sqlx::query("UPDATE ai.identity SET pic = $2, updated_ts = NOW() WHERE id = $1")
            .bind(target)
            .bind(url.trim())
            .execute(&mut *tx)
            .await
            .map_err(|e| AdminError::bad(e.to_string()))?;
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
    }

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
        } else {
            sqlx::query("UPDATE ai.identity SET referred_by_iid = NULL, updated_ts = NOW() WHERE id = $1")
                .bind(target)
                .execute(&mut *tx)
                .await
                .map_err(|e| AdminError::bad(e.to_string()))?;
        }
    }

    tx.commit().await.map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(ResAdminUserPut {})
}
