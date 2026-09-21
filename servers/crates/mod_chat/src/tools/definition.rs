use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use serde_json::Value;

use super::context::ToolContext;

/// Optional UI localization keys for tool status labels.
#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct ToolUiKeys {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ui_label_key: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ui_calling_key: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ui_done_key: Option<String>,
}

/// Canonical definition of an AI tool conforming to standard JSON Schema.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ToolDefinition {
    pub name: String,
    pub description: String,
    pub parameters: Value,
    #[serde(default)]
    pub cost_wholesale: f64,
    #[serde(default)]
    pub aliases: Vec<String>,
    #[serde(default)]
    pub sensitive: bool,
    /// Read-only tools stay available in ask mode (no writes).
    #[serde(default)]
    pub readonly: bool,
    /// Topic IDs this tool applies to; empty means all topics.
    #[serde(default)]
    pub topics: Vec<String>,
    /// Topic IDs where this tool is always included regardless of RAG selection.
    #[serde(default)]
    pub always: Vec<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ui_keys: Option<ToolUiKeys>,
}

/// Unified trait implemented by all cluster tools.
#[async_trait]
pub trait Tool: Send + Sync {
    fn definition(&self) -> ToolDefinition;

    async fn execute(&self, args: Value, ctx: &ToolContext) -> Result<Value>;
}
