use c35_mod_chat::{
    mention_active_topic, mention_force_tools, mention_has_device, mention_ref_parse, MentionRef,
    MentionResolved,
};

#[test]
fn mention_ref_parse_catalog_and_iid() {
    assert_eq!(
        mention_ref_parse("catalog:research"),
        Some(MentionRef::Catalog("research".into()))
    );
    assert_eq!(
        mention_ref_parse("iid:12831892391293"),
        Some(MentionRef::Iid(12831892391293))
    );
    assert_eq!(
        mention_ref_parse("12831892391293"),
        Some(MentionRef::Iid(12831892391293))
    );
    assert_eq!(
        mention_ref_parse("device:42"),
        Some(MentionRef::Iid(42))
    );
    assert_eq!(
        mention_ref_parse("research"),
        Some(MentionRef::Catalog("research".into()))
    );
}

#[test]
fn mention_force_tools_includes_device_when_remote() {
    use c35_proto::MentionItem;
    let resolved = vec![MentionResolved {
        item: c35_proto::MentionItem {
            id: "iid:99".into(),
            topic_id: "device".into(),
            inst_id: String::new(),
            icon: String::new(),
            color: String::new(),
            sort: 0,
            label_key: "Chito PC".into(),
            caption_key: String::new(),
            search_terms: vec![],
            enabled: true,
            title: "Chito PC".into(),
            scope_label: String::new(),
            label: "Chito PC".into(),
            scope_ref: String::new(),
            kind: "identity".into(),
        },
        identity_iid: Some(99),
        identity_kind: Some("remote".into()),
    }];
    assert!(mention_has_device(&resolved));
    let tools = mention_force_tools(&resolved);
    assert!(tools.iter().any(|t| t == "device.screenshot"));
    assert!(!tools.iter().any(|t| t == "device.input"));
    assert!(!tools.iter().any(|t| t == "device.command"));
    assert_eq!(mention_active_topic(&resolved, ""), "device");
}
