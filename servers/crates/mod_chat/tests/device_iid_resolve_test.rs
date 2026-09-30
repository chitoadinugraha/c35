use c35_mod_chat::{device_iid_resolve, MentionContext};

#[test]
fn device_iid_resolve_single_mention_overrides_wrong_llm_arg() {
    let mention = MentionContext {
        sites: vec![],
        devices: vec![42],
        bots: vec![],
        default_site_iid: None,
    };
    assert_eq!(device_iid_resolve(&mention, &[], 99).unwrap(), 42);
}

#[test]
fn device_iid_resolve_explicit_arg_when_no_device_context() {
    assert_eq!(device_iid_resolve(&MentionContext::empty(), &[], 99).unwrap(), 99);
}

#[test]
fn device_iid_resolve_single_mentioned_device() {
    let mention = MentionContext {
        sites: vec![],
        devices: vec![42],
        bots: vec![],
        default_site_iid: None,
    };
    assert_eq!(device_iid_resolve(&mention, &[], 0).unwrap(), 42);
}

#[test]
fn device_iid_resolve_from_mention_ids_iid_ref() {
    let mention = MentionContext::empty();
    assert_eq!(
        device_iid_resolve(&mention, &["iid:12345".into()], 0).unwrap(),
        12345
    );
}

#[test]
fn device_iid_resolve_errors_when_ambiguous() {
    let mention = MentionContext {
        sites: vec![],
        devices: vec![1, 2],
        bots: vec![],
        default_site_iid: None,
    };
    assert!(device_iid_resolve(&mention, &[], 0).is_err());
}
