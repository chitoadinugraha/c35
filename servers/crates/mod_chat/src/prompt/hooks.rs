#[derive(Clone, Debug)]
pub struct PromptHopCheckpoint {
    pub hop: i32,
    pub turn_count: i32,
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    pub blocks_json: String,
    pub fail_class: String,
    pub checkpoint_json: String,
}
