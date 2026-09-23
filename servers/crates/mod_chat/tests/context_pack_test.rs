use c35_mod_chat::context_pack::{
    context_pack_history, history_prune_for_prompt, model_context_limit, token_estimate, HistoryRow,
    CONTEXT_RECENT_MSG_MIN,
};

#[test]
fn model_limit_gemini() {
    assert_eq!(model_context_limit("gemini-2.0-flash"), 1_000_000);
    assert_eq!(model_context_limit("alienai"), 128_000);
}

#[test]
fn prune_strips_blocks_hint() {
    let out = history_prune_for_prompt("hello", "[{\"type\":\"tool\"}]");
    assert!(out.contains("tool output omitted"));
}

#[test]
fn pack_keeps_minimum_recent() {
    let rows: Vec<HistoryRow> = (0..10)
        .map(|i| HistoryRow {
            id: i as i64,
            role: "user".into(),
            content: format!("message {i} with some text"),
            blocks_json: "[]".into(),
        })
        .collect();
    let packed = context_pack_history("", &rows, "alienai", 1000, 500);
    assert!(packed.messages.len() >= CONTEXT_RECENT_MSG_MIN);
}

#[test]
fn pack_respects_budget() {
    let rows: Vec<HistoryRow> = (0..20)
        .map(|i| HistoryRow {
            id: i as i64,
            role: "user".into(),
            content: "x".repeat(4000),
            blocks_json: "[]".into(),
        })
        .collect();
    let packed = context_pack_history("", &rows, "alienai", 50_000, 10_000);
    assert!(packed.messages.len() < rows.len());
}

#[test]
fn summary_prefix() {
    use c35_mod_chat::context_pack::history_with_summary;
    use c35_mod_chat::prompt::ChatHistoryMsg;
    let msgs = history_with_summary("prior topic", &[ChatHistoryMsg { role: "user".into(), content: "hi".into() }]);
    assert_eq!(msgs.len(), 2);
    assert!(msgs[0].content.contains("CONVERSATION SUMMARY"));
}

#[test]
fn token_estimate_nonempty() {
    assert!(token_estimate("hello world") > 0);
    assert_eq!(token_estimate(""), 0);
}
