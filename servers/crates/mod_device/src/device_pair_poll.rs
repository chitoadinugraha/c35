use c35_proto::{ReqDevicePairPoll, ResDevicePairPoll};
use chrono::Utc;
use sqlx::{PgPool, Row};

pub async fn device_pair_poll(
    pool: &PgPool,
    req: ReqDevicePairPoll,
) -> Result<ResDevicePairPoll, String> {
    let secret = req.device_secret.trim();
    if secret.is_empty() {
        return Ok(expired_poll());
    }

    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, meta, (meta->>'pairing_expires_ms')::bigint AS exp_ms
        FROM ai.identity
        WHERE meta->>'device_secret' = $1 AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(secret)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    let Some(row) = row else {
        return Ok(expired_poll());
    };

    let device_iid: i64 = row.get("id");
    let owner_iid: Option<i64> = row.try_get("owner_iid").ok().flatten();
    let exp_ms: Option<i64> = row.try_get("exp_ms").ok().flatten();
    let now_ms = Utc::now().timestamp_millis();

    if owner_unclaimed(owner_iid) {
        if exp_ms.map(|e| e < now_ms).unwrap_or(true) {
            return Ok(expired_poll());
        }
        return Ok(ResDevicePairPoll {
            status: "pending".into(),
            session_key: String::new(),
            device_iid: 0,
        });
    }

    let meta = row.get::<serde_json::Value, _>("meta");
    let session_key = meta
        .get("session_key")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();

    Ok(ResDevicePairPoll {
        status: "claimed".into(),
        session_key,
        device_iid,
    })
}

fn owner_unclaimed(owner_iid: Option<i64>) -> bool {
    owner_iid.is_none() || owner_iid == Some(0)
}

fn expired_poll() -> ResDevicePairPoll {
    ResDevicePairPoll {
        status: "expired".into(),
        session_key: String::new(),
        device_iid: 0,
    }
}
