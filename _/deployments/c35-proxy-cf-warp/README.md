# Deployment: c35-proxy-cf-warp

Deploys `c35-proxy-cf-warp` (HTTP CONNECT forward proxy) with a `cloudflare-mesh` container in namespace `c35`.

## Prerequisite

Secret `c35-proxy-cf-warp` with `MESH_NODE_TOKEN` retrieved via Cloudflare MCP tool:
```json
{ "name": "alienai-proxy-cf" } -> warp_connector_token_get
```

## Service

Exposes `http://c35-proxy-cf-warp.c35.svc.cluster.local:8080`.

## Consumers

1. **SearXNG** (`searx` namespace):
   Configured with `HTTP_PROXY`, `HTTPS_PROXY`, and `outgoing.proxies` in `/etc/searxng/settings.yml`.
2. **c35-server** (`c35` namespace):
   Configured with `ALIENAI_PROXY_CF_URL` for `web.visit` and `web.research` page scraping.
