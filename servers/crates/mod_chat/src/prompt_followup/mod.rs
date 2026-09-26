mod store;

use anyhow::{anyhow, Result};
use c35_mod_billing::billing_followup_caps;
use c35_proto::{
    PromptFollowupKind, PromptFollowupPush, PromptFollowupRow, ResPromptFollowupCancel,
    ResPromptFollowupList, ResPromptFollowupPut,
};
use async_nats::Client;
use c35_proto::PromptRunJob;
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::PgPool;

use c35_proto::ResPromptStart;
use crate::prompt_run::{
    prompt_followup_fanout_push, prompt_run_enqueue, prompt_run_fanout_publish, prompt_run_fanout_start,
    prompt_run_get, prompt_run_insert, prompt_run_push_from_row, prompt_run_row_new,
};

pub use store::{
    prompt_followup_active_req, prompt_followup_cancel, prompt_followup_cancel_all_for_req,
    prompt_followup_drain_steers, prompt_followup_list_pending, prompt_followup_mark_queue_delivered,
    prompt_followup_next_queued, prompt_followup_pop_delivered_queue, FollowupRow,
};

pub fn prompt_followup_enabled() -> bool {
    !matches!(
        std::env::var("C35_PROMPT_FOLLOWUP").ok().as_deref(),
        Some("0") | Some("false")
    )
}

fn kind_wire(s: &str) -> i32 {
    match s {
        "steer" => PromptFollowupKind::Steer as i32,
        "queue" => PromptFollowupKind::Queue as i32,
        _ => PromptFollowupKind::Unspecified as i32,
    }
}

fn row_to_proto(r: &FollowupRow) -> PromptFollowupRow {
    PromptFollowupRow {
        id: r.id.clone(),
        req_id: r.req_id.clone(),
        chat_id: r.chat_id,
        kind: kind_wire(&r.kind),
        status: r.status.clone(),
        text: r.text.clone(),
        seq: r.seq,
        created_ts_ms: r.created_ts.timestamp_millis(),
    }
}

pub async fn prompt_followup_put(
    pool: &PgPool,
    owner_iid: i64,
    chat_id: i64,
    req_id_hint: &str,
    text: &str,
    attachments_json: &str,
    kind: i32,
    source: &str,
    external_dedup_key: Option<&str>,
) -> Result<ResPromptFollowupPut> {
    if !prompt_followup_enabled() {
        return Ok(rejected_put("", "", "disabled"));
    }
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Ok(rejected_put("", "", "empty_text"));
    }
    let req_id = if req_id_hint.is_empty() {
        prompt_followup_active_req(pool, chat_id)
            .await?
            .ok_or_else(|| anyhow!("no_active_run"))?
    } else {
        req_id_hint.to_string()
    };
    if let Some(key) = external_dedup_key.filter(|s| !s.is_empty()) {
        if store::prompt_followup_dedup_exists(pool, key).await? {
            return Ok(rejected_put("", &req_id, "duplicate"));
        }
    }
    let caps = billing_followup_caps(pool, owner_iid).await?;
    let kind_enum = PromptFollowupKind::try_from(kind).unwrap_or(PromptFollowupKind::Steer);
    let kind_str = match kind_enum {
        PromptFollowupKind::Queue => "queue",
        PromptFollowupKind::Steer | PromptFollowupKind::Unspecified => "steer",
    };
    if kind_str == "queue" && caps.queue_max <= 0 {
        return Ok(rejected_put("", &req_id, "plan_cap"));
    }
    let pending_queue = store::prompt_followup_pending_count(pool, &req_id, "queue").await?;
    if kind_str == "queue" && pending_queue >= caps.queue_max {
        return Ok(rejected_put("", &req_id, "queue_full"));
    }
    let steer_used = store::prompt_followup_steer_used(pool, &req_id).await?;
    let pending_steer = store::prompt_followup_pending_count(pool, &req_id, "steer").await?;
    if kind_str == "steer" && steer_used + pending_steer >= caps.steer_max {
        return Ok(rejected_put("", &req_id, "steer_cap"));
    }
    let id = snowflake_id().to_string();
    let seq = store::prompt_followup_next_seq(pool, &req_id).await?;
    store::prompt_followup_insert(
        pool,
        &id,
        &req_id,
        chat_id,
        owner_iid,
        seq,
        kind_str,
        trimmed,
        attachments_json,
        source,
        external_dedup_key,
    )
    .await?;
    let queue_depth = store::prompt_followup_pending_count(pool, &req_id, "queue").await?;
    Ok(ResPromptFollowupPut {
        id,
        req_id,
        queue_depth,
        rejected: false,
        reject_reason: String::new(),
    })
}

fn rejected_put(id: &str, req_id: &str, reason: &str) -> ResPromptFollowupPut {
    ResPromptFollowupPut {
        id: id.into(),
        req_id: req_id.into(),
        queue_depth: 0,
        rejected: true,
        reject_reason: reason.into(),
    }
}

pub async fn prompt_followup_list(
    pool: &PgPool,
    chat_id: i64,
    req_id_hint: &str,
) -> Result<ResPromptFollowupList> {
    let active = if req_id_hint.is_empty() {
        prompt_followup_active_req(pool, chat_id).await?
    } else {
        Some(req_id_hint.to_string())
    };
    let items = if let Some(rid) = active.as_deref() {
        prompt_followup_list_pending(pool, rid)
            .await?
            .iter()
            .map(row_to_proto)
            .collect()
    } else {
        vec![]
    };
    Ok(ResPromptFollowupList {
        items,
        active_req_id: active.unwrap_or_default(),
    })
}

pub async fn prompt_followup_cancel_rpc(
    pool: &PgPool,
    owner_iid: i64,
    id: &str,
) -> Result<(ResPromptFollowupCancel, Option<(i64, String)>)> {
    let meta = store::prompt_followup_meta(pool, id).await?;
    let ok = prompt_followup_cancel(pool, owner_iid, id).await?;
    let notify = meta
        .filter(|(_, o, _)| *o == owner_iid)
        .map(|(chat_id, _, req_id)| (chat_id, req_id));
    Ok((ResPromptFollowupCancel { ok }, notify))
}

pub fn prompt_followup_push_from_list(active_req_id: &str, rows: &[FollowupRow]) -> PromptFollowupPush {
    PromptFollowupPush {
        active_req_id: active_req_id.into(),
        items: rows.iter().map(row_to_proto).collect(),
    }
}

/// Append drained steer texts to Gemini `contents` conversation.
pub async fn prompt_followup_publish_state(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    chat_id: i64,
    req_id: &str,
) -> Result<()> {
    let Some(nats) = nats else { return Ok(()) };
    let rows = prompt_followup_list_pending(pool, req_id).await?;
    let push = prompt_followup_push_from_list(req_id, &rows);
    prompt_followup_fanout_push(nats, owner_iid, chat_id, push).await?;
    Ok(())
}

/// After a turn finishes, start the next queued follow-up as a new `prompt_run` (FIFO, one per call).
pub async fn prompt_followup_start_next_queued(
    pool: &PgPool,
    nats: &Client,
    finished_req_id: &str,
) -> Result<Option<String>> {
    if !prompt_followup_enabled() {
        return Ok(None);
    }
    let Some(parent) = prompt_run_get(pool, finished_req_id).await? else {
        return Ok(None);
    };
    let Some(q) = prompt_followup_next_queued(pool, finished_req_id).await? else {
        return Ok(None);
    };
    prompt_followup_mark_queue_delivered(pool, &q.id).await?;
    let new_req_id = snowflake_id().to_string();
    let user_msg_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, attachments, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, $3, 'user', 'prompt', $5, $6, NOW(), NOW())
        "#,
    )
    .bind(user_msg_id)
    .bind(parent.chat_id)
    .bind(parent.owner_iid)
    .bind(&new_req_id)
    .bind(&q.text)
    .bind(&q.attachments_json)
    .execute(pool)
    .await?;
    chat_touch_preview(pool, parent.chat_id, parent.owner_iid, &q.text, "streaming").await?;
    let mut req = parent.to_req_prompt();
    req.text = q.text.clone();
    req.attachments_json = q.attachments_json.clone();
    let row = prompt_run_row_new(&new_req_id, parent.owner_iid, parent.chat_id, &req, &parent.locale);
    prompt_run_insert(pool, &row).await?;
    let job = PromptRunJob {
        req_id: new_req_id.clone(),
        owner_iid: parent.owner_iid,
        chat_id: parent.chat_id,
    };
    prompt_run_enqueue(nats, &job).await?;
    let _ = prompt_run_fanout_start(
        nats,
        parent.owner_iid,
        parent.chat_id,
        &new_req_id,
        ResPromptStart {
            chat_id: parent.chat_id,
            msg_id: user_msg_id,
            model: row.model.clone(),
        },
    )
    .await;
    let _ = prompt_run_fanout_publish(nats, parent.owner_iid, parent.chat_id, prompt_run_push_from_row(&row)).await;
    let _ = prompt_followup_publish_state(pool, Some(nats), parent.owner_iid, parent.chat_id, &new_req_id).await;
    let _ = prompt_followup_publish_state(pool, Some(nats), parent.owner_iid, parent.chat_id, finished_req_id).await;
    Ok(Some(new_req_id))
}

async fn chat_touch_preview(pool: &PgPool, chat_id: i64, owner_iid: i64, preview: &str, status: &str) -> Result<()> {
    let p: String = preview.chars().take(255).collect();
    sqlx::query(
        r#"UPDATE ai.chat SET last_msg_ts = NOW(), last_msg_preview = $2, updated_ts = NOW() WHERE id = $1"#,
    )
    .bind(chat_id)
    .bind(&p)
    .execute(pool)
    .await?;
    sqlx::query(
        r#"
        UPDATE ai.chat_member SET last_msg_ts = NOW(), last_msg_preview = $2, last_msg_status = $4, updated_ts = NOW()
        WHERE chat_id = $1 AND member_iid = $3
        "#,
    )
    .bind(chat_id)
    .bind(&p)
    .bind(owner_iid)
    .bind(status)
    .execute(pool)
    .await?;
    Ok(())
}

pub fn prompt_followup_append_to_contents(contents: &mut Vec<Value>, steer_texts: &[String]) {
    for t in steer_texts {
        let body = format!(
            "[MID-RUN USER REFINEMENT — continue the same task with this guidance]\n{}",
            t
        );
        contents.push(json!({ "role": "user", "parts": [{ "text": body }] }));
    }
}
