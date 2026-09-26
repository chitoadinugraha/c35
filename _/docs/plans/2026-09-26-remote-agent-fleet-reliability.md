# Remote Windows Agent — Fleet Reliability, Security & OTA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make unattended remote Windows installs safe to roll out at scale: always talk to prod cluster for control + OTA, clear pairing errors, enforced release floors, verified live download path, and documented session (non-JWT) lifecycle so operators do not confuse deploy tokens with agent auth.

**Architecture:** Keep the existing split: **control plane** (`https://alienai.id` — pair, WS, logs) and **OTA plane** (`/version/remote-windows` + signed `/fs/{hash}`). Harden publish scripts and smoke gates in Dart/PowerShell; small, testable Rust changes only where reliability gaps remain (download retry, clearer pair errors). Do not add JWT rotation on the agent — `session_key` is opaque and long-lived until unpair; document that explicitly.

**Tech Stack:** Rust (`c_remote_core`, `c_remote_windows`), Dart deploy scripts, PowerShell smoke/E2E, YB `ai.config`, NATS `c35.release.remote-windows`, Blake3 CAS.

## Global Constraints

- Read [`spec.md`](../../spec.md), [`_/docs/remote.md`](../../_/docs/remote.md), [`_/docs/auto-update.md`](../../_/docs/auto-update.md), [`_/docs/app-release.md`](../../_/docs/app-release.md) before behavior changes.
- **Release agent server URL:** production builds ignore `C35_SERVER` / `C35_SERVER_URL` unless `is_dev_mode()` — do not regress (`remotes/c_remote_core/src/config.rs`).
- **Session auth:** `meta.session_key` in YB + DPAPI `config.json` — **not** user JWT; OTA must not wipe `%LOCALAPPDATA%\AlienAI\config.json` (`update_apply` copies exe only).
- **Verify Rust:** `cd remotes && cargo test -p c_remote_core && cargo build --release -p c_remote_windows`.
- **Verify PowerShell:** parse edited `*.ps1` with `[System.Management.Automation.Language.Parser]::ParseFile`.
- **Verify prod gate:** `smoke_remote_release.ps1 -MinVersion <published>` after every remote publish.
- **Do not commit** secrets (`.env.local`, tokens). `sync_c35_server_env.ps1` syncs cluster secrets only from local env when operator runs it.
- **Multitask:** dispatch **one subagent per track** below; wave 2 starts after wave 1 tracks that publish scripts depend on are merged or use ordered deps as noted.

---

## Current baseline (shipped on main)

| Piece | Status |
|-------|--------|
| Release `server_url()` → `https://alienai.id` (non-dev) | Done |
| OTA single-flight download mutex | Done |
| `release_requires_update` honors `min` + newer `version` | Done |
| `publish_app_release.ps1 -RemoteAgent` + post-upload smoke | Done |
| Mock E2E `test_remote_autoupdate.ps1` | Done (dev only, `C35_DEV=1`) |
| Prod release **v3** (`1.3.0+3`) | Live |
| `ai.config` **`min: 0`** for remote-windows | **Gap** — no forced floor yet |
| Mock test default zip path `…-2.zip` | **Stale** after v3 publish |
| Pair UI generic “Can’t reach Alien AI” | **Gap** — hides wrong-server vs offline |
| NATS broadcast from laptop | **Unreliable** — cluster DNS only |
| Live prod OTA dry-run (no mock) | **Missing** script |

---

## File map (by track)

| Track | Create | Modify |
|-------|--------|--------|
| **1 — Release policy & publish** | `_/scripts/deploy/deploy_remote/remote_release_min.dart` (constant + helper) | `publish_remote_agent_version.dart`, `upload_remote_windows_release.dart`, `remote_windows_upload_prod.dart`, `smoke_remote_release.ps1` |
| **2 — Test & smoke matrix** | `_/scripts/dev/test_remote_ota_prod.ps1` | `test_remote_autoupdate.ps1`, `_/scripts/dev/remote_autoupdate_mock_server.py` (optional pair stub) |
| **3 — Agent reliability** | — | `remotes/c_remote_core/src/update.rs`, `remotes/c_remote_windows/src/pair_loop.rs`, `pair_window.rs` / `pair_ui.rs` |
| **4 — Security & ops** | `_/docs/remote-agent-fleet.md` | `_/docs/auto-update.md`, `_/docs/app-release.md`, `_/scripts/deploy/publish_app_release.ps1` (banner) |
| **5 — Cluster NATS broadcast** | `_/scripts/deploy/deploy_remote/nats_broadcast_release.dart` or `kubectl` Job manifest under `_/deployments/` | `publish_remote_agent_version.dart` |

---

## Multitask execution map

```text
Wave 1 (parallel)
├── Track 1: Release min floor + publish safety
├── Track 2: Prod OTA dry-run + fix mock defaults
├── Track 3: Pairing error clarity + download retry
└── Track 4: Fleet runbook + session/OTA security doc

Wave 2 (parallel, after Wave 1 Track 1 merged)
├── Track 5: NATS broadcast from cluster (Job or in-cluster dart)
└── Track 2 follow-up: wire prod dry-run into publish_app_release -RemoteAgent (optional flag)

Wave 3 (single integration track)
└── Track 6: Full verification checklist + set prod min after soak
```

---

## Track 1 — Release policy & publish safety

**Owner deliverable:** Publishing build N never lowers `min`; smoke asserts `min` and `version`; optional `-MinBuild` on publish.

### Requirements

- Add `remoteAgentMinBuild` constant (mirror `appReleaseMinBuild` pattern in `publish_app_version.dart`) — start at **3** once fleet soak approves, **0** during development of this plan until operator flips constant.
- On publish, SQL/JSON merge: `min = GREATEST(existing_min, requested_min, remoteAgentMinBuild)` — never decrease.
- `smoke_remote_release.ps1`: optional `-MinBuild` param; assert `$ver.min -ge $MinBuild` when set.
- After upload, re-fetch `/version/remote-windows` and assert `hash`, `size`, `url` host is `alienai.id`.

### Tasks

- [ ] **1.1** Add `remoteAgentMinBuild` + `remoteReleaseMinResolve(int publishVersion)` in deploy lib or `agent_version.dart`.
- [ ] **1.2** Update `publishRemoteAgentVersion` to read current `ai.config` row and merge `min` with `GREATEST`.
- [ ] **1.3** Extend `smoke_remote_release.ps1` with `-MinBuild` and URL host check.
- [ ] **1.4** Document constant bump policy in `_/docs/app-release.md` (remote-windows section).

### Verify

```powershell
.\_\scripts\deploy\deploy_remote\smoke_remote_release.ps1 -MinVersion 3 -MinBuild 0
# After constant=3 and DB updated:
.\_\scripts\deploy\deploy_remote\smoke_remote_release.ps1 -MinVersion 3 -MinBuild 3
```

---

## Track 2 — Test & smoke matrix (reliability gates)

**Owner deliverable:** One command proves **live** OTA metadata + CAS download + Blake3 without mock server; mock test tracks current publish version.

### Requirements

- **`test_remote_ota_prod.ps1`:**  
  1. `GET https://alienai.id/version/remote-windows`  
  2. Download `url` to temp file  
  3. Blake3 via `hash_blake3` tool — match `hash`  
  4. Optional: `-MinVersion`, `-MaxBytes` sanity  
  No agent process required (validates cluster + CDN + CAS signing).
- **`test_remote_autoupdate.ps1`:** Default zip = `.cache/c_remote/remote-windows/c_remote_windows-{TargetVersion}.zip`; if missing, print hint to run publish or `_build_zip_only.dart`. Default `TargetVersion` = read from prod `/version` (invoke-restmethod) when `-TargetVersion` omitted.
- Add `-SkipApply` already implied by dev mode; document that prod apply test needs unpaired idle agent on VM.

### Tasks

- [ ] **2.1** Create `test_remote_ota_prod.ps1`.
- [ ] **2.2** Fix autoupdate test defaults + version discovery.
- [ ] **2.3** Add `-ProdOta` switch to `publish_app_release.ps1 -RemoteAgent` to run prod dry-run after smoke (Wave 2 ok to add in same PR as 2.1).

### Verify

```powershell
.\_\scripts\dev\test_remote_ota_prod.ps1 -MinVersion 3
.\_\scripts\dev\test_remote_autoupdate.ps1 -TargetVersion 3
```

---

## Track 3 — Agent reliability & operator UX

**Owner deliverable:** Fewer false “Can’t reach” loops; transient OTA download failures recover without corrupt partial zips.

### Requirements

- **Pair errors (release only):** Map common failures to status text:
  - Connection refused / timeout → “Network unreachable. Retrying…”
  - HTTP 4xx/5xx to non-prod host → “Server error (HTTP n). Retrying…”
  - Do **not** log full session_key; keep existing redaction.
  - If `server_url()` is dev and host is loopback → footer hint: “Dev server — pairing needs full API, not OTA mock alone.”
- **Download retry:** In `update_download`, on failure after partial staging dir, remove staging and retry up to **3** attempts with exponential backoff (2s, 8s, 32s). Keep mutex for whole attempt chain.
- **Optional:** Log one line with `release.version`, `hash` prefix on successful stage (no URL sig).
- **Confirm:** `update_apply` / `apply.ps1` does not touch `AlienAI\config.json` — add Rust unit test or comment + manual checklist in fleet doc.

### Tasks

- [ ] **3.1** Add `pair_register_error_label(err: &anyhow::Error, base_url: &str) -> String` in `pair.rs` or `pair_loop.rs`.
- [ ] **3.2** Wire labels into `pair_loop.rs` + pair window status.
- [ ] **3.3** Implement download retry loop in `update.rs` + unit test for retry policy helper (pure fn).
- [ ] **3.4** `cargo test -p c_remote_core` + rebuild v1 fixture if integration test version changes.

### Verify

```powershell
cd remotes
cargo test -p c_remote_core
cargo build --release -p c_remote_windows
.\_\scripts\dev\test_remote_autoupdate.ps1 -TargetVersion 3
```

---

## Track 4 — Security & fleet runbook

**Owner deliverable:** Operator doc for unattended rollout; no confusion between JWT deploy token and agent session.

### Requirements — document in `_/docs/remote-agent-fleet.md`

| Topic | Locked guidance |
|-------|-----------------|
| Install source | `https://alienai.id/download/agent.exe` (307 → CAS zip) |
| Forbidden on fleet | User/system `C35_SERVER`, `C35_DEV`, mock scripts |
| Session | Opaque `session_key`; survives OTA; re-pair only on unpair/delete/lost profile |
| Deploy JWT | `DEPLOY_AUTH_TOKEN` — publish only; **never** ship to agents |
| Secrets | DPAPI for `session_key_enc`; backup not required for OTA |
| Rollout order | Pilot N machines → smoke + remote session → raise `min` → mass install |
| Incident | S3/CAS 403 → run `sync_c35_server_env.ps1 -Restart`; upload limit 256 MiB on `mod_file` |

### Tasks

- [ ] **4.1** Write `_/docs/remote-agent-fleet.md`.
- [ ] **4.2** Link from `_/docs/README.md` and `_/docs/auto-update.md`.
- [ ] **4.3** Add “Remote agent” subsection to `_/docs/app-release.md` with `-RemoteAgent`, smoke, prod OTA test commands.

---

## Track 5 — Cluster NATS broadcast (instant OTA wake)

**Owner deliverable:** Publish path triggers NATS from **inside cluster**, not developer laptop.

### Options (pick one in implementation)

1. **kubectl run** one-shot pod on cluster network posting to `nats.c35.svc.cluster.local:4222` (same payload as today).
2. **HTTP admin hook** on server_ai (auth required) — heavier; only if Job is undesirable.

### Requirements

- Replace laptop `Socket.connect(nats.c35…)` failure with success path when run from CI or publish script that invokes cluster Job.
- Publish script: try local NATS 3s → on fail, invoke `_/scripts/deploy/deploy_remote/nats_broadcast_release.ps1` (kubectl) with same JSON payload.
- Idempotent: agents still poll every 5 min if broadcast fails.

### Tasks

- [ ] **5.1** Implement cluster broadcast script + document required kubectl context (`k3s-btm`).
- [ ] **5.2** Wire into `publish_remote_agent_version.dart` fallback chain.
- [ ] **5.3** Manual test: publish to staging or dry-run Job with `-WhatIf`.

---

## Track 6 — Integration & fleet soak (Wave 3)

**Single owner after Waves 1–2 merge.**

### Checklist

- [ ] **6.1** Run full matrix on operator machine:

```powershell
.\_\scripts\deploy\deploy_remote\smoke_remote_release.ps1 -MinVersion 3
.\_\scripts\dev\test_remote_ota_prod.ps1 -MinVersion 3
.\_\scripts\dev\test_remote_autoupdate.ps1 -TargetVersion 3
```

- [ ] **6.2** Pilot: install build 3 on 2–3 unattended PCs; pair once; confirm WS online 24h; trigger publish build 4 on branch → verify OTA without re-pair.
- [ ] **6.3** Set `remoteAgentMinBuild = 3` (or current prod) and publish with merged `min` — agents below floor must OTA even if `version` equals stale build (test with v1 fixture + prod `/version` in dev mode only on lab VM).
- [ ] **6.4** Record outcomes in fleet doc “Soak log” section (date, count, failures).

---

## Security review checklist (all tracks)

- [ ] No new plaintext secrets in repo; MCP/`.env.local` unchanged in git.
- [ ] Release builds cannot be redirected to `http://` via env (dev mode only).
- [ ] OTA verifies Blake3 before `.ready`; single-flight mutex prevents zip corruption.
- [ ] CAS URLs are signed; agent does not persist sig beyond download attempt.
- [ ] Pairing codes expire; `session_key` only stored after claim over HTTPS.
- [ ] `apply.ps1` runs hidden PowerShell with fixed paths — no user-controlled strings in script body beyond escaped staging/install paths (existing pattern — re-audit on change).

---

## Out of scope (explicit)

- MSIX / Store track, Linux/macOS agents.
- JWT/session refresh on agent (not in architecture; would be new spec).
- Automatic re-pair without user code (security risk).
- Changing pairing code TTL or session_key rotation policy without identity spec update.

---

## Suggested commit slices

1. `docs: remote agent fleet runbook and release min policy`
2. `deploy: prod OTA dry-run smoke and min GREATEST on publish`
3. `agent: pair error labels and OTA download retry`
4. `deploy: cluster NATS broadcast fallback for remote release`

Each slice runs its track **Verify** block before merge.
