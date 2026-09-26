//! Outbound HTTP for billing (Midtrans, etc.) — optional static-IP forward proxy.

use std::time::Duration;

use reqwest::{Client, ClientBuilder, Proxy};
use tracing::info;

const DEFAULT_TIMEOUT: Duration = Duration::from_secs(60);

fn static_proxy_url() -> Option<String> {
    ["ALIENAI_PROXY_STATIC_URL", "MIDTRANS_HTTP_PROXY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .map(|v| v.trim().to_string())
        .filter(|s| !s.is_empty())
}

fn no_proxy_from_env() -> Option<reqwest::NoProxy> {
    std::env::var("NO_PROXY")
        .or_else(|_| std::env::var("no_proxy"))
        .ok()
        .and_then(|s| reqwest::NoProxy::from_string(&s))
}

pub fn billing_http_client_builder() -> Result<ClientBuilder, String> {
    let mut builder = Client::builder().timeout(DEFAULT_TIMEOUT);
    if let Some(proxy_url) = static_proxy_url() {
        info!("[billing_http] Midtrans/billing egress via static proxy: {}", proxy_url);
        let mut proxy = Proxy::all(&proxy_url).map_err(|e| format!("proxy {proxy_url}: {e}"))?;
        if let Some(no_proxy) = no_proxy_from_env() {
            proxy = proxy.no_proxy(Some(no_proxy));
        }
        builder = builder.proxy(proxy);
    }
    Ok(builder)
}

pub fn billing_http_client() -> Client {
    match billing_http_client_builder().and_then(|b| b.build().map_err(|e| e.to_string())) {
        Ok(c) => c,
        Err(e) => {
            tracing::warn!("[billing_http] proxy client build failed, direct egress: {e}");
            Client::builder()
                .timeout(DEFAULT_TIMEOUT)
                .build()
                .unwrap_or_default()
        }
    }
}
