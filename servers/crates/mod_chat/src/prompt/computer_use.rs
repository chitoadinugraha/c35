/// Computer-use subagent: detect model handoff to the human instead of device.input.
pub const COMPUTER_USE_CONTINUE_HINT: &str = "The user is not at the device keyboard. Do not ask them to click or type. \
Continue with device.screenshot (som=true) and device.input until the stated goal is fully done. \
If a click did not change the UI, retry with corrected coordinates or keyboard (Tab, Enter, Space).";

pub const COMPUTER_USE_FORCE_TOOL_HINT: &str = "You must call device.screenshot or device.input now. \
Final text without a tool call is not allowed until the stated goal is fully completed on the device.";

pub const COMPUTER_USE_PARENT_INCOMPLETE_HINT: &str =
    "Delegate did not complete the goal on the device. Do not ask the user to click or type. \
Briefly state that automation could not finish; do not paste numbered UI steps from the child summary.";

pub const COMPUTER_USE_INCOMPLETE_FAIL_CLASS: &str = "fatal_incomplete";

pub fn reply_looks_like_computer_use_handoff(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    [
        "please click",
        "please tap",
        "you can manually",
        "you can click",
        "once you open",
        "once the editor opens",
        "let me know when",
        "let me know once",
        "to complete your request, please",
        "proceed with the following steps",
        "using the sidebar",
        "you can set the title",
        "silakan klik",
        "klik ikon",
        "klik tombol",
        "klik \"",
        "klik untitled",
        "anda dapat melanjutkan",
        "setelah terbuka",
        "please manually",
        "manually click",
        "buka sendiri",
        "lakukan langkah",
        "secara manual",
        "lanjutkan secara",
        "perlu anda lanjutkan",
        "anda lanjutkan",
        "manual di browser",
        "silakan lanjutkan",
        "mohon konfirmasi",
        "beri tahu saya jika",
    ]
    .iter()
    .any(|k| t.contains(k))
}

/// Model gave up or blocked without asking the user explicitly — still not an acceptable final reply.
pub fn reply_looks_like_computer_use_incomplete(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    [
        "blocked by",
        "not responding",
        "unable to complete",
        "unable to finish",
        "could not complete",
        "could not finish",
        "couldn't complete",
        "couldn't finish",
        "cannot complete",
        "cannot finish",
        "multiple tabs",
        "template is not",
        "ui state",
        "automation stopped",
        "did not complete",
        "gagal menyelesaikan",
        "tidak dapat menyelesaikan",
        "terhalang",
        "belum selesai",
    ]
    .iter()
    .any(|k| t.contains(k))
}

pub fn computer_use_final_text_acceptable(text: &str) -> bool {
    let t = text.trim();
    if t.is_empty() {
        return false;
    }
    !reply_looks_like_computer_use_handoff(t) && !reply_looks_like_computer_use_incomplete(t)
}

pub fn computer_use_goal_met(kind: &str, status: &str, summary: &str) -> bool {
    computer_use_goal_met_with_goal(kind, status, summary, "")
}

pub fn computer_use_goal_met_with_goal(
    kind: &str,
    status: &str,
    summary: &str,
    goal: &str,
) -> bool {
    if status != "done" {
        return false;
    }
    if kind == "computer_use" {
        if !computer_use_final_text_acceptable(summary) {
            return false;
        }
        if crate::prompt::google_forms::user_text_looks_like_google_forms(goal) {
            return crate::prompt::google_forms::google_forms_summary_sufficient(goal, summary);
        }
        true
    } else {
        true
    }
}

pub const DELEGATE_INCOMPLETE_CHECKPOINT_KEY: &str = "delegate_incomplete";

pub fn parent_reply_after_incomplete_delegate(locale: &str) -> String {
    let id = locale.to_ascii_lowercase().starts_with("id");
    if id {
        "Automasi di perangkat remote belum menyelesaikan tugas (misalnya formulir belum dibuat). \
Periksa layar VM — Chrome mungkin sudah terbuka di Google Forms. Anda bisa minta saya mencoba lagi."
            .to_string()
    } else {
        computer_use_stopped_incomplete_message()
    }
}

pub fn computer_use_stopped_incomplete_message() -> String {
    "Automation stopped before completing the goal on the remote device. \
Check the device screen and try again if the task still needs to be done."
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn handoff_phrases_detected() {
        assert!(reply_looks_like_computer_use_handoff(
            "Please click the Blank form option to start."
        ));
        assert!(reply_looks_like_computer_use_handoff(
            "Once the editor opens, you can set the title."
        ));
    }

    #[test]
    fn incomplete_give_up_detected() {
        let snippet = "The form creation process on Google Forms is currently blocked by the UI state, \
as multiple tabs are open and the \"Blank form\" template is not responding to selection.";
        assert!(reply_looks_like_computer_use_incomplete(snippet));
        assert!(!computer_use_final_text_acceptable(snippet));
    }

    #[test]
    fn done_confirmation_acceptable() {
        assert!(computer_use_final_text_acceptable(
            "Created form Test Pendaftaran with fields nama, gender, alamat on VM1."
        ));
    }
}
