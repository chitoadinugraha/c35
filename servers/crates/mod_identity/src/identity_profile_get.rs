use c35_ctx::Ctx;
use c35_proto::IdentityProfile;
use c35_wire::{WireErr, WireResult};
use sqlx::Row;

pub async fn identity_profile_get(ctx: &Ctx) -> WireResult<IdentityProfile> {
    let row = sqlx::query(
        r#"
        SELECT id, kind, type, alien_id, name, pic, locale, tz, billing_iid,
               COALESCE((meta->>'is_root')::boolean, false) AS is_root
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
    })
}
