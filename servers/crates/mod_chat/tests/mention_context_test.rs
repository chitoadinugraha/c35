use c35_mod_chat::{
    mention_context_build, mention_context_sites_block, site_iid_resolve, MentionContext,
    MentionResolved, SiteContext,
};
use c35_proto::MentionItem;
fn site_mention(iid: i64, alien_id: &str, name: &str) -> MentionResolved {
    MentionResolved {
        item: MentionItem {
            id: format!("iid:{iid}"),
            topic_id: "web.builder".into(),
            inst_id: String::new(),
            icon: "web".into(),
            color: "#34d399".into(),
            sort: 40,
            label_key: name.into(),
            caption_key: "Website".into(),
            search_terms: vec![name.to_lowercase(), alien_id.to_lowercase(), iid.to_string()],
            enabled: true,
            title: name.into(),
            scope_label: String::new(),
            label: name.into(),
            scope_ref: String::new(),
            kind: "identity".into(),
        },
        identity_iid: Some(iid),
        identity_kind: Some("site".into()),
    }
}

#[test]
fn mention_context_build_two_sites() {
    let resolved = vec![
        site_mention(111, "warung-a", "Warung A"),
        site_mention(222, "warung-b", "Warung B"),
    ];
    let ctx = mention_context_build(&resolved);
    assert_eq!(ctx.sites.len(), 2);
    assert_eq!(ctx.sites[0].site_iid, 111);
    assert_eq!(ctx.sites[0].alien_id, "warung-a");
    assert_eq!(ctx.sites[1].site_iid, 222);
    assert_eq!(ctx.default_site_iid, None);
}

#[test]
fn mention_context_sites_block_lists_both_sites() {
    let ctx = MentionContext {
        sites: vec![
            SiteContext {
                site_iid: 111,
                alien_id: "warung-a".into(),
                name: "Warung A".into(),
            },
            SiteContext {
                site_iid: 222,
                alien_id: "warung-b".into(),
                name: "Warung B".into(),
            },
        ],
        devices: vec![],
        default_site_iid: None,
    };
    let block = mention_context_sites_block(&ctx);
    assert!(block.starts_with("[SITE CONTEXTS]\n"));
    assert!(block.contains("site_iid=111 alien_id=warung-a name=Warung A"));
    assert!(block.contains("site_iid=222 alien_id=warung-b name=Warung B"));
}

#[test]
fn site_iid_resolve_single_site_defaults() {
    let ctx = MentionContext {
        sites: vec![SiteContext {
            site_iid: 111,
            alien_id: "warung-a".into(),
            name: "Warung A".into(),
        }],
        devices: vec![],
        default_site_iid: Some(111),
    };
    assert_eq!(site_iid_resolve(&ctx, None, None).unwrap(), 111);
}

#[test]
fn site_iid_resolve_ambiguous_without_arg_fails() {
    let ctx = MentionContext {
        sites: vec![
            SiteContext {
                site_iid: 111,
                alien_id: "warung-a".into(),
                name: "Warung A".into(),
            },
            SiteContext {
                site_iid: 222,
                alien_id: "warung-b".into(),
                name: "Warung B".into(),
            },
        ],
        devices: vec![],
        default_site_iid: None,
    };
    let err = site_iid_resolve(&ctx, None, None).unwrap_err().to_string();
    assert!(err.contains("multiple sites"));
}

#[test]
fn site_iid_resolve_explicit_arg_wins() {
    let ctx = MentionContext {
        sites: vec![
            SiteContext {
                site_iid: 111,
                alien_id: "warung-a".into(),
                name: "Warung A".into(),
            },
            SiteContext {
                site_iid: 222,
                alien_id: "warung-b".into(),
                name: "Warung B".into(),
            },
        ],
        devices: vec![],
        default_site_iid: None,
    };
    assert_eq!(
        site_iid_resolve(&ctx, None, Some(222)).unwrap(),
        222
    );
}

#[test]
fn site_iid_resolve_zero_sites_requires_fallback_or_arg() {
    let ctx = MentionContext::empty();
    assert!(site_iid_resolve(&ctx, None, None).is_err());
    assert_eq!(site_iid_resolve(&ctx, Some(333), None).unwrap(), 333);
    assert_eq!(site_iid_resolve(&ctx, None, Some(444)).unwrap(), 444);
}
