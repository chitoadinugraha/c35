#[tokio::test]
async fn device_screenshot_artifact_row_db() {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        return;
    }
    use c35_mod_chat::tools::device_screenshot_artifact::device_screenshot_artifact_put;
    use c35_store::{migrate_apply, pool_connect, snowflake_id};

    let pool = pool_connect().await.expect("pool_connect");
    migrate_apply(&pool).await.expect("migrate_apply");

    let owner_iid = snowflake_id();
    let req_id = snowflake_id().to_string();
    let tool_call_id = snowflake_id().to_string();
    let jpeg: &[u8] = &[0xFF, 0xD8, 0xFF, 0xD9];

    let (hash, url) = device_screenshot_artifact_put(
        &pool,
        owner_iid,
        &req_id,
        &tool_call_id,
        "device.screenshot",
        12345,
        jpeg,
        4,
        4,
        true,
        false,
        0,
    )
    .await
    .expect("artifact put");

    assert!(!hash.is_empty());
    assert!(!url.is_empty());

    let row: (String, i32, i32) = sqlx::query_as(
        r#"
        SELECT hash_blake3, width, height
        FROM ai.tool_artifact
        WHERE owner_iid = $1 AND req_id = $2 AND tool_call_id = $3 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(&req_id)
    .bind(&tool_call_id)
    .fetch_one(&pool)
    .await
    .expect("artifact row");

    assert_eq!(row.0, hash);
    assert_eq!(row.1, 4);
    assert_eq!(row.2, 4);
}
