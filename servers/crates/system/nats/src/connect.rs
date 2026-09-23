use std::path::Path;
use std::time::Duration;

use async_nats::Event;
use tokio::sync::mpsc;

pub type Client = async_nats::Client;

pub fn configured() -> bool {
    std::env::var("NATS_URL")
        .ok()
        .is_some_and(|s| !s.trim().is_empty())
}

fn connect_options() -> async_nats::ConnectOptions {
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
    opts
}

pub async fn connect() -> Option<Client> {
    let url = std::env::var("NATS_URL").ok().filter(|s| !s.trim().is_empty())?;
    let opts = connect_options();
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

pub async fn connect_supervised() -> Option<(Client, mpsc::UnboundedReceiver<Event>)> {
    let url = std::env::var("NATS_URL").ok().filter(|s| !s.trim().is_empty())?;
    let (tx, rx) = mpsc::unbounded_channel();
    let opts = connect_options().event_callback(move |event| {
        let tx = tx.clone();
        async move {
            if matches!(event, Event::Connected | Event::Disconnected) {
                let _ = tx.send(event);
            }
        }
    });
    match tokio::time::timeout(Duration::from_secs(5), opts.connect(url)).await {
        Ok(Ok(c)) => Some((c, rx)),
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
