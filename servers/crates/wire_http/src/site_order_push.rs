use async_nats::Client;
use c35_mod_notify::{notify_emit, NotifyEmit, NotifyFcm};
use c35_nats::user_app_subject_site_order;
use c35_proto::{sync_push, SyncPush, Tx, WsRes, ws_res};
use prost::Message;
use serde_json::json;
use sqlx::{PgPool, Row};

pub async fn guest_order_notify_app(nats: &Client, pool: &PgPool, site_iid: i64, tx: &Tx) {
    let uids = site_staff_notify_uids(pool, site_iid).await;
    if uids.is_empty() {
        return;
    }
    let ws = WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::SyncPush(SyncPush {
            body: Some(sync_push::Body::Tx(tx.clone())),
        })),
    };
    let bytes = ws.encode_to_vec();
    let fcm = NotifyFcm::from_env();
    let title = "New guest order".to_string();
    let body = if tx.subject_name.trim().is_empty() {
        format!("Order #{}", tx.tx_id)
    } else {
        tx.subject_name.clone()
    };
    let route_json = json!({
        "path": "/pos/orders",
        "site_iid": site_iid,
        "tx_id": tx.tx_id,
    });
    for uid in uids {
        let subject = user_app_subject_site_order(uid);
        let _ = nats.publish(subject, bytes.clone().into()).await;
        if let Err(e) = notify_emit(
            pool,
            Some(nats),
            &fcm,
            NotifyEmit {
                owner_iid: uid,
                title: title.clone(),
                body: body.clone(),
                category: "site_order",
                route_json: route_json.clone(),
                req_id: String::new(),
            },
        )
        .await
        {
            tracing::warn!(owner_iid = uid, error = %e, "[c35:notify] guest order emit");
        }
    }
}

async fn site_staff_notify_uids(pool: &PgPool, site_iid: i64) -> Vec<i64> {
    let owner: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT owner_iid FROM ai.identity
        WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    let rows = sqlx::query(
        r#"
        SELECT grantee_iid FROM ai.identity_grant
        WHERE resource_iid = $1 AND deleted_ts IS NULL
          AND role IN ('staff', 'manage', 'owner')
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    let mut uids: Vec<i64> = rows.iter().map(|r| r.get::<i64, _>("grantee_iid")).collect();
    if let Some(o) = owner {
        if o > 0 {
            uids.push(o);
        }
    }
    uids.sort_unstable();
    uids.dedup();
    uids
}
