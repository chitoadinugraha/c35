use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::routing::post;
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_chat::{
    mcp_agent_owner_allowed, mcp_prompt_compose, mcp_prompt_run, mcp_tool_exec,
    DEFAULT_TEST_OWNER_IID,
};
use c35_store::snowflake_id;
use serde::Deserialize;
use serde_json::{json, Value};
use subtle::ConstantTimeEq;

const WEAK_MCP_KEYS: &[&str] = &["dev-mcp-agent-key", "dev-mcp-agent-change-me"];

pub fn mcp_agent_enabled() -> bool {
    match std::env::var("C35_MCP_AGENT_ENABLED").ok().as_deref() {
        Some("1") | Some("true") | Some("TRUE") => true,
        Some("0") | Some("false") | Some("FALSE") => false,
        _ => cfg!(debug_assertions),
    }
}

pub fn mcp_agent_router() -> Router<AppState> {
    Router::new().route("/v1/mcp/agent", post(mcp_agent_post))
}

fn mcp_key_configured() -> Option<String> {
    let key = std::env::var("C35_MCP_AGENT_KEY").unwrap_or_default();
    if key.is_empty() {
        return None;
    }
    if WEAK_MCP_KEYS.iter().any(|weak| key == *weak) {
        return None;
    }
    #[cfg(not(debug_assertions))]
    if key.len() < 32 {
        return None;
    }
    Some(key)
}

fn mcp_key_ok(headers: &HeaderMap) -> bool {
    let Some(expected) = mcp_key_configured() else {
        return false;
    };
    let got = headers
        .get("X-C35-Mcp-Key")
        .or_else(|| headers.get("x-c35-mcp-key"))
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");
    expected.as_bytes().ct_eq(got.as_bytes()).into()
}

#[derive(Debug, Deserialize)]
struct McpAgentBody {
    action: String,
    #[serde(default)]
    owner_iid: Option<i64>,
    #[serde(default)]
    tool_name: String,
    #[serde(default)]
    args_json: Value,
    #[serde(default)]
    text: String,
    #[serde(default)]
    locale: String,
    #[serde(default)]
    req_id: String,
    #[serde(default)]
    chat_id: i64,
}

async fn mcp_agent_post(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<McpAgentBody>,
) -> impl IntoResponse {
    if !mcp_key_ok(&headers) {
        return (
            StatusCode::UNAUTHORIZED,
            Json(json!({ "ok": false, "error": "unauthorized" })),
        )
            .into_response();
    }

    let owner_iid = body.owner_iid.unwrap_or(DEFAULT_TEST_OWNER_IID);
    if !mcp_agent_owner_allowed(owner_iid) {
        return (
            StatusCode::FORBIDDEN,
            Json(json!({
                "ok": false,
                "error": format!(
                    "mcp agent actions only allowed for test owner {}",
                    DEFAULT_TEST_OWNER_IID
                ),
                "owner_iid": owner_iid,
            })),
        )
            .into_response();
    }

    let locale = if body.locale.is_empty() {
        "en"
    } else {
        body.locale.as_str()
    };
    let req_id = if body.req_id.is_empty() {
        snowflake_id().to_string()
    } else {
        body.req_id.clone()
    };

    let out = match body.action.as_str() {
        "tool_exec" => {
            if body.tool_name.is_empty() {
                return (
                    StatusCode::BAD_REQUEST,
                    Json(json!({ "ok": false, "error": "tool_name required" })),
                )
                    .into_response();
            }
            mcp_tool_exec(
                &st.pool,
                owner_iid,
                &body.tool_name,
                &body.args_json,
                locale,
                &req_id,
            )
            .await
        }
        "prompt_compose" => {
            if body.text.is_empty() {
                return (
                    StatusCode::BAD_REQUEST,
                    Json(json!({ "ok": false, "error": "text required" })),
                )
                    .into_response();
            }
            mcp_prompt_compose(&st.pool, owner_iid, &body.text, locale).await
        }
        "prompt_run" => {
            if body.text.is_empty() {
                return (
                    StatusCode::BAD_REQUEST,
                    Json(json!({ "ok": false, "error": "text required" })),
                )
                    .into_response();
            }
            mcp_prompt_run(
                &st.pool,
                st.nats.as_ref(),
                owner_iid,
                &body.text,
                locale,
                &req_id,
                body.chat_id,
            )
            .await
        }
        other => {
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "ok": false,
                    "error": format!("unknown action: {other}"),
                    "actions": ["tool_exec", "prompt_compose", "prompt_run"],
                })),
            )
                .into_response();
        }
    };

    (StatusCode::OK, Json(out)).into_response()
}
