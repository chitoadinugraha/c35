use c35_mod_drive::{drive_normalize_path, drive_sync_nudge_bytes, drive_sync_nats_subject};

#[test]
fn drive_sync_nudge_format() {
    let bytes = drive_sync_nudge_bytes(42);
    let s = String::from_utf8(bytes).unwrap();
    assert!(s.starts_with("c35.drive:"));
    assert!(s.contains("42"));
}

#[test]
fn drive_normalize_strips_slashes() {
    assert_eq!(drive_normalize_path("foo/bar"), "/foo/bar");
}

#[test]
fn drive_sync_nats_subject_owner() {
    assert_eq!(drive_sync_nats_subject(99000), "c35.user.99000.drive-sync");
}