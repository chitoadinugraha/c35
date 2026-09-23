# Remote device & computer use (LOCKED)

Status: **locked** 2026-09-21

Remote PCs/phones (`identity.kind = remote`) expose two **separate** planes. Do not mix them.

| Plane | Transport | Use |
|-------|-----------|-----|
| **Control** (tasks, skills, shell automation, presence) | Agent ↔ server **only** — WebSocket or Alien Beacon | Server-orchestrated automation; **no file bytes** |
| **Data** (screen, input, file browse, file copy, media stream) | WebRTC (P2P or TURN relay) + SCTP data channels | Human UX in app — **Remote** + **Files** tabs |

**Locked:** task/skill automation **never** goes over WebRTC. File browse/copy/stream for humans **always** goes over WebRTC (not agent session, not server storage).

**Server role on data plane:** signaling + ephemeral ICE credentials only. File bytes are **app ↔ device** direct (or via TURN relay when NAT requires it). c35 does not persist device files unless user explicitly saves to CAS.

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

**Register + poll (agent, done):** `wire_http` — `POST /v1/device/pair/register`, `GET /v1/device/pair/poll`; agent in `remotes/c_remote_windows`.

Proto: [`../schemas/proto/c35/device.proto`](../schemas/proto/c35/device.proto) — `ReqDevicePairRegister`, `ReqDevicePairPoll`.

### Agent session auth

After pairing, the agent connects with `meta.session_key` (stored in `%LOCALAPPDATA%\AlienAI\config.json`).

| Endpoint | Auth |
|----------|------|
| `GET /v1/agent/ws?session_key=…` | WebSocket control plane (presence, task dispatch later) |
| `POST /v1/agent/log` | Header `X-Device-Session: {session_key}` |

Server resolves `identity(kind=remote)` where `meta.session_key` matches and `owner_iid` is set (`mod_device::agent_session_resolve`).

Tray while paired: **Show Log** · **Unpair** (clear config, show new code) · **Quit**.

### Agent logging (locked)

**No SQLite on the agent.** c35 agents do not run a SQLCipher replica (see [sync.md](sync.md)).

| Layer | Storage | Purpose |
|-------|---------|---------|
| **Local file** | `%LOCALAPPDATA%\AlienAI\logs\agent-{ts}-{pid}.log` + `latest.txt` | Auth/connection debugging on device (like cs_agent `trace.rs`) |
| **Server push** | `ai.log` via `POST /v1/agent/log` | `conn` / `error` events visible in app admin logs |

- `tracing` writes to the session log file (`c_remote_core::log_local`).
- Important events (`connected`, `disconnected`, WS errors) also POST to server when online.
- Offline: events stay in the local file only (no local DB queue in v1).

**Local dev:**

```powershell
.\dev_server.ps1          # server on :8080
.\dev_agent.ps1           # Win32 pair window (default)
.\dev_agent.ps1 -Cli      # pairing code in console (--cli)
```

`dev_agent.ps1` kills any running `c_remote_windows` before start. Env: `C35_SERVER_URL` (default `http://127.0.0.1:8080`).

Pair window countdown label: **Code Refresh in** (new pairing code when TTL hits zero).

### Agent OTA & Multi-Platform Update Lifecycle

| Piece | Role |
|-------|------|
| `GET /version/remote-{platform}` | Release JSON from `ai.config` key `app.release.c35.remote-{platform}` (windows, macos, linux, android) |
| `GET {origin}/fs/{hash}?exp=&sig=` | Signed CAS download (blake3 zip of binary), served via Cloudflare orange cloud |
| NATS `c35.release.{platform}` | Real-time release broadcast; server forwards frame over agent WS for instant background download |
| `c_remote_core/update.rs` | Cross-platform core: background download, Blake3 verify, activity tracking, idle auto-apply |

- **Idle Condition:** `active_tasks == 0 && active_sessions == 0`.
- **Active Tasks:** Held until tasks finish; applies immediately on idle wakeup via `IDLE_NOTIFY`.
- **Active Remote Viewer:** Agent never reboots automatically; broadcasts `RemoteSessionPush { update_ready: true }`. The Flutter appbar displays an emerald **`Update (vN)`** button, allowing the user to trigger `apply_update` on demand.
- **Dev-Mode Protection:** Skipped in debug builds, `--dev`, or `C35_DEV=1`.
- **Multi-Platform Porting Guide:** See [remote-agent.md](remote-agent.md) and [auto-update.md](auto-update.md) for OS-specific capture, input, autostart, and watchdog specs.

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

## Human remote (WebRTC data plane)

One **PeerConnection** per viewer session (app ↔ device). Server relays SDP/ICE only.

```
Flutter app  ◄──WebRTC (P2P/TURN)──►  c_remote_* agent
      │                                      │
      └── WS signaling (offer/answer/ice) ───┘
                relayed via NATS pub/sub
     (c35.signal.device.* / c35.signal.user.*)
```

### Signaling relay (NATS, cross-pod)

To allow the Flutter client on Pod A to connect with an agent on Pod B:
- `c35.signal.device.{device_iid}` — App offers/ICE forwarded to agent session.
- `c35.signal.user.{owner_iid}` — Agent answers/ICE forwarded to user app sessions.
No in-memory single-pod DashMap locks.

### Unified agent input executor (`input_exec`)

Both Human remote interaction and Alien AI automation converge on the exact same OS input executor on the agent (`c_remote_windows`):

```
 [Human UiRemote]                           [Alien AI Chat]
        │                                           │
  remote-input channel                       mod_chat device tool
 (WebRTC P2P/TURN)                                  │
        │                                    Server pushes WS
        │                                   (ActDeviceTaskRun)
        ▼                                           ▼
  RemoteInputEvent                           RemoteInputEvent
        └───────────────────┬───────────────────────┘
                            ▼
              input_exec::execute(event)
       (Win32 SendInput / mouse_event / keybd_event)
```

### Dynamic Device Mentions (@DeviceName)

- **Composer:** Typing `@` suggests user's online remote devices from `ai.identity` (e.g. `@Chito-PC`) alongside static topics (`@research`).
- **Prompt:** When device mention is active, Alien AI tool dispatcher injects `device_command_run` and `device_computer_use`.
- **Multitask:** If multiple devices are mentioned (e.g. `@Chito-PC` and `@Laptop`), Alien AI calls execution tools in parallel, orchestrating multi-device workflows concurrently.

### Computer Use Architecture & LLM Tools

c35 supports Claude Computer Use / Grok / Gemini-style desktop control over paired remote devices via three tightly-integrated capabilities:

#### 1. Available Tools in Chat

When a user mentions a device (e.g. `@Chito-PC`) or when computer use is needed, the following builtin tools are dispatched to the LLM:

- **`device.screenshot`**: Captures high-definition JPEG desktop screenshots (`max_width`, `quality`, optional `marker_x`, `marker_y`, optional `som: bool`).
- **`device.input`**: Dispatches mouse clicks, moves, drags, typing, and key presses using normalized `(0.0, 0.0)` to `(1.0, 1.0)` coordinates. Setting `screenshot_after=true` automatically waits 200ms and returns a follow-up screenshot with a red target marker confirming where the action landed.
- **`device.command`**: Executes PowerShell commands directly on the remote agent with a configurable timeout (`timeout_sec`), returning structured `stdout`, `stderr`, and `exit_code`.

#### 2. Set-of-Mark (SoM) & Windows UI Automation (UIA) Engine

To eliminate coordinate hallucination and trial-and-error clicks:
- The remote agent scans the active foreground window hierarchy using Windows UI Automation (`uiautomation` crate).
- It extracts interactive control bounding boxes (Buttons, Edits, ComboBoxes, CheckBoxes, Menus, Links, etc.).
- `draw_som_overlay` renders high-contrast 2px coral/orange-red bounding boxes and numbered crimson badges directly onto the screenshot framebuffer using embedded scalable 5x7 digit glyphs (zero font file dependencies).
- Returns structured `axtree_text` in the screenshot result:
  ```text
  @1 Button 'Submit' -> center=(0.450, 0.320)
  @2 Edit 'Search query' -> center=(0.210, 0.080)
  @3 ComboBox 'Language' -> center=(0.620, 0.150)
  ```
- The vision model can target `@index` or normalized center coordinates with 100% precision.

#### 3. Visual Red Action Markers

- When verifying an action or setting `marker_x` and `marker_y`, `draw_red_marker` renders a solid red target dot (radius 4px) encircled by a crisp white halo (radius 7px).
- In post-action screenshots (`screenshot_after=true`), the marker visualizes the exact click/drag destination, giving LLMs instant feedback to self-correct if a target moved or if focus was lost.

#### 4. Token & Context Optimization

Desktop screenshots consume substantial tokens (~1,000–2,000 tokens per image). In multi-step computer use loops (10–30 turns), appending screenshots naively would quickly exhaust context windows (e.g. 100k+ tokens).
- `prune_previous_screenshots()` in `servers/crates/mod_chat/src/prompt/tool_loop.rs` parses conversation history and strips raw base64 JPEG content from earlier turns, replacing them with lightweight metadata summaries (`[Screenshot observation: 1280x720 JPEG - pruned to save context]`).
- Only the **latest screenshot** is provided as image content to the model on each turn.
- Token consumption drops by **up to 90%**, allowing agents to run indefinitely complex multi-step desktop tasks reliably.

### ICE / TURN (cluster)

| Piece | Status | Notes |
|-------|--------|-------|
| **c35 coturn** | **Deployed** (`c35` ns) | `coturn/coturn:4.6.3`, hostNetwork arm64 node `129.225.3.111`. Secret: `coturn-secret` (`static-auth-secret`). Manifests: [`_/deployments/coturn/`](../deployments/coturn/) |
| **LiveKit TURN** | Running (`livekit` ns) | Embedded TURN on host UDP **3478** (`rtc.alienai.id`). Optional fallback during rollout |
| **eturnal** | **Broken** | DaemonSet stuck — missing `eturnal-config` ConfigMap; superseded by c35 coturn |
| **Server API** | Planned | `ReqRemoteIceConfig` → STUN + TURN URLs + short-lived username/credential (HMAC over `coturn-secret`) |

**ICE URLs (c35 coturn — use these in `ReqRemoteIceConfig`):**

| URL | Status |
|-----|--------|
| `stun:stun.alienai.id:3479` | Ready (DNS → `129.225.3.111`) |
| `stun:turn.alienai.id:3479` | Ready (same host) |
| `turn:turn.alienai.id:3479?transport=udp` | Ready (UDP relay on hostNetwork) |
| `turn:turn.alienai.id:3479?transport=tcp` | Ready (TCP fallback) |
| `turns:turn.alienai.id:443?transport=tcp` | **Not yet** — Traefik ingress `turn.alienai.id:443` routes to LiveKit HTTP, not coturn TLS |

**Port note:** c35 coturn listens on **3479** because LiveKit embedded TURN already binds host UDP/TCP **3478**. To move c35 to 3478, disable LiveKit `turn.enabled` first.

**DNS (manual / existing):** `turn.alienai.id` and `stun.alienai.id` A records → `129.225.3.111` (node external IP). No ingress change needed for UDP; TLS TURNS on 443 requires either Traefik TCP passthrough to coturn or coturn `tls-listening-port` with cert mount (future).

App and agent fetch ICE config from server before `createOffer`. Prefer **host/srflx** (Direct badge); fall back to **relay** (Relay badge).

### Data channels (one PC, labeled)

| Label | Payload | Tab |
|-------|---------|-----|
| `remote-input` | `RemoteInputEvent` protobuf | Remote |
| `remote-fs` | `RemoteFs*` protobuf frames | Files |

### Remote tab — screen + audio + input

| Piece | Detail |
|-------|--------|
| Signaling | WS `ReqRemoteSessionStart`, `RtcSignalOffer/Answer/Ice` |
| Video Track | WebRTC RTP Video Track (`video/VP8` or `video/H264`) with BWE/TWCC dynamic bitrate & framerate adaptation |
| GPU Capture | **DXGI Desktop Duplication API** (sub-millisecond in-VRAM capture, 60+ FPS) with GDI fallback for headless/VMs |
| Audio Track | WebRTC RTP Audio Track (`audio/opus`) captured via **Windows WASAPI Loopback** (stereo 48kHz) |
| Input | WebRTC data channel `remote-input` → `RemoteInputEvent` (Win32 `SendInput`) |
| Auto-Connect | Starts immediately when user enters device detail / Remote tab |
| Auto-Reconnect | Re-initiates on connection failure with exponential backoff (1s, 2s, 4s, 8s, 16s) up to 5 attempts |
| Inactivity Disconnect | Closes peer connection after 60s idle (zero user input) with 1-click **Resume Session** overlay |
| Fallback | MJPEG diffs over `remote-screen` SCTP data channel if video track negotiation is unavailable |
| Badge | `host`/`srflx` → **Direct**; `relay` → **Relay** |
| Idle | Stop encode when no subscribers / no dirty frames |

### Files tab — browse, copy, stream

Master/detail file UI (tree + list + preview on wide screens). **All ops on `remote-fs` data channel.**

| Op | Wire | Notes |
|----|------|-------|
| List dir | `RemoteFsListReq` → `RemoteFsListRes` | Lazy tree; agent reads local FS |
| Read chunk | `RemoteFsReadReq{path, offset, len}` → `RemoteFsReadRes{bytes, eof}` | Text preview, progressive image |
| Write chunk | `RemoteFsWriteReq` | Phone → PC send; chunked upload |
| Stream media | `RemoteFsReadReq` with larger chunks or dedicated `RemoteFsStreamOpen` | Video/audio preview; range-like reads |

**Preview limits (client):** cap text preview (e.g. 256 KB), stream images/video progressively. Unsupported types → download-only over same channel.

**Session gate:** Files tab requires WebRTC connected (left status dot). Cluster dot (agent online) alone is not enough — show **Connect** prompt.

Proto: [`../schemas/proto/c35/remote.proto`](../schemas/proto/c35/remote.proto).

## UI

Devices page → remote device row shows **two status dots** (trailing):

| Dot | Position | Meaning |
|-----|----------|---------|
| Left | WebRTC | App ↔ device data plane connected |
| Right | Cluster | Agent ↔ server control session online |

Device detail tabs per [ui.md](ui.md):

| Tab | Scope |
|-----|-------|
| Remote | WebRTC screen + input (`remote-input`) |
| Files | WebRTC file browse/copy/stream (`remote-fs`) — mock UI done |
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
| WebRTC mixed with automation | Split planes: automation = agent session; human files/media = WebRTC data plane |
