use chrono::Utc;
use serde_json::{json, Value};
use sqlx::PgPool;

use crate::release_config::{release_config_get, release_needs_update, release_summary};

fn cloud_online_from_meta(meta: &Value) -> bool {
    if meta.get("online").and_then(|v| v.as_bool()) == Some(false) {
        return false;
    }
    let now = Utc::now().timestamp_millis();
    let last = meta
        .get("last_seen_ts_ms")
        .or_else(|| meta.get("last_seen_ms"))
        .or_else(|| meta.get("last_seen"))
        .and_then(|v| v.as_i64())
        .unwrap_or(0);
    if last <= 0 {
        return meta.get("online").and_then(|v| v.as_bool()) == Some(true);
    }
    now - last < 120_000
}

async fn device_release_fields_async(pool: &PgPool, meta: &Value) -> Value {
    let agent_build = meta.get("agent_build").and_then(|v| v.as_i64()).unwrap_or(0);
    let rel = release_config_get(pool, "remote-windows").await.ok().flatten();
    let Some(rel) = rel else {
        return json!({
            "agent_build": agent_build,
            "agent_version_name": meta.get("agent_version_name"),
            "agent_version": meta.get("agent_version"),
        });
    };
    let (latest_build, latest_name, min_build) = release_summary(&rel);
    json!({
        "agent_build": agent_build,
        "agent_version_name": meta.get("agent_version_name"),
        "agent_version": meta.get("agent_version"),
        "release_latest_build": latest_build,
        "release_latest_name": latest_name,
        "release_min_build": min_build,
        "needs_update": release_needs_update(agent_build, &rel),
    })
}

pub async fn mcp_device_list(pool: &PgPool, owner_iid: i64) -> Value {
    let rows = sqlx::query_as::<_, (i64, String, String, Value)>(
        r#"
        SELECT id, name, type, COALESCE(meta, '{}'::jsonb)
        FROM ai.identity
        WHERE owner_iid = $1 AND kind = 'remote' AND deleted_ts IS NULL
        ORDER BY id DESC
        "#,
    )
    .bind(owner_iid)
    .fetch_all(pool)
    .await;

    match rows {
        Ok(list) => {
            let mut devices = Vec::new();
            for (id, name, typ, meta) in list {
                let release = device_release_fields_async(pool, &meta).await;
                devices.push(json!({
                    "device_iid": id,
                    "name": name,
                    "type": typ,
                    "cloud_online": cloud_online_from_meta(&meta),
                    "online": meta.get("online"),
                    "last_seen_ts_ms": meta.get("last_seen_ts_ms"),
                    "release": release,
                }));
            }
            json!({ "ok": true, "owner_iid": owner_iid, "count": devices.len(), "devices": devices })
        }
        Err(e) => json!({ "ok": false, "error": e.to_string() }),
    }
}

pub async fn mcp_device_get(pool: &PgPool, owner_iid: i64, device_iid: i64) -> Value {
    let row = sqlx::query_as::<_, (i64, i64, String, String, Value)>(
        r#"
        SELECT id, owner_iid, name, type, COALESCE(meta, '{}'::jsonb)
        FROM ai.identity
        WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await;

    match row {
        Ok(Some((id, row_owner, name, typ, meta))) if row_owner == owner_iid => {
            let release = device_release_fields_async(pool, &meta).await;
            json!({
                "ok": true,
                "device_iid": id,
                "owner_iid": row_owner,
                "name": name,
                "type": typ,
                "cloud_online": cloud_online_from_meta(&meta),
                "meta": meta,
                "release": release,
            })
        }
        Ok(Some(_)) => json!({ "ok": false, "error": "device not owned by this owner_iid" }),
        Ok(None) => json!({ "ok": false, "error": "device not found" }),
        Err(e) => json!({ "ok": false, "error": e.to_string() }),
    }
}