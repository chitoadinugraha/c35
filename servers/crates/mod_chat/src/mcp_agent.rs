use c35_proto::{ReqLogList, ReqPrompt};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::compose::compose_tools_and_inst_async;
use crate::inst_cache::inst_list_cached;
use crate::inst_macro::inst_scopes_home;
use crate::log_list::log_list;
use crate::mention::mention_list_enabled;
use crate::mention_context::MentionContext;
use crate::prompt_turn::{prompt_turn, PromptTurnHooks};
use crate::site_capability::SiteCapabilityView;
use crate::tools::{cluster_tools, default_dispatcher, http_client, ToolContext};

pub const DEFAULT_DEBUG_OWNER_IID: i64 = 99000;
pub const DEFAULT_TEST_OWNER_IID: i64 = 33000;

pub fn mcp_agent_owner_allowed(owner_iid: i64) -> bool {
    owner_iid == DEFAULT_TEST_OWNER_IID || owner_iid == DEFAULT_DEBUG_OWNER_IID
}

pub fn mcp_agent_allowed_owners() -> &'static [i64] {
    &[DEFAULT_TEST_OWNER_IID, DEFAULT_DEBUG_OWNER_IID]
}

fn mcp_agent_owner_denied(owner_iid: i64, req_id: &str) -> Value {
    json!({
        "ok": false,
        "error": format!(
            "mcp agent actions only allowed for owner_iid in [{}] (got {})",
            mcp_agent_allowed_owners()
                .iter()
                .map(|i| i.to_string())
                .collect::<Vec<_>>()
                .join(", "),
            owner_iid
        ),
        "owner_iid": owner_iid,
        "req_id": req_id,
        "allowed_owner_iids": mcp_agent_allowed_owners(),
    })
}

async fn mcp_turn_trace(pool: &PgPool, owner_iid: i64, req_id: &str) -> Value {
    let req = ReqLogList {
        req_id: req_id.to_string(),
        limit: 200,
    };
    match log_list(pool, owner_iid, req).await {
        Ok(res) => {
            let lines: Vec<String> = res
                .logs
                .iter()
                .map(|l| {
                    let tag = if l.topic.is_empty() {
                        l.kind.clone()
                    } else {
                        format!("{}/{}", l.kind, l.topic)
                    };
                    let preview = l.text.chars().take(160).collect::<String>();
                    format!(
                        "[{}] req={} {}{} {}",
                        tag,
                        l.req_id,
                        if l.tokens_in > 0 || l.tokens_out > 0 {
                            format!(" in={} out={}", l.tokens_in, l.tokens_out)
                        } else {
                            String::new()
                        },
                        if l.duration_ms > 0 {
                            format!(" {}ms", l.duration_ms)
                        } else {
                            String::new()
                        },
                        preview
                    )
                })
                .collect();
            let trace: Vec<Value> = res
                .logs
                .iter()
                .map(|l| {
                    json!({
                        "kind": l.kind,
                        "topic": l.topic,
                        "text": l.text,
                        "model": l.model,
                        "tokens_in": l.tokens_in,
                        "tokens_out": l.tokens_out,
                        "duration_ms": l.duration_ms,
                        "cost_usd": l.cost_usd,
                        "meta": serde_json::from_str::<Value>(&l.meta_json).unwrap_or(json!({})),
                    })
                })
                .collect();
            json!({
                "count": res.logs.len(),
                "lines": lines,
                "trace": trace,
            })
        }
        Err(e) => json!({
            "count": 0,
            "lines": [],
            "trace": [],
            "error": e.to_string(),
        }),
    }
}

pub async fn mcp_tool_exec(
    pool: &PgPool,
    owner_iid: i64,
    tool_name: &str,
    args_json: &Value,
    locale: &str,
    req_id: &str,
) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return mcp_agent_owner_denied(owner_iid, req_id);
    }
    let http = http_client(std::time::Duration::from_secs(30));
    let ctx = ToolContext::new(
        pool.clone(),
        None,
        owner_iid,
        0,
        None,
        MentionContext::empty(),
        vec![],
        "",
        locale,
        "",
        "",
        "",
        "[]",
        req_id,
        http,
    );
    let (result, cost) = default_dispatcher()
        .execute(tool_name, args_json.clone(), &ctx)
        .await;
    json!({
        "ok": true,
        "owner_iid": owner_iid,
        "tool_name": tool_name,
        "req_id": req_id,
        "result": result,
        "cost_usd": cost,
    })
}

pub async fn mcp_prompt_compose(pool: &PgPool, owner_iid: i64, text: &str, locale: &str) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return mcp_agent_owner_denied(owner_iid, "");
    }
    let inst_rows = inst_list_cached();
    let mentions = mention_list_enabled(pool).await;
    let inst_scopes = inst_scopes_home();
    let http = http_client(std::time::Duration::from_secs(30));
    let composed = compose_tools_and_inst_async(
        pool,
        &http,
        &inst_rows,
        text,
        cluster_tools(),
        &[],
        &[],
        &["general".into()],
        "agent",
        &mentions,
        &inst_scopes,
        &MentionContext::empty(),
        &SiteCapabilityView::empty(),
    )
    .await;
    let selected_tools: Vec<String> = composed.tools.iter().map(|t| t.name.clone()).collect();
    json!({
        "ok": true,
        "owner_iid": owner_iid,
        "locale": locale,
        "inst_ids": composed.matched_ids,
        "inst_block": inst_block_preview(&composed.inst_block),
        "selected_tools": selected_tools,
        "trace": composed.trace,
    })
}

pub async fn mcp_prompt_run(
    pool: &PgPool,
    nats: Option<&async_nats::Client>,
    owner_iid: i64,
    text: &str,
    locale: &str,
    req_id: &str,
    chat_id: i64,
) -> Value {
    if !mcp_agent_owner_allowed(owner_iid) {
        return mcp_agent_owner_denied(owner_iid, req_id);
    }
    let req = ReqPrompt {
        chat_id,
        model: String::new(),
        text: text.to_string(),
        attachments_json: String::new(),
        thinking: String::new(),
        mention_ids: vec![],
        topic_id: String::new(),
        tool_mode: "agent".into(),
        device_iids: vec![],
    };
    let cancel = CancellationToken::new();
    let hooks = PromptTurnHooks {
        skip_billing_gate: true,
        on_hop: None,
    };
    match prompt_turn(
        pool,
        nats,
        owner_iid,
        req_id,
        req,
        locale,
        |_thought, _delta| {},
        |_blocks| {},
        &cancel,
        hooks,
    )
    .await
    {
        Ok(turn) => {
            let trace = mcp_turn_trace(pool, owner_iid, req_id).await;
            json!({
                "ok": true,
                "req_id": req_id,
                "owner_iid": owner_iid,
                "chat_id": turn.chat_id,
                "user_msg_id": turn.user_msg_id,
                "assistant_msg_id": turn.assistant_msg_id,
                "text": turn.text,
                "thought": turn.thought,
                "blocks_json": turn.blocks_json,
                "tokens_in": turn.tokens_in,
                "tokens_out": turn.tokens_out,
                "cost_usd": turn.cost_usd,
                "model": turn.model,
                "duration_ms": turn.duration_ms,
                "error_text": turn.error_text,
                "trace": trace,
            })
        }
        Err(e) => json!({
            "ok": false,
            "error": e.to_string(),
            "req_id": req_id,
            "owner_iid": owner_iid,
        }),
    }
}

fn inst_block_preview(block: &str) -> String {
    const MAX: usize = 2000;
    if block.len() <= MAX {
        return block.to_string();
    }
    let mut out = block.chars().take(MAX).collect::<String>();
    out.push_str("…");
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mcp_agent_owner_allowed_test_and_debug() {
        assert!(mcp_agent_owner_allowed(DEFAULT_TEST_OWNER_IID));
        assert!(mcp_agent_owner_allowed(DEFAULT_DEBUG_OWNER_IID));
        assert!(!mcp_agent_owner_allowed(12345));
    }
}
