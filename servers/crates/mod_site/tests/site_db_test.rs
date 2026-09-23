//! Integration tests — require YSQL with site schema.

#[tokio::test]
#[ignore]
async fn site_list_empty_for_unknown_caller() {
    let pool = c35_store::pool_connect().await.expect("pool");
    let res = c35_mod_site::site_list(&pool, 0, c35_proto::ReqSiteList { archived: false })
        .await
        .expect("site_list");
    assert!(res.sites.is_empty());
}
