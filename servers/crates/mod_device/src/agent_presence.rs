use async_nats::Client;
use c35_nats::user_app_subject_device_presence;
use c35_proto::{pb_encode, DevicePresencePush, WsRes, ws_res};
use chrono::Utc;
use serde_json::{json, Value};
use sqlx::PgPool;
use tracing::warn;

pub struct AgentVersionReport {
    pub build: i64,
    pub version_name: String,
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
            Some(v) if v.build > 0 => {
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
            }
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
