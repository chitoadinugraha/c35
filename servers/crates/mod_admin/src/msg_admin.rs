use crate::{require_root, AdminError};
use serde_json::{json, Value};
use sqlx::{PgPool, QueryBuilder, Row};

pub async fn admin_msg_get(
    pool: &PgPool,
    viewer_iid: i64,
    msg_id: i64,
    req_id: &str,
    owner_iid: i64,
) -> Result<Value, AdminError> {
    require_root(pool, viewer_iid).await?;
    let rid = req_id.trim();
    if msg_id <= 0 && rid.is_empty() {
        return Err(AdminError::bad("msg_id or req_id required"));
    }
    if owner_iid <= 0 {
        return Err(AdminError::bad("subject_uid (owner_iid) required"));
    }
    if msg_id > 0 {
        let row = sqlx::query(
            r#"
            SELECT id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought,
                   attachments, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd::float8 AS cost_usd,
                   status, created_ts, updated_ts
            FROM ai.chat_msg
            WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
            LIMIT 1
            "#,
        )
        .bind(msg_id)
        .bind(owner_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
        let Some(r) = row else {
            return Err(AdminError::bad("message not found"));
        };
        let msg = msg_row_json(&r);
        let turn_req = r.get::<String, _>("req_id");
        let trace = admin_trace_rows(pool, &turn_req, owner_iid).await?;
        return Ok(json!({
            "ok": true,
            "message": msg,
            "trace": trace,
        }));
    }
    let rows = sqlx::query(
        r#"
        SELECT id, chat_id, owner_iid, req_id, sender_iid, role, source, content, thought,
               attachments, blocks_json, tokens_in, tokens_out, duration_ms, cost_usd::float8 AS cost_usd,
               status, created_ts, updated_ts
        FROM ai.chat_msg
        WHERE req_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        ORDER BY created_ts ASC, id ASC
        "#,
    )
    .bind(rid)
    .bind(owner_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    let messages: Vec<Value> = rows.iter().map(msg_row_json).collect();
    let trace = admin_trace_rows(pool, rid, owner_iid).await?;
    Ok(json!({
        "ok": true,
        "req_id": rid,
        "messages": messages,
        "trace": trace,
    }))
}

pub async fn admin_msg_find(
    pool: &PgPool,
    viewer_iid: i64,
    owner_iid: i64,
    q: &str,
    chat_id: i64,
    limit: i32,
) -> Result<Value, AdminError> {
    require_root(pool, viewer_iid).await?;
    let query = q.trim();
    if query.is_empty() {
        return Err(AdminError::bad("q required"));
    }
    if owner_iid <= 0 {
        return Err(AdminError::bad("subject_uid (owner_iid) required"));
    }
    let lim = if limit <= 0 { 20 } else { limit.min(50) };
    let mut qb = QueryBuilder::new(
        r#"
        SELECT id, chat_id, owner_iid, req_id, role, left(content, 240) AS preview, created_ts
        FROM ai.chat_msg
        WHERE deleted_ts IS NULL AND owner_iid =
        "#,
    );
    qb.push_bind(owner_iid);
    qb.push(" AND content ILIKE ");
    qb.push_bind(format!("%{}%", query));
    if chat_id > 0 {
        qb.push(" AND chat_id = ");
        qb.push_bind(chat_id);
    }
    qb.push(" ORDER BY created_ts DESC, id DESC LIMIT ");
    qb.push_bind(lim);
    let rows = qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let messages: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.get::<i64, _>("id"),
                "chat_id": r.get::<i64, _>("chat_id"),
                "owner_iid": r.get::<i64, _>("owner_iid"),
                "req_id": r.get::<String, _>("req_id"),
                "role": r.get::<String, _>("role"),
                "preview": r.get::<String, _>("preview"),
                "created_ts_ms": ts_ms(r.get("created_ts")),
            })
        })
        .collect();
    Ok(json!({
        "ok": true,
        "owner_iid": owner_iid,
        "q": query,
        "count": messages.len(),
        "messages": messages,
    }))
}

pub async fn admin_log_trace(
    pool: &PgPool,
    viewer_iid: i64,
    req_id: &str,
    owner_iid: i64,
    limit: i32,
) -> Result<Value, AdminError> {
    require_root(pool, viewer_iid).await?;
    let rid = req_id.trim();
    if rid.is_empty() {
        return Err(AdminError::bad("req_id required"));
    }
    let lim = if limit <= 0 { 200 } else { limit.min(500) };
    let mut qb = QueryBuilder::new(
        r#"
        SELECT id, owner_iid, kind, topic, dv, req_id, chat_id, task_id, device_iid,
               text, model, tokens_in, tokens_out, duration_ms, cost_usd::float8 AS cost_usd, meta,
               event_kind, subject, class, created_ts, updated_ts, deleted_ts
        FROM ai.log
        WHERE deleted_ts IS NULL AND req_id =
        "#,
    );
    qb.push_bind(rid);
    if owner_iid > 0 {
        qb.push(" AND owner_iid = ");
        qb.push_bind(owner_iid);
    }
    qb.push(" ORDER BY created_ts ASC, id ASC LIMIT ");
    qb.push_bind(lim);
    let rows = qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let logs: Vec<Value> = rows.iter().map(log_row_json).collect();
    let lines: Vec<String> = rows.iter().map(log_compact_line).collect();
    Ok(json!({
        "ok": true,
        "req_id": rid,
        "owner_iid": if owner_iid > 0 { json!(owner_iid) } else { json!(null) },
        "count": logs.len(),
        "lines": lines,
        "trace": logs,
    }))
}

async fn admin_trace_rows(pool: &PgPool, req_id: &str, owner_iid: i64) -> Result<Vec<Value>, AdminError> {
    if req_id.is_empty() {
        return Ok(vec![]);
    }
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, kind, topic, dv, req_id, chat_id, task_id, device_iid,
               text, model, tokens_in, tokens_out, duration_ms, cost_usd::float8 AS cost_usd, meta,
               event_kind, subject, class, created_ts, updated_ts, deleted_ts
        FROM ai.log
        WHERE deleted_ts IS NULL AND req_id = $1 AND owner_iid = $2
        ORDER BY created_ts ASC, id ASC
        LIMIT 500
        "#,
    )
    .bind(req_id)
    .bind(owner_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(rows.iter().map(log_row_json).collect())
}

fn msg_row_json(r: &sqlx::postgres::PgRow) -> Value {
    json!({
        "id": r.get::<i64, _>("id"),
        "chat_id": r.get::<i64, _>("chat_id"),
        "owner_iid": r.get::<i64, _>("owner_iid"),
        "req_id": r.get::<String, _>("req_id"),
        "sender_iid": r.get::<i64, _>("sender_iid"),
        "role": r.get::<String, _>("role"),
        "source": r.get::<String, _>("source"),
        "content": r.get::<String, _>("content"),
        "thought": r.get::<Option<String>, _>("thought").unwrap_or_default(),
        "attachments": r.get::<serde_json::Value, _>("attachments"),
        "blocks_json": r.get::<serde_json::Value, _>("blocks_json"),
        "tokens_in": r.get::<i32, _>("tokens_in"),
        "tokens_out": r.get::<i32, _>("tokens_out"),
        "duration_ms": r.get::<i32, _>("duration_ms"),
        "cost_usd": r.get::<f64, _>("cost_usd"),
        "status": r.get::<String, _>("status"),
        "created_ts_ms": ts_ms(r.get("created_ts")),
        "updated_ts_ms": ts_ms(r.get("updated_ts")),
    })
}

fn log_row_json(r: &sqlx::postgres::PgRow) -> Value {
    let meta = r.get::<serde_json::Value, _>("meta");
    json!({
        "id": r.get::<i64, _>("id"),
        "owner_iid": r.get::<i64, _>("owner_iid"),
        "kind": r.get::<String, _>("kind"),
        "topic": r.get::<Option<String>, _>("topic").unwrap_or_default(),
        "req_id": r.get::<String, _>("req_id"),
        "text": r.get::<String, _>("text"),
        "model": r.get::<Option<String>, _>("model").unwrap_or_default(),
        "tokens_in": r.get::<i32, _>("tokens_in"),
        "tokens_out": r.get::<i32, _>("tokens_out"),
        "duration_ms": r.get::<i32, _>("duration_ms"),
        "cost_usd": r.get::<f64, _>("cost_usd"),
        "event_kind": r.get::<Option<String>, _>("event_kind").unwrap_or_default(),
        "class": r.get::<Option<String>, _>("class").unwrap_or_default(),
        "subject": r.get::<Option<String>, _>("subject").unwrap_or_default(),
        "meta": c35_mod_log::log_meta_redact(&meta),
        "created_ts_ms": ts_ms(r.get("created_ts")),
    })
}

fn log_compact_line(r: &sqlx::postgres::PgRow) -> String {
    let kind = r.get::<String, _>("kind");
    let topic = r.get::<Option<String>, _>("topic").unwrap_or_default();
    let event_kind = r.get::<Option<String>, _>("event_kind").unwrap_or_default();
    let class = r.get::<Option<String>, _>("class").unwrap_or_default();
    let tag = if !event_kind.is_empty() {
        format!("{}/{}", class, event_kind)
    } else if !topic.is_empty() {
        format!("{}/{}", kind, topic)
    } else {
        kind
    };
    let req_id = r.get::<String, _>("req_id");
    let text = r.get::<String, _>("text");
    let preview = text.chars().take(160).collect::<String>();
    let tokens_in = r.get::<i32, _>("tokens_in");
    let tokens_out = r.get::<i32, _>("tokens_out");
    let duration_ms = r.get::<i32, _>("duration_ms");
    format!(
        "[{}] req={}{}{} {}",
        tag,
        req_id,
        if tokens_in > 0 || tokens_out > 0 {
            format!(" in={} out={}", tokens_in, tokens_out)
        } else {
            String::new()
        },
        if duration_ms > 0 {
            format!(" {}ms", duration_ms)
        } else {
            String::new()
        },
        preview
    )
}

fn ts_ms(v: Option<chrono::DateTime<chrono::Utc>>) -> i64 {
    v.map(|t| t.timestamp_millis()).unwrap_or(0)
}
