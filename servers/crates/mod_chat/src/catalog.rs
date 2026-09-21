use std::collections::HashMap;

use c35_store::missing_table;
use serde::Serialize;
use sqlx::PgPool;
use tracing::warn;

#[derive(Debug, Clone, Serialize)]
pub struct CatalogMentionRow {
    pub id: String,
    pub topic_id: String,
    pub icon: String,
    pub color: String,
    pub sort: i32,
    pub label_key: String,
    pub caption_key: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct CatalogTopicRow {
    pub id: String,
    pub label_key: String,
    pub extend: String,
    pub sort: i32,
}

pub async fn translation_get(
    pool: &PgPool,
    lang: &str,
    categories: &[String],
) -> HashMap<String, String> {
    let lang = lang.trim();
    if lang.is_empty() {
        return HashMap::new();
    }
    let rows = if categories.is_empty() {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, text FROM ai.translation WHERE lang = $1 ORDER BY key ASC",
        )
        .bind(lang)
        .fetch_all(pool)
        .await
    } else {
        sqlx::query_as::<_, (String, String)>(
            "SELECT key, text FROM ai.translation WHERE lang = $1 AND category = ANY($2) ORDER BY key ASC",
        )
        .bind(lang)
        .bind(categories)
        .fetch_all(pool)
        .await
    };
    match rows {
        Ok(rows) => rows.into_iter().collect(),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "translation_get: ai.translation missing");
            HashMap::new()
        }
        Err(e) => {
            warn!(error = %e, lang = %lang, "translation_get failed");
            HashMap::new()
        }
    }
}

pub async fn translation_rev(pool: &PgPool) -> i64 {
    let row = sqlx::query_scalar::<_, Option<i64>>(
        "SELECT COALESCE(FLOOR(EXTRACT(EPOCH FROM MAX(updated_ts)))::BIGINT, 0) FROM ai.translation",
    )
    .fetch_one(pool)
    .await;
    match row {
        Ok(rev) => rev.unwrap_or(0),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "translation_rev: ai.translation missing");
            0
        }
        Err(e) => {
            warn!(error = %e, "translation_rev failed");
            0
        }
    }
}

pub async fn mention_list(pool: &PgPool) -> Vec<CatalogMentionRow> {
    let rows = sqlx::query_as::<_, (String, Option<String>, String, String, i32, String, String)>(
        "SELECT id, topic_id, icon, color, sort, label_key, caption_key \
         FROM ai.mention WHERE enabled = true ORDER BY sort ASC, id ASC",
    )
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) => rows
            .into_iter()
            .map(|(id, topic_id, icon, color, sort, label_key, caption_key)| CatalogMentionRow {
                id,
                topic_id: topic_id.unwrap_or_default(),
                icon,
                color,
                sort,
                label_key,
                caption_key,
            })
            .collect(),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "mention_list: ai.mention missing");
            Vec::new()
        }
        Err(e) => {
            warn!(error = %e, "mention_list failed");
            Vec::new()
        }
    }
}

pub async fn topic_list(pool: &PgPool) -> Vec<CatalogTopicRow> {
    let rows = sqlx::query_as::<_, (String, String, String, i32)>(
        "SELECT id, label_key, extend, sort FROM ai.topic WHERE enabled = true ORDER BY sort ASC, id ASC",
    )
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) => rows
            .into_iter()
            .map(|(id, label_key, extend, sort)| CatalogTopicRow {
                id,
                label_key,
                extend,
                sort,
            })
            .collect(),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "topic_list: ai.topic missing");
            Vec::new()
        }
        Err(e) => {
            warn!(error = %e, "topic_list failed");
            Vec::new()
        }
    }
}
