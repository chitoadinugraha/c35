use anyhow::Result;
use async_nats::Client;
use c35_proto::{Event, EventPush};
use c35_store::snowflake_id;
use prost::Message;
use serde_json::Value;
use sqlx::PgPool;
use tracing::warn;

use crate::catalog::event_by_kind;
use crate::render::render_en;
use crate::subject::subject_fill;

#[derive(Clone, Debug)]
pub struct EventCtx {
    pub owner_iid: i64,
    pub dv: &'static str,
    pub name: String,
    pub alien_id: Option<String>,
    pub sess_id: Option<i64>,
    pub conn_id: Option<i64>,
    pub req_id: Option<String>,
    pub device_iid: Option<i64>,
    pub channel_platform: Option<String>,
    pub channel_id: Option<String>,
}

impl EventCtx {
    pub fn for_owner(owner_iid: i64, dv: &'static str) -> Self {
        Self {
            owner_iid,
            dv,
            name: String::new(),
            alien_id: None,
            sess_id: None,
            conn_id: None,
            req_id: None,
            device_iid: None,
            channel_platform: None,
            channel_id: None,
        }
    }
}

pub async fn identity_names(pool: &PgPool, owner_iid: i64) -> (String, Option<String>) {
    let row = sqlx::query_as::<_, (String, Option<String>)>(
        "SELECT name, alien_id FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    row.map(|(n, a)| (n, a)).unwrap_or((format!("User {owner_iid}"), None))
}

pub async fn event_emit(
    pool: &PgPool,
    nats: Option<&Client>,
    ctx: EventCtx,
    kind: &str,
    meta: Value,
) -> Result<i64> {
    let def = event_by_kind(kind).ok_or_else(|| anyhow::anyhow!("unknown event kind: {kind}"))?;
    let (name, alien_id) = if ctx.name.is_empty() {
        identity_names(pool, ctx.owner_iid).await
    } else {
        (ctx.name.clone(), ctx.alien_id.clone())
    };
    let meta = merge_meta(meta, &ctx);
    let text = render_en(def.txt_en, &name, alien_id.as_deref(), &meta);
    let subject = subject_fill(def, &ctx);
    let id = snowflake_id();
    let req_id = ctx.req_id.as_deref().unwrap_or("");
    let class = def.class.as_str();
    let log_kind = def.class.log_kind();

    sqlx::query(
        r#"
        INSERT INTO ai.log (
            id, owner_iid, kind, topic, dv, req_id, chat_id, task_id, device_iid,
            text, model, tokens_in, tokens_out, duration_ms, cost_usd, meta,
            event_kind, subject, class, created_ts, updated_ts
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, NULL, NULL, $7,
            $8, '', 0, 0, 0, 0, $9::jsonb,
            $10, $11, $12, NOW(), NOW()
        )
        "#,
    )
    .bind(id)
    .bind(ctx.owner_iid)
    .bind(log_kind)
    .bind(def.slug)
    .bind(ctx.dv)
    .bind(req_id)
    .bind(ctx.device_iid)
    .bind(&text)
    .bind(&meta)
    .bind(def.kind)
    .bind(&subject)
    .bind(class)
    .execute(pool)
    .await?;

    let now_ms = chrono::Utc::now().timestamp_millis();
    let pb = Event {
        id,
        event_kind: def.kind.to_string(),
        class: class.to_string(),
        subject: subject.clone(),
        owner_iid: ctx.owner_iid,
        dv: ctx.dv.to_string(),
        slug: def.slug.to_string(),
        text,
        meta_json: meta.to_string(),
        created_ts_ms: now_ms,
    };
    let payload = EventPush { event: Some(pb) }.encode_to_vec();
    if let Some(client) = nats {
        let subj = subject.clone();
        if let Err(e) = client.publish(subj, payload.into()).await {
            warn!(error = %e, subject = %subject, "event_emit: nats publish failed");
        }
    } else {
        warn!(subject = %subject, "event_emit: nats unavailable");
    }
    Ok(id)
}

fn merge_meta(meta: Value, ctx: &EventCtx) -> Value {
    let mut obj = meta.as_object().cloned().unwrap_or_default();
    if let Some(s) = ctx.sess_id.filter(|&v| v > 0) {
        obj.insert("sess_id".into(), serde_json::json!(s));
    }
    if let Some(s) = ctx.conn_id.filter(|&v| v > 0) {
        obj.insert("conn_id".into(), serde_json::json!(s));
    }
    Value::Object(obj)
}

pub fn event_spawn(
    pool: PgPool,
    nats: Option<Client>,
    ctx: EventCtx,
    kind: &'static str,
    meta: Value,
) {
    tokio::spawn(async move {
        let _ = event_emit(&pool, nats.as_ref(), ctx, kind, meta).await;
    });
}
