# CAS `blob_ref` + `storage.usage` — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline. Model: **`inherit`** only (`subagent-model.mdc`).
>
> **Specs (read first):** [`spec.md`](../../../spec.md) · [`_/specs/file.md`](../../../_/specs/file.md) · [`_/specs/inst.md`](../../../_/specs/inst.md) · [`_/specs/chat.md`](../../../_/specs/chat.md) · [`prompt-run-test.mdc`](../../../.cursor/rules/prompt-run-test.mdc)

**Goal:** Attribute every kept CAS hash to a **scope** (user personal, site, bot, mailbox), index for fast rollups, extend orphan GC, expose one **`storage.usage`** tool (self + site + bot + staff), and wire **`ai.inst`** rows for prompt-first queries (“how much storage do I use?”, “site A”, “bot Rasa”, “how much does chito use?”).

**Architecture:**

- New table **`ai.blob_ref`**: `(billable_owner_iid, scope_kind, scope_iid, hash_blake3, source, source_key)` with indexes for user rollup and GC.
- **`c35_mod_file`**: `blob_ref_upsert` / `blob_ref_delete_source` / hash extraction helpers; **`storage_usage_query`** (SQL aggregates); variant refs on `file_variant_set`.
- **Writers** call upsert at **entity save** (not only `cas_put` — dedupe hash may skip put).
- **`cas_kept`** CTEs add `SELECT hash_blake3 FROM ai.blob_ref` (variants still via ref rows or existing expansion during backfill).
- **One tool** `storage.usage` in `mod_chat` with in-executor auth (site grant, bot owner, staff roles); four inst rows.

**Tech stack:** YSQL (`_/schemas/file.sql`), Rust `c35_mod_file` + `c35_mod_chat`, `inst.sql`, PowerShell backfill `_/scripts/dev/backfill_blob_ref.ps1`, MCP `prompt_compose` / `prompt_run`.

## Global constraints

- Update **`_/specs/file.md`** (normative) before claiming done; no provider web grounding.
- Inst steering in **`inst.sql`**; live cluster needs **`inst_put`** after deploy.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` after edits.
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_file` / `c35_mod_chat` when tests added; `.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed` if touching LLM paths.
- Do not commit unless user asks.
- **Metrics:** `total_bytes` = **DISTINCT** hashes per `billable_owner_iid`; breakdown lines = **SUM per scope** (may over-sum shared files).

## Explicitly out of scope (v1)

| Item | Notes |
|------|--------|
| `ai.blob_usage_daily` rollup / triggers | Add only if director dashboards need it |
| User-facing Flutter storage page | Prompt-first only |
| Partner cross-user storage | Default **director + root** only for `subject_*` ≠ caller (configurable in tool) |
| Guest site grant sees storage | **manage/staff** on site only, not `guest` |
| Billing charge from storage bytes | Reporting only v1 |
| `include_platform` cluster totals | Optional v1.1 flag, **root** only |

---

## Data model (lock in Wave 0)

### `ai.blob_ref`

```sql
CREATE TABLE IF NOT EXISTS ai.blob_ref (
    id                  BIGSERIAL PRIMARY KEY,
    billable_owner_iid  BIGINT NOT NULL REFERENCES ai.identity(id),
    scope_kind          VARCHAR(16) NOT NULL,  -- user | site | bot | mailbox
    scope_iid           BIGINT NOT NULL,
    hash_blake3         VARCHAR(64) NOT NULL REFERENCES ai.file_blob_meta(hash_blake3) ON DELETE CASCADE,
    source              VARCHAR(64) NOT NULL,
    source_key          VARCHAR(256) NOT NULL,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_blob_ref_scope_kind CHECK (
        scope_kind IN ('user', 'site', 'bot', 'mailbox')
    ),
    CONSTRAINT uq_blob_ref_source_key UNIQUE (scope_kind, scope_iid, source_key)
);

CREATE INDEX IF NOT EXISTS idx_blob_ref_owner_scope
    ON ai.blob_ref (billable_owner_iid, scope_kind, scope_iid);
CREATE INDEX IF NOT EXISTS idx_blob_ref_hash
    ON ai.blob_ref (hash_blake3);
CREATE INDEX IF NOT EXISTS idx_blob_ref_scope
    ON ai.blob_ref (scope_kind, scope_iid);
```

**`source_key` examples:** `chat_msg:123`, `drive:path:/foo`, `site.product:99:42:pic`, `mail.msg:555:att:0`, `identity.pic:99000`, `variant:thumb:canonical_hash`.

**Billable owner resolution:**

| scope_kind | scope_iid | billable_owner_iid |
|------------|-----------|---------------------|
| `user` | user iid | same user |
| `site` | site identity id | `site.config.owner_iid` or `identity.owner_iid` |
| `bot` | bot identity id | `identity.owner_iid` |
| `mailbox` | `mail.mailbox.id` | `mailbox.owner_iid` (site mailbox → still user owner) |

**Chat attachment scope:**

- `chat.kind = prompt` → `scope_kind=user`, `scope_iid=owner_iid`.
- `chat.kind = bot_peer` → `scope_kind=bot`, `scope_iid=chat.bot_iid`.

---

## Tool + inst catalog (v1)

### Tool: `storage.usage`

| Param | Type | Notes |
|-------|------|--------|
| `scope` | string | `account` (default) \| `site` \| `bot` \| `mailbox` |
| `subject_uid` | int | 0 = caller; staff may set another user |
| `subject_handle` | string | `alien_id` |
| `site_iid` / `site_handle` | | For `scope=site` |
| `bot_iid` / `bot_handle` | | For `scope=bot` |
| `mailbox_id` / `mailbox_address` | | For `scope=mailbox` |
| `include_breakdown` | bool | default true for `account` |

**Auth:**

- Account self: always.
- Account other user: `require_referral_staff` **or** `director`/`root` (pick one policy in Wave 5 — recommend **director + root** only, not partner).
- Site: reuse `mod_site::site_grant` / `site_resolve` pattern — owner or grant role in `staff|manage` (not guest).
- Bot: `identity.owner_iid == caller` or staff.
- Mailbox: `mail_access` for that mailbox (same as `mod_mail` tools).

**Topics:** `general`, `account`, `staff`, `site` · **readonly** · no `requires_global_roles` on macro.

### Inst rows

| inst id | roles | include_tools |
|---------|-------|----------------|
| `inst.account.storage` | — | `storage.usage` |
| `inst.site.storage` | — | `storage.usage` |
| `inst.bot.storage` | — | `storage.usage` |
| `inst.staff.storage` | director, root | `storage.usage`, `admin.user.search` |

---

## Multitask map

```
WAVE 0 — Spec lock (parallel, docs)
  S0  file.md: blob_ref + storage.usage + GC
  S1  inst wording draft (paste into inst.sql in Wave 6)

WAVE 1 — Schema (blocking)
  B1  file.sql + migrate apply note in file.md

WAVE 2 — mod_file core (after B1)
  F1  blob_ref.rs: upsert/delete/extract_hashes_from_json
  F2  storage_usage.rs: query by scope + labels
  F3  file_variant_set + optimize/doc_cache: variant refs
  F4  cas_gc.sql + cas_gc_fast_build.sql: blob_ref in kept
  F5  unit tests (mod_file)

WAVE 3 — Backfill (after F1, can overlap F4)
  K1  backfill_blob_ref.ps1 (idempotent upsert from cas_kept sources)
  K2  Dry-run counts vs storage_usage for 99000 / 33000

WAVE 4 — Writers (parallel after F1)
  W4a chat: prompt_turn / channel + bot_peer scope
  W4b site: product/object/post/draft/publish/member_face sync paths
  W4c drive: drive_file_put/delete
  W4d mail: inbound/outbound message insert
  W4e identity: pic update
  W4f tool_artifact: insert (TTL scope user or bot from ctx if available)

WAVE 5 — Tool + auth (after F2, can start before W4 complete if queries work on backfill only)
  T1  mod_chat builtin storage.rs + register mod.rs
  T2  mod_chat Cargo.toml → ensure mod_file exports public API
  T3  integration test storage_usage_auth (pool skip ok)

WAVE 6 — Inst + RAG (parallel with T1)
  I1  inst.sql four rows
  I2  rag_phrases on ToolDefinition

WAVE 7 — Verification
  V1  cargo test mod_file + mod_chat
  V2  MCP prompt_compose: EN/ID phrases (33000 self; 99000 staff if roles seeded)
  V3  prompt_run staff phrase with subject_handle chito (after backfill on env)
  V4  check_utf8 + cargo build -p server_ai
```

### Suggested agent assignments

| Wave | Agent | Track | Deliverable |
|------|-------|-------|-------------|
| 0 | A | S0 | `file.md` |
| 0 | B | S1 | Inst text in plan → `inst.sql` |
| 1 | C | B1 | `file.sql` |
| 2 | D | F1–F5 | `mod_file` |
| 3 | E | K1–K2 | backfill script + smoke |
| 4 | F | W4a | chat refs |
| 4 | G | W4b | site refs |
| 4 | H | W4c–W4f | drive/mail/identity/artifact |
| 5 | I | T1–T3 | `storage.rs` |
| 6 | J | I1–I2 | `inst.sql` |
| 7 | K | V1–V4 | evidence |

**Dependency graph:** `B1 → F1 → (W4*, K1) → V*`; `F2 → T1`; `K1` before trusting `prompt_run` on prod-like data.

---

## Wave 0 — Docs

### Task S0 — `file.md`

**Files:** [`_/specs/file.md`](../../../_/specs/file.md)

**Add sections:**

- `ai.blob_ref` table, indexes, scope kinds, billable_owner_iid rules.
- Write path: entity save + variant_set; not refcount on meta.
- GC: `blob_ref` participates in `cas_kept`.
- `storage.usage` tool summary + total vs attributed breakdown.
- Backfill script path.

**Acceptance:** No contradiction with locked CAS tiers; references table updated.

### Task S1 — Inst steering draft

**Paste into `inst.sql` in Wave 6:**

**`inst.account.storage`**

- Phrases: `how much storage do I use`, `my file storage`, `berapa storage saya`, `penggunaan penyimpanan`.
- Body: call `storage.usage` with default `scope=account`; report `total_bytes` then breakdown from JSON.

**`inst.site.storage`**

- Phrases: `storage for this site`, `how big is my shop`, `penyimpanan site`.
- Body: `scope=site`; use `ctx.site_iid` when user means “this site”.

**`inst.bot.storage`**

- Phrases: `bot storage`, `berapa storage bot`, bot name in phrase.
- Body: `scope=bot`; resolve `bot_handle` from message or mentions.

**`inst.staff.storage`**

- Phrases: `how much storage does`, `storage usage user`, `berapa storage chito`.
- Body: resolve via `admin.user.search` if needed; `storage.usage` with `subject_*`; explain `scopes_attributed_sum_bytes` vs `total_bytes`.

---

## Wave 1 — Schema

### Task B1 — `file.sql`

**Files:**

- Create/Modify: [`_/schemas/file.sql`](../../../_/schemas/file.sql)

**Steps:**

- Add `ai.blob_ref` DDL (above).
- Document apply order: after `file_blob_meta` exists.

**Acceptance:** `migrate_db.ps1` or manual YSQL apply succeeds on dev YB.

---

## Wave 2 — `mod_file` core

### Task F1 — `blob_ref` module

**Files:**

- Create: `servers/crates/mod_file/src/blob_ref.rs`
- Modify: `servers/crates/mod_file/src/lib.rs` (exports)

**Interfaces (produce):**

```rust
pub struct BlobRefScope {
    pub scope_kind: &'static str, // user|site|bot|mailbox
    pub scope_iid: i64,
    pub billable_owner_iid: i64,
}

pub async fn blob_ref_upsert(
    pool: &PgPool,
    scope: &BlobRefScope,
    hash: &str,
    source: &str,
    source_key: &str,
) -> Result<(), sqlx::Error>;

pub async fn blob_ref_delete_source_key(
    pool: &PgPool,
    scope_kind: &str,
    scope_iid: i64,
    source_key: &str,
) -> Result<(), sqlx::Error>;

pub fn cas_hashes_from_text(s: &str) -> Vec<String>; // /fs/{hash} + 64-hex
pub fn cas_hashes_from_json_value(v: &Value) -> Vec<String>;
```

**Steps:**

- Normalize hash to lowercase; skip invalid.
- Upsert: `ON CONFLICT (scope_kind, scope_iid, source_key) DO UPDATE SET hash_blake3 = EXCLUDED.hash_blake3`.
- Optional: delete stale keys when entity replaces pic (delete old source_key then upsert new).

### Task F2 — `storage_usage` queries

**Files:**

- Create: `servers/crates/mod_file/src/storage_usage.rs`

**Interfaces:**

```rust
pub struct StorageUsageReport { /* total_bytes, scopes_attributed_sum_bytes, personal, sites[], bots[], mailboxes[] */ }

pub async fn storage_usage_account(
    pool: &PgPool,
    billable_owner_iid: i64,
    include_breakdown: bool,
) -> Result<StorageUsageReport, sqlx::Error>;

pub async fn storage_usage_scope(
    pool: &PgPool,
    scope_kind: &str,
    scope_iid: i64,
) -> Result<ScopeUsage, sqlx::Error>;
```

**SQL sketch:**

- Distinct total: subquery `SELECT DISTINCT hash_blake3 FROM ai.blob_ref WHERE billable_owner_iid = $1` join meta.
- Breakdown: `GROUP BY scope_kind, scope_iid` with SUM(size_bytes) — **not** distinct per group (attributed).
- Labels: join `ai.identity` for site/bot; `mail.mailbox` for mailbox.

### Task F3 — Variant refs

**Files:**

- Modify: `servers/crates/mod_file/src/lib.rs` (`file_variant_set`)
- Modify: `servers/crates/mod_file/src/optimize.rs`, `doc_cache.rs`

**Behavior:**

- After setting variant hash, if caller passes `BlobRefScope` (extend API) **or** copy scope from existing ref on canonical hash (`SELECT scope_* FROM ai.blob_ref WHERE hash_blake3 = canonical LIMIT 1` fallback):
  - Upsert `source_key = variant:{key}:{canonical}`, `source = variant.{key}`.

**v1 shortcut:** On variant set, duplicate all `(scope_kind, scope_iid, billable_owner_iid)` rows from canonical hash to variant hash with new source_key.

### Task F4 — GC SQL

**Files:**

- Modify: [`_/schemas/cas_gc.sql`](../../../_/schemas/cas_gc.sql), [`_/schemas/cas_gc_fast_build.sql`](../../../_/schemas/cas_gc_fast_build.sql)

**Add to `kept` union:**

```sql
SELECT lower(hash_blake3) FROM ai.blob_ref
```

**Acceptance:** Dry-run `cleanup_cas_orphans.ps1` does not mark kept blobs as orphans.

### Task F5 — Tests

**Files:**

- Create: `servers/crates/mod_file/tests/blob_ref_test.rs` (or inline `#[sqlx::test]` if harness exists)

**Cases:**

- Upsert idempotent; scope replace updates hash on same source_key.
- `storage_usage_account` distinct total with two scopes sharing one hash.

---

## Wave 3 — Backfill

### Task K1 — `backfill_blob_ref.ps1`

**Files:**

- Create: [`_/scripts/dev/backfill_blob_ref.ps1`](../../../_/scripts/dev/backfill_blob_ref.ps1)

**Behavior:**

- For each source in `cas_gc_fast_build` / documented surfaces, INSERT … ON CONFLICT DO NOTHING (or upsert).
- Resolve `billable_owner_iid` + scope from row (chat join for bot_peer, site.config, etc.).
- Flags: `-DryRun`, `-Limit`, `-OwnerIid` filter.
- Log: rows inserted/updated per source type.

### Task K2 — Smoke

- Run backfill on dev/staging.
- Compare `storage_usage` for `owner_iid=99000` to ad-hoc audit from conversation (~order of magnitude).

---

## Wave 4 — Writers (parallel)

Each track: on **create/update**, upsert refs for all hashes found; on **delete/clear field**, delete by `source_key` prefix or exact key.

### Task W4a — Chat

**Files:**

- Modify: `servers/crates/mod_chat/src/prompt_turn.rs` (user msg persist)
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs` if attachments
- Helper: `blob_ref_chat_msg(pool, chat_id, msg_id, owner_iid, attachments, content, blocks_json)`

**Scope resolver:** load `ai.chat.kind`, `bot_iid` for thread.

### Task W4b — Site

**Files:**

- Modify: `servers/crates/mod_site/src/...` and/or `mod_chat/src/tools/builtin/site.rs` RPC paths that persist `pic`, `product_json`, `doc_json`, etc.

**Prefer:** central helper in `mod_site` called from sync/write paths so POS/app sync also refs.

**source_key:** stable ids (`site.product:{site_iid}:{product_id}:pic`).

### Task W4c — Drive

**Files:**

- Modify: `servers/crates/mod_drive/src/store.rs` (`drive_file_put`, delete)

**Scope:** `user`, `scope_iid=owner_iid`, `source_key=drive:{id}` or path-based key.

### Task W4d — Mail

**Files:**

- Modify: `servers/crates/mod_mail/src/service.rs` (inbound insert, outbound after CAS attach)

**Scope:** `mailbox`, load mailbox owner for billable.

### Task W4e — Identity pic

**Files:**

- Modify: identity profile update path in `mod_identity` (where `pic` is set)

**Scope:** `user`, `source_key=identity.pic:{iid}`.

### Task W4f — Tool artifact

**Files:**

- Modify: artifact insert crate (grep `tool_artifact`)

**Scope:** `user` + `owner_iid`; optional `bot` if `bot_iid` in context later.

**Acceptance (Wave 4):** New upload in each surface creates `blob_ref` row visible in SQL within same request.

---

## Wave 5 — Tool

### Task T1 — `storage.rs`

**Files:**

- Create: `servers/crates/mod_chat/src/tools/builtin/storage.rs`
- Modify: `servers/crates/mod_chat/src/tools/builtin/mod.rs`, `tools/mod.rs`

**Execute flow:**

1. Parse args; default `scope=account`, subject = caller.
2. Resolve handles → iids (site_resolve, identity by alien_id).
3. Auth checks (per catalog).
4. Call `storage_usage_*` from `c35_mod_file`.
5. Return JSON `{ ok, tool: "storage.usage", ... }`.

### Task T2 — Dependencies

- `c35_mod_chat/Cargo.toml` already depends on `c35_mod_file` — verify; add `mod_mail` / `mod_site` only if auth helpers need them.

### Task T3 — Test

- Mock or DB test: caller cannot read another user's account without staff role.

---

## Wave 6 — Inst

### Task I1 — `inst.sql`

**Files:** [`_/schemas/inst.sql`](../../../_/schemas/inst.sql) — four INSERTs from S1.

**Priority:** account ~135, site/bot ~134, staff ~136 (near other staff rows).

### Task I2 — Tool metadata

- `description` + `rag_phrases` EN/ID on `storage.usage` tool macro.

---

## Wave 7 — Verification

### Task V1 — Rust tests

```powershell
cd servers
cargo test -p c35_mod_file
cargo test -p c35_mod_chat -- storage
```

### Task V2 — prompt_compose (33000)

| Phrase | Expect |
|--------|--------|
| `how much storage do I use` | `inst.account.storage`, `storage.usage` fed |
| `berapa storage saya` | same |
| `storage for this site` | `inst.site.storage` |

### Task V3 — prompt_run (staff, 99000 on env with roles)

- `how much storage does chito use` → hop `storage.usage`, JSON breakdown.

### Task V4 — Build + UTF-8

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
cd servers; cargo build -p server_ai
```

---

## Rollout checklist (human)

1. Apply `file.sql` on YB.
2. Deploy server with `mod_file` + tool (writers optional but refs empty until backfill).
3. Run `backfill_blob_ref.ps1` (execute, not dry-run).
4. `inst_put` or full inst rollout for four new rows.
5. Re-run CAS GC only after refs stable (should not delete kept).

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Missed writer → orphan GC deletes blob | Backfill + GC includes blob_ref; add reconcile job v1.1 |
| Chat regex missed hash in blocks | Use shared `cas_hashes_from_json_value` on full msg row |
| Site sync bypasses mod_chat tools | Wire `mod_site` store layer |
| Double-count confusion in UI | Tool returns both `total_bytes` and `scopes_attributed_sum_bytes` |
| Large backfill on prod | Batched inserts; `-Limit` loops |

---

## Definition of done

- [ ] `ai.blob_ref` live; GC uses it.
- [ ] Backfill run; Chito/staff query returns sensible breakdown.
- [ ] New uploads in chat/site/drive/mail create refs.
- [ ] `storage.usage` works for account / site / bot / mailbox + staff subject.
- [ ] Four inst rows seeded; `prompt_compose` picks correct inst on sample phrases.
- [ ] `file.md` updated; verify commands green.
