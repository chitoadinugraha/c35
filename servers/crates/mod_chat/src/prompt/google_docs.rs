//! Google Docs in Chrome on @device Windows/desktop.

pub const GOOGLE_DOCS_DESKTOP_PLAYBOOK: &str = "[GOOGLE DOCS ON DEVICE] \
Turn 0 may include desktop observation — reuse an open docs.google.com/document tab before docs.new. \
Execute with device.input (click, type_text, shortcut, click_and_type). Never browser.sheets.* or presentation tools for Docs. \
Dismiss side panels and promo banners (X) before editing. \
Select text before applying bold, alignment, or heading styles. \
Verify title and body in post-action screenshot — do not finish on prose alone.";

pub const GOOGLE_DOCS_DEVICE_SKILL: &str =
    include_str!("../../../../../_/schemas/skill_seeds/google_docs_device.txt");

pub const GOOGLE_DOCS_SKILL_RULE: &str = "[GOOGLE DOCS] \
For Docs on @device use device.input + this skill playbook. \
Do not use presentation.create or spreadsheet tools unless the user explicitly switched to Slides/Sheets.";

fn device_mention_in_text(text: &str) -> bool {
    text.contains("[@iid:") || text.contains("@iid:")
}

fn text_mentions_google_doc(t: &str) -> bool {
    t.contains("google doc")
        || t.contains("google docs")
        || t.contains("docs.new")
        || t.contains("document.new")
        || t.contains("document/d/")
        || t.contains("dokumen google")
        || t.contains("google document")
}

pub fn user_text_looks_like_device_google_docs(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    if !text_mentions_google_doc(&t) {
        return false;
    }
    device_mention_in_text(text)
        || t.contains("on my pc")
        || t.contains("di komputer")
        || t.contains("@device")
        || t.contains("buka doc")
        || t.contains("open doc")
        || t.contains("buat dokumen")
        || t.contains("create document")
}

pub fn user_text_looks_like_docs_format_intent(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    t.contains("bold")
        || t.contains("tebal")
        || t.contains("heading")
        || t.contains("judul")
        || t.contains("align")
        || t.contains("rata")
        || t.contains("bullet")
        || t.contains("numbering")
        || t.contains("spacing")
        || t.contains("indent")
        || t.contains("format")
        || t.contains("heading 1")
        || t.contains("heading 2")
}

pub fn google_docs_playbook_block() -> &'static str {
    GOOGLE_DOCS_DESKTOP_PLAYBOOK
}

pub fn google_docs_skill_block() -> &'static str {
    GOOGLE_DOCS_DEVICE_SKILL
}
