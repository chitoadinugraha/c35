use serde_json::{json, Value};
use sqlx::PgPool;

use crate::release_config::{
    client_platform_release_key, release_config_get, release_needs_update, release_summary,
};

pub async fn mcp_client_list(pool: &PgPool, owner_iid: i64) -> Value {
    let rows = sqlx::query_as::<_, (String, String, i32, i64, String, i64)>(
        r#"
        SELECT dv, client_id, platform, app_build, app_version_name, last_ws_ts_ms
        FROM ai.identity_client
        WHERE identity_iid = $1 AND deleted_ts IS NULL
        ORDER BY last_ws_ts_ms DESC
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await;

    match rows {
        Ok(list) => {
            let mut clients = Vec::new();
            for (dv, client_id, platform, app_build, app_version_name, last_ws_ts_ms) in list {
                let release = if let Some(key) = client_platform_release_key(platform) {
                    match release_config_get(pool, key).await.ok().flatten() {
                        Some(rel) => {
                            let (latest_build, latest_name, min_build) = release_summary(&rel);
                            json!({
                                "platform_key": key,
                                "release_latest_build": latest_build,
                                "release_latest_name": latest_name,
                                "release_min_build": min_build,
                                "needs_update": release_needs_update(app_build, &rel),
                            })
                        }
                        None => json!({}),
                    }
                } else {
                    json!({})
                };
                clients.push(json!({
                    "dv": dv,
                    "client_id": client_id,
                    "platform": platform,
                    "app_build": app_build,
                    "app_version_name": app_version_name,
                    "last_ws_ts_ms": last_ws_ts_ms,
                    "release": release,
                }));
            }
            json!({ "ok": true, "owner_iid": owner_iid, "count": clients.len(), "clients": clients })
        }
        Err(e) => json!({ "ok": false, "error": e.to_string() }),
    }
}