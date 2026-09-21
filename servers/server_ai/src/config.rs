use std::path::PathBuf;

#[derive(Clone)]
pub struct Config {
    pub listen: String,
    pub jwt_secret: String,
    pub cas_secret: String,
    pub cas_dir: PathBuf,
    pub public_origin: String,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            listen: std::env::var("LISTEN").unwrap_or_else(|_| "0.0.0.0:8080".into()),
            jwt_secret: std::env::var("C35_JWT_SECRET")
                .or_else(|_| std::env::var("AGENT_SECRET_KEY"))
                .unwrap_or_else(|_| "dev-change-me".into()),
            cas_secret: std::env::var("CAS_HMAC_SECRET")
                .or_else(|_| std::env::var("C35_JWT_SECRET"))
                .unwrap_or_else(|_| "dev-cas-hmac".into()),
            cas_dir: std::env::var("CAS_DIR")
                .map(PathBuf::from)
                .unwrap_or_else(|_| c35_mod_file::cas_dir_default()),
            public_origin: std::env::var("C35_PUBLIC_ORIGIN")
                .or_else(|_| std::env::var("CS_PUBLIC_ORIGIN"))
                .or_else(|_| std::env::var("CSAI_PUBLIC_ORIGIN"))
                .unwrap_or_else(|_| "https://alienai.id".into()),
        })
    }
}

pub fn env_load() {
    c35_store::env_load();
}
