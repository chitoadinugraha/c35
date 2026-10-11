# Device egress proxy (`proxy.alienai.id`) — master multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review **Implementation status** and each wave **Review gate** before starting the next wave. Captcha solver (`mod_captcha`, 2Captcha, billing SKUs) is a **follow-up plan** after egress proxy is proven—this plan ends at lease + CONNECT + agent relay + smoke test.

**Goal:** Ship **HTTP CONNECT** on **`proxy.alienai.id`** in the **`server_ai`** process (isolated crate), authenticate with **short-lived username/password** leases tied to **`device_iid` + `req_id`**, relay TCP through the **existing outbound `/v1/agent/ws`** session, **publish updated remote agents**, and verify with **`curl -x`** against a simple HTTPS URL (e.g. ipify).

**Architecture:** New crate `c35_mod_device_egress` owns lease mint/validate, tunnel registry, and CONNECT serving. `wire_http` mounts an egress router (Host `proxy.alienai.id` at ingress). Agent side in `c_remote_core` handles new protobuf **egress** messages (open stream, data, close). Cluster captcha/tools later call the same lease API or in-process tunnel API—**not in this plan’s scope beyond a stub hook**.

**Tech stack:** Rust (`server_ai`, `mod_device`, `c_remote_core`, `c_remote_windows`, `c_remote_browser`), protobuf (`_/schemas/proto/c35/`), Traefik ingress, PowerShell smoke (`_\scripts\dev\`), OTA `publish_remote_agent.ps1` (+ `publish_remote_browser.ps1` if browser agent shares core changes).

**Specs to add/update:** [`_/specs/device-egress-proxy.md`](../device-egress-proxy.md) (new), touch [`_/specs/remote.md`](../remote.md) § networking, [`_/specs/plans/2026-09-22-platform-ops-multitask.md`](2026-09-22-platform-ops-multitask.md) DNS row for `proxy.alienai.id`.

## Global constraints

- Same binary **`server_ai`** for v1; **no** open proxy without auth; **no** reuse of `c35-proxy-cf-warp` for device IP.
- Proto changes: edit `_/schemas/proto/c35/`, regenerate Dart only if app exposes lease UI (v1: **server/MCP only**).
- Agent WS remains **`https://api.alienai.id/v1/agent/ws`**; egress data is **additional binary frames**, not a second socket.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` after `.rs` / `.md` / `.proto` / `.ps1`.
- Server: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_device_egress` when crate exists.
- Remote: `cd remotes && cargo build -p c_remote_windows` (and `-p c_remote_browser` if core touched).
- Ship agents: `.\_\scripts\deploy\publish_remote_agent.ps1`; browser OTA if `c_remote_browser` changed.
- Ship server: `.\_\scripts\deploy\publish_server.ps1` after ingress + env documented.
- Device debug on Chito machines: **`owner_iid` 99000** (`device-control-chito.mdc`).
- Do not commit unless user asks.

---

## Auth model (locked for v1)

| Field | Rule |
|--------|------|
| **Mint** | Authenticated owner (invoke or internal `prompt_run` worker) calls **`device.egress.lease`** with `device_iid`, `req_id`, optional `ttl_sec` (default 600, max 3600). |
| **Username** | `{lease_id}` (snowflake string, no secrets in username). |
| **Password** | Random 32+ char secret; stored **hashed** in lease row or KV; shown **once** in mint response. |
| **Proxy URL** | `https://proxy.alienai.id:443` (CONNECT). Dev: `http://127.0.0.1:{C35_EGRESS_PROXY_PORT}` with `Host: proxy.alienai.id` or plain localhost in smoke script. |
| **Client auth** | `Proxy-Authorization: Basic base64("{lease_id}:{password}")` on CONNECT. |
| **Allowlist** | v1: configurable set; default test hosts `api.ipify.org`, `ifconfig.me`, `httpbin.org`; deny all others unless lease carries `allow_hosts[]` (admin/root) or prompt-run flag `egress_allow_captcha_hosts` (later). |
| **Concurrency** | Max **4** concurrent tunnels per lease; max **16** per device while agent online. |

---

## Implementation status (today)

| Piece | Status |
|--------|--------|
| `proxy.alienai.id` DNS / ingress | **In repo** — ship via [captcha + egress ship plan](2026-10-11-captcha-egress-ship-multitask.md) Track OPS |
| `c35_mod_device::egress` (lease, CONNECT, registry) | **Done** in repo |
| Agent egress relay (`c_remote_core::egress`) | **Done** in repo |
| `device.egress.lease` invoke | **Done** |
| Smoke `test_device_egress_proxy.ps1` | **Done** in repo — run after OPS |
| Captcha integration | **[captcha + egress ship plan](2026-10-11-captcha-egress-ship-multitask.md) Track CAPTCHA** |

---

## Outcomes (acceptance)

1. Paired **Windows** agent (99000 test device) online on **`api.alienai.id`**.
2. Mint lease → receive `username`, `password`, `proxy_url`.
3. `curl -x $proxy_url -U "$username:$password" https://api.ipify.org` returns **the same public IP** as `curl https://api.ipify.org` run **on that PC** (not OCI pod IP).
4. Wrong password → **407**; expired lease → **407**; disallowed host → **403**; agent offline → **502** with clear body.
5. **OTA**: published remote agent build includes egress handler; Chito VM or Hyper-V agent updates and passes smoke.
6. Unit/integration tests in Rust for CONNECT auth + mock agent relay (no live cluster required in CI).

---

## Master wave map

```text
W0  Spec + proto (egress messages, lease RPC)
 │
 ├── W1  mod_device_egress (lease, registry, relay logic)     [Track A]
 ├── W2  CONNECT listener + wire_http mount                   [Track B]  (after W0 proto)
 ├── W3  c_remote_core agent handler                          [Track C]  (parallel once proto frozen)
 │
W4  Ingress + DNS proxy.alienai.id + server env
 │
W5  dev smoke script + Rust integration tests + manual checklist
 │
W6  Publish server + publish remote agent(s) + prod smoke
 │
W7  (follow-up) mod_captcha + billing + inst — separate plan
```

---

## W0 — Spec + protobuf

**Owner:** one agent session (parent) or parallel subagents only for doc vs proto.

- [ ] **W0.1** Create [`_/specs/device-egress-proxy.md`](../device-egress-proxy.md): auth, allowlist, limits, error codes, split-later note (`server_egress` binary).
- [ ] **W0.2** Add messages to `_/schemas/proto/c35/remote.proto` (or new `egress.proto` imported by wire):
  - `ActDeviceEgressOpen { tunnel_id, host, port }`
  - `ActDeviceEgressData { tunnel_id, bytes }` (chunked, max 64KiB)
  - `ActDeviceEgressClose { tunnel_id, reason }`
  - `EvtDeviceEgressOpened { tunnel_id, ok, error }`
  - `EvtDeviceEgressData { tunnel_id, bytes }`
  - `EvtDeviceEgressClosed { tunnel_id }`
- [ ] **W0.3** Document frame dispatch: server → agent uses existing `remote_agent_send_raw` path; agent → server demux in `wire_ws` agent session handler (identify message type prefix or `oneof` wrapper in existing envelope if present).
- [ ] **W0.4** `cd servers && cargo build -p c35_proto` (or workspace proto crate name used today).

**Review gate:** Proto compiles; spec reviewed by Chito.

---

## W1 — Track A: `c35_mod_device_egress`

**Files (new crate):**

```text
servers/crates/mod_device_egress/
  Cargo.toml
  src/lib.rs
  src/lease.rs      # mint, validate, revoke, hash secret
  src/registry.rs   # tunnel_id -> (device_iid, mpsc, state)
  src/relay.rs      # bridge CONNECT stream <-> agent frames
  src/allowlist.rs
```

- [ ] **W1.1** Add crate to `servers/Cargo.toml` workspace; depend on `c35_store`, `c35_proto`, `tokio`, `tracing`.
- [ ] **W1.2** `lease_mint(pool, owner_iid, device_iid, req_id, ttl)` → `(lease_id, password_plain, expires_ts)`; persist `ai.device_egress_lease` table **or** JetStream KV `c35_device_egress_lease` (prefer **YB table** for audit: `lease_id`, `device_iid`, `owner_iid`, `req_id`, `secret_hash`, `expires_ts`, `revoked_ts`).
- [ ] **W1.3** `lease_validate_basic_auth(username, password)` → `LeaseContext { device_iid, owner_iid, req_id, allow_hosts }`.
- [ ] **W1.4** `tunnel_open(ctx, host, port)` → register tunnel, call `mod_device::remote_agent_send_raw` with `ActDeviceEgressOpen`; wait for `EvtDeviceEgressOpened` (timeout 15s).
- [ ] **W1.5** Bidirectional relay until CLOSE or idle timeout (5 min default).
- [ ] **W1.6** Export `egress_lease_mint` for later `captcha.solve`; v1 expose via **`device_egress_lease` HTTP** under invoke (see W2).

**Tests:**

- [ ] **W1.T1** `cargo test -p c35_mod_device_egress` — lease expiry, bad password, allowlist deny.

**Review gate:** Crate tests green without live agent (mock channel).

---

## W2 — Track B: CONNECT front door

**Files:**

```text
servers/crates/mod_device_egress/src/connect.rs   # HTTP CONNECT server task
servers/crates/wire_http/src/egress_proxy.rs    # optional: health only route
servers/server_ai/src/boot.rs                   # spawn CONNECT listener OR merge hyper on dedicated port
```

**Design v1:** Separate **listener port** inside process: `C35_EGRESS_PROXY_ADDR=0.0.0.0:8443` (Traefik routes `proxy.alienai.id:443` → Service port 8443). Keeps CONNECT parsing out of main Axum router (simpler timeouts).

- [ ] **W2.1** Implement minimal CONNECT parser (reuse pattern from `servers/c35-proxy-cf-warp/src/main.rs` — **do not** share process with WARP proxy).
- [ ] **W2.2** On CONNECT: parse `Proxy-Authorization: Basic`, validate lease, check host allowlist, call `tunnel_open`.
- [ ] **W2.3** `GET /health` on same listener → `ok`.
- [ ] **W2.4** Wire agent **inbound** egress events: extend `wire_ws` agent WS read path to forward `EvtDeviceEgress*` into `mod_device_egress::registry`.
- [ ] **W2.5** Invoke route **`device.egress.lease`** (owner + `device_remote_allowed`) returning:

```json
{
  "proxy_url": "https://proxy.alienai.id:443",
  "username": "<lease_id>",
  "password": "<one-time>",
  "expires_ts": 1234567890,
  "device_iid": 99000
}
```

- [ ] **W2.6** Env: `C35_EGRESS_PROXY_ENABLED=1`, document in `servers/server_ai/.env.example`.

**Review gate:** Local listener + mock agent unit test OR integration test with fake relay.

---

## W3 — Track C: Remote agent (`c_remote_core`)

**Files:**

```text
remotes/c_remote_core/src/egress.rs
remotes/c_remote_core/src/conn_ws.rs          # dispatch egress acts from binary frames
remotes/c_remote_core/src/webrtc/...          # only if frame dispatch lives in webrtc hub today
```

- [ ] **W3.1** Parse server → agent egress acts; on `Open`, `TcpStream::connect(host, port)` (respect allowlist mirror on agent optional—server is source of truth).
- [ ] **W3.2** Spawn relay tasks: socket → `EvtDeviceEgressData`; server data → socket.
- [ ] **W3.3** On WS disconnect: close all tunnels.
- [ ] **W3.4** `cd remotes && cargo build -p c_remote_windows && cargo build -p c_remote_browser`.
- [ ] **W3.5** Bump agent version via existing `remotes/.../version` / build.rs so OTA picks up build.

**Review gate:** Manual test against **local** `dev_server.ps1` + agent on Chito PC (99000).

---

## W4 — Cluster ingress + DNS

**Files:**

```text
_/deployments/c35-server/ingress.yaml
_/deployments/c35-server/deployment.yaml   # port 8443, env C35_EGRESS_PROXY_*
_/specs/plans/2026-09-22-platform-ops-multitask.md   # DNS row
```

- [ ] **W4.1** Service port **8443** → `c35-egress-proxy` name or extra port on `c35-server` Service.
- [ ] **W4.2** Ingress host **`proxy.alienai.id`** → that port; TLS cert covers SAN (same secret as api or dedicated).
- [ ] **W4.3** Cloudflare DNS **A** record → OCI LB IP; **grey cloud** (same as api) unless CONNECT testing requires otherwise—document result of smoke.
- [ ] **W4.4** Traefik: **long** read/write timeout for proxy host only.

**Review gate:** `curl -sf https://proxy.alienai.id/health` from laptop.

---

## W5 — Tests + dev smoke

**Files:**

```text
servers/crates/mod_device_egress/tests/connect_auth_test.rs
servers/crates/mod_device_egress/tests/relay_mock_test.rs
_/scripts/dev/test_device_egress_proxy.ps1
_/scripts/dev/test_device_egress_proxy.md   # optional one-pager in spec instead
```

- [ ] **W5.1** Rust: Basic auth success/failure; allowlist; expired lease.
- [ ] **W5.2** Script `test_device_egress_proxy.ps1`:
  1. Requires `$env:C35_SERVER_URL`, paired agent online.
  2. Invoke `device.egress.lease` (or `tool_exec` / HTTP invoke) for `device_iid`.
  3. `$direct = curl https://api.ipify.org` on **local machine** (user runs on same PC as agent).
  4. `$via = curl -x $proxy_url -U "$user:$pass" https://api.ipify.org`.
  5. Assert `$direct -eq $via`; exit 1 with diagnostics on mismatch.
- [ ] **W5.3** Second check: `curl -x ... https://httpbin.org/get` returns JSON (proves TLS + HTTP through tunnel).
- [ ] **W5.4** Negative: wrong password → expect failure; `https://example.com` if not allowlisted → 403.

**Review gate:** Script passes on Chito agent **99000** against dev or prod `proxy.alienai.id`.

---

## W6 — Publish

- [ ] **W6.1** `.\_\scripts\deploy\publish_server.ps1` — include ingress/deployment changes.
- [ ] **W6.2** `.\_\scripts\deploy\publish_remote_agent.ps1` — **required** (`c_remote_core` changed).
- [ ] **W6.3** If `c_remote_browser` rebuilt: `publish_remote_browser.ps1`.
- [ ] **W6.4** Post-publish: run `test_device_egress_proxy.ps1` against **prod** `proxy.alienai.id`; paste **Publish summary** (server + remote agent) per cluster rules.
- [ ] **W6.5** MCP/doc: add note under device debug for `device.egress.lease` (no user-facing 2Captcha yet).

**Review gate:** Prod smoke green; agent build on test device ≥ published version.

---

## Parallel dispatch (subagents)

| Wave | Tracks | Can parallelize |
|------|--------|-----------------|
| W0 | — | Single |
| W1 + W2 | A + B | After W0: B needs proto + lease API from A (start B after W1.2) |
| W3 | C | After W0 proto; integrate with W2.4 when server ingress events wired |
| W4 | — | After W2 listener works locally |
| W5 | — | After W3 + W4 for full e2e |
| W6 | — | Sequential publish |

Suggested **wave 1 execution:** Subagent **A** = W0+W1, Subagent **B** = W3 (agent) once proto merged; parent integrates W2+W4.

---

## Manual test checklist (Chito)

1. Pair Windows agent; confirm online in app.
2. `device.egress.lease` for that `device_iid` + fake `req_id`.
3. Note `username` / `password` / `proxy_url`.
4. On the **same PC as the agent**: compare ipify direct vs proxied (script does this).
5. Revoke: wait TTL or add `device.egress.revoke` (optional v1.1); confirm CONNECT fails.

---

## Follow-up plan (not this file)

- **`2026-10-11-captcha-solver-multitask.md`** (to write): `mod_captcha`, 2Captcha provider, `captcha.solve`, `browser.captcha.apply`, billing at 2Captcha SKU × 1.50, AI OCR fallback, `device.egress.lease` from `prompt_run` only.

---

## SQL sketch (W1)

```sql
CREATE TABLE IF NOT EXISTS ai.device_egress_lease (
  lease_id        BIGINT PRIMARY KEY,
  device_iid      BIGINT NOT NULL,
  owner_iid       BIGINT NOT NULL,
  req_id          TEXT NOT NULL,
  secret_hash     TEXT NOT NULL,
  allow_hosts_json JSONB NOT NULL DEFAULT '[]',
  expires_ts      TIMESTAMPTZ NOT NULL,
  revoked_ts      TIMESTAMPTZ,
  created_ts      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS device_egress_lease_device_idx ON ai.device_egress_lease (device_iid) WHERE revoked_ts IS NULL;
```

Add to `_/schemas/identity.sql` or new `_/schemas/device_egress.sql` per schema conventions.
