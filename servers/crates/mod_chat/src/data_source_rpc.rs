use anyhow::{anyhow, Result};
use chrono::{DateTime, Utc};
use c35_proto::{
    DataSourceDoc, DataSourceSheetTab, ReqDataSourceCheck, ReqDataSourceDelete, ReqDataSourceList, ReqDataSourcePut,
    ReqDataSourceSync, ResDataSourceCheck, ResDataSourceDelete, ResDataSourceList, ResDataSourcePut, ResDataSourceSync,
};
use c35_mod_data_source::{
    config_merge_doc_url, config_merge_sheet_url, config_merge_slide_url, config_normalize_access_mode,
    data_source_check_run, SOURCE_KIND_GOOGLE_DOC,
    SOURCE_KIND_GOOGLE_SLIDE,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::bot_peer::bot_access_verify;
use crate::inbox::ts_ms;

async fn data_source_owned_get(pool: &PgPool, caller_iid: i64, id: i64) -> Result<()> {
    if id == 0 {
        return Err(anyhow!("id required"));
    }
    let ok = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS (
            SELECT 1 FROM ai.data_source
            WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        )
        "#,
    )
    .bind(id)
    .bind(caller_iid)
    .fetch_one(pool)
    .await?;
    if !ok {
        return Err(anyhow!("data source not found or access denied"));
    }
    Ok(())
}

fn row_to_doc(r: sqlx::postgres::PgRow) -> DataSourceDoc {
    let config = r.get::<serde_json::Value, _>("config");
    DataSourceDoc {
        id: r.get("id"),
        bot_iid: r.get::<Option<i64>, _>("bot_iid").unwrap_or(0),
        source_kind: r.get("source_kind"),
        name: r.get("name"),
        config_json: config.to_string(),
        sync_status: r.get::<Option<String>, _>("sync_status").unwrap_or_default(),
        row_count: r.get::<Option<i32>, _>("row_count").unwrap_or(0),
        synced_ts_ms: ts_ms(r.get::<Option<DateTime<Utc>>, _>("synced_ts")),
        updated_ts_ms: ts_ms(r.get("updated_ts")),
    }
}

async fn data_source_doc_fetch(pool: &PgPool, caller_iid: i64, id: i64) -> Result<DataSourceDoc> {
    let row = sqlx::query(
        r#"
        SELECT d.id, d.bot_iid, d.source_kind, d.name, d.config, d.updated_ts,
               s.status AS sync_status, s.row_count, s.synced_ts
        FROM ai.data_source d
        LEFT JOIN ai.data_source_sync s ON s.data_source_id = d.id
        WHERE d.id = $1 AND d.owner_iid = $2 AND d.deleted_ts IS NULL
        "#,
    )
    .bind(id)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?;
    row.map(row_to_doc).ok_or_else(|| anyhow!("data source not found"))
}

pub async fn data_source_list(pool: &PgPool, caller_iid: i64, req: ReqDataSourceList) -> Result<ResDataSourceList> {
    if req.bot_iid > 0 {
        bot_access_verify(pool, caller_iid, req.bot_iid).await?;
    }
    let limit = if req.limit <= 0 { 100 } else { req.limit.min(500) };
    let since = req.since_updated_ts_ms;
    let rows = if req.bot_iid > 0 {
        sqlx::query(
            r#"
            SELECT d.id, d.bot_iid, d.source_kind, d.name, d.config, d.updated_ts,
                   s.status AS sync_status, s.row_count, s.synced_ts
            FROM ai.data_source d
            LEFT JOIN ai.data_source_sync s ON s.data_source_id = d.id
            WHERE d.owner_iid = $1 AND d.bot_iid = $2 AND d.deleted_ts IS NULL
              AND ($3 <= 0 OR d.updated_ts > to_timestamp($3 / 1000.0))
            ORDER BY d.updated_ts DESC
            LIMIT $4
            "#,
        )
        .bind(caller_iid)
        .bind(req.bot_iid)
        .bind(since)
        .bind(limit)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT d.id, d.bot_iid, d.source_kind, d.name, d.config, d.updated_ts,
                   s.status AS sync_status, s.row_count, s.synced_ts
            FROM ai.data_source d
            LEFT JOIN ai.data_source_sync s ON s.data_source_id = d.id
            WHERE d.owner_iid = $1 AND d.deleted_ts IS NULL
              AND ($2 <= 0 OR d.updated_ts > to_timestamp($2 / 1000.0))
            ORDER BY d.updated_ts DESC
            LIMIT $3
            "#,
        )
        .bind(caller_iid)
        .bind(since)
        .bind(limit)
        .fetch_all(pool)
        .await?
    };
    let items = rows.into_iter().map(row_to_doc).collect();
    Ok(ResDataSourceList { items })
}

pub async fn data_source_put(pool: &PgPool, caller_iid: i64, req: ReqDataSourcePut) -> Result<ResDataSourcePut> {
    let doc = req.doc.ok_or_else(|| anyhow!("doc required"))?;
    let source_kind = doc.source_kind.trim();
    let name = doc.name.trim();
    if source_kind.is_empty() {
        return Err(anyhow!("source_kind required"));
    }
    if name.is_empty() {
        return Err(anyhow!("name required"));
    }
    if doc.bot_iid > 0 {
        bot_access_verify(pool, caller_iid, doc.bot_iid).await?;
    }
    let mut config: serde_json::Value = if doc.config_json.trim().is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&doc.config_json).map_err(|e| anyhow!("invalid config_json: {e}"))?
    };
    if let Some(url) = config
        .get("view_url")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
    {
        match source_kind {
            "google_sheet" => config_merge_sheet_url(&mut config, &url)?,
            SOURCE_KIND_GOOGLE_DOC => config_merge_doc_url(&mut config, &url)?,
            SOURCE_KIND_GOOGLE_SLIDE => config_merge_slide_url(&mut config, &url)?,
            _ => {}
        }
    }
    config_normalize_access_mode(&mut config, source_kind);
    let bot_iid: Option<i64> = if doc.bot_iid > 0 { Some(doc.bot_iid) } else { None };
    let id = if doc.id > 0 {
        data_source_owned_get(pool, caller_iid, doc.id).await?;
        sqlx::query(
            r#"
            UPDATE ai.data_source
            SET bot_iid = $3, source_kind = $4, name = $5, config = $6, updated_ts = NOW()
            WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
            "#,
        )
        .bind(doc.id)
        .bind(caller_iid)
        .bind(bot_iid)
        .bind(source_kind)
        .bind(name)
        .bind(config)
        .execute(pool)
        .await?;
        doc.id
    } else {
        let id = snowflake_id();
        sqlx::query(
            r#"
            INSERT INTO ai.data_source (id, owner_iid, bot_iid, source_kind, name, config)
            VALUES ($1, $2, $3, $4, $5, $6)
            "#,
        )
        .bind(id)
        .bind(caller_iid)
        .bind(bot_iid)
        .bind(source_kind)
        .bind(name)
        .bind(config)
        .execute(pool)
        .await?;
        sqlx::query(
            r#"
            INSERT INTO ai.data_source_sync (data_source_id, source_kind, status)
            VALUES ($1, $2, 'stale')
            ON CONFLICT (data_source_id) DO NOTHING
            "#,
        )
        .bind(id)
        .bind(source_kind)
        .execute(pool)
        .await?;
        id
    };
    let out = data_source_doc_fetch(pool, caller_iid, id).await?;
    Ok(ResDataSourcePut { id, doc: Some(out) })
}

pub async fn data_source_delete(pool: &PgPool, caller_iid: i64, req: ReqDataSourceDelete) -> Result<ResDataSourceDelete> {
    data_source_owned_get(pool, caller_iid, req.id).await?;
    sqlx::query(
        r#"
        UPDATE ai.data_source
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
        "#,
    )
    .bind(req.id)
    .bind(caller_iid)
    .execute(pool)
    .await?;
    Ok(ResDataSourceDelete { ok: true })
}

pub async fn data_source_check(_pool: &PgPool, _caller_iid: i64, req: ReqDataSourceCheck) -> Result<ResDataSourceCheck> {
    let source_kind = req.source_kind.trim();
    let view_url = req.view_url.trim();
    if source_kind.is_empty() {
        return Err(anyhow!("source_kind required"));
    }
    if view_url.is_empty() {
        return Err(anyhow!("view_url required"));
    }
    let http = crate::tools::http_client(std::time::Duration::from_secs(30));
    match data_source_check_run(&http, source_kind, view_url).await {
        Ok(res) => Ok(ResDataSourceCheck {
            ok: true,
            error_msg: String::new(),
            title: res.title,
            config_json: res.config.to_string(),
            tabs: res
                .tabs
                .into_iter()
                .map(|t| DataSourceSheetTab {
                    title: t.title,
                    gid: t.gid,
                })
                .collect(),
        }),
        Err(e) => Ok(ResDataSourceCheck {
            ok: false,
            error_msg: e.to_string(),
            title: String::new(),
            config_json: String::new(),
            tabs: vec![],
        }),
    }
}

pub async fn data_source_sync(pool: &PgPool, caller_iid: i64, req: ReqDataSourceSync) -> Result<ResDataSourceSync> {
    data_source_owned_get(pool, caller_iid, req.id).await?;
    let http = crate::tools::http_client(std::time::Duration::from_secs(60));
    c35_mod_data_source::data_source_sync_run(&http, pool, req.id)
        .await
        .map_err(|e| anyhow!("sync failed: {e:#}"))?;
    let doc = data_source_doc_fetch(pool, caller_iid, req.id).await?;
    Ok(ResDataSourceSync { doc: Some(doc) })
}