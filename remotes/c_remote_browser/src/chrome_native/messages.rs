use serde::{Deserialize, Serialize};
use serde_json::Value;

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
    pub cmd: String,
    #[serde(default)]
    pub tab_id: Option<String>,
    #[serde(flatten)]
    pub extra: Value,
}

#[derive(Debug, Serialize, Deserialize)]
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
}