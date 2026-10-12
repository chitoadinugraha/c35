# Root console disk cleanup (broom) — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Date:** 2026-10-12  
**Spec:** [`_/specs/root-console-disk-cleanup.md`](../../root-console-disk-cleanup.md)  
**Related:** [`_/specs/ui.md`](../../ui.md), [`_/specs/sync.md`](../../sync.md), [`2026-09-22-root-console-node-stats.md`](2026-09-22-root-console-node-stats.md)

**Goal:** Root-only **broom** on each Boot / yugabyte / buildkit block-device row runs safe cleanup via server-orchestrated cluster actions, with confirm dialogs and step results.

**Architecture:** Flutter keeps passive stats UI; tap broom → `ReqAdminDiskClean` on WS. `c35-server` (`mod_admin` or small `mod_ops`) uses in-cluster **kube** client: boot = pinned **Job** with host `/` mount; yugabyte = **exec** into `yb-tserver`; buildkit = scale + **exec** prune (parity with `cleanup_buildkit.ps1`). No provider SSH from laptop.

**Tech Stack:** Protobuf, Rust (`kube`, `k8s-openapi`), Flutter admin widgets, k8s Job/RBAC.

## Global Constraints

- Root RBAC: `require_root` on all handlers.
- UTF-8 sources; verify per `verify-after-edit.mdc`.
- Cluster buildkit: no local Docker arm64 publish; reuse Buildkit namespace `build` ([`cluster-buildkit.mdc`](../../../.cursor/rules/cluster-buildkit.mdc)).
- UI: **small** `Icons.cleaning_services` (14–16px) **immediately after** device title; do not redesign `UiAdminStorageRow` bars/IO columns.
- Boot janitor: **allowlist only** — see spec; never touch kubelet/YB/buildkit data paths.
- YB: compaction is **online**; copy must warn about latency, not downtime.
- Audit `ai.log` per invocation.

---

## Multitask map

Execute **Track 1** first (proto). **Tracks 2–4** can parallelize after Track 1 merges. **Track 5** depends on Track 1. **Track 6** after Track 5 (or mock API in parallel). **Track 7** last.

| Track | Name | Depends | Delivers |
|-------|------|---------|----------|
| **1** | Proto + wire + codegen | — | `ReqAdminDiskClean` / `ResAdminDiskClean` |
| **2** | Boot janitor Job + script | 1 | Host allowlist script + Job manifest + RBAC |
| **3** | YB clean + compact | 1 | Exec helpers, timeouts, step reporting |
| **4** | Buildkit prune | 1 | Go/no-go if pod Running; prune + scale down |
| **5** | Server handler + RBAC | 1–4 | `admin_disk_clean`, logging, concurrency guard |
| **6** | Flutter broom UI | 1 (5 for E2E) | Icon, dialogs, API, error states |
| **7** | Docs + verify | 5–6 | ui.md, server.md, sync.md, manual checklist |

---

### Track 1 — Proto + wire

**Files:**

- Modify: `_/schemas/proto/c35/stats.proto` or `admin.proto` (messages above)
- Modify: `_/schemas/proto/c35/wire.proto` (new req/res field numbers)
- Regenerate: Dart + Rust proto (repo script / `build.rs` as usual)

**Interfaces:**

- Produces: `AdminDiskCleanKind`, `ReqAdminDiskClean`, `ResAdminDiskClean`

- [ ] **Step 1:** Add messages per [`root-console-disk-cleanup.md`](../../root-console-disk-cleanup.md).
- [ ] **Step 2:** Wire `invoke` + `session.rs` dispatch mirror `admin_ops_peaks`.
- [ ] **Step 3:** `cd servers && cargo build -p server_ai`
- [ ] **Step 4:** `.\_\scripts\dev\verify_flutter_app.ps1` (proto Dart)

---

### Track 2 — Boot janitor (safe host cleanup)

**Files:**

- Create: `_/scripts/deploy/node_boot_disk_clean.sh` (allowlist steps; `set -euo pipefail`; logs to stdout for Job log)
- Create: `_/deployments/c35-node-janitor/job-template.yaml` (documented template; server creates Job with node name)
- Modify: `_/deployments/c35-server/rbac.yaml` (or cluster role) — `jobs` create/get/watch in `c35`
- Optional: `_/deployments/c35-node-janitor/Dockerfile` if not using chroot busybox

**Interfaces:**

- Consumes: `node_name`
- Produces: step list + exit code

- [ ] **Step 1:** Implement script exactly as spec allowlist (journal, rotated logs, tmp, apt, crictl prune).
- [ ] **Step 2:** Job spec: `hostPath` `/` → `/host`, privileged or CAP_SYS_ADMIN per cluster policy; `nodeSelector: kubernetes.io/hostname: <node>`.
- [ ] **Step 3:** Rust helper `boot_disk_clean_job(node_name) -> JobName` wait with timeout 15m, parse log lines into steps.
- [ ] **Step 4:** Manual test on one worker: Job completes, `df` improves, pods healthy.

---

### Track 3 — Yugabyte maintenance

**Files:**

- Create: `servers/crates/mod_admin/src/disk_clean_yb.rs` (or under `mod_ops`)
- Modify: `_/deployments/yugabyte/README.md` — document `yb-admin` compact command used

**Interfaces:**

- Consumes: `node_name`, `full` (compact only when deep/compact flag — v1: `full` on YB = include compact step)

- [ ] **Step 1:** `yb_log_cleanup` exec with fallbacks from Helm hook paths.
- [ ] **Step 2:** `yb_compact` gated behind `req.full == true` with 45m timeout and streaming log capture.
- [ ] **Step 3:** Verify node hosts `yb-tserver-0` before exec.
- [ ] **Step 4:** YSQL smoke after compact in manual checklist.

---

### Track 4 — Buildkit prune

**Files:**

- Create: `servers/crates/mod_admin/src/disk_clean_buildkit.rs`
- Reference: `_/deployments/_lib/publish.ps1` (`Ensure-Buildkit`, `Stop-Buildkit`, prune flags)

**Interfaces:**

- Consumes: `full`, optional `force` (proto v1: use `full` only; force via UI resubmit)

- [ ] **Step 1:** Port `Get-BuildkitPodName` logic — list pods `app=buildkit` ns `build`.
- [ ] **Step 2:** If Running+Ready and not `force`, return error `buildkit_active` for UI dialog retry.
- [ ] **Step 3:** Scale up deployment if replicas=0; exec prune; scale down on success.
- [ ] **Step 4:** Parity test: same disk delta as `cleanup_buildkit.ps1` on staging.

---

### Track 5 — Server handler

**Files:**

- Modify: `servers/crates/mod_admin/src/lib.rs` + `disk_clean.rs`
- Modify: `servers/crates/wire_ws/src/session.rs`
- Modify: `_/deployments/c35-server/` ServiceAccount RBAC (exec pods in `yugabyte`, `build`)

- [ ] **Step 1:** `admin_disk_clean(pool, viewer_iid, req) -> ResAdminDiskClean` dispatch by kind.
- [ ] **Step 2:** In-memory mutex `HashMap<(node, kind), Instant>` for concurrent guard.
- [ ] **Step 3:** `mod_log` audit line with steps JSON.
- [ ] **Step 4:** `cargo build -p server_ai` + `cargo test -p c35_mod_admin` (unit: kind validation, reject non-root).

---

### Track 6 — Flutter UI

**Files:**

- Modify: `clients/app/lib/widgets/admin/ui_admin_storage_row.dart`
- Modify: `clients/app/lib/pages/page_root_console.dart` (pass `nodeName`, `onClean` or callback)
- Create: `clients/app/lib/widgets/admin/ui_admin_disk_clean_dialog.dart`
- Modify: `clients/app/lib/c/admin/admin_api.dart`

**UI checklist (required):**

```dart
// Title row: "sda (Boot)" [broom 14px] ... bytes ... %
Row(
  children: [
    Expanded(child: Text(_title, ...)),
    if (cleanKind != null)
      IconButton(
        icon: Icon(Icons.cleaning_services, size: 15, color: adminMuted),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
        onPressed: () => onBroomTap(cleanKind!),
      ),
    Text(adminFmtBytesPair(...)),
    ...
  ],
)
```

- [ ] **Step 1:** Map `label` / `isBoot` → `AdminDiskCleanKind` (match Rust `normalize_disk_label`).
- [ ] **Step 2:** Confirm dialog per kind (boot list steps; YB mentions online compaction; buildkit warns if server returns `buildkit_active`).
- [ ] **Step 3:** Call `adminDiskClean`; show steps in bottom sheet; snackbar on failure.
- [ ] **Step 4:** `flutter analyze` / `verify_flutter_app.ps1`.

---

### Track 7 — Docs + ship

**Files:**

- Modify: [`_/specs/ui.md`](../../ui.md) — broom row in Root console table
- Modify: [`_/specs/server.md`](../../server.md) — link spec; update “Action when high” column
- Modify: [`_/specs/sync.md`](../../sync.md) — `admin_disk_clean` WS note (no NATS)
- Modify: [`_/deployments/c35-node-stats/README.md`](../../deployments/c35-node-stats/README.md) — cross-link (stats read-only; clean via server)

- [ ] **Step 1:** Docs committed with spec.
- [ ] **Step 2:** `publish_server.ps1` after RBAC/manifest changes.
- [ ] **Step 3:** Manual E2E from app (99000 root): each broom once on `168.110.203.3` node card.
- [ ] **Step 4:** `check_utf8_sources.ps1 -Changed -Fix`

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Boot Job too privileged | Allowlist script only; no shell; short TTL; audit log |
| YB compact load | Default broom = logs only; compact needs `full`/second confirm |
| Prune during publish | UI + `buildkit_active` error; user confirms force |
| Wrong node | Bind YB/buildkit to pod node; boot Job nodeSelector |

---

## Definition of done

- [ ] Broom visible only on Boot / yugabyte / buildkit rows; size 14–16; title row unchanged otherwise.
- [ ] All three kinds run from app against production cluster with root user.
- [ ] Spec and multitask plan in repo; ui.md updated.
- [ ] Server build + Flutter verify green.
