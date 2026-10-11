use c35_mod_site::{
    site_editor_warm, site_editor_warm_product_limit, SITE_EDITOR_WARM_PRODUCT_DEFAULT,
    SITE_EDITOR_WARM_PRODUCT_MAX,
};
use c35_proto::ReqSiteEditorWarm;

#[test]
fn site_editor_warm_product_limit_defaults_and_caps() {
    assert_eq!(site_editor_warm_product_limit(0), SITE_EDITOR_WARM_PRODUCT_DEFAULT);
    assert_eq!(site_editor_warm_product_limit(-1), SITE_EDITOR_WARM_PRODUCT_DEFAULT);
    assert_eq!(site_editor_warm_product_limit(30), 30);
    assert_eq!(site_editor_warm_product_limit(100), SITE_EDITOR_WARM_PRODUCT_MAX);
}

#[tokio::test]
async fn site_editor_warm_rejects_missing_site_iid() {
    let pool = sqlx::PgPool::connect_lazy("postgres://invalid").expect("lazy pool");
    let err = site_editor_warm(&pool, 1, ReqSiteEditorWarm { site_iid: 0, product_limit: 0 })
        .await
        .expect_err("site_iid required");
    assert!(err.to_string().contains("site_iid"));
}

/// Requires YSQL with site schema and a site the caller can read (e.g. owner 99000 fixture).
#[tokio::test]
#[ignore]
async fn site_editor_warm_returns_parallel_catalog_slices() {
    let pool = c35_store::pool_connect().await.expect("pool");
    let caller_iid: i64 = std::env::var("C35_SITE_WARM_TEST_CALLER")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(99_000);
    let site_iid: i64 = std::env::var("C35_SITE_WARM_TEST_SITE")
        .ok()
        .and_then(|s| s.parse().ok())
        .expect("set C35_SITE_WARM_TEST_SITE to a site_iid the caller can access");
    let res = site_editor_warm(
        &pool,
        caller_iid,
        ReqSiteEditorWarm {
            site_iid,
            product_limit: 5,
        },
    )
    .await
    .expect("site_editor_warm");
    assert!(res.products.len() <= 5);
}
