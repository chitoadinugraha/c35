use std::collections::HashMap;
use std::sync::{LazyLock, RwLock};

use async_nats::Client;
use futures_util::StreamExt;
use sqlx::PgPool;
use tracing::warn;

use crate::inst::{inst_fetch_enabled, inst_fetch_one};
use crate::inst_admin::NATS_SUBJECT_PREFIX;
use crate::inst_macro::InstRow;

pub const NATS_SUBJECT_WILDCARD: &str = "c35.inst.>";

static CACHE: LazyLock<RwLock<HashMap<String, InstRow>>> =
    LazyLock::new(|| RwLock::new(HashMap::new()));

pub fn inst_list_cached() -> Vec<InstRow> {
    let g = CACHE.read().unwrap();
    let mut rows: Vec<InstRow> = g.values().cloned().collect();
    rows.sort_by(|a, b| b.priority.cmp(&a.priority).then_with(|| a.id.cmp(&b.id)));
    rows
}

pub async fn inst_cache_reload_all(pool: &PgPool) {
    let rows = inst_fetch_enabled(pool).await;
    let map = rows.into_iter().map(|r| (r.id.clone(), r)).collect();
    *CACHE.write().unwrap() = map;
}

pub async fn inst_cache_reload_one(pool: &PgPool, id: &str) {
    if id.trim().is_empty() {
        return;
    }
    if let Some(row) = inst_fetch_one(pool, id).await {
        CACHE.write().unwrap().insert(row.id.clone(), row);
    } else {
        CACHE.write().unwrap().remove(id);
    }
}

pub async fn inst_cache_init(pool: &PgPool) {
    inst_cache_reload_all(pool).await;
}

pub fn inst_cache_nats_subscribe(pool: PgPool, nats: Client) {
    tokio::spawn(async move {
        let mut sub = match nats.subscribe(NATS_SUBJECT_WILDCARD).await {
            Ok(s) => s,
            Err(e) => {
                warn!("[c35:inst] nats subscribe: {e}");
                return;
            }
        };
        while let Some(msg) = sub.next().await {
            let id = inst_id_from_invalidation(&msg);
            if id.is_empty() {
                continue;
            }
            inst_cache_reload_one(&pool, &id).await;
        }
    });
}

fn inst_id_from_invalidation(msg: &async_nats::Message) -> String {
    let payload = String::from_utf8_lossy(&msg.payload).trim().to_string();
    if !payload.is_empty() {
        return payload;
    }
    msg.subject
        .as_str()
        .strip_prefix(NATS_SUBJECT_PREFIX)
        .unwrap_or("")
        .to_string()
}
