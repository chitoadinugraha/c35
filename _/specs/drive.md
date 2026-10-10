# Alien AI Drive (LOCKED)

Status: **locked** 2026-09-27

**Alien AI Drive** is an **owner-scoped** cloud volume (one logical drive per user), backed by c35 **CAS** (`ai.file_blob_*`) plus path metadata in **`ai.drive_file`**. Windows agents expose it as drive **A:** with volume label **Alien AI**. It is **not** the WebRTC **Files** tab on real device disks — see [`remote.md`](remote.md) (control vs data plane).

Related: [`billing.md`](billing.md) (personal plan → quota), [`sync.md`](sync.md) (`_ts` / tombstones), [`../schemas/file.sql`](../schemas/file.sql) (CAS), [`../schemas/drive.sql`](../schemas/drive.sql), [`../schemas/proto/c35/drive.proto`](../schemas/proto/c35/drive.proto). Implementation plan: [`plans/2026-09-27-alien-ai-drive-multitask.md`](plans/2026-09-27-alien-ai-drive-multitask.md).

---

## Goals

| Goal | Approach |
|------|----------|
| Same files on every paired **desktop** agent for one owner | Server tree + agent sync loop (Windows, Linux, Android cache) |
| Bulk bytes off agent WS | HTTP upload + signed `GET /fs/{hash}` pull |
| Plan-based caps | Enforce `storage_used_bytes + new_size <= storage_limit_bytes` on server |
| Simple desktop UX | Windows: **A:**; Linux: **`~/Alien AI`** FUSE; label **Alien AI** only |
| Android UX | System **Documents** / Files apps via `DocumentsProvider` |

---

## Scope (v1)

| In scope | Out of scope |
|----------|----------------|
| **Windows** agent mount (**A:**) + HTTP sync | WebRTC exposure of drive tree on **`remote-fs`** (all platforms) |
| **Linux** agent FUSE mount (`$HOME/Alien AI`) + HTTP sync — [`remote-linux.md`](remote-linux.md) | Cross-owner / team drives |
| **Android** agent cache + **DocumentsProvider** + HTTP sync — [`remote-android.md`](remote-android.md#10-alien-ai-drive) | WinFsp silent install on locked-down PCs (`subst` fallback only) |
| Owner paths under logical root | |
| Toggle default **on** when paired (`drive_enabled`) | |
| App row for used/limit (phase 2) | |

### Transport: HTTP/CAS vs NATS (locked)

| Responsibility | Transport | Notes |
|----------------|-----------|--------|
| Tree, changes, upload, delete, quota | **HTTP** device session (`X-Device-Session`) | Source of truth in `ai.drive_file` + CAS |
| File bytes (pull) | **HTTP** signed `GET /fs/{blake3}` | Not agent WebSocket |
| **Wake** paired agents to sync | **NATS** `c35.user.{owner_iid}.drive-sync` | Payload is a **nudge** (`since_ms` hint); relayed on agent WS — **no file bytes** |
| Local edit detection | **OS watcher** on agent backing dir | Windows: `ReadDirectoryChangesW`; Linux: `inotify`; Android: provider/cache hooks |

---

## Architecture

```text
Owner devices (agents with drive_enabled)
  Windows:  %USERPROFILE%\.alienai\drive_a\  +  sync_manifest.json (sibling)
  Linux:    ~/.local/share/AlienAI/drive_a/  +  sync_manifest.json (sibling)
  Android:  app cache backing tree + DocumentsProvider (no remote-fs)

        │  device session HTTP (tree / upload / delete / storage)
        │  NATS c35.user.{owner}.drive-sync  →  wake only
        ▼
c35-server  ──►  YugabyteDB ai.drive_file  +  CAS (S3 / inline)
        │
        └── signed GET /fs/{blake3}?exp=&sig=  (agent pull; not agent WS)
```

**Source of truth:** server rows in `ai.drive_file` (active paths) and blob bytes in CAS. Agents are caches; sync reconciles local tree ↔ remote tree.

Port reference (do not depend on repo): `D:\cs_bots\agents\desktop_node\src\{vfs.rs,sync.rs,vfs_winfsp*.rs}` and `D:\cs_bots\servers\alienai\src\roles\file.rs`.

---

## Local layout (Windows agent)

| Path | Role |
|------|------|
| `%USERPROFILE%\.alienai\drive_a\` | Backing cache (mounted as **A:** via WinFsp/subst) |
| `%USERPROFILE%\.alienai\sync_manifest.json` | Agent sync state (sibling of `drive_a`, **not** inside it) |
| `%USERPROFILE%\.alienai\drive_a\system\` | Legacy path — prefer sibling `system/` beside `drive_a` |

Linux layout: [`remote-linux.md`](remote-linux.md#2-xdg-layout-locked). Android: [`remote-android.md`](remote-android.md#10-alien-ai-drive).

**Config** (`%LOCALAPPDATA%\AlienAI\config.json` on Windows; `$XDG_CONFIG_HOME/AlienAI/config.json` on Linux):

| Key | Default | Behavior |
|-----|---------|----------|
| `drive_enabled` | **`true`** | On paired start: prepare layout, fetch quota, mount when true |
| `session_key` | (paired) | Device session for drive HTTP |

First save after pair should persist `drive_enabled: true` unless user turns it off.

---

## Sync manifest

`sync_manifest.json` tracks last-known remote snapshot and pending local ops (same **shape** as cs_bots desktop_node). Server does not read this file; it is agent-only.

Rules:

- Paths are **relative** to drive root, `/` separators in wire JSON, normalized on server (no `..`, no leading `/`).
- Content addressed by **blake3** hex (`hash_blake3`); pull via signed `/fs/{hash}`.
- Agent sync: **OS watcher** + **WS/NATS `c35.drive` nudge** wake; incremental `/v1/file/changes` with `remote_since_ms` in manifest; full tree heal on 404 or legacy server.

---

## Quota (locked defaults)

Limits come from the owner’s active **personal** `billing_subscription` → `billing_plan.slug`. Server computes:

| Field | Meaning |
|-------|---------|
| `storage_used_bytes` | `SUM(size_bytes)` on `ai.drive_file` where `deleted_ts IS NULL` for `owner_iid` |
| `storage_limit_bytes` | Plan ladder below |

**Initial ladder** (extend in one server constants module; document changes here):

| Plan / tier | `storage_limit_bytes` |
|-------------|------------------------|
| No active personal plan, `lite`, `plus`, `pro`, … | **1 GiB** (`1073741824`) |
| `ultra` | **15 GiB** (`16106127360`) |

Upload/delete handlers reject when `used + size > limit` (HTTP 413 or 400). Deleting a file frees usage after tombstone commit.

**Display elsewhere (allowed):** agent status window or Flutter may show `120 MB / 15 GB`. That is **not** Explorer subtitle text.

---

## Mount display UX lock (all platforms)

| Rule | Detail |
|------|--------|
| Volume / mount label | **`Alien AI`** everywhere (Windows subst/WinFsp, Linux FUSE + `.directory`, Android provider display name) |
| **Forbidden** | Mount name suffix **`· N% used`** (cs_bots `QuotaSnapshot::label()` / `update_explorer_quota_label` with percentage) |
| Allowed | Windows WinFsp / Linux file manager **Properties** may show total/free from quota — not a `%` subtitle in the mount label |

---

## Toggle & lifecycle

| Event | Behavior |
|-------|----------|
| Paired + `drive_enabled: true` | `prepare_layout` → `GET /v1/agent/storage` → mount **A:** → start sync task |
| User sets `drive_enabled: false` | Stop sync; unmount WinFsp/subst; local cache may remain |
| Agent unpair | Clear paired secrets; **unmount**; optional local wipe — see below |
| App delete device | Same as unpair push (`c35.unpair`) — mount must drop |

---

## Unpair & local data

| Policy | Default |
|--------|---------|
| Server | Tombstones / grants per [`remote.md`](remote.md) unpair; drive rows remain (owner data) |
| Agent config | Remove `session_key`; show pairing UI |
| Local `drive_a` + manifest | **Retain on disk** by default (user can delete `%USERPROFILE%\.alienai\` manually). Document in support runbooks; optional future “wipe drive cache on unpair” flag is **not** v1 |

---

## HTTP API (implementation track 1)

Auth patterns match [`remote.md`](remote.md) agent session (`X-Device-Session: {session_key}`).

| Method | Path | Auth | Body / response |
|--------|------|------|-----------------|
| GET | `/v1/agent/storage` | Device session | `ResDriveStorage` JSON keys: `storage_used_bytes`, `storage_limit_bytes` |
| GET | `/v1/file/tree` | Device session | Remote file list `{ path, hash, size }[]` (cs_bots-compatible JSON); **heal / legacy** only when incremental unavailable |
| GET | `/v1/file/changes` | Device session | Query `since_ms`, `limit` — delta rows `{ path, hash, size, updated_ts_ms, deleted }[]` + `next_since_ms`, `has_more` |
| GET | `/v1/file/sync_cursor` | Device session | `{ since_ms }` max `updated_ts` watermark for owner |
| POST | `/v1/file/upload` | Device session | Path + bytes or CAS hash after put |
| POST | `/v1/file/delete` | Device session | Path |
| GET | `/v1/drive/tree` | User session | App browser (phase 2) |
| POST | `/v1/drive/upload` | User session | App upload |
| POST | `/v1/drive/delete` | User session | App delete |

Optional: extend `GET /v1/agent/profile` with the same storage fields.

Wire messages: [`drive.proto`](../schemas/proto/c35/drive.proto). JSON field names for agent tree entries should match cs_bots `RemoteFile` (`path`, `hash`, `size`) until proto is wired on HTTP.

---

## Database

DDL: [`drive.sql`](../schemas/drive.sql).

- One active row per `(owner_iid, path)` (partial unique index where `deleted_ts IS NULL`).
- `hash_blake3` references CAS meta when blob exists.
- Soft delete via `deleted_ts`; usage sums ignore tombstones.

---

## Mentions & tools (optional track 5)

- Mention: `[@drive:relative/path]` → canonical `drive:path` in `mention_ids[]` — document in [`mention.md`](mention.md) when shipped.
- Tools: `drive.list`, `drive.read` on eligible topics.

---

## Verification (when implemented)

- Server: upload over quota fails; delete reduces `storage_used_bytes`.
- VM: **A:** label **Alien AI** without `· % used`; file round-trip via tree + second agent pull.
- Builds: `cd remotes && cargo build -p c_remote_windows`; `cd servers && cargo build -p server_ai`.
