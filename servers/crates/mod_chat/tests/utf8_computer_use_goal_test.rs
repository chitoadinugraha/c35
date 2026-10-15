//! Regression: augmented Google Sheets computer_use goals must not panic on UTF-8 (em dash in playbook).

use c35_mod_chat::context_compact::summary_merge;
use c35_mod_chat::context_pack::history_prune_for_prompt;
use c35_mod_chat::prompt::google_sheets::{
    google_sheets_min_tool_counts, google_sheets_playbook_block, user_text_looks_like_google_sheets_desktop,
};
use c35_mod_chat::prompt::tool_loop::truncate_large_tool_payload;
use c35_mod_chat::utterance_site_phrase;

fn augmented_sheets_goal() -> String {
    let goal = "Buka Google Sheets 'Test Anggota', cari sel A3, dan ubah isinya jadi 'Estes'. \
Pasitikan layer terlihat jelas sebelum melakukan tindakan.";
    format!("{goal}\n\n{}", google_sheets_playbook_block())
}

#[test]
fn sheets_augmented_goal_prepare_path_string_ops_do_not_panic() {
    let goal = augmented_sheets_goal();
    assert!(user_text_looks_like_google_sheets_desktop(&goal));
    assert!(goal.contains('\u{2014}') || goal.contains("Tables"));
    let _ = google_sheets_min_tool_counts(&goal);
    let _ = utterance_site_phrase(&goal);
    let _ = history_prune_for_prompt(&goal, "[]");
    let merged = summary_merge("", &goal);
    assert!(!merged.is_empty());
}

#[test]
fn history_prune_em_dash_past_12k_bytes() {
    let mut content = "x".repeat(12_000);
    content.push('\u{2014}');
    content.push_str("yz");
    let out = history_prune_for_prompt(&content, "[]");
    assert!(out.ends_with('\u{2026}'));
}

#[test]
fn summary_merge_em_dash_past_8k_bytes() {
    let mut block = "a".repeat(7_997);
    block.push('\u{2014}');
    block.push_str("zzz");
    let out = summary_merge("", &block);
    assert!(out.ends_with('\u{2026}'));
}

#[test]
fn truncate_large_tool_payload_counts_chars_not_bytes() {
    let mut v = serde_json::Value::String("1".repeat(25_000));
    truncate_large_tool_payload(&mut v, 24_000);
    let s = v.as_str().expect("string");
    assert!(s.contains("truncated"));
    assert!(s.chars().count() <= 24_000 + 80);
}
