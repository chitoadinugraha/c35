pub mod builtin;
pub mod context;
pub mod definition;
pub mod dispatcher;
pub mod egress_http;
pub mod device_screenshot_artifact;
pub mod img;
pub mod image_tier;
pub mod media;
pub mod music;
pub mod vid;
pub mod macros;
pub mod web;

use std::sync::{Arc, Mutex, OnceLock};
use std::time::Duration;

use reqwest::Client;
use serde_json::{json, Value};
use sqlx::PgPool;

pub use context::ToolContext;
pub use definition::{Tool, ToolDefinition, ToolUiKeys};
pub use dispatcher::{tool_topic_eligible, ToolDispatcher};

use crate::mention_context::MentionContext;

use builtin::{
    BotDraftTool, BotInboxQueryTool, BrowserFileUploadTool, BrowserPageActTool, BrowserPageExtractTool, BrowserPageObserveTool,
    BrowserAgentRestartTool, BrowserExtensionTool, BrowserPageScreenshotTool,
    BrowserSheetsAppendRowTool, BrowserSheetsCellSetTool, BrowserSheetsRowSetTool,
    BrowserSheetsRangeReadTool, BrowserTabsTool,
    BrowserTaskRunTool, DriveListTool,
    DriveReadTool, GsheetAppendTool,
    GsheetReadTool, GsheetUpdateTool, ComputerUseDelegateTool, ConsumptionAddTool,
    ConsumptionDeleteTool, ConsumptionTodayTool,
    ConsumptionUpdateTool, DelegateRunTool, DeviceFsListTool, DeviceFsReadTool, ShellRunTool,
    DeviceInputTool, DeviceScreenshotTool,
    ExpenseAddTool, ExpenseDeleteTool, ExpenseSummaryTool, ImgEditTool, ImgGenerateTool, MusicGenerateTool,
    VidGenerateTool,
    ChatMessagesTool, ChatSearchTool, MemoryForgetTool, MemoryListTool, MemorySaveTool,
    PresentationCreateTool, PresentationExportTool, PresentationPatchTool,
    PresentationSourceExtractTool, PresentationSourceStructureTool,
    PresentationVideoExtractTool, PresentationVideoStructureTool,
    ReferralCodeDeleteTool, ReferralCodeListTool, ReferralCodePutTool, ReferralTreeGetTool, SiteContactPutTool,
    SiteCreateTool, SiteDomainPutTool, SiteDomainVerifyTool, SiteDraftGetTool, SiteDraftPutTool,
    SiteHandleUpdateTool, SiteObjectPutTool, SiteOrderStatusTool, SitePatchTool, SiteProductPatchTool,
    SiteProductPutTool, SitePublishTool, SiteQueryRunTool,
    SiteTxDebtPayTool, SiteTxListTool, SiteTxPreviewTool, SiteTxPutTool, TaskRunCancelDeviceTool,
    TaskRunCancelTool, TaskRunStartTool, TaskRunStatusTool, WebResearchTool, WebSearchTool,
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
    pub rag_phrases: Vec<String>,
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
            rag_phrases: vec![],
        }
    }

    pub fn from_definition(def: &ToolDefinition) -> Self {
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
            rag_phrases: def.rag_phrases.clone(),
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
    pub mention_ids: &'a [String],
    pub user_text: &'a str,
    pub locale: &'a str,
    pub location_city: &'a str,
    pub location_region: &'a str,
    pub location_country: &'a str,
    pub attachments_json: &'a str,
    pub req_id: &'a str,
    pub run_kind: &'a str,
    pub checkpoint: Option<&'a mut serde_json::Value>,
    pub title_slot: Arc<Mutex<Option<String>>>,
}

fn build_default_dispatcher() -> ToolDispatcher {
    let dispatcher = ToolDispatcher::new();
    dispatcher.register(Arc::new(DriveListTool));
    dispatcher.register(Arc::new(DriveReadTool));
    dispatcher.register(Arc::new(GsheetReadTool));
    dispatcher.register(Arc::new(GsheetAppendTool));
    dispatcher.register(Arc::new(GsheetUpdateTool));
    dispatcher.register(Arc::new(BotDraftTool));
    dispatcher.register(Arc::new(BotInboxQueryTool));
    dispatcher.register(Arc::new(WebSearchTool));
    dispatcher.register(Arc::new(WebVisitTool));
    dispatcher.register(Arc::new(WebResearchTool));
    dispatcher.register(Arc::new(ImgGenerateTool));
    dispatcher.register(Arc::new(ImgEditTool));
    dispatcher.register(Arc::new(VidGenerateTool));
    dispatcher.register(Arc::new(MusicGenerateTool));
    dispatcher.register(Arc::new(PresentationCreateTool));
    dispatcher.register(Arc::new(PresentationPatchTool));
    dispatcher.register(Arc::new(PresentationExportTool));
    dispatcher.register(Arc::new(PresentationSourceStructureTool));
    dispatcher.register(Arc::new(PresentationSourceExtractTool));
    dispatcher.register(Arc::new(PresentationVideoStructureTool));
    dispatcher.register(Arc::new(PresentationVideoExtractTool));
    dispatcher.register(Arc::new(ConsumptionAddTool));
    dispatcher.register(Arc::new(ConsumptionTodayTool));
    dispatcher.register(Arc::new(ConsumptionUpdateTool));
    dispatcher.register(Arc::new(ConsumptionDeleteTool));
    dispatcher.register(Arc::new(ExpenseAddTool));
    dispatcher.register(Arc::new(ExpenseSummaryTool));
    dispatcher.register(Arc::new(ExpenseDeleteTool));
    dispatcher.register(Arc::new(BrowserTaskRunTool));
    dispatcher.register(Arc::new(BrowserPageObserveTool));
    dispatcher.register(Arc::new(BrowserPageScreenshotTool));
    dispatcher.register(Arc::new(BrowserPageExtractTool));
    dispatcher.register(Arc::new(BrowserPageActTool));
    dispatcher.register(Arc::new(BrowserTabsTool));
    dispatcher.register(Arc::new(BrowserAgentRestartTool));
    dispatcher.register(Arc::new(BrowserExtensionTool));
    dispatcher.register(Arc::new(BrowserSheetsAppendRowTool));
    dispatcher.register(Arc::new(BrowserSheetsCellSetTool));
    dispatcher.register(Arc::new(BrowserSheetsRowSetTool));
    dispatcher.register(Arc::new(BrowserSheetsRangeReadTool));
    dispatcher.register(Arc::new(BrowserFileUploadTool));
    dispatcher.register(Arc::new(ShellRunTool));
    dispatcher.register(Arc::new(DeviceFsListTool));
    dispatcher.register(Arc::new(DeviceFsReadTool));
    dispatcher.register(Arc::new(DeviceInputTool));
    dispatcher.register(Arc::new(DeviceScreenshotTool));
    dispatcher.register(Arc::new(SiteCreateTool));
    dispatcher.register(Arc::new(SitePatchTool));
    dispatcher.register(Arc::new(SiteHandleUpdateTool));
    dispatcher.register(Arc::new(SiteDraftGetTool));
    dispatcher.register(Arc::new(SiteDraftPutTool));
    dispatcher.register(Arc::new(SitePublishTool));
    dispatcher.register(Arc::new(SiteDomainPutTool));
    dispatcher.register(Arc::new(SiteDomainVerifyTool));
    dispatcher.register(Arc::new(SiteProductPutTool));
    dispatcher.register(Arc::new(SiteProductPatchTool));
    dispatcher.register(Arc::new(SiteContactPutTool));
    dispatcher.register(Arc::new(SiteObjectPutTool));
    dispatcher.register(Arc::new(SiteQueryRunTool));
    dispatcher.register(Arc::new(SiteTxPutTool));
    dispatcher.register(Arc::new(SiteTxPreviewTool));
    dispatcher.register(Arc::new(SiteOrderStatusTool));
    dispatcher.register(Arc::new(SiteTxDebtPayTool));
    dispatcher.register(Arc::new(SiteTxListTool));
    dispatcher.register(Arc::new(ReferralCodePutTool));
    dispatcher.register(Arc::new(ReferralCodeListTool));
    dispatcher.register(Arc::new(ReferralCodeDeleteTool));
    dispatcher.register(Arc::new(ReferralTreeGetTool));
    dispatcher.register(Arc::new(DelegateRunTool));
    dispatcher.register(Arc::new(ComputerUseDelegateTool));
    dispatcher.register(Arc::new(TaskRunStartTool));
    dispatcher.register(Arc::new(TaskRunCancelTool));
    dispatcher.register(Arc::new(TaskRunCancelDeviceTool));
    dispatcher.register(Arc::new(ChatSearchTool));
    dispatcher.register(Arc::new(ChatMessagesTool));
    dispatcher.register(Arc::new(MemorySaveTool));
    dispatcher.register(Arc::new(MemoryForgetTool));
    dispatcher.register(Arc::new(MemoryListTool));
    dispatcher.register(Arc::new(TaskRunStatusTool));
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

pub fn cluster_tool_def(name: &str) -> Option<ToolDef> {
    default_dispatcher()
        .get(name)
        .map(|t| ToolDef::from_definition(&t.definition()))
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
        turn.mention_ids.to_vec(),
        turn.user_text,
        turn.locale,
        turn.location_city,
        turn.location_region,
        turn.location_country,
        turn.attachments_json,
        turn.req_id,
        client,
    )
    .with_title_slot(turn.title_slot.clone())
}

pub async fn cluster_tool_exec(
    client: &Client,
    name: &str,
    args: &Value,
    ctx: Option<&TurnCtx<'_>>,
    tool_call_id: Option<&str>,
) -> (Value, f64) {
    let dispatcher = default_dispatcher();
    let tool_ctx = match ctx {
        Some(turn) => {
            let mut tc = tool_context_from_turn(client.clone(), turn);
            if let Some(id) = tool_call_id {
                tc = tc.with_tool_call_id(id);
            }
            tc
        }
        None => ToolContext::new(
            PgPool::connect_lazy("postgres://unused").expect("lazy pool"),
            None,
            0,
            0,
            None,
            MentionContext::empty(),
            vec![],
            "",
            "en",
            "",
            "",
            "",
            "",
            "",
            client.clone(),
        ),
    };
    dispatcher.execute(name, args.clone(), &tool_ctx).await
}
