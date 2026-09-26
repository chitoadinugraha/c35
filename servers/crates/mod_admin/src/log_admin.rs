use crate::{require_root, AdminError};
use c35_proto::{Log, ReqAdminLogList, ResAdminLogList};
use sqlx::{PgPool, QueryBuilder, Row};

pub async fn admin_log_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminLogList,
) -> Result<ResAdminLogList, AdminError> {
    require_root(pool, viewer_iid).await?;
    let limit = if req.limit <= 0 { 200 } else { req.limit.min(500) };
    let mut qb = QueryBuilder::new(
        r#"
        SELECT id, owner_iid, kind, topic, dv, req_id, chat_id, task_id, device_iid,
               text, model, tokens_in, tokens_out, duration_ms, cost_usd::float8 AS cost_usd, meta,
               event_kind, subject, class, created_ts, updated_ts, deleted_ts
        FROM ai.log
        WHERE deleted_ts IS NULL
        "#,
    );
    if req.exclude_trace {
        qb.push(" AND class IN ('event', 'error')");
    }
    if let Some(event_kind) = req.event_kind.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        qb.push(" AND event_kind = ");
        qb.push_bind(event_kind);
    }
    if let Some(class) = req.class.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        qb.push(" AND class = ");
        qb.push_bind(class);
    }
    if let Some(prefix) = req.subject_prefix.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        qb.push(" AND subject LIKE ");
        qb.push_bind(format!("{}%", prefix));
    }
    if let Some(owner_iid) = req.owner_iid {
        qb.push(" AND owner_iid = ");
        qb.push_bind(owner_iid);
    }
    if req.since_ms > 0 {
        qb.push(" AND created_ts >= ");
        qb.push_bind(ms_to_ts(req.since_ms));
    }
    if req.until_ms > 0 {
        qb.push(" AND created_ts <= ");
        qb.push_bind(ms_to_ts(req.until_ms));
    }
    if let Some(kind) = req.kind.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        qb.push(" AND kind = ");
        qb.push_bind(kind);
    }
    if let Some(topic) = req.topic.as_ref().map(|s| s.trim()).filter(|s| !s.is_empty()) {
        qb.push(" AND topic = ");
        qb.push_bind(topic);
    }
    if !req.text.trim().is_empty() {
        qb.push(" AND text ILIKE ");
        qb.push_bind(format!("%{}%", req.text.trim()));
    }
    if let Some(before_id) = req.before_id {
        qb.push(" AND id < ");
        qb.push_bind(before_id);
    }
    qb.push(" ORDER BY created_ts DESC, id DESC LIMIT ");
    qb.push_bind(limit);
    let rows = qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    let logs = rows.into_iter().map(row_to_log).collect();
    Ok(ResAdminLogList { logs })
}

fn ms_to_ts(ms: i64) -> chrono::DateTime<chrono::Utc> {
    chrono::DateTime::from_timestamp_millis(ms).unwrap_or_else(chrono::Utc::now)
}

fn row_to_log(r: sqlx::postgres::PgRow) -> Log {
    let meta = r.get::<serde_json::Value, _>("meta");
    Log {
        id: r.get("id"),
        owner_iid: r.get("owner_iid"),
        kind: r.get::<String, _>("kind"),
        topic: r.get::<Option<String>, _>("topic").unwrap_or_default(),
        dv: r.get::<Option<String>, _>("dv").unwrap_or_default(),
        req_id: r.get::<String, _>("req_id"),
        chat_id: r.get::<Option<i64>, _>("chat_id").unwrap_or(0),
        task_id: r.get::<Option<i64>, _>("task_id").unwrap_or(0),
        device_iid: r.get::<Option<i64>, _>("device_iid").unwrap_or(0),
        text: r.get::<String, _>("text"),
        model: r.get::<Option<String>, _>("model").unwrap_or_default(),
        tokens_in: r.get("tokens_in"),
        tokens_out: r.get("tokens_out"),
        duration_ms: r.get("duration_ms"),
        cost_usd: r.get("cost_usd"),
        meta_json: meta.to_string(),
        created_ts_ms: ts_ms(r.get("created_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
        deleted_ts_ms: ts_ms(r.get("deleted_ts")),
        event_kind: r.get::<Option<String>, _>("event_kind").unwrap_or_default(),
        class: r.get::<Option<String>, _>("class").unwrap_or_default(),
        subject: r.get::<Option<String>, _>("subject").unwrap_or_default(),
    }
}

fn ts_ms(v: Option<chrono::DateTime<chrono::Utc>>) -> i64 {
    v.map(|t| t.timestamp_millis()).unwrap_or(0)
}
