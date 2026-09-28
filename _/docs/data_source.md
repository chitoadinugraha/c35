# Bot data sources — synced external knowledge (LOCKED)

**Status:** LOCKED 2026-09-27

Canonical spec for **cached, indexed** bot knowledge (Google Sheets v1; extensible to Slides, CSV, files). Bots and channel agents read from **YugabyteDB**, not the remote API on every turn.

**Reference implementation:** `D:\cs_bots\servers\alienai\src\integrations\asset_chunk.rs` + `google_sheet.rs` (ported to c35 identity model).

**Plans:**

| Phase | Doc |
|-------|-----|
| **All waves (review gates)** | [`plans/2026-09-27-data-source-all-waves-multitask.md`](plans/2026-09-27-data-source-all-waves-multitask.md) |
| v1 (lazy sync, RPC, tools, Flutter) | [`plans/2026-09-27-data-source-google-sheet-multitask.md`](plans/2026-09-27-data-source-google-sheet-multitask.md) |
| v2 (background refresh on `server_ai`) | [`plans/2026-09-27-data-source-bg-sync-phase2-multitask.md`](plans/2026-09-27-data-source-bg-sync-phase2-multitask.md) |

**Related:** [`identity.md`](identity.md) (bots = `ai.identity`), [`sync.md`](sync.md) (`_ts` convention), [`channels.md`](channels.md) (bot turns), [`chat.md`](chat.md) (JetStream prompt / worker mode), [`fetcher.md`](fetcher.md) (cluster singleton — **not** used for bot sheets), [`embed.sql`](../schemas/embed.sql) (`ai.embed_cache`).

---

## Goals

| Goal | Approach |
|------|----------|
| Fast bot replies | Prompt context from `ai.data_source_chunk` (+ FTS / embed retrieval) |
| Fresh data | **Lazy sync** on channel turn + optional **`server_ai` background refresh** (sharded across replicas) |
| Generic adapters | `source_kind` + `config` JSON; shared sync/chunk tables |
| c35 identity model | **No** cs_bots `ai.asset` tree — bindings are `ai.data_source` rows owned by user, linked to `bot_iid` |

---

## What we do *not* port from cs_bots

| cs_bots | c35 |
|---------|-----|
| `ai.asset` + `ai.asset_integration` | `ai.data_source` |
| `ai.asset_grant` | `owner_iid` on binding row (+ optional `bot_iid` column) |
| Bot id = asset id | Bot id = `identity.iid` where `kind=bot` |

Flutter `meta.assets: ["google_sheets"]` string tags are **deprecated** — replace with persisted `data_source` rows (see v1 plan).

---

## Schema overview

DDL: [`_/schemas/data_source.sql`](../schemas/data_source.sql).

```
ai.data_source          — binding (what to fetch, for which bot)
ai.data_source_sync     — 1:1 sync metadata (hash, row_count, status)
ai.data_source_chunk    — searchable chunks (FTS GIN + embed cache keys)
ai.embed_cache          — existing; document embeddings for retrieval
```

### `ai.data_source` (binding)

| Column | Notes |
|--------|-------|
| `id` | Snowflake PK |
| `owner_iid` | User who connected the source |
| `bot_iid` | Primary bot (`identity`, `kind=bot`); NULL = unattached draft |
| `source_kind` | `google_sheet` \| `google_slide` (future) \| `file_csv` (future) |
| `name` | Display name (tab title, user label) |
| `config` | Adapter JSON (see below) |
| `created_ts`, `updated_ts`, `deleted_ts` | Sync watermark on binding row |

**`config` for `google_sheet`:**

```json
{
  "spreadsheet_id": "1ab…",
  "gid": "0",
  "sheet_name": "Sheet1",
  "view_url": "https://docs.google.com/spreadsheets/d/…/edit#gid=0",
  "access_mode": "read_write"
}
```

`access_mode`: `read_write` (default) enables `gsheet.append` / `gsheet.update` for that binding; `read_only` keeps sync + prompt read path only. Docs/Slides bindings are always stored as `read_only`.

Server may parse `view_url` on `data_source_put` to fill `spreadsheet_id` / `gid` when omitted.

### `ai.data_source_sync`

| Column | Notes |
|--------|-------|
| `data_source_id` | PK, FK → `data_source` |
| `snapshot_hash` | Blake3 hex of normalized remote payload (full CSV for sheets) |
| `row_count` | Data rows (excludes header chunk) |
| `status` | `ok` \| `error` \| `stale` (optional `syncing` during bg claim — phase 2) |
| `error_msg` | Last fetch/chunk failure |
| `synced_ts` | Last successful remote read (or touch) |

### `ai.data_source_chunk`

| Column | Notes |
|--------|-------|
| `chunk_key` | Stable within source, e.g. `header`, `row:42`, `slide:3` |
| `content` | Plain text for FTS + prompt |
| `content_hash` | Blake3 of normalized content (embed cache material) |
| `meta` | JSON, e.g. `{"row": 42, "tab": "Sheet1"}` |
| `tsv` | Generated `english` tsvector |

**Replace strategy:** full delete + insert for `data_source_id` when snapshot hash changes (same as cs_bots).

---

## Sync pipeline

### Triggers

| Trigger | When | Where |
|---------|------|-------|
| **Lazy (primary)** | Start of `channel_prompt_turn` (and optional bot test turn) | `server_ai` → `data_source_sync_if_stale` per binding |
| **On write** | After `gsheet.append` / `gsheet.update` | `data_source_sync_invalidate` → next turn or bg refresh |
| **Manual** | `data_source_sync` RPC / MCP | Same `data_source_sync_run` |
| **Background (phase 2)** | Periodic due-row sweep | **`server_ai` only** — sharded; see below |

### `data_source_sync_run` (per binding)

```mermaid
sequenceDiagram
  participant Turn as channel_prompt_turn / bg worker
  participant Sync as data_source_sync_run
  participant Remote as Google CSV export
  participant YB as YugabyteDB
  participant Emb as embed_cache

  Turn->>Sync: data_source_id
  Sync->>YB: read data_source + sync row
  alt hash unchanged within TTL
    Sync-->>Turn: touch synced_ts only
  else stale or hash changed
    Sync->>Remote: GET export?format=csv
    Sync->>YB: DELETE chunks; INSERT chunks
    Sync->>Emb: embed_text for chunks >= min chars
    Sync->>YB: UPSERT data_source_sync ok + hash
  end
```

**Stale rule (`data_source_sync_if_stale`):**

- No sync row or `status != 'ok'` or empty `snapshot_hash` → stale
- `now - synced_ts > DATA_SOURCE_SYNC_TTL_SEC` (default **120**) → stale

**Unchanged remote:** if new Blake3 matches `snapshot_hash`, only bump `synced_ts` (no chunk rewrite, no embed churn).

### Google Sheet fetch (v1 adapter)

- **Read:** `https://docs.google.com/spreadsheets/d/{spreadsheet_id}/export?format=csv&gid={gid}`
- **Auth:** optional service account (`GOOGLE_SERVICE_ACCOUNT_PATH` or `FIREBASE_SERVICE_ACCOUNT_PATH`) when sheet is not public
- **Write (tools):** Sheets API v4 with same service account; sheet shared with the link Editor (cs_bots behavior)

### Chunking (`google_sheet`)

1. Parse CSV (quoted fields)
2. Chunk `header`: column names
3. One chunk per data row: `row:{line}` with `col1: v1 | col2: v2 | …`
4. `row_count` = data rows only

Future `google_slide`: one chunk per slide text (`slide:{n}`).

---

## Background sync — architecture (phase 2)

**Not `c35-fetcher`.** Fetcher is a **singleton** for cluster-wide config (FX, LLM catalog, vendor bills). Bot sheet sync is **per-owner / per-bot**, uses the same `data_source_sync_run` as lazy sync, and must run on **`server_ai`** so it shares YB, egress, Google credentials, and `ai.embed_cache` with channel turns.

```text
                    ┌─────────────────────────────────────┐
                    │  c35-fetcher (replicas: 1)          │
                    │  FX, LLM catalog, vendor bills      │
                    │  NATS c35.fetch.*                   │
                    └─────────────────────────────────────┘
                                      ✗ bot sheets

┌──────────────────┐   lazy on turn    ┌──────────────────────────────┐
│ Telegram / WA /  │ ────────────────► │ server_ai (replicas: N)        │
│ Home bot chat    │                   │ mod_data_source::sync_run      │
└──────────────────┘                   │ + bg_spawn (phase 2, sharded) │
                                       └──────────────────────────────┘
                                                    │
                                                    ▼
                                            ai.data_source_*
```

### Per-pod scheduler (phase 2 — ship first)

| Concern | Decision |
|---------|----------|
| **Process** | `server_ai` only — `data_source_bg_spawn(pool, http)` from `main.rs` next to `embed_cache_evict_spawn` |
| **Enable** | `DATA_SOURCE_BG_ENABLED` (default `1` when unset in prod manifests) |
| **Tick** | `DATA_SOURCE_BG_TICK_SEC` (default **30**) — interval between due scans |
| **Batch** | `DATA_SOURCE_BG_BATCH` (default **8**) — max rows claimed per tick per pod |
| **Concurrency** | `DATA_SOURCE_BG_MAX_CONCURRENT` (default **2**) — in-flight `sync_run` per pod (tokio semaphore) |
| **TTL** | Reuse `DATA_SOURCE_SYNC_TTL_SEC` (default **120**) for due selection |
| **Sharding** | `SELECT … FOR UPDATE OF d SKIP LOCKED` on due `ai.data_source` rows so **N replicas** split work without duplicate Google pulls |
| **In-flight** | Short `status = 'syncing'` (or lease column) while claim held; clear on success/error |
| **Errors** | `sync_upsert_error`; exponential backoff via `synced_ts` bump + `error` status (do not hot-loop failed sheets) |
| **Pool** | Respect DB pool — bg concurrency must stay below `prompt_run` + WS load (see `structure.md`) |

**Due query (conceptual):**

```sql
SELECT d.id
FROM ai.data_source d
JOIN ai.data_source_sync s ON s.data_source_id = d.id
WHERE d.deleted_ts IS NULL
  AND s.status IN ('ok', 'error', 'stale')
  AND s.synced_ts < NOW() - make_interval(secs => $ttl_sec)
ORDER BY s.synced_ts ASC
LIMIT $batch
FOR UPDATE OF d SKIP LOCKED;
```

Optional **priority** (phase 2 stretch): join recent `ai.chat_msg` / channel traffic for `bot_iid` to refresh active bots first.

### Worker mode (later — phase 3+)

Align with prompt JetStream in [`chat.md`](chat.md):

| Piece | Role |
|-------|------|
| Stream | e.g. `C35_DATA_SOURCE_SYNC` / subject `c35.data_source.sync` |
| Payload | `{ data_source_id, owner_iid, reason: "bg" \| "invalidate" }` |
| Consumer | `server_ai` pods in queue group `c35-data-source-sync` |
| Handler | Same `data_source_sync_run` — no second sync implementation |

Enqueue on: invalidate, put with new URL, or scheduler pod publishing due ids (hybrid). **Do not** add a fetcher task or `mod_fetch` registration.

---

## Prompt injection (read path)

Called from `channel_prompt_turn` after `inst_base`, before memory:

1. `data_source_sync_if_stale` per binding (lazy)
2. If `row_count <= DATA_SOURCE_SMALL_ROW_LIMIT` (default **50**): `chunks_full_text` into `## Sheet data ({name})`
3. Else: `data_source_chunk_retrieve` — FTS + embed rank, top **8** chunks, **4s** timeout

**Rule:** Normal auto-reply turns must **not** call Google per row; tools `gsheet.read` may force sync for debugging.

---

## Tools (LLM)

Register in `mod_chat` with `topics: ["bot"]` (and channel topics as needed):

| Tool | Behavior |
|------|----------|
| `gsheet.read` | CSV text for attached sheet; optional `spreadsheet_id` when multiple |
| `gsheet.append` | Append row → **invalidate** sync |
| `gsheet.update` | Range update → **invalidate** sync |

Resolve `bot_iid` from `ai.chat` on channel turns.

---

## Wire / RPC (client)

Proto: `_/schemas/proto/c35/data_source.proto` (WS fields 161–164).

| RPC | Request | Response |
|-----|---------|----------|
| `data_source_list` | `bot_iid` optional, `since` for delta | list of `DataSourceDoc` + sync summary |
| `data_source_put` | doc / id | id |
| `data_source_delete` | id | ok |
| `data_source_sync` | id | sync row status |

Access: `owner_iid` must match caller; bot must be owned by caller or granted admin.

v1: list via RPC when opening bot settings. Phase 2+: optional `SessionInit` delta slice.

---

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `DATA_SOURCE_SYNC_TTL_SEC` | `120` | Lazy + bg freshness threshold |
| `DATA_SOURCE_SMALL_ROW_LIMIT` | `50` | Full inject vs retrieve |
| `DATA_SOURCE_RETRIEVE_LIMIT` | `8` | Max chunks in prompt |
| `DATA_SOURCE_RETRIEVE_TIMEOUT_SEC` | `4` | Retrieve budget |
| `GOOGLE_SERVICE_ACCOUNT_PATH` | — | Sheets read/write + private export |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | — | Alias accepted for same JSON |
| `DATA_SOURCE_BG_ENABLED` | `1` | Phase 2 background loop |
| `DATA_SOURCE_BG_TICK_SEC` | `30` | Scheduler interval |
| `DATA_SOURCE_BG_BATCH` | `8` | Claims per tick per pod |
| `DATA_SOURCE_BG_MAX_CONCURRENT` | `2` | Parallel syncs per pod |

---

## Events (optional v1.1)

When `mod_event` catalog gains kinds:

- `data_source.synced` after hash-changing success
- `data_source.sync_failed` on `status=error`

Not required for phase 2 scheduler.

---

## cs_bots mapping

| cs_bots | c35 |
|---------|-----|
| `asset_sync_run` | `data_source_sync_run` |
| `asset_chunk_prompt_for_binding` | `data_source_prompt_for_bot` |
| `asset_chunk_retrieve` | `data_source_chunk_retrieve` |
| `bindings_for_bot` | `data_source_list_for_bot` |
| `SOURCE_KIND_GOOGLE_SHEET` | `google_sheet` |

---

## Verification

- Unit: `cargo test -p c35_mod_data_source` (CSV, chunk keys, snapshot hash)
- Build: `cd servers && cargo build -p server_ai`
- Manual: bot + public sheet URL → turn sees data without `gsheet.read` in trace
- Phase 2: two `server_ai` replicas, one sheet due — only one pod logs sync; both see updated `synced_ts`
- App: `cd clients/app && flutter analyze` on bot data-source UI
