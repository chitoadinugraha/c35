use anyhow::{Context, Result};
use c35_proto::MentionCatalog;
use c35_store::missing_table;
use chrono::Utc;
use prost::Message;
use sqlx::{PgPool, Row};
use tracing::warn;

use crate::mention_registry::mention_items_build;

pub async fn mention_bundle_get(pool: &PgPool, user_iid: i64, since_ms: i64) -> Result<MentionCatalog> {
    let row = sqlx::query("SELECT updated_ts_ms, body FROM ai.mention_bundle WHERE user_iid = $1")
        .bind(user_iid)
        .fetch_optional(pool)
        .await;

    match row {
        Ok(Some(r)) => {
            let updated_ts_ms: i64 = r.get("updated_ts_ms");
            let body: Vec<u8> = r.get("body");
            if updated_ts_ms > 0 && since_ms >= updated_ts_ms {
                return Ok(MentionCatalog {
                    rev: updated_ts_ms,
                    items: vec![],
                });
            }
            if !body.is_empty() {
                return MentionCatalog::decode(body.as_slice()).context("mention_bundle decode");
            }
        }
        Ok(None) => {}
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "mention_bundle_get: ai.mention_bundle missing");
        }
        Err(e) => return Err(e.into()),
    }
    mention_bundle_compile(pool, user_iid).await
}

pub async fn mention_bundle_compile(pool: &PgPool, user_iid: i64) -> Result<MentionCatalog> {
    let items = mention_items_build(pool, user_iid).await;
    let updated_ts_ms = Utc::now().timestamp_millis();
    let catalog = MentionCatalog {
        rev: updated_ts_ms,
        items,
    };
    let body = catalog.encode_to_vec();
    if let Err(e) = sqlx::query(
        r#"
        INSERT INTO ai.mention_bundle (user_iid, updated_ts_ms, body, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (user_iid) DO UPDATE SET
            updated_ts_ms = EXCLUDED.updated_ts_ms,
            body = EXCLUDED.body,
            updated_ts = NOW()
        "#,
    )
    .bind(user_iid)
    .bind(updated_ts_ms)
    .bind(&body)
    .execute(pool)
    .await
    {
        if !missing_table(&e) {
            return Err(e.into());
        }
        warn!(error = %e, "mention_bundle_compile: ai.mention_bundle missing");
    }
    Ok(catalog)
}

pub async fn mention_list_bundle_rpc(pool: &PgPool, caller_iid: i64, since_ms: i64) -> c35_proto::ResMentionList {
    match mention_bundle_get(pool, caller_iid, since_ms).await {
        Ok(catalog) => c35_proto::ResMentionList {
            rev: catalog.rev,
            mentions: catalog.items,
        },
        Err(e) => {
            warn!(error = %e, caller_iid, "mention_bundle_get failed");
            let items = mention_items_build(pool, caller_iid).await;
            c35_proto::ResMentionList {
                rev: Utc::now().timestamp_millis(),
                mentions: items,
            }
        }
    }
}
