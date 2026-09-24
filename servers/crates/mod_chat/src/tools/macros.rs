//! The `tool!` macro for defining tools with JSON Schema and async execution.

#[macro_export]
macro_rules! tool {
    (
        struct: $struct_name:ident,
        name: $name:expr,
        $(aliases: [$($alias:expr),* $(,)?],)?
        description: $desc:expr,
        $(topics: [$($topic:expr),* $(,)?],)?
        $(always: [$($always_topic:expr),* $(,)?],)?
        $(rag_phrases: [$($rag_phrase:expr),* $(,)?],)?
        $(requires_kinds: [$($kind:expr),* $(,)?],)?
        $(requires_capability: $capability:expr,)?
        $(ui_label_key: $ui_label:expr,)?
        $(ui_calling_key: $ui_calling:expr,)?
        $(ui_done_key: $ui_done:expr,)?
        $(cost_wholesale: $cost:expr,)?
        $(sensitive: $sensitive:expr,)?
        $(readonly: $readonly:expr,)?
        parameters: {
            $($param_name:ident: ($param_type:ident, $param_desc:expr $(, $req:ident)? $(, default = $def:expr)?)),* $(,)?
        },
        execute: |$args:ident, $ctx:ident| $body:expr
    ) => {
        #[derive(Debug, Clone, Copy, Default)]
        pub struct $struct_name;

        #[async_trait::async_trait]
        impl $crate::tools::Tool for $struct_name {
            fn definition(&self) -> $crate::tools::ToolDefinition {
                #[allow(unused_mut)]
                let mut properties = serde_json::Map::new();
                #[allow(unused_mut)]
                let mut required: Vec<serde_json::Value> = Vec::new();

                $(
                    #[allow(unused_mut)]
                    let mut prop = serde_json::json!({
                        "type": stringify!($param_type),
                        "description": $param_desc,
                    });
                    $(
                        prop["default"] = serde_json::json!($def);
                    )?
                    if stringify!($param_type) == "array" {
                        prop["items"] = serde_json::json!({ "type": "object" });
                    }
                    properties.insert(stringify!($param_name).to_string(), prop);

                    $crate::tool_param_req!(required, stringify!($param_name) $(, $req)?);
                )*

                let parameters = serde_json::json!({
                    "type": "object",
                    "properties": properties,
                    "required": required,
                });

                #[allow(unused_mut)]
                let mut aliases: Vec<String> = Vec::new();
                $($(
                    aliases.push($alias.to_string());
                )*)?

                #[allow(unused_mut)]
                let mut topics: Vec<String> = Vec::new();
                $($(
                    topics.push($topic.to_string());
                )*)?

                #[allow(unused_mut)]
                let mut always: Vec<String> = Vec::new();
                $($(
                    always.push($always_topic.to_string());
                )*)?

                #[allow(unused_mut)]
                let mut rag_phrases: Vec<String> = Vec::new();
                $($(
                    rag_phrases.push($rag_phrase.to_string());
                )*)?

                #[allow(unused_mut)]
                let mut requires_kinds: Vec<String> = Vec::new();
                $($(
                    requires_kinds.push($kind.to_string());
                )*)?

                let requires_capability: Option<String> = [
                    $(Some($capability.to_string()),)?
                ]
                .first()
                .cloned()
                .flatten();

                #[allow(unused_mut)]
                let mut ui_keys = $crate::tools::ToolUiKeys::default();
                $(ui_keys.ui_label_key = Some($ui_label.to_string());)?
                $(ui_keys.ui_calling_key = Some($ui_calling.to_string());)?
                $(ui_keys.ui_done_key = Some($ui_done.to_string());)?
                let ui_keys = if ui_keys.ui_label_key.is_some()
                    || ui_keys.ui_calling_key.is_some()
                    || ui_keys.ui_done_key.is_some()
                {
                    Some(ui_keys)
                } else {
                    None
                };

                let cost_wholesale = 0.0 $(+ $cost)?;
                let sensitive = false $(|| $sensitive)?;
                let readonly = false $(|| $readonly)?;

                $crate::tools::ToolDefinition {
                    name: $name.to_string(),
                    description: $desc.to_string(),
                    parameters,
                    cost_wholesale,
                    aliases,
                    sensitive,
                    readonly,
                    topics,
                    always,
                    rag_phrases,
                    requires_kinds,
                    requires_capability,
                    ui_keys,
                }
            }

            async fn execute(
                &self,
                $args: serde_json::Value,
                $ctx: &$crate::tools::ToolContext,
            ) -> anyhow::Result<serde_json::Value> {
                $body
            }
        }
    };
}

#[macro_export]
macro_rules! tool_param_req {
    ($req_vec:ident, $name:expr, required) => {
        $req_vec.push(serde_json::json!($name));
    };
    ($req_vec:ident, $name:expr, optional) => {};
    ($req_vec:ident, $name:expr) => {};
}
