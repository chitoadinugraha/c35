# Site custom domain + TLS + platform mail — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline.
>
> **Specs (read first):** [`spec.md`](../../../spec.md) · [`_/docs/site.md`](../../../_/docs/site.md) · [`_/docs/architecture.md`](../../../_/docs/architecture.md) · [`_/schemas/site.sql`](../../../_/schemas/site.sql)

**Goal:** Ship **HTTP custom domains** (verify DNS → serve site on `Host` → TLS on origin) and **platform mail** (CSA `mod_mail` parity: `@alienai.id` + site mailboxes + CF Email Routing/Sending for customer zones), with **`site.alienai.id` grey** as the CNAME target.

**Architecture:**

- **HTTP** stays in `c35-server` / `mod_site`: existing `site.domain` rows; add verify RPC + real `tls_sync` (cert-manager Ingress per hostname). **Private keys stay in k8s** (cert-manager Secrets) — YB only `tls_status` / errors per locked `site.md`.
- **DNS:** Customers CNAME (or apex A) to **`site.alienai.id`** (proxied **false**). `alienai.id` remains orange for `/{alien_id}` only.
- **Mail** is a **separate crate** `mod_mail` (port from CSA git `e34b9bf2`), YSQL schema **`mail.*`**, CF APIs for zone onboard — **not** the same code path as `site.domain` HTTP verify.

**Tech stack:** Rust `servers/` (`mod_site`, new `mod_mail`), protobuf `site.proto` + new `mail.proto`, Flutter Sites Settings + Mail page, Traefik/cert-manager, Cloudflare API (`CLOUDFLARE_API_TOKEN`).

## Global constraints

- Read `spec.md` and relevant `_/docs/*` before coding; revise doc first if behavior diverges.
- Guest path URLs: `https://alienai.id/{alien_id}/…` — never `{alien_id}.alienai.id`.
- App RPC/WS: `https://api.alienai.id` — not guest HTML host.
- One **verified hostname → one site** (`uq_site_domain_hostname`); subdomains are separate FQDN rows.
- Build: `cd servers && cargo build -p server_ai`; tests `cargo test -p c35_mod_site` / `c35_mod_mail` when added; Flutter `cd clients/app && flutter analyze`.
- Rust cache under `.cache/server` only.
- Do not commit unless user asks.

## Explicitly out of scope (this plan)

| Item | Notes |
|------|--------|
| Storing TLS PEM/private keys in Yugabyte | Contradicts `site.md`; use cert-manager |
| CF SSL for SaaS / Custom Hostnames only (no origin Ingress) | Alternative architecture — pick Track D0 if switching |
| Wildcard HTTP domains (`*.example.com`) | Future |
| Same hostname → multiple sites (N:N) | Future |
| CSA domain registrar buy flow | Optional later (`cloudflare_registrar.rs`) |
| Full custom-host multi-page routes on custom domain (posts/forms) | CSA parity stretch — Track H4 optional |

## Reference sources

| What | Where |
|------|--------|
| HTTP verify + DNS | `D:\csa_site_published` @ `a813e99a` — `mod_site/src/service.rs` (`site_domain_verify`, `dns_cname_points_to`, `domain_cname_target`) |
| TLS Ingress sync | CSA `mod_site/src/tls_sync.rs` @ `a813e99a` (~500 lines) |
| Platform mail | CSA `git show e34b9bf2:crates/mod_mail/` + `clients/app/lib/pages/mail/` + mail protos in CSA `ca_pb` |
| c35 today | `site.domain`, `try_custom_domain_root`, `site_domain_put`, Domains UITable, `tls_sync` stub |

**CSA `mod_mail` is deleted on CSA `HEAD`** — always checkout files from commit **`e34b9bf2`** (last commit before removal).

---

## Multitask map

```
WAVE 0 — Decisions + docs (parallel, no code)
  D0  Architecture lock (origin TLS vs CF SaaS) + update site.md
  D1  mail.md spec sketch + schema outline

WAVE 1 — Platform DNS + env (ops + tiny code)
  O1  CF: site.alienai.id grey A → origin IP
  O2  C35_PRIMARY_HOSTS + C35_DOMAIN_CNAME_TARGET in deployment

WAVE 2 — HTTP custom domain server (parallel)
  H1  DNS verify RPC + dns helper
  H2  tls_sync port (cert-manager) + RBAC
  H3  site.domain columns (verify_error, tls_error, last_verify_ts) migration

WAVE 3 — HTTP Flutter + copy (after H1 proto)
  F1  Verify / Fix HTTPS UI (CSA dialogs pattern)
  F2  Settings domain hints → site.alienai.id

WAVE 4 — Mail foundation (parallel with W2/W3 once D1 done)
  M1  mail.sql + mail.proto + crate scaffold
  M2  Port core service (mailbox, message, send, inbound webhook)
  M3  Port CF domain onboard (mail_domain, sending, routing)
  M4  Wire WS/RPC in wire_ws + wire_http webhook

WAVE 5 — Mail Flutter
  M5  page_mail + conn + app nav entry

WAVE 6 — Integration
  I1  E2E HTTP custom domain on test hostname
  I2  E2E mail send/receive smoke (@alienai.id)
  I3  Doc index + deploy runbook
```

### Suggested agent assignments

| Wave | Agent | Track | Deliverable |
|------|-------|-------|-------------|
| 0 | A | D0 | Revised `site.md` + env contract |
| 0 | B | D1 | `_/docs/mail.md` + `mail.sql` draft |
| 1 | C | O1+O2 | CF DNS + `c35-server` deployment env |
| 2 | D | H1 | `ReqSiteDomainVerify` + DNS |
| 2 | E | H2 | `tls_sync` + k8s RBAC |
| 2 | F | H3 | SQL migration + proto fields |
| 3 | G | F1+F2 | Flutter domain UX |
| 4 | H | M1 | Schema + proto |
| 4 | I | M2 | Inbound/outbound + storage |
| 4 | J | M3+M4 | CF + HTTP webhook + RPC |
| 5 | K | M5 | Flutter mail UI |
| 6 | L | I1–I3 | E2E + runbook |

---

# WAVE 0 — Docs & decisions

## Track D0 — Lock HTTP + TLS architecture

**Decision (default for this plan):** **Origin TLS** — customer grey DNS → `site.alienai.id` → Traefik → cert-manager **per-host Ingress** (CSA `tls_sync`). Orange `alienai.id` unchanged.

**Files:**

- Modify: [`_/docs/site.md`](../../../_/docs/site.md) — replace “CNAME → alienai.id, orange OK” with **`site.alienai.id` grey** + cert-manager; list env vars.
- Modify: [`_/docs/plans/2026-09-22-platform-ops-multitask.md`](../../../_/docs/plans/2026-09-22-platform-ops-multitask.md) — add `site.alienai.id` row in DNS table (optional cross-link).

**Tasks:**

- [x] Document `C35_DOMAIN_CNAME_TARGET` (default `site.alienai.id`).
- [x] Document `C35_TLS_SYNC_ENABLED`, `C35_TLS_NAMESPACE`, `C35_TLS_CLUSTER_ISSUER` (mirror CSA `CSA_TLS_*` semantics).
- [x] Document verify: CNAME chain **or** A/AAAA match target (apex).
- [x] State clearly: **no PEM in YB**.

**Acceptance:** Another engineer can configure DNS without reading chat history.

---

## Track D1 — Mail spec + schema outline

**Files:**

- Create: [`_/docs/mail.md`](../../../_/docs/mail.md)
- Create: [`_/schemas/mail.sql`](../../../_/schemas/mail.sql) (draft — apply order after `identity.sql`)

**Content to lock in `mail.md`:**

| Topic | CSA behavior to preserve |
|-------|-------------------------|
| Personal mailbox | `{alien_id}@alienai.id` on signup / role grant |
| Site mailbox | `kind=site`, tied to `site_iid` |
| `mail.domain` | CF zone required; admin `domain_add` runs sending + routing worker |
| Inbound | HTTP webhook → `mail_message` rows |
| Outbound | CF worker / SMTP config from env |
| vs `site.domain` | HTTP CNAME verify ≠ mail zone onboard; optional UX link later |

**Tables (proposed `mail` schema):**

- `mail.domain` — hostname, `zone_id`, `sending_enabled`, `routing_enabled`, `setup_error`, timestamps
- `mail.mailbox` — id, address (unique lower), kind (`personal`|`site`), `owner_iid` / `site_iid`, label, limits
- `mail.mailbox_member` — ACL / notify uids (map to `identity` iid)
- `mail.message` — direction, from/to, subject, bodies, attachments JSON, status, read_at, timestamps
- Seed row: `alienai.id` domain enabled

**Acceptance:** `mail.sql` parses; listed in `_/schemas/README.md` apply order.

**Tasks (D1):** [x] `mail.md` + `mail.sql` + README; [x] `sql_stmts_parses_mail_sql` test; [x] `SCHEMA_APPLY_ORDER` includes `mail` after `identity`.

---

# WAVE 1 — Ops: `site.alienai.id`

## Track O1 — Cloudflare DNS

**Tasks (cluster/CF — document in plan runbook):**

- [x] Create DNS `site.alienai.id` → same origin IP as `api.alienai.id`, **proxied: false** (grey).
- [ ] Confirm Traefik accepts requests with `Host: site.alienai.id` (health: `curl -H 'Host: site.alienai.id' https://<origin>/livez` if exposed, or in-cluster).

**Acceptance:** `dig site.alienai.id` returns origin IP, not CF proxy-only edge if grey.

---

## Track O2 — Server env + primary hosts

**Files:**

- Modify: [`_/deployments/c35-server/deployment.yaml`](../../../_/deployments/c35-server/deployment.yaml)
- Modify: [`servers/crates/mod_site/src/http.rs`](../../../servers/crates/mod_site/src/http.rs) — ensure `site.alienai.id` in primary set via env
- Modify: [`_/scripts/deploy/sync_c35_server_env.ps1`](../../../_/scripts/deploy/sync_c35_server_env.ps1) if env template exists

**Tasks:**

- [x] Set `C35_DOMAIN_CNAME_TARGET=site.alienai.id`
- [x] Set `C35_PRIMARY_HOSTS=alienai.id,www.alienai.id,site.alienai.id` (or document append to default)
- [x] Set `C35_TLS_SYNC_ENABLED=1` when Track H2 ships

**Acceptance:** `host_is_primary("site.alienai.id")` true; custom domain lookup does not treat it as a customer site.

---

# WAVE 2 — HTTP custom domain (server)

## Track H3 — Schema migration (do first in wave 2)

**Files:**

- Modify: [`_/schemas/site.sql`](../../../_/schemas/site.sql)
- Add: [`_/schemas/migrations/site_domain_verify_v1.sql`](../../../_/schemas/migrations/site_domain_verify_v1.sql)

**Columns on `site.domain`:**

- `verify_error VARCHAR(512) NOT NULL DEFAULT ''`
- `tls_error TEXT NOT NULL DEFAULT ''`
- `last_verify_ts TIMESTAMPTZ`

**Proto:** extend `SiteDomain` in [`_/schemas/proto/c35/site.proto`](../../../_/schemas/proto/c35/site.proto); regen Dart + Rust.

**Acceptance:** migrate applies; `site_domain_put` preserves new fields.

**Tasks (H3):** [x] schema + proto + Rust/Dart wiring. **Ops:** run `_/schemas/migrations/site_domain_verify_v1.sql` on existing YB before deploy (fresh installs get columns from `site.sql`).

---

## Track H1 — DNS verify RPC

**Status:** [x] Done ([DNS verify RPC](e11e462f-7e60-4490-988d-7c07df0b96af)).

**Files:**

- Create: `servers/crates/mod_site/src/dns_verify.rs` (port CSA `dns_cname_points_to`, `domain_cname_target` → `C35_DOMAIN_CNAME_TARGET`)
- Modify: [`servers/crates/mod_site/src/site_domain.rs`](../../../servers/crates/mod_site/src/site_domain.rs) — `site_domain_verify`
- Modify: [`_/schemas/proto/c35/site.proto`](../../../_/schemas/proto/c35/site.proto) — `ReqSiteDomainVerify`, `ResSiteDomainVerify` (+ optional `ReqSiteDomainCertEnsure`, `ResSiteDomainCertStatus`)
- Modify: [`servers/crates/wire_ws/src/session.rs`](../../../servers/crates/wire_ws/src/session.rs) — dispatch
- Modify: [`clients/app/lib/c/chat/chat_conn.dart`](../../../clients/app/lib/c/chat/chat_conn.dart) + [`site_api.dart`](../../../clients/app/lib/c/site/site_api.dart)

**Logic:**

- [ ] Grant: `site_grant_check` manage on `site_iid`
- [ ] Reject primary platform hosts
- [ ] On success: set `verified_ts`, clear `verify_error`, set `last_verify_ts`
- [ ] On failure: set `verify_error`, leave `verified_ts` null
- [ ] Call `domain_tls_ensure` after verify (H2)

**Tests:**

- [ ] Unit tests for `normalize_hostname` + DNS helper with mocked resolver or fixed test vectors

**Acceptance:** `prompt_compose` N/A; manual/API: verify test hostname sets `verified_ts`; `try_custom_domain_root` serves site.

---

## Track H2 — TLS sync (cert-manager)

**Status:** [x] Done ([TLS sync](a588b49b-58e5-4f09-8c26-9769cf699f4a)); RBAC applied to cluster.

**Files:**

- Replace stub: [`servers/crates/mod_site/src/tls_sync.rs`](../../../servers/crates/mod_site/src/tls_sync.rs) — port from CSA @ `a813e99a` (adjust labels `csa.alienai.id` → `c35.alienai.id`, service name `c35-server`)
- Modify: [`_/deployments/c35-server/`](../../../_/deployments/c35-server/) — ServiceAccount + Role for Ingress/cert-manager read (if not present)
- Optional: Cron or on-demand `site_domain_cert_status` RPC refreshing `tls_status` from cluster

**Tasks:**

- [ ] `domain_tls_ensure(hostname, force)` creates/updates Ingress TLS rule → `c35-server` backend
- [ ] `domain_tls_status` → map to `pending`|`ready`|`failed`|`disabled`
- [ ] `domain_tls_delete` on domain row soft-delete
- [ ] Update `site_domain_put` / verify to persist `tls_status` + `tls_error`

**Acceptance:** On cluster, verify test domain → Ingress `c35-domain-<sanitized>` exists; `tls_status` becomes `ready` when secret exists.

---

# WAVE 3 — HTTP Flutter

## Track F1 — Verify + Fix HTTPS UI

**Reference:** CSA `io_custom_domain_dialogs.dart`, `ui_site_custom_domain_section.dart` @ `a813e99a`

**Files:**

- Modify: [`clients/app/lib/widgets/sites/ui_site_detail.dart`](../../../clients/app/lib/widgets/sites/ui_site_detail.dart)
- Add: `clients/app/lib/widgets/sites/io_site_domain_dialogs.dart` (CNAME dialog, target from constant/config)

**Tasks:**

- [x] Per-row **Verify** when `verified_ts` empty
- [x] Show DNS steps: CNAME → `site.alienai.id` (not `alienai.id`)
- [x] Chips: DNS verified, HTTPS pending/ready/failed
- [x] **Fix HTTPS** when `tls_status=failed` — `ReqSiteDomainVerify.force_tls` + `domain_tls_ensure(..., true)`

**Acceptance:** `flutter analyze` clean; UX matches CSA flow without domain-buy button (optional add later).

---

## Track F2 — Copy + collection def

**Files:**

- Modify: [`clients/app/lib/c/site/site_table_rows.dart`](../../../clients/app/lib/c/site/site_table_rows.dart) — surface `verify_error`, `tls_error` read-only if migrated
- Modify: [`clients/app/lib/c/site/collection_def.dart`](../../../clients/app/lib/c/site/collection_def.dart)

**Acceptance:** Domains table shows TLS/verify state without manual DB edits.

**Tasks (F2):** [x] `verify_error` / `tls_error` / chips in Settings domains UI.

---

# WAVE 4 — Platform mail (`mod_mail`)

## Track M1 — Schema + proto + crate

**Status:** [x] Scaffold done ([mod_mail scaffold](da245f60-710a-483b-8336-e844a59aebe5)); RPC stubs return `mail: not implemented`. `mail.*` tables on YB; `SCHEMA_APPLY_ORDER` has `mail` after `identity`.

**Files:**

- Finalize: [`_/schemas/mail.sql`](../../../_/schemas/mail.sql)
- Create: [`_/schemas/proto/c35/mail.proto`](../../../_/schemas/proto/c35/mail.proto) — port message names from CSA `Mail*` (list/get/send/mailbox/domain)
- Create: `servers/crates/mod_mail/` — `Cargo.toml`, `lib.rs`, module split like CSA
- Modify: [`servers/Cargo.toml`](../../../servers/Cargo.toml), [`servers/server_ai/Cargo.toml`](../../../servers/server_ai/Cargo.toml), boot in `server_ai`

**Tasks:**

- [x] `mail.sql` + `mail.proto` + `c35_mod_mail` crate + wire slots 86–92 / 134–140
- [x] `cargo build -p server_ai`
- [ ] Full CSA identity mapping + real RPC (M2/M3)

**Acceptance:** Server starts with mail schema applied; WS mail handlers stubbed until M2.

---

## Track M2 — Core mail service

**Status:** [x] Core ported ([Mail core + wire](9e194c2f-1f5e-41ed-af99-4e7d4b504af8)); tests + group/broadcast deferred.

**Port from `e34b9bf2`:**

- `service.rs`, `mailbox.rs`, `access.rs`, `attachments.rs`, `inbound.rs`, `outbound.rs`, `events.rs`

**Adapt:**

- [ ] Personal mailbox provision on identity create (or explicit RPC) — port `provision_on_role_grant` if still desired
- [ ] Attachments via `mod_file` / CAS (replace CSA `FileStore` paths)
- [ ] ACL: mail admin role → c35 `global_roles` or config flag

**Tests:**

- [ ] `cargo test -p c35_mod_mail` — list/send validation, address parsing

**Acceptance:** Unit tests pass; inbound webhook inserts message row.

---

## Track M3 — Cloudflare domain onboard

**Port:** `cloudflare.rs`, `domain.rs` from `e34b9bf2`

**Files:**

- `servers/crates/mod_mail/src/cloudflare.rs`
- `servers/crates/mod_mail/src/domain.rs`

**Env:**

- `CLOUDFLARE_API_TOKEN`
- Worker name for routing catch-all (document; deploy worker separately if not in repo)

**RPC:** `mail_domain_list`, `mail_domain_add`, `mail_domain_fix` (admin)

**Acceptance:** Admin can add a zone that exists in CF account; `mail.domain` row reflects sending/routing flags.

---

## Track M4 — Wire integration

**Status:** [x] WS + inbound webhook shipped with M2 ([Mail core + wire](9e194c2f-1f5e-41ed-af99-4e7d4b504af8)).

**Files:**

- Modify: [`_/schemas/proto/c35/wire.proto`](../../../_/schemas/proto/c35/wire.proto) — `mail_*` req/res slots
- Modify: [`servers/crates/wire_ws/src/session.rs`](../../../servers/crates/wire_ws/src/session.rs)
- Modify: [`servers/crates/wire_http/src/web.rs`](../../../servers/crates/wire_http/src/web.rs) or router — **inbound mail webhook** path (match CSA route + signature verify `verify_inbound_signature`)

**Security:**

- [ ] Webhook secret env; reject unsigned inbound
- [ ] Document in [`_/docs/mcp-security.md`](../../../_/docs/mcp-security.md) if debug tools touch mail

**Acceptance:** App can `mail_list` / `mail_send`; CF worker POST delivers inbound message visible in list.

---

# WAVE 5 — Mail Flutter

## Track M5 — Client mail UI

**Port from CSA @ `e34b9bf2`:**

- `clients/app/lib/pages/mail/page_mail.dart`
- `clients/app/lib/core/mail/*` (adapt to c35 `c/chat`, pb package, `l()` logging)

**Tasks:**

- [ ] Nav entry (avatar menu or similar — match CSA `ui_user_menu.dart`)
- [ ] Inbox list, read, send, archive
- [ ] Admin domain UI (if CSA had — optional v1: server-only admin RPC)

**Acceptance:** `flutter analyze`; signed-in user sees `{alien_id}@alienai.id` mailbox.

---

# WAVE 6 — Integration

## Track I1 — HTTP E2E

**Checklist:**

- [ ] Add `test-verify-<random>.<your-test-domain>` CNAME → `site.alienai.id`
- [ ] Verify in app → `verified_ts` set
- [ ] `curl -H "Host: test-verify-…" https://…/` returns published HTML
- [ ] TLS valid in browser (or `openssl s_client`)
- [ ] `alienai.id/{alien_id}` still works orange path

---

## Track I2 — Mail E2E

- [ ] Send to `{alien_id}@alienai.id` from external MTA → inbound webhook → message in app
- [ ] Send from app → arrives at external inbox (or CF worker log)
- [ ] (Stretch) Site mailbox on `site_iid` receives mail

---

## Track I3 — Docs + deploy

- [ ] [`spec.md`](../../../spec.md) project references — add `mail.md`
- [ ] [`_/docs/README.md`](../../../_/docs/README.md) index
- [ ] Runbook section: DNS matrix (`alienai.id` orange, `api` grey, `site` grey, customer CNAME target)
- [ ] Raise `app.release` / proto only if wire breaks old clients (coordinate `app-release-min.mdc`)

---

## Dependency graph (critical path)

```
D0 ──┬──> O1/O2 ──> H1 ──> F1
     │              H2 ──┘
D1 ──> M1 ──> M2 ──> M4 ──> M5 ──> I2
H3 ──> H1
M3 ──> M4
F1, M5, H2 ──> I1, I3
```

**Parallelizable early:** D0 + D1; then H3 + M1; then H1 + H2 + M2 + M3; F1 after H1 proto merge.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| cert-manager rate limits | Debounce `domain_tls_ensure` (CSA has debounce) |
| Customer orange-clouds their domain to wrong target | Verify uses IP/CNAME chain; clear errors in UI |
| Mail requires customer zone on CF | Document in mail.md; not solvable with HTTP CNAME alone |
| CSA proto ID mismatch | New c35 `mail.proto` wire ids — do not reuse CSA fn numbers blindly |
| Ingress sprawl | Label + garbage-collect Ingress on domain delete |

---

## Verification commands (summary)

```powershell
cd servers
cargo build -p server_ai
cargo test -p c35_mod_site
cargo test -p c35_mod_mail

cd clients/app
flutter analyze
```

Manual: Tracks I1, I2 after deploy to btm cluster.
