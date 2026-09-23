use anyhow::Result;
use c35_proto::{Log, ReqLogList, ResLogList};
use sqlx::{PgPool, Row};

pub async fn log_list(pool: &PgPool, owner_iid: i64, req: ReqLogList) -> Result<ResLogList> {
    let req_id = req.req_id.trim();
    if req_id.is_empty() {
        return Ok(ResLogList { logs: vec![] });
    }
    let limit = if req.limit <= 0 { 200 } else { req.limit.min(500) };
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, kind, topic, dv, req_id, chat_id, task_id, device_iid,
               text, model, tokens_in, tokens_out, duration_ms, cost_usd::float8 AS cost_usd, meta, created_ts, updated_ts, deleted_ts
        FROM ai.log
        WHERE owner_iid = $1 AND req_id = $2 AND deleted_ts IS NULL
        ORDER BY id ASC
        LIMIT $3
        "#,
    )
    .bind(owner_iid)
    .bind(req_id)
    .bind(limit)
    .fetch_all(pool)
    .await?;

    let logs = rows.into_iter().map(row_to_log).collect();
    Ok(ResLogList { logs })
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
    }
}

fn ts_ms(v: Option<chrono::DateTime<chrono::Utc>>) -> i64 {
    v.map(|t| t.timestamp_millis()).unwrap_or(0)
}
