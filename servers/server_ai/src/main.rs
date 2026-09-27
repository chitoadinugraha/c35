mod boot;
mod boot_handlers;
mod config;
mod log;
mod nats_boot;

use std::sync::Arc;
use std::time::Instant;
use tokio::sync::Mutex;
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

    log::booting("store, NATS, listen socket");
    let yb_t0 = Instant::now();
    let nats_t0 = Instant::now();
    let (pool, nats_supervised, listener) = tokio::join!(
        c35_store::pool_connect(),
        async {
            if nats_required {
                c35_nats::connect_supervised().await
            } else {
                None
            }
        },
        async {
            match tokio::net::TcpListener::bind(&addr).await {
                Ok(l) => Ok(l),
                Err(e) if e.kind() == std::io::ErrorKind::AddrInUse => {
                    log::port_in_use(&addr);
                    std::process::exit(1);
                }
                Err(e) => Err(anyhow::Error::from(e)),
            }
        }
    );
    let pool = pool?;
    let listener = listener?;
    let (nats, nats_events) = match nats_supervised {
        Some((client, events)) => (Some(client), Some(events)),
        None => (None, None),
    };
    let yb_ms = yb_t0.elapsed().as_millis();
    let nats_ms = nats.as_ref().map(|_| nats_t0.elapsed().as_millis());
    log::store_connected(yb_ms, nats_ms, nats_required);

    c35_store::migrate_startup(&pool).await?;

    let prompt_worker = Arc::new(Mutex::new(None));
    tokio::spawn(boot_handlers::boot_handlers_background(
        pool.clone(),
        cfg.clone(),
        nats.clone(),
        nats_events,
        nats_required,
        prompt_worker.clone(),
    ));

    let app = boot::router(cfg, pool, nats);
    log::listening(&[("HTTP", format!("http://{addr}"))]);
    axum::serve(listener, app)
        .with_graceful_shutdown(async move {
            shutdown_signal().await;
            if let Some(worker) = prompt_worker.lock().await.take() {
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
