use c35_ctx::Ctx;
use c35_proto::NavCounts;
use c35_wire::WireResult;

pub async fn identity_nav_counts(ctx: &Ctx) -> WireResult<NavCounts> {
    let bots: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)::bigint FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.owner_iid = $1 AND i.kind = 'bot' AND i.deleted_ts IS NULL
          AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0
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

    // Match site_list: owned sites plus grantee access; exclude archived grants.
    let sites: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(DISTINCT i.id)::bigint
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL
          AND (i.owner_iid = $1 OR g.grantee_iid IS NOT NULL)
          AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0
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
