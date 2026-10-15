use c35_mod_site::{display_label_for_ticket, validate_queue_answers};
use serde_json::{json, Map};

#[test]
fn display_label_prefix_and_padding() {
    assert_eq!(display_label_for_ticket("A", 1), "A-001");
    assert_eq!(display_label_for_ticket("A", 42), "A-042");
    assert_eq!(display_label_for_ticket("", 7), "007");
    assert_eq!(display_label_for_ticket("  ", 3), "003");
}

#[test]
fn validate_queue_answers_required_field() {
    let fields = json!([
        { "name": "party_size", "label": "Jumlah orang", "required": true },
        { "name": "note", "required": false },
    ]);
    let empty = Map::new();
    let err = validate_queue_answers(&fields, &empty).unwrap_err();
    assert!(err.contains("Jumlah orang"));

    let mut ok = Map::new();
    ok.insert("party_size".into(), json!("4"));
    assert!(validate_queue_answers(&fields, &ok).is_ok());
}

#[test]
fn validate_queue_answers_ignores_blank_field_names() {
    let fields = json!([{ "name": "", "required": true }]);
    assert!(validate_queue_answers(&fields, &Map::new()).is_ok());
}
