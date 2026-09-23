use c35_mod_site::doc::{render_key_for_page, site_doc_validate};
use c35_mod_site::render::{block_html_render, render_etag};
use c35_mod_site::site_preview_token_verify;
use c35_proto::{SiteBlock, SiteDoc, SitePage};
use serde_json::json;

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

#[test]
fn block_gallery_renders_pics() {
    let html = block_html_render(
        "gallery",
        &json!({"pics": ["/fs/abc", "https://example.com/x.jpg"], "title": "Photos"}),
        &[],
        &json!({}),
    );
    assert!(html.contains("class=\"gallery\""));
    assert!(html.contains("Photos"));
    assert!(html.contains("/fs/abc"));
}

#[test]
fn block_links_renders_items() {
    let html = block_html_render(
        "links",
        &json!({"links": [{"label": "Home", "url": "https://example.com"}], "title": "Links"}),
        &[],
        &json!({}),
    );
    assert!(html.contains("class=\"links\""));
    assert!(html.contains("Home"));
    assert!(html.contains("https://example.com"));
}

#[test]
fn block_contact_form_renders_fields() {
    let html = block_html_render(
        "contact_form",
        &json!({
            "title": "Reach us",
            "submit_label": "Send",
            "fields": [{"name": "email", "label": "Email", "type": "email"}]
        }),
        &[],
        &json!({}),
    );
    assert!(html.contains("class=\"contact-form\""));
    assert!(html.contains("#contact"));
    assert!(html.contains("Email"));
}

#[test]
fn block_map_gated_by_booking() {
    let props = json!({"lat": 1.0, "lng": 2.0, "address": "Main St"});
    assert!(block_html_render("map", &props, &[], &json!({})).contains("class=\"map\""));
    assert!(block_html_render("map", &props, &[], &json!({"booking": false})).is_empty());
}

#[test]
fn block_hours_gated_by_booking() {
    let props = json!({"hours": [{"day": "Mon", "open": "09:00", "close": "17:00"}]});
    assert!(block_html_render("hours", &props, &[], &json!({})).contains("class=\"hours\""));
    assert!(block_html_render("hours", &props, &[], &json!({"booking": false})).is_empty());
}

#[test]
fn block_queue_gated_by_queue_capability() {
    let props = json!({"title": "Now serving", "mode": "walk-in"});
    assert!(block_html_render("queue", &props, &[], &json!({})).contains("class=\"queue\""));
    assert!(block_html_render("queue", &props, &[], &json!({"queue": false})).is_empty());
}

#[test]
fn block_embed_uses_sandboxed_iframe() {
    let html = block_html_render(
        "embed",
        &json!({"url": "https://example.com/embed", "height": 300}),
        &[],
        &json!({}),
    );
    assert!(html.contains("<iframe sandbox=\"\""));
    assert!(html.contains("https://example.com/embed"));
}

#[test]
fn block_custom_html_strips_scripts() {
    let html = block_html_render(
        "custom_html",
        &json!({"html": "<p>safe</p><script>alert(1)</script><SCRIPT>x()</SCRIPT>"}),
        &[],
        &json!({}),
    );
    assert!(html.contains("class=\"custom-html\""));
    assert!(html.contains("safe"));
    assert!(!html.to_ascii_lowercase().contains("script"));
    assert!(!html.contains("alert"));
}

#[test]
fn block_markdown_escapes_content() {
    let html = block_html_render(
        "markdown",
        &json!({"content": "<b>bold</b> & \"quoted\""}),
        &[],
        &json!({}),
    );
    assert!(html.contains("&lt;b&gt;"));
    assert!(!html.contains("<b>bold</b>"));
}

#[test]
fn preview_token_valid_shape_verifies() {
    std::env::set_var("C35_SITE_PREVIEW_SECRET", "test-preview-secret");
    let site_iid = 42_i64;
    let exp_ms = chrono::Utc::now().timestamp_millis() + 60_000;
    let payload = format!("{site_iid}:{exp_ms}");
    use hmac::{Hmac, Mac};
    use sha2::Sha256;
    type HmacSha256 = Hmac<Sha256>;
    let mut mac = HmacSha256::new_from_slice(b"test-preview-secret").expect("hmac key");
    mac.update(payload.as_bytes());
    let sig = hex::encode(mac.finalize().into_bytes());
    let token = format!("{site_iid}:{exp_ms}:{sig}");
    assert!(site_preview_token_verify(site_iid, &token).unwrap());
}

#[test]
fn preview_token_invalid_sig_rejected() {
    std::env::set_var("C35_SITE_PREVIEW_SECRET", "test-preview-secret");
    let site_iid = 42_i64;
    let exp_ms = chrono::Utc::now().timestamp_millis() + 60_000;
    let token = format!("{site_iid}:{exp_ms}:deadbeef");
    assert!(!site_preview_token_verify(site_iid, &token).unwrap());
}

#[test]
fn preview_token_wrong_site_rejected() {
    std::env::set_var("C35_SITE_PREVIEW_SECRET", "test-preview-secret");
    let site_iid = 42_i64;
    let exp_ms = chrono::Utc::now().timestamp_millis() + 60_000;
    let payload = format!("{site_iid}:{exp_ms}");
    use hmac::{Hmac, Mac};
    use sha2::Sha256;
    type HmacSha256 = Hmac<Sha256>;
    let mut mac = HmacSha256::new_from_slice(b"test-preview-secret").expect("hmac key");
    mac.update(payload.as_bytes());
    let sig = hex::encode(mac.finalize().into_bytes());
    let token = format!("{site_iid}:{exp_ms}:{sig}");
    assert!(!site_preview_token_verify(99, &token).unwrap());
}
