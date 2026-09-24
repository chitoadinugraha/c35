use std::time::Duration;

use sqlx::PgPool;
use tracing::warn;

use super::store::prompt_run_list_active;

/// When the SQLx pool is saturated, log active prompt jobs (req_id + prompt text) for correlation.
pub fn prompt_run_pool_diag_spawn(pool: PgPool, max_connections: u32) {
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(15));
        loop {
            interval.tick().await;
            let size = pool.size();
            let idle = pool.num_idle();
            if size == 0 || idle > 0 || size < max_connections {
                continue;
            }
            match prompt_run_list_active(&pool).await {
                Ok(rows) if rows.is_empty() => {
                    warn!(
                        pool_size = size,
                        pool_idle = idle,
                        pool_max = max_connections,
                        "[c35:prompt_run] db pool saturated — no active prompt_run rows (check other DB users)"
                    );
                }
                Ok(rows) => {
                    for row in rows {
                        warn!(
                            pool_size = size,
                            pool_idle = idle,
                            pool_max = max_connections,
                            req_id = row.req_id,
                            owner_iid = row.owner_iid,
                            status = row.status,
                            lease_pod = row.lease_pod.as_deref().unwrap_or(""),
                            turn_count = row.turn_count,
                            prompt = row.prompt_preview,
                            "[c35:prompt_run] db pool saturated — active prompt"
                        );
                    }
                }
                Err(e) => {
                    warn!(
                        pool_size = size,
                        pool_idle = idle,
                        error = %e,
                        "[c35:prompt_run] db pool saturated — failed to list active prompts"
                    );
                }
            }
        }
    });
}
