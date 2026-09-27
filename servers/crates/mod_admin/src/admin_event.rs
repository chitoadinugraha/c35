use async_nats::Client;
use c35_mod_event::{event_emit, kinds, EventCtx};
use serde_json::json;
use sqlx::PgPool;

pub async fn admin_event_profile_updated(
    pool: &PgPool,
    nats: Option<&Client>,
    actor_iid: i64,
    target_iid: i64,
    fields: &[&str],
) {
    let meta = json!({
        "actor_iid": actor_iid,
        "target_iid": target_iid,
        "fields": fields.join(", "),
        "source": "rpc",
    });
    let ctx = EventCtx::for_owner(actor_iid, "c35-admin");
    let _ = event_emit(pool, nats, ctx, kinds::ADMIN_USER_PROFILE_UPDATED, meta).await;
}

pub async fn admin_event_referrer_updated(
    pool: &PgPool,
    nats: Option<&Client>,
    actor_iid: i64,
    target_iid: i64,
    from_iid: Option<i64>,
    to_iid: Option<i64>,
) {
    let meta = json!({
        "actor_iid": actor_iid,
        "target_iid": target_iid,
        "from_referred_by_iid": from_iid,
        "to_referred_by_iid": to_iid,
        "source": "rpc",
    });
    let ctx = EventCtx::for_owner(actor_iid, "c35-admin");
    let _ = event_emit(pool, nats, ctx, kinds::ADMIN_USER_REFERRER_UPDATED, meta).await;
}

pub async fn admin_event_roles_updated(
    pool: &PgPool,
    nats: Option<&Client>,
    actor_iid: i64,
    target_iid: i64,
    before: &[String],
    after: &[String],
) {
    let added: Vec<&str> = after
        .iter()
        .filter(|r| !before.iter().any(|b| b == *r))
        .map(String::as_str)
        .collect();
    let removed: Vec<&str> = before
        .iter()
        .filter(|r| !after.iter().any(|a| a == *r))
        .map(String::as_str)
        .collect();
    let meta = json!({
        "actor_iid": actor_iid,
        "target_iid": target_iid,
        "roles_before": before,
        "roles_after": after,
        "roles_added": added,
        "roles_removed": removed,
        "source": "rpc",
    });
    let ctx = EventCtx::for_owner(actor_iid, "c35-admin");
    let _ = event_emit(pool, nats, ctx, kinds::ADMIN_USER_ROLES_UPDATED, meta).await;
}
