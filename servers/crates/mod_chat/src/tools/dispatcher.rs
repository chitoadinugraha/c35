use std::sync::Arc;

use dashmap::DashMap;
use serde_json::{json, Value};
use tracing::info;

use super::context::ToolContext;
use super::definition::{Tool, ToolDefinition};

/// Whether a tool is eligible for the given topic (topics / always filter).
pub fn tool_topic_eligible(def: &ToolDefinition, topic_id: &str) -> bool {
    if def.always.iter().any(|t| t == "*" || t == topic_id) {
        return true;
    }
    def.topics.is_empty()
        || def
            .topics
            .iter()
            .any(|t| t == topic_id || t == "*" || t == "general")
}

/// Registers and invokes cluster builtin tools.
#[derive(Clone, Default)]
pub struct ToolDispatcher {
    tools: Arc<DashMap<String, Arc<dyn Tool>>>,
    aliases: Arc<DashMap<String, String>>,
}

impl ToolDispatcher {
    pub fn new() -> Self {
        Self {
            tools: Arc::new(DashMap::new()),
            aliases: Arc::new(DashMap::new()),
        }
    }

    pub fn register(&self, tool: Arc<dyn Tool>) {
        let def = tool.definition();
        let primary_name = def.name.clone();

        self.tools.insert(primary_name.clone(), tool);

        for alias in &def.aliases {
            self.aliases.insert(alias.clone(), primary_name.clone());
        }

        if primary_name.contains('_') {
            let dot_name = primary_name.replace('_', ".");
            self.aliases.insert(dot_name, primary_name.clone());
        } else if primary_name.contains('.') {
            let underscore_name = primary_name.replace('.', "_");
            self.aliases.insert(underscore_name, primary_name.clone());
        }

        info!("Registered tool '{}' (aliases: {:?})", primary_name, def.aliases);
    }

    pub fn get(&self, name: &str) -> Option<Arc<dyn Tool>> {
        if let Some(tool) = self.tools.get(name) {
            return Some(tool.value().clone());
        }
        if let Some(target) = self.aliases.get(name) {
            if let Some(tool) = self.tools.get(target.value()) {
                return Some(tool.value().clone());
            }
        }
        None
    }

    pub fn definitions(&self) -> Vec<ToolDefinition> {
        self.tools.iter().map(|item| item.value().definition()).collect()
    }

    pub async fn execute(&self, name: &str, args: Value, ctx: &ToolContext) -> (Value, f64) {
        let tool = match self.get(name) {
            Some(t) => t,
            None => {
                return (
                    json!({
                        "ok": false,
                        "runner": "cluster",
                        "error": format!("unknown cluster tool: {}", name),
                    }),
                    0.0,
                );
            }
        };

        let def = tool.definition();
        match tool.execute(args, ctx).await {
            Ok(output) => {
                let ok = output.get("ok").and_then(|v| v.as_bool()).unwrap_or(true);
                let cost_usd = if ok {
                    if def.cost_wholesale > 0.0 {
                        c35_mod_billing::billing_to_retail_usd(def.cost_wholesale)
                    } else {
                        c35_mod_billing::billing_tool_cost_usd(&def.name, true)
                    }
                } else {
                    0.0
                };
                (output, cost_usd)
            }
            Err(e) => (
                json!({
                    "ok": false,
                    "runner": "cluster",
                    "tool": def.name,
                    "error": e.to_string(),
                }),
                0.0,
            ),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tools::ToolUiKeys;

    fn def(topics: &[&str], always: &[&str]) -> ToolDefinition {
        ToolDefinition {
            name: "test.tool".into(),
            description: "test".into(),
            parameters: json!({}),
            cost_wholesale: 0.0,
            aliases: vec![],
            sensitive: false,
            readonly: false,
            topics: topics.iter().map(|s| s.to_string()).collect(),
            always: always.iter().map(|s| s.to_string()).collect(),
            requires_kinds: vec![],
            requires_capability: None,
            ui_keys: None,
        }
    }

    #[test]
    fn tool_topic_eligible_wildcard() {
        assert!(tool_topic_eligible(&def(&["*"], &[]), "billing"));
        assert!(tool_topic_eligible(&def(&[], &[]), "anything"));
        assert!(tool_topic_eligible(&def(&["general"], &[]), "general"));
        assert!(!tool_topic_eligible(&def(&["billing"], &[]), "chat"));
    }

    #[test]
    fn tool_topic_eligible_always() {
        assert!(tool_topic_eligible(&def(&["billing"], &["*"]), "chat"));
        assert!(tool_topic_eligible(&def(&["billing"], &["chat"]), "chat"));
        assert!(!tool_topic_eligible(&def(&["billing"], &["chat"]), "other"));
    }

    #[test]
    fn tool_ui_keys_optional() {
        let keys = ToolUiKeys {
            ui_label_key: Some("tool.web_search".into()),
            ui_calling_key: None,
            ui_done_key: Some("tool.web_search.done".into()),
        };
        assert_eq!(keys.ui_label_key.as_deref(), Some("tool.web_search"));
    }
}
