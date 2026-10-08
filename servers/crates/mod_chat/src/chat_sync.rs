use anyhow::Result;
use async_nats::Client;
use c35_nats::user_app_subject_inbox;
use c35_proto::{pb_encode, sync_push, ws_res, Chat, ChatKind, ResChatPatch, SyncPush, WsRes};
use chrono::{DateTime, Utc};
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
    lock: bool,
) -> Result<()> {
    let title: String = title.trim().chars().take(128).collect();
    if chat_id == 0 || title.is_empty() {
        return Ok(());
    }
    let sql = if lock {
        r#"
        UPDATE ai.chat SET title = $3,
            meta = COALESCE(meta, '{}'::jsonb) || '{"title_locked":true}'::jsonb,
            updated_ts = NOW()
        WHERE id = $1 AND owner_iid = $2 AND kind = 'prompt' AND deleted_ts IS NULL
        "#
    } else {
        r#"
        UPDATE ai.chat SET title = $3, updated_ts = NOW()
        WHERE id = $1 AND owner_iid = $2 AND kind = 'prompt' AND deleted_ts IS NULL
        "#
    };
    let updated = sqlx::query(sql)
        .bind(chat_id)
        .bind(owner_iid)
        .bind(&title)
        .execute(pool)
        .await?;
    if updated.rows_affected() == 0 {
        return Ok(());
    }
    if let Some(nats) = nats {
        chat_fanout(pool, nats, owner_iid, chat_id).await?;
    }
    Ok(())
}

/// Pin/archive/tags/delete — fanout to other app sessions (`c35.user.{iid}.app.inbox`).
pub async fn chat_inbox_fanout(nats: &Client, owner_iid: i64, patch: &ResChatPatch) -> Result<()> {
    if let Some(member) = patch.member.as_ref() {
        let res = WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::SyncPush(SyncPush {
                body: Some(sync_push::Body::ChatMember(member.clone())),
            })),
        };
        nats.publish(user_app_subject_inbox(owner_iid), pb_encode(&res).into())
            .await?;
    }
    if let Some(chat) = patch.chat.as_ref() {
        let res = WsRes {
            req_id: String::new(),
            body: Some(ws_res::Body::SyncPush(SyncPush {
                body: Some(sync_push::Body::Chat(chat.clone())),
            })),
        };
        nats.publish(user_app_subject_inbox(owner_iid), pb_encode(&res).into())
            .await?;
    }
    Ok(())
}

pub async fn chat_fanout(pool: &PgPool, nats: &Client, owner_iid: i64, chat_id: i64) -> Result<()> {
    let row = sqlx::query(
        r#"
        SELECT c.id, c.kind, c.owner_iid, c.title, c.model, c.last_msg_ts, c.last_msg_preview, c.meta,
               c.context_window, c.created_ts, c.updated_ts, c.deleted_ts
        FROM ai.chat c
        WHERE c.id = $1 AND c.owner_iid = $2 AND c.kind = 'prompt' AND c.deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    let Some(r) = row else {
        return Ok(());
    };
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
        context_window: r.get("context_window"),
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
    nats.publish(
        prompt_chat_subject(owner_iid, chat_id),
        pb_encode(&res).into(),
    )
    .await?;
    Ok(())
}

pub async fn chat_touch(
    pool: &PgPool,
    nats: Option<&Client>,
    chat_id: i64,
    owner_iid: i64,
    preview: &str,
    status: &str,
) -> Result<()> {
    let p: String = preview.chars().take(255).collect();
    let mut tx = match pool.begin().await {
        Ok(t) => t,
        Err(e) => {
            tracing::warn!("[c35:chat] chat_touch begin tx failed: {e}");
            return Ok(());
        }
    };
    let _ = sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(&p)
    .execute(&mut *tx)
    .await;
    let _ = sqlx::query(
        r#"
        UPDATE ai.chat_member SET last_msg_ts = NOW(), last_msg_preview = $2, last_msg_status = $4, updated_ts = NOW()
        WHERE chat_id = $1 AND member_iid = $3
        "#,
    )
    .bind(chat_id)
    .bind(&p)
    .bind(owner_iid)
    .bind(status)
    .execute(&mut *tx)
    .await;
    let _ = tx.commit().await;
    if let Some(nats) = nats {
        let _ = chat_fanout(pool, nats, owner_iid, chat_id).await;
    }
    Ok(())
}
