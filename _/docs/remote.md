# Remote device & computer use (LOCKED)

Status: **locked** 2026-09-21

Remote PCs/phones (`identity.kind = remote`) expose two **separate** planes. Do not mix them.

| Plane | Transport | Use |
|-------|-----------|-----|
| **Computer use** (AI tasks, skills, shell, file ops) | Agent ↔ server **only** — WebSocket or Alien Beacon | Server-orchestrated automation |
| **Human remote** (screen, input, media playback) | WebRTC (P2P or TURN relay) + data channels | Interactive viewer in `UIRemoteDevice` |

**Locked:** computer use **never** goes over WebRTC. The agent always maintains a control connection to the server (WS or Alien Beacon). WebRTC is viewer-only.

## Reference

| Project | Borrow |
|---------|--------|
| `D:\cs_bots` | Server-authoritative sync, gateway patterns |
| `D:\cs_agent` | `task` / `task_run` shape, Windows automation executor |
| c35 channel worker | NATS `act` / `ev` + WS fanout (`ChannelPairPush`) |

## Agent control connection

```
c_remote_*  ──WS or Alien Beacon──►  c35-server  ◄──WS──  Flutter client
                                         │
                                         ▼
                                    NATS JetStream
                                         │
                                         ▼
                                    YugabyteDB (source of truth)
```

- Agent registers as `identity(kind=remote, type=windows|android|…)`.
- Pairing: 10-char code — see [Pairing](#pairing) below and [identity.md](identity.md).
- Presence: `meta.last_seen_ts_ms`, `meta.online` updated on connect/disconnect.
- **No** client SQLCipher replica; **no** bidirectional task sync from agent (cs_agent pattern removed).

## Pairing

10-char code `[A-Z0-9]`, display `XXXXX-XXXXX`. Slashed-zero typography on agent window.

| Step | Actor | Action |
|------|-------|--------|
| 1 | Agent (unpaired) | `POST /v1/device/pair/register` → `ResDevicePairRegister` |
| 2 | Agent | Show large code in **Rust** pair window (`c_remote_windows/pair_window.rs`) |
| 3 | Agent | Poll `GET /v1/device/pair/poll?secret=…` until `claimed` |
| 4 | Flutter app | Devices → Add → enter code → `InvokeReq.device_pair` (claim — **implemented**) |
| 5 | Server | Set `owner_iid`, clear `pairing_code`, issue `session_key` in meta |
| 6 | Agent | Save `%LOCALAPPDATA%\AlienAI\config.json`, connect WS/Beacon |

**Claim (app, done):** `mod_device::device_pair` — lookup `meta.pairing_code`, assign owner, upsert grant.

**Register + poll (agent, TODO):** HTTP handlers in `wire_http`; agent port from `D:\cs_bots\agents\desktop_node\src\{pair,pair_window}.rs`.

Proto: [`../schemas/proto/c35/device.proto`](../schemas/proto/c35/device.proto) — `ReqDevicePairRegister`, `ReqDevicePairPoll`.

Tray while paired: **Unpair** (clear config, show new code) · **Quit**.

**Local dev:**

```powershell
.\dev_server.ps1          # server on :8080
.\dev_agent.ps1           # Win32 pair window (default)
.\dev_agent.ps1 -Cli      # pairing code in console (--cli)
```

`dev_agent.ps1` kills any running `c_remote_windows` before start. Env: `C35_SERVER_URL` (default `http://127.0.0.1:8080`).

## Computer use — task dispatch (NATS, not YB polling)

Work is **pushed** over NATS JetStream. Server pods **never** poll YB for runnable tasks.

### Status machine (`ai.task_run.status`)

```
queued → leased → running → done
                          ↘ failed
                          ↘ cancelled
```

| Status | Meaning |
|--------|---------|
| `queued` | Row persisted; JetStream message published (or pending publish) |
| `leased` | A server pod forwarded `ActDeviceTaskRun` to the agent session |
| `running` | Agent acknowledged and is executing |
| `done` / `failed` / `cancelled` | Terminal |

### Dispatch flow

```
1. Client  WsReq.task_run_start
2. Server  INSERT ai.task_run (status=queued)
           JetStream publish ActDeviceTaskRun → c35.act.device.{device_iid}.task.run
3. Server pod holding agent WS subscribes c35.act.device.{device_iid}.task.*
           → forwards ActDeviceTaskRun on agent session
           → UPDATE status=leased, lease_pod, lease_expires_ts
4. Agent   executes (shell / UI / skill steps)
           → EvDeviceTaskProgress / EvDeviceTaskDone on agent session (or NATS ev)
5. Server  UPDATE ai.task_run, write ai.log rows, ack JetStream
           → TaskRunPush to owner WS clients
```

### Multi-pod (2+ replicas)

| Concern | Rule |
|---------|------|
| Agent session | One WS/Beacon session per `device_iid`; pod registers route on connect |
| Dispatch | JetStream **queue group** `c35-task-dispatch` — only pod with live agent session should ack |
| No agent online | Message not acked → JetStream redelivers after `ack_wait` |
| Server rolling deploy | Client WS reconnects to any pod; agent reconnects to any pod; JetStream retains unacked work |
| Lease timeout | `lease_expires_ts` + agent heartbeat → stale `leased`/`running` → republish same `run_id` (idempotent) |

### Recovery (not background polling)

| Event | Action |
|-------|--------|
| Agent connects | Pod subscribes `c35.act.device.{device_iid}.task.*`; JetStream delivers backlog |
| Publish failed after INSERT | `task_run_replay` RPC or agent `EvDeviceAgentHello` triggers **one** republish query: `status=queued AND device_iid=$1` |
| Duplicate delivery | Agent dedupes by `run_id`; ignore if already terminal |

**Forbidden:** periodic `SELECT … WHERE status='queued'` sweeper on a timer.

## NATS subjects

### JetStream stream

| Stream | Subjects | Retention |
|--------|----------|-----------|
| `C35_DEVICE_TASK` | `c35.act.device.*.task.run` | workqueue, `ack_wait` 60s, max_deliver 10 |

### Core pub/sub

| Subject | Direction | Payload |
|---------|-----------|---------|
| `c35.act.device.{device_iid}.task.run` | server → agent (via JetStream) | `ActDeviceTaskRun` |
| `c35.ev.device.{device_iid}.task.{run_id}` | agent → server | `EvDeviceTaskProgress` / `EvDeviceTaskDone` |
| `c35.ev.device.{device_iid}.presence` | agent ↔ server | `EvDevicePresence` (`online` / `offline`) |
| `c35.user.{owner_iid}.task_run` | server → client WS | `TaskRunPush` fanout |

Log tail (unchanged): `log.{owner_iid}.{dv}.{topic}` — task steps use `kind=task`, `topic=task_step|task_done|task_fail`.

## Tables

See [`../schemas/task.sql`](../schemas/task.sql).

| Table | Synced | Notes |
|-------|--------|-------|
| `task` | yes | Definition: name, prompt, skill_id, device_iid, model |
| `task_trigger` | yes | `once` \| `cron` \| `webhook` |
| `task_run` | yes | Execution instance; status machine above |

DDL + indexes in `task.sql`. Proto: [`../schemas/proto/c35/task.proto`](../schemas/proto/c35/task.proto).

## Wire (client)

| RPC | Purpose |
|-----|---------|
| `ReqTaskList` / `ResTaskList` | Devices → Task tab |
| `ReqTaskPut` / `ResTaskPut` | Create/update task + triggers |
| `ReqTaskRunStart` / `ResTaskRunStart` | Enqueue run (ad-hoc or from task id) |
| `ReqTaskRunCancel` / `ResTaskRunCancel` | Cancel queued/leased/running |
| `ReqTaskRunList` / `ResTaskRunList` | History for device |
| `TaskRunPush` | Unsolicited progress (NATS → WS) |

## Wire (agent session)

Server forwards JetStream payload as agent session frame `ActDeviceTaskRun`.

Agent responds with `EvDeviceTaskProgress` / `EvDeviceTaskDone` on the same session (server may also accept via NATS `c35.ev.device.*` for Beacon-only agents).

## Human remote (WebRTC) — separate plane

Interactive screen control in `UIRemoteDevice` tab **Remote**:

| Piece | Detail |
|-------|--------|
| Signaling | WS `ReqRemoteSessionStart`, `RtcSignalOffer/Answer/Ice` |
| Video | Hardware-encoded screen track on agent |
| Input | Data channel `RemoteInputEvent` (click, drag, keys) |
| Badge | `host`/`srflx` → **Direct**; `relay` → **Relay** |
| Idle | Stop encode when no subscribers / no dirty frames (unlike always-on ARF1) |

Proto: [`../schemas/proto/c35/remote.proto`](../schemas/proto/c35/remote.proto).

Shell + file explorer + media playback over WebRTC data channels / second video track — Phase 6+; not required for task dispatch v1.

## UI

Devices page → remote device → tabs per [ui.md](ui.md):

| Tab | v1 scope |
|-----|----------|
| Remote | WebRTC viewer (human) |
| Task | `ReqTaskList`, run history, start/cancel |
| Skill | Teach + list (see [skill.md](skill.md)) |
| Settings | Name, instructions, agent version |

## Server crates

| Crate | Role |
|-------|------|
| `mod_device` | Pairing, presence, agent session registry |
| `mod_task` | Task CRUD, `task_run_start`, JetStream publish, WS fanout |
| `remotes/c_remote_*` | Executor — receives `ActDeviceTaskRun`, reports ev |

## cs_agent differences (intentional)

| cs_agent | c35 |
|----------|-----|
| Client/agent bidirectional sync of `task_run` | Server owns `task_run`; agent is executor only |
| Task state on agent SQLite | Agent stateless except in-memory lease |
| Chat-integrated task loop | Optional `chat_id` on run; no chat sync for steps |
| WebRTC mixed with automation | WebRTC viewer-only; automation via server session |
