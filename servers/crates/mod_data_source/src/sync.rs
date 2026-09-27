use anyhow::{Context, Result};
use reqwest::Client;
use sqlx::{PgPool, Row};
use tracing::info;

use crate::chunk::{chunk_content_hash, chunk_embed_eligible, embed_normalize, sheet_csv_chunk_rows, snapshot_hash};
use crate::config::{data_source_sync_ttl_sec, DATA_SOURCE_SYNCING_STUCK_SEC, SOURCE_KIND_GOOGLE_SHEET};
use crate::google_sheet::{google_sheet_config_from_row, google_sheet_read_csv, sheet_tab_name};
use crate::store::{
    chunk_insert, chunks_delete_for_source, data_source_get, sync_row_get, sync_touch, sync_invalidate_row,
    sync_upsert_error, sync_upsert_ok, DataSourceRow,
};
use c35_mod_llm::{embed_cached, EMBED_TASK_DOCUMENT};

pub async fn data_source_sync_invalidate(pool: &PgPool, data_source_id: i64) {
    if data_source_id <= 0 {
        return;
    }
    let _ = sync_invalidate_row(pool, data_source_id).await;
}

pub async fn data_source_sync_if_stale(http: &Client, pool: &PgPool, data_source_id: i64) -> Result<()> {
    if data_source_id <= 0 {
        return Ok(());
    }
    if !sync_is_stale(pool, data_source_id).await? {
        return Ok(());
    }
    data_source_sync_run(http, pool, data_source_id).await
}

pub async fn data_source_sync_run(http: &Client, pool: &PgPool, data_source_id: i64) -> Result<()> {
    let row = data_source_get(pool, data_source_id)
        .await?
        .context("data_source not found")?;
    match row.source_kind.as_str() {
        SOURCE_KIND_GOOGLE_SHEET => google_sheet_sync_run(http, pool, &row).await,
        other => {
            let msg = format!("unsupported source_kind: {other}");
            let _ = sync_upsert_error(pool, data_source_id, other, &msg).await;
            anyhow::bail!(msg)
        }
    }
}

async fn google_sheet_sync_run(http: &Client, pool: &PgPool, row: &DataSourceRow) -> Result<()> {
    let cfg = google_sheet_config_from_row(row).context("google sheet config")?;
    let data_source_id = row.id;
    let tab = sheet_tab_name(&cfg);
    let csv = google_sheet_read_csv(http, &cfg).await.context("data source sync read csv")?;
    let hash = snapshot_hash(&csv);
    if let Some((existing, _)) = sync_row_get(pool, data_source_id).await? {
        if existing == hash && !hash.is_empty() {
            sync_touch(pool, data_source_id).await?;
            info!(
                "[c35:data_source] synced id={} hash_changed=false reason=unchanged",
                data_source_id
            );
            return Ok(());
        }
    }
    let (chunks, data_rows) = sheet_csv_chunk_rows(&csv, &tab);
    chunks_delete_for_source(pool, data_source_id).await?;
    let dims = crate::config::EMBED_DIMS;
    for spec in &chunks {
        let content_hash = chunk_content_hash(&spec.content);
        chunk_insert(
            pool,
            data_source_id,
            &spec.chunk_key,
            SOURCE_KIND_GOOGLE_SHEET,
            &spec.content,
            &content_hash,
            &spec.meta,
        )
        .await?;
        if chunk_embed_eligible(&spec.content) {
            let payload = embed_normalize(&spec.content);
            let _ = embed_cached(pool, http, &payload, EMBED_TASK_DOCUMENT, dims).await;
        }
    }
    sync_upsert_ok(pool, data_source_id, SOURCE_KIND_GOOGLE_SHEET, &hash, data_rows as i32).await?;
    info!(
        "[c35:data_source] synced id={} rows={} chunks={} hash_changed=true",
        data_source_id,
        data_rows,
        chunks.len()
    );
    Ok(())
}

async fn sync_is_stale(pool: &PgPool, data_source_id: i64) -> Result<bool> {
    let ttl = data_source_sync_ttl_sec();
    let row = sqlx::query(
        r#"
        SELECT snapshot_hash, status,
               EXTRACT(EPOCH FROM (NOW() - synced_ts))::bigint AS age_sec,
               EXTRACT(EPOCH FROM (NOW() - updated_ts))::bigint AS updated_age_sec
        FROM ai.data_source_sync WHERE data_source_id = $1
        "#,
    )
    .bind(data_source_id)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else { return Ok(true) };
    let hash: String = row.try_get("snapshot_hash").unwrap_or_default();
    let status: String = row.try_get("status").unwrap_or_default();
    let age_sec: i64 = row.try_get("age_sec").unwrap_or(ttl + 1);
    let updated_age_sec: i64 = row.try_get("updated_age_sec").unwrap_or(0);
    if status == "syncing" && updated_age_sec < DATA_SOURCE_SYNCING_STUCK_SEC {
        return Ok(false);
    }
    Ok(hash.is_empty() || !matches!(status.as_str(), "ok") || age_sec >= ttl)
}
