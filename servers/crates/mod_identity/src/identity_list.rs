use anyhow::{anyhow, Result};
use chrono::{DateTime, Utc};
use c35_proto::{IdentityListRow, IdentityRow, ReqIdentityList, ResIdentityList};
use serde_json::Value;
use sqlx::{PgPool, Row};

pub(crate) fn ts_ms(t: Option<DateTime<Utc>>) -> i64 {
    t.map(|x| x.timestamp_millis()).unwrap_or(0)
}

fn meta_i32(meta: &Value, key: &str, default: i32) -> i32 {
    meta.get(key)
        .and_then(|v| v.as_i64())
        .map(|n| n as i32)
        .unwrap_or(default)
}

fn meta_i64(meta: &Value, key: &str) -> i64 {
    meta.get(key).and_then(|v| v.as_i64()).unwrap_or(0)
}

pub(crate) fn row_to_list_row(r: &sqlx::postgres::PgRow) -> IdentityListRow {
    let grant_meta: Value = r
        .try_get::<Option<Value>, _>("grant_meta")
        .ok()
        .flatten()
        .unwrap_or(Value::Object(Default::default()));
    let identity_meta: Value = r.get("meta");
    IdentityListRow {
        identity: Some(IdentityRow {
            iid: r.get("id"),
            kind: r.get("kind"),
            r#type: r.get("type"),
            alien_id: r
                .try_get::<Option<String>, _>("alien_id")
                .ok()
                .flatten()
                .unwrap_or_default(),
            name: r.get("name"),
            pic: r.try_get::<Option<String>, _>("pic").ok().flatten().unwrap_or_default(),
            meta_json: identity_meta.to_string(),
            owner_iid: r.get("owner_iid"),
            updated_ts_ms: ts_ms(r.get("updated_ts")),
        }),
        grant_role: r.try_get::<Option<String>, _>("role").ok().flatten().unwrap_or_default(),
        is_pinned: r.get("is_pinned"),
        sort_order: meta_i32(&grant_meta, "sort_order", 500),
        archived_ts_ms: meta_i64(&grant_meta, "archived_ts_ms"),
    }
}

pub async fn identity_list(pool: &PgPool, caller_iid: i64, req: ReqIdentityList) -> Result<ResIdentityList> {
    if req.kinds.is_empty() {
        return Ok(ResIdentityList { rows: vec![] });
    }
    let archived_clause = if req.include_archived {
        ""
    } else {
        "AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0"
    };
    let sql = format!(
        r#"
        SELECT i.id, i.kind, i.type, i.alien_id, i.name, i.pic, i.meta, i.owner_iid, i.updated_ts,
               g.role, COALESCE(g.is_pinned, false) AS is_pinned, g.meta AS grant_meta
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.deleted_ts IS NULL
          AND i.kind = ANY($2::text[])
          AND (i.owner_iid = $1 OR g.grantee_iid = $1)
          {archived_clause}
        ORDER BY COALESCE(g.is_pinned, false) DESC,
                 COALESCE((g.meta->>'sort_order')::int, 500),
                 i.updated_ts DESC
        "#,
        archived_clause = archived_clause
    );
    let rows = sqlx::query(&sql)
        .bind(caller_iid)
        .bind(&req.kinds)
        .fetch_all(pool)
        .await?;
    Ok(ResIdentityList {
        rows: rows.iter().map(row_to_list_row).collect(),
    })
}

pub(crate) async fn identity_list_row_get(pool: &PgPool, caller_iid: i64, resource_iid: i64) -> Result<IdentityListRow> {
    let row = sqlx::query(
        r#"
        SELECT i.id, i.kind, i.type, i.alien_id, i.name, i.pic, i.meta, i.owner_iid, i.updated_ts,
               g.role, COALESCE(g.is_pinned, false) AS is_pinned, g.meta AS grant_meta
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.deleted_ts IS NULL
          AND (i.owner_iid = $2 OR g.grantee_iid = $2)
        "#,
    )
    .bind(resource_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("identity not found"))?;
    Ok(row_to_list_row(&row))
}
