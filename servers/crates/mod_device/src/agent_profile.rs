use sqlx::{PgPool, Row};

use crate::agent_auth::AgentSession;

#[derive(Debug, Clone, serde::Serialize)]
pub struct AgentProfile {
    pub device_iid: i64,
    pub device_name: String,
    pub owner_iid: i64,
    pub owner_alien_id: String,
    pub owner_name: String,
}

pub async fn agent_profile_get(pool: &PgPool, session: &AgentSession) -> Result<AgentProfile, String> {
    let row = sqlx::query(
        r#"
        SELECT d.id AS device_iid,
               d.name AS device_name,
               d.owner_iid,
               COALESCE(o.alien_id, '') AS owner_alien_id,
               COALESCE(o.name, '') AS owner_name
        FROM ai.identity d
        LEFT JOIN ai.identity o ON o.id = d.owner_iid AND o.deleted_ts IS NULL
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

    Ok(AgentProfile {
        device_iid: row.get("device_iid"),
        device_name: row.try_get("device_name").unwrap_or_default(),
        owner_iid: row.try_get("owner_iid").ok().flatten().unwrap_or(session.owner_iid),
        owner_alien_id: row.try_get("owner_alien_id").unwrap_or_default(),
        owner_name: row.try_get("owner_name").unwrap_or_default(),
    })
}
