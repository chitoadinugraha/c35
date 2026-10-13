use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Correlated automation RPC (CE-A1) — wire JSON uses dotted `op` names (`tabs.list`, …).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtRpcRequest {
    pub req_id: String,
    pub op: String,
    #[serde(default)]
    pub params: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtRpcResponse {
    pub req_id: String,
    pub ok: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub result: Option<Value>,
}

impl ExtRpcResponse {
    pub fn ok(req_id: impl Into<String>, result: Value) -> Self {
        Self {
            req_id: req_id.into(),
            ok: true,
            error: None,
            result: Some(result),
        }
    }

    pub fn err(req_id: impl Into<String>, error: impl Into<String>) -> Self {
        Self {
            req_id: req_id.into(),
            ok: false,
            error: Some(error.into()),
            result: None,
        }
    }
}

pub fn ipc_is_rpc_request(v: &Value) -> bool {
    v.get("req_id").and_then(|x| x.as_str()).is_some()
        && v.get("op").and_then(|x| x.as_str()).map(|o| o.contains('.')).unwrap_or(false)
        && !v.get("ok").is_some()
}

pub fn ipc_is_rpc_response(v: &Value) -> bool {
    v.get("req_id").and_then(|x| x.as_str()).is_some() && v.get("ok").is_some()
}

#[derive(Debug, Deserialize)]
pub struct ExtRequest {
    #[serde(alias = "type", alias = "command")]
    pub cmd: String,
    #[serde(default)]
    pub device_name: Option<String>,
    #[serde(default)]
    pub width: Option<u16>,
    #[serde(default)]
    pub height: Option<u16>,
    #[serde(default)]
    pub jpeg_b64: Option<String>,
    #[serde(default)]
    pub tab_id: Option<String>,
    #[serde(flatten)]
    pub extra: Value,
}

#[derive(Debug, Serialize)]
pub struct ExtResponse {
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pong: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expires_in_sec: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub device_iid: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tabs: Option<Value>,
    #[serde(flatten)]
    pub data: Value,
}

impl ExtResponse {
    pub fn ok() -> Self {
        Self {
            ok: true,
            error: None,
            pong: None,
            code: None,
            expires_in_sec: None,
            status: None,
            device_iid: None,
            tabs: None,
            data: Value::Null,
        }
    }

    pub fn err(msg: impl Into<String>) -> Self {
        Self {
            ok: false,
            error: Some(msg.into()),
            pong: None,
            code: None,
            expires_in_sec: None,
            status: None,
            device_iid: None,
            tabs: None,
            data: Value::Null,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExtPush {
    #[serde(rename = "type")]
    pub cmd: String,
    #[serde(default)]
    pub tab_id: Option<String>,
    #[serde(flatten)]
    pub extra: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "op", rename_all = "snake_case")]
pub enum AgentIpcMsg {
    Frame {
        width: u16,
        height: u16,
        jpeg_b64: String,
    },
    CaptureStart,
    CaptureStop,
    TabsList,
    TabsActivate { tab_id: String },
    TabsResult { value: Value },
    Ping,
    Pong,
    StatusQuery,
    StatusResult {
        ws_connected: bool,
        webrtc_sessions: usize,
        webrtc_connecting: bool,
        device_iid: i64,
        agent_version: String,
        server_url: String,
        log_lines: Vec<String>,
    },
}