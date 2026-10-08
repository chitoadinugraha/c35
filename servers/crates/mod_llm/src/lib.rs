mod catalog_price;
mod catalog_pricing;
mod catalog_rank;
mod catalog_resolve;
mod catalog_sync;
mod fetch_catalog;
mod catalog_types;
mod cf_gateway;
mod cf_realtime;
mod cf_image;
mod cf_music;
mod cf_video;
mod lyria;
mod embed_cache;
mod embed_gemini;
mod gemini_no_provider_grounding;
mod llm_catalog;
mod model_catalog;
mod model_cost;
mod runtime_config;

use sqlx::PgPool;

pub use cf_gateway::cf_chat_generate;
pub use cf_realtime::{
    cf_realtime_via_cf, cf_realtime_ws_header_pairs, cf_realtime_ws_url, CfRealtimeUpstream,
};
pub use cf_image::{cf_grok_image_run, cf_image_provider_enabled};
pub use cf_music::{cf_music_run, CF_MUSIC_DURATION_SEC_DEFAULT, CF_MUSIC_MODEL_DEFAULT};
pub use cf_video::{cf_video_run, CF_VIDEO_MODEL_DEFAULT};
pub use lyria::{lyria_run, LYRIA_MODEL_DEFAULT};
pub use embed_cache::{
    embed_cache_evict_spawn, embed_cache_evict_stale, embed_cache_get_many_touch, embed_cache_get_touch,
    embed_cache_put, embed_cached, EmbedCacheResult, EMBED_CACHE_RETENTION_DAYS, EMBED_DIMENSIONS_DEFAULT,
};
pub use embed_gemini::{embed_text, embed_token_est, EmbedTextResult, EMBED_MODEL};
pub use gemini_no_provider_grounding::gemini_request_reject_provider_grounding;
pub use model_catalog::{
    model_chain_for_slug, model_is_alien, model_log_label, model_resolve_target, ModelTarget,
};
pub use catalog_types::context_tokens_infer;
pub use model_catalog::{
    context_tokens_from_raw, context_window_default, context_window_options, context_window_picker_ceiling, context_window_resolve,
    context_window_store, model_context_tokens, CONTEXT_WINDOW_DEFAULT, CONTEXT_WINDOW_STEPS,
};
pub use catalog_sync::{llm_catalog_spawn, llm_catalog_sync_force, sync_live_offers, PricingIndex};
pub use fetch_catalog::{llm_catalog_nats_subscribe, LlmCatalogFetchTask};
pub use catalog_resolve::{
    catalog_alien_chain_build, catalog_alien_chain_effective, catalog_alien_default, catalog_provider_model,
    google_gemini_api_model_id,
};
pub use llm_catalog::{
    catalog_models, catalog_price, llm_catalog_ensure_memory, llm_catalog_init, llm_catalog_pinned_ensure, llm_catalog_reload,
    llm_catalog_warm, prompt_models, provider_model_resolve, LlmModelRow,
};
pub use catalog_price::{ALIEN_POOL_USD_IN_PER_1M, ALIEN_POOL_USD_OUT_PER_1M};
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

/// Legacy alias — prefer `embed_cache_get_touch` (updates sliding access window).
pub async fn embed_cache_get(pool: &PgPool, model: &str, key: &str) -> Result<Option<Vec<f32>>, sqlx::Error> {
    Ok(embed_cache_get_touch(pool, model, key).await?.map(|(v, _)| v))
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
    fn embed_cache_key_differs_by_task_and_dims() {
        let q = embed_cache_key("hello", EMBED_TASK_QUERY, 768);
        let d = embed_cache_key("hello", EMBED_TASK_DOCUMENT, 768);
        let d2 = embed_cache_key("hello", EMBED_TASK_DOCUMENT, 512);
        assert_ne!(q, d);
        assert_ne!(d, d2);
    }

    #[test]
    fn embed_vec_roundtrip() {
        let v = vec![0.1_f32, -0.5, 1.0];
        let b = embed_vec_to_bytes(&v);
        assert_eq!(embed_bytes_to_vec(&b).unwrap(), v);
    }
}
