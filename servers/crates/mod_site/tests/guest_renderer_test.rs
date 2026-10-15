use c35_mod_site::{GUEST_RENDERER_CONFIG_KEY, GUEST_RENDERER_VERSION};

#[test]
fn guest_renderer_version_starts_at_one() {
    assert_eq!(GUEST_RENDERER_VERSION, 11);
    assert_eq!(GUEST_RENDERER_CONFIG_KEY, "site.guest_renderer_version");
}
