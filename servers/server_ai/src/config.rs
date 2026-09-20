use std::path::{Path, PathBuf};

#[derive(Clone)]
pub struct Config {
    pub listen: String,
    pub jwt_secret: String,
    pub db_migrate: bool,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            listen: std::env::var("LISTEN").unwrap_or_else(|_| "0.0.0.0:8080".into()),
            jwt_secret: std::env::var("C35_JWT_SECRET")
                .unwrap_or_else(|_| "dev-change-me".into()),
            db_migrate: std::env::var("C35_DB_MIGRATE").ok().as_deref() == Some("1"),
        })
    }
}

pub fn env_load() {
    for p in env_files() {
        let _ = dotenvy::from_path(&p);
    }
}

fn env_files() -> Vec<PathBuf> {
    let mut out = vec![
        PathBuf::from("server_ai/.env.local"),
        PathBuf::from("servers/server_ai/.env.local"),
        PathBuf::from(".env.local"),
    ];
    if let Ok(man) = std::env::var("CARGO_MANIFEST_DIR") {
        out.push(Path::new(&man).join(".env.local"));
    }
    out
}
