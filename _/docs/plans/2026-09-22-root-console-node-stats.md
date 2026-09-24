# Root console + node stats implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Date:** 2026-09-22  
**Specs:** [`_/docs/ui.md`](../../_/docs/ui.md), [`_/docs/log.md`](../../_/docs/log.md), [`_/docs/inst.md`](../../_/docs/inst.md), [`_/docs/sync.md`](../../_/docs/sync.md)

**Goal:** Root-only admin console in Flutter: compact NATS-driven node/volume stats dashboard, live log browser, and inst UITable editor. Background stats via `c35-node-stats` DaemonSet (one pod per k8s node).

**Architecture:** `c35-node-stats` samples host CPU/RAM/net, OS disk mounts, and PVC usage (YB + NATS via k8s volume stats API), publishes protobuf `StatsPush` on NATS every 2s. `server_ai` relays stats + logs to root WS clients on subscribe (no polling). Flutter root page listens passively; Logs and Inst open separate pages.

**Tech Stack:** Rust (`sysinfo`, `kube` client, `async-nats`), protobuf, k8s DaemonSet + RBAC, Flutter (`UiTable`, referral date-range sheet pattern).

## Global Constraints

- Root RBAC: `require_root` on all admin invoke + subscribe handlers.
- NATS subjects documented in `_/docs/sync.md`.
- No SSH, no on-demand stats sampling from Flutter.
- DaemonSet = **one reporter pod per k8s node** (not one per cluster).
- `c35-server` replicas → 2 with `maxUnavailable: 0` during rollout.
- Naming: `ui_` widgets, `io_` inputs, `l()` logging, contextual API names (`adminLogList`, `statsSubscribe`).
- Verify: `cargo build -p server_ai`, `cargo test` on touched crates, `flutter analyze` in `clients/app`.

---

## Stateful vs stateless (cluster inventory)

| Component | Stateful? | What to monitor |
|-----------|-----------|-----------------|
| **YugabyteDB** (`yugabyte` ns) | **Yes** — PVC per tserver/master | PVC used/capacity % — **must** alert before full |
| **NATS JetStream** (`nats` ns) | **Yes** — if JS store on PVC | PVC used/capacity % |
| **c35-server** | **Mostly no** — CAS is `emptyDir` today | Node OS disk (boot, `/var/log`) on nodes it runs on |
| **channel-whatsapp-device** | **No** — session state in YB | None (optional pod restarts OK) |
| **coturn** | **No** | None |
| **buildkit** | PVC exists but `replicas: 0` | Skip unless enabled |

Everything else is stateless for ops purposes. **Only YB + NATS PVCs need volume rows on the dashboard** for resize/replica decisions. Node OS disk covers “clean up / resize node” for logs and boot partition.

---

## NATS subjects

| Subject | Publisher | Payload |
|---------|-----------|---------|
| `c35.stats.node.{node_name}` | `c35-node-stats` | `StatsPush` (node section) |
| `c35.stats.volume.{namespace}.{pvc_name}` | `c35-node-stats` | `StatsPush` (single volume) |
| `log.{iid}.{dv}.{topic}` | `mod_log` (existing) | `LogPush` |

Root UI subscribes via WS relay:
- `c35.stats.>` — latest per subject cached on server, fanout on change
- `log.>` or `log.{iid}.>` — when log page open

---

## Proto (`_/schemas/proto/c35/stats.proto` — new)

```protobuf
syntax = "proto3";
package c35;

message DiskMountStat {
  string label = 1;        // "Boot", "OS logs"
  string mount = 2;        // "/", "/var/log"
  uint64 used_bytes = 3;
  uint64 total_bytes = 4;
  double read_bps = 5;
  double write_bps = 6;
}

message VolumeStat {
  string namespace = 1;
  string pvc_name = 2;
  string pod_name = 3;
  string node_name = 4;
  uint64 used_bytes = 5;
  uint64 capacity_bytes = 6;
  string storage_class = 7;
}

message NodeStat {
  string node_name = 1;
  int32 cpu_cores = 2;
  double cpu_pct = 3;
  uint64 mem_used_bytes = 4;
  uint64 mem_total_bytes = 5;
  repeated DiskMountStat mounts = 6;
  double net_in_bps = 7;
  double net_out_bps = 8;
  int64 ts_ms = 9;
}

message StatsPush {
  oneof body {
    NodeStat node = 1;
    VolumeStat volume = 2;
  }
}

message ReqStatsSubscribe {}
message ReqStatsUnsubscribe {}
message ReqAdminLogList {
  optional int64 owner_iid = 1;
  int64 since_ms = 2;
  int64 until_ms = 3;
  string text = 4;
  optional string kind = 5;
  optional string topic = 6;
  int32 limit = 7;
  optional int64 before_id = 8;
}
message ResAdminLogList {
  repeated Log logs = 1;   // reuse c35.Log from log.proto
}
message ReqLogSubscribe {
  optional int64 owner_iid = 1;
}
message ReqLogUnsubscribe {}
```

Wire into `wire.proto` `WsReq` / `WsRes` + `InvokeReq` for `ReqAdminLogList` only (stats/logs subscribe are WS).

---

## File map

### New — Rust workspace `node_stats/`

```
node_stats/
  Cargo.toml
  c_node_stats/
    Cargo.toml
    src/
      main.rs           # loop: sample → publish
      node.rs           # CPU/RAM/net + host mounts
      volume.rs         # k8s PVC usage
      k8s.rs            # kube client + volume stats
      sample.rs           # delta IO/net between ticks
  Dockerfile
```

### New — k8s

```
_/deployments/c35-node-stats/
  daemonset.yaml        # hostPath + downward API + ConfigMap
  rbac.yaml             # list nodes, read stats/summary, list PVCs
  configmap.yaml        # mount paths, PVC label selectors
```

### Modified — server

```
servers/crates/mod_admin/src/log_admin.rs     # ReqAdminLogList SQL
servers/crates/wire_ws/src/session.rs         # stats + log fanout on subscribe
servers/crates/wire_ws/src/admin_subscribe.rs # optional split
_/schemas/proto/c35/stats.proto
_/schemas/proto/c35/wire.proto
_/docs/sync.md
_/docs/ui.md
_/deployments/c35-server/deployment.yaml      # replicas: 2, NODE_NAME env
```

### New — Flutter

```
clients/app/lib/pages/page_root_console.dart
clients/app/lib/pages/page_root_logs.dart
clients/app/lib/pages/page_root_inst.dart
clients/app/lib/c/admin/admin_api.dart
clients/app/lib/c/admin/admin_stats_stream.dart
clients/app/lib/c/admin/admin_log_stream.dart
clients/app/lib/widgets/admin/ui_admin_stat_bar.dart
clients/app/lib/widgets/admin/ui_admin_volume_row.dart
clients/app/lib/widgets/admin/ui_admin_log_table.dart
clients/app/lib/widgets/admin/io_admin_user_pick.dart
clients/app/lib/widgets/ui/ui_date_range_chip.dart   # generalize referral sheet
```

---

## Track 1 — Proto + docs

- [ ] **1.1** Add `_/schemas/proto/c35/stats.proto`; import in `wire.proto` (WsReq: `stats_subscribe`, `stats_unsubscribe`, `log_subscribe`, `log_unsubscribe`; WsRes: `stats_push`; InvokeReq: `admin_log_list`).
- [ ] **1.2** Regenerate Dart + Rust protos (`servers/crates/proto/build.rs`, client pb).
- [ ] **1.3** Document subjects in `_/docs/sync.md` § NATS (`c35.stats.*`, admin WS subscribe).
- [ ] **1.4** Update `_/docs/ui.md` § Root console (dashboard layout, action buttons, log filters).

**Verify:** `cargo build -p c35_proto`, `flutter analyze` (pb compile).

---

## Track 2 — `c35-node-stats` DaemonSet

### 2.1 Binary

- [ ] **2.1.1** Create `node_stats/` workspace; binary `c_node_stats`.
- [ ] **2.1.2** `node.rs`: read host via `hostPath` prefix `/host` — `statvfs` on `/host`, `/host/var/log` (configurable `C35_NODE_MOUNTS`).
- [ ] **2.1.3** `node.rs`: CPU/RAM from `/host/proc` or `sysinfo` with `set_root("/host")` if supported; network deltas from `/host/proc/net/dev`.
- [ ] **2.1.4** `sample.rs`: keep previous sample; compute `read_bps`, `write_bps`, `net_in_bps`, `net_out_bps`.
- [ ] **2.1.5** `volume.rs` + `k8s.rs`: ServiceAccount; for configured namespaces (`yugabyte`, `nats`):
  - List PVCs (label selector optional).
  - Resolve bound PV → node; read **kubelet volume stats** (`Node::stats` or `GET /api/v1/nodes/{name}/proxy/stats/summary`) for `usedBytes` / `capacityBytes`.
  - Publish one `StatsPush { volume }` per PVC per tick.
- [ ] **2.1.6** Main loop every **2s**: publish `c35.stats.node.{NODE_NAME}`; publish each volume subject `c35.stats.volume.{ns}.{pvc}`.
- [ ] **2.1.7** Env: `NATS_URL`, `NATS_CA`, `NODE_NAME` (downward API), `C35_VOLUME_NS=yugabyte,nats`, `C35_NODE_MOUNTS=/,/var/log`.

### 2.2 Deploy

- [ ] **2.2.1** `daemonset.yaml`: `hostPID: true`, hostPath mounts (`/ → /host`, read-only), `priorityClassName` optional, tolerations for all nodes.
- [ ] **2.2.2** `rbac.yaml`: ClusterRole `get/list/watch` on `nodes`, `nodes/stats`, `persistentvolumeclaims`, `pods`; bind SA in `c35` ns.
- [ ] **2.2.3** `Dockerfile` + publish script entry in `_/deployments/_lib/publish.ps1` (arm64).
- [ ] **2.2.4** Deploy to `k3s-btm`; confirm `nats sub 'c35.stats.>'` shows node + YB/NATS volume messages.

**Verify:** Manual NATS subscribe; volume rows show realistic used/capacity for YB PVCs.

**Note:** If kubelet stats API is blocked, fallback: ConfigMap explicit `C35_VOLUME_MOUNTS` host paths (document in README).

---

## Track 3 — Server WS relay + admin log query

### 3.1 Stats fanout

- [ ] **3.1.1** On `ReqStatsSubscribe` (root only): server subscribes NATS `c35.stats.>` if not already (one global sub per pod, ref-count connected root clients).
- [ ] **3.1.2** Forward each `StatsPush` as `WsRes.stats_push` to subscribed root sessions.
- [ ] **3.1.3** Keep in-memory `last_stats: HashMap<subject, StatsPush>` — send snapshot on subscribe.
- [ ] **3.1.4** `ReqStatsUnsubscribe` decrements ref-count; drop NATS sub when zero.

### 3.2 Log fanout

- [ ] **3.2.1** `mod_admin/log_admin.rs`: `admin_log_list(pool, viewer_iid, req)` — `require_root`; SQL with optional `owner_iid`, `since_ms`, `until_ms`, `text ILIKE`, `kind`, `topic`, `LIMIT`, cursor `before_id`.
- [ ] **3.2.2** Wire `InvokeReq.admin_log_list` in `wire_http/invoke.rs`.
- [ ] **3.2.3** On `ReqLogSubscribe` (root): NATS `log.{iid}.>` or `log.>`; forward `LogPush` to WS.
- [ ] **3.2.4** `ReqLogUnsubscribe` cleanup (per-session filter: only forward if matches session's `owner_iid` filter).

**Verify:**

```powershell
cd servers
cargo build -p server_ai
cargo test -p c35_mod_admin   # add log_admin tests
```

---

## Track 4 — `c35-server` HA

- [ ] **4.1** `deployment.yaml`: `replicas: 2`, `maxUnavailable: 0`, `maxSurge: 1`.
- [ ] **4.2** Add `NODE_NAME`, `POD_NAME` downward API env (for future pod-level debug, not required for stats).

---

## Track 5 — Flutter root console

### 5.1 Entry

- [ ] **5.1.1** `UiAccountMenuAction.onRootConsole`; show row + tappable Root badge when `Session.isRoot`.
- [ ] **5.1.2** Wire from `page_ai_home.dart` (and other pages with avatar menu if any).

### 5.2 `PageRootConsole`

- [ ] **5.2.1** On init: `statsSubscribe()` via WS; on dispose: `statsUnsubscribe()`.
- [ ] **5.2.2** `AdminStatsStream`: merge `StatsPush` by subject into `nodeStats` + `volumeStats` list.
- [ ] **5.2.3** Dashboard widgets:
  - `ui_admin_stat_bar` — CPU, memory (compact bars per mock).
  - `ui_admin_volume_row` — per mount: IO bar + storage bar; label Boot / OS logs.
  - Volume section: YB + NATS PVCs sorted by % used; warn color ≥ 80%, critical ≥ 90%.
  - Network row: aggregate node net from selected node (single-node: first node).
- [ ] **5.2.4** Action buttons: **Logs** → `PageRootLogs`, **Inst** → `PageRootInst`.

### 5.3 `PageRootLogs`

- [ ] **5.3.1** Toolbar: search field, `io_admin_user_pick`, date chip (`ui_date_range_chip` — presets Today/Yesterday/7d/30d + custom, from referral sheet).
- [ ] **5.3.2** Initial load: `adminLogList` invoke with filters.
- [ ] **5.3.3** `logSubscribe(owner_iid)`; append `log_push` rows matching filters; dedupe by `id`.
- [ ] **5.3.4** `ui_admin_log_table`: time, user name (cache from pick), topic, kind, text truncate, expand for meta.

### 5.4 `PageRootInst`

- [ ] **5.4.1** `TableDef` for inst columns: `id`, `scope`, `kind`, `enabled`, `priority`, `phrases` (preview).
- [ ] **5.4.2** `inst_list` / `inst_put` / `inst_delete` via existing invoke.
- [ ] **5.4.3** Expand row: multiline `inst`, `triggers` chips; add row for new inst.
- [ ] **5.4.4** Root-only scope filter dropdown (`global`, `role:personal_assistant`, all).

**Verify:**

```powershell
cd clients/app
flutter analyze
flutter test
```

---

## Track 6 — Docs + deploy checklist

- [ ] **6.1** `_/docs/server.md` — add `c35-node-stats` section.
- [ ] **6.2** `_/deployments/c35-node-stats/README.md` — config, RBAC, how to add PVC namespace.
- [ ] **6.3** Deploy order: node-stats DaemonSet → server 2 replicas → Flutter build.

---

## Execution order (waves)

| Wave | Tracks | Delivers |
|------|--------|----------|
| **1** | Track 1 | Proto + docs |
| **2** | Track 2 | DaemonSet publishing real node + PVC stats |
| **3** | Track 3 + 4 | WS relay + admin log SQL + 2 server replicas |
| **4** | Track 5 | Flutter root UI |
| **5** | Track 6 | Docs, prod deploy |

Waves 2 and 3 can run in parallel after wave 1.

---

## Dashboard UI reference (compact)

```
CPU  4 cores  90%  [████████░░░░]
Memory  4/14 GB     [███░░░░░░░░░]

Boot disk      R 9 MB/s W 10 MB/s  [████░░░░]  30/100 GB [███████░░]
OS logs        R …                  [██░░░░░░]  2/20 GB   [█░░░░░░░░]

Volumes
  yugabyte / yb-data-tserver-0     82/100 GB  [████████░░]  ⚠
  nats     / nats-js-pvc-0         12/50 GB   [██░░░░░░░░]

Network  In 10 MB/s  Out 90 MB/s

[ Logs ]  [ Inst ]
```

---

## Assumptions (locked unless you correct)

1. YB namespace: `yugabyte`; NATS namespace: `nats` (from existing `deployment.yaml` service DNS).
2. Node-stats DaemonSet runs in `c35` namespace with cluster-wide RBAC for volume stats.
3. Single k8s node today; UI still renders a list when you add nodes (one `NodeStat` per subject).
4. Root-only for entire console; partner inst UI deferred.
5. CAS stays `emptyDir` for now — not on volume dashboard until you move to PVC.

---

## Open questions (non-blocking — defaults above)

1. **Exact YB/NATS PVC names** — discovered at runtime via namespace list; confirm namespaces if different on `k3s-btm`.
2. **NATS JetStream** — if NATS runs without PVC (memory only), volume row simply won't appear; OK?
3. **Log retention** — admin list capped at 500 rows; no auto-archival in this plan.

---

## Verify (full)

```powershell
cd servers && cargo build -p server_ai && cargo test -p c35_mod_admin
cd node_stats && cargo build
cd clients/app && flutter analyze
# cluster: kubectl apply -f _/deployments/c35-node-stats/
# nats sub 'c35.stats.>' --count=5
```
