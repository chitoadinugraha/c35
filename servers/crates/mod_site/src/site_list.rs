use anyhow::Result;
use c35_proto::{ReqSiteList, ResSiteList, SiteRow};
use serde_json::Value;
use sqlx::{PgPool, Row};

fn grant_sort_order(meta: &Value) -> i32 {
    meta.get("sort_order")
        .and_then(|v| v.as_i64())
        .map(|n| n as i32)
        .unwrap_or(500)
}

pub async fn site_list(pool: &PgPool, caller_iid: i64, req: ReqSiteList) -> Result<ResSiteList> {
    let archived_clause = if req.archived {
        "AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) > 0"
    } else {
        "AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0"
    };
    let sql = format!(
        r#"
        SELECT i.id AS site_iid, i.alien_id, i.name, i.pic,
               COALESCE(c.published_version_id, '') AS published_version_id,
               GREATEST(i.updated_ts, COALESCE(c.updated_ts, i.updated_ts)) AS updated_ts,
               COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) AS archived_ts,
               COALESCE(g.is_pinned, false) AS is_pinned,
               g.meta AS grant_meta
        FROM ai.identity i
        LEFT JOIN site.config c ON c.site_iid = i.id AND c.deleted_ts IS NULL
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL
          AND (i.owner_iid = $1 OR g.grantee_iid IS NOT NULL)
          {archived_clause}
        ORDER BY COALESCE(g.is_pinned, false) DESC,
                 COALESCE((g.meta->>'sort_order')::int, 500),
                 GREATEST(i.updated_ts, COALESCE(c.updated_ts, i.updated_ts)) DESC
        "#,
        archived_clause = archived_clause
    );
    let rows = sqlx::query(&sql).bind(caller_iid).fetch_all(pool).await?;
    let archived_count = if req.archived {
        rows.len() as i32
    } else {
        0
    };
    Ok(ResSiteList {
        sites: rows
            .iter()
            .map(|r| {
                let grant_meta: Value = r
                    .try_get::<Option<Value>, _>("grant_meta")
                    .ok()
                    .flatten()
                    .unwrap_or(Value::Object(Default::default()));
                SiteRow {
                    site_iid: r.get("site_iid"),
                    alien_id: r
                        .try_get::<Option<String>, _>("alien_id")
                        .ok()
                        .flatten()
                        .unwrap_or_default(),
                    name: r.get("name"),
                    pic: r
                        .try_get::<Option<String>, _>("pic")
                        .ok()
                        .flatten()
                        .unwrap_or_default(),
                    published_version_id: r.get("published_version_id"),
                    updated_ts_ms: r
                        .get::<chrono::DateTime<chrono::Utc>, _>("updated_ts")
                        .timestamp_millis(),
                    is_archived: r.get::<i64, _>("archived_ts") > 0,
                    is_pinned: r.get("is_pinned"),
                    sort_order: grant_sort_order(&grant_meta),
                }
            })
            .collect(),
        archived_count,
    })
}
