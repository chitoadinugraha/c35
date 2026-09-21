pub mod gemini;
pub mod audio;
pub mod llm_route;
pub mod thought;
pub mod time;
pub mod tool_loop;

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
}

#[derive(Debug, Clone, Default)]
pub struct ChatRes {
    pub text: String,
    pub thought: String,
    pub blocks_json: String,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub model_used: String,
}
