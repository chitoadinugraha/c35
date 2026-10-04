# Drive sync — efficient long-term plan (watcher + deltas + events)

**Status:** draft plan (2026-10-05)  
**Goal:** Replace periodic full-tree polling with **event-driven + incremental** sync while keeping `drive_a` a correct cache of `ai.drive_file` + CAS.

**Related:** [`drive.md`](../drive.md), [`sync.md`](../sync.md), [`event.md`](../event.md), [`remote.md`](../remote.md), agent `c_remote_drive/src/sync.rs`.

---

## Problem (today)

| Step | Cost |
|------|------|
| Timer (30-120s) | Wakes sync even when nothing changed |
| `GET /v1/file/tree` | Full owner tree every cycle (grows with library size) |
| Local walk | `read_dir` entire `drive_a` |
| Push path | `read` + blake3 every file when manifest metadata miss |

**Already in agent (next publish):** one tree fetch per cycle, manifest `{hash,size,mtime_ms}`, adaptive sleep. Still **O(n)** remote list on every wake.

---

## Target architecture

```text
                    +-------------------------------------+
                    |  Server (source of truth)           |
                    |  ai.drive_file + CAS                |
                    |  emit events on put/delete          |
                    +--------------+----------------------+
                                   |
         GET /v1/file/changes?since |  NATS c35.user.{iid}.ev.drive-*
         (incremental, tombstones)|  optional hint on agent WS
                                   |
                    +--------------v----------------------+
                    |  Windows agent (c_remote_drive)     |
                    |  OS watcher -> debounced wake       |
                    |  sync_manifest: watermark + paths     |
                    |  pull/push only touched paths       |
                    +--------------+----------------------+
                                   |
                    drive_a (backing) --> WinFsp A:
```

**Principles**

1. **Server-authoritative** — same as [`sync.md`](../sync.md): `updated_ts` watermark, tombstones in delta.
2. **Bytes off agent WS** — pulls stay HTTP `/fs/{hash}`; WS/NATS only **hints** (something changed).
3. **Heal path** — full `GET /v1/file/tree` for first pair, manifest reset, or gap detection.

---

## Phase 1 — OS watcher (agent-only)

**Why:** Most edits are **local** (Explorer on A:\). Watcher makes sync **change-driven**.

| Item | Detail |
|------|--------|
| API | `ReadDirectoryChangesW` on `%USERPROFILE%\.alienai\drive_a` |
| Filter | Skip `VfsDriveManager::is_internal_path` |
| Debounce | 300-800 ms; coalesce bursts |
| Wake | `tokio::sync::Notify`; **max** heartbeat 15-30 min when idle (remote-only edits, sleep) |
| Local fast path | `pending_local: HashSet<RelPath>` from watcher; push scans only those paths |
| Remote pull | Full tree per wake until Phase 2 |

**Files:** `c_remote_drive/src/watch_windows.rs`, `runtime.rs`, `sync.rs`.

---

## Phase 2 — Incremental tree API (server + agent)

**Schema** — add per [`sync.md`](../sync.md):

```sql
CREATE INDEX IF NOT EXISTS idx_drive_file_sync
  ON ai.drive_file (owner_iid, updated_ts);
```

**HTTP** (device session):

| Method | Path | Query | Response |
|--------|------|-------|----------|
| GET | `/v1/file/changes` | `since_ms`, `limit` (default 500) | `{ entries, next_since_ms, has_more }` |

**Entry:** `path`, `hash`, `size`, `updated_ts_ms`, `deleted` (tombstone).

**Query:** rows where `owner_iid = $1` AND `updated_ts > since`, **include tombstones**, ORDER BY `updated_ts`, LIMIT.

**Agent manifest:** add `remote_since_ms`; paginate changes; advance watermark.

**Heal:** missing/invalid watermark -> `GET /v1/file/tree` once, rebuild manifest.

**Server:** `mod_drive::drive_changes_list`, `wire_http` route, tests.

---

## Phase 3 — Server events

**Catalog** ([`event.md`](../event.md)):

| event_kind | slug | When |
|------------|------|------|
| `drive.file_updated` | `drive-file-updated` | after `drive_file_put` |
| `drive.file_deleted` | `drive-file-deleted` | after `drive_file_delete` |

**Meta:** `path`, `hash_blake3`, `size_bytes`, `source`: app | tool | agent | rpc.

**NATS:** `c35.user.{owner_iid}.ev.drive-file-updated` (and deleted).

**Emit:** `mod_drive::store` only.

**Agent v1 delivery:** frame on **existing agent WS**: `{ "t": "drive_hint", "since_ms": ... }` -> `notify_wake()` -> incremental pull.

Flutter / app browser can use same delta HTTP or WS `since` later.

---

## Phase 4 — Polish

- Rate limits, metrics on sync cycle
- Deprecate full tree except heal; update `drive.md`
- Android: same HTTP delta when drive ships

---

## Multitask map

| Track | Work | Depends |
|-------|------|---------|
| **A** | Phase 1 watcher | — |
| **B** | Phase 2 index + API + agent watermark | A (server parallel) |
| **C** | Phase 3 events + `event_emit` | B |
| **D** | Agent WS `drive_hint` fanout | C |
| **E** | Docs, tests, publish | A-D |

**Wave 1:** A + B server  
**Wave 2:** C + D  
**Wave 3:** E

---

## Test plan

| Case | Expect |
|------|--------|
| Save on A:\ | Watcher -> push; peer gets hint -> pull one file |
| App deletes file | Tombstone in changes -> local removed |
| Missed hint | Heartbeat incremental/heal catches up |
| 10k files idle | No full tree; small change pages only |

---

## Out of scope

- Lock conflict UI
- Cross-owner drives
- Second NATS client on agent (WS hint first)