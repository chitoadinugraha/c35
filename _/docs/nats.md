# NATS (LOCKED)

Status: **locked** 2026-09-23

NATS is the **runtime bus** — not the system of record. YugabyteDB holds durable state; NATS delivers work and live fanout.

Server: **NATS 2.15** (`nats:2.15-alpine`). JetStream store: **`emptyDir`** on `nats-0` (no `oci-bv` PVC). Manifests: [`_/deployments/nats/`](../deployments/nats/README.md). Storage layout: [`_/deployments/storage.md`](../deployments/storage.md).

---

## Three layers

| Layer | Store | Role |
|-------|--------|------|
| **Source of truth** | YB | `ai.prompt_run`, `ai.task_run`, `ai.task_trigger`, chat, billing, logs |
| **Core NATS** | Ephemeral | Live push — balance, chat delta, `log.*`, stats, cache invalidation |
| **JetStream** | Ephemeral (emptyDir) | Work queues + NATS cron schedules; ack, retry, competing consumers |

```text
YB (truth)                         NATS (runtime)
──────────                         ──────────────
prompt_run / task_run rows  ──►    JetStream workqueue → c35-server workers
task_trigger (cron)       ──►    C35_TASK_SCHEDULE → fires → task_run + dispatch
WS clients                ◄──    core pub/sub fanout
```

**Rule:** Never treat NATS disk as durable. After NATS pod loss, **`c35-server` hydrates** from YB.

---

## JetStream streams

Bootstrapped by `c35_nats::jetstream_streams_ensure` on every `c35-server` NATS connect (`server_ai/src/nats_boot.rs`).

| Stream | Subject(s) | Retention | Queue group | Purpose |
|--------|------------|-----------|-------------|---------|
| `C35_CHAT_PROMPT` | `c35.prompt.run` | WorkQueue | `c35-prompt-dispatch` | Prompt turn jobs (`ai.prompt_run`) |
| `C35_DEVICE_TASK` | `c35.act.device.*.task.run` | WorkQueue | `c35-task-dispatch` | Device automation (`ai.task_run`) |
| `C35_TASK_SCHEDULE` | `c35.schedule.task.>`, `c35.task.fire.>` | default + `allow_msg_schedules` | `c35-task-schedule-fire` (planned) | Cron / once triggers |

### JetStream KV — `c35_stats`

Bootstrapped with streams via `c35_nats::stats_kv_ensure` (`stats_kv.rs`). Holds the **latest** protobuf `StatsPush` per key for cluster-wide ops snapshots:

| Key pattern | Value |
|-------------|--------|
| `node/{node_name}` | `StatsPush` (`node` body) |
| `vol/{node_name}/{namespace}/{pvc_name}` | `StatsPush` (`volume` body) |

Ephemeral like other JetStream data on `emptyDir` — recover from live `c35.stats.*` publishers after NATS loss. **1-minute rollups** for peaks/history are persisted in YB `ai.ops_metric_1m` ([`ops.sql`](../schemas/ops.sql)); see [sync.md](sync.md) node stats section.

Work message body (minimal JSON):

```json
{"req_id":"…","owner_iid":123,"chat_id":456}
```

Full state loaded from YB by `req_id` / `run_id`.

### Core pub/sub (no JetStream)

See [sync.md](sync.md) — `c35.user.{iid}.*` (incl. `.ev.{slug}` per [event.md](event.md)), `c35.stats.*`, `c35.fetch.*`, `c35.inst.*`, channel `c35.ev.channel.*`. LLM trace is DB-only; deprecated: `log.{iid}.{dv}.{topic}`.

---

## Cron schedules (NATS 2.14+)

**No YB poller** for “what is due now?” — NATS message schedules (ADR-51) fire ticks.

### Flow

```text
1. Client  ReqTaskPut (trigger kind=cron|once)
2. Server  UPSERT ai.task_trigger (YB)
           publish schedule → c35.schedule.task.{trigger_id}
             Nats-Schedule: <cron 6-field | @at RFC3339>
             Nats-Schedule-Time-Zone: Asia/Jakarta
             Nats-Schedule-Target: c35.task.fire.{trigger_id}
3. NATS   fires on schedule → c35.task.fire.{trigger_id}
4. Server  worker (queue group): load trigger from YB
           INSERT ai.task_run (queued)
           JetStream publish → C35_DEVICE_TASK
5. Server  TaskRunPush → owner WS (core NATS)
```

| Trigger kind | `Nats-Schedule` |
|--------------|-----------------|
| `cron` | 6-field cron (`sec min hr dom mon dow`), e.g. `0 0 9 * * *` |
| `once` | `@at 2026-09-24T09:00:00Z` |

On `task_trigger` deactivate or delete → cancel schedule subject (`c35.schedule.task.{id}.stop` or purge).

**Implementation:** `c35_nats::hydrate_task_schedules` + `mod_task` fire handler (see [remote.md](remote.md), plan [`plans/2026-09-23-nats-scheduler-hydrate-multitask.md`](plans/2026-09-23-nats-scheduler-hydrate-multitask.md)).

---

## Hydrate (recovery)

**Owner:** `c35-server` (`nats_post_connect` in `server_ai/src/nats_boot.rs`).

**Not** a periodic YB sweeper — event-driven only.

| Trigger | Action |
|---------|--------|
| `server_ai` boot + NATS connected | `jetstream_streams_ensure` → hydrate (if lock acquired) |
| NATS reconnect after disconnect | Same (supervisor skips initial `Connected`) |
| Agent `EvDeviceAgentHello` | Republish `queued` runs for that `device_iid` |
| Lease timeout | Republish same `run_id` (idempotent) |
| `task_run_replay` RPC | Manual republish |

### Single leader (multi-pod)

```text
pg_try_advisory_lock(0xC35, 0x4E41)  →  one pod hydrates
other pods  →  skip (lock busy)
all pods    →  JetStream queue consumers (normal work)
```

### Hydrate steps

1. **Schedules** — `SELECT` active `ai.task_trigger` (`cron` / `once`) → republish NATS schedule subjects
2. **Prompt dispatch** — `SELECT req_id FROM ai.prompt_run WHERE status='queued'` → republish `c35.prompt.run` (`Nats-Msg-Id` = `req_id`)
3. **Task dispatch** — `SELECT` queued `ai.task_run` → republish `C35_DEVICE_TASK` (when `mod_task` ships)

Log line: `[c35:nats] hydrate complete schedules=N prompt_replay=M task_replay=K`

**Forbidden:** periodic `SELECT … WHERE status='queued'` timer (see [remote.md](remote.md)).

---

## Multi-pod dispatch

| Work | Spreads across |
|------|----------------|
| Prompt runs | Any `c35-server` pod (`c35-prompt-dispatch` queue group) |
| Device tasks | Pod holding agent WS for that `device_iid` |
| Cron fire handler | Any pod (`c35-task-schedule-fire`) |
| Per-device execution | That device’s agent only |

Scale **stateless `c35-server` replicas** before adding NATS cluster nodes.

---

## Ops

### Upgrade NATS (ephemeral)

```powershell
.\_\scripts\deploy\nats_ephemeral_upgrade.ps1
# or set $env:KUBE_CONTEXT to your kubectl context
```

Deletes legacy PVC `nats-data-nats-0`, applies `nats:2.15-alpine` + `emptyDir`, restarts consumers.

### Verify after NATS recycle

```powershell
kubectl exec -n nats nats-0 -c nats -- nats-server -v
kubectl get pvc -n nats   # expect none for NATS
kubectl logs -n c35 deploy/c35-server --tail=30 | Select-String hydrate
```

### Publish server (includes hydrate code)

```powershell
.\_\scripts\deploy\publish_server.ps1
```

Feature flag on boot: `nats_hydrate` in startup `Features:` line.

---

## Related

- [sync.md](sync.md) — NATS subject catalog
- [remote.md](remote.md) — task dispatch, status machine, recovery
- [server.md](server.md) — crate layout, deployments
- [log.md](log.md) — live log tail over core NATS
