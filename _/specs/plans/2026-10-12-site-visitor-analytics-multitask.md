# Site visitor analytics (CSA parity) — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `superpowers:executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline. Subagent **model: inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship **guest traffic tracking** (CSA `/api/analytics/ping` parity) on c35’s YSQL `site` schema — rollup-on-write storage, public ingest HTTP, **`site.query.run`** reads for Home + Sites UI, **`inst.site.visitor`** steering — plus **v2** path and link-click rollups. No LLM write tool for ingest.

**Architecture:** Guest browsers send **`sendBeacon`** pings on `pagehide` / `visibilitychange` (hidden), keyed by existing `visitor_id` + `session_id`. Server resolves **published** `site_iid` (never trust naked client `site_iid` without boot/slug validation), rate-limits by IP, upserts **day rollups** in one transaction. Owners read via **`visitor.summary`**, **`visitor.paths`**, **`link.clicks`** query defs (same grant checks as tx reports). Opt-out via **`site.config.capabilities_json.analytics`** (default **true** when absent).

**Tech stack:** YSQL `site.analytics_*` tables; Rust `c35_mod_site` (`site_analytics.rs`, `query/visitor.rs`); `wire_http` route on `api.alienai.id`; static `clients/web/static/site-guest/site-guest.v1.js`; Flutter `guest_site_analytics.dart`; `inst.sql` + `site-ai.md` / `site.md` docs.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/specs/site.md`](../site.md) · [`_/specs/site-ai.md`](../site-ai.md) · [`_/specs/time-range.md`](../time-range.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md)

**CSA reference (read-only):**

- `D:\csa_site_published\client\site\src\main.ts` — `startAnalytics()`
- `D:\csa_site_published\crates\mod_site\src\http.rs` — `guest_analytics_ping`
- `D:\csa_site_published\crates\mod_site\src\service.rs` — `analytics_summary`, `analytics_day_aggregate`

---

## Global constraints

- **No provider web grounding** on LLM paths; visitor questions use **`site.query.run`** only (`prompt-run-test.mdc`).
- **No new LLM ingest tool** — ping is HTTP only (like `guest-contact/put`).
- **ACL:** query defs call `site_grant_check(..., write: false)` per `site_iid`; ingest is **public** but scoped to valid published sites + rate limits.
- **Privacy:** store `visitor_key = blake3(visitor_id)` in DB, not raw UUID; truncate `referrer` / `user_agent` to 512 chars; document retention in `site.md`.
- **TZ:** `day_bucket` = calendar date in **`site.config.tz`** (fallback `Asia/Jakarta`).
- UTF-8 sources; verify per [`verify-after-edit.mdc`](../../.cursor/rules/verify-after-edit.mdc): `cargo build -p server_ai` from `servers/`, `check_utf8_sources.ps1 -Changed -Fix`, guest JS rebuild if bundled.
- After server/static ship: `.\_\scripts\deploy\publish_server.ps1` (Buildkit). Re-publish guest static is part of server image.

---

## Locked design

### Metrics (CSA-aligned)

Per **day** (and per site):

| Metric | Definition |
|--------|------------|
| `unique_visitors` | Distinct `visitor_key` with at least one accepted ping that day |
| `page_views` | Count of accepted pings (CSA: one row per ping ≈ page view event) |
| `active_duration_ms` | Sum of client-reported active ms (monotonic per session; server clamps delta per ping ≤ 30 min) |
| `visitor_slots` | Length-12 `int64` array: count of visitors whose **last_seen_ts** falls in each 2-hour bucket (local site TZ) |

### Capability flag

- Key: **`analytics`** in `site.config.capabilities_json`.
- **Default:** treated as **enabled** when key missing (`site_capabilities_get` / ingest helper).
- **`site.config.put`** already merges capability booleans — document `analytics` in tool description + seed inst.

### HTTP contract

| Route | Host | Body |
|-------|------|------|
| `POST /v1/site/guest-analytics/ping` | `api.alienai.id` | JSON (see Wave 2) |
| `POST /api/analytics/ping` | `alienai.id` guest router | **Alias** — same handler, for relative `sendBeacon` from published HTML |

Resolve site:

1. `alien_id` in body **or** path context from `Referer` / optional `X-Site-Alien-Id` header.
2. Lookup `ai.identity` `kind=site`, not deleted.
3. Require **active published** snapshot (`site.publish` latest row) — same gate as `guest_order_put` published check.

Reject: unknown site, unpublished, `analytics: false`, malformed payload, rate limit exceeded → `204` (no body) or `429` with `Retry-After`.

### Query catalog (no new chat tool names)

| `query_id` | Scope | Params |
|------------|-------|--------|
| `visitor.summary` | site_scoped | `range` or `day_from` / `day_to` (max 62 days, CSA cap) |
| `visitor.paths` | site_scoped | `range`, optional `limit` (default 20) |
| `link.clicks` | site_scoped | `range`, optional `limit` (default 50) |

---

## Schema (v1 + v2)

Apply canonical DDL in [`_/schemas/site.sql`](../../_schemas/site.sql) and idempotent migration [`_/schemas/migrations/site_analytics_v1.sql`](../../_schemas/migrations/site_analytics_v1.sql).

### v1 — core rollups

```sql
-- site.analytics_day — one row per site per calendar day (site TZ)
CREATE TABLE IF NOT EXISTS site.analytics_day (
    site_iid              BIGINT NOT NULL REFERENCES ai.identity(id),
    day_bucket            DATE NOT NULL,
    page_views            BIGINT NOT NULL DEFAULT 0,
    unique_visitors       INT NOT NULL DEFAULT 0,
    active_duration_ms    BIGINT NOT NULL DEFAULT 0,
    visitor_slots         JSONB NOT NULL DEFAULT '[]',  -- JSON array, length 12
    created_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket)
);

CREATE INDEX IF NOT EXISTS idx_site_analytics_day_updated
    ON site.analytics_day (site_iid, updated_ts DESC);

-- site.analytics_visitor_day — distinct visitor per day (for unique count + slots)
CREATE TABLE IF NOT EXISTS site.analytics_visitor_day (
    site_iid              BIGINT NOT NULL,
    day_bucket            DATE NOT NULL,
    visitor_key           TEXT NOT NULL,   -- blake3 hex of visitor_id
    session_key           TEXT NOT NULL DEFAULT '',  -- blake3 of session_id (v1 optional grouping)
    page_views            INT NOT NULL DEFAULT 0,
    active_duration_ms    BIGINT NOT NULL DEFAULT 0,
    last_path             TEXT NOT NULL DEFAULT '',
    last_seen_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    referrer_host         TEXT NOT NULL DEFAULT '',
    created_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket, visitor_key),
    CONSTRAINT fk_site_analytics_visitor_site
        FOREIGN KEY (site_iid) REFERENCES ai.identity(id)
);

CREATE INDEX IF NOT EXISTS idx_site_analytics_visitor_day_seen
    ON site.analytics_visitor_day (site_iid, day_bucket, last_seen_ts DESC);
```

### v2 — paths + link clicks

```sql
CREATE TABLE IF NOT EXISTS site.analytics_path_day (
    site_iid              BIGINT NOT NULL,
    day_bucket            DATE NOT NULL,
    path                  TEXT NOT NULL,   -- normalized: max 256 chars, default '/'
    views                 INT NOT NULL DEFAULT 0,
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket, path),
    CONSTRAINT fk_site_analytics_path_site
        FOREIGN KEY (site_iid) REFERENCES ai.identity(id)
);

CREATE TABLE IF NOT EXISTS site.analytics_link_day (
    site_iid              BIGINT NOT NULL,
    day_bucket            DATE NOT NULL,
    link_id               BIGINT NOT NULL,  -- site.link.link_id
    clicks                INT NOT NULL DEFAULT 0,
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket, link_id),
    CONSTRAINT fk_site_analytics_link_site
        FOREIGN KEY (site_iid) REFERENCES ai.identity(id)
);
```

### Retention (v2 ops)

- **`site.analytics_visitor_day`:** delete rows where `day_bucket < now() - 90 days` (nightly job or `mod_task` schedule) — **keeps** `analytics_day` aggregates.
- **`analytics_path_day` / `analytics_link_day`:** retain 365 days (config env `C35_SITE_ANALYTICS_RETENTION_DAYS` default 365).

---

## File map

| File | Responsibility |
|------|----------------|
| `_/schemas/site.sql` | Canonical `analytics_*` tables |
| `_/schemas/migrations/site_analytics_v1.sql` | `ADD TABLE IF NOT EXISTS` for live migrate |
| `servers/crates/mod_site/src/site_analytics.rs` | `site_analytics_ping`, `visitor_key_hash`, day bucket TZ, rollup SQL |
| `servers/crates/mod_site/src/query/visitor.rs` | `VisitorSummaryQuery`, `VisitorPathsQuery`, `LinkClicksQuery` |
| `servers/crates/mod_site/src/query/mod.rs` | Register query defs |
| `servers/crates/mod_site/tests/site_analytics_test.rs` | Ingest + aggregate unit tests |
| `servers/crates/wire_http/src/guest_analytics.rs` | Axum router + rate limit |
| `servers/crates/wire_http/src/lib.rs` | Merge router |
| `servers/crates/mod_site/src/render.rs` | Mount guest alias route if guest HTML served from same binary (or document api-only) |
| `clients/web/static/site-guest/src/site-guest.v1.js` | `c35GuestAnalytics.start()` |
| `clients/web/static/site-guest/site-guest.v1.js` | Rebuild bundle |
| `clients/app/lib/guest_site/guest_site_analytics.dart` | Flutter preview ping (same payload) |
| `clients/app/lib/widgets/sites/editor/ui_site_traffic_panel.dart` | Optional Settings/Traffic card |
| `servers/crates/mod_chat/src/tools/builtin/site.rs` | `site.config.put` description: `analytics` |
| `_/schemas/inst.sql` | `inst.site.visitor`, builder note |
| `_/specs/site-ai.md` | Query table rows |
| `_/specs/site.md` | Visitor analytics section + privacy |

---

## Multitask map

```
WAVE 0  Schema + spec lock (SQL, site.md, site-ai.md)
WAVE 1  Server ingest (mod_site site_analytics.rs + tests)
WAVE 2  wire_http routes + rate limit + published gate
WAVE 3  Query defs visitor.summary | visitor.paths | link.clicks
WAVE 4  Guest JS + link click events + static rebuild
WAVE 5  Flutter guest ping + optional Traffic panel
WAVE 6  inst + site.config.put docs + prompt_compose / prompt_run verification
WAVE 7  Retention job + MCP/prompt regression + publish_server
```

Dispatch **parallel tracks within a wave** when files do not conflict. **Order:** Wave 0 → 1 → 2 can overlap 1 tail with 2; Wave 3 needs 1; Wave 4 needs 2; Wave 5 needs 2; Wave 6 needs 3; Wave 7 last.

---

## WAVE 0 — Schema & docs (parallel)

### Track 0A — SQL

- [ ] **0A.1** Append v1 + v2 table DDL to [`_/schemas/site.sql`](../../_schemas/site.sql) after `site.link` section (comment: visitor analytics, CSA parity).
- [ ] **0A.2** Create [`_/schemas/migrations/site_analytics_v1.sql`](../../_schemas/migrations/site_analytics_v1.sql) with same `CREATE TABLE IF NOT EXISTS` statements.
- [ ] **0A.3** Run migration against dev YB (operator) or document in plan PR that `server_ai` migrate hook applies new migration filename if wired in migrate list.

### Track 0B — Specs

- [x] **0B.1** Add **Visitor analytics** section to [`_/specs/site.md`](../site.md): tables, ping routes, opt-out flag, retention, no raw visitor UUID in DB.
- [x] **0B.2** Extend query table in [`_/specs/site-ai.md`](../site-ai.md) with `visitor.summary`, `visitor.paths`, `link.clicks`.
- [x] **0B.3** Add one row to [`_/specs/site-guest-components.md`](../site-guest-components.md) runtime table: `c35GuestAnalytics`, ping URL, `visitor_id` reuse.

**Review gate:** DDL reviewed; `analytics` capability documented.

---

## WAVE 1 — Ingest core (`mod_site`)

### Track 1A — `site_analytics.rs`

**Files:**

- Create: `servers/crates/mod_site/src/site_analytics.rs`
- Modify: `servers/crates/mod_site/src/lib.rs` (pub use)
- Test: `servers/crates/mod_site/tests/site_analytics_test.rs`

**Interfaces:**

- `pub fn visitor_key_hash(visitor_id: &str) -> String` — blake3 hex, empty → error.
- `pub fn site_analytics_day_bucket(pool, site_iid) -> Result<NaiveDate>` — read `site.config.tz`, `chrono_tz`.
- `pub struct SiteAnalyticsPing { alien_id, session_id, path, visitor_id, referrer, active_duration_ms, user_agent }`
- `pub async fn site_analytics_ping(pool: &PgPool, req: SiteAnalyticsPing, client_ip: &str) -> Result<()>` — full rollup logic.

- [ ] **1A.1** Implement `visitor_key_hash` + path normalize (`trim`, max 256, default `/`).
- [ ] **1A.2** `site_analytics_resolve_site_iid(pool, alien_id) -> i64` + `site_analytics_published_ok(pool, site_iid)`.
- [ ] **1A.3** `site_analytics_enabled(pool, site_iid)` — read `capabilities_json->>'analytics'`; absent → true; explicit `false` → skip (return Ok without write).
- [ ] **1A.4** Transaction:
  - `INSERT INTO site.analytics_visitor_day ... ON CONFLICT DO UPDATE` increment `page_views`, add clamped duration, update `last_path`, `last_seen_ts`, `referrer_host` (parse host from referrer URL).
  - If `INSERT` (new visitor row): `UPDATE site.analytics_day SET unique_visitors = unique_visitors + 1`.
  - Always: bump `analytics_day.page_views`, `active_duration_ms`, merge `visitor_slots` JSON (recompute slot from `last_seen_ts` in site TZ for this visitor’s update).
  - v2: `INSERT INTO site.analytics_path_day ... ON CONFLICT DO UPDATE views = views + 1`.
- [ ] **1A.5** `site_analytics_link_click(pool, site_iid, link_id, visitor_id, client_ip)` — validate `link_id` belongs to `site_iid`, upsert `analytics_link_day`.

### Track 1B — Tests

- [ ] **1B.1** Test: first ping of day creates visitor row, `unique_visitors=1`, `page_views=1`.
- [ ] **1B.2** Test: second ping same `visitor_id` same day → `unique_visitors` still 1, `page_views=2`.
- [ ] **1B.3** Test: `analytics: false` → no row written.
- [ ] **1B.4** Test: path rollup increments `analytics_path_day`.
- [ ] **1B.5** Test: link click increments `analytics_link_day`.

Run: `cd servers && cargo test -p c35_mod_site site_analytics`

**Review gate:** `cargo build -p server_ai` green.

---

## WAVE 2 — HTTP (`wire_http`)

### Track 2A — Router

**Files:**

- Create: `servers/crates/wire_http/src/guest_analytics.rs`
- Modify: `servers/crates/wire_http/src/lib.rs`

- [ ] **2A.1** `POST /v1/site/guest-analytics/ping` — JSON body:

```json
{
  "alien_id": "warung-a",
  "session_id": "uuid",
  "path": "/",
  "visitor_id": "uuid",
  "referrer": "https://google.com/",
  "active_duration_ms": 12000
}
```

- [ ] **2A.2** Rate limit: in-memory map `(site_iid, ip)` max **120/min** (separate from guest-assistant 40/min).
- [ ] **2A.3** Clamp `active_duration_ms` per request to `0..1_800_000` (30 min).
- [ ] **2A.4** On success return `204 No Content`; on disabled analytics `204`; on bad site `404`; rate limit `429`.

### Track 2B — Guest host alias (optional same wave)

- [ ] **2B.1** If guest HTML is served from `server_ai` guest router, add `POST /api/analytics/ping` forwarding to same `site_analytics_ping` (CSA path). If guest is static-only on CF, document that JS must use absolute `https://api.alienai.id/v1/site/guest-analytics/ping` in `site-guest.v1.js` (preferred for c35).

**Review gate:** `curl` ping against local `server_ai` increments DB rows.

---

## WAVE 3 — Query defs

### Track 3A — `visitor.rs`

**Files:**

- Create: `servers/crates/mod_site/src/query/visitor.rs`
- Modify: `servers/crates/mod_site/src/query/mod.rs`

- [ ] **3A.1** `VisitorSummaryQuery` id `visitor.summary` — parse `range` via `c35_time_range` (same as tx queries); loop days ≤ 62; for each day read `site.analytics_day`; emit `SiteQueryRow` per site with cells: `day`, `unique_visitors`, `page_views`, `active_duration_ms`, `visitor_slots` (JSON string).
- [ ] **3A.2** `VisitorPathsQuery` id `visitor.paths` — aggregate `site.analytics_path_day` over day range, `ORDER BY views DESC LIMIT n`.
- [ ] **3A.3** `LinkClicksQuery` id `link.clicks` — join `site.analytics_link_day` to `site.link` for label/url; sum clicks across days in range or per-day rows (document: **per-day rows** with `day` + `link_id` + `title` + `clicks`).

### Track 3B — Tool metadata

- [ ] **3B.1** Update `site.query.run` tool description in `site_query.rs` (or generated catalog) to list new `query_id`s in description string.

- [ ] **3B.2** Rust test: `site_query_run` caller with grant returns summary rows.

Run: `cd servers && cargo test -p c35_mod_site visitor`

**Review gate:** MCP `tool_exec` `site.query.run` with `query_id: visitor.summary`, `owner_iid: 99000` on a site with seed pings.

---

## WAVE 4 — Guest static JS

### Track 4A — Analytics client

**Files:**

- Modify: `clients/web/static/site-guest/src/site-guest.v1.js`
- Rebuild: `site-guest.v1.js` per existing site-guest build script in repo

- [ ] **4A.1** Add `c35GuestAnalytics.start()` — read `site_iid` / `alien_id` from `window.__SITE_GUEST__` (or boot JSON already on page).
- [ ] **4A.2** Reuse `visitorId()` from guest assistant module; add `sessionId()` in `sessionStorage` key `c35.guest.session.v1.{siteIid}`.
- [ ] **4A.3** Port CSA `startAnalytics` visibility/pagehide logic; POST to `https://api.alienai.id/v1/site/guest-analytics/ping` with `alien_id` + fields.
- [ ] **4A.4** Skip start when `__SITE_GUEST__.capabilities.analytics === false`.
- [ ] **4A.5** Call `c35GuestAnalytics.start()` from existing guest init (after boot parse).

### Track 4B — Link clicks (v2)

- [ ] **4B.1** On hub link anchors with `data-link-id`, `click` handler → `POST /v1/site/guest-analytics/link-click` **or** extend ping with `event: link_click` + `link_id` (pick one handler in `guest_analytics.rs`; prefer **dedicated small route** `guest-analytics/link-click` to keep ping payload stable).
- [ ] **4B.2** Wire `site_analytics_link_click` from Track 1A.5.

**Review gate:** Published guest page in browser; network tab shows 204 ping; DB rows update.

---

## WAVE 5 — Flutter

### Track 5A — Preview ping

**Files:**

- Create: `clients/app/lib/guest_site/guest_site_analytics.dart`
- Modify: `clients/app/lib/guest_site/guest_site_view.dart` (or preview host) — call start on resume/pause

- [ ] **5A.1** Mirror JS: `GuestAnalytics.pingOnHidden(siteIid, alienId)` using `GuestAssistantApi.visitorIdForSite` + new session id in `SharedPreferences`.
- [ ] **5A.2** HTTP POST to production api host helper (same as `guest_order_api.dart`).

### Track 5B — Traffic panel (optional UI)

**Files:**

- Create: `clients/app/lib/widgets/sites/editor/ui_site_traffic_panel.dart`
- Modify: Sites editor shell — tab or Settings section

- [ ] **5B.1** Call `SiteApi` / WS `site_query_run` with `visitor.summary` last 7 days; simple chart or table.
- [ ] **5B.2** Toggle “Collect visitor analytics” bound to `site.config.put` `analytics: true/false`.

Run: `.\_\scripts\dev\verify_flutter_app.ps1`

---

## WAVE 6 — Inst & config tool

### Track 6A — `inst.sql`

- [x] **6A.1** Seed `inst.site.visitor` — phrases: `pengunjung`, `kunjungan`, `traffic`, `visitors`, `page view`, `berapa orang buka`, `pengunjung hari ini`; `tool_include:site.query.run`; `include_tools` / `selected_tools` `site.query.run`; inst body: call `visitor.summary` with `params.range`; exclude `web.search`, `web.visit`.
- [x] **6A.2** Add to `inst.web.builder` footer: traffic questions → `site.query.run`, not web search.
- [ ] **6A.3** Live `inst_put` for `inst.site.visitor` on cluster (or document seed deploy).

### Track 6B — `site.config.put`

- [ ] **6B.1** Extend tool description + parameter docs for `analytics` boolean in `site.rs` `SiteConfigPutTool`.
- [ ] **6B.2** Ensure `site_capabilities_merge` accepts `analytics` from top-level boolean arg (mirror `commerce` pattern if present).

### Track 6C — Prompt verification

- [ ] **6C.1** `prompt_compose` owner 99000: “berapa pengunjung situs ini minggu ini?” with `@site` → `inst.site.visitor` + `site.query.run` fed.
- [ ] **6C.2** `prompt_run` same phrase after seed data → hop 1 `site.query.run`, text cites numbers from tool result.

---

## WAVE 7 — Retention, docs, ship

### Track 7A — Retention

**Files:**

- Create: `servers/crates/mod_site/src/site_analytics_retention.rs` OR add to `server_ai` cron hook

- [ ] **7A.1** Function `site_analytics_retention_run(pool, retention_days)` deletes old `analytics_visitor_day`, `analytics_path_day`, `analytics_link_day` rows.
- [ ] **7A.2** Wire daily trigger via existing scheduler pattern (`mod_task` or boot interval) behind env `C35_SITE_ANALYTICS_RETENTION_ENABLED=1`.

### Track 7B — Ship

- [ ] **7B.1** `check_utf8_sources.ps1 -Changed -Fix`
- [ ] **7B.2** `cargo build -p server_ai` + `cargo test -p c35_mod_site`
- [ ] **7B.3** `publish_server.ps1` — **Publish summary** in PR/commit notes.
- [ ] **7B.4** Manual E2E checklist (below).

---

## Manual E2E checklist

1. Publish a test site; open `https://alienai.id/{alien_id}`; switch tab away → ping 204.
2. YB: `site.analytics_day` row for today with `page_views >= 1`.
3. Home: `@site` “berapa pengunjung hari ini?” → tool `visitor.summary` → sensible reply.
4. Turn off analytics in Settings → ping no longer increments counts.
5. Click hub link → `analytics_link_day.clicks` increments (v2).
6. Flutter preview background → ping fires once.

---

## Explicitly out of scope (this plan)

| Item | Reason |
|------|--------|
| `site.post_put` chat tool | Separate prompt-first plan; not required for analytics |
| `site.domain.buy` tool | Wallet UI; RPC only |
| Raw event log table | Rollup-only by design (lightweight) |
| Cross-device logged-in visitor identity | Deferred in commerce parity Wave 8 |
| Scylla port | YSQL only |

---

## Subagent dispatch cheatsheet

| Wave | Tracks | Parallel? |
|------|--------|-----------|
| 0 | 0A, 0B | Yes |
| 1 | 1A, 1B | Sequential (1B after 1A) |
| 2 | 2A, 2B | Yes |
| 3 | 3A, 3B | Sequential |
| 4 | 4A, 4B | 4B after 2 + 1 |
| 5 | 5A, 5B | Yes (5B optional) |
| 6 | 6A, 6B, 6C | 6C after 3+6A |
| 7 | 7A, 7B | Sequential |

**First dispatch when executing:** Wave **0A + 0B** in parallel, then Wave **1A**.

---

## Tool summary (add / update only)

| Name | Action |
|------|--------|
| `site.query.run` | **Update** description; register `visitor.summary`, `visitor.paths`, `link.clicks` |
| `site.config.put` | **Update** docs for `analytics` flag |
| HTTP `guest-analytics/ping` | **Add** (not an LLM tool) |
| HTTP `guest-analytics/link-click` | **Add** (v2, not LLM) |
| `inst.site.visitor` | **Add** seed row |
| `inst.web.builder` | **Update** traffic steering |

No `site.analytics.*` LLM tools.
