use std::sync::Arc;

use async_nats::{Client, Event};
use c35_ctx::{AppState, OAuthStore};
use c35_mod_chat::PromptRunWorker;
use c35_store::PgPool;
use tokio::sync::{mpsc::UnboundedReceiver, Mutex};

use crate::config::Config;
use crate::log;
use crate::nats_boot;

pub async fn boot_handlers_background(
    pool: PgPool,
    cfg: Config,
    nats: Option<Client>,
    nats_events: Option<UnboundedReceiver<Event>>,
    nats_required: bool,
    prompt_worker: Arc<Mutex<Option<PromptRunWorker>>>,
) {
    log::booting("handlers");
    if let Err(e) = c35_mod_billing::fx_live_init(&pool).await {
        tracing::warn!("fx_live_init: {e:#}");
    }
    if let Err(e) = c35_mod_llm::llm_catalog_init(&pool).await {
        tracing::warn!("llm_catalog_init: {e:#}");
    }
    if let Err(e) = c35_mod_live::live_catalog_init(&pool).await {
        tracing::warn!("live_catalog_init: {e:#}");
    }
    c35_mod_llm::llm_catalog_spawn(pool.clone());
    c35_mod_llm::runtime_config_watch(pool.clone());
    c35_mod_chat::inst_cache_init(&pool).await;
    c35_mod_llm::embed_cache_evict_spawn(pool.clone());
    let embed_http = c35_mod_chat::tools::http_client(std::time::Duration::from_secs(60));
    c35_mod_data_source::data_source_bg_spawn(pool.clone(), embed_http.clone());
    if let Err(e) = c35_mod_chat::tool_index_init(&pool, &embed_http).await {
        tracing::warn!("tool_index init failed (lexical fallback): {e}");
    }
    let pool_cfg = c35_store::PoolConfig::from_env();
    c35_store::pool_monitor_spawn(pool.clone(), pool_cfg.clone());
    c35_mod_chat::prompt_run_concurrency_init();
    c35_mod_chat::prompt_run_pool_diag_spawn(pool.clone(), pool_cfg.max_connections);
    c35_wire_http::status_probe_spawn(pool.clone(), nats.clone());
    let had_nats = nats.is_some();
    if let (Some(nats_client), Some(events)) = (nats.clone(), nats_events) {
        nats_boot::nats_post_connect(pool.clone(), nats_client.clone()).await;
        nats_boot::nats_supervise_reconnect(pool.clone(), nats_client.clone(), events);
    }
    if let Some(nats_client) = nats {
        c35_mod_billing::fx_live_subscribe(pool.clone(), nats_client.clone());
        c35_mod_llm::llm_catalog_nats_subscribe(pool.clone(), nats_client.clone());
        c35_mod_chat::inst_cache_nats_subscribe(pool.clone(), nats_client.clone());
        c35_mod_task::scheduler::task_scheduler_start(pool.clone(), nats_client.clone());
        let cas_dir = cfg.cas_dir.clone();
        let _ = std::fs::create_dir_all(&cas_dir);
        let subscriber_state = Arc::new(AppState {
            pool: pool.clone(),
            nats: Some(nats_client.clone()),
            jwt_secret: cfg.jwt_secret.clone(),
            oauth: Arc::new(OAuthStore::default()),
            cas_secret: cfg.cas_secret.clone(),
            cas_dir,
            public_origin: cfg.public_origin.clone(),
        });
        tokio::spawn(async move {
            c35_mod_channel::start_channel_inbound_subscriber(subscriber_state).await;
        });
        let worker = c35_mod_chat::prompt_run_worker_start(pool.clone(), nats_client);
        *prompt_worker.lock().await = Some(worker);
    } else if nats_required {
        tracing::warn!("inst cache: NATS unavailable, invalidation disabled");
    }
    log::features(&feature_names(had_nats));
}

fn feature_names(nats: bool) -> Vec<String> {
    let mut names = vec![
        "ws", "auth", "google", "referral", "admin", "file_cas", "billing", "channel", "site",
        "mail", "voice",
    ]
    .into_iter()
    .map(str::to_string)
    .collect::<Vec<_>>();
    if nats {
        names.extend(["nats", "prompt_run", "nats_hydrate"].into_iter().map(str::to_string));
    }
    names
}