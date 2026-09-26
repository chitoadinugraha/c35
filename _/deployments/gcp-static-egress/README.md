# GCP static egress proxy (`c-personal`)

HTTP **CONNECT** forward proxy on legacy GCP VM **`35.212.234.193`** so cluster workloads egress with a **stable IP** (Midtrans whitelist, other vendors).

Not the OCI ingress LB. Not Cloudflare WARP (`c35-proxy-cf-warp`).

## Image (build locally — never on GCP)

Same CONNECT binary as in-cluster CF proxy, **without** the WARP sidecar. **`linux/amd64`** only.

```powershell
.\_\scripts\deploy\publish_gcp_static_egress.ps1
```

- Image: `hsg.ocir.io/axr8wqrrukgm/c35-static-egress:latest`
- Port: **`8080`** on `c-personal` (`c_log_server` removed)

## Security (Midtrans / finance)

| Leg | Encryption |
|-----|----------------|
| **c35-server → proxy** | **Tailscale (WireGuard)**. `ALIENAI_PROXY_STATIC_URL` uses `http://100.x:8080` only **on the tailnet** — not public cleartext on the internet. |
| **proxy → Midtrans** | **HTTPS (TLS)** to `api.midtrans.com:443` inside the CONNECT tunnel. Server key / payloads are TLS-protected; Squid forwards TCP bytes only. |
| **Midtrans → you (webhooks)** | **HTTPS** to `https://api.alienai.id/...` (OCI LB). |

Do **not** expose Squid on `0.0.0.0:8080` without Tailscale. Prefer: `.\_\scripts\deploy\install_gcp_tailscale_egress.ps1`.

## Tailscale (recommended)

```powershell
.\_\scripts\deploy\install_gcp_tailscale_egress.ps1
```

Sets hostname `c-personal-egress`, binds Squid to **Tailscale IP only**, patches `ALIENAI_PROXY_STATIC_URL` to `http://100.x:8080`.

## On `c-personal` (pull + run only — legacy public IP)

```bash
ssh -i ~/.ssh/id_ed25519 chito@35.212.234.193
docker login hsg.ocir.io   # if needed
docker pull hsg.ocir.io/axr8wqrrukgm/c35-static-egress:latest
docker rm -f c35-static-egress 2>/dev/null
docker run -d --name c35-static-egress --restart unless-stopped \
  -p 8080:8080 \
  -e C35_PROXY_CF_ADDR=0.0.0.0:8080 \
  hsg.ocir.io/axr8wqrrukgm/c35-static-egress:latest
```

### Firewall: outbound vs inbound

| Direction | Usually allowed? | Meaning |
|-----------|------------------|---------|
| **OCI pod → internet** (Midtrans direct, no proxy) | **Yes** | No GCP firewall involved; source IP = worker public IP (`168.110.203.3`, changes on node replace). |
| **OCI pod → GCP VM proxy → internet** | **GCP must allow inbound TCP to the proxy port** | The cluster opens a **TCP connection to** `35.212.234.193:8080`. That is **inbound on GCP**, not “outbound from GCP”. Default GCP VPC often **denies** unsolicited inbound from the internet — hence the earlier timeout from btm. |

You only open **8080** (or use Tailscale below) if you use the **proxy on GCP**. If Midtrans whitelists the **OCI worker IP** instead, you do **not** need GCP port 8080 at all.

**Options without public 8080:**

1. **Tailscale** on `c-personal` + cluster subnet-router — proxy listens on `100.x:8080`, firewall stays closed to the public internet.
2. **Skip GCP proxy** — reserve a **stable OCI public IP** on the worker and whitelist that in Midtrans (no VM proxy).

If you expose **8080** on the public IP, restrict source to OCI worker `/32` or Tailscale CIDR.

From btm cluster (test after rule or tailscale):

```bash
kubectl run curl-test --rm -it -n c35 --image=curlimages/curl -- \
  curl -x http://35.212.234.193:8080 -sS https://api.ipify.org
# must print: 35.212.234.193
```

## Cluster consumers

| Env | Use |
|-----|-----|
| `ALIENAI_PROXY_STATIC_URL` | **Static IP** egress (`http://<host>:8080`) |
| `ALIENAI_PROXY_CF_URL` | **Cloudflare** egress (scraping / SearXNG) — unchanged |

### `c35-server` (Midtrans)

Set in `c35-server-env` secret or deployment:

```yaml
ALIENAI_PROXY_STATIC_URL: "http://35.212.234.193:8080"
# or tailscale: http://100.x.x.x:8080
```

Billing HTTP client reads `ALIENAI_PROXY_STATIC_URL` or `MIDTRANS_HTTP_PROXY`.

### Other call sites

Rust: `c35_mod_chat::tools::egress_http::http_client_static(timeout)` for tools that need the same IP.

Do **not** set global `HTTP_PROXY` on `c35-server` — keeps Midtrans on GCP and scraping on CF.

## Midtrans

1. Whitelist **`35.212.234.193`** in Midtrans dashboard (likely already from CSA).
2. Webhooks stay **`https://api.alienai.id/v1/billing/webhook/midtrans`** (OCI LB inbound).
3. Snap / Core API calls use static proxy → Midtrans sees GCP IP.
