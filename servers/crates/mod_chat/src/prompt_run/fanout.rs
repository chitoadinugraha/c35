use anyhow::Result;
use async_nats::Client;
use c35_proto::{pb_encode, PromptRunPush, ResPromptDelta, ResPromptEnd, ResPromptFail, ResPromptStart, WsRes, ws_res};

pub fn prompt_chat_subject(owner_iid: i64, chat_id: i64) -> String {
    format!("c35.user.{owner_iid}.chat.{chat_id}")
}

async fn prompt_chat_fanout_ws(nats: &Client, owner_iid: i64, chat_id: i64, res: WsRes) -> Result<()> {
    let subject = prompt_chat_subject(owner_iid, chat_id);
    nats.publish(subject, pb_encode(&res).into()).await?;
    Ok(())
}

pub async fn prompt_run_fanout_publish(
    nats: &Client,
    owner_iid: i64,
    chat_id: i64,
    push: PromptRunPush,
) -> Result<()> {
    prompt_chat_fanout_ws(
        nats,
        owner_iid,
        chat_id,
        WsRes {
            req_id: push.req_id.clone(),
            body: Some(ws_res::Body::PromptRunPush(push)),
        },
    )
    .await
}

pub async fn prompt_run_fanout_delta(
    nats: &Client,
    owner_iid: i64,
    chat_id: i64,
    req_id: &str,
    delta: ResPromptDelta,
) -> Result<()> {
    prompt_chat_fanout_ws(
        nats,
        owner_iid,
        chat_id,
        WsRes {
            req_id: req_id.into(),
            body: Some(ws_res::Body::PromptDelta(delta)),
        },
    )
    .await
}

pub async fn prompt_run_fanout_start(
    nats: &Client,
    owner_iid: i64,
    chat_id: i64,
    req_id: &str,
    start: ResPromptStart,
) -> Result<()> {
    prompt_chat_fanout_ws(
        nats,
        owner_iid,
        chat_id,
        WsRes {
            req_id: req_id.into(),
            body: Some(ws_res::Body::PromptStart(start)),
        },
    )
    .await
}

pub async fn prompt_run_fanout_end(
    nats: &Client,
    owner_iid: i64,
    chat_id: i64,
    req_id: &str,
    end: ResPromptEnd,
) -> Result<()> {
    prompt_chat_fanout_ws(
        nats,
        owner_iid,
        chat_id,
        WsRes {
            req_id: req_id.into(),
            body: Some(ws_res::Body::PromptEnd(end)),
        },
    )
    .await
}

pub async fn prompt_run_fanout_fail(
    nats: &Client,
    owner_iid: i64,
    chat_id: i64,
    req_id: &str,
    fail: ResPromptFail,
) -> Result<()> {
    prompt_chat_fanout_ws(
        nats,
        owner_iid,
        chat_id,
        WsRes {
            req_id: req_id.into(),
            body: Some(ws_res::Body::PromptFail(fail)),
        },
    )
    .await
}

pub fn prompt_run_push_from_row(row: &super::store::PromptRunRow) -> PromptRunPush {
    PromptRunPush {
        req_id: row.req_id.clone(),
        parent_req_id: row.parent_req_id.clone().unwrap_or_default(),
        kind: row.kind.clone(),
        device_iid: row.device_iid,
        status: row.status.clone(),
        label: String::new(),
        topic_id: row.topic_id.clone(),
        turn_count: row.turn_count,
        tokens_in: row.tokens_in,
        tokens_out: row.tokens_out,
        cost_usd: row.cost_usd,
        duration_ms: row.duration_ms,
        fail_class: row.fail_class.clone().unwrap_or_default(),
        fail_reason: row.fail_reason.clone().unwrap_or_default(),
    }
}
