use anyhow::{anyhow, Result};
use chrono::Utc;
use c35_proto::{Chat, ChatKind, ChatMember, ReqChatPatch, ResChatPatch};
use sqlx::{PgPool, Row};

use crate::asset_tag::{asset_tags_map, asset_tags_replace};
use crate::inbox::ts_ms;

pub async fn chat_patch(pool: &PgPool, member_iid: i64, req: ReqChatPatch) -> Result<ResChatPatch> {
    let chat_id = req.chat_id;
    if chat_id == 0 {
        return Err(anyhow!("chat_id required"));
    }
    let owner_iid = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT c.owner_iid FROM ai.chat c
        JOIN ai.chat_member m ON m.chat_id = c.id
        WHERE c.id = $1 AND m.member_iid = $2 AND c.kind = 'prompt' AND c.deleted_ts IS NULL AND m.deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(member_iid)
    .fetch_optional(pool)
    .await?;
    let owner_iid = owner_iid.ok_or_else(|| anyhow!("chat not found"))?;

    if req.deleted == Some(true) {
        sqlx::query("UPDATE ai.chat SET deleted_ts = NOW(), updated_ts = NOW() WHERE id = $1")
            .bind(chat_id)
            .execute(pool)
            .await?;
        sqlx::query("UPDATE ai.chat_member SET deleted_ts = NOW(), updated_ts = NOW() WHERE chat_id = $1 AND member_iid = $2")
            .bind(chat_id)
            .bind(member_iid)
            .execute(pool)
            .await?;
        return chat_patch_get(pool, member_iid, chat_id, true).await;
    }

    if let Some(pinned) = req.pinned {
        if pinned {
            sqlx::query(
                "UPDATE ai.chat_member SET pinned_ts = NOW(), archived_ts = NULL, updated_ts = NOW() WHERE chat_id = $1 AND member_iid = $2",
            )
            .bind(chat_id)
            .bind(member_iid)
            .execute(pool)
            .await?;
        } else {
            sqlx::query("UPDATE ai.chat_member SET pinned_ts = NULL, updated_ts = NOW() WHERE chat_id = $1 AND member_iid = $2")
                .bind(chat_id)
                .bind(member_iid)
                .execute(pool)
                .await?;
        }
    }

    if let Some(archived) = req.archived {
        if archived {
            sqlx::query(
                "UPDATE ai.chat_member SET archived_ts = NOW(), pinned_ts = NULL, updated_ts = NOW() WHERE chat_id = $1 AND member_iid = $2",
            )
            .bind(chat_id)
            .bind(member_iid)
            .execute(pool)
            .await?;
        } else {
            sqlx::query("UPDATE ai.chat_member SET archived_ts = NULL, updated_ts = NOW() WHERE chat_id = $1 AND member_iid = $2")
                .bind(chat_id)
                .bind(member_iid)
                .execute(pool)
                .await?;
        }
    }

    if let Some(tags) = req.tags {
        asset_tags_replace(pool, owner_iid, "chat", chat_id, &tags.tags).await?;
    }

    chat_patch_get(pool, member_iid, chat_id, false).await
}

async fn chat_patch_get(pool: &PgPool, member_iid: i64, chat_id: i64, deleted: bool) -> Result<ResChatPatch> {
    let row = sqlx::query(
        r#"
        SELECT c.id, c.kind, c.owner_iid, c.title, c.model, c.last_msg_ts, c.last_msg_preview,
               c.created_ts, c.updated_ts, c.deleted_ts,
               m.last_read_msg_id, m.unread_count, m.last_msg_ts AS member_last_msg_ts, m.last_msg_preview AS member_preview,
               m.pinned_ts, m.archived_ts, m.created_ts AS member_created_ts, m.updated_ts AS member_updated_ts, m.deleted_ts AS member_deleted_ts
        FROM ai.chat c
        JOIN ai.chat_member m ON m.chat_id = c.id
        WHERE c.id = $1 AND m.member_iid = $2
        "#,
    )
    .bind(chat_id)
    .bind(member_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("chat not found"))?;

    let owner_iid: i64 = row.get("owner_iid");
    let tags = asset_tags_map(pool, owner_iid, "chat", &[chat_id]).await?.remove(&chat_id).unwrap_or_default();

    let preview: String = row
        .get::<Option<String>, _>("member_preview")
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| row.get("last_msg_preview"));
    let last_at = row.get::<Option<chrono::DateTime<Utc>>, _>("member_last_msg_ts").or_else(|| row.get("last_msg_ts"));

    let chat = Chat {
        id: chat_id,
        kind: ChatKind::Prompt as i32,
        owner_iid,
        title: row.get("title"),
        tags,
        model: row.get("model"),
        last_msg_ts_ms: ts_ms(last_at),
        last_msg_preview: preview.clone(),
        created_ts_ms: ts_ms(row.get("created_ts")),
        updated_ts_ms: ts_ms(row.get("updated_ts")),
        deleted_ts_ms: if deleted { Utc::now().timestamp_millis() } else { ts_ms(row.get("deleted_ts")) },
        ..Default::default()
    };
    let member = ChatMember {
        chat_id,
        member_iid,
        last_read_msg_id: row.get::<Option<i64>, _>("last_read_msg_id").unwrap_or(0),
        unread_count: row.get("unread_count"),
        last_msg_ts_ms: ts_ms(last_at),
        last_msg_preview: preview,
        pinned_ts_ms: ts_ms(row.get("pinned_ts")),
        archived_ts_ms: ts_ms(row.get("archived_ts")),
        created_ts_ms: ts_ms(row.get("member_created_ts")),
        updated_ts_ms: ts_ms(row.get("member_updated_ts")),
        deleted_ts_ms: if deleted {
            Utc::now().timestamp_millis()
        } else {
            ts_ms(row.get("member_deleted_ts"))
        },
    };
    Ok(ResChatPatch { chat: Some(chat), member: Some(member) })
}
