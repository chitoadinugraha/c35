//! Public system status — background probes write to `ai.config`; `GET /v1/system/status` reads one row.

use std::time::{Duration, Instant};

use axum::{http::header, response::IntoResponse, Json};
use c35_ctx::AppState;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

const SYSTEM_STATUS_KEY: &str = "system.status";
const PROBE_INTERVAL: Duration = Duration::from_secs(30);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum StatusLevel {
    Operational,
    Degraded,
    Outage,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StatusComponent {
    pub id: String,
    pub name: String,
    pub description: String,
    pub status: StatusLevel,
    pub latency_ms: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StatusRes {
    pub overall: StatusLevel,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    pub components: Vec<StatusComponent>,
}

pub fn status_probe_spawn(pool: PgPool, nats: Option<async_nats::Client>) {
    tokio::spawn(async move {
        loop {
            if let Err(e) = status_probe_store(&pool, nats.as_ref()).await {
                tracing::warn!("[status] probe store failed: {e:#}");
            }
            tokio::time::sleep(PROBE_INTERVAL).await;
        }
    });
}

async fn config_put(pool: &PgPool, key: &str, value: serde_json::Value) -> anyhow::Result<()> {
    sqlx::query(
        "INSERT INTO ai.config (key, value, updated_at) VALUES ($1, $2, NOW()) \
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()",
    )
    .bind(key)
    .bind(value)
    .execute(pool)
    .await?;
    Ok(())
}

async fn config_get(pool: &PgPool, key: &str) -> anyhow::Result<Option<serde_json::Value>> {
    let row: Option<(serde_json::Value,)> =
        sqlx::query_as("SELECT value FROM ai.config WHERE key = $1")
            .bind(key)
            .fetch_optional(pool)
            .await?;
    Ok(row.map(|r| r.0))
}

async fn status_probe_store(pool: &PgPool, nats: Option<&async_nats::Client>) -> anyhow::Result<()> {
    let res = status_probe(pool, nats).await;
    config_put(pool, SYSTEM_STATUS_KEY, serde_json::to_value(&res)?).await
}

pub async fn status_get(pool: &PgPool) -> impl IntoResponse {
    let value = match config_get(pool, SYSTEM_STATUS_KEY).await {
        Ok(Some(v)) => v,
        Ok(None) => {
            return (
                axum::http::StatusCode::SERVICE_UNAVAILABLE,
                Json(serde_json::json!({ "error": "Status not ready yet." })),
            )
                .into_response();
        }
        Err(e) => {
            tracing::warn!("[status] config read failed: {e:#}");
            return (
                axum::http::StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({ "error": "Could not load status." })),
            )
                .into_response();
        }
    };

    match serde_json::from_value::<StatusRes>(value) {
        Ok(res) => (
            [(header::CACHE_CONTROL, "public, max-age=30")],
            Json(res),
        )
            .into_response(),
        Err(e) => {
            tracing::warn!("[status] config parse failed: {e:#}");
            (
                axum::http::StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({ "error": "Invalid status snapshot." })),
            )
                .into_response()
        }
    }
}

pub async fn status_handler(axum::extract::State(st): axum::extract::State<AppState>) -> impl IntoResponse {
    status_get(&st.pool).await
}

async fn status_probe(pool: &PgPool, nats: Option<&async_nats::Client>) -> StatusRes {
    let (api, ai, whatsapp, storage, remote) = tokio::join!(
        probe_db(pool, "SELECT 1"),
        probe_nats(nats),
        probe_nats(nats),
        probe_db(pool, "SELECT 1 FROM ai.file_blob_meta LIMIT 1"),
        probe_remote(pool, nats),
    );

    let components = vec![
        StatusComponent {
            id: "api".into(),
            name: "Core Platform API".into(),
            description: "Authentication, workspace sync & user management".into(),
            status: api.status,
            latency_ms: api.latency_ms,
        },
        StatusComponent {
            id: "ai".into(),
            name: "AI Engine & Automations".into(),
            description: "Conversational reasoning, scheduled routines & bots".into(),
            status: ai.status,
            latency_ms: ai.latency_ms,
        },
        StatusComponent {
            id: "whatsapp".into(),
            name: "WhatsApp Channel".into(),
            description: "WhatsApp message delivery & automated customer replies".into(),
            status: whatsapp.status,
            latency_ms: whatsapp.latency_ms,
        },
        StatusComponent {
            id: "storage".into(),
            name: "Cloud Drive & Storage".into(),
            description: "Virtual cloud drive, encrypted vault & asset delivery".into(),
            status: storage.status,
            latency_ms: storage.latency_ms,
        },
        StatusComponent {
            id: "remote".into(),
            name: "Remote Control & Screen Relay".into(),
            description: "Low-latency desktop screen streaming & background input node".into(),
            status: remote.status,
            latency_ms: remote.latency_ms,
        },
    ];

    let overall = components
        .iter()
        .map(|c| c.status)
        .max()
        .unwrap_or(StatusLevel::Operational);

    StatusRes {
        overall,
        updated_at: chrono::Utc::now(),
        components,
    }
}

struct ProbeResult {
    status: StatusLevel,
    latency_ms: Option<u64>,
}

async fn probe_db(pool: &PgPool, sql: &str) -> ProbeResult {
    let t0 = Instant::now();
    match sqlx::query(sql).execute(pool).await {
        Ok(_) => ProbeResult {
            status: StatusLevel::Operational,
            latency_ms: Some(t0.elapsed().as_millis() as u64),
        },
        Err(e) => {
            tracing::warn!("[status] db probe failed: {e:#}");
            ProbeResult {
                status: StatusLevel::Outage,
                latency_ms: None,
            }
        }
    }
}

async fn probe_nats(nats: Option<&async_nats::Client>) -> ProbeResult {
    let t0 = Instant::now();
    let Some(client) = nats else {
        return ProbeResult {
            status: StatusLevel::Degraded,
            latency_ms: None,
        };
    };
    match tokio::time::timeout(Duration::from_secs(2), client.flush()).await {
        Ok(Ok(_)) => ProbeResult {
            status: StatusLevel::Operational,
            latency_ms: Some(t0.elapsed().as_millis() as u64),
        },
        _ => ProbeResult {
            status: StatusLevel::Degraded,
            latency_ms: None,
        },
    }
}

async fn probe_remote(pool: &PgPool, nats: Option<&async_nats::Client>) -> ProbeResult {
    let db = probe_db(pool, "SELECT 1").await;
    if db.status == StatusLevel::Outage {
        return db;
    }
    let latency = db.latency_ms.unwrap_or(0);
    if nats.is_none() {
        return ProbeResult {
            status: StatusLevel::Degraded,
            latency_ms: Some(latency),
        };
    }
    ProbeResult {
        status: StatusLevel::Operational,
        latency_ms: Some(latency),
    }
}
