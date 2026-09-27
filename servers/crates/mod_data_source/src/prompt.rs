use reqwest::Client;
use sqlx::PgPool;
use tracing::warn;

use crate::config::{data_source_retrieve_limit, DATA_SOURCE_SMALL_ROW_LIMIT};
use crate::retrieve::data_source_chunk_retrieve;
use crate::store::{chunks_full_text, data_source_list_for_bot, sync_row_count};
use crate::sync::data_source_sync_if_stale;

pub fn data_source_prompt_block(title: &str, body: &str) -> String {
    let body = body.trim();
    if body.is_empty() {
        return String::new();
    }
    format!("## {title}\n{body}")
}

pub fn data_source_prompt_merge(base: &str, block: &str) -> String {
    let block = block.trim();
    if block.is_empty() {
        return base.to_string();
    }
    if base.trim().is_empty() {
        return block.to_string();
    }
    format!("{base}\n\n{block}")
}

pub async fn data_source_prompt_for_bot(
    pool: &PgPool,
    http: &Client,
    bot_iid: i64,
    query_text: &str,
) -> String {
    if bot_iid <= 0 {
        return String::new();
    }
    let bindings = data_source_list_for_bot(pool, bot_iid).await.unwrap_or_default();
    if bindings.is_empty() {
        return String::new();
    }
    let mut blocks: Vec<String> = Vec::new();
    for row in &bindings {
        if let Err(e) = data_source_sync_if_stale(http, pool, row.id).await {
            warn!("[c35:data_source] sync failed id={}: {e:#}", row.id);
        }
        let row_count = sync_row_count(pool, row.id).await;
        let title = format!("Sheet data ({})", row.name);
        if row_count <= DATA_SOURCE_SMALL_ROW_LIMIT {
            if let Ok(full) = chunks_full_text(pool, row.id).await {
                let block = data_source_prompt_block(&title, &full);
                if !block.is_empty() {
                    blocks.push(block);
                }
            }
        } else {
            let block = data_source_chunk_retrieve(
                pool,
                http,
                &[row.id],
                query_text,
                data_source_retrieve_limit(),
            ).await;
            if !block.is_empty() {
                blocks.push(data_source_prompt_block(&title, &block));
            }
        }
    }
    blocks.join("\n\n")
}
