use std::path::Path;
use std::time::Duration;

pub fn configured() -> bool {
    std::env::var("NATS_URL")
        .ok()
        .is_some_and(|s| !s.trim().is_empty())
}

pub async fn connect() -> Option<async_nats::Client> {
    let url = std::env::var("NATS_URL").ok().filter(|s| !s.trim().is_empty())?;
    let mut opts = async_nats::ConnectOptions::new();
    if let (Ok(u), Ok(p)) = (std::env::var("NATS_USER"), std::env::var("NATS_PASS")) {
        if !u.is_empty() {
            opts = opts.user_and_password(u, p);
        }
    }
    if let Ok(ca) = std::env::var("NATS_CA") {
        if Path::new(&ca).exists() {
            opts = opts.add_root_certificates(std::path::PathBuf::from(ca));
        }
    }
    match tokio::time::timeout(Duration::from_secs(5), opts.connect(url)).await {
        Ok(Ok(c)) => Some(c),
        Ok(Err(e)) => {
            tracing::warn!(error = %e, "nats connect");
            None
        }
        Err(_) => {
            tracing::warn!("nats connect timeout");
            None
        }
    }
}
