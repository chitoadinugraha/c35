# Root console — block device cleanup (broom)

Root-only actions from the **Stats dashboard** block-device rows. Each row already shows `sda (Boot)`, `sdb (yugabyte)`, `sdc (buildkit)` via `c35-node-stats` labels ([`_/deployments/c35-node-stats/README.md`](../deployments/c35-node-stats/README.md)).

Related: [ui.md](ui.md) (Root console), [server.md](server.md) (stateful inventory), [storage.md](../deployments/storage.md), [`cleanup_buildkit.ps1`](../scripts/deploy/cleanup_buildkit.ps1).

## UI

| Rule | Detail |
|------|--------|
| Placement | **Small broom** immediately after the block device title text (`sda (Boot)`), same row as today — do not change bar layout or IO column. |
| Control | `IconButton` or `InkWell` + `Icons.cleaning_services`, **size 14–16**, color `adminMuted`; slightly brighter on hover/press. |
| Visibility | Show broom only when `label` normalizes to `Boot`, `yugabyte`, or `buildkit` (match `node_stats` `normalize_disk_label` / `pick_disk_label`). Hide for unknown disks and **nats** (JetStream is `emptyDir` on boot — use Boot janitor, not a separate broom). |
| Flow | Tap → confirm dialog (action-specific copy) → WS invoke → progress snackbar → optional result sheet (`df` summary, log tail). |
| Errors | Surface server message; never claim success without `ok: true` in response. |

## Wire (target)

Root RBAC: `require_root` on handler (same as `admin_log_list`, `ReqRootConsole`).

```protobuf
enum AdminDiskCleanKind {
  ADMIN_DISK_CLEAN_UNSPECIFIED = 0;
  ADMIN_DISK_CLEAN_BOOT = 1;
  ADMIN_DISK_CLEAN_YUGABYTE = 2;
  ADMIN_DISK_CLEAN_BUILDKIT = 3;
}

message ReqAdminDiskClean {
  string node_name = 1;       // k8s node (from NodeStat.node_name)
  AdminDiskCleanKind kind = 2;
  bool full = 3;              // buildkit: prune all vs default retention; boot: unused for v1
}

message AdminDiskCleanStep {
  string name = 1;
  string detail = 2;
  bool ok = 3;
}

message ResAdminDiskClean {
  bool ok = 1;
  string message = 2;
  repeated AdminDiskCleanStep steps = 3;
  // Optional post-clean usage on affected mount (bytes).
  optional uint64 used_bytes_after = 4;
  optional uint64 total_bytes_after = 5;
}
```

Register on `WireReq` / `WireRes` (next free field ids — see `wire.proto`). Flutter: `adminDiskClean` on `AdminApi`.

Audit: one `ai.log` row per invocation (`class=admin`, `topic=disk_clean`, `meta_json`: node, kind, steps).

## Action matrix

| Kind | Disk row | What runs | Downtime |
|------|----------|-----------|----------|
| **Boot** | `sda (Boot)` | Allowlisted host janitor on **that node only** | No planned outage; brief I/O on `/` |
| **yugabyte** | `sdb (yugabyte)` | In-cluster YB maintenance (logs + optional compaction) | No stop; possible latency / I/O spike |
| **buildkit** | `sdc (buildkit)` | `buildctl prune` on cluster buildkit (same policy as script) | No cluster outage; next publish slower if full wipe |

Server resolves **kind** from the request; UI passes kind derived from row `label` + `is_boot` (boot wins when `is_boot == true`).

---

## Boot volume (`ADMIN_DISK_CLEAN_BOOT`)

**Scope:** host filesystem where `mount == "/"` (boot disk). **Never** delete under PVC mount paths (`/mnt/disk0`, kubelet volumes, `/var/lib/kubelet`, `/var/lib/rancher`, `/etc`, `/usr`, `/boot` contents).

### Allowlist (v1 steps)

Execute in order; each step is idempotent and logged in `AdminDiskCleanStep`.

| Step | Command / action | Notes |
|------|------------------|-------|
| `journal_vacuum` | `journalctl --vacuum-time=7d` (or `--vacuum-size=500M` if time vacuum frees &lt; 50MiB) | Primary win on Ubuntu OKE workers |
| `log_rotated` | Remove `*.gz` and `*.[0-9]` under `/var/log` older than 14d; **do not** truncate active `*.log` without `logrotate` |
| `tmp_stale` | Delete files under `/tmp` and `/var/tmp` with mtime &gt; 7d; skip `systemd-private-*` trees |
| `apt_cache` | `apt-get clean` if `apt` exists |
| `cri_images` | `crictl rmi --prune` (or k3s wrapper) — **unused images only** |

### Execution model

- One-shot **Job** per target node: `c35-node-janitor` image or `busybox` + mounted host root at `/host`, `chroot /host` or path-prefix `/host/...`.
- Job `nodeSelector` / `affinity` pins to `req.node_name`.
- Job TTL 10m; RBAC: `c35-server` ServiceAccount may `create` Job in `c35` ns (not cluster-admin).

### Safe to skip / never automate

- `docker system prune` on live kubelet socket without crictl semantics
- Anything under `/var/lib/kubelet/pods`
- Shrink YB or buildkit block volumes from the boot job

---

## Yugabyte volume (`ADMIN_DISK_CLEAN_YUGABYTE`)

**Scope:** data on PVC `yb-data` (tserver/master subPaths). **Never** `rm -rf` on `/mnt/disk0` or host paths backing `yb-data`.

### Yugabyte compaction and downtime

| Question | Answer |
|----------|--------|
| Compaction without stopping YB? | **Yes.** DocDB/RocksDB compaction is online background work. |
| Effect on users? | Extra disk I/O and possible **temporary latency** on a single-node cluster; no rolling restart required. |
| What frees space after deletes? | Compaction (and YB TTL/GC where configured) — not manual file deletion. |

### v1 steps (two-tier UI)

**Default (broom, single confirm):**

| Step | Action |
|------|--------|
| `yb_log_cleanup` | `kubectl exec -n yugabyte yb-tserver-0 -c yb-tserver -- /mnt/disk0/yb-data/scripts/log_cleanup.sh` (fallback: image `/home/yugabyte/bin/log_cleanup.sh` with data dir env) |

**Deep clean (second dialog or “Compact database” checkbox with strong warning):**

| Step | Action |
|------|--------|
| `yb_compact` | `yb-admin` compact against local master (exact flags per deployed YB version — document in deploy README). Prefer **off-peak**; timeout 30–60m. |

If tserver pod is not on `req.node_name`, return `ok: false` with “YB not on this node” (single-node cluster: always co-located).

---

## Buildkit volume (`ADMIN_DISK_CLEAN_BUILDKIT`)

Align with [`cleanup_buildkit.ps1`](../scripts/deploy/cleanup_buildkit.ps1):

| `full` | Prune |
|--------|--------|
| `false` | `buildctl prune --all --keep-duration 168h` |
| `true` | `buildctl prune --all --keep-duration 0s` |

Flow:

1. `Ensure-Buildkit` (scale deployment to 1 if scaled to 0).
2. Exec prune in build namespace pod.
3. `Stop-Buildkit` (scale to 0) after success — same as script.

### Running buildkit warning

Before prune, if **any** `buildkit` pod in `build` ns is `Running` and `Ready`:

- Flutter shows **alert dialog**: in-flight cluster image builds may fail or slow; confirm **Prune anyway** / **Cancel**.
- Optional server-side: reject without `force: true` if pod has label `c35.io/build-active=true` (future); v1 UI confirm is enough.

Buildkit cache PVC is expendable ([storage.md](../deployments/storage.md)).

---

## Security

| Item | Rule |
|------|------|
| Caller | Root identity only (`require_root`). |
| Target | `node_name` must match a node present in latest stats snapshot (or kube node list) — no arbitrary hostnames. |
| Rate limit | Max 1 concurrent clean per `(node_name, kind)`; reject duplicate with `already_running`. |
| Secrets | No kubeconfig in client; server uses in-cluster credentials. |

---

## Verification (manual)

| Kind | Check |
|------|--------|
| Boot | Root console boot % drops or stable; `df -h /` on node; no pod evictions |
| YB | `ysqlsh` smoke; disk % on yugabyte row; YB logs show cleanup/compaction |
| Buildkit | `cleanup_buildkit.ps1` equivalent; publish once after full prune |

Automated: unit tests for label→kind mapping (Dart + Rust); integration optional with mocked kube.
