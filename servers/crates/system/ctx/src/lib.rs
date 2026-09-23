use chrono::{DateTime, Utc};
use dashmap::DashMap;
use serde::Serialize;
use sqlx::PgPool;
use std::path::PathBuf;
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct OAuthPending {
    pub client_id: String,
    pub return_path: String,
    pub origin: String,
    pub expires_at: DateTime<Utc>,
}

#[derive(Clone, Debug, Serialize)]
pub struct OAuthResult {
    pub ready: bool,
    pub ok: bool,
    pub uid: Option<i64>,
    pub token: Option<String>,
    pub name: Option<String>,
    pub email: Option<String>,
    pub pic: Option<String>,
    pub handle: Option<String>,
    pub expires_at: DateTime<Utc>,
}

#[derive(Default)]
pub struct OAuthStore {
    pub pending: DashMap<String, OAuthPending>,
    pub results: DashMap<String, OAuthResult>,
}

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub nats: Option<async_nats::Client>,
    pub jwt_secret: String,
    pub oauth: Arc<OAuthStore>,
    pub cas_secret: String,
    pub cas_dir: PathBuf,
    pub public_origin: String,
}

#[derive(Clone)]
pub struct Ctx {
    pub pool: PgPool,
    pub caller_iid: i64,
}

impl Ctx {
    pub fn from_state(state: &AppState, caller_iid: i64) -> Self {
        Self {
            pool: state.pool.clone(),
            caller_iid,
        }
    }
}
