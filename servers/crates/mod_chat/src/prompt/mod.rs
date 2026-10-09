pub mod audio;
pub mod gemini;
pub mod hooks;
pub mod llm_route;
pub mod thought;
pub mod time;
pub mod tool_loop;
pub mod user_context;
pub mod web_grounding;

use crate::catalog_web::CatalogWebPhase;
use crate::tools::ToolDef;

#[derive(Debug, Clone, Default)]
pub struct ChatHistoryMsg {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, Default)]
pub struct ChatReq {
    pub model: String,
    pub system: String,
    pub user: String,
    pub thinking: String,
    pub tools: Vec<ToolDef>,
    pub history: Vec<ChatHistoryMsg>,
    /// When true, first tool hop uses Gemini function-calling mode ANY (web-search inst).
    pub force_tool_call: bool,
    pub force_web_tool_call: bool,
    pub catalog_web: CatalogWebPhase,
    pub skip_web_prefetch: bool,
    /// `inst.site.stock_report` matched. The tool loop may answer from SQL with no model hop.
    pub stock_report: bool,
    /// `inst.site.tx_browse` matched. The tool loop may list transactions with no model hop.
    pub tx_browse: bool,
    /// `inst.site.report` matched. Profit / sales summary may run without a model tool hop.
    pub site_report: bool,
}

#[derive(Debug, Clone, Default)]
pub struct ChatRes {
    pub text: String,
    pub thought: String,
    pub blocks_json: String,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub model_used: String,
    pub tools_cost_usd: f64,
}
