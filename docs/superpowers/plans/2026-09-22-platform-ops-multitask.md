# Platform ops multitask — master checklist

**Date:** 2026-09-22  
**Use:** Review patches before dispatching parallel subagents.

> **Track F + G:** IMPLEMENTED 2026-09-22 — `c35-server` HA (2 replicas, safe rolling update, downward API env) + docs (`ui.md`, `site.md`, `server.md`, `sync.md`).

Related: [`2026-09-22-root-console-node-stats.md`](2026-09-22-root-console-node-stats.md)

---

## What is Root Console?

**Root console** = root-only **ops screen inside the Flutter app** (opened from avatar menu when you have the Root badge). It is **not** a public page on `alienai.id`.

| Section | Purpose |
|---------|---------|
| **Stats dashboard** | See node CPU/RAM/disk IO, YB disk, NATS JetStream disk — know when to resize/cleanup **before** outage |
| **Logs** (button → page) | Search/tail `ai.log` per user, date, text; live via NATS |
| **Inst** (button → page) | Edit `ai.inst` rows in UITable (prompt steering) without MCP |

Audience: **you (root admin)** only. Regular users never see it.

---

## Multitask map (7 tracks)

Execute **Track A + B** first (routing + NATS persist). **C–G** can parallelize after proto (Track D.1).

| Track | Name | Depends on | Delivers |
|-------|------|------------|----------|
| **A** | Ingress + DNS split | — | `api.alienai.id` for app; `alienai.id` for guest/home |
| **B** | NATS JetStream PVC | — | Durable JS store for future task triggers |
| **C** | `c35-node-stats` DaemonSet | — | NATS push: node + volume metrics |
| **D** | Server admin wire | A (api host) | WS fanout stats/logs; `admin_log_list` |
| **E** | Flutter root console | D | Dashboard + Logs + Inst pages |
| **F** | `c35-server` HA | A | 2 replicas, rolling update safe |
| **G** | Docs | all | sync.md, site.md, server.md, deploy READMEs |

---

## Track A — Ingress + DNS (`alienai.id` → c35, not CSA)

### Goal

- `alienai.id` `/` + `/{alien_id}` → **c35-server** (home stub + guest sites)
- `api.alienai.id` `/v1`, `/a`, `/ws`, `/fs` → **c35-server** (app API, grey CF)
- Remove CSA catch-all on `alienai.id` `/`

### Patches (repo)

| File | Change |
|------|--------|
| `_/deployments/c35-server/ingress.yaml` | Split or extend: host `api.alienai.id` (API paths); host `alienai.id` add `/` Prefix + guest catch-all `/{path}` or single Prefix `/` to c35; TLS secret covers both hosts |
| `_/deployments/c35-server/ingress-api.yaml` | *(optional)* second Ingress resource if cleaner |
| `clients/app/lib/c/conn/server_host.dart` | `serverHostProductionUrl` → `https://api.alienai.id` |
| `clients/app/lib/c/config.dart` | `authApiProductionUrl` → `https://api.alienai.id` |
| `servers/crates/mod_site/src/http.rs` | `RESERVED` + `host_is_primary`: treat `api.alienai.id` as non-guest; never resolve as `alien_id` |
| `_/scripts/deploy/publish_server.ps1` | Smoke `api.alienai.id/livez` |
| `_/docs/site.md` | Mark API split as implemented |

### Patches (cluster / Cloudflare — not in git)

| Action | Detail |
|--------|--------|
| CF DNS | `api.alienai.id` A → `168.110.219.43`, **proxied: false** |
| CF DNS | `alienai.id` → same IP, **proxied: true** when ready for CDN |
| CSA ingress | `csa-ingress` — remove `alienai.id` `/` rule OR lower priority so c35 wins |
| Traefik priority | c35 `alienai.id` `/` priority > CSA; keep c35 `/v1`/`/a` on api host |

### Verify

```powershell
curl https://api.alienai.id/livez
curl https://alienai.id/          # c35 home stub, not CSA
curl https://alienai.id/{test_alien_id}  # guest site when published
# Flutter app: WS connects to api.alienai.id/v1/ws
```

---

## Track B — NATS JetStream on PVC

### Current (cluster)

- `nats-0` in `nats` ns
- JetStream: `/data/jetstream`, **emptyDir 10Gi** — **lost on pod restart**

### Goal

- `volumeClaimTemplates` on NATS StatefulSet → PVC (e.g. 20Gi `oci-bv`)
- JetStream data survives reschedule

### Patches

| Location | Change |
|----------|--------|
| **Cluster** (helm values or StatefulSet patch) | Replace `emptyDir` `nats-data` with `persistentVolumeClaim`; `storageClassName: oci-bv`; size 20Gi |
| `_/deployments/nats/` | **(new)** manifest or README documenting desired StatefulSet volume block + upgrade steps |
| `_/docs/server.md` | NATS persistence note; JS used for c35 task triggers (future) |

### Upgrade caution

- One-time: backup `/data/jetstream` if any data matters; scale carefully; may need manual copy into new PVC on first migrate.

### Verify

```powershell
kubectl get pvc -n nats
kubectl exec -n nats nats-0 -- du -sh /data/jetstream
# restart pod — data still present
```

---

## Track C — `c35-node-stats` DaemonSet

### Goal

- 1 pod per k8s node; publish `c35.stats.*` on NATS every 2s
- Monitor: node OS (`/`, `/var/log`), **YB hostPath** `/var/lib/alienai/yb-tserver`, **NATS** jetstream mount (after PVC: via path or volume stats)

### New files

```
node_stats/c_node_stats/          # Rust binary
_/deployments/c35-node-stats/
  daemonset.yaml
  rbac.yaml
  configmap.yaml
  README.md
_/schemas/proto/c35/stats.proto
```

### Verify

```powershell
nats sub 'c35.stats.>' --count=3
```

---

## Track D — Server admin wire

### Patches

| File | Change |
|------|--------|
| `_/schemas/proto/c35/stats.proto` | `StatsPush`, subscribe messages |
| `_/schemas/proto/c35/wire.proto` | WsReq/WsRes + Invoke `admin_log_list` |
| `servers/crates/mod_admin/src/log_admin.rs` | **(new)** root SQL log query |
| `servers/crates/wire_ws/src/session.rs` | `stats_subscribe` + `log_subscribe` NATS fanout |
| `servers/crates/wire_http/src/invoke.rs` | `admin_log_list` |
| `_/docs/sync.md` | NATS subjects |

### Verify

```powershell
cd servers && cargo build -p server_ai && cargo test -p c35_mod_admin
```

---

## Track E — Flutter root console

### Patches

| File | Change |
|------|--------|
| `clients/app/lib/pages/page_root_console.dart` | **(new)** stats dashboard + action buttons |
| `clients/app/lib/pages/page_root_logs.dart` | **(new)** search, user, date range, live tail |
| `clients/app/lib/pages/page_root_inst.dart` | **(new)** UITable inst CRUD |
| `clients/app/lib/c/admin/admin_api.dart` | **(new)** |
| `clients/app/lib/c/admin/admin_stats_stream.dart` | **(new)** |
| `clients/app/lib/c/admin/admin_log_stream.dart` | **(new)** |
| `clients/app/lib/widgets/admin/*` | **(new)** stat bars, log table |
| `clients/app/lib/widgets/ui/ui_account_menu.dart` | Root badge + Admin row |
| `clients/app/lib/pages/page_ai_home.dart` | Wire `onRootConsole` |
| `_/docs/ui.md` | Root console section |

### Verify

```powershell
cd clients/app && flutter analyze
```

---

## Track F — `c35-server` HA

- [x] `_/deployments/c35-server/deployment.yaml` — `replicas: 2`, `maxUnavailable: 0`, `maxSurge: 1`, `NODE_NAME`/`POD_NAME` env

---

## Track G — Docs

- [x] `_/docs/site.md` — API split implemented
- [x] `_/docs/server.md` — node-stats, NATS PVC, stateful inventory, 2 replicas
- [x] `_/docs/ui.md` — Root console
- [x] `_/docs/sync.md` — `c35.stats.*` subjects + admin log subscribe

---

## Stateful inventory (for dashboard)

| Monitor | Path / source | Action when high |
|---------|---------------|------------------|
| Node boot disk | `/` on host | cleanup logs, resize node disk |
| Node logs | `/var/log` | rotate, truncate |
| YB data | `/var/lib/alienai/yb-tserver` | expand disk, add tserver |
| NATS JetStream | PVC `/data/jetstream` | expand PVC, prune streams |
| c35 CAS | emptyDir (ephemeral) | move to PVC later if needed |

**Stateless (no volume row):** c35-server, whatsapp-device worker, coturn.

---

## Suggested dispatch order

```
Wave 1 (parallel):  A, B, C.1 (proto only for C if needed)
Wave 2 (parallel):  C.2 (node-stats binary+deploy), D, F
Wave 3:             E (Flutter, needs D)
Wave 4:             G
```

---

## File count summary

| Area | New | Modified |
|------|-----|----------|
| Ingress/DNS/Flutter host | 0–1 | ~6 repo + CF + CSA cluster |
| NATS PVC | 1 dir | cluster StatefulSet |
| node-stats | ~10 | 0 |
| Server wire | 2–3 | ~5 |
| Flutter root | ~12 | ~3 |
| HA deploy | 0 | 1 |

**Total repo touch:** ~35 files (many new under `node_stats/`, `widgets/admin/`, `pages/page_root_*`).
