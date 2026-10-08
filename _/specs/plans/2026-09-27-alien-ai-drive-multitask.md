# Alien AI Drive (A:) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship owner-scoped **Alien AI Drive** on Windows agents (cs_bots-style cache + sync + WinFsp/subst mount) backed by c35 **CAS + YB metadata**, with tray/UI toggle default **on**, plan-based quotas (e.g. 1 GiB free / 15 GiB paid tiers), and **no** Explorer subtitle `뿯½ N% used`.

**Architecture:** Server is source of truth for path 뿯↽ blake3 hash and `storage_used_bytes` / `storage_limit_bytes`. Agent keeps `%USERPROFILE%\.alienai\drive_a` + `sync_manifest.json` beside it; sync loop matches `D:\cs_bots\agents\desktop_node\src\sync.rs` (tree list, `/fs/{hash}` pull, upload/delete/lock). Mount matches cs_bots `vfs.rs` + `vfs_winfsp*.rs` but **static drive label "Alien AI"** only (registry + WinFsp volume label). Bulk bytes never on agent WS ([`_/specs/remote.md`](../../_/specs/remote.md)).

**Tech Stack:** Rust (`c_remote_windows`, new `c_remote_drive` or `c_remote_core::drive`), `c35_mod_file`, `mod_device` / `wire_http`, WinFsp optional feature, Flutter (phase 2 app browser).

**Reference implementation (port, do not depend on repo):** `D:\cs_bots\agents\desktop_node\src\{vfs.rs,sync.rs,vfs_winfsp.rs,vfs_winfsp_mount.rs}` and `D:\cs_bots\servers\alienai\src\roles\file.rs` (API shape).

## Global constraints

- Read [`spec.md`](../../spec.md), [`_/specs/remote.md`](../../_/specs/remote.md), [`_/specs/billing.md`](../../_/specs/billing.md), [`_/specs/mention.md`](../../_/specs/mention.md) before coding.
- **No `% used` in Explorer:** do not call `QuotaSnapshot::label()` or `update_explorer_quota_label` with a percentage. Use label **`Alien AI`** everywhere (autorun, `DriveIcons\DefaultLabel`, WinFsp `volume_label`). WinFsp may still expose **total/free bytes** from quota for Properties — that is not the `%` subtitle.
- **Default toggle on:** `config.json` key e.g. `drive_enabled: true`; unpair clears paired secrets, optional wipe of `drive_a` documented in `drive.md`.
- **Quotas:** enforce on server at upload; limits from personal `billing_plan` (seed/config table — start with **1 GiB** default tier, **15 GiB** Ultra; extend ladder in `drive.md`).
- **IDs / hashing:** blake3 for content; snowflake for row ids where needed.
- **Verify:** `cd remotes && cargo build -p c_remote_windows`; `cd servers && cargo build -p server_ai`; agent changes 뿯↽ `publish_remote_agent.ps1` when shipping to VM.
- Do not commit unless user asks.

---

## Multitask map

```text
Track 0 (drive.md + schema)     ──┬──뿯▽ Track 1 (server APIs + quota)
                                  └──뿯▽ Track 5 (mention/tools — optional wave)

Track 1 (server)                ──뿯▽ Track 2 (agent vfs + sync port)
Track 2 (agent core)            ──뿯▽ Track 3 (agent UI toggle + lifecycle)
Track 1                           ──뿯▽ Track 4 (Flutter drive quota display — optional)
Tracks 1–3                        ──뿯▽ Track 6 (tests + E2E + publish)
```

| Track | Focus | Est. | Depends |
|-------|-------|------|---------|
| **0** | Lock spec: `_/specs/drive.md`, SQL/proto sketch, `spec.md` index | 1h | — |
| **1** | `mod_drive` + HTTP: tree/upload/delete/lock, `GET /v1/agent/storage`, quota | 4h | 0 |
| **2** | Port vfs + sync + winfsp into remotes (no `%` label) | 4h | 1 |
| **3** | Agent status window toggle, config, mount on pair, unmount on off/unpair | 2h | 2 |
| **4** | App: storage used/limit on profile/settings (no new Explorer UX) | 2h | 1 |
| **5** | `[@drive:path]` + `drive.*` tools (defer if needed) | 3h | 0, 1 |
| **6** | Integration tests, manual VM checklist, publish agent | 2h | 2, 3 |

**Parallel wave 1:** Tracks **0** + **1** (schema/doc agent can draft while server starts)  
**Parallel wave 2:** Track **2** + Track **4**  
**Parallel wave 3:** Track **3**  
**Parallel wave 4:** Track **5** (optional) + Track **6**

---

## File map (target)

| Path | Responsibility |
|------|----------------|
| `_/specs/drive.md` | Locked product + wire rules |
| `_/schemas/drive.sql` | `ai.drive_file` (owner_iid, path, hash, size, deleted_ts) |
| `_/schemas/proto/c35/drive.proto` | Tree/upload/delete messages (or extend `wire.proto`) |
| `servers/crates/mod_drive/` | Quota, tree, upload, delete; uses `c35_mod_file::cas_put` |
| `servers/crates/wire_http/src/drive.rs` | Routes + agent session auth |
| `servers/crates/mod_device/src/agent_profile.rs` | Optional: include `storage_*_bytes` on profile |
| `remotes/c_remote_drive/` (or `c_remote_windows/src/drive/`) | `vfs`, `sync`, `winfsp`, `mount` |
| `remotes/c_remote_core/src/config.rs` | `drive_enabled` persist |
| `remotes/c_remote_windows/src/agent_status_window.rs` | Toggle UI |
| `clients/app/lib/...` | Phase 2: drive usage row |

---

## Track 0 — Docs & schema

### Task 0.1: `drive.md`

- [ ] Create [`_/specs/drive.md`](../../_/specs/drive.md): scope (owner volume, not device WebRTC fs), paths (`.alienai/drive_a`, `system/`, manifest), toggle behavior, quota ladder, unpair policy.
- [ ] Explicit **UX lock:** Explorer name **Alien AI** — **no** `뿯½ % used` string (differs from cs_bots `vfs_winfsp.rs` `QuotaSnapshot::label`).
- [ ] Link from [`spec.md`](../../spec.md) docs index.

### Task 0.2: Database

- [ ] Add [`_/schemas/drive.sql`](../../_/schemas/drive.sql): `ai.drive_file` unique `(owner_iid, path)` where `deleted_ts IS NULL`; index `owner_iid`.
- [ ] Document apply order in [`_/schemas/README.md`](../../_/schemas/README.md).

### Task 0.3: Proto (minimal)

- [ ] Add `drive.proto` or extend wire: `DriveFileEntry { path, hash, size }`, `ResDriveTree`, `ReqDriveUpload` (path + bytes or CAS hash after put), `ResDriveStorage { used_bytes, limit_bytes }`.
- [ ] Regenerate Dart + Rust protos per repo convention.

---

## Track 1 — Server (c35)

### Task 1.1: Crate `mod_drive`

- [ ] Create `servers/crates/mod_drive` with:
  - `drive_storage_limit_bytes(owner_iid) -> i64` from personal plan (reuse `billing_plan` join like `agent_profile.rs`).
  - `drive_storage_used_bytes(owner_iid) -> i64` = `SUM(size)` on active `ai.drive_file`.
  - `storage_limit_bytes` defaults: **1 GiB** free / no plan, **15 GiB** for `ultra` (tune in one constants module; document in `drive.md`).
- [ ] Unit tests for limit function (no DB): table-driven plan slug 뿯↽ bytes.

### Task 1.2: CAS + path index

- [ ] `drive_file_put(owner_iid, path, body)` 뿯↽ `cas_put` 뿯↽ upsert `ai.drive_file`; reject if `used + size > limit`.
- [ ] `drive_file_delete`, `drive_tree_list(owner_iid)` 뿯↽ vec of `{path, hash, size}` (match cs_bots `RemoteFile` JSON shape for agent port).
- [ ] Optional: file lock endpoints if porting cs_bots lock (for concurrent edit); else document single-writer v1.

### Task 1.3: HTTP routes

- [ ] `GET /v1/agent/storage` — `X-Device-Session`; body `{ storage_used_bytes, storage_limit_bytes }` (same keys as cs_bots agent).
- [ ] Extend `GET /v1/agent/profile` with same fields (optional convenience).
- [ ] User/session routes (for app): `GET /v1/drive/tree`, `POST /v1/drive/upload`, `POST /v1/drive/delete` — session auth `owner_iid`.
- [ ] Agent sync uses **device session** variants or shared handlers: `GET /v1/file/tree`, `POST /v1/file/upload`, `POST /v1/file/delete` — **match cs_bots paths** so `sync.rs` copies with minimal edits.
- [ ] Wire in `wire_http` + `server_ai` router.
- [ ] `cargo build -p server_ai`.

### Task 1.4: Signed download

- [ ] Confirm agent `sync` pull URL: `{origin}/fs/{hash}?exp=&sig=` via existing `mod_file` signing (not raw S3 from agent).

---

## Track 2 — Windows agent port (cs_bots)

### Task 2.1: Module layout

- [ ] Add `remotes/c_remote_drive` (preferred) depending on `c_remote_core`, `reqwest`, `blake3`, optional `winfsp` feature mirroring cs_bots `Cargo.toml` feature flags.
- [ ] Copy/adapt `vfs.rs`: `drive_a`, `system/`, `subst`, icon registry — label **only** `Alien AI` (drop dynamic label update or make it constant).
- [ ] Copy/adapt `sync.rs`: point `FILE_SERVICE_URL` / base URL at `C35_SERVER_URL`; auth header `X-Device-Session: {session_key}` instead of bearer if cs_bots used bearer (adjust `list_remote` / `upload` to match c35 handlers).

### Task 2.2: WinFsp

- [ ] Port `vfs_winfsp.rs` + `vfs_winfsp_mount.rs`: pass `used_bytes` / `limit_bytes` into volume total/free.
- [ ] **Remove** or no-op `update_explorer_quota_label` percentage behavior; if registry label is set once at mount, use static `Alien AI`.
- [ ] Feature flag `winfsp`; fallback `subst` when install fails (log warn).
- [ ] Tests: port `vfs.rs` unit tests from cs_bots.

### Task 2.3: Lifecycle

- [ ] On agent start (paired + `drive_enabled`): `prepare_layout` 뿯↽ fetch quota from `/v1/agent/storage` 뿯↽ `mount_virtual_drive`.
- [ ] Spawn `SyncEngine::run_loop` in tokio (30s interval like cs_bots).
- [ ] On `drive_enabled = false` or unpair: stop sync task, `unmount_subst` / WinFsp teardown.

### Task 2.4: Build

- [ ] `cargo build -p c_remote_windows` with default features.

---

## Track 3 — Agent UI toggle

### Task 3.1: Config

- [ ] `config.json`: `drive_enabled: bool` default `true` on first paired save.
- [ ] `config.rs` load/save + `agent_ui` snapshot field `drive_enabled` for window.

### Task 3.2: Status window

- [ ] Add switch **Alien AI Drive** in `agent_status_window.rs` (footer or info block); toggling writes config and posts message to main thread to mount/unmount.
- [ ] Show **used / limit** as human GiB in info text (optional, not Explorer) — e.g. `Drive: 120 MB / 15 GB`.

### Task 3.3: Tray

- [ ] Optional: mirror toggle in tray menu; keep slim menu per existing UX.

---

## Track 4 — Flutter (optional wave 2)

### Task 4.1: API client

- [ ] `drive_storage_get()` from session init or profile.

### Task 4.2: UI

- [ ] Billing or Devices settings: one row **Alien AI Drive** with linear progress or text `used / limit` (reuse cs_bots **quota ring** only if design wants — not required for v1).
- [ ] `flutter analyze`.

---

## Track 5 — Mentions & tools (optional)

### Task 5.1: Mention kind

- [ ] Document `[@drive:relative/path]` in `mention.md`; canonical `drive:path` in `mention_ids[]`.
- [ ] Server normalize in `mention_content.rs`; Dart wire helpers.

### Task 5.2: Tools

- [ ] `drive.list`, `drive.read` (metadata + signed URL or small file inline cap) on `general` / device topic per product choice.
- [ ] `prompt_compose` / `prompt_run` smoke with mention phrase.

---

## Track 6 — Verify & ship

### Task 6.1: Server tests

- [ ] Rust tests: upload over quota 뿯↽ 413/400; tree lists paths; delete frees usage.

### Task 6.2: Manual VM

- [ ] Pair agent 뿯↽ **A:** appears as **Alien AI** (not `% used`).
- [ ] Drop file in `A:\` 뿯↽ appears in `GET /v1/file/tree` 뿯↽ second machine pull after sync.
- [ ] Toggle off 뿯↽ `A:` gone; toggle on 뿯↽ remount.
- [ ] Unpair 뿯↽ mount removed.

### Task 6.3: Publish

- [ ] `.\_\scripts\deploy\publish_server.ps1` after server routes live.
- [ ] `.\_\scripts\deploy\publish_remote_agent.ps1` after agent port.
- [ ] Publish summary per `publish-perf-report.mdc`.

---

## Agent assignment cheat sheet

| Track | Owner focus | Key files |
|-------|-------------|-----------|
| **0** | Docs + SQL + proto | `drive.md`, `drive.sql`, `drive.proto` |
| **1** | Server | `mod_drive`, `wire_http`, `agent_profile` |
| **2** | Agent mount/sync | `c_remote_drive`, cs_bots port |
| **3** | Agent UI | `agent_status_window.rs`, `config.rs` |
| **4** | Flutter | `clients/app` API + settings row |
| **5** | Chat/tools | `mod_chat`, `mention.md`, inst seeds |
| **6** | QA + deploy | tests, publish scripts |

---

## Out of scope (v1)

- WebRTC exposure of `A:\` (separate from cloud drive; keep Remote tab on real disks).
- Cross-owner sharing / team drives.
- WinFsp silent install on locked-down corporate PCs (subst fallback only).
- Android agent drive (Windows first).

---

## cs_bots 뿯↽ c35 port checklist

| cs_bots | c35 action |
|---------|------------|
| `QuotaSnapshot::label()` `% used` | **Skip** — static **Alien AI** |
| `GET /v1/device/storage` | `GET /v1/agent/storage` |
| `GET /v1/file/tree` | Same path, device session auth |
| `sync_manifest.json` parent of `drive_a` | **Same** |
| `ai.asset` path files | `ai.drive_file` + `mod_file` CAS |
| `storage_limit_bytes(plan_tier)` | Map c35 `billing_plan.slug` |
⌊‣潃灭敬楴湯⠠〲㘲〭ⴹ㜲਩ⴊ嬠嵸匠牥敶⁲牤癩⁥偁⁉‫慠⹩牤癩彥楦敬⁠捳敨慭ⴊ嬠嵸䄠敧瑮怠彣敲潭整摟楲敶⁠潭湵⁴䄨ⰺ氠扡汥䄠楬湥䄠ⱉ渠⁯‥湩䔠灸潬敲⥲ⴊ嬠嵸䄠敧瑮唠⁉潴杧敬⬠唠敳⁲灁⁰瑳瑡獵挠牡੤‭硛⁝汆瑵整⁲敳瑴湩獧猠潴慲敧爠睯⬠搠楲敶洠湥楴湯⽳潴汯ੳ‭硛⁝畐汢獩⁨敳癲牥椠慭敧⬠爠浥瑯⁥条湥⁴㉶‵呏⽁湩瑳污敬ੲ‭硛⁝呕ⵆ‸捳湡漠⁮敲潭整⁳牤癩⁥潳牵散⁳挨敬湡਩‭⁛⁝䵖›灡汰⁹条湥⁴呏⁁㉶ⰵ挠湯楦浲䄠›湡⁤祳据⠠獵牥洠捡楨敮਩‭⁛⁝䉄›畲⁮楠獮⹴牤癩⹥楬瑳⁠敳摥⠠楠獮⹴煳恬漠⁲楠獮彴異恴愠瑦牥洠杩慲整਩