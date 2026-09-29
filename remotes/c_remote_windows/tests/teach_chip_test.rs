use c_remote_windows::skill_teach_overlay::{
    chip_hit, chip_screen_rect, chip_stop_local, classify_click, click_label, type_label, ChipHit,
    TeachClick, CHIP_H, CHIP_MARGIN, CHIP_W,
};

#[test]
fn test_chip_sits_top_left() {
    let r = chip_screen_rect(1920, 1080);
    assert_eq!(r.x, CHIP_MARGIN);
    assert_eq!(r.y, CHIP_MARGIN);
    assert_eq!(r.w, CHIP_W);
    assert_eq!(r.h, CHIP_H);
}

#[test]
fn test_chip_body_click_is_ignored() {
    let win = chip_screen_rect(1920, 1080);
    let stop = chip_stop_local();
    let hit = chip_hit(win, stop, win.x + 20, win.y + 20);
    assert_eq!(hit, ChipHit::Body);
    assert_eq!(classify_click(hit, false), TeachClick::Ignore);
}

#[test]
fn test_chip_stop_click_stops() {
    let win = chip_screen_rect(1920, 1080);
    let stop = chip_stop_local();
    let hit = chip_hit(win, stop, win.x + stop.x + 4, win.y + stop.y + 4);
    assert_eq!(hit, ChipHit::Stop);
    assert_eq!(classify_click(hit, false), TeachClick::Stop);
}

#[test]
fn test_outside_click_records_unless_agent_ui() {
    let win = chip_screen_rect(1920, 1080);
    let stop = chip_stop_local();
    let hit = chip_hit(win, stop, 200, 500);
    assert_eq!(hit, ChipHit::Outside);
    assert_eq!(classify_click(hit, false), TeachClick::Record);
    assert_eq!(classify_click(hit, true), TeachClick::Ignore);
}

#[test]
fn test_click_label_generation() {
    assert_eq!(
        click_label("Google Chrome", "Search"),
        "In Google Chrome, click Search"
    );
    assert_eq!(click_label("", "Submit"), "Click Submit");
    assert_eq!(click_label("Notepad", ""), "In Notepad, click a control");
}

#[test]
fn test_type_label_compacted_and_enter() {
    assert_eq!(
        type_label("Google Chrome", "Search", "antigravity", false, true),
        "In Google Chrome, fill Search with \"antigravity\", then press Enter"
    );
    assert_eq!(
        type_label("", "Username", "alice", false, false),
        "Fill Username with \"alice\""
    );
}

#[test]
fn test_type_label_password_masking() {
    let lbl = type_label("Login - App", "Password", "supersecret123", true, false);
    assert_eq!(lbl, "In Login - App, fill password in Password");
    assert!(!lbl.contains("supersecret123"));

    let enter_lbl = type_label("", "Password", "hunter2", true, true);
    assert_eq!(enter_lbl, "Fill password in Password, then press Enter");
    assert!(!enter_lbl.contains("hunter2"));
}
