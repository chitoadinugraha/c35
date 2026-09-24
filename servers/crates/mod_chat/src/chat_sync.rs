use anyhow::Result;
use async_nats::Client;
use chrono::{DateTime, Utc};
use c35_proto::{pb_encode, sync_push, Chat, ChatKind, SyncPush, WsRes, ws_res};
use sqlx::{PgPool, Row};

use crate::asset_tag::asset_tags_map;
use crate::inbox::ts_ms;
use crate::prompt_run::prompt_chat_subject;

pub async fn chat_title_set(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    chat_id: i64,
    title: &str,
) -> Result<()> {
    let title: String = title.trim().chars().take(128).collect();
    if chat_id == 0 || title.is_empty() {
        return Ok(());
    }
    let updated = sqlx::query(
        r#"
        UPDATE ai.chat SET title = $3, updated_ts = NOW()
        WHERE id = $1 AND owner_iid = $2 AND kind = 'prompt' AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .bind(&title)
    .execute(pool)
    .await?;
    if updated.rows_affected() == 0 {
        return Ok(());
    }
    if let Some(nats) = nats {
        chat_title_fanout(pool, nats, owner_iid, chat_id).await?;
    }
    Ok(())
}

async fn chat_title_fanout(pool: &PgPool, nats: &Client, owner_iid: i64, chat_id: i64) -> Result<()> {
    let row = sqlx::query(
        r#"
        SELECT c.id, c.kind, c.owner_iid, c.title, c.model, c.last_msg_ts, c.last_msg_preview, c.meta,
               c.created_ts, c.updated_ts, c.deleted_ts
        FROM ai.chat c
        WHERE c.id = $1 AND c.owner_iid = $2 AND c.kind = 'prompt' AND c.deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    let Some(r) = row else { return Ok(()); };
    let tags = asset_tags_map(pool, owner_iid, "chat", &[chat_id])
        .await?
        .remove(&chat_id)
        .unwrap_or_default();
    let preview: String = r.get("last_msg_preview");
    let last_at = r.get::<Option<DateTime<Utc>>, _>("last_msg_ts");
    let meta: serde_json::Value = r.get("meta");
    let chat = Chat {
        id: chat_id,
        kind: ChatKind::Prompt as i32,
        owner_iid,
        title: r.get("title"),
        tags,
        model: r.get("model"),
        last_msg_ts_ms: ts_ms(last_at),
        last_msg_preview: preview,
        meta_json: meta.to_string(),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        ..Default::default()
    };
    let res = WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::SyncPush(SyncPush {
            body: Some(sync_push::Body::Chat(chat)),
        })),
    };
    nats.publish(prompt_chat_subject(owner_iid, chat_id), pb_encode(&res).into())
        .await?;
    Ok(())
}
