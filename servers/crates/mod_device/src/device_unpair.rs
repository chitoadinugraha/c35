use async_nats::Client;
use sqlx::{PgPool, Row};

use crate::agent_log_put::agent_log_put;
use crate::agent_presence::agent_presence_put;
use crate::remote_signaling::remote_agent_send_raw;

pub const DEVICE_UNPAIR_PUSH: &[u8] = b"c35.unpair";

pub async fn device_unpair(
    pool: &PgPool,
    nats: Option<&Client>,
    device_iid: i64,
) -> Result<(), String> {
    if device_iid <= 0 {
        return Err("invalid device_iid".into());
    }
    let row = sqlx::query(
        "SELECT kind, owner_iid FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = row else {
        device_unpair_notify(nats, device_iid).await?;
        return Ok(());
    };
    let kind: String = row.get("kind");
    if kind != "remote" && kind != "iot" {
        return Err("not a device identity".into());
    }
    let owner_iid: i64 = row.try_get("owner_iid").ok().flatten().unwrap_or(0);

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    sqlx::query("UPDATE ai.identity SET deleted_ts = NOW(), updated_ts = NOW() WHERE id = $1")
        .bind(device_iid)
        .execute(&mut *tx)
        .await
        .map_err(|e| e.to_string())?;
    sqlx::query(
        "UPDATE ai.identity_grant SET deleted_ts = NOW(), updated_ts = NOW() WHERE resource_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(device_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    tx.commit().await.map_err(|e| e.to_string())?;

    let _ = agent_presence_put(pool, device_iid, false, None).await;
    let _ = agent_log_put(
        pool,
        nats,
        device_iid,
        owner_iid,
        "conn",
        "agent.unpair",
        "unpaired",
        None,
    )
    .await;

    device_unpair_notify(nats, device_iid).await?;
    Ok(())
}

pub async fn device_unpair_notify(
    nats: Option<&Client>,
    device_iid: i64,
) -> Result<(), String> {
    remote_agent_send_raw(nats, device_iid, DEVICE_UNPAIR_PUSH.to_vec()).await?;
    Ok(())
}
