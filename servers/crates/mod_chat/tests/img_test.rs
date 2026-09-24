use c35_mod_chat::tools::img::{enhance_prompt, image_size_for_quality, photo_hashes_from_attachments};

#[test]
fn image_size_for_quality_maps_draft_and_hd() {
    assert_eq!(image_size_for_quality("draft"), "1K");
    assert_eq!(image_size_for_quality("hd"), "2K");
    assert_eq!(image_size_for_quality(""), "1K");
}

#[test]
fn enhance_prompt_skips_when_already_enhanced() {
    let p = "masterpiece logo, clean vector art";
    assert_eq!(enhance_prompt(p), p);
}

#[test]
fn photo_hashes_from_attachments_collects_images() {
    let json = r#"[{"hash":"abc","mime":"image/jpeg"},{"hash":"def","mime":"text/plain"}]"#;
    assert_eq!(photo_hashes_from_attachments(json), vec!["abc".to_string()]);
}
