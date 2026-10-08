# Event bus + log refactor + MCP grep — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `c35_mod_event` (`def_event!`, `event_emit`, English `text` at emit, NATS `c35.user.{iid}.ev.{slug}`), migrate lifecycle `log_put` call sites, stop NATS publish for `class=trace` (LLM/tool), and upgrade MCP `log_tail` (and related tools) for fast **owner-ordered DESC** grep/debug.

**Architecture:** Canonical spec [`_/specs/event.md`](../event.md). Events: YB `ai.log` + core NATS `EventPush`. Trace: YB only. User UI copy from catalog at read time.

**Tech Stack:** Rust (`mod_event`, `mod_log`, `mod_identity`, `mod_consumption`, `wire_ws`, `mod_channel`, `mod_device`), protobuf `event.proto`, SQL migration on `ai.log`, TypeScript MCP `_/mcps/inst`, indexes per [`_/schemas/log.sql`](../../schemas/log.sql).

## Global constraints

- Read `spec.md`, [`_/specs/event.md`](../event.md), [`_/specs/log.md`](../log.md), [`.cursor/rules/event-logging.mdc`](../../.cursor/rules/event-logging.mdc) before coding.
- **0 users** — OK to break deprecated `log.{iid}.{dv}.{topic}` NATS; update admin fanout in same rollout.
- Register every new kind in catalog (`def_event!` + `event.md`) before emit.
- Verify: `cd servers && cargo build -p server_ai`; `cd _/mcps/inst && npm run build`; `cargo test -p mod_event` / `mod_admin` when added.
- Do not commit unless user asks.

---

## Multitask map

```text
Track 0 (schema + proto)     ──┬──► Track 1 (mod_event)
                              ├──► Track 8 (Log proto + admin list)
                              └──► Track 7 (MCP SQL columns)

Track 1 (mod_event)          ──┬──► Track 2 (mod_log trace NATS off)
                              ├──► Track 3 (auth + WS)
                              ├──► Track 4 (consumption)
                              └──► Track 5 (channel/device refactor)

Track 2 + 5                  ──► Track 6 (admin NATS fanout)

Tracks 1–7                   ──► Track 9 (tests + doc lock)
```

| Track | Focus | Est. | Depends |
|-------|-------|------|---------|
| **0** | `ai.log` migration + `event.proto` + indexes | 2h | — |
| **1** | `c35_mod_event` — catalog, `event_emit`, `event_spawn!`, NATS | 4h | 0 |
| **2** | `mod_log` — `class`, trace path **no NATS**; deprecate lifecycle `log_put` | 2h | 1 |
| **3** | Auth sign-in/out/fail + app WS connected/disconnected | 2h | 1 |
| **4** | Consumption `store` emits (logged/updated/deleted) | 1.5h | 1 |
| **5** | Refactor channel/device/identity lifecycle → `event_emit` | 3h | 1 |
| **6** | `admin_fanout` + root log subscribe: `c35.user.*.ev.>`, `c35.ev.>` | 1.5h | 1, 5 |
| **7** | MCP `log_tail` / `log_find` — uid, filters, grep, time DESC | 2h | 0 |
| **8** | `admin_log_list` + `Log` proto fields (`event_kind`, `class`, `subject`) | 1.5h | 0 |
| **9** | Integration tests, `mcp-security.md`, rollout checklist | 2h | all |

**Parallel wave 1:** Tracks **0** + **7** (schema + MCP can start once column names are locked)  
**Parallel wave 2:** Track **1** + **8**  
**Parallel wave 3:** Tracks **2**, **3**, **4**, **5** (four subagents)  
**Parallel wave 4:** Track **6**  
**Parallel wave 5:** Track **9**

---

## Track 0 — Schema + proto

**Files:**

- Modify: [`_/schemas/log.sql`](../../schemas/log.sql)
- Add: [`_/schemas/proto/c35/event.proto`](../../schemas/proto/c35/event.proto)
- Modify: [`_/schemas/proto/c35/log.proto`](../../schemas/proto/c35/log.proto) — add `event_kind`, `class`, `subject` on `Log`
- Modify: [`_/schemas/proto/c35/admin.proto`](../../schemas/proto/c35/admin.proto) — `ReqAdminLogList` filters
- Modify: [`servers/crates/proto/build.rs`](../../servers/crates/proto/build.rs)

**DDL (additive):**

```sql
ALTER TABLE ai.log ADD COLUMN IF NOT EXISTS event_kind VARCHAR(64) NOT NULL DEFAULT '';
ALTER TABLE ai.log ADD COLUMN IF NOT EXISTS subject TEXT NOT NULL DEFAULT '';
ALTER TABLE ai.log ADD COLUMN IF NOT EXISTS class VARCHAR(16) NOT NULL DEFAULT 'trace';

CREATE INDEX IF NOT EXISTS idx_log_owner_event_kind_created
  ON ai.log (owner_iid, event_kind, created_ts DESC, id DESC)
  WHERE deleted_ts IS NULL AND event_kind <> '';

CREATE INDEX IF NOT EXISTS idx_log_class_owner_created
  ON ai.log (owner_iid, class, created_ts DESC, id DESC)
  WHERE deleted_ts IS NULL;
```

**Class values:** `event` | `error` | `trace` (default existing rows → `trace` via migration script or `UPDATE` once).

- [ ] **0.1** Add columns + indexes; document backfill: existing rows `class=trace`, `event_kind=''`.
- [ ] **0.2** `event.proto`: `Event`, `EventPush`, `EventUserSession`, `EventConsumptionMeal`, …
- [ ] **0.3** Extend `Log` + `ReqAdminLogList` with `event_kind`, `class`, `subject` optional filters.
- [ ] **0.4** `cargo build -p server_ai` after prost regen.

---

## Track 1 — `c35_mod_event`

**Files:**

- Add: `servers/crates/mod_event/` (`Cargo.toml`, `src/lib.rs`, `src/catalog/`, `src/emit.rs`, `src/render.rs`, `src/subject.rs`, `src/bootstrap.rs`)
- Modify: `servers/Cargo.toml` workspace, `server_ai` / `mod_identity` deps as needed

**Interfaces:**

```rust
pub async fn event_emit<M: prost::Message>(pool, nats, ctx: EventCtx, kind: &str, payload: M, meta: Value) -> Result<i64>;
pub fn event_spawn!(st, ctx, kind, payload [, meta]); // tokio::spawn → event_emit
```

- [ ] **1.1** `def_event!` + `inventory` registry; `registry_event_by_kind`.
- [ ] **1.2** `subject_fill(scope, slug, ctx)` → `c35.user.{owner_iid}.ev.{slug}` etc.
- [ ] **1.3** `render_en(meta, ctx, payload)` → `ai.log.text` from `txt.en` only.
- [ ] **1.4** INSERT `ai.log` with `event_kind`, `subject`, `class`, `topic=slug`, `kind=conn|system`, `cost_usd=0`.
- [ ] **1.5** NATS publish `EventPush` on exact `subject` (core NATS).
- [ ] **1.6** Bootstrap catalog: auth (5 kinds), consumption (3), channel/device stubs per [event.md](../event.md).
- [ ] **1.7** Unit tests: subject fill, English render, meta redaction (`sess_id` not `session_token`).

---

## Track 2 — `mod_log` trace path

**Files:**

- Modify: [`servers/crates/mod_log/src/lib.rs`](../../servers/crates/mod_log/src/lib.rs)

- [ ] **2.1** `LogPut` gains optional `class` (default `trace` for billing/chat tracer callers).
- [ ] **2.2** If `class == trace` → INSERT only, **skip NATS** (breaking change for admin live LLM tail — acceptable; use MCP/SQL).
- [ ] **2.3** If `class == event|error` → warn + delegate to `mod_event` (or remove path — lifecycle must not use `log_put`).
- [ ] **2.4** Update `turn_tracer`, `billing_turn`, `mod_voice` billing — explicit `class: trace`.
- [ ] **2.5** Document: legacy `log.>` fanout no longer receives LLM rows.

---

## Track 3 — Auth + app WS

**Files:**

- Modify: [`servers/crates/mod_identity/src/auth_password.rs`](../../servers/crates/mod_identity/src/auth_password.rs)
- Modify: [`servers/crates/mod_identity/src/auth_oauth.rs`](../../servers/crates/mod_identity/src/auth_oauth.rs)
- Modify: [`servers/crates/wire_ws/src/session.rs`](../../servers/crates/wire_ws/src/session.rs)

- [ ] **3.1** `sign_in` / signup auto-login / OAuth success → `event_spawn` `user.sign_in` (`sess_id` from `auth_session.id`).
- [ ] **3.2** `sign_out` → `user.sign_out`.
- [ ] **3.3** Failed password sign-in → `user.sign_in_failed` (no uid leak in meta; optional `method`).
- [ ] **3.4** WS: after `caller_iid` ok → `user.connected` (`conn_id` = admin_session_id or new snowflake); on loop exit → `user.disconnected`.
- [ ] **3.5** Pass `locale` from WS query into `EventCtx` for future client render (emit still English `text`).

---

## Track 4 — Consumption

**Files:**

- Modify: [`servers/crates/mod_consumption/src/store.rs`](../../servers/crates/mod_consumption/src/store.rs)
- Modify: [`servers/crates/mod_consumption/Cargo.toml`](../../servers/crates/mod_consumption/Cargo.toml) — dep `mod_event`

- [ ] **4.1** `food_put` (new meal) → `consumption.meal_logged`, `meta.source` param (`rpc` | `tool` | `app`).
- [ ] **4.2** `food_update` → `consumption.meal_updated`.
- [ ] **4.3** `food_delete` → `consumption.meal_deleted`.
- [ ] **4.4** Thread optional `nats` + `EventCtx` into store from RPC/tools (minimal: helper `consumption_event_ctx(owner, locale, name, req_id)`).
- [ ] **4.5** Tool path in [`mod_chat/.../consumption.rs`](../../servers/crates/mod_chat/src/tools/builtin/consumption.rs) passes `source: tool` + `req_id` from `ToolContext`.

---

## Track 5 — Refactor legacy lifecycle `log_put`

Replace `log_put` + old subject with `event_emit` (keep trace callers on `log_put`).

| File | Today | Target kinds |
|------|-------|----------------|
| `mod_channel/whatsapp/connect.rs` | `log_put` connected/error | `channel.connected`, errors as `class=error` |
| `mod_channel/whatsapp/pair.rs` | pair lifecycle | `channel.*` slugs per [server.md](../server.md) catalog |
| `mod_channel/telegram/connect.rs` | same | same |
| `mod_channel/disconnect.rs` | disconnected | `channel.disconnected` |
| `mod_channel/inbound.rs` | msg_received | **defer** or `channel.msg_received` (add def_event if in scope) |
| `mod_device/agent_log_put.rs` | agent ws | `device.agent_connected` / `device.agent_disconnected` |
| `mod_device/device_unpair.rs` | unpair | new kind `device.unpaired` (register in catalog) |
| `mod_identity/identity_put.rs` | bot create | `system` event or skip if not user-visible |
| `channel_whatsapp_device/db.rs` | worker logs | map to `channel.*` under `c35.ev.channel.*` |
| `wire_http/agent.rs` | agent POST log | route through `agent_log_put` → events |

- [ ] **5.1** Add missing `def_event!` rows (pair, error, msg_*) to catalog + `event.md`.
- [ ] **5.2** Migrate files in table; delete duplicate NATS on `log.*` for those rows.
- [ ] **5.3** Slim `agent_log_put` to wrapper over `event_emit` with device scope.

**Out of scope (stay trace):** `turn_tracer`, `billing_turn`, `mod_voice` billing.

---

## Track 6 — Admin / root live tail

**Files:**

- Modify: [`servers/crates/wire_ws/src/admin_fanout.rs`](../../servers/crates/wire_ws/src/admin_fanout.rs)

- [ ] **6.1** Subscribe `c35.user.*.ev.>` and `c35.ev.>` instead of (or in addition during transition) `log.>`.
- [ ] **6.2** Decode `EventPush` → existing `WsRes.log_push` or new `WsRes.event_push` (proto choice in 0.3).
- [ ] **6.3** Remove `log.>` subscription once Track 5 complete.
- [ ] **6.4** Flutter `admin_log_stream.dart` — handle new payload if wire changes (optional same sprint).

---

## Track 7 — MCP log grep (debug ergonomics)

**Files:**

- Modify: [`_/mcps/inst/src/log.ts`](../../_/mcps/inst/src/log.ts)
- Modify: [`_/mcps/README.md`](../../_/mcps/README.md), [`_/specs/mcp-security.md`](../mcp-security.md)
- Modify: [`.cursor/rules/agent-debug.mdc`](../../.cursor/rules/agent-debug.mdc) tool table (if new tool name)

**Goals:** One obvious tool to **grep** `ai.log` by **owner iid**, **time DESC**, optional text/kind/event filters; align with new columns.

### `log_tail` (enhance)

- [ ] **7.1** Accept **`uid`** as alias for **`owner_iid`** (document both).
- [ ] **7.2** Filters: `event_kind`, `class`, `subject` (exact or `subject_prefix`), `since_ms`, `until_ms` (keep `since_minutes`).
- [ ] **7.3** `q` searches: `text`, `topic`, `event_kind`, `subject`, `req_id`, `meta::text` (YB JSON cast).
- [ ] **7.4** `ORDER BY created_ts DESC, id DESC` (already); document index used: `idx_log_owner_created_desc` / `idx_log_owner_event_kind_created`.
- [ ] **7.5** Compact line format: include `event_kind` when set: `2026-… [event/user.sign_in] …`.
- [ ] **7.6** `exclude_trace: true` default **false**; when **true**, `class IN ('event','error')` for “domain events only”.

### `log_find` (new, optional thin wrapper)

- [ ] **7.7** Add `log_find` — same backend as `log_tail` but defaults: `limit=100`, `exclude_trace=true`, description “grep domain events for owner”. Re-export shared query builder from `log.ts`.

### HTTP agent parity (if used)

- [ ] **7.8** If `/v1/mcp/agent` exposes log tools server-side later, mirror filters; **not required** if MCP uses direct SQL (current `inst` `pool`).

- [ ] **7.9** `npm run build` in `_/mcps/inst`; sync `.cursor/mcp.json` if tool descriptions change (no new server key).

---

## Track 8 — Admin invoke API

**Files:**

- Modify: [`servers/crates/mod_admin/src/log_admin.rs`](../../servers/crates/mod_admin/src/log_admin.rs)

- [ ] **8.1** `ReqAdminLogList`: `event_kind`, `class`, `subject_prefix`, `exclude_trace`.
- [ ] **8.2** `ORDER BY created_ts DESC, id DESC` (switch from `id DESC` only for stable time order).
- [ ] **8.3** Map new columns in `row_to_log`.

---

## Track 9 — Verify + docs

- [ ] **9.1** Manual: sign-in → SQL `event_kind='user.sign_in'`; NATS subject `c35.user.{iid}.ev.sign-in`; MCP `log_tail { uid: 99000, event_kind: "user.sign_in" }`.
- [ ] **9.2** Meal log → `consumption.meal_logged`; `log_tail { q: "kcal", class: "event" }`.
- [ ] **9.3** Prompt turn → rows with `class=trace`, **no** NATS message on `c35.user.*.ev.*`.
- [ ] **9.4** Update [`_/specs/event.md`](../event.md) implementation status table.
- [ ] **9.5** Update [`_/specs/sync.md`](../sync.md) admin tail section (EventPush not `log.>`).

---

## MCP examples (target UX)

```json
// Recent domain events for Chito
{ "tool": "log_tail", "arguments": { "uid": 99000, "exclude_trace": true, "limit": 30 } }

// Grep sign-in + connected
{ "tool": "log_tail", "arguments": { "uid": 99000, "q": "sign", "class": "event" } }

// Exact kind
{ "tool": "log_tail", "arguments": { "uid": 99000, "event_kind": "consumption.meal_logged" } }

// Global ops tail (root DB creds)
{ "tool": "log_tail", "arguments": { "global": true, "since_minutes": 60, "event_kind": "user.sign_in" } }
```

---

## Risk / notes

| Risk | Mitigation |
|------|------------|
| Admin UI expected LLM on live NATS | Document; use MCP `log_tail` with `class=trace` |
| `meta` redaction hides `session*` keys | Use `sess_id` in events ([event.md](../event.md)) |
| Channel `msg_received` volume | Keep as trace or separate high-volume stream — decide in 5.1 |
| Proto + Flutter regen | Run protoc / app codegen in Track 0/6 if wire changes |

---

## Subagent dispatch checklist (parent)

When executing, launch **wave 1** tasks with `Task` description = track id + link to this file. Model **`inherit`**. After each track: `cargo build -p server_ai` per `verify-after-edit.mdc`.
