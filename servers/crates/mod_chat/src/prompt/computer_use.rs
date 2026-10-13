/// Computer-use subagent: detect model handoff to the human instead of device.input.
pub const COMPUTER_USE_CONTINUE_HINT: &str = "The user is not at the device keyboard. Do not ask them to click or type. \
Continue with device.screenshot (som=true) and device.input until the stated goal is fully done. \
If a click did not change the UI, retry with corrected coordinates or keyboard (Tab, Enter, Space).";

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
        "klik tombol",
        "buka sendiri",
        "lakukan langkah",
    ]
    .iter()
    .any(|k| t.contains(k))
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
    fn done_confirmation_not_handoff() {
        assert!(!reply_looks_like_computer_use_handoff(
            "Created form Test Pendaftaran with fields nama, gender, alamat on VM1."
        ));
    }
}
