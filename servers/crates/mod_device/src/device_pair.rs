use c35_proto::{IdentityListRow, IdentityRow, ReqDevicePair, ResDevicePair};
use c35_store::snowflake_id;
use chrono::{DateTime, Utc};
use serde_json::Value;
use sqlx::{PgPool, Row};

pub async fn device_pair(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqDevicePair,
) -> Result<ResDevicePair, String> {
    let code = pair_code_normalize(&req.code)?;

    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    let device = sqlx::query(
        r#"
        SELECT id
        FROM ai.identity
        WHERE kind IN ('remote', 'iot')
          AND deleted_ts IS NULL
          AND meta->>'pairing_code' = $1
        LIMIT 1
        FOR UPDATE
        "#,
    )
    .bind(&code)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    let Some(device) = device else {
        return Err("pairing code not found or expired".into());
    };
    let device_iid: i64 = device.get("id");

    sqlx::query(
        r#"
        UPDATE ai.identity
        SET owner_iid = $2,
            meta = meta - 'pairing_code',
            updated_ts = NOW()
        WHERE id = $1
        "#,
    )
    .bind(device_iid)
    .bind(caller_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, is_pinned, meta)
        VALUES ($1, $2, $3, 'admin', false, '{}')
        ON CONFLICT (resource_iid, grantee_iid)
        DO UPDATE SET
            role = 'admin',
            deleted_ts = NULL,
            updated_ts = NOW()
        "#,
    )
    .bind(snowflake_id())
    .bind(device_iid)
    .bind(caller_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    let row = sqlx::query(
        r#"
        SELECT i.id, i.kind, i.type, i.alien_id, i.name, i.pic, i.meta, i.owner_iid, i.updated_ts,
               g.role, COALESCE(g.is_pinned, false) AS is_pinned, g.meta AS grant_meta
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.deleted_ts IS NULL
        "#,
    )
    .bind(device_iid)
    .bind(caller_iid)
    .fetch_one(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    tx.commit().await.map_err(|e| e.to_string())?;

    Ok(ResDevicePair {
        device: Some(identity_list_row_from_sql(&row)),
    })
}

fn pair_code_normalize(raw: &str) -> Result<String, String> {
    let code: String = raw
        .chars()
        .filter(|c| *c != '-')
        .collect::<String>()
        .to_uppercase();
    if code.len() != 10 {
        return Err("pairing code must be 10 characters".into());
    }
    if !code.chars().all(|c| c.is_ascii_alphanumeric()) {
        return Err("invalid pairing code".into());
    }
    Ok(code)
}

fn identity_list_row_from_sql(row: &sqlx::postgres::PgRow) -> IdentityListRow {
    let meta: Value = row.get("meta");
    let grant_meta: Value = row.try_get("grant_meta").unwrap_or(Value::Object(Default::default()));
    IdentityListRow {
        identity: Some(IdentityRow {
            iid: row.get("id"),
            kind: row.get("kind"),
            r#type: row.get("type"),
            alien_id: row
                .try_get::<Option<String>, _>("alien_id")
                .ok()
                .flatten()
                .unwrap_or_default(),
            name: row.get("name"),
            pic: row
                .try_get::<Option<String>, _>("pic")
                .ok()
                .flatten()
                .unwrap_or_default(),
            meta_json: meta.to_string(),
            owner_iid: row.try_get("owner_iid").unwrap_or(0),
            updated_ts_ms: ts_to_ms(row.get("updated_ts")),
        }),
        grant_role: row.try_get::<Option<String>, _>("role").ok().flatten().unwrap_or_default(),
        is_pinned: row.get("is_pinned"),
        sort_order: grant_meta
            .get("sort_order")
            .and_then(|v| v.as_i64())
            .map(|v| v as i32)
            .unwrap_or(500),
        archived_ts_ms: grant_meta
            .get("archived_ts_ms")
            .and_then(|v| v.as_i64())
            .unwrap_or(0),
    }
}

fn ts_to_ms(ts: DateTime<Utc>) -> i64 {
    ts.timestamp_millis()
}
