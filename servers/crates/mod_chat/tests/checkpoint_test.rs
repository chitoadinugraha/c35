use c35_mod_chat::prompt_run::{
    chat_tool_rounds_max, checkpoint_record_screenshot_hash_hex, checkpoint_screenshot_stuck,
    checkpoint_tool_should_stop, CK_DEVICE_INPUT_COUNT, CK_SCREENSHOT_COUNT,
    COMPUTER_USE_MAX_DEVICE_INPUT, COMPUTER_USE_MAX_ROUNDS, COMPUTER_USE_MAX_SCREENSHOTS,
    SCREENSHOT_STUCK_LEN,
};
use serde_json::json;

#[test]
fn checkpoint_threshold_constants() {
    assert_eq!(COMPUTER_USE_MAX_DEVICE_INPUT, 60);
    assert_eq!(COMPUTER_USE_MAX_ROUNDS, 75);
    assert_eq!(COMPUTER_USE_MAX_SCREENSHOTS, 80);
    assert_eq!(SCREENSHOT_STUCK_LEN, 5);
    assert_eq!(chat_tool_rounds_max("computer_use"), 75);
    assert_eq!(chat_tool_rounds_max("main"), 24);
}

#[test]
fn checkpoint_stuck_ui_requires_five_identical_screenshots() {
    let mut cp = json!({});
    for i in 1..SCREENSHOT_STUCK_LEN {
        checkpoint_record_screenshot_hash_hex(&mut cp, "hash_frame_identical");
        assert!(
            !checkpoint_screenshot_stuck(&cp),
            "should not be stuck with {} screenshots",
            i
        );
        assert_eq!(checkpoint_tool_should_stop(&cp, "computer_use"), None);
    }

    checkpoint_record_screenshot_hash_hex(&mut cp, "hash_frame_identical");
    assert!(checkpoint_screenshot_stuck(&cp));
    assert_eq!(
        checkpoint_tool_should_stop(&cp, "computer_use"),
        Some(("stuck_ui", "desktop unchanged across last 5 screenshots"))
    );
}

#[test]
fn checkpoint_device_input_and_screenshot_extended_caps() {
    let mut cp = json!({
        CK_DEVICE_INPUT_COUNT: 59,
        CK_SCREENSHOT_COUNT: 79,
    });
    assert_eq!(checkpoint_tool_should_stop(&cp, "computer_use"), None);

    cp[CK_DEVICE_INPUT_COUNT] = json!(60);
    assert_eq!(
        checkpoint_tool_should_stop(&cp, "computer_use"),
        Some(("turn_cap", "device.input limit reached"))
    );

    cp[CK_DEVICE_INPUT_COUNT] = json!(50);
    cp[CK_SCREENSHOT_COUNT] = json!(80);
    assert_eq!(
        checkpoint_tool_should_stop(&cp, "computer_use"),
        Some(("turn_cap", "screenshot limit reached"))
    );
}
