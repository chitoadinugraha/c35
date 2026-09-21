use anyhow::{anyhow, Result};
use chrono::{DateTime, Utc};
use c35_proto::{
    Chat, ChatKind, ChatMember, ChatMsg, ChatMsgRole, ChatMsgSource, ChatMsgStatus, ReqChatMsgList, ReqInboxList,
    ResChatMsgList, ResInboxList,
};
use sqlx::{PgPool, Row};

use crate::asset_tag::asset_tags_map;

pub(crate) fn ts_ms(t: Option<DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

pub async fn inbox_list(pool: &PgPool, member_iid: i64, req: ReqInboxList) -> Result<ResInboxList> {
    let limit = if req.limit <= 0 { 100 } else { req.limit.min(500) };
    let archived_clause = if req.include_archived {
        ""
    } else {
        "AND m.archived_ts IS NULL"
    };
    let sql = format!(
        r#"
        SELECT c.id, c.kind, c.owner_iid, c.title, c.model, c.last_msg_ts, c.last_msg_preview,
               c.created_ts, c.updated_ts, c.deleted_ts,
               m.last_read_msg_id, m.unread_count, m.last_msg_ts AS member_last_msg_ts, m.last_msg_preview AS member_preview,
               m.pinned_ts, m.archived_ts, m.created_ts AS member_created_ts, m.updated_ts AS member_updated_ts, m.deleted_ts AS member_deleted_ts
        FROM ai.chat_member m
        JOIN ai.chat c ON c.id = m.chat_id
        WHERE m.member_iid = $1
          AND m.deleted_ts IS NULL
          {archived_clause}
          AND c.kind = 'prompt'
          AND c.deleted_ts IS NULL
        ORDER BY m.pinned_ts DESC NULLS LAST, m.last_msg_ts DESC
        LIMIT $2
        "#,
        archived_clause = archived_clause
    );
    let rows = sqlx::query(&sql).bind(member_iid).bind(limit).fetch_all(pool).await?;
    let chat_ids: Vec<i64> = rows.iter().map(|r| r.get("id")).collect();
    let tags_by_chat = asset_tags_map(pool, member_iid, "chat", &chat_ids).await?;
    let mut chats = Vec::with_capacity(rows.len());
    let mut members = Vec::with_capacity(rows.len());
    for r in rows {
        let chat_id: i64 = r.get("id");
        let preview: String = r.get::<Option<String>, _>("member_preview").filter(|s| !s.is_empty()).unwrap_or_else(|| r.get("last_msg_preview"));
        let last_at = r.get::<Option<DateTime<Utc>>, _>("member_last_msg_ts").or_else(|| r.get("last_msg_ts"));
        chats.push(Chat {
            id: chat_id,
            kind: ChatKind::Prompt as i32,
            owner_iid: r.get("owner_iid"),
            title: r.get("title"),
            tags: tags_by_chat.get(&chat_id).cloned().unwrap_or_default(),
            model: r.get("model"),
            last_msg_ts_ms: ts_ms(last_at),
            last_msg_preview: preview.clone(),
            created_ts_ms: ts_ms(r.get("created_ts")),
            updated_ts_ms: ts_ms(r.get("updated_ts")),
            deleted_ts_ms: ts_ms(r.get("deleted_ts")),
            ..Default::default()
        });
        members.push(ChatMember {
            chat_id,
            member_iid,
            last_read_msg_id: r.get::<Option<i64>, _>("last_read_msg_id").unwrap_or(0),
            unread_count: r.get("unread_count"),
            last_msg_ts_ms: ts_ms(last_at),
            last_msg_preview: preview,
            pinned_ts_ms: ts_ms(r.get("pinned_ts")),
            archived_ts_ms: ts_ms(r.get("archived_ts")),
            created_ts_ms: ts_ms(r.get("member_created_ts")),
            updated_ts_ms: ts_ms(r.get("member_updated_ts")),
            deleted_ts_ms: ts_ms(r.get("member_deleted_ts")),
        });
    }
    Ok(ResInboxList { chats, members })
}

pub async fn chat_msg_list(pool: &PgPool, member_iid: i64, req: ReqChatMsgList) -> Result<ResChatMsgList> {
    let chat_id = req.chat_id;
    if chat_id == 0 {
        return Err(anyhow!("chat_id required"));
    }
    let allowed = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT c.id FROM ai.chat c
        JOIN ai.chat_member m ON m.chat_id = c.id
        WHERE c.id = $1 AND m.member_iid = $2 AND c.kind = 'prompt' AND c.deleted_ts IS NULL AND m.deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(member_iid)
    .fetch_optional(pool)
    .await?;
    if allowed.is_none() {
        return Err(anyhow!("chat not found"));
    }
    let limit = if req.limit <= 0 { 100 } else { req.limit.min(500) };
    let before = req.before_id;
    let rows = if before > 0 {
        sqlx::query(
            r#"
            SELECT id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought, attachments, blocks_json,
                   tokens_in, tokens_out, duration_ms, status, cost_usd, error_text, created_ts, updated_ts, deleted_ts
            FROM ai.chat_msg
            WHERE chat_id = $1 AND deleted_ts IS NULL AND id < $2
            ORDER BY id DESC
            LIMIT $3
            "#,
        )
        .bind(chat_id)
        .bind(before)
        .bind(limit)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought, attachments, blocks_json,
                   tokens_in, tokens_out, duration_ms, status, cost_usd, error_text, created_ts, updated_ts, deleted_ts
            FROM ai.chat_msg
            WHERE chat_id = $1 AND deleted_ts IS NULL
            ORDER BY id DESC
            LIMIT $2
            "#,
        )
        .bind(chat_id)
        .bind(limit)
        .fetch_all(pool)
        .await?
    };
    let messages = rows.into_iter().map(row_to_msg).collect::<Vec<_>>();
    Ok(ResChatMsgList { messages })
}

fn row_to_msg(r: sqlx::postgres::PgRow) -> ChatMsg {
    let role: String = r.get("role");
    let source: String = r.get("source");
    let status: String = r.get("status");
    let attachments = r.get::<serde_json::Value, _>("attachments");
    let blocks = r.get::<serde_json::Value, _>("blocks_json");
    ChatMsg {
        id: r.get("id"),
        chat_id: r.get("chat_id"),
        owner_iid: r.get("owner_iid"),
        req_id: r.get("req_id"),
        sender_iid: r.get("sender_iid"),
        role: msg_role(&role),
        source: msg_source(&source),
        content: r.get("content"),
        thought: r.get("thought"),
        attachments_json: attachments.to_string(),
        blocks_json: blocks.to_string(),
        tokens_in: r.get("tokens_in"),
        tokens_out: r.get("tokens_out"),
        duration_ms: r.get("duration_ms"),
        status: msg_status(&status),
        cost_usd: r.get("cost_usd"),
        error_text: r.get("error_text"),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
    }
}

fn msg_role(s: &str) -> i32 {
    match s {
        "user" => ChatMsgRole::User as i32,
        "assistant" => ChatMsgRole::Assistant as i32,
        "system" => ChatMsgRole::System as i32,
        _ => ChatMsgRole::Unspecified as i32,
    }
}

fn msg_source(s: &str) -> i32 {
    match s {
        "prompt" => ChatMsgSource::Prompt as i32,
        "user" => ChatMsgSource::User as i32,
        "external" => ChatMsgSource::External as i32,
        "staff" => ChatMsgSource::Staff as i32,
        _ => ChatMsgSource::Unspecified as i32,
    }
}

fn msg_status(s: &str) -> i32 {
    match s {
        "streaming" => ChatMsgStatus::Streaming as i32,
        "done" => ChatMsgStatus::Done as i32,
        "interrupted" => ChatMsgStatus::Interrupted as i32,
        "error" => ChatMsgStatus::Error as i32,
        _ => ChatMsgStatus::Unspecified as i32,
    }
}
