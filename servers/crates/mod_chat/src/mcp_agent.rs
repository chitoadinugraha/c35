use c35_proto::ReqPrompt;
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio_util::sync::CancellationToken;

use crate::compose::compose_tools_and_inst;
use crate::inst_cache::inst_list_cached;
use crate::inst_macro::inst_scopes_home;
use crate::mention::mention_list_enabled;
use crate::mention_context::MentionContext;
use crate::prompt_turn::{prompt_turn, PromptTurnHooks};
use crate::site_capability::SiteCapabilityView;
use crate::tools::{cluster_tools, default_dispatcher, http_client, ToolContext};

pub const DEFAULT_DEBUG_OWNER_IID: i64 = 99000;
pub const DEFAULT_TEST_OWNER_IID: i64 = 33000;

pub fn mcp_agent_owner_allowed(owner_iid: i64) -> bool {
    owner_iid == DEFAULT_TEST_OWNER_IID
}

fn mcp_agent_owner_denied(owner_iid: i64, req_id: &str) -> Value {
    json!({
        "ok": false,
        "error": format!(
            "mcp agent actions only allowed for test owner {}",
            DEFAULT_TEST_OWNER_IID
        ),
        "owner_iid": owner_iid,
        "req_id": req_id,
    })
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
        locale,
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
    let composed = compose_tools_and_inst(
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
    );
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
        Ok(turn) => json!({
            "ok": true,
            "req_id": req_id,
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
        }),
        Err(e) => json!({
            "ok": false,
            "error": e.to_string(),
            "req_id": req_id,
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
