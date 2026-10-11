use c35_ctx::Ctx;
use c35_mod_identity::identity_profile_get;
use serde_json::json;
use sqlx::{PgPool, Row};

async fn auth_email_for_iid(pool: &PgPool, iid: i64) -> String {
    let rows = sqlx::query(
        r#"
        SELECT kind, identifier
        FROM ai.identity_provider
        WHERE identity_iid = $1 AND deleted_ts IS NULL AND kind IN ('google', 'email', 'phone')
        ORDER BY CASE kind WHEN 'google' THEN 0 WHEN 'email' THEN 1 ELSE 2 END
        "#,
    )
    .bind(iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    for r in rows {
        let kind: String = r.get("kind");
        if kind == "phone" {
            continue;
        }
        let id: String = r.get("identifier");
        let trimmed = id.trim();
        if !trimmed.is_empty() {
            return trimmed.to_string();
        }
    }
    String::new()
}

/// Factual caller identity for `inst.me` enrich (name, alien_id, email).
pub async fn user_me_enrich(pool: &PgPool, owner_iid: i64) -> Option<String> {
    if owner_iid <= 0 {
        return None;
    }
    let ctx = Ctx {
        pool: pool.clone(),
        nats: None,
        caller_iid: owner_iid,
    };
    let profile = identity_profile_get(&ctx).await.ok()?;
    if profile.name.is_empty() && profile.alien_id.is_empty() {
        return None;
    }
    let auth_email = auth_email_for_iid(pool, owner_iid).await;
    let email = if profile.email.is_empty() {
        auth_email
    } else {
        profile.email.clone()
    };
    let v = json!({
        "name": profile.name,
        "alien_id": profile.alien_id,
        "email": email,
        "iid": profile.iid,
    });
    serde_json::to_string(&v).ok()
}
