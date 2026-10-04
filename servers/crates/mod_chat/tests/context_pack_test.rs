use c35_mod_chat::context_pack::{
    context_pack_history, context_window_options, context_window_resolve, context_window_store, history_prune_for_prompt,
    model_context_limit, token_estimate, HistoryRow, CONTEXT_RECENT_MSG_MIN, CONTEXT_WINDOW_STEPS,
};

#[test]
fn model_limit_gemini() {
    assert_eq!(model_context_limit("gemini-2.0-flash"), 1_048_576);
    assert_eq!(model_context_limit("alienai"), 128_000);
}

#[test]
fn alien_stored_zero_resolves_default() {
    for slug in ["alienai", "auto", "alien", "cloud", ""] {
        assert_eq!(context_window_resolve(slug, 0), 128_000, "{slug}");
    }
    assert_eq!(context_window_resolve("gemini-2.5-pro", 0), 128_000);
    assert_eq!(context_window_resolve("gpt-4o", 0), 128_000);
}

#[test]
fn context_window_picker_and_reject() {
    assert_eq!(context_window_options("alienai"), CONTEXT_WINDOW_STEPS.to_vec());
    assert_eq!(context_window_options("gemini-2.0-flash"), CONTEXT_WINDOW_STEPS.to_vec());
    assert_eq!(context_window_options("gpt-4o"), vec![32_768, 65_536]);
    assert_eq!(context_window_store("alienai", 0).unwrap(), 0);
    assert_eq!(context_window_store("gemini-2.0-flash", 524_288).unwrap(), 524_288);
    assert!(context_window_store("gemini-2.0-flash", 1_048_576).is_err());
    assert!(context_window_store("gpt-4o", 131_072).is_err());
    assert_eq!(context_window_resolve("alienai", 131_072), 131_072);
    assert_eq!(context_window_resolve("gpt-4o", 65_536), 65_536);
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
    let packed = context_pack_history("", &rows, context_window_resolve("alienai", 0), 1000, 500);
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
    let packed = context_pack_history("", &rows, context_window_resolve("alienai", 0), 50_000, 10_000);
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
