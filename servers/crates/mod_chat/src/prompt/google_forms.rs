/// Shared Google Forms on @device playbook (tab reuse + resume). Used in compose and delegate goals.
pub const GOOGLE_FORMS_TAB_RESUME_PLAYBOOK: &str = "[GOOGLE FORMS TAB RESUME] \
Always device.screenshot with som=true before any shell.run or chrome launch. \
If Chrome already shows forms.google.com, the template gallery, or an open form editor, do NOT run shell.run to open forms.new or another forms URL - switch to that window (Alt+Tab if needed), click the existing Forms tab, and continue from the visible stage. \
Open forms.google.com or a new blank form only when the screenshot shows no Forms tab. \
Do not stack duplicate Forms tabs; close extras only if they block clicking Blank. \
Opening a URL or a new tab is never task completion; finish title and every requested field, then verify with a final screenshot.";

pub fn user_text_looks_like_google_forms(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    [
        "google form",
        "google forms",
        "forms.google",
        "form baru",
        "buat form",
        "create a form",
        "create new form",
        "untitled form",
        "template gallery",
    ]
    .iter()
    .any(|k| t.contains(k))
}

pub fn google_forms_playbook_block() -> &'static str {
    GOOGLE_FORMS_TAB_RESUME_PLAYBOOK
}

/// Stricter completion check when the delegate goal is a multi-field Forms build.
pub fn google_forms_summary_sufficient(goal: &str, summary: &str) -> bool {
    let g = goal.to_ascii_lowercase();
    let s = summary.to_ascii_lowercase();
    if s.is_empty() {
        return false;
    }
    let opening_only = [
        "opened chrome",
        "opened google chrome",
        "membuka chrome",
        "launched chrome",
        "navigated to forms",
        "forms.new",
        "template gallery",
        "gallery page",
    ];
    let claims_done = [
        "created",
        "added",
        "finished",
        "completed",
        "selesai",
        "dibuat",
        "menambahkan",
        "berhasil",
    ];
    if opening_only.iter().any(|k| s.contains(k))
        && !claims_done.iter().any(|k| s.contains(k))
    {
        return false;
    }
    let mut hits = 0u32;
    for token in ["nama", "gender", "alamat", "name", "address"] {
        if g.contains(token) && s.contains(token) {
            hits += 1;
        }
    }
    if g.contains("judul") || g.contains("title") {
        for word in extract_quoted_or_title_words(goal) {
            if s.contains(&word) {
                hits += 1;
                break;
            }
        }
        if s.contains("pendaftaran") || s.contains("form title") || s.contains("judul") {
            hits += 1;
        }
    }
    if hits >= 2 {
        return true;
    }
    hits >= 1
        && claims_done.iter().any(|k| s.contains(k))
        && (s.contains("field") || s.contains("question") || s.contains("pertanyaan"))
}

fn extract_quoted_or_title_words(goal: &str) -> Vec<String> {
    let mut out = Vec::new();
    let lower = goal.to_ascii_lowercase();
    for marker in ["judul ", "title "] {
        if let Some(rest) = lower.split(marker).nth(1) {
            let phrase = rest
                .split(|c: char| c == ',' || c == '\n' || c == '.')
                .next()
                .unwrap_or("")
                .trim();
            if phrase.len() >= 4 {
                out.push(phrase.to_string());
            }
        }
    }
    out
}