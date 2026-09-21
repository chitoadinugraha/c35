use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub http_addr: String,
    pub yb_host: String,
    pub yb_port: u16,
    pub yb_user: String,
    pub yb_pass: String,
    pub yb_database: String,
    pub nats_url: String,
    pub nats_user: Option<String>,
    pub nats_pass: Option<String>,
    pub nats_ca: Option<String>,
    pub sessions_dir: String,
    pub poll_interval_secs: u64,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            http_addr: env::var("PORT")
                .map(|p| format!("0.0.0.0:{p}"))
                .unwrap_or_else(|_| "0.0.0.0:8080".into()),
            yb_host: env::var("YB_HOST")
                .unwrap_or_else(|_| "yb-tservers.yugabyte.svc.cluster.local".into()),
            yb_port: env::var("YB_PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(5433),
            yb_user: env::var("YB_USER").unwrap_or_else(|_| "csa".into()),
            yb_pass: env::var("YB_PASSWORD")
                .unwrap_or_else(|_| "mNLo6VrdKzJnEl7TOQvAHc9Cx1hktUwuIgSy3R25".into()),
            yb_database: env::var("YB_DATABASE").unwrap_or_else(|_| "c35".into()),
            nats_url: env::var("NATS_URL")
                .unwrap_or_else(|_| "tls://nats-client.nats.svc.cluster.local:4222".into()),
            nats_user: env::var("NATS_USER").ok(),
            nats_pass: env::var("NATS_PASS").ok(),
            nats_ca: env::var("NATS_CA").ok(),
            sessions_dir: env::var("WA_SESSIONS_DIR").unwrap_or_else(|_| ".cache/wa_sessions".into()),
            poll_interval_secs: env::var("WA_POLL_INTERVAL_SECS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(5),
        }
    }

    pub fn db_url(&self) -> String {
        format!(
            "postgresql://{}:{}@{}:{}/{}?sslmode=disable",
            self.yb_user, self.yb_pass, self.yb_host, self.yb_port, self.yb_database
        )
    }
}
