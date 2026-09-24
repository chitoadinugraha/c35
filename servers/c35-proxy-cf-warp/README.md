# c35-proxy-cf-warp

HTTP CONNECT forward proxy running alongside a Cloudflare WARP mesh sidecar.

## Purpose

Enables cluster workloads (such as SearXNG meta-search engine and Alien AI scraping agents) to egress through Cloudflare's residential/clean edge network via Zero Trust WARP Connector (`alienai-proxy-cf`).

This prevents search engines (Google, Bing, Yahoo, DuckDuckGo) from IP-banning, rate-limiting, or CAPTCHA-blocking cloud datacenter IP ranges (such as Oracle Cloud OCI).

## Ports & Endpoints

- Port: `8080` (HTTP CONNECT tunnel proxy)
- `GET /health` or `GET /ready`: Health probe returning `200 OK` with active connection count.

## Deployment

Located at [`_\deployments\c35-proxy-cf-warp`](../../_/deployments/c35-proxy-cf-warp).
