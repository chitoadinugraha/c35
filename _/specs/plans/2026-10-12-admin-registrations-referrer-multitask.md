# Admin registrations list + referral stats referrer — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline. Model: **`inherit`** only (`subagent-model.mdc`).
>
> **Specs (read first):** [`spec.md`](../../../spec.md) · [`_/specs/referral.md`](../../../_/specs/referral.md) · [`_/specs/identity.md`](../../../_/specs/identity.md) · [`_/specs/inst.md`](../../../_/specs/inst.md) · [`prompt-run-test.mdc`](../../../.cursor/rules/prompt-run-test.mdc)

**Goal:** Let **partner** and **director** ask in Home chat about platform signups (count + list with referrer) and about a specific user’s wallet / referrer / signup time, via **`admin.user.registrations.list`**, extended **`referral.user.stats`** (referrer + registration time), and **`ai.inst`** staff rows.

**Architecture:**

- **`c35_mod_admin`**: new RPC `admin_user_registrations_list` — SQL on `ai.identity` (`kind=user`, `created_ts` range), join referrer row on `referred_by_iid`; staff gate = `require_referral_staff` (root, director, partner).
- **`c35_mod_referral`**: extend `referral_user_stats` / `ResReferralUserStats` with **subject’s upline** (`referred_by`) and **`registered_ts_ms`** for single-user staff/self queries.
- **`mod_chat`**: register tool `admin.user.registrations.list`; extend `referral.user.stats` JSON (`subject_handle`, `referred_by`, `registered_ts_ms`); reuse `subject_iid_resolve` + `owner_tz` / `chat_local_range` for date windows.
- **`inst.sql`**: `inst.staff.registrations` + `inst.staff.user_lookup` (saldo / kapan daftar / siapa refer).

**Tech stack:** Protobuf `admin.proto` / `referral.proto` / `wire.proto` (= **146**), Rust `c35_mod_admin`, `c35_mod_referral`, `c35_mod_chat`, `inst.sql`, MCP `prompt_compose` / `prompt_run`.

## Global constraints

- Normative doc updates: **`_/specs/referral.md`** (Admin RPC table) before claiming done; optional one paragraph in **`identity.md`** if signup listing is documented there.
- Inst steering in **`inst.sql`**; production needs **`inst_put`** after deploy.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_admin` / `c35_mod_referral` when tests added; `.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed` if touching LLM paths; `prompt_compose` on Indonesian + English staff phrases.
- Do not commit unless user asks.
- **Privacy (inst + tool description):** JSON includes `identity_id` for disambiguation; model replies use **name + @handle** only; show numeric uid **only when the operator asks for uid/id**.

## Explicitly out of scope (v1)

| Item | Notes |
|------|--------|
| `admin.user.get` | Deferred; `referral.user.stats` + `admin.user.search` cover single-user v1 |
| Subtree filter (`subtree_of_uid`) | Optional v1.1; v1 only `referred_by_uid` (direct signups under one referrer) |
| Flutter staff UI | Prompt-first only |
| Partner-only downline signup list | v1 list = **platform-wide** (same wide-forest trust as `referral.md`) |

---

## API lock (Wave 0)

### Proto — `admin.proto`

```protobuf
message AdminUserReferrerBrief {
  int64 identity_id = 1;
  string name = 2;
  string alien_id = 3;  // bare handle, no @
}

message AdminUserRegistrationRow {
  int64 identity_id = 1;
  string name = 2;
  string handle = 3;    // @alien_id
  string email = 4;     // same rules as AdminUserHit
  int64 registered_ts_ms = 5;
  AdminUserReferrerBrief referred_by = 6;  // absent when no referrer
}

message ReqAdminUserRegistrationsList {
  // Window: use preset OR since/until (dates), not both required empty.
  string preset = 1;   // today | yesterday | this_week | last_week | this_month | last_month
  string since = 2;    // YYYY-MM-DD inclusive (viewer TZ)
  string until = 3;    // YYYY-MM-DD inclusive (viewer TZ)
  bool count_only = 4;
  int32 limit = 5;     // default 50, max 100 when listing
  int64 after_registered_ts_ms = 6;  // keyset cursor: rows strictly older than this ts (tie-break id in SQL)
  int64 after_identity_id = 7;
  int64 referred_by_uid = 8;  // 0 = all platform signups in window
  string timezone = 9;  // optional override; default viewer ai.identity.tz
}

message ResAdminUserRegistrationsList {
  int64 count = 1;
  repeated AdminUserRegistrationRow users = 2;
  string timezone_used = 3;
  int64 window_start_ms = 4;
  int64 window_end_ms = 5;  // exclusive end
  bool has_more = 6;
}
```

### Proto — `referral.proto` (extend)

```protobuf
message ReferralUserReferrerBrief {
  int64 identity_id = 1;
  string name = 2;
  string alien_id = 3;
}

message ResReferralUserStats {
  // ... existing fields 1-5 ...
  ReferralUserReferrerBrief referred_by = 6;  // subject's upline; empty if none
  int64 registered_ts_ms = 7;                 // subject created_ts
}
```

Optional (recommended v1): `ReqReferralUserStats.subject_handle` **string** field 4 — staff tool resolves handle without search hop.

### Wire

- `InvokeReq` / `InvokeRes` oneof: `admin_user_registrations_list = **146**` (after `admin_disk_clean = 145`).

### Preset semantics (viewer TZ)

| preset | Window `[start, end)` |
|--------|------------------------|
| `today` | Local midnight today → tomorrow 00:00 |
| `yesterday` | Yesterday 00:00 → today 00:00 |
| `this_week` | Monday 00:00 (ISO week) → next Monday 00:00 |
| `last_week` | Previous Monday → this Monday |
| `this_month` | 1st 00:00 → 1st next month |
| `last_month` | 1st previous month → 1st this month |

Implement in `mod_admin` (or shared helper extracted from `chat_history` preset logic — **new** `admin_registration_window.rs` in `mod_admin`).

---

## Tool + inst catalog (v1)

### Tool: `admin.user.registrations.list`

| Param | Maps to RPC |
|-------|-------------|
| `preset` | `preset` |
| `since`, `until` | `since`, `until` |
| `count_only` | `count_only` |
| `limit` | `limit` |
| `after_registered_ts_ms`, `after_identity_id` | cursor |
| `referred_by_uid` | optional filter |
| `timezone` | optional |

- `requires_global_roles: ["partner", "director"]`
- `topics: ["staff", "referral"]`, `always: ["general", "staff"]`, `readonly: true`
- `rag_phrases`: ID/EN signup list phrases (daftar user, user mendaftar, registrasi, signups today, …)

### Tool: `referral.user.stats` (extend, no rename)

- Add params: `subject_handle` (optional; with existing `subject_uid`)
- JSON: `referred_by`, `registered_ts_ms`, mirror in `llm` block for account tool parity
- Update **description** only (not inst body): upline + registration time included

### Inst rows

| inst id | `requires_global_roles` | `include_tools` |
|---------|-------------------------|-----------------|
| `inst.staff.registrations` | partner, director | `admin.user.registrations.list` |
| `inst.staff.user_lookup` | partner, director | `admin.user.search`, `referral.user.stats` |

**`inst.staff.registrations` body (steering):**

- Platform signup **count** → `admin.user.registrations.list` with `count_only: true`.
- **List** who signed up → same tool, `count_only: false`, `limit` 50 unless they ask for more; mention each user’s **referrer name/handle** from `referred_by`; omit uid unless asked.
- Map Indonesian: hari ini → `preset=today`, minggu lalu → `last_week`, bulan ini → `this_month`, rentang tanggal → `since`/`until`.
- Do **not** use `referral.tree.get` for signup reports.

**`inst.staff.user_lookup` body:**

- Resolve ambiguous name → `admin.user.search`, then `referral.user.stats` with `subject_uid` or `subject_handle`.
- **Saldo / komisi / wallet** → stats tool; quote currency from `wallet`.
- **Siapa yang refer X** → `referred_by` in stats; if null, say no referrer on file.
- **Kapan X daftar** → `registered_ts_ms` / formatted time in viewer TZ.
- Do not show numeric uid in prose unless operator asks.

---

## Wave map

```text
W0 Spec + proto (sequential gate)
W1 Parallel:  A = mod_admin RPC + tests
              B = mod_referral stats referrer + tests
W2 Wire invoke + mod_chat tools + compose_test (sequential)
W3 inst.sql + prompt_compose / prompt_run + spec referral.md (sequential)
```

---

## Task 0: Spec + protobuf (gate)

**Files:**

- Modify: `_/schemas/proto/c35/admin.proto`
- Modify: `_/schemas/proto/c35/referral.proto`
- Modify: `_/schemas/proto/c35/wire.proto` (146)
- Modify: `_/specs/referral.md` — Admin RPC: `admin_user_registrations_list`; note `referral_user_stats` referrer fields

**Steps:**

- [ ] Add messages above; run proto codegen for Rust (`servers/crates/proto` per repo script).
- [ ] `cargo build -p c35_proto` (or full `server_ai`) to confirm generated types.

**Produces:** `ReqAdminUserRegistrationsList`, `ResAdminUserRegistrationsList`, extended `ResReferralUserStats`.

---

## Task 1A: `admin_user_registrations_list` (`c35_mod_admin`)

**Files:**

- Create: `servers/crates/mod_admin/src/registrations_list.rs`
- Modify: `servers/crates/mod_admin/src/lib.rs` — export `admin_user_registrations_list`
- Create: `servers/crates/mod_admin/tests/registrations_list_test.rs`

**Interfaces:**

- Consumes: `require_referral_staff`, `ReqAdminUserRegistrationsList`
- Produces: `pub async fn admin_user_registrations_list(pool, viewer_iid, req) -> Result<ResAdminUserRegistrationsList, AdminError>`

**SQL sketch:**

```sql
SELECT i.id, i.name, i.alien_id, i.created_ts, i.referred_by_iid,
       r.name AS ref_name, r.alien_id AS ref_alien_id,
       -- email subquery same as admin_user_search
FROM ai.identity i
LEFT JOIN ai.identity r ON r.id = i.referred_by_iid AND r.deleted_ts IS NULL
WHERE i.kind = 'user' AND i.deleted_ts IS NULL
  AND i.created_ts >= $start AND i.created_ts < $end
  AND ($referred_by = 0 OR i.referred_by_iid = $referred_by)
ORDER BY i.created_ts DESC, i.id DESC
LIMIT $limit
```

- Count-only: `SELECT COUNT(*)` with same filters.
- Keyset: `AND (i.created_ts, i.id) < ($cursor_ts, $cursor_id)` when cursor set.

**Tests:**

- [ ] Partner viewer allowed; normal user 403.
- [ ] Window preset `today` with fixed clock or injected TZ (use UTC test identities + bound dates).
- [ ] Row includes referrer when `referred_by_iid` set.
- [ ] `count_only` matches row insert count in fixture.

**Verify:** `cd servers && cargo test -p c35_mod_admin`

---

## Task 1B: Referrer + registration on `referral_user_stats` (`c35_mod_referral`)

**Files:**

- Modify: `servers/crates/mod_referral/src/stats.rs`
- Create or extend: `servers/crates/mod_referral/tests/stats_referrer_test.rs` (or inline in existing test crate)

**Logic:**

- After resolving `subject`, load `created_ts` → `registered_ts_ms`.
- If `referred_by_iid > 0`, load referrer `id, name, alien_id` → `ReferralUserReferrerBrief`.
- Populate for all viewers who pass `stats_can_view` (same as wallet).

**Tests:**

- [ ] Subject with referrer → `referred_by` populated.
- [ ] Subject without referrer → field absent / empty.
- [ ] `registered_ts_ms` matches identity `created_ts`.

**Verify:** `cargo test -p c35_mod_referral`

---

## Task 2: Wire + chat tools

**Files:**

- Modify: `servers/crates/wire_http/src/invoke.rs` — route `AdminUserRegistrationsList`
- Modify: `servers/crates/mod_chat/src/tools/builtin/staff.rs`
- Modify: `servers/crates/mod_chat/src/tools/builtin/account.rs` — pass through `referred_by` + `registered_ts_ms` in `account.referral.stats` JSON
- Modify: `servers/crates/mod_chat/tests/compose_test.rs` — staff role + phrase → tool fed (optional dedicated test file)

**`admin.user.registrations.list` executor:**

- `require_staff_json` → `admin_user_registrations_list`
- Default `timezone` from `owner_tz` pattern (copy query from `chat_history` or pass `ctx.locale` / `ctx.user_text` into admin helper)

**`referral_user_stats_exec`:**

- Resolve `subject_handle` via `subject_iid_resolve` when `subject_uid` is 0.
- Map proto `referred_by` + `registered_ts_ms` to JSON; add `llm` summary keys for model.

**Compose test (minimal):**

- [ ] Viewer meta `global_roles: ["partner"]` + phrase `berapa user mendaftar hari ini` → `admin.user.registrations.list` in catalog when inst seeded (may mock inst list in test harness).

**Verify:** `cargo build -p server_ai`; `cargo test -p mod_chat` (crate name `c35_mod_chat` if that's the package name - check Cargo.toml)

---

## Task 3: Inst seeds + prompt verification

**Files:**

- Modify: `_/schemas/inst.sql` — `inst.staff.registrations`, `inst.staff.user_lookup`

**Steps:**

- [ ] Insert rows with `requires_global_roles`, `include_tools`, `exclude_tools`, priority ~136 (near other staff rows).
- [ ] Live: `inst_put` both rows on cluster (document in PR notes).

**MCP (`owner_iid` 33000 seed staff — if no partner role on 33000, use compose with inst_block or test with 99000 partner account):**

| Phrase | Expect |
|--------|--------|
| `berapa user yang mendaftar hari ini` | `admin.user.registrations.list` fed |
| `siapa yang mendaftar minggu lalu` | same |
| `berapa saldo chito` | `referral.user.stats` or search then stats |
| `siapa yang me refer budi` | `referral.user.stats` after search |
| `kapan alice daftar` | `referral.user.stats` |

- [ ] `prompt_compose` each phrase; confirm `inst_ids` + `selected_tools`.
- [ ] `prompt_run` one registration count + one user lookup (33000 or staff-capable fixture).

---

## Review gates

| Gate | Owner | Pass criteria |
|------|-------|----------------|
| RB1-W0 | Chito | Proto field numbers + preset table OK |
| RB2-W1 | Reviewer | Tests green; partner gate enforced |
| RB3-W3 | Chito | `prompt_compose` traces match inst |

---

## Publish

Server-only change: **`publish_server.ps1`** after merge/deploy (no remote agent). End with **Publish summary** from `.cache/publish-perf/latest.json` when publishing.

---

## File touch summary

| Path | Action |
|------|--------|
| `_/schemas/proto/c35/admin.proto` | Add registration messages |
| `_/schemas/proto/c35/referral.proto` | Extend stats response |
| `_/schemas/proto/c35/wire.proto` | Invoke 146 |
| `_/specs/referral.md` | Document RPC + tools |
| `servers/crates/mod_admin/src/registrations_list.rs` | New |
| `servers/crates/mod_admin/tests/registrations_list_test.rs` | New |
| `servers/crates/mod_referral/src/stats.rs` | Referrer + registered_ts |
| `servers/crates/wire_http/src/invoke.rs` | Handler |
| `servers/crates/mod_chat/src/tools/builtin/staff.rs` | Tools |
| `servers/crates/mod_chat/src/tools/builtin/account.rs` | JSON parity |
| `_/schemas/inst.sql` | Two inst rows |
