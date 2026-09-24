mod catalog_price;
mod catalog_rank;
mod catalog_resolve;
mod catalog_sync;
mod fetch_catalog;
mod catalog_types;
mod cf_gateway;
mod cf_image;
mod embed_gemini;
mod llm_catalog;
mod model_catalog;
mod model_cost;
mod runtime_config;

use chrono::Utc;
use sqlx::PgPool;

pub use cf_gateway::cf_chat_generate;
pub use cf_image::{cf_grok_image_run, cf_image_provider_enabled};
pub use embed_gemini::embed_text;
pub use model_catalog::{
    model_chain_for_slug, model_is_alien, model_log_label, model_resolve_target, ModelTarget,
};
pub use catalog_sync::llm_catalog_spawn;
pub use fetch_catalog::{llm_catalog_nats_subscribe, LlmCatalogFetchTask};
pub use catalog_resolve::{catalog_alien_chain_build, catalog_alien_chain_effective, catalog_alien_default, catalog_provider_model};
pub use llm_catalog::{
    catalog_models, catalog_price, llm_catalog_init, llm_catalog_reload, prompt_models, provider_model_resolve, LlmModelRow,
};
pub use model_cost::model_cost_usd;
pub use runtime_config::{
    alien_chain_default, alien_chain_models, alien_default_model, cf_gateway_config, cf_gateway_from_env,
    cf_gateway_ready, model_is_flash_lite, runtime_config_init, runtime_config_reload,
    runtime_config_watch, CfGatewayRuntime,
};

pub const EMBED_TASK_DOCUMENT: &str = "retrieval_document";
pub const EMBED_TASK_QUERY: &str = "retrieval_query";

pub async fn alien_chain_init(pool: &PgPool) {
    runtime_config_init(pool).await;
}

pub fn embed_model_tag(model: &str, dimensions: i32) -> String {
    format!("{}@{}", model.trim(), dimensions)
}

pub fn embed_cache_key(text: &str, task: &str, dimensions: i32) -> String {
    let payload = format!("{}\0{}\0{}", text.trim(), task.trim(), dimensions);
    blake3::hash(payload.as_bytes()).to_hex().to_string()
}

pub fn embed_vec_to_bytes(vec: &[f32]) -> Vec<u8> {
    let mut out = Vec::with_capacity(vec.len() * 4);
    for v in vec {
        out.extend_from_slice(&v.to_le_bytes());
    }
    out
}

pub fn embed_bytes_to_vec(bytes: &[u8]) -> Option<Vec<f32>> {
    if bytes.len() % 4 != 0 {
        return None;
    }
    Some(
        bytes
            .chunks_exact(4)
            .map(|c| f32::from_le_bytes([c[0], c[1], c[2], c[3]]))
            .collect(),
    )
}

pub async fn embed_cache_get(
    pool: &PgPool,
    model: &str,
    key: &str,
) -> Result<Option<Vec<f32>>, sqlx::Error> {
    let row = sqlx::query_scalar::<_, Option<Vec<u8>>>(
        "SELECT embedding FROM ai.embed_cache WHERE model = $1 AND key = $2 LIMIT 1",
    )
    .bind(model)
    .bind(key)
    .fetch_optional(pool)
    .await?;
    Ok(row.flatten().and_then(|b| embed_bytes_to_vec(&b)))
}

pub async fn embed_cache_put(
    pool: &PgPool,
    model: &str,
    key: &str,
    text: &str,
    task: &str,
    embedding: &[f32],
    token_in: i32,
) -> Result<(), sqlx::Error> {
    let ts_ms = Utc::now().timestamp_millis();
    let bytes = embed_vec_to_bytes(embedding);
    sqlx::query(
        r#"
        INSERT INTO ai.embed_cache (model, key, text, embedding, task, token_in, ts_ms)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (model, key) DO UPDATE SET
            text = EXCLUDED.text,
            embedding = EXCLUDED.embedding,
            task = EXCLUDED.task,
            token_in = EXCLUDED.token_in,
            ts_ms = EXCLUDED.ts_ms
        "#,
    )
    .bind(model)
    .bind(key)
    .bind(text)
    .bind(bytes)
    .bind(task)
    .bind(token_in)
    .bind(ts_ms)
    .execute(pool)
    .await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn embed_cache_key_stable() {
        let a = embed_cache_key("hello", EMBED_TASK_QUERY, 768);
        let b = embed_cache_key("hello", EMBED_TASK_QUERY, 768);
        assert_eq!(a, b);
        assert_eq!(a.len(), 64);
    }

    #[test]
    fn embed_vec_roundtrip() {
        let v = vec![0.1_f32, -0.5, 1.0];
        let b = embed_vec_to_bytes(&v);
        assert_eq!(embed_bytes_to_vec(&b).unwrap(), v);
    }
}
