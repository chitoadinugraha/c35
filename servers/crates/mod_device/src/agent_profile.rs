use sqlx::{PgPool, Row};

use crate::agent_auth::AgentSession;

#[derive(Debug, Clone, serde::Serialize)]
pub struct AgentProfile {
    pub device_iid: i64,
    pub device_name: String,
    pub owner_iid: i64,
    pub owner_alien_id: String,
    pub owner_name: String,
    pub personal_package_name: String,
    pub device_package_name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub storage_used_bytes: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub storage_limit_bytes: Option<i64>,
}

pub async fn agent_profile_get(pool: &PgPool, session: &AgentSession) -> Result<AgentProfile, String> {
    let row = sqlx::query(
        r#"
        SELECT d.id AS device_iid,
               d.name AS device_name,
               d.owner_iid,
               COALESCE(o.alien_id, '') AS owner_alien_id,
               COALESCE(o.name, '') AS owner_name,
               COALESCE(
                   up.name,
                   INITCAP(REPLACE(COALESCE(bp.plan_tier, 'free'), '_', ' ')),
                   'Free'
               ) AS personal_package_name,
               COALESCE(dp.name, 'No device package') AS device_package_name
        FROM ai.identity d
        LEFT JOIN ai.identity o ON o.id = d.owner_iid AND o.deleted_ts IS NULL
        LEFT JOIN ai.billing_profile bp
            ON bp.owner_iid = d.owner_iid AND bp.deleted_ts IS NULL
        LEFT JOIN ai.billing_plan up
            ON up.slug = bp.plan_tier AND up.scope = 'user'
        LEFT JOIN LATERAL (
            SELECT s.plan_slug
            FROM ai.billing_subscription s
            WHERE s.scope = 'device'
              AND s.scope_iid = d.id
              AND s.deleted_ts IS NULL
              AND (s.expires_ts IS NULL OR s.expires_ts > NOW())
            ORDER BY s.updated_ts DESC
            LIMIT 1
        ) ds ON TRUE
        LEFT JOIN ai.billing_plan dp
            ON dp.slug = ds.plan_slug AND dp.scope = 'device'
        WHERE d.id = $1 AND d.deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(session.device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    let Some(row) = row else {
        return Err("device not found".into());
    };

    let owner_iid = row.try_get("owner_iid").ok().flatten().unwrap_or(session.owner_iid);
    let storage = c35_mod_drive::drive_storage_snapshot(pool, owner_iid)
        .await
        .ok()
        .map(|s| (Some(s.storage_used_bytes), Some(s.storage_limit_bytes)));

    Ok(AgentProfile {
        device_iid: row.get("device_iid"),
        device_name: row.try_get("device_name").unwrap_or_default(),
        owner_iid,
        owner_alien_id: row.try_get("owner_alien_id").unwrap_or_default(),
        owner_name: row.try_get("owner_name").unwrap_or_default(),
        personal_package_name: row.try_get("personal_package_name").unwrap_or_else(|_| "—".into()),
        device_package_name: row.try_get("device_package_name").unwrap_or_else(|_| "—".into()),
        storage_used_bytes: storage.map(|s| s.0).unwrap_or(None),
        storage_limit_bytes: storage.map(|s| s.1).unwrap_or(None),
    })
}
