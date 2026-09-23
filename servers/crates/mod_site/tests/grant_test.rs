use c35_mod_site::grant::{site_role_allows, site_role_rank};

#[test]
fn site_role_rank_order() {
    assert!(site_role_rank("owner") > site_role_rank("manage"));
    assert!(site_role_rank("manage") > site_role_rank("staff"));
    assert_eq!(site_role_rank("unknown"), 0);
}

#[test]
fn site_role_allows_read_write() {
    assert!(site_role_allows("staff", false));
    assert!(site_role_allows("manage", true));
    assert!(!site_role_allows("staff", true));
    assert!(!site_role_allows("", false));
}
