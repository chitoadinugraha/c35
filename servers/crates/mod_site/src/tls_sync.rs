//! cert-manager TLS sync stub — updates tls_status when in-cluster.

use tracing::info;

pub async fn domain_tls_ensure(hostname: &str) -> String {
    if std::env::var("C35_TLS_SYNC_ENABLED")
        .map(|v| v == "1" || v.eq_ignore_ascii_case("true"))
        .unwrap_or(false)
    {
        info!("tls_sync: ensure cert for {}", hostname);
        return "pending".into();
    }
    "disabled".into()
}

pub async fn domain_tls_status_sync(pool: &sqlx::PgPool, domain_id: i64, status: &str) {
    let _ = sqlx::query(
        r#"
        UPDATE site.domain SET tls_status = $2, updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(domain_id)
    .bind(status)
    .execute(pool)
    .await;
}
