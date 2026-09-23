mod boot;
mod config;
mod log;

use std::sync::Arc;
use std::time::Instant;
use c35_ctx::{AppState, OAuthStore};
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .without_time()
        .with_target(false)
        .compact()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("warn")),
        )
        .init();

    config::env_load();
    let cfg = config::Config::from_env()?;
    let addr = cfg.listen.clone();
    let nats_required = c35_nats::configured();

    let yb_t0 = Instant::now();
    let nats_t0 = Instant::now();
    let (pool, nats, listener) = tokio::join!(
        c35_store::pool_connect(),
        c35_nats::connect(),
        async {
            match tokio::net::TcpListener::bind(&addr).await {
                Ok(l) => Ok(l),
                Err(e) if e.kind() == std::io::ErrorKind::AddrInUse => {
                    log::port_in_use(addr.rsplit(':').next().unwrap_or("8080"));
                    std::process::exit(1);
                }
                Err(e) => Err(anyhow::Error::from(e)),
            }
        }
    );
    let pool = pool?;
    c35_store::pool_monitor_spawn(pool.clone());
    c35_store::migrate_boot(&pool).await?;
    c35_store::migrate_apply(&pool).await?;
    c35_mod_billing::fx_live_init(&pool).await?;
    c35_mod_llm::llm_catalog_init(&pool).await?;
    c35_mod_llm::runtime_config_init(&pool).await;
    c35_mod_llm::llm_catalog_spawn(pool.clone());
    c35_mod_llm::runtime_config_watch(pool.clone());
    c35_mod_chat::inst_cache_init(&pool).await;
    if let Some(nats_client) = nats.clone() {
        c35_mod_billing::fx_live_subscribe(pool.clone(), nats_client.clone());
        c35_mod_llm::llm_catalog_nats_subscribe(pool.clone(), nats_client.clone());
        c35_mod_chat::inst_cache_nats_subscribe(pool.clone(), nats_client.clone());
        let cas_dir = cfg.cas_dir.clone();
        let _ = std::fs::create_dir_all(&cas_dir);
        let subscriber_state = Arc::new(AppState {
            pool: pool.clone(),
            nats: Some(nats_client),
            jwt_secret: cfg.jwt_secret.clone(),
            oauth: Arc::new(OAuthStore::default()),
            cas_secret: cfg.cas_secret.clone(),
            cas_dir,
            public_origin: cfg.public_origin.clone(),
        });
        tokio::spawn(async move {
            c35_mod_channel::start_channel_inbound_subscriber(subscriber_state).await;
        });
    } else if nats_required {
        tracing::warn!("inst cache: NATS unavailable, invalidation disabled");
    }
    let listener = listener?;
    let yb_ms = yb_t0.elapsed().as_millis();
    let nats_ms = nats.as_ref().map(|_| nats_t0.elapsed().as_millis());
    log::store_connected(yb_ms, nats_ms, nats_required);

    let prompt_worker = nats.clone().map(|nats_client| {
        c35_mod_chat::prompt_run_worker_start(pool.clone(), nats_client)
    });

    let mut names = feature_names();
    if nats.is_some() {
        names.push("nats");
        names.push("prompt_run");
    }
    log::features(&names);

    let app = boot::router(cfg, pool, nats);
    log::listening(&[("HTTP", format!("http://{addr}"))]);
    axum::serve(listener, app)
        .with_graceful_shutdown(async move {
            shutdown_signal().await;
            if let Some(worker) = prompt_worker {
                worker.drain().await;
            }
        })
        .await?;
    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };
    #[cfg(unix)]
    let terminate = async {
        let mut sig =
            tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()).expect("SIGTERM handler");
        sig.recv().await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
}

fn feature_names() -> Vec<&'static str> {
    vec![
        "ws",
        "auth",
        "google",
        "referral",
        "admin",
        "file_cas",
        "billing",
        "channel",
        "site",
        "voice",
    ]
}
