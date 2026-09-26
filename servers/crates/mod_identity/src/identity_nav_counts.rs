use c35_ctx::Ctx;
use c35_proto::NavCounts;
use c35_wire::WireResult;

pub async fn identity_nav_counts(ctx: &Ctx) -> WireResult<NavCounts> {
    let bots: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*) FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'bot' AND deleted_ts IS NULL
        "#,
    )
    .bind(ctx.caller_iid)
    .fetch_one(&ctx.pool)
    .await
    .unwrap_or(0);

    let devices: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*) FROM ai.identity
        WHERE owner_iid = $1 AND kind IN ('remote', 'iot') AND deleted_ts IS NULL
        "#,
    )
    .bind(ctx.caller_iid)
    .fetch_one(&ctx.pool)
    .await
    .unwrap_or(0);

    let sites: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*) FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'site' AND deleted_ts IS NULL
        "#,
    )
    .bind(ctx.caller_iid)
    .fetch_one(&ctx.pool)
    .await
    .unwrap_or(0);

    Ok(NavCounts {
        bots: bots as i32,
        devices: devices as i32,
        sites: sites as i32,
        mail_inbox_unread: 0,
        mail_menu_visible: false,
    })
}
