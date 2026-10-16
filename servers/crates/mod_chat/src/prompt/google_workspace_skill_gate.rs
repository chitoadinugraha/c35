//! Tiered injection: full device skill markdown only when URL/history or open/edit intent warrants it.

use crate::context_pack::HistoryRow;
use crate::prompt::google_docs::user_text_looks_like_docs_format_intent;
use crate::prompt::google_sheets::{
    user_text_looks_like_google_sheets_desktop, user_text_looks_like_sheet_format_intent,
    user_text_looks_like_spreadsheet_cell_ref_edit,
};
use crate::prompt::google_slides::user_text_looks_like_slides_format_intent;

const RECENT_CONTEXT_CAP: usize = 12_000;

/// Recent chat text for URL / observation hints (compose runs before this turn's screenshot).
pub fn compose_device_recent_context(
    summary: &str,
    last_assistant: Option<&str>,
    rows: &[HistoryRow],
) -> String {
    let mut buf = String::new();
    if !summary.trim().is_empty() {
        buf.push_str(summary.trim());
        buf.push('\n');
    }
    if let Some(c) = last_assistant {
        if !c.trim().is_empty() {
            buf.push_str(c.trim());
            buf.push('\n');
        }
    }
    for row in rows.iter().rev().take(10) {
        if !row.content.trim().is_empty() {
            buf.push_str(row.content.trim());
            buf.push('\n');
        }
        let b = row.blocks_json.as_str();
        if b.contains("docs.google.com") || b.contains("sheets.new") || b.contains("slides.new") {
            buf.push_str(b);
            buf.push('\n');
        }
    }
    if buf.len() > RECENT_CONTEXT_CAP {
        buf.truncate(RECENT_CONTEXT_CAP);
    }
    buf
}

fn combined_lower(user_text: &str, recent: &str) -> String {
    let mut s = user_text.to_string();
    if !recent.is_empty() {
        s.push('\n');
        s.push_str(recent);
    }
    s.to_ascii_lowercase()
}

fn open_or_operate_intent(t: &str) -> bool {
    t.contains("open ")
        || t.contains("buka ")
        || t.contains("launch")
        || t.contains("go to ")
        || t.contains("goto ")
        || t.contains("create ")
        || t.contains("buat ")
        || t.contains("new doc")
        || t.contains("new sheet")
        || t.contains("new slide")
        || t.contains("docs.new")
        || t.contains("sheets.new")
        || t.contains("slides.new")
        || t.contains("ketik")
        || t.contains("type ")
        || t.contains("tulis")
        || t.contains("isi ")
        || t.contains("edit")
        || t.contains("tambah")
        || t.contains("insert")
        || t.contains("add ")
        || t.contains("rename")
        || t.contains("ganti ")
        || t.contains("ubah ")
        || t.contains("this doc")
        || t.contains("that doc")
        || t.contains("this sheet")
        || t.contains("that sheet")
        || t.contains("doc ini")
        || t.contains("sheet ini")
        || t.contains("slide ini")
        || t.contains("the spreadsheet")
        || t.contains("spreadsheet ini")
}

pub fn context_shows_google_sheets(combined: &str) -> bool {
    combined.contains("docs.google.com/spreadsheets")
        || combined.contains("sheets.google.com")
        || combined.contains("sheets.new")
}

pub fn context_shows_google_docs(combined: &str) -> bool {
    combined.contains("docs.google.com/document")
        || combined.contains("docs.new")
        || combined.contains("document/d/")
}

pub fn context_shows_google_slides(combined: &str) -> bool {
    combined.contains("docs.google.com/presentation")
        || combined.contains("slides.new")
        || combined.contains("presentation/d/")
}

pub fn inject_full_google_sheets_skill(user_text: &str, recent_context: &str) -> bool {
    let c = combined_lower(user_text, recent_context);
    if context_shows_google_sheets(&c) {
        return true;
    }
    if user_text_looks_like_sheet_format_intent(user_text) {
        return true;
    }
    if user_text_looks_like_spreadsheet_cell_ref_edit(user_text) {
        return true;
    }
    if user_text_looks_like_google_sheets_desktop(user_text) && open_or_operate_intent(&c) {
        return true;
    }
    false
}

pub fn inject_full_google_docs_skill(user_text: &str, recent_context: &str) -> bool {
    let c = combined_lower(user_text, recent_context);
    if context_shows_google_docs(&c) {
        return true;
    }
    if user_text_looks_like_docs_format_intent(user_text) {
        return true;
    }
    if open_or_operate_intent(&c) {
        return true;
    }
    false
}

pub fn inject_full_google_slides_skill(user_text: &str, recent_context: &str) -> bool {
    let c = combined_lower(user_text, recent_context);
    if context_shows_google_slides(&c) {
        return true;
    }
    if user_text_looks_like_slides_format_intent(user_text) {
        return true;
    }
    if open_or_operate_intent(&c) {
        return true;
    }
    false
}

pub const GOOGLE_WORKSPACE_SKILL_DEFERRED_HINT: &str =
    "[Device skill detail] Full step-by-step skill text is omitted until the app tab is visible in chat history/screenshot or you ask to open, create, or edit.";

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn vague_sheets_mention_skips_full_skill() {
        assert!(!inject_full_google_sheets_skill(
            "[@iid:1] I sometimes use Google Sheets for budgeting",
            ""
        ));
    }

    #[test]
    fn open_sheets_requests_full_skill() {
        assert!(inject_full_google_sheets_skill(
            "[@iid:1] buka google sheet dan isi baris 1",
            ""
        ));
    }

    #[test]
    fn history_url_requests_docs_full_skill() {
        assert!(inject_full_google_docs_skill(
            "[@iid:1] lanjutkan",
            "https://docs.google.com/document/d/abc123/edit"
        ));
    }

    #[test]
    fn format_intent_requests_slides_full_skill() {
        assert!(inject_full_google_slides_skill(
            "[@iid:1] ganti theme slide google slides",
            ""
        ));
    }
}
