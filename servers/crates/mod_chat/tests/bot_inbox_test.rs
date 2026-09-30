use c35_mod_chat::bot_inbox::{bot_inbox_content_fingerprint, bot_inbox_content_normalize};

#[test]
fn bot_inbox_normalize_strips_mentions_and_case() {
    let raw = "  Halo [@iid:123]   apa   harga?  ";
    let n = bot_inbox_content_normalize(raw);
    assert_eq!(n, "halo apa harga?");
    let fp1 = bot_inbox_content_fingerprint(&n);
    let fp2 = bot_inbox_content_fingerprint("halo apa harga?");
    assert_eq!(fp1, fp2);
}