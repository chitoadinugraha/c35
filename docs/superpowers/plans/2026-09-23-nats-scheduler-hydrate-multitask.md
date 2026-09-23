# NATS 2.15 Upgrade, JetStream Hydrate & Scheduled Tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade NATS to a maintained 2.x line with recurring message schedules; drop the 50Gi NATS PVC; make YugabyteDB the sole durable store; use JetStream (no persistence) + YB hydrate on recovery; wire cron `task_trigger` via NATS schedules (no YB dispatch poller); support multi-pod `c35-server` with single-leader hydrate.

**Architecture:**

```text
YB (truth)                         NATS (runtime, ephemeral OK)
──────────                         ─────────────────────────────
ai.task_trigger          ──sync──►  C35_TASK_SCHEDULE stream
  cron_expr, timezone                 c35.schedule.task.{trigger_id}
                                      Nats-Schedule + Target

NATS fires ──► c35.task.fire.{trigger_id}
                 └─► server worker (queue group)
                       INSERT ai.task_run (queued)
                       JetStream publish C35_DEVICE_TASK

ai.prompt_run / ai.task_run (queued) ──hydrate on recovery──► JetStream work queues
```

**Tech Stack:** NATS Server 2.15-alpine, Rust (`system/nats`, new `mod_nats_hydrate` or `mod_task` + `mod_chat`), `async_nats` (schedule headers), YugabyteDB advisory locks, k3s-btm manifests under `_/deployments/nats/`.

## NATS version (locked for this plan)

| Version | Status (2026-09) | Schedules |
|---------|------------------|-----------|
| **2.15** | **Latest** — use this | One-shot `@at` + recurring `@every` / cron / `@hourly` |
| 2.14 | Maintained — OK minimum | Recurring cron added in 2.14 |
| 2.12 | **EOL** — current cluster image | One-shot `@at` only; no recurring cron |

**Deploy target:** `nats:2.15-alpine` (not “v14/v15” — NATS minors are **2.14**, **2.15**).

| Feature | Min server |
|---------|------------|
| `allow_msg_schedules` (one-shot) | 2.12 |
| Recurring cron / `@every` | **2.14+** |
| Production deploy | **2.15** (latest maintained line) |

## Global constraints

- Read `spec.md`, `_/docs/remote.md`, `_/docs/sync.md`, `_/deployments/storage.md` before coding.
- **YB = source of truth.** NATS schedules and JetStream queues are disposable; hydrate rebuilds them.
- **No periodic `SELECT … WHERE status='queued'` sweeper** (locked in `remote.md`). Hydrate is **event-driven**: boot, NATS reconnect, agent hello, lease timeout, manual replay.
- **One hydrator per recovery:** `pg_try_advisory_lock` (YB); not “every pod hydrates dispatch.”
- NATS storage: `emptyDir` or boot `hostPath` `/var/lib/alienai/nats/jetstream` — **no `oci-bv` PVC**.
- Verify: `cargo build -p server_ai`; `cargo test -p mod_chat` / `mod_task` when tests added.
- Do not commit unless user asks.

---

## Multitask map

```text
Track 0 (NATS upgrade + streams)  ──┬──► Track 2 (hydrate module)
                                    ├──► Track 3 (schedule stream + sync)
                                    └──► Track 5 (ops docs)

Track 1 (async_nats + reconnect)  ──► Track 2
Track 2 (hydrate)                 ──► Track 4 (task fire handler)
Track 3 (schedule CRUD sync)      ──► Track 4
Track 0 + Track 3                 ──► Track 4

Track 4 (mod_task schedules)      ──► Track 6 (Flutter — optional if UI already in 2026-09-21-tasks)
All                               ──► Track 7 (verify + doc lock)
```

| Track | Focus | Est. | Depends |
|-------|-------|------|---------|
| **0** | NATS 2.15 image, drop PVC, stream configs, `allow_msg_schedules` | 2h | — |
| **1** | `system/nats` reconnect watcher, connection state in `AppState` | 1.5h | — |
| **2** | `nats_hydrate` — advisory lock, boot + reconnect, prompt + task replay | 3h | 0, 1 |
| **3** | `C35_TASK_SCHEDULE` stream bootstrap, schedule publish/cancel helpers | 2h | 0 |
| **4** | `mod_task`: trigger CRUD → NATS sync; fire handler → `task_run` + dispatch | 4h | 2, 3 |
| **5** | `_/deployments/nats/`, `storage.md`, node-stats volume paths | 1h | 0 |
| **6** | Flutter trigger save → server sync (if not done in tasks plan) | 1h | 4 |
| **7** | Integration tests, `remote.md` / `sync.md` updates, rollout checklist | 2h | all |

**Parallel wave 1:** Tracks 0 + 1 + 5  
**Parallel wave 2:** Tracks 2 + 3  
**Parallel wave 3:** Track 4  
**Parallel wave 4:** Tracks 6 + 7  

---

## NATS subjects & streams (locked)

### Existing (unchanged)

| Stream | Subject(s) | Retention | Queue group |
|--------|------------|-----------|-------------|
| `C35_CHAT_PROMPT` | `c35.prompt.run` | WorkQueue | `c35-prompt-dispatch` |
| `C35_DEVICE_TASK` | `c35.act.device.*.task.run` | WorkQueue | `c35-task-dispatch` |

### New — schedules

| Stream | Purpose | Config |
|--------|---------|--------|
| `C35_TASK_SCHEDULE` | Holds schedule config messages | `allow_msg_schedules: true`, `allow_msg_ttl: true`, subjects below |

| Subject pattern | Role |
|-----------------|------|
| `c35.schedule.task.{trigger_id}` | Schedule config (rollup per subject) |
| `c35.schedule.task.{trigger_id}.stop` | Cancel schedule (or publish `Nats-Schedule-Next: purge`) |
| `c35.task.fire.{trigger_id}` | **Target** — fired tick lands here |
| `c35.task.fire.>` | Consumer filter for fire handler |

Schedule publish (conceptual):

```text
Nats-Schedule:        0 0 9 * * *          # 6-field cron, sec first
Nats-Schedule-Time-Zone: Asia/Jakarta
Nats-Schedule-Target: c35.task.fire.{trigger_id}
Nats-Schedule-TTL:    24h                  # auto-purge fired ticks (stream allow_msg_ttl)
```

Payload on schedule subject: minimal JSON `{ "trigger_id", "task_id", "owner_iid", "device_iid" }` (YB is authoritative; payload is hint only).

### Core pub/sub (unchanged)

Live fanout, log tail, stats, inst invalidation — **core NATS only**, no persistence.

---

## Track 0 — NATS upgrade & deployment

### Task 0.1: Bump server image

- [ ] `_/deployments/nats/statefulset.yaml`: `nats:2.12-alpine` → `nats:2.15-alpine`
- [ ] Verify `nats.conf` JetStream enabled; store dir `/data/jetstream`
- [ ] Rollout: `kubectl rollout restart statefulset/nats -n nats`

### Task 0.2: Remove NATS PVC (ephemeral store)

- [ ] Replace `volumeClaimTemplates` with `emptyDir` **or** boot `hostPath`:

```yaml
# Option A — emptyDir (simplest; hydrate required every pod delete)
- name: nats-data
  emptyDir: {}

# Option B — boot disk (survives pod restart, not node replace)
- name: nats-data
  hostPath:
    path: /var/lib/alienai/nats/jetstream
    type: DirectoryOrCreate
```

- [ ] Delete `nats-data-nats-0` PVC after migration (ops runbook in Track 5)
- [ ] Update `_/deployments/storage.md`: NATS row → boot/emptyDir, not `oci-bv`

### Task 0.3: Stream bootstrap on server boot

- [ ] Extend `prompt_jetstream_ensure` pattern or add `nats_streams_ensure()` in `system/nats` or `mod_task`:
  - `C35_CHAT_PROMPT` (existing)
  - `C35_DEVICE_TASK` (when `mod_task` lands)
  - `C35_TASK_SCHEDULE` with `allow_msg_schedules`, `allow_msg_ttl`, subject patterns

### Task 0.4: Smoke test NATS 2.15 schedules

- [ ] `kubectl exec -n nats nats-0 -- nats stream info C35_TASK_SCHEDULE`
- [ ] Manual publish test cron `@every 1m` → target subject receives tick

---

## Track 1 — NATS client reconnect

### Task 1.1: Connection supervisor

- [ ] `system/nats/src/lib.rs`: wrap client in `NatsHandle` with:
  - `connect()` + exponential backoff reconnect loop
  - `on_reconnect` callback channel (broadcast)
- [ ] `AppState` holds `NatsHandle` instead of bare `Option<Client>`

### Task 1.2: Wire reconnect in `server_ai`

- [ ] On reconnect event → spawn hydrate (Track 2) — all pods try lock, one wins
- [ ] Log: `[c35:nats] reconnected — hydrate scheduled`

---

## Track 2 — YB hydrate (single leader)

### Task 2.1: Advisory lock constants

- [ ] `mod_nats_hydrate` crate (or `system/nats/hydrate.rs`):

```rust
// pg advisory lock keys (two int4 args)
pub const HYDRATE_LOCK_K1: i32 = 0xC35;
pub const HYDRATE_LOCK_K2: i32 = 0x4E41; // 'NA'
```

### Task 2.2: `nats_hydrate_run(pool, nats) -> Result<bool>`

- [ ] `SELECT pg_try_advisory_lock($1, $2)` — return `false` if not acquired
- [ ] **Schedules:** `SELECT id, task_id, owner_iid, device_iid, cron_expr, timezone FROM ai.task_trigger WHERE kind='cron' AND is_active AND deleted_ts IS NULL`
  - For each → `task_schedule_publish(js, row)` (Track 3)
- [ ] **Dispatch replay:**
  - `SELECT req_id FROM ai.prompt_run WHERE status='queued'`
  - `SELECT id, device_iid, … FROM ai.task_run WHERE status='queued'`
  - Republish with JetStream dedup: `Nats-Msg-Id` = `req_id` / `run:{id}`
- [ ] `pg_advisory_unlock` in finally block
- [ ] Log counts: `hydrate schedules=N replay_prompt=M replay_task=K`

### Task 2.3: Triggers

| Event | Caller |
|-------|--------|
| `server_ai` main after NATS first connect | `main.rs` |
| NATS reconnect (Track 1) | reconnect callback |
| Manual admin RPC (optional v1) | `InvokeReq.nats_hydrate` root-only |

### Task 2.4: Tests

- [ ] Unit test: lock not acquired → hydrate skipped (mock pool or `C35_TEST_DB=1`)
- [ ] Unit test: idempotent schedule publish called N times with same trigger_id

---

## Track 3 — Schedule publish helpers

### Task 3.1: `task_schedule_publish(js, trigger_row)`

- [ ] Map `cron_expr` + `timezone` → `Nats-Schedule` header (6-field cron)
- [ ] Subject: `c35.schedule.task.{trigger_id}`
- [ ] Target: `c35.task.fire.{trigger_id}`
- [ ] Use `async_nats` JetStream publish with schedule headers (or raw headers if crate version requires)

### Task 3.2: `task_schedule_cancel(js, trigger_id)`

- [ ] Publish to stop subject or `Nats-Schedule-Next: purge` per ADR-51

### Task 3.3: One-shot `task_trigger.kind=once`

- [ ] `Nats-Schedule: @at {run_at_rfc3339}` instead of cron
- [ ] After fire: server marks trigger inactive or deletes schedule

---

## Track 4 — mod_task integration

> Builds on [2026-09-21-tasks.md](./2026-09-21-tasks.md) Track 1. Skip duplicate CRUD; add schedule + fire paths.

### Task 4.1: `task_trigger_put` → YB then NATS

- [ ] After UPSERT `ai.task_trigger`:
  - `kind=cron` + `is_active` → `task_schedule_publish`
  - `is_active=false` or soft delete → `task_schedule_cancel`
- [ ] Transaction order: **YB commit first**, then NATS (if NATS fails, row exists — hydrate will fix)

### Task 4.2: Fire handler worker

- [ ] New queue group: `c35-task-schedule-fire`
- [ ] Subscribe JetStream consumer on `c35.task.fire.>` (pull, explicit ack)
- [ ] On message:
  1. Load `task_trigger` from YB by `trigger_id`; exit if inactive/deleted
  2. `INSERT ai.task_run` (`status=queued`)
  3. JetStream publish `ActDeviceTaskRun` → `C35_DEVICE_TASK`
  4. `TaskRunPush` fanout (core NATS)
  5. Ack

### Task 4.3: Recovery paths (no poller)

- [ ] Agent `EvDeviceAgentHello` → republish `queued` for that `device_iid` (existing spec)
- [ ] Lease timeout → republish same `run_id` (existing spec)
- [ ] Do **not** add periodic queued sweeper

### Task 4.4: `task_run_replay` RPC

- [ ] Root or owner: republish single run or all `queued` for device

---

## Track 5 — Ops & manifests

### Task 5.1: Update deployment docs

- [ ] `_/deployments/nats/README.md` — 2.15, no PVC, hydrate note
- [ ] `_/deployments/storage.md` — remove NATS PVC row
- [ ] `_/deployments/c35-node-stats/README.md` — NATS path = hostPath or drop volume monitor

### Task 5.2: Rollout runbook

```powershell
# 1. Deploy server with hydrate code FIRST (tolerates empty NATS)
# 2. Upgrade NATS image + remove PVC
# 3. Restart server pods → leader hydrates schedules + queued runs
kubectl rollout restart deploy/c35-server -n c35
kubectl exec -n nats nats-0 -c nats -- nats stream ls
```

---

## Track 6 — Flutter (if needed)

- [ ] `ReqTaskPut` already sends triggers — no client change if server syncs NATS
- [ ] Show `next_fire` hint from server optional field (computed from cron, not from NATS)

---

## Track 7 — Docs & verify

### Task 7.1: Doc updates

- [ ] `_/docs/remote.md` — replace “Forbidden sweeper” nuance: hydrate ≠ poller; add NATS schedule flow
- [ ] `_/docs/sync.md` — `C35_TASK_SCHEDULE` subjects
- [ ] `_/docs/server.md` — NATS 2.15, no PVC, hydrate owner = `c35-server`

### Task 7.2: Verify checklist

- [ ] `cd servers && cargo build -p server_ai`
- [ ] `cargo test -p mod_chat` (hydrate tests)
- [ ] Create cron trigger → verify `nats stream info` shows schedule subject
- [ ] Delete NATS pod → restart server → leader hydrates → cron still fires
- [ ] Scale `c35-server` to 3 replicas → single hydrate log line per recovery
- [ ] Prompt `queued` row survives NATS pod delete → replayed once (dedup)

---

## Multi-pod hydrate (reference)

```text
server_ai-0 ──try lock──► acquired ──hydrate──► unlock
server_ai-1 ──try lock──► busy ──skip
server_ai-2 ──try lock──► busy ──skip

All pods: JetStream queue consumers (normal work)
One pod:  hydrate per NATS recovery event
```

## Multi-NATS-node (future, out of scope v1)

| Setup | 1 NATS node dies |
|-------|------------------|
| 1 replica, no disk | Outage; YB hydrate when back |
| 3-node JS cluster, R=3, file store | Quorum OK; no hydrate needed for schedules |
| 3 core + 1 JS | JS node is still SPOF unless clustered |

v1 ships **single NATS + YB hydrate**. Cluster HA is a later ops track.

---

## Decision log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| NATS version | **2.15** | Latest maintained; recurring cron since 2.14 |
| NATS persistence | **None** (emptyDir/hostPath) | OCI 50Gi min; YB hydrate |
| Cron scheduler | **NATS schedules** | No YB `next_run_at` poller |
| Hydrate leader | **YB advisory lock** | Already have YB; no K8s Lease dep |
| JetStream vs core | **Both** | Core fanout; JS queues + schedules |

---

## Related plans

- [2026-09-23-prompt-run-multitask.md](./2026-09-23-prompt-run-multitask.md) — `C35_CHAT_PROMPT` worker (hydrate includes `prompt_run`)
- [2026-09-21-tasks.md](./2026-09-21-tasks.md) — `mod_task` CRUD + device dispatch
- [2026-09-22-platform-ops-multitask.md](./2026-09-22-platform-ops-multitask.md) — node-stats volume monitoring
