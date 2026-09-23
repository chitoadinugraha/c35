use c35_mod_site::doc::{render_key_for_page, site_doc_validate};
use c35_mod_site::render::render_etag;
use c35_proto::{SiteBlock, SiteDoc, SitePage};

fn sample_doc() -> SiteDoc {
    SiteDoc {
        pages: vec![
            SitePage {
                path: "/".into(),
                title: "Home".into(),
                blocks: vec![
                    SiteBlock {
                        id: "b1".into(),
                        r#type: "hero".into(),
                        props_json: r#"{"title":"Hello","subtitle":"World"}"#.into(),
                    },
                    SiteBlock {
                        id: "b2".into(),
                        r#type: "spacer".into(),
                        props_json: r#"{"height":32}"#.into(),
                    },
                ],
            },
        ],
        theme_json: r##"{"accent":"#ff0000"}"##.into(),
        meta_json: "{}".into(),
    }
}

#[test]
fn site_doc_validate_accepts_v1_blocks() {
    assert!(site_doc_validate(&sample_doc()).is_ok());
}

#[test]
fn site_doc_validate_rejects_unknown_block() {
    let doc = SiteDoc {
        pages: vec![SitePage {
            path: "/".into(),
            title: "X".into(),
            blocks: vec![SiteBlock {
                id: "b1".into(),
                r#type: "unknown".into(),
                props_json: "{}".into(),
            }],
        }],
        ..Default::default()
    };
    assert!(site_doc_validate(&doc).is_err());
}

#[test]
fn render_key_for_page_home_and_subpage() {
    assert_eq!(render_key_for_page("/"), "html:/");
    assert_eq!(render_key_for_page("/about"), "html:/about");
}

#[test]
fn render_etag_is_blake3_hex() {
    let etag = render_etag("<html></html>");
    assert_eq!(etag.len(), 64);
}
