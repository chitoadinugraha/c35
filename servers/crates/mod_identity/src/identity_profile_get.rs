use c35_ctx::Ctx;
use c35_proto::IdentityProfile;
use c35_wire::{WireErr, WireResult};
use sqlx::Row;

pub async fn identity_profile_get(ctx: &Ctx) -> WireResult<IdentityProfile> {
    let row = sqlx::query(
        r#"
        SELECT id, kind, type, alien_id, name, pic, locale, tz, billing_iid,
               COALESCE((meta->>'is_root')::boolean, false) AS is_root,
               COALESCE(meta #>> '{location,city}', '') AS location_city,
               COALESCE(meta #>> '{location,region}', '') AS location_region,
               COALESCE(meta #>> '{location,country}', '') AS location_country,
               COALESCE(meta #>> '{location,source}', '') AS location_source
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(ctx.caller_iid)
    .fetch_optional(&ctx.pool)
    .await
    .map_err(|e| WireErr::Internal(e.to_string()))?;

    let Some(row) = row else {
        return Ok(IdentityProfile {
            iid: ctx.caller_iid,
            kind: "user".into(),
            name: "User".into(),
            locale: "en_US".into(),
            tz: "UTC".into(),
            ..Default::default()
        });
    };

    Ok(IdentityProfile {
        iid: row.get("id"),
        kind: row.get("kind"),
        r#type: row.get("type"),
        alien_id: row.try_get::<Option<String>, _>("alien_id").ok().flatten().unwrap_or_default(),
        name: row.get("name"),
        pic: row.try_get::<Option<String>, _>("pic").ok().flatten().unwrap_or_default(),
        locale: row.get("locale"),
        tz: row.get("tz"),
        billing_iid: row.try_get("billing_iid").unwrap_or(0),
        is_root: row.get("is_root"),
        location_city: row.try_get::<String, _>("location_city").unwrap_or_default(),
        location_region: row.try_get::<String, _>("location_region").unwrap_or_default(),
        location_country: row.try_get::<String, _>("location_country").unwrap_or_default(),
        location_source: row.try_get::<String, _>("location_source").unwrap_or_default(),
    })
}
