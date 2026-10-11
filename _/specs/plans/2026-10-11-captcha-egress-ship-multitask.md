# Captcha solver + egress proxy ship — master multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review **Prerequisites** and run **Track OPS** before prod smoke. **Track CAPTCHA** can run in parallel with OPS once W0 spec is frozen. **Track PUBLISH** needs green `cargo build` + OPS env/ingress (captcha can land in a follow-up publish if you split releases).

**Goal:** (1) **Ship** device egress (`proxy.alienai.id`, schema, ingress, DNS, `publish_server` + `publish_remote_agent`, prod smoke). (2) **Implement** white-label **captcha solving** (2Captcha primary, billed at wholesale × **1.50**), **IP-aligned** via `device.egress.lease` + CONNECT, **only during automated prompt/browser tasks** — phased: **Playwright → per-tenant → desktop → extension / AI OCR**.

**Architecture:** Egress is implemented in `c35_mod_device::egress` + `c_remote_core::egress` (see prior plan). Cluster calls **2Captcha** from `c35_mod_captcha` (new crate), passing **device egress proxy** credentials so solver traffic matches the paired agent’s public IP. **`captcha.solve`** returns a token/solution; **`browser.captcha.apply`** injects it on the **Playwright** remote browser (phase 1). Billing uses `RETAIL_MARKUP` (1.50) over 2Captcha list prices; users never see “2Captcha” in UI or tool text.

**Tech stack:** Rust (`server_ai`, `c35_mod_captcha`, `c35_mod_device`, `c35_mod_billing`, `c35_mod_chat` tools), YSQL (`ai.device_egress_lease`, optional `ai.captcha_job`), protobuf if needed, k8s Traefik (`ingress-proxy.yaml`), Cloudflare DNS, Buildkit `publish_server.ps1` / `publish_remote_agent.ps1`, PowerShell smoke `test_device_egress_proxy.ps1`.

**Related specs/plans:** [`device-egress-proxy.md`](../device-egress-proxy.md), [`2026-10-11-device-egress-proxy-multitask.md`](2026-10-11-device-egress-proxy-multitask.md) (implementation waves), [`schema-migrate.md`](../schema-migrate.md), [`browser-remote.md`](../browser-remote.md), [`remote.md`](../remote.md).

## Global constraints

- **No provider web grounding** on LLM bodies (`web-grounding-cluster-only.mdc`).
- **UTF-8** sources; `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` after edits.
- **Server:** `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_captcha` when crate exists; `cargo test -p c35_mod_device --lib`.
- **Remote:** `cd remotes && cargo build -p c_remote_windows` (+ `-p c_remote_browser` if core touched).
- **Cluster images:** `.\_\scripts\deploy\publish_server.ps1` and `publish_remote_agent.ps1` — **no** local `docker build` for arm64 (`cluster-buildkit.mdc`). End ship replies with **Publish summary** from `.cache/publish-perf/latest.json`.
- **Device debug:** Chito machines **`owner_iid` 99000** (`device-control-chito.mdc`).
- **Prompt verification** for inst/tool changes: `prompt_compose` / `prompt_run` (`prompt-run-test.mdc`).
- **Do not commit** unless user asks.

---

## Prerequisites (egress code — done in repo)

| Piece | Status |
|--------|--------|
| Proto `ReqDeviceEgress*` / `DeviceEgress*` + invoke `device_egress_lease` | Done |
| `ai.device_egress_lease` in `_/schemas/device_egress.sql` + `schema.rs` order | Done |
| `mod_device::egress` CONNECT + registry + lease | Done |
| `c_remote_core::egress` TCP relay | Done |
| `ingress-proxy.yaml`, Service/Deployment port **8443** | In repo, **not applied** |
| `test_device_egress_proxy.ps1` | In repo |
| Captcha (`mod_captcha`, tools, billing) | **This plan** |

---

## Parallel track map

```text
Track OPS (ship egress)          Track CAPTCHA (feature)
────────────────────────         ─────────────────────────
OPS1 Schema apply                C0 Spec + proto (if any)
OPS2 Cluster env secret          C1 mod_captcha + 2Captcha client
OPS3 kubectl ingress-proxy       C2 captcha.solve + billing
OPS4 DNS proxy.alienai.id        C3 egress lease + proxy param
OPS5 Pre-publish smoke           C4 browser.captcha.apply (Playwright)
                                 C5 inst.sql + live inst_put
                                 C6 Tests + prompt_run
        \                       /
         v                     v
      Track PUBLISH (server + remote agent OTA)
      PUB1 publish_server.ps1
      PUB2 publish_remote_agent.ps1 (+ browser OTA if needed)
      PUB3 Prod smoke (egress + optional captcha e2e)
```

**Suggested dispatch:** Subagent **OPS** + **C0–C1** in parallel → **PUBLISH** when OPS2–4 done → **C2–C6** can merge before or after first publish (recommend **egress-only publish first**, captcha **second publish** unless you want one combined release).

---

## Locked product decisions (captcha)

| Topic | Decision |
|--------|----------|
| Provider | **2Captcha** API (cluster secret `C35_2CAPTCHA_API_KEY`); no user-facing provider name |
| Markup | `billing_to_retail_usd(wholesale)` → **× 1.50** (`RETAIL_MARKUP` in `billing_cost.rs`) |
| IP alignment | Mint **`device.egress.lease`** for target `device_iid`; pass `proxy` to 2Captcha as `https://proxy.alienai.id:443` + Basic auth (`lease_id` / one-time password) |
| When allowed | **Automated task paths only** — `browser.task.run` / active `prompt_run` / task worker for that `req_id`; reject bare Home chat unless `inst` + active task (implementation: guard in `captcha.solve` + tool topics / `include_tools`) |
| Phase 1 surface | **Playwright** `type=browser`, `browser_engine=playwright` |
| Phase 2 | Per-tenant caps / optional BYO key (deferred sub-wave) |
| Phase 3 | **Windows desktop** / `computer_use` hooks (deferred) |
| Phase 4 | Chrome **extension** browser + **AI OCR** fallback (deferred) |
| Human fallback | Keep inst: if solve fails or 2FA, user completes on **Remote** tab |

---

# Track OPS — Ship egress proxy

### OPS1 — Apply schema (`ai.device_egress_lease`)

- [ ] **OPS1.1** Confirm `_/schemas/device_egress.sql` is in `SCHEMA_APPLY_ORDER` (`servers/crates/store/src/schema.rs`).
- [ ] **OPS1.2** From dev machine with YB reachability (Tailscale / cluster DNS):

```powershell
cd D:\c35\servers
cargo run -p c35_store --bin c35_migrate -- apply
```

- [ ] **OPS1.3** Verify table exists (MCP `yb_query` or `user-alienai-yb`):

```sql
SELECT lease_id, device_iid, expires_ts FROM ai.device_egress_lease LIMIT 1;
```

- [ ] **OPS1.4** After next `server_ai` rollout, pod logs include `schema: up to date` (hash includes `device_egress.sql`).

**Review gate:** `c35_migrate apply` succeeds; no duplicate-object errors on re-run.

---

### OPS2 — Cluster env (`c35-server-env`)

Add to **`c35-server-env`** secret (and document in `servers/server_ai/.env.example` — already partially done):

| Key | Value |
|-----|--------|
| `C35_EGRESS_PROXY_ENABLED` | `1` |
| `C35_EGRESS_PROXY_ADDR` | `0.0.0.0:8443` |
| `C35_EGRESS_PROXY_PUBLIC_URL` | `https://proxy.alienai.id:443` |

Optional for captcha track (can wait until C2):

| Key | Value |
|-----|--------|
| `C35_2CAPTCHA_API_KEY` | cluster secret only |

- [ ] **OPS2.1** Patch secret (extend `sync_c35_server_env.ps1` `-Keys` or `kubectl edit secret c35-server-env -n c35`).
- [ ] **OPS2.2** `kubectl rollout restart deployment/c35-server -n c35` and wait for ready.
- [ ] **OPS2.3** Confirm pod listens: `kubectl logs -n c35 deploy/c35-server --tail=200 | findstr /i egress` (or exec netstat if needed).

**Review gate:** Two replicas healthy; no crash loop on egress bind (port 8443).

---

### OPS3 — Deploy ingress

- [ ] **OPS3.1** `kubectl apply -f D:\c35\_\deployments\c35-server\ingress-proxy.yaml`
- [ ] **OPS3.2** Confirm Service exposes port name `egress` → 8443 (`service.yaml` already in repo).
- [ ] **OPS3.3** Wait for cert-manager: `kubectl describe certificate proxy-alienai-id-tls -n c35` → Ready=True.

**Review gate:** TLS secret exists; Traefik route to `c35-server:egress`.

---

### OPS4 — DNS (`proxy.alienai.id`)

Same pattern as **`api.alienai.id`**: **grey cloud OFF** (direct to OCI LB), A record to cluster ingress IP (**168.110.219.43** unless ops doc updated).

- [ ] **OPS4.1** Cloudflare MCP `dns_record_upsert_a` (or dashboard): host `proxy`, proxied **false**, TTL auto.
- [ ] **OPS4.2** `nslookup proxy.alienai.id` → expected A.
- [ ] **OPS4.3** `curl -sfI https://proxy.alienai.id/` — expect connection (CONNECT listener may not speak plain GET; **502/400 is OK** if TLS and routing work). Prefer smoke script for real check.

**Review gate:** `openssl s_client -connect proxy.alienai.id:443 -servername proxy.alienai.id` handshake OK.

---

### OPS5 — Pre-publish smoke (Chito 99000)

- [ ] **OPS5.1** Pair agent online (`device_list` MCP, `owner_iid=99000`).
- [ ] **OPS5.2** Against **prod** or **local** `C35_SERVER_URL`:

```powershell
$env:C35_SERVER_URL = 'https://api.alienai.id'   # or http://127.0.0.1:PORT
$env:C35_JWT = '<session>'
.\_\scripts\dev\test_device_egress_proxy.ps1 -DeviceIid <id>
```

- [ ] **OPS5.3** Assert proxy IP matches agent PC public IP (script checks direct vs via proxy).

**Review gate:** OPS5.2 passes before **PUB1**.

---

# Track CAPTCHA — Implementation

### C0 — Spec + contracts

- [ ] **C0.1** Add [`_/specs/captcha-solver.md`](../captcha-solver.md): flows, 2Captcha task types (v2/v3/image/hCaptcha), proxy format, billing table, error codes, phase boundaries.
- [ ] **C0.2** Update [`browser-remote.md`](../browser-remote.md): automated captcha path vs human Remote tab.
- [ ] **C0.3** Optional proto: only if agent needs new messages for `browser.captcha.apply` (prefer JSON over existing browser task channel if sufficient).

**Review gate:** Chito sign-off on phase-1 scope (Playwright only).

---

### C1 — `c35_mod_captcha` crate

**Files (new):**

```text
servers/crates/mod_captcha/
  Cargo.toml
  src/lib.rs
  src/twocaptcha.rs      # HTTP client: in.php / res.php
  src/types.rs             # CaptchaKind, SolveRequest, SolveResult
  src/proxy.rs             # build 2captcha proxy= user:pass@host:port from ResDeviceEgressLease
  src/billing.rs           # wholesale_usd(kind) -> retail via billing_cost
```

- [ ] **C1.1** Workspace member in `servers/Cargo.toml`; depend on `reqwest`, `serde`, `tracing`, `c35_mod_billing`, `c35_mod_device` (lease mint internal API).
- [ ] **C1.2** `twocaptcha.rs`: create task, poll result, map errors; **no** logging of API key or proxy password.
- [ ] **C1.3** Unit tests with `httpmock` or stub trait (no live 2Captcha in CI).

**Review gate:** `cargo test -p c35_mod_captcha`.

---

### C2 — `captcha.solve` tool

- [ ] **C2.1** Register in `mod_chat` tools (`tools/builtin/captcha.rs` or under `browser.rs`):
  - **name:** `captcha.solve`
  - **params:** `device_iid`, `kind` (enum), `sitekey` / `page_url` / `image_b64` as required by kind
  - **topics:** `browser`, `device`, `task` — not `always`
- [ ] **C2.2** **Task gate:** refuse unless `prompt_run` row active for `ctx.req_id` **or** in-flight remote browser task for `device_iid` (define helper in `mod_device` or `mod_task`).
- [ ] **C2.3** Mint egress lease (`device_egress_lease_mint`) with `allow_hosts` including target page host + `2captcha.com` / `api.2captcha.com` (helper in `egress/allowlist.rs`: `captcha_egress_hosts(page_url)`).
- [ ] **C2.4** Call 2Captcha with `proxy=` set to public URL + credentials.
- [ ] **C2.5** Bill on success: extend `billing_tool_cost_usd` **or** charge inside tool via `billing_package` using per-kind wholesale from `mod_captcha::billing` (prefer single wallet line item `captcha.solve:{kind}` in `ai.log`).

**Review gate:** `prompt_run` on 33000 fixture with mocked 2Captcha returns token JSON; freemium / wallet tests if applicable.

---

### C3 — `browser.captcha.apply` (Playwright phase 1)

- [ ] **C3.1** Tool `browser.captcha.apply`: `device_iid`, `slot_id`, `tab_id`, `kind`, `token` (from `captcha.solve`).
- [ ] **C3.2** Agent path: enqueue remote browser step (same channel as `browser.page.act`) to run Playwright `evaluate` / frame injection for reCAPTCHA hCaptcha callbacks — **minimal** v1: reCAPTCHA v2 checkbox + hCaptcha.
- [ ] **C3.3** Return `{ ok, url }` after navigation settle.

**Review gate:** Manual on Chito Playwright device against `https://www.google.com/recaptcha/api2/demo` (or httpbin test page).

---

### C4 — Inst + tool catalog

- [ ] **C4.1** `_/schemas/inst.sql`: new `inst.browser.captcha` (or extend remote browser inst): when automation hits captcha, call `captcha.solve` then `browser.captcha.apply`; still escalate to user for 2FA.
- [ ] **C4.2** Relax / narrow existing “ask user on Remote tab” inst for **task** context only (keep for extension + 2FA).
- [ ] **C4.3** `inst_put` live on cluster after deploy (`prompt-run-test.mdc`).
- [ ] **C4.4** Tool `ToolDefinition` `rag_phrases` for captcha; **no** “2Captcha” in description.

**Review gate:** `prompt_compose` “solve captcha on browser” includes `captcha.solve` + browser inst; `prompt_run` hop 1 tool call on 33000.

---

### C5 — Egress allowlist for captcha hosts

- [ ] **C5.1** Lease mint from `captcha.solve` sets non-empty `allow_hosts_json` (not default ipify-only list).
- [ ] **C5.2** Document default captcha host bundle in `captcha-solver.md`.
- [ ] **C5.3** Optional env `C35_EGRESS_CAPTCHA_HOSTS_JSON` for ops overrides.

**Review gate:** CONNECT to disallowed host still **403**; allowed target host **200** through tunnel in dev.

---

### C6 — Tests + docs

- [ ] **C6.1** Rust: auth proxy string builder, billing retail math, allowlist helper.
- [ ] **C6.2** `prompt_run` regression phrase on **33000**.
- [ ] **C6.3** `_/docs/` — **defer** user guide until UI copy exists (spec-only OK).

---

### Deferred waves (do not block OPS/PUBLISH)

| Wave | Scope |
|------|--------|
| **C-P2** | Per-tenant rate limits / optional BYO 2Captcha key in `ai.identity.meta_json` |
| **C-P3** | Desktop `computer_use` + captcha |
| **C-P4** | Extension browser + on-cluster vision OCR fallback |

---

# Track PUBLISH

### PUB1 — Server

- [ ] **PUB1.1** `git status` clean enough for release (user commits).
- [ ] **PUB1.2** `.\_\scripts\deploy\publish_server.ps1` (Buildkit arm64, no `-LocalBuild`).
- [ ] **PUB1.3** Confirm rollout: `kubectl rollout status deployment/c35-server -n c35`.
- [ ] **PUB1.4** Paste **Publish summary** (target, version, image, duration).

### PUB2 — Remote agent

- [ ] **PUB2.1** `.\_\scripts\deploy\publish_remote_agent.ps1` (egress handler in `c_remote_core`).
- [ ] **PUB2.2** If `c_remote_browser` changed: `publish_remote_browser.ps1` per repo scripts.
- [ ] **PUB2.3** Chito VM / Hyper-V agent: wait for OTA or reinstall; confirm version build in logs.

### PUB3 — Production acceptance

- [ ] **PUB3.1** `test_device_egress_proxy.ps1` with `C35_SERVER_URL=https://api.alienai.id`, prod proxy URL in lease response.
- [ ] **PUB3.2** Wrong password → **407**; agent stopped → **502** (manual curl).
- [ ] **PUB3.3** After captcha ship: one end-to-end Playwright captcha demo on 99000 device (record `req_id` + `trace_get`).

**Review gate:** PUB3.1 green; Publish summaries attached for server + agent.

---

## Subagent dispatch checklist

| Subagent task | Suggested scope |
|---------------|-----------------|
| **OPS** | OPS1–OPS5 only; MCP Cloudflare DNS; no Rust |
| **Captcha core** | C0 + C1 + C2 |
| **Captcha browser** | C3 + C5 |
| **Captcha steering** | C4 + C6 prompt tests |
| **Publish** | PUB1–PUB3 after OPS gates |

Use **`model: inherit`** for all `Task` calls (`subagent-model.mdc`).

---

## Risk register

| Risk | Mitigation |
|------|------------|
| CONNECT on shared port 8443 behind Traefik | Smoke early; tune read timeouts in `connect.rs` |
| 2Captcha cost drift | Centralize wholesale table; comment source URL + date in `billing.rs` |
| Extension captcha unsupported in P1 | Inst keeps human path for `browser_engine=extension` |
| Schema apply lock | One `c35_migrate apply` at a time (`schema-migrate.md`) |
| UTF-16 on Windows edits | Use editor / UTF-8 `WriteAllText` for `.rs` |

---

## Manual checklist (Chito)

1. Agent **99000** online on prod API.
2. Egress lease returns `https://proxy.alienai.id:443`.
3. `curl -x` ipify via proxy matches PC IP.
4. (Post-captcha) Demo page submits without opening Remote tab.
5. Wallet / usage shows captcha line item at **1.50×** 2Captcha list price.
