use anyhow::Result;
use chrono::Utc;
use serde_json::json;
use sqlx::{PgPool, Row};
use std::collections::HashMap;

use crate::bus::{encode_notify_push, NotifyNats};
use crate::plan::{plan_delivery, AppConn, FcmTok, PRESENCE_TTL};
use crate::FcmSend;
use c35_mod_event::{event_emit, kinds, EventCtx};

pub async fn notify_deliver(
    pool: &PgPool,
    nats: Option<&c35_nats::Client>,
    fcm: &dyn FcmSend,
    id: i64,
) -> Result<()> {
    let _claimed = deliver_once(pool, nats, fcm, id).await?;
    Ok(())
}

pub async fn notify_release_waiting(
    pool: &PgPool,
    nats: Option<&c35_nats::Client>,
    fcm: &dyn FcmSend,
    owner_iid: i64,
    req_id: &str,
) -> Result<u32> {
    if req_id.is_empty() {
        return Ok(0);
    }
    let rows = sqlx::query(
        "SELECT id FROM ai.notify \
         WHERE owner_iid = $1 AND req_id = $2 AND status = 'waiting' AND deleted_ts IS NULL \
         ORDER BY id ASC",
    )
    .bind(owner_iid)
    .bind(req_id)
    .fetch_all(pool)
    .await?;
    let mut n = 0u32;
    for row in rows {
        let id: i64 = row.try_get("id")?;
        if deliver_once(pool, nats, fcm, id).await? {
            n += 1;
        }
    }
    Ok(n)
}

async fn deliver_once(
    pool: &PgPool,
    nats: Option<&c35_nats::Client>,
    fcm: &dyn FcmSend,
    id: i64,
) -> Result<bool> {
    let head = sqlx::query(
        "SELECT owner_iid, req_id, status FROM ai.notify WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;
    let Some(head) = head else {
        return Ok(false);
    };
    let status: String = head.try_get("status")?;
    if status != "scheduled" && status != "waiting" {
        return Ok(false);
    }
    let owner_iid: i64 = head.try_get("owner_iid")?;
    let req_id: String = head.try_get("req_id")?;

    let stale_secs = PRESENCE_TTL.num_seconds();
    let delete_stale = format!(
        "DELETE FROM ai.app_conn \
         WHERE owner_iid = $1 AND updated_ts <= NOW() - INTERVAL '{stale_secs} seconds'"
    );
    sqlx::query(&delete_stale)
        .bind(owner_iid)
        .execute(pool)
        .await?;

    let conn_rows = sqlx::query(
        "SELECT client_id, resumed, updated_ts FROM ai.app_conn WHERE owner_iid = $1",
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await?;
    let conns: Vec<AppConn> = conn_rows
        .iter()
        .map(|r| {
            Ok(AppConn {
                client_id: r.try_get("client_id")?,
                resumed: r.try_get("resumed")?,
                updated_ts: r.try_get("updated_ts")?,
            })
        })
        .collect::<Result<_, sqlx::Error>>()?;

    let tok_rows =
        sqlx::query("SELECT client_id, token FROM ai.fcm_token WHERE owner_iid = $1")
            .bind(owner_iid)
            .fetch_all(pool)
            .await?;
    let tokens: Vec<FcmTok> = tok_rows
        .iter()
        .map(|r| {
            Ok(FcmTok {
                client_id: r.try_get("client_id")?,
                token: r.try_get("token")?,
            })
        })
        .collect::<Result<_, sqlx::Error>>()?;

    let plan = plan_delivery(&conns, &tokens, Utc::now());
    let claimed = sqlx::query(
        "UPDATE ai.notify \
         SET status = 'sent', channels = $2, sent_ts = NOW(), updated_ts = NOW() \
         WHERE id = $1 AND status IN ('scheduled', 'waiting') AND deleted_ts IS NULL \
         RETURNING id, owner_iid, title, body, route_json::text AS route_text",
    )
    .bind(id)
    .bind(&plan.channels)
    .fetch_optional(pool)
    .await?;
    let Some(row) = claimed else {
        return Ok(false);
    };
    let title: String = row.try_get("title")?;
    let body: String = row.try_get("body")?;
    let owner_iid: i64 = row.try_get("owner_iid")?;
    let route_text: String = row.try_get("route_text")?;

    if plan.nats {
        match nats {
            Some(bus) => {
                let bytes = encode_notify_push(&req_id, id, &title, &body, &route_text);
                if let Err(e) = bus.publish_user_notify(owner_iid, bytes).await {
                    tracing::warn!(notify_id = id, error = %e, "notify push publish failed");
                }
            }
            None => {
                tracing::warn!(notify_id = id, "notify push skipped: nats unavailable");
            }
        }
    }
    if !plan.fcm_tokens.is_empty() {
        let mut data = HashMap::new();
        data.insert("type".into(), "user_notify".into());
        data.insert("title".into(), title.clone());
        data.insert("body".into(), body);
        data.insert("notify_id".into(), id.to_string());
        data.insert("route_json".into(), route_text);
        fcm.send_data(&plan.fcm_tokens, data).await;
    }

    let mut ctx = EventCtx::for_owner(owner_iid, "c35-server");
    if !req_id.is_empty() {
        ctx.req_id = Some(req_id);
    }
    let meta = json!({
        "notify_id": id,
        "channels": plan.channels,
        "title": title,
    });
    if let Err(e) = event_emit(pool, nats, ctx, kinds::USER_NOTIFIED, meta).await {
        tracing::warn!(notify_id = id, error = %e, "user.notified emit failed");
    }
    Ok(true)
}
