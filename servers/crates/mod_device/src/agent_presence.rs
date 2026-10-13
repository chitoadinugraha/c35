use async_nats::Client;
use c35_nats::user_app_subject_device_presence;
use c35_proto::{pb_encode, DevicePresencePush, WsRes, ws_res};
use chrono::Utc;
use serde_json::{json, Map, Value};
use sqlx::PgPool;
use tracing::warn;

/// Version + optional browser capability fields from the agent.
///
/// **Agent contract (WS query, log `meta` on `agent.ws` connected, or `agent.presence` log):**
/// - `browser_ready` (bool) — extension IPC connected on this desktop session
/// - `browser_engine` (string) — e.g. `extension` when unified path is active
/// - `extension_install_version` or `browser_install_version` (string) — MV3 manifest version
pub struct AgentVersionReport {
    pub build: i64,
    pub version_name: String,
    /// Browser keys merged into `ai.identity.meta` (may be non-empty when `build == 0`).
    pub browser_meta: Value,
}

/// Extract browser presence keys from agent JSON (unknown keys ignored).
pub fn agent_browser_meta_from_json(src: &Value) -> Value {
    let mut patch = Map::new();
    if let Some(v) = src.get("browser_ready") {
        if v.is_boolean() {
            patch.insert("browser_ready".into(), v.clone());
        }
    }
    if let Some(s) = src
        .get("browser_engine")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
    {
        patch.insert("browser_engine".into(), json!(s));
    }
    let install = src
        .get("extension_install_version")
        .or_else(|| src.get("browser_install_version"))
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty());
    if let Some(s) = install {
        patch.insert("extension_install_version".into(), json!(s));
    }
    Value::Object(patch)
}

pub fn agent_version_report_has_payload(v: &AgentVersionReport) -> bool {
    v.build > 0
        || v
            .browser_meta
            .as_object()
            .is_some_and(|m| !m.is_empty())
}

fn merge_version_into_patch(v: &AgentVersionReport, now: i64) -> Value {
    let mut patch = if v.build > 0 {
        let label = if v.version_name.is_empty() {
            format!("v{}", v.build)
        } else {
            format!("{} (v{})", v.version_name, v.build)
        };
        json!({
            "online": true,
            "last_seen_ts_ms": now,
            "agent_build": v.build,
            "agent_version_name": v.version_name,
            "agent_version": label,
        })
    } else {
        json!({
            "online": true,
            "last_seen_ts_ms": now,
        })
    };
    if let Some(extra) = v.browser_meta.as_object() {
        if let Some(obj) = patch.as_object_mut() {
            for (k, val) in extra {
                obj.insert(k.clone(), val.clone());
            }
        }
    }
    patch
}

/// Agent WS keepalive: fan out fresh `last_seen_ts_ms` on `c35.user.{owner}.app.device_presence`.
/// When `persist_db` is false, only NATS + in-memory meta merge (no YB write).
pub async fn agent_presence_heartbeat(
    pool: &PgPool,
    nats: Option<&Client>,
    device_iid: i64,
    owner_iid: i64,
    persist_db: bool,
) -> Result<(), String> {
    if owner_iid <= 0 {
        return Ok(());
    }
    let now = Utc::now().timestamp_millis();
    if persist_db {
        let patch = json!({
            "online": true,
            "last_seen_ts_ms": now,
        });
        sqlx::query(
            r#"
            UPDATE ai.identity
            SET meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb,
                updated_ts = NOW()
            WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
            "#,
        )
        .bind(device_iid)
        .bind(patch)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    }
    let meta = agent_meta_get(pool, device_iid).await?;
    let meta = merge_presence_touch(meta, now);
    device_presence_push(
        nats,
        owner_iid,
        DevicePresencePush {
            device_iid,
            online: true,
            meta_json: meta.to_string(),
            updated_ts_ms: now,
        },
    );
    Ok(())
}

fn merge_presence_touch(meta: Value, now: i64) -> Value {
    let mut obj = meta.as_object().cloned().unwrap_or_default();
    obj.insert("online".into(), json!(true));
    obj.insert("last_seen_ts_ms".into(), json!(now));
    Value::Object(obj)
}

pub async fn agent_presence_put(
    pool: &PgPool,
    nats: Option<&Client>,
    device_iid: i64,
    online: bool,
    version: Option<AgentVersionReport>,
) -> Result<(), String> {
    let now = Utc::now().timestamp_millis();
    let patch = if online {
        match version {
            Some(v) if agent_version_report_has_payload(&v) => merge_version_into_patch(&v, now),
            _ => json!({
                "online": true,
                "last_seen_ts_ms": now,
            }),
        }
    } else {
        json!({
            "online": false,
            "last_seen_ts_ms": now,
        })
    };
    sqlx::query(
        r#"
        UPDATE ai.identity
        SET meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb,
            updated_ts = NOW()
        WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .bind(patch)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let row = sqlx::query_as::<_, (Option<i64>, Value, i64)>(
        r#"
        SELECT owner_iid,
               COALESCE(meta, '{}'::jsonb),
               (EXTRACT(EPOCH FROM updated_ts) * 1000)::bigint
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    if let Some((owner_iid, meta, updated_ms)) = row {
        let owner = owner_iid.unwrap_or(0);
        if owner > 0 {
            device_presence_push(
                nats,
                owner,
                DevicePresencePush {
                    device_iid,
                    online,
                    meta_json: meta.to_string(),
                    updated_ts_ms: updated_ms,
                },
            );
        }
    }
    Ok(())
}

pub fn device_presence_push(nats: Option<&Client>, owner_iid: i64, push: DevicePresencePush) {
    if owner_iid <= 0 {
        return;
    }
    let Some(nc) = nats else { return };
    let ws = WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::DevicePresencePush(push)),
    };
    let subject = user_app_subject_device_presence(owner_iid);
    let bytes = pb_encode(&ws).into();
    let nc = nc.clone();
    tokio::spawn(async move {
        if let Err(e) = nc.publish(subject, bytes).await {
            warn!("device_presence_push: {e}");
        }
    });
}

/// Merge browser capability fields without touching online/version (agent `agent.presence` log).
pub async fn agent_presence_meta_merge(
    pool: &PgPool,
    nats: Option<&Client>,
    device_iid: i64,
    src: &Value,
) -> Result<(), String> {
    let patch = agent_browser_meta_from_json(src);
    if patch.as_object().is_none_or(|m| m.is_empty()) {
        return Ok(());
    }
    let now = Utc::now().timestamp_millis();
    let touch = json!({
        "last_seen_ts_ms": now,
    });
    let merged_patch = {
        let mut base = touch;
        if let Some(obj) = base.as_object_mut() {
            for (k, v) in patch.as_object().unwrap() {
                obj.insert(k.clone(), v.clone());
            }
        }
        base
    };
    sqlx::query(
        r#"
        UPDATE ai.identity
        SET meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb,
            updated_ts = NOW()
        WHERE id = $1 AND kind = 'remote' AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .bind(merged_patch)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let row = sqlx::query_as::<_, (Option<i64>, Value, i64)>(
        r#"
        SELECT owner_iid,
               COALESCE(meta, '{}'::jsonb),
               (EXTRACT(EPOCH FROM updated_ts) * 1000)::bigint
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    if let Some((owner_iid, meta, updated_ms)) = row {
        let owner = owner_iid.unwrap_or(0);
        let online = meta.get("online").and_then(|v| v.as_bool()).unwrap_or(false);
        if owner > 0 {
            device_presence_push(
                nats,
                owner,
                DevicePresencePush {
                    device_iid,
                    online,
                    meta_json: meta.to_string(),
                    updated_ts_ms: updated_ms,
                },
            );
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn agent_browser_meta_from_json_accepts_aliases() {
        let m = agent_browser_meta_from_json(&json!({
            "browser_ready": true,
            "browser_engine": "extension",
            "browser_install_version": "1.2.3",
        }));
        assert_eq!(m["browser_ready"], true);
        assert_eq!(m["browser_engine"], "extension");
        assert_eq!(m["extension_install_version"], "1.2.3");
    }
}

pub async fn agent_meta_get(pool: &PgPool, device_iid: i64) -> Result<Value, String> {
    let row = sqlx::query_scalar::<_, Value>(
        r#"SELECT COALESCE(meta, '{}'::jsonb) FROM ai.identity WHERE id = $1"#,
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.unwrap_or_else(|| json!({})))
}
