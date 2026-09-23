pub mod builtin;
pub mod context;
pub mod definition;
pub mod dispatcher;
pub mod egress_http;
pub mod img;
pub mod macros;
pub mod web;

use std::sync::{Arc, OnceLock};
use std::time::Duration;

use reqwest::Client;
use serde_json::{json, Value};
use sqlx::PgPool;

pub use context::ToolContext;
pub use definition::{Tool, ToolDefinition, ToolUiKeys};
pub use dispatcher::{tool_topic_eligible, ToolDispatcher};

use crate::mention_context::MentionContext;

use builtin::{
    ComputerUseDelegateTool, ConsumptionAddTool, ConsumptionTodayTool, ConsumptionUpdateTool,
    DelegateRunTool, DeviceCommandTool, DeviceInputTool, DeviceScreenshotTool, ImgGenerateTool,
    ReferralCodeDeleteTool, ReferralCodeListTool, ReferralCodePutTool, ReferralTreeGetTool,
    SiteContactPutTool, SiteDraftPutTool, SiteObjectPutTool, SiteProductPutTool, SitePublishTool,
    SiteQueryRunTool, SiteTxDebtPayTool, SiteTxListTool, SiteTxPreviewTool, SiteTxPutTool,
    WebResearchTool, WebSearchTool,
    WebVisitTool,
};

#[derive(Debug, Clone)]
pub struct ToolDef {
    pub name: String,
    pub description: String,
    pub parameters: Value,
    pub aliases: Vec<String>,
    pub topics: Vec<String>,
    pub always: Vec<String>,
    pub readonly: bool,
    pub requires_kinds: Vec<String>,
    pub requires_capability: Option<String>,
}

impl ToolDef {
    pub fn new(name: String, description: String, parameters: Value) -> Self {
        Self {
            name,
            description,
            parameters,
            aliases: vec![],
            topics: vec![],
            always: vec![],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        }
    }

    fn from_definition(def: &ToolDefinition) -> Self {
        Self {
            name: def.name.clone(),
            description: def.description.clone(),
            parameters: def.parameters.clone(),
            aliases: def.aliases.clone(),
            topics: def.topics.clone(),
            always: def.always.clone(),
            readonly: def.readonly,
            requires_kinds: def.requires_kinds.clone(),
            requires_capability: def.requires_capability.clone(),
        }
    }
}

pub struct TurnCtx<'a> {
    pub pool: &'a PgPool,
    pub nats: Option<&'a async_nats::Client>,
    pub owner_iid: i64,
    pub chat_id: i64,
    pub site_iid: Option<i64>,
    pub mention: MentionContext,
    pub locale: &'a str,
    pub attachments_json: &'a str,
    pub req_id: &'a str,
    pub run_kind: &'a str,
    pub checkpoint: Option<&'a mut serde_json::Value>,
}

fn build_default_dispatcher() -> ToolDispatcher {
    let dispatcher = ToolDispatcher::new();
    dispatcher.register(Arc::new(WebSearchTool));
    dispatcher.register(Arc::new(WebVisitTool));
    dispatcher.register(Arc::new(WebResearchTool));
    dispatcher.register(Arc::new(ImgGenerateTool));
    dispatcher.register(Arc::new(ConsumptionAddTool));
    dispatcher.register(Arc::new(ConsumptionTodayTool));
    dispatcher.register(Arc::new(ConsumptionUpdateTool));
    dispatcher.register(Arc::new(DeviceCommandTool));
    dispatcher.register(Arc::new(DeviceInputTool));
    dispatcher.register(Arc::new(DeviceScreenshotTool));
    dispatcher.register(Arc::new(SiteDraftPutTool));
    dispatcher.register(Arc::new(SitePublishTool));
    dispatcher.register(Arc::new(SiteProductPutTool));
    dispatcher.register(Arc::new(SiteContactPutTool));
    dispatcher.register(Arc::new(SiteObjectPutTool));
    dispatcher.register(Arc::new(SiteQueryRunTool));
    dispatcher.register(Arc::new(SiteTxPutTool));
    dispatcher.register(Arc::new(SiteTxPreviewTool));
    dispatcher.register(Arc::new(SiteTxDebtPayTool));
    dispatcher.register(Arc::new(SiteTxListTool));
    dispatcher.register(Arc::new(ReferralCodePutTool));
    dispatcher.register(Arc::new(ReferralCodeListTool));
    dispatcher.register(Arc::new(ReferralCodeDeleteTool));
    dispatcher.register(Arc::new(ReferralTreeGetTool));
    dispatcher.register(Arc::new(DelegateRunTool));
    dispatcher.register(Arc::new(ComputerUseDelegateTool));
    dispatcher
}

static DEFAULT_DISPATCHER: OnceLock<ToolDispatcher> = OnceLock::new();

pub fn default_dispatcher() -> ToolDispatcher {
    DEFAULT_DISPATCHER
        .get_or_init(build_default_dispatcher)
        .clone()
}

pub fn cluster_tools() -> Vec<ToolDef> {
    default_dispatcher()
        .definitions()
        .iter()
        .map(ToolDef::from_definition)
        .collect()
}

pub fn cluster_tool_name(name: &str) -> String {
    default_dispatcher()
        .get(name)
        .map(|t| t.definition().name.clone())
        .unwrap_or_else(|| name.replace('_', "."))
}

pub fn tool_decls(tools: &[ToolDef]) -> Value {
    let decls = tools
        .iter()
        .map(|t| {
            json!({
                "name": t.name.replace('.', "_"),
                "description": t.description,
                "parameters": t.parameters
            })
        })
        .collect::<Vec<_>>();
    json!([{ "functionDeclarations": decls }])
}

pub fn http_client(timeout: Duration) -> Client {
    egress_http::http_client(timeout)
}

fn tool_context_from_turn(client: Client, turn: &TurnCtx<'_>) -> ToolContext {
    ToolContext::new(
        turn.pool.clone(),
        turn.nats.cloned(),
        turn.owner_iid,
        turn.chat_id,
        turn.site_iid,
        turn.mention.clone(),
        turn.locale,
        turn.attachments_json,
        turn.req_id,
        client,
    )
}

pub async fn cluster_tool_exec(
    client: &Client,
    name: &str,
    args: &Value,
    ctx: Option<&TurnCtx<'_>>,
) -> (Value, f64) {
    let dispatcher = default_dispatcher();
    let tool_ctx = match ctx {
        Some(turn) => tool_context_from_turn(client.clone(), turn),
        None => ToolContext::new(
            PgPool::connect_lazy("postgres://unused").expect("lazy pool"),
            None,
            0,
            0,
            None,
            MentionContext::empty(),
            "en",
            "",
            "",
            client.clone(),
        ),
    };
    dispatcher.execute(name, args.clone(), &tool_ctx).await
}
