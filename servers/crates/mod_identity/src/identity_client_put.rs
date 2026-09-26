use chrono::Utc;
use sqlx::PgPool;

pub async fn identity_client_put(
    pool: &PgPool,
    identity_iid: i64,
    dv: &str,
    client_id: &str,
    platform: i32,
    app_build: i64,
    app_version_name: &str,
) -> Result<(), String> {
    let dv = dv.trim();
    if dv.is_empty() || identity_iid <= 0 {
        return Ok(());
    }
    let now_ms = Utc::now().timestamp_millis();
    let client_id = client_id.trim();
    let app_version_name = app_version_name.trim();
    sqlx::query(
        r#"
        INSERT INTO ai.identity_client (
            identity_iid, dv, client_id, platform, app_build, app_version_name, last_ws_ts_ms, updated_ts
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
        ON CONFLICT (identity_iid, dv) DO UPDATE SET
            client_id = EXCLUDED.client_id,
            platform = EXCLUDED.platform,
            app_build = EXCLUDED.app_build,
            app_version_name = EXCLUDED.app_version_name,
            last_ws_ts_ms = EXCLUDED.last_ws_ts_ms,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(identity_iid)
    .bind(dv)
    .bind(client_id)
    .bind(platform)
    .bind(app_build)
    .bind(app_version_name)
    .bind(now_ms)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}