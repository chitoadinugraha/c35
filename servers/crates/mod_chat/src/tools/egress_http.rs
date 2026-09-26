//! Platform egress HTTP — honors `ALIENAI_PROXY_CF_URL` / `HTTP_PROXY` / `NO_PROXY`.

use std::time::Duration;

use reqwest::{Client, ClientBuilder, Proxy};
use tracing::info;

fn proxy_url_from_keys(keys: &[&str]) -> Option<String> {
    keys.iter()
        .filter_map(|k| std::env::var(k).ok())
        .map(|v| v.trim().to_string())
        .find(|s| !s.is_empty())
}

pub fn platform_proxy_url() -> Option<String> {
    proxy_url_from_keys(&["ALIENAI_PROXY_CF_URL", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"])
}

/// Dedicated egress via GCP (or other) static IP — not Cloudflare WARP.
pub fn static_proxy_url() -> Option<String> {
    proxy_url_from_keys(&["ALIENAI_PROXY_STATIC_URL"])
}

pub fn http_client_static(timeout: Duration) -> Client {
    let mut builder = Client::builder().timeout(timeout);
    if let Some(proxy_url) = static_proxy_url() {
        info!("[egress_http] static-IP egress via proxy: {}", proxy_url);
        match Proxy::all(&proxy_url) {
            Ok(mut proxy) => {
                if let Some(no_proxy) = no_proxy_from_env() {
                    proxy = proxy.no_proxy(Some(no_proxy));
                }
                builder = builder.proxy(proxy);
            }
            Err(e) => tracing::warn!("[egress_http] static proxy invalid: {e}"),
        }
    }
    builder.build().unwrap_or_default()
}

fn no_proxy_from_env() -> Option<reqwest::NoProxy> {
    std::env::var("NO_PROXY")
        .or_else(|_| std::env::var("no_proxy"))
        .ok()
        .and_then(|s| reqwest::NoProxy::from_string(&s))
}

pub fn http_client_builder(timeout: Duration) -> Result<ClientBuilder, String> {
    let mut builder = Client::builder().timeout(timeout);
    if let Some(proxy_url) = platform_proxy_url() {
        info!("[egress_http] routing HTTP egress via proxy: {}", proxy_url);
        let mut proxy = Proxy::all(&proxy_url).map_err(|e| format!("proxy {proxy_url}: {e}"))?;
        if let Some(no_proxy) = no_proxy_from_env() {
            proxy = proxy.no_proxy(Some(no_proxy));
        }
        builder = builder.proxy(proxy);
    }
    Ok(builder)
}

pub fn http_client(timeout: Duration) -> Client {
    match http_client_builder(timeout).and_then(|b| b.build().map_err(|e| e.to_string())) {
        Ok(c) => c,
        Err(e) => {
            tracing::warn!("[egress_http] failed to build proxy client, falling back to default: {e}");
            Client::builder().timeout(timeout).build().unwrap_or_default()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_platform_proxy_url_resolution() {
        std::env::remove_var("ALIENAI_PROXY_CF_URL");
        std::env::remove_var("HTTP_PROXY");
        std::env::remove_var("HTTPS_PROXY");
        std::env::remove_var("ALL_PROXY");

        assert!(platform_proxy_url().is_none());

        std::env::set_var("ALIENAI_PROXY_CF_URL", "http://cs-service-proxy-cf.cs.svc.cluster.local:8080");
        assert_eq!(
            platform_proxy_url(),
            Some("http://cs-service-proxy-cf.cs.svc.cluster.local:8080".to_string())
        );

        std::env::set_var("NO_PROXY", "localhost,127.0.0.1,.cluster.local");
        let builder = http_client_builder(Duration::from_secs(10));
        assert!(builder.is_ok());

        let client = http_client(Duration::from_secs(10));
        drop(client);

        std::env::remove_var("ALIENAI_PROXY_CF_URL");
        std::env::remove_var("NO_PROXY");
    }
}
