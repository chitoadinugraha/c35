use sqlx::{PgPool, Row};

#[derive(Debug, Clone, Default)]
pub struct UserPromptContext {
    pub locale: String,
    pub tz: String,
    pub location_city: String,
    pub location_region: String,
    pub location_country: String,
}

pub async fn user_prompt_context_get(pool: &PgPool, owner_iid: i64) -> UserPromptContext {
    let row = sqlx::query(
        r#"
        SELECT locale, tz,
               COALESCE(meta #>> '{location,city}', '') AS location_city,
               COALESCE(meta #>> '{location,region}', '') AS location_region,
               COALESCE(meta #>> '{location,country}', '') AS location_country
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.map(|r| UserPromptContext {
        locale: r.try_get("locale").unwrap_or_else(|_| "en_US".into()),
        tz: r.try_get("tz").unwrap_or_else(|_| "UTC".into()),
        location_city: r.try_get("location_city").unwrap_or_default(),
        location_region: r.try_get("location_region").unwrap_or_default(),
        location_country: r.try_get("location_country").unwrap_or_default(),
    })
    .unwrap_or_default()
}
