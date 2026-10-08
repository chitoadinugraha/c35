use c35_mod_site::byo_unverified_expires;

mod domain_pending {
    use super::byo_unverified_expires;

    #[test]
    fn bought_unverified_does_not_expire() {
        assert!(!byo_unverified_expires(48, "bought", false));
    }

    #[test]
    fn byo_unverified_expires_after_24h() {
        assert!(byo_unverified_expires(25, "byo", false));
        assert!(!byo_unverified_expires(23, "byo", false));
        assert!(!byo_unverified_expires(48, "byo", true));
    }
}
