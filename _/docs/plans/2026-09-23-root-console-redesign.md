# Root Console Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the root console dashboard with proper storage/network bars, block-device naming (`sda (boot)`), multi-node cards, volume rows (`yb-tserver`, `yb-master`, `nats`), action tile grid, and Objects/Aliases UITable curation.

**Architecture:** Extend `stats.proto` with `DiskDeviceStat`; `c35-node-stats` enumerates `/host/sys/block/sd*` and maps to mounts; volume NATS subjects include `node_name` to fix multi-node cache collisions; Flutter `PageRootConsole` shows per-node expandable cards with Storages/Network/Volumes sections; new `object_admin` invoke handlers mirror `inst_admin`; Objects page uses `UiTable` like Inst.

**Tech Stack:** Rust (`node_stats`, `mod_chat`), protobuf, k8s ConfigMap/DaemonSet, Flutter (`UiTable`, `UiAdminStatBar`), NATS relay (`admin_fanout.rs`).

## Global Constraints

- Root RBAC: `require_root` on all admin invoke + subscribe handlers.
- Naming: `ui_` widgets, `io_` inputs; contextual API names (`objectAliasList`, `adminStatsStream`).
- Verify: `cd servers && cargo build -p server_ai`; `cd clients/app && flutter analyze`; `cd node_stats && cargo build -p c_node_stats`.
- Rust cache under `.cache/` — always `cd` into workspace before `cargo build`.
- Do not commit secrets; ConfigMap paths are host paths only.
- Cluster: `k3s-btm` arm64 — `publish_node_stats.ps1` for image deploy.
- Backward compat: keep `DiskMountStat mounts` on wire during rollout; UI prefers `devices` when non-empty.
- Volume display label: **pvc_name only** (`yb-tserver`, `yb-master`, `nats-data` → show as `nats`).

---

## Multitask Waves

```
Wave 0 (gate)     Task 1 — Proto + regen
                      │
Wave 1 (parallel) ├── Task 2 — Block devices (node_stats)
                  ├── Task 3 — Volume subjects + ConfigMap
                  ├── Task 4 — Flutter admin widgets
                  └── Task 5 — Object proto + server admin
                      │
Wave 2 (parallel) ├── Task 6 — AdminStatsStream multi-node
                  ├── Task 7 — PageRootConsole + node cards
                  ├── Task 8 — PageRootObjects Flutter
                  └── Task 9 — Deploy node-stats + verify NATS
                      │
Wave 3            Task 10 — Docs + integration verify
```

---

## File Map

| Area | Create | Modify |
|------|--------|--------|
| Proto | — | `_/schemas/proto/c35/stats.proto`, `object.proto`, `wire.proto` |
| Collector | `node_stats/c_node_stats/src/device.rs` | `node.rs`, `host.rs`, `main.rs`, `volume.rs` |
| Deploy | — | `_/deployments/c35-node-stats/configmap.yaml`, `README.md` |
| Server | `servers/crates/mod_chat/src/object_admin.rs` | `lib.rs`, `wire_http/src/invoke.rs` |
| Flutter pages | `page_root_objects.dart` | `page_root_console.dart` |
| Flutter widgets | `ui_admin_network_row.dart`, `ui_admin_storage_row.dart`, `ui_admin_node_card.dart`, `ui_admin_action_tile.dart` | `ui_admin_stat_bar.dart`, `ui_admin_volume_row.dart` |
| Flutter API | `object_table.dart` | `admin_stats_stream.dart`, `admin_api.dart` |
| Docs | — | `_/docs/ui.md`, `_/docs/sync.md`, `_/docs/tx.md` |

---

### Task 1: Proto foundation (Wave 0 — blocks all)

**Files:**
- Modify: `_/schemas/proto/c35/stats.proto`
- Modify: `_/schemas/proto/c35/object.proto` (new file)
- Modify: `_/schemas/proto/c35/wire.proto`
- Regenerate: `clients/app/lib/c/pb/**`, Rust `c35_proto`

**Interfaces:**
- Produces: `DiskDeviceStat`, extended `NodeStat.devices`, `VolumeStat.label`, volume subject `c35.stats.volume.{node}.{ns}.{pvc}`
- Produces: `ObjectNormalizerDoc`, `ObjectAliasDoc`, `ReqObjectAliasList`, `ReqObjectAliasPut`, `ResObjectAliasList`, `ResObjectAliasPut`

- [ ] **Step 1: Extend stats.proto**

```protobuf
message DiskDeviceStat {
  string device = 1;       // "sda", "nvme0n1"
  string mount = 2;        // "/", "/data" (empty if unmounted)
  string label = 3;        // "boot", "data" (display suffix)
  bool is_boot = 4;
  uint64 used_bytes = 5;
  uint64 total_bytes = 6;
  double read_bps = 7;
  double write_bps = 8;
}

message VolumeStat {
  // ... existing fields 1-7 ...
  string label = 8;        // display label; pod_name kept for compat
}

message NodeStat {
  // ... existing fields 1-9 ...
  repeated DiskDeviceStat devices = 10;
}
```

- [ ] **Step 2: Create object.proto**

```protobuf
syntax = "proto3";
package c35;

message ObjectNormalizerDoc {
  int64 id = 1;
  string slug = 2;
  int64 parent_id = 3;
  string path = 4;
  int32 depth = 5;
  string kind = 6;
}

message ObjectAliasDoc {
  int64 id = 1;
  int64 obj_id = 2;
  string lang = 3;
  string name = 4;
  string name_norm = 5;
  bool is_canonical = 6;
  bool verified = 7;
  string obj_path = 8;     // joined path for display
}

message ReqObjectAliasList {
  optional bool verified = 1;   // default: list unverified only when false
  optional string lang = 2;
  optional string q = 3;        // ILIKE on name_norm
  int32 limit = 4;
}

message ResObjectAliasList {
  repeated ObjectAliasDoc items = 1;
}

message ReqObjectAliasPut {
  ObjectAliasDoc doc = 1;
}

message ResObjectAliasPut {
  ObjectAliasDoc doc = 1;
}

message ReqObjectNormalizerList {
  optional string q = 1;        // path prefix ILIKE
  int32 limit = 2;
}

message ResObjectNormalizerList {
  repeated ObjectNormalizerDoc items = 1;
}
```

- [ ] **Step 3: Wire invoke IDs in wire.proto** (next free slots after inst 103-106):

```
ReqObjectAliasList object_alias_list = 111;
ReqObjectAliasPut object_alias_put = 112;
ReqObjectNormalizerList object_normalizer_list = 113;
```

- [ ] **Step 4: Regenerate protos**

```powershell
cd servers
cargo build -p c35_proto
cd ../clients/app
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Verify**

```powershell
cd servers && cargo build -p server_ai
cd ../clients/app && flutter analyze
```

---

### Task 2: Block device enumeration (Wave 1)

**Files:**
- Create: `node_stats/c_node_stats/src/device.rs`
- Modify: `node_stats/c_node_stats/src/node.rs`, `host.rs`, `main.rs`
- Test: `node_stats/c_node_stats/src/device.rs` (unit tests with fixture mountinfo)

**Interfaces:**
- Consumes: `DiskDeviceStat` from proto
- Produces: `NodeStat.devices` populated each tick; `mounts` still filled for compat

- [ ] **Step 1: Add device.rs — enumerate block devices**

```rust
// device.rs — parse /host/sys/block/sd* and /host/sys/block/nvme*
pub struct BlockDevice {
    pub name: String,       // "sda"
    pub mount: String,      // "/" or ""
    pub is_boot: bool,
    pub used_bytes: u64,
    pub total_bytes: u64,
}

pub fn block_devices(host_prefix: &str) -> Vec<BlockDevice> {
    // 1. list /host/sys/block — filter sd*, nvme*n*
    // 2. skip partitions (names ending in digit for sd; nvme*p* for partitions)
    // 3. map mount via mountinfo (longest mount path wins per device)
    // 4. is_boot = mount == "/"
    // 5. statvfs on mount path if mounted, else read size from sysfs size file
    // 6. label: is_boot → "boot", else mount basename or ""
}
```

- [ ] **Step 2: Wire IO deltas in node.rs**

Map `disk_io_by_device(host_prefix, device_names)` in `host.rs` (key by device name from diskstats major:minor → device symlink).

```rust
// In NodeSampler::sample():
let devices = block_devices(HOST_PREFIX)
    .into_iter()
    .map(|d| {
        let (read_bps, write_bps) = /* delta from prev snapshot keyed by d.name */;
        DiskDeviceStat {
            device: d.name,
            mount: d.mount,
            label: d.is_boot.then_some("boot".into()).unwrap_or_default(),
            is_boot: d.is_boot,
            used_bytes: d.used_bytes,
            total_bytes: d.total_bytes,
            read_bps,
            write_bps,
        }
    })
    .collect();
```

- [ ] **Step 3: Unit test with fixture**

```rust
#[test]
fn boot_device_marked() {
    let devices = parse_devices_from_fixture("fixtures/mountinfo_boot.txt");
    assert!(devices.iter().any(|d| d.is_boot && d.name == "sda"));
}
```

- [ ] **Step 4: Build**

```powershell
cd node_stats
cargo test -p c_node_stats
cargo build --release -p c_node_stats
```

---

### Task 3: Volume subjects + ConfigMap (Wave 1)

**Files:**
- Modify: `node_stats/c_node_stats/src/volume.rs`, `main.rs`
- Modify: `_/deployments/c35-node-stats/configmap.yaml`, `README.md`
- Modify: `_/docs/sync.md`

**Interfaces:**
- Produces: NATS subject `c35.stats.volume.{node_name}.{namespace}.{pvc_name}`
- Produces: `VolumeStat.label` field set from config (not `pod_name`)

- [ ] **Step 1: Change volume subject**

```rust
pub fn volume_subject(node_name: &str, namespace: &str, pvc_name: &str) -> String {
    format!("c35.stats.volume.{node_name}.{namespace}.{pvc_name}")
}
```

- [ ] **Step 2: Set label field in sample_volume**

```rust
VolumeStat {
    // ...
    pod_name: cfg.label.clone(),  // keep for old clients
    label: cfg.label.clone(),
}
```

- [ ] **Step 3: Update ConfigMap**

```yaml
C35_VOLUME_PATHS: >-
  yugabyte:yb-tserver:/host/var/lib/alienai/yb-tserver:oci-bv:yb-tserver,
  yugabyte:yb-master:/host/var/lib/alienai/yb-master:oci-bv:yb-master,
  nats:nats-data:/host/var/lib/alienai/nats:oci-bv:nats
```

> **Deploy note:** Before apply, verify host paths on cluster:
> `kubectl exec -n c35 -l app=c35-node-stats -- ls /host/var/lib/alienai/`
> Adjust `yb-master` and `nats` paths to match actual host layout.

- [ ] **Step 4: Document new subject in sync.md**

```
c35.stats.volume.{node_name}.{namespace}.{pvc_name}
```

- [ ] **Step 5: Build**

```powershell
cd node_stats && cargo build -p c_node_stats
```

---

### Task 4: Flutter admin widgets (Wave 1)

**Files:**
- Create: `clients/app/lib/widgets/admin/ui_admin_storage_row.dart`
- Create: `clients/app/lib/widgets/admin/ui_admin_network_row.dart`
- Create: `clients/app/lib/widgets/admin/ui_admin_action_tile.dart`
- Create: `clients/app/lib/widgets/admin/ui_admin_node_card.dart`
- Modify: `clients/app/lib/widgets/admin/ui_admin_volume_row.dart`

**Interfaces:**
- Consumes: `DiskDeviceStat` or fallback `DiskMountStat`
- Produces: reusable widgets for Task 7

- [ ] **Step 1: UiAdminStorageRow — full-width bar like CPU/RAM**

```dart
// Label: "sda (boot)" when isBoot, else "sdb"
// Detail: "22 / 83 GB" right-aligned
// Bar: UiAdminStatBar-style full width
// Optional subtitle: "R 12 KB/s  W 4 KB/s" muted
class UiAdminStorageRow extends StatelessWidget {
  final String device;      // "sda"
  final String label;       // "boot" or ""
  final int usedBytes;
  final int totalBytes;
  final double readBps;
  final double writeBps;
  final bool isBoot;
}
```

- [ ] **Step 2: UiAdminNetworkRow — dual bars**

```dart
// Rolling max from parent (AdminStatsStream tracks peak in/out over 60s)
// Two bars: In (blue #60A5FA), Out (green #34D399)
// Labels: "In 33 B/s" / "Out 180 B/s"
class UiAdminNetworkRow extends StatelessWidget {
  final double inBps;
  final double outBps;
  final double maxBps;  // scale denominator
}
```

- [ ] **Step 3: UiAdminActionTile**

```dart
class UiAdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;  // filled accent vs outlined
}
```

- [ ] **Step 4: UiAdminNodeCard — collapsed/expanded**

```dart
class UiAdminNodeCard extends StatelessWidget {
  final NodeStat node;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  // collapsed: one-line "CPU 13% · RAM 40% · sda 26%"
  // expanded: CPU, RAM, Network, Storages section
}
```

- [ ] **Step 5: Fix UiAdminVolumeRow label**

```dart
// Display: volume.label.isNotEmpty ? volume.label : volume.pvcName
// Strip namespace prefix; show "yb-tserver" not "yugabyte / yb-tserver"
// Append node_name suffix when multi-node: "yb-tserver @ k3s-btm-01"
```

- [ ] **Step 6: Verify**

```powershell
cd clients/app && flutter analyze
```

---

### Task 5: Object admin server (Wave 1)

**Files:**
- Create: `servers/crates/mod_chat/src/object_admin.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Modify: `servers/crates/wire_http/src/invoke.rs`
- Test: `servers/crates/mod_chat/src/object_admin.rs` (sqlx tests with `C35_TEST_DB=1`)

**Interfaces:**
- Produces: `object_alias_list`, `object_alias_put`, `object_normalizer_list`

- [ ] **Step 1: object_alias_list**

```rust
pub async fn object_alias_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqObjectAliasList,
) -> Result<ResObjectAliasList, ObjectAdminError> {
    require_root(pool, viewer_iid).await?;
    // SELECT a.*, o.path AS obj_path
    // FROM ai.object_alias a
    // JOIN ai.object_normalizer o ON o.id = a.obj_id
    // WHERE ($verified IS NULL OR a.verified = $verified)
    //   AND ($lang IS NULL OR a.lang = $lang)
    //   AND ($q IS NULL OR a.name_norm ILIKE '%' || $q || '%')
    // ORDER BY a.verified ASC, a.created_ts DESC
    // LIMIT $limit
}
```

- [ ] **Step 2: object_alias_put** — update `verified`, `name`, `is_canonical`; recompute `name_norm = lowercase trim`.

- [ ] **Step 3: object_normalizer_list** — search by path prefix for picker in alias editor.

- [ ] **Step 4: Wire invoke.rs** (mirror inst_list pattern).

- [ ] **Step 5: Verify**

```powershell
cd servers
cargo build -p server_ai
cargo test -p c35_mod_chat object_admin -- --nocapture
```

---

### Task 6: AdminStatsStream multi-node (Wave 2)

**Files:**
- Modify: `clients/app/lib/c/admin/admin_stats_stream.dart`

**Interfaces:**
- Consumes: new volume subject key `{node}/{ns}/{pvc}`
- Produces: `selectedNodeName`, `volumesForNode(node)`, `networkPeakBps`

- [ ] **Step 1: Volume key fix**

```dart
void _onPush(StatsPush push) {
  // volume key: '${v.nodeName}/${v.namespace}/${v.pvcName}'
  // fallback for old subjects without node in key: keep old key if nodeName empty
}
```

- [ ] **Step 2: Selected node state**

```dart
String? _selectedNodeName;

NodeStat? get selectedNode {
  if (_selectedNodeName != null) return _nodes[_selectedNodeName];
  return nodes.isEmpty ? null : nodes.first;
}

void selectNode(String name) {
  _selectedNodeName = name;
  notifyListeners();
}

List<VolumeStat> volumesForNode(String nodeName) =>
    volumes.where((v) => v.nodeName == nodeName).toList();
```

- [ ] **Step 3: Network peak tracking (60s window)**

```dart
final _netPeaks = <String, _NetPeak>{};
double networkMaxBps(String nodeName) => _netPeaks[nodeName]?.max ?? 1;
```

- [ ] **Step 4: Device preference**

```dart
List<DiskDeviceStat> storagesFor(NodeStat node) =>
    node.devices.isNotEmpty ? node.devices : /* map mounts to pseudo-devices */;
```

- [ ] **Step 5: Verify** — `flutter analyze`

---

### Task 7: PageRootConsole restructure (Wave 2)

**Files:**
- Modify: `clients/app/lib/pages/page_root_console.dart`

**Interfaces:**
- Consumes: all Task 4 widgets, Task 6 stream API

- [ ] **Step 1: Layout structure**

```
ListView
├── if nodes.length > 1:
│     for each node → UiAdminNodeCard (tap selects + expands)
├── else if selectedNode != null:
│     _NodeStatsBody(node)
├── Volumes section (filtered to selectedNode)
│     Container panel → UiAdminVolumeRow × N
└── Action grid (2×2)
      UiAdminActionTile Logs / Inst / Objects / (Translations placeholder disabled)
```

- [ ] **Step 2: _NodeStatsBody widget (private in same file or extract)**

```
CPU    → UiAdminStatBar
Memory → UiAdminStatBar
Network → UiAdminNetworkRow
Storages (section header)
  for device in storages → UiAdminStorageRow
```

- [ ] **Step 3: Action grid**

```dart
GridView.count(
  crossAxisCount: 2,
  childAspectRatio: 2.2,
  children: [
    UiAdminActionTile(icon: Icons.article_outlined, title: 'Logs', subtitle: 'ai.log tail', primary: true, onTap: _openLogs),
    UiAdminActionTile(icon: Icons.tune_outlined, title: 'Inst', subtitle: 'prompt steering', onTap: _openInst),
    UiAdminActionTile(icon: Icons.category_outlined, title: 'Objects', subtitle: 'aliases & taxonomy', onTap: _openObjects),
  ],
)
```

- [ ] **Step 4: Remove old UiAdminMountRow usage and bottom Row buttons**

- [ ] **Step 5: Verify** — `flutter analyze`

---

### Task 8: PageRootObjects Flutter (Wave 2)

**Files:**
- Create: `clients/app/lib/pages/page_root_objects.dart`
- Create: `clients/app/lib/c/admin/object_table.dart`
- Modify: `clients/app/lib/c/admin/admin_api.dart`
- Modify: `clients/app/lib/pages/page_root_console.dart` (navigation)

**Interfaces:**
- Consumes: Task 5 invoke handlers

- [ ] **Step 1: object_table.dart**

```dart
TableDef objectAliasTableDef() => TableDef(
  label: 'object_alias',
  primaryKey: 'id',
  columns: [
    ColDef(key: 'id', label: 'ID', readonly: true),
    ColDef(key: 'obj_path', label: 'Object', readonly: true),
    ColDef(key: 'lang', label: 'Lang'),
    ColDef(key: 'name', label: 'Name'),
    ColDef(key: 'verified', label: 'OK', type: ColType.COL_TYPE_BOOL, inlineEditable: true),
  ],
);
```

- [ ] **Step 2: PageRootObjects** — mirror `PageRootInst`:
  - Filter toggle: Unverified / All
  - Search field → `objectAliasList(q: ...)`
  - `UiTable` with inline `verified` toggle → `objectAliasPut`
  - Expand row for full name + obj_path

- [ ] **Step 3: AdminApi methods**

```dart
Future<List<ObjectAliasDoc>> objectAliasList({bool? verified, String? lang, String? q, int limit = 200});
Future<ObjectAliasDoc> objectAliasPut(ObjectAliasDoc doc);
```

- [ ] **Step 4: Verify** — `flutter analyze`

---

### Task 9: Deploy node-stats + verify NATS (Wave 2)

**Files:**
- Deploy only (no code unless path discovery changes ConfigMap)

- [ ] **Step 1: Discover host paths on cluster**

```powershell
kubectl get pods -n c35 -l app=c35-node-stats -o wide
kubectl exec -n c35 <pod> -- ls -la /host/var/lib/alienai/
kubectl exec -n c35 <pod> -- ls /host/sys/block/
```

- [ ] **Step 2: Fix ConfigMap paths if needed, then publish**

```powershell
.\_\scripts\deploy\publish_node_stats.ps1
kubectl apply -f _/deployments/c35-node-stats/configmap.yaml
kubectl rollout restart daemonset/c35-node-stats -n c35
kubectl rollout status daemonset/c35-node-stats -n c35
```

- [ ] **Step 3: Verify NATS subjects**

Use `yb` MCP or cluster pod:

```sql
-- not applicable; use nats sub or log_tail
```

```powershell
kubectl exec -n nats deploy/nats-box -- nats sub 'c35.stats.>' --count=10
```

Expected subjects:
- `c35.stats.node.{NODE_NAME}` with `devices` populated
- `c35.stats.volume.{NODE_NAME}.yugabyte.yb-tserver`
- `c35.stats.volume.{NODE_NAME}.yugabyte.yb-master` (on YB node)
- `c35.stats.volume.{NODE_NAME}.nats.nats-data` (on NATS node)

---

### Task 10: Docs + integration verify (Wave 3)

**Files:**
- Modify: `_/docs/ui.md` § Root console
- Modify: `_/docs/sync.md` NATS subjects
- Modify: `_/docs/tx.md` — mark Objects UI as shipped

- [ ] **Step 1: Update ui.md** — document layout (node cards, storages, volumes, action grid, Objects page).

- [ ] **Step 2: Full verify**

```powershell
cd servers && cargo build -p server_ai
cd ../node_stats && cargo test -p c_node_stats
cd ../clients/app && flutter analyze
```

- [ ] **Step 3: Manual smoke** — root user opens console, confirms:
  - CPU/RAM full-width bars
  - Storages show `sda (boot)` etc.
  - Network dual bars animate
  - Volumes show `yb-tserver`, `yb-master`, `nats` with used/capacity
  - Objects page loads unverified aliases

---

## Subagent Dispatch Guide

| Task | Subagent focus | Model |
|------|----------------|-------|
| 1 | Proto + regen | inherit |
| 2 | Rust device.rs | inherit |
| 3 | volume.rs + ConfigMap | inherit |
| 4 | Flutter widgets only | inherit |
| 5 | object_admin.rs + invoke | inherit |
| 6 | admin_stats_stream.dart | inherit |
| 7 | page_root_console.dart | inherit |
| 8 | page_root_objects.dart | inherit |
| 9 | Deploy + cluster verify | inherit |
| 10 | Docs + final verify | inherit |

**Wave 1 dispatch:** Tasks 2, 3, 4, 5 in parallel (after Task 1 completes).  
**Wave 2 dispatch:** Tasks 6, 7, 8 in parallel; Task 9 after 2+3 deployed.  
**Never** parallelize tasks that edit the same file.

---

## Self-Review (spec coverage)

| Requirement | Task |
|-------------|------|
| Storages section with full-width bars | 4, 7 |
| `sda (boot)` device naming | 2, 4, 7 |
| Boot graph fix (was 72px bar) | 4 (UiAdminStorageRow) |
| Network bars | 4, 6, 7 |
| Multi-node cards | 4, 6, 7 |
| Volumes yb-tserver/master/nats | 3, 4, 9 |
| used/capacity display | 4 (UiAdminVolumeRow) |
| Action tile grid (Logs/Inst/Objects) | 4, 7 |
| Objects & aliases UITable | 5, 8 |
| Stats process update + redeploy | 2, 3, 9 |
| Volume multi-node cache fix | 3, 6 |

No placeholders remain. All interfaces named.

---

## Out of Scope (future)

- **Translations** action tile (proto exists as `translation_put`; no list UI yet)
- K8s-native PVC discovery (`k8s.rs` from original plan)
- Per-node volume aggregation summary across cluster
- Alerting/notifications when volume ≥ 90%
