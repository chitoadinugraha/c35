use c35_mod_chat::context_compact::{should_compact, summary_merge, title_refresh_allowed};
use c35_mod_chat::context_pack::{
    context_pack_history, context_window_resolve, history_rows_tokens, HistoryRow, CONTEXT_RECENT_MSG_MAX,
};
use c35_mod_chat::chat_title_from_text;

#[test]
fn should_compact_over_threshold() {
    let window = context_window_resolve("alienai", 0);
    assert_eq!(window, 128_000);
    assert!(should_compact(window, 10_000, 5_000, 80_000, 2_000));
    assert!(!should_compact(window, 1_000, 500, 5_000, 500));
    let edge = (window as f64 * 0.70) as i32;
    assert!(should_compact(window, edge, 0, 0, 0));
    assert!(!should_compact(window, edge - 1, 0, 0, 0));
}

#[test]
fn full_history_compacts_when_packed_tail_is_small() {
    let window = context_window_resolve("alienai", 0);
    let mut rows = Vec::new();
    for i in 0..CONTEXT_RECENT_MSG_MAX {
        rows.push(HistoryRow {
            id: i as i64,
            role: "user".into(),
            content: format!("recent {i}"),
            blocks_json: "[]".into(),
        });
    }
    for i in 0..50 {
        rows.push(HistoryRow {
            id: (100 + i) as i64,
            role: "user".into(),
            content: "x".repeat(8_000),
            blocks_json: "[]".into(),
        });
    }
    let packed = context_pack_history("", &rows, window, 1_000, 500);
    let packed_history = packed.tokens_est;
    let full = history_rows_tokens(&rows);
    assert!(packed.messages.len() <= CONTEXT_RECENT_MSG_MAX);
    assert!(full > packed_history);
    assert!(!should_compact(window, 1_000, 0, packed_history, 500));
    assert!(should_compact(window, 1_000, 0, full, 500));
}

#[test]
fn title_refresh_respects_lock_and_auto_title() {
    let auto = chat_title_from_text("hello there");
    let open = serde_json::json!({});
    let locked = serde_json::json!({"title_locked": true});
    assert!(title_refresh_allowed(&open, "Chat", "hello there"));
    assert!(title_refresh_allowed(&open, "", "hello there"));
    assert!(title_refresh_allowed(&open, &auto, "hello there"));
    assert!(!title_refresh_allowed(&open, "Lunch at home", "hello there"));
    assert!(!title_refresh_allowed(&locked, "Chat", "hello there"));
    assert!(!title_refresh_allowed(&locked, &auto, "hello there"));
}

#[test]
fn summary_merge_preserves_both() {
    let m = summary_merge("user likes IDR", "decided to use site ABC");
    assert!(m.contains("IDR"));
    assert!(m.contains("ABC"));
}
