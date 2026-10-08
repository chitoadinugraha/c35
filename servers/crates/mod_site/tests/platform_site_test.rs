use c35_mod_site::{
    platform_home_assemble, platform_site_alien_id_is, platform_site_handle_assign_check,
    platform_site_identity_put_check, PlatformHomeContact, PlatformHomeLink, PlatformHomePost,
    PLATFORM_HOME_POST_CAP, PLATFORM_SITE_ALIEN_ID,
};

fn post(id: i64, on_storefront: bool) -> PlatformHomePost {
    PlatformHomePost {
        post_id: id,
        title: format!("t{id}"),
        caption: String::new(),
        body: String::new(),
        thumb: String::new(),
        created_ts: String::new(),
        on_storefront,
    }
}

fn contact(id: i64, featured: &str, archived: bool) -> PlatformHomeContact {
    PlatformHomeContact {
        contact_id: id,
        name: format!("n{id}"),
        pic: String::new(),
        url: String::new(),
        featured: featured.to_string(),
        archived,
    }
}

#[test]
fn platform_site_alien_id_is_trim_case() {
    assert!(platform_site_alien_id_is(" AlienAI "));
    assert!(!platform_site_alien_id_is("alien"));
    assert!(!platform_site_alien_id_is("alienai-x"));
    assert_eq!(PLATFORM_SITE_ALIEN_ID, "alienai");
}

#[test]
fn platform_site_home_groups_featured_and_skips_hidden() {
    let posts: Vec<PlatformHomePost> = (1..=PLATFORM_HOME_POST_CAP as i64 + 2)
        .map(|id| post(id, id != 2))
        .collect();
    let contacts = vec![
        contact(1, "partners", false),
        contact(2, "clients", false),
        contact(3, "partners", true),
        contact(4, "clients", true),
        contact(5, "", false),
    ];
    let links = vec![
        PlatformHomeLink {
            link_id: 1,
            label: "On".into(),
            url: "https://example.com".into(),
            icon: String::new(),
            active: true,
        },
        PlatformHomeLink {
            link_id: 2,
            label: "Off".into(),
            url: String::new(),
            icon: String::new(),
            active: false,
        },
    ];
    let doc = platform_home_assemble(&posts, &contacts, &links);
    assert_eq!(doc["alien_id"], "alienai");

    let posts_json = doc["posts"].as_array().unwrap();
    assert_eq!(posts_json.len(), PLATFORM_HOME_POST_CAP);
    assert!(posts_json.iter().all(|p| p["post_id"].as_i64() != Some(2)));
    assert_eq!(posts_json[0]["post_id"].as_i64(), Some(1));

    let partners = doc["partners"].as_array().unwrap();
    assert_eq!(partners.len(), 1);
    assert_eq!(partners[0]["contact_id"].as_i64(), Some(1));
    assert!(partners[0].get("email").is_none());

    let clients = doc["clients"].as_array().unwrap();
    assert_eq!(clients.len(), 1);
    assert_eq!(clients[0]["contact_id"].as_i64(), Some(2));

    let links_json = doc["links"].as_array().unwrap();
    assert_eq!(links_json.len(), 1);
    assert_eq!(links_json[0]["link_id"].as_i64(), Some(1));
    assert_eq!(links_json[0]["label"], "On");
}

#[test]
fn platform_site_handle_rejects_alienai_for_other_site() {
    let reserved = platform_site_handle_assign_check("other-site", "alienai").unwrap_err();
    assert!(reserved.to_string().contains("reserved"));
    let reserved_case = platform_site_handle_assign_check("shop", " AlienAI ").unwrap_err();
    assert!(reserved_case.to_string().contains("reserved"));
    let locked = platform_site_handle_assign_check("alienai", "new-name").unwrap_err();
    assert!(locked.to_string().contains("locked"));
    assert!(platform_site_handle_assign_check("other-site", "my-shop").is_ok());
}

#[test]
fn platform_site_identity_put_rejects_claim_and_rename() {
    let claim = platform_site_identity_put_check("alienai", None).unwrap_err();
    assert!(claim.to_string().contains("reserved"));
    let steal = platform_site_identity_put_check("AlienAI", Some("other")).unwrap_err();
    assert!(steal.to_string().contains("reserved"));
    let rename = platform_site_identity_put_check("other", Some("alienai")).unwrap_err();
    assert!(rename.to_string().contains("locked"));
    assert!(platform_site_identity_put_check("alienai", Some("alienai")).is_ok());
    assert!(platform_site_identity_put_check("", Some("alienai")).is_ok());
    assert!(platform_site_identity_put_check("shop", Some("other")).is_ok());
}
