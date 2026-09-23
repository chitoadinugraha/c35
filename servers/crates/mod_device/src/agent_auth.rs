use sqlx::{PgPool, Row};

pub struct AgentSession {
    pub device_iid: i64,
    pub owner_iid: i64,
    pub device_name: String,
}

pub async fn agent_session_resolve(pool: &PgPool, session_key: &str) -> Result<Option<AgentSession>, String> {
    let key = session_key.trim();
    if key.is_empty() {
        return Ok(None);
    }
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, name, meta
        FROM ai.identity
        WHERE kind = 'remote'
          AND deleted_ts IS NULL
          AND meta->>'session_key' = $1
          AND owner_iid IS NOT NULL
          AND owner_iid <> 0
        LIMIT 1
        "#,
    )
    .bind(key)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    Ok(row.map(|r| AgentSession {
        device_iid: r.get("id"),
        owner_iid: r.get("owner_iid"),
        device_name: r.get("name"),
    }))
}
