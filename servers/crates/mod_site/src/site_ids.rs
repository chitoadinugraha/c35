use sqlx::PgPool;

pub(crate) async fn site_ids_for_caller(pool: &PgPool, caller_iid: i64) -> Vec<i64> {
    sqlx::query_scalar(
        r#"
        SELECT i.id
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL
          AND (i.owner_iid = $1 OR g.grantee_iid = $1)
        "#,
    )
    .bind(caller_iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
}
