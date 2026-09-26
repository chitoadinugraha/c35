use async_nats::{Client, Event};
use c35_store::PgPool;
use tokio::sync::mpsc::UnboundedReceiver;

pub async fn nats_post_connect(pool: PgPool, client: Client) {
    c35_wire_ws::admin_stats_warm(client.clone()).await;
    if let Err(e) = c35_nats::jetstream_streams_ensure(&client).await {
        tracing::warn!(error = %e, "[c35:nats] stream ensure failed");
        return;
    }

    match c35_nats::try_advisory_lock(&pool).await {
        Ok(true) => {
            let schedules = c35_nats::hydrate_task_schedules(&client, &pool)
                .await
                .unwrap_or_else(|e| {
                    tracing::warn!(error = %e, "[c35:nats] schedule hydrate failed");
                    0
                });
            let prompt_replay = c35_mod_chat::prompt_run_hydrate_replay(&client, &pool)
                .await
                .unwrap_or_else(|e| {
                    tracing::warn!(error = %e, "[c35:nats] prompt hydrate failed");
                    0
                });
            c35_nats::advisory_unlock(&pool).await;
            tracing::info!(
                schedules,
                prompt_replay,
                task_replay = 0u32,
                "[c35:nats] hydrate complete"
            );
        }
        Ok(false) => tracing::info!("[c35:nats] hydrate skipped (lock not acquired)"),
        Err(e) => tracing::warn!(error = %e, "[c35:nats] hydrate lock failed"),
    }
}

pub fn nats_supervise_reconnect(pool: PgPool, client: Client, mut events: UnboundedReceiver<Event>) {
    tokio::spawn(async move {
        let mut saw_disconnect = false;
        while let Some(event) = events.recv().await {
            match event {
                Event::Disconnected => saw_disconnect = true,
                Event::Connected if saw_disconnect => {
                    tracing::info!("[c35:nats] reconnected — hydrate scheduled");
                    nats_post_connect(pool.clone(), client.clone()).await;
                    saw_disconnect = false;
                }
                _ => {}
            }
        }
    });
}
