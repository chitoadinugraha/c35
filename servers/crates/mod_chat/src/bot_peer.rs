use anyhow::{anyhow, Result};
use c35_proto::{
    Chat, ChatKind, ChatMsg, ChatMsgRole, ChatMsgSource, ChatMsgStatus, ReqBotPeerList, ReqChatMsgList,
    ReqChatSend, ReqChatStop, ResBotPeerList, ResChatMsgList, ResChatSend, ResChatStop,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::inbox::ts_ms;

async fn bot_access_verify(pool: &PgPool, caller_iid: i64, bot_iid: i64) -> Result<()> {
    if bot_iid == 0 {
        return Err(anyhow!("bot_iid required"));
    }
    let ok = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS (
            SELECT 1 FROM ai.identity i
            LEFT JOIN ai.identity_grant g
              ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
            WHERE i.id = $1 AND i.kind = 'bot' AND i.deleted_ts IS NULL
              AND (i.owner_iid = $2 OR g.grantee_iid IS NOT NULL)
        )
        "#,
    )
    .bind(bot_iid)
    .bind(caller_iid)
    .fetch_one(pool)
    .await?;
    if !ok {
        return Err(anyhow!("bot not found or access denied"));
    }
    Ok(())
}

async fn bot_peer_chat_verify(pool: &PgPool, caller_iid: i64, chat_id: i64) -> Result<i64> {
    if chat_id == 0 {
        return Err(anyhow!("chat_id required"));
    }
    let row = sqlx::query(
        r#"
        SELECT owner_iid, bot_iid FROM ai.chat
        WHERE id = $1 AND kind = 'bot_peer' AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let row = row.ok_or_else(|| anyhow!("chat not found"))?;
    bot_access_verify(pool, caller_iid, row.get("bot_iid")).await?;
    Ok(row.get("owner_iid"))
}

pub async fn bot_peer_msg_list(pool: &PgPool, caller_iid: i64, req: ReqChatMsgList) -> Result<ResChatMsgList> {
    let chat_id = req.chat_id;
    bot_peer_chat_verify(pool, caller_iid, chat_id).await?;
    let limit = if req.limit <= 0 { 100 } else { req.limit.min(500) };
    let before = req.before_id;
    let rows = if before > 0 {
        sqlx::query(
            r#"
            SELECT id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought, attachments, blocks_json,
                   tokens_in, tokens_out, duration_ms, status, cost_usd::float8 AS cost_usd, error_text, created_ts, updated_ts, deleted_ts
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
                   tokens_in, tokens_out, duration_ms, status, cost_usd::float8 AS cost_usd, error_text, created_ts, updated_ts, deleted_ts
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
    let messages = rows.into_iter().map(row_to_msg).collect();
    Ok(ResChatMsgList { messages })
}

pub async fn bot_peer_list(pool: &PgPool, caller_iid: i64, req: ReqBotPeerList) -> Result<ResBotPeerList> {
    bot_access_verify(pool, caller_iid, req.bot_iid).await?;
    let limit = if req.limit <= 0 { 100 } else { req.limit.min(500) };
    let rows = sqlx::query(
        r#"
        SELECT id, kind, owner_iid, title, model, bot_iid, channel_id, peer_key, peer_name, peer_pic,
               ai_reply_enabled, last_msg_ts, last_msg_preview, meta, created_ts, updated_ts, deleted_ts
        FROM ai.chat
        WHERE kind = 'bot_peer' AND bot_iid = $1 AND deleted_ts IS NULL
        ORDER BY last_msg_ts DESC
        LIMIT $2
        "#,
    )
    .bind(req.bot_iid)
    .bind(limit)
    .fetch_all(pool)
    .await?;
    let chats = rows.into_iter().map(row_to_chat).collect();
    Ok(ResBotPeerList { chats })
}

pub async fn chat_stop(pool: &PgPool, caller_iid: i64, req: ReqChatStop) -> Result<ResChatStop> {
    let chat_id = req.chat_id;
    bot_peer_chat_verify(pool, caller_iid, chat_id).await?;
    let ai_reply_enabled = !req.stopped;
    sqlx::query(
        r#"
        UPDATE ai.chat SET ai_reply_enabled = $2, updated_ts = NOW()
        WHERE id = $1 AND kind = 'bot_peer' AND owner_iid = $3 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .bind(ai_reply_enabled)
    .bind(caller_iid)
    .execute(pool)
    .await?;
    Ok(ResChatStop {
        chat_id,
        ai_reply_enabled,
    })
}

pub async fn chat_send(pool: &PgPool, caller_iid: i64, req: ReqChatSend) -> Result<ResChatSend> {
    let chat_id = req.chat_id;
    let owner_iid = bot_peer_chat_verify(pool, caller_iid, chat_id).await?;
    let text = req.text.trim();
    let attachments = serde_json::from_str::<serde_json::Value>(&req.attachments_json)
        .unwrap_or_else(|_| serde_json::json!([]));
    if text.is_empty() && attachments.as_array().is_none_or(|a| a.is_empty()) {
        return Err(anyhow!("text required"));
    }
    let msg_id = snowflake_id();
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (
            id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, status, created_ts, updated_ts
        )
        VALUES ($1, $2, $3, '', $4, 'assistant', 'staff', $5, $6, 'done', NOW(), NOW())
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(caller_iid)
    .bind(text)
    .bind(attachments.clone())
    .execute(&mut *tx)
    .await?;
    let preview: String = text.chars().take(255).collect();
    sqlx::query(
        r#"
        UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1
        "#,
    )
    .bind(chat_id)
    .bind(&preview)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    let row = sqlx::query(
        r#"
        SELECT id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought, attachments, blocks_json,
               tokens_in, tokens_out, duration_ms, status, cost_usd::float8 AS cost_usd, error_text, created_ts, updated_ts, deleted_ts
        FROM ai.chat_msg WHERE id = $1
        "#,
    )
    .bind(msg_id)
    .fetch_one(pool)
    .await?;
    Ok(ResChatSend {
        message: Some(row_to_msg(row)),
    })
}

fn row_to_chat(r: sqlx::postgres::PgRow) -> Chat {
    let meta = r.get::<serde_json::Value, _>("meta");
    Chat {
        id: r.get("id"),
        kind: ChatKind::BotPeer as i32,
        owner_iid: r.get("owner_iid"),
        title: r.get("title"),
        bot_iid: r.get("bot_iid"),
        channel_id: r.get("channel_id"),
        peer_key: r.get("peer_key"),
        peer_name: r.get("peer_name"),
        peer_pic: r.get::<Option<String>, _>("peer_pic").unwrap_or_default(),
        ai_reply_enabled: r.get("ai_reply_enabled"),
        last_msg_ts_ms: ts_ms(r.get("last_msg_ts")),
        last_msg_preview: r.get("last_msg_preview"),
        meta_json: meta.to_string(),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        ..Default::default()
    }
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
