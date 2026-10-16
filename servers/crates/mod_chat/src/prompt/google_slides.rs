//! Google Slides in Chrome on @device (not Alien presentation.create).

pub const GOOGLE_SLIDES_DESKTOP_PLAYBOOK: &str = "[GOOGLE SLIDES ON DEVICE] \
Reuse docs.google.com/presentation tab when visible; open slides.new only if none. \
Use device.input for filmstrip, text boxes, and toolbar. \
This is Google Slides in Chrome — NOT presentation.create / presentation.patch (in-app deck). \
Close Themes side panel (X top-right) when it covers the canvas. \
Verify slide thumbnails and text in screenshot before finishing.";

pub const GOOGLE_SLIDES_DEVICE_SKILL: &str =
    include_str!("../../../../../_/schemas/skill_seeds/google_slides_device.md");

pub const GOOGLE_SLIDES_SKILL_RULE: &str = "[GOOGLE SLIDES IN CHROME] \
On @device with Google Slides in the browser, use device.input and the google-slides-device skill. \
Do not call presentation.create unless the user wants an Alien in-app deck (no Google Slides URL).";

fn device_mention_in_text(text: &str) -> bool {
    text.contains("[@iid:") || text.contains("@iid:")
}

fn text_mentions_google_slides(t: &str) -> bool {
    t.contains("google slide")
        || t.contains("google slides")
        || t.contains("slides.new")
        || t.contains("presentation/d/")
        || t.contains("slide google")
        || t.contains("google presentation")
}

/// Chrome Google Slides — distinct from generic "presentasi" → inst.presentation.
pub fn user_text_looks_like_device_google_slides(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    if !text_mentions_google_slides(&t) {
        return false;
    }
    if t.contains("presentation.create") || t.contains("slide-patch") {
        return false;
    }
    device_mention_in_text(text)
        || t.contains("slides.new")
        || t.contains("presentation/d/")
        || t.contains("di google slide")
        || t.contains("in google slide")
}

pub fn user_text_looks_like_slides_format_intent(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    t.contains("bold")
        || t.contains("font")
        || t.contains("align")
        || t.contains("theme")
        || t.contains("background")
        || t.contains("layout")
        || t.contains("new slide")
        || t.contains("tambah slide")
        || t.contains("duplicate")
        || t.contains("format")
}

pub fn google_slides_playbook_block() -> &'static str {
    GOOGLE_SLIDES_DESKTOP_PLAYBOOK
}

pub fn google_slides_skill_block() -> &'static str {
    GOOGLE_SLIDES_DEVICE_SKILL
}
