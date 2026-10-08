use c35_mod_site::doc::{render_key_for_page, site_doc_validate};
use c35_mod_site::guest_design::GuestDesign;
use c35_mod_site::render::{
    block_html_render, guest_client_script_markup, product_card_html, product_detail_article_html,
    render_etag, render_offline_html, ProductGridCtx, ProductRow,
};
use c35_mod_site::site_preview_token_verify;
use c35_proto::{SiteBlock, SiteDoc, SitePage};
use serde_json::{json, Value};

fn render_block(
    block_type: &str,
    props: &Value,
    products: &[ProductRow],
    caps: &Value,
    grid_ctx: Option<&ProductGridCtx>,
) -> String {
    let design = GuestDesign::from_theme_json("");
    block_html_render(block_type, props, products, caps, grid_ctx, 0, &[], &[], None, &design, &[])
}

fn render_block_site(
    block_type: &str,
    props: &Value,
    products: &[ProductRow],
    caps: &Value,
    grid_ctx: Option<&ProductGridCtx>,
    site_iid: i64,
    product_design: Option<&Value>,
) -> String {
    let design = GuestDesign::from_theme_json("");
    block_html_render(
        block_type,
        props,
        products,
        caps,
        grid_ctx,
        site_iid,
        &[],
        &[],
        product_design,
        &design,
        &[],
    )
}

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
fn site_doc_validate_accepts_contact_form_and_cta_label() {
    let doc = SiteDoc {
        pages: vec![SitePage {
            path: "/".into(),
            title: "Test".into(),
            blocks: vec![
                SiteBlock {
                    id: "h1".into(),
                    r#type: "hero".into(),
                    props_json: r#"{"title":"T","cta_label":"Click","cta_href":"/contact"}"#.into(),
                },
                SiteBlock {
                    id: "c1".into(),
                    r#type: "contact_form".into(),
                    props_json: r#"{"title":"Contact","submit_label":"Send"}"#.into(),
                },
            ],
        }],
        ..Default::default()
    };
    assert!(site_doc_validate(&doc).is_ok());
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
fn render_offline_html_is_branded_unpublished_page() {
    let html = render_offline_html("Warung Bu Siti");
    assert!(html.contains("Warung Bu Siti"));
    assert!(html.contains("#F97316"));
    assert!(html.contains("not published yet"));
    assert!(html.contains("AlienAI"));
}

#[test]
fn block_hero_renders_title_cta() {
    let html = render_block(
        "hero",
        &json!({
            "title": "Welcome",
            "subtitle": "Tagline here",
            "cta": "Order now",
            "cta_url": "/menu"
        }),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"block hero\""));
    assert!(html.contains("<h1>Welcome</h1>"));
    assert!(html.contains("Tagline here"));
    assert!(html.contains("class=\"hero-cta\""));
    assert!(html.contains("href=\"/menu\""));
    assert!(html.contains("Order now"));
}

#[test]
fn block_hero_renders_cta_label_alias() {
    let html = render_block(
        "hero",
        &json!({
            "title": "Welcome",
            "subtitle": "Tagline here",
            "cta_label": "Kunjungi",
            "cta_href": "#contact"
        }),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"hero-cta\""));
    assert!(html.contains("href=\"#contact\""));
    assert!(html.contains("Kunjungi"));
}

#[test]
fn block_image_renders_pic() {
    let html = render_block(
        "image",
        &json!({
            "pic": "img-abc",
            "alt": "Hero shot",
            "caption": "Our storefront"
        }),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"block image\""));
    assert!(html.contains("src=\"/fs/img-abc?v=thumb\""));
    assert!(html.contains("alt=\"Hero shot\""));
    assert!(html.contains("<figcaption>Our storefront</figcaption>"));
}

#[test]
fn block_spacer_renders_height() {
    let html = render_block(
        "spacer",
        &json!({"height": 48}),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"block spacer\""));
    assert!(html.contains("style=\"height:48px\""));
}

#[test]
fn block_product_grid_renders_products() {
    let products = vec![
        ProductRow {
            product_id: 101,
            name: "Kopi Susu".into(),
            desc: "Enak".into(),
            price: 15000,
            pic: "pic-kopi".into(),
            category: "drinks".into(),
            sort_order: 0,
            can_reserve: false,
            duration_value: 1,
            duration_unit: "day".into(),
            reservation_unit_selection: "system".into(),
            icon: String::new(),
            stock_show_to_customer: false,
            stock_qty: None,
        },
        ProductRow {
            product_id: 102,
            name: "Teh".into(),
            desc: "Hangat".into(),
            price: 8000,
            pic: "".into(),
            category: "drinks".into(),
            sort_order: 1,
            can_reserve: false,
            duration_value: 1,
            duration_unit: "day".into(),
            reservation_unit_selection: "system".into(),
            icon: "mdi:tea".into(),
            stock_show_to_customer: false,
            stock_qty: None,
        },
    ];
    let grid_ctx = ProductGridCtx {
        site_iid: 42,
        block_id: "g1".into(),
        next_cursor: "0:102".into(),
    };
    let design = json!({
        "titleFontSize": 20,
        "titleFontWeight": "w700",
        "titleColor": "#ff00aa",
        "priceFontSize": 16,
        "priceFontWeight": "w800",
        "priceColor": "#00cc88"
    });
    let html = render_block_site(
        "product_grid",
        &json!({}),
        &products,
        &json!({}),
        Some(&grid_ctx),
        42,
        Some(&design),
    );
    assert!(html.contains("class=\"block product-grid\""));
    assert!(html.contains("font-size:20px"));
    assert!(html.contains("color:#ff00aa"));
    assert!(html.contains("font-weight:700"));
    assert!(html.contains("data-pid=\"101\""));
    assert!(html.contains("Kopi Susu"));
    assert!(html.contains("Rp 15.000"));
    assert!(html.contains("/fs/pic-kopi?v=thumb"));
    assert!(html.contains("data-pid=\"102\""));
    assert!(html.contains("Teh"));
    assert!(html.contains("Rp 8.000"));
    assert!(html.contains("guest-add-btn"));
    assert!(html.contains("data-site-iid=\"42\""));
    assert!(html.contains("data-block-id=\"g1\""));
    assert!(html.contains("data-next-cursor=\"0:102\""));
    assert!(html.contains("guest-load-more-btn"));
}

fn sample_product(can_reserve: bool) -> ProductRow {
    ProductRow {
        product_id: 7,
        name: "Villa Melati".into(),
        desc: "Malam".into(),
        price: 250000,
        pic: "".into(),
        category: "stay".into(),
        sort_order: 0,
        can_reserve,
        duration_value: 1,
        duration_unit: "day".into(),
        reservation_unit_selection: "guest_picks".into(),
        icon: String::new(),
        stock_show_to_customer: false,
        stock_qty: None,
    }
}

#[test]
fn reservable_product_detail_renders_reserve_button() {
    let html = product_detail_article_html(&sample_product(true));
    assert!(html.contains("guest-reserve-btn"));
    assert!(html.contains("data-reserve-product=\"7\""));
    assert!(html.contains(">Reservasi</button>"));
    assert!(!html.contains("product-reserve-placeholder"));
    assert!(!html.contains("+ Pesan"));
    assert!(html.contains("data-can-reserve=\"1\""));
}

#[test]
fn sellable_product_detail_keeps_pesan_button() {
    let html = product_detail_article_html(&sample_product(false));
    assert!(html.contains("guest-add-btn"));
    assert!(html.contains("+ Pesan"));
    assert!(!html.contains("guest-reserve-btn"));
    assert!(!html.contains("product-reserve-placeholder"));
}

#[test]
fn block_gallery_renders_pics() {
    let html = render_block(
        "gallery",
        &json!({"pics": ["/fs/abc", "https://example.com/x.jpg"], "title": "Photos"}),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"gallery\""));
    assert!(html.contains("Photos"));
    assert!(html.contains("/fs/abc"));
}

#[test]
fn block_links_renders_items() {
    let html = render_block(
        "links",
        &json!({"links": [{"label": "Home", "url": "https://example.com"}], "title": "Links"}),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"links\""));
    assert!(html.contains("data-guest=\"link\""));
    assert!(html.contains("Home"));
    assert!(html.contains("https://example.com"));
}

#[test]
fn block_contact_form_renders_fields() {
    let html = render_block(
        "contact_form",
        &json!({
            "title": "Reach us",
            "submit_label": "Send",
            "fields": [{"name": "email", "label": "Email", "type": "email"}]
        }),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"contact-form\""));
    assert!(html.contains("data-guest=\"form\""));
    assert!(html.contains("c35GuestLead.submit"));
    assert!(html.contains("#contact"));
    assert!(html.contains("Email"));
}

#[test]
fn page_without_effects_omits_effects_script() {
    for effects in [
        json!([]),
        Value::Null,
        json!([{"presetId": "rain-shower", "active": false}]),
        json!([{"preset_id": "", "active": true}]),
        json!([{"active": true}]),
    ] {
        let html = guest_client_script_markup("{}", &effects);
        assert!(html.contains("/static/site-guest/site-guest.v1.js"), "{html}");
        assert!(!html.contains("site-guest.effects"), "{html}");
        assert!(!html.contains("\"effects\""), "{html}");
        assert!(!html.contains("form.js"), "{html}");
        assert!(!html.contains("queue.js"), "{html}");
    }
}

#[test]
fn page_with_active_preset_includes_effects_script() {
    let html = guest_client_script_markup(
        "{}",
        &json!([{"presetId": "rain-shower", "params": {}, "active": true}]),
    );
    assert!(html.contains("/static/site-guest/site-guest.v1.js"));
    assert!(html.contains("/static/site-guest/site-guest.effects.v1.js"));
    assert!(html.contains("\"effects\""));
    assert!(html.contains("rain-shower"));

    let snake = guest_client_script_markup("{}", &json!([{"preset_id": "snow-fall"}]));
    assert!(snake.contains("/static/site-guest/site-guest.effects.v1.js"));
    assert!(snake.contains("snow-fall"));
}

#[test]
fn product_card_stock_line_follows_show_flag() {
    let mut shown = sample_product(false);
    shown.stock_show_to_customer = true;
    shown.stock_qty = Some(4);
    let html = product_card_html(&shown, None);
    assert!(html.contains("Stock: 4"));

    let mut hidden = sample_product(false);
    hidden.stock_show_to_customer = false;
    hidden.stock_qty = Some(4);
    let off = product_card_html(&hidden, None);
    assert!(!off.contains("Stock:"));

    let mut missing = sample_product(false);
    missing.stock_show_to_customer = true;
    missing.stock_qty = None;
    let no_count = product_card_html(&missing, None);
    assert!(!no_count.contains("Stock:"));
}

#[test]
fn block_map_gated_by_booking() {
    let props = json!({"lat": 1.0, "lng": 2.0, "address": "Main St"});
    assert!(render_block("map", &props, &[], &json!({}), None).contains("class=\"map\""));
    assert!(render_block("map", &props, &[], &json!({"booking": false}), None).is_empty());
}

#[test]
fn block_hours_gated_by_booking() {
    let props = json!({"hours": [{"day": "Mon", "open": "09:00", "close": "17:00"}]});
    assert!(render_block("hours", &props, &[], &json!({}), None).contains("class=\"hours\""));
    assert!(render_block("hours", &props, &[], &json!({"booking": false}), None).is_empty());
}

#[test]
fn block_queue_gated_by_queue_capability() {
    let props = json!({"title": "Now serving", "mode": "walk-in"});
    assert!(render_block("queue", &props, &[], &json!({}), None).contains("class=\"queue\""));
    assert!(render_block("queue", &props, &[], &json!({"queue": false}), None).is_empty());
}

#[test]
fn block_embed_uses_sandboxed_iframe() {
    let html = render_block(
        "embed",
        &json!({"url": "https://example.com/embed", "height": 300}),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("<iframe sandbox=\"\""));
    assert!(html.contains("https://example.com/embed"));
}

#[test]
fn block_custom_html_strips_scripts() {
    let html = render_block(
        "custom_html",
        &json!({"html": "<p>safe</p><script>alert(1)</script><SCRIPT>x()</SCRIPT>"}),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("class=\"custom-html\""));
    assert!(html.contains("safe"));
    assert!(!html.to_ascii_lowercase().contains("script"));
    assert!(!html.contains("alert"));
}

#[test]
fn block_markdown_escapes_content() {
    let html = render_block(
        "markdown",
        &json!({"content": "<b>bold</b> & \"quoted\""}),
        &[],
        &json!({}),
        None,
    );
    assert!(html.contains("&lt;b&gt;"));
    assert!(!html.contains("<b>bold</b>"));
}

#[test]
fn social_feed_block_renders_hub_posts() {
    use c35_proto::SitePost;
    let post = SitePost {
        post_id: 7,
        title: "News".into(),
        caption: "Sub".into(),
        ..Default::default()
    };
    let html = block_html_render(
        "social_feed",
        &json!({"title": "Feed", "limit": 5}),
        &[],
        &json!({}),
        None,
        0,
        &[],
        &[post],
        None,
        &GuestDesign::from_theme_json(""),
        &[],
    );
    assert!(html.contains("posts/7"));
    assert!(html.contains("News"));
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
