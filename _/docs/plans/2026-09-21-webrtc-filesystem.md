# WebRTC Data Plane + Device Filesystem Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship app ↔ device WebRTC data plane for screen, file browse/copy, and media streaming — with cluster TURN/STUN, WS signaling, dual status dots, and Files tab wired to `remote-fs` (replacing mock).

**Architecture:** Two planes (locked in [`_/docs/remote.md`](../../_/docs/remote.md)): **control** = agent WS to cluster (tasks, presence); **data** = WebRTC PeerConnection app ↔ device (P2P or TURN). Server relays SDP/ICE and mints ephemeral TURN creds only — **no file bytes through server**. One PC per viewer session; SCTP data channels `remote-input` (Remote tab) and `remote-fs` (Files tab); screen as video track.

**Tech Stack:** Rust (`mod_device`, `wire_ws`, `remotes/c_remote_*`), Flutter (`flutter_webrtc` or `dart_webrtc`), protobuf (`remote.proto`), coturn/eturnal TURN, existing LiveKit TURN (`turn.alienai.id`) as fallback candidate.

## Global Constraints

- Read `spec.md`, [`_/docs/remote.md`](../../_/docs/remote.md), [`_/docs/ui.md`](../../_/docs/ui.md) before coding.
- Task automation **never** over WebRTC; human file ops **always** over WebRTC.
- Pair code / naming / logging conventions per user rules (`ca.L`, `l()`, blake3, Snowflake/ULID).
- Verify Rust: `cargo build -p server_ai`; agent: `cargo build -p c_remote_windows` (from `remotes/`); Flutter: `flutter analyze` in `clients/app`.
- Cluster: **k3s-btm** (arm64), registry `hsg.ocir.io`, secrets in cluster (plaintext OK).

## Cluster TURN/STUN audit (2026-09-21)

| Resource | Namespace | Status | Action |
|----------|-----------|--------|--------|
| LiveKit + embedded TURN | `livekit` | **Running** | `turn.alienai.id`, `rtc.alienai.id`, UDP 3478, TLS — evaluate ephemeral cred mint |
| eturnal DaemonSet | `eturnal` | **Broken** | Pod stuck `ContainerCreating` — `configmap "eturnal-config" not found` |
| c35 TURN | — | **Missing** | Deploy dedicated coturn OR fix eturnal + wire `ReqRemoteIceConfig` |

**Recommendation:** Track 0 fixes infra first. Prefer **coturn in `c35` namespace** (arm64 image) for c35-owned credentials; keep LiveKit TURN as optional fallback during rollout.

---

## Multitask map

```
Track 0 (TURN/STUN infra)     ──► Track 1 (ICE config API)
                                      │
Track 2 (Proto lock)          ──► Track 3 (Server signaling relay)
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
         Track 4 (Agent WebRTC + fs)          Track 5 (Flutter WebRTC client)
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      ▼
                         Track 6 (Files tab wire + status dots)
                                      │
                         Track 7 (E2E manual test checklist)

Parallel wave 1 (no deps):
  • Agent A → Track 0 (coturn deploy OR fix eturnal)
  • Agent B → Track 2 (remote.proto RemoteFs* + RemoteIceConfig)

Parallel wave 2 (needs wave 1):
  • Agent C → Track 1 (ReqRemoteIceConfig handler)
  • Agent D → Track 3 (WS signaling relay offer/answer/ice)

Parallel wave 3 (needs wave 2):
  • Agent E → Track 4 (c_remote_windows webrtc + remote-fs handler)
  • Agent F → Track 5 (Flutter RemoteSession + data channels)

Parallel wave 4 (integration):
  • Agent G → Track 6 (UiDeviceFiles real wire, dual dots state)
  • Agent H → Track 7 (E2E doc + smoke test)
```

---

## Track 0 — TURN/STUN on cluster

**Files:**
- Create: `_/deployments/coturn/deployment.yaml`, `service.yaml`, `configmap.yaml`, `secret.yaml` (or fix `eturnal` manifests)
- Modify: `_/docs/remote.md` (ICE table — mark deployed)

**Option A — Fix eturnal (fast if config exists elsewhere):**
- [ ] **Step 1:** `kubectl get configmap -n eturnal` — confirm missing `eturnal-config`
- [ ] **Step 2:** Create `eturnal-config` ConfigMap with listener `3478`, realm `alienai.id`, static-auth-secret from K8s secret
- [ ] **Step 3:** Verify pod `eturnal-*` reaches Running on arm64 node
- [ ] **Step 4:** UDP 3478 reachable via Traefik LB `168.110.219.43` or hostNetwork if required

**Option B — coturn in c35 namespace (recommended):**
- [ ] **Step 1:** Add `_/deployments/coturn/` — `linux/arm64` image `coturn/coturn:4.6.3`, hostNetwork or NodePort UDP/TCP 3478
- [ ] **Step 2:** DNS `turn.alienai.id` → LB (reuse existing ingress host OR dedicated `c35-turn.alienai.id`)
- [ ] **Step 3:** TLS cert via cert-manager (matches existing `turn-alienai-id-tls` pattern in livekit ns)
- [ ] **Step 4:** Document STUN: `stun:turn.alienai.id:3478` and TURN: `turns:turn.alienai.id:443?transport=tcp` (or UDP)

Run: `kubectl apply -f _/deployments/coturn/ -n c35`  
Expected: coturn pod Running; `turnutils_uclient` smoke test from dev machine succeeds.

---

## Track 1 — ICE config API

**Files:**
- Create: `servers/crates/mod_device/src/remote_ice_config.rs`
- Modify: `servers/crates/mod_device/src/lib.rs`, `servers/crates/wire_http/src/device.rs` (or wire_ws)
- Modify: `_/schemas/proto/c35/remote.proto`

**Interfaces:**
- Produces: `ReqRemoteIceConfig` / `ResRemoteIceConfig { repeated IceServer ice_servers }`
- Consumes: coturn shared secret from env `C35_TURN_SECRET` or K8s secret mount

- [ ] **Step 1:** Add proto:

```protobuf
message IceServer {
  repeated string urls = 1;
  string username = 2;
  string credential = 3;
}
message ReqRemoteIceConfig {}
message ResRemoteIceConfig {
  repeated IceServer ice_servers = 1;
  uint32 ttl_sec = 2;
}
```

- [ ] **Step 2:** Mint TURN username `expiry:owner_iid` + HMAC credential (coturn REST API or static secret formula)
- [ ] **Step 3:** Expose via WS invoke `remote_ice_config` (authenticated JWT)
- [ ] **Step 4:** `cargo build -p server_ai`

---

## Track 2 — Proto lock (`remote-fs` + session)

**Files:**
- Modify: `_/schemas/proto/c35/remote.proto`, `_/schemas/proto/c35/wire.proto`
- Regenerate: `clients/app/lib/c/pb/`, Rust pb crates

**Interfaces:**
- Produces: `RemoteFsListReq/Res`, `RemoteFsReadReq/Res`, `RemoteFsWriteReq/Res`, `RemoteFsError`

- [ ] **Step 1:** Add file messages:

```protobuf
message RemoteFsEntry {
  string name = 1;
  string path = 2;
  bool is_dir = 3;
  int64 size = 4;
  int64 modified_ms = 5;
}
message RemoteFsListReq { string path = 1; }
message RemoteFsListRes { repeated RemoteFsEntry entries = 1; string error = 2; }
message RemoteFsReadReq { string path = 1; int64 offset = 2; int32 length = 3; }
message RemoteFsReadRes { bytes data = 1; bool eof = 2; string mime = 3; string error = 4; }
message RemoteFsWriteReq { string path = 1; int64 offset = 2; bytes data = 3; bool finalize = 4; }
message RemoteFsWriteRes { int64 bytes_written = 1; string error = 2; }
```

- [ ] **Step 2:** Add `RemoteSessionPush.webrtc_connected = 6` (optional) for dot state
- [ ] **Step 3:** Regenerate protobuf Dart + Rust
- [ ] **Step 4:** Commit proto lock before agent/client impl

---

## Track 3 — Server signaling relay

**Files:**
- Create: `servers/crates/mod_device/src/remote_signaling.rs`
- Modify: `servers/crates/wire_ws/src/` (client WS + agent session forward)

**Flow:**
1. App `ReqRemoteSessionStart{device_iid}` → server notifies agent session
2. App/agent exchange `RtcSignalOffer/Answer/Ice` via WS; server forwards to peer
3. Server pushes `RemoteSessionPush{mode, video_active}` to app

- [ ] **Step 1:** Validate caller owns `device_iid` via `identity_grant`
- [ ] **Step 2:** Forward signaling frames agent ↔ app on same `session_id`
- [ ] **Step 3:** Agent must be cluster-online before signaling allowed
- [ ] **Step 4:** `cargo build -p server_ai`

---

## Track 4 — Agent WebRTC + filesystem

**Files:**
- Create: `remotes/c_remote_core/src/webrtc/mod.rs`, `webrtc/fs.rs`, `webrtc/session.rs`
- Modify: `remotes/c_remote_windows/src/main.rs`, agent WS frame handler
- Add dep: `webrtc` / `webrtc-sys` or `livekit-webrtc` (evaluate arm64 + Windows)

**Interfaces:**
- Consumes: signaling frames from agent WS
- Produces: answers ICE; handles `remote-fs` binary frames → local `std::fs` reads

- [ ] **Step 1:** On `ReqRemoteSessionStart` relay from server, create `RTCPeerConnection` with ICE servers from env
- [ ] **Step 2:** Register data channels `remote-input`, `remote-fs` (or accept in-bound from offer)
- [ ] **Step 3:** Implement `RemoteFsList` / `RemoteFsRead` / `RemoteFsWrite` on Windows paths (sanitize `..`, drive roots)
- [ ] **Step 4:** Screen capture → video track (Remote tab — can be sub-task after fs works)
- [ ] **Step 5:** `cargo build -p c_remote_windows`

---

## Track 5 — Flutter WebRTC client

**Files:**
- Create: `clients/app/lib/c/remote/remote_session.dart`, `remote_fs_api.dart`
- Modify: `clients/app/pubspec.yaml` (add `flutter_webrtc`)
- Modify: `clients/app/lib/widgets/devices/ui_device_files.dart`

**Interfaces:**
- Consumes: `ResRemoteIceConfig`, signaling via existing `ChatConn` / WS
- Produces: `RemoteSession` singleton per device with `connected`, `mode`, `fsList()`, `fsRead()`

- [ ] **Step 1:** Add `flutter_webrtc` dependency; platform permissions (camera/mic not needed for fs-only)
- [ ] **Step 2:** `remote_session.dart` — fetch ICE, create PC, handle signaling, expose `ValueNotifier<bool> connected`
- [ ] **Step 3:** `remote_fs_api.dart` — encode/decode `RemoteFs*` over `remote-fs` data channel
- [ ] **Step 4:** `flutter analyze`

---

## Track 6 — UI integration

**Files:**
- Modify: `clients/app/lib/widgets/devices/ui_device_row.dart` (wire `webrtcConnected`)
- Modify: `clients/app/lib/widgets/devices/ui_device_files.dart` (replace mock with `RemoteFsApi`)
- Modify: `clients/app/lib/pages/page_devices.dart`, `ui_device_detail.dart`
- Modify: `clients/app/lib/c/device/device_store.dart` (optional session map)

- [ ] **Step 1:** `PageDevices` listens to `RemoteSession.connected` per selected device → pass `webrtcConnected` to `UiDeviceRow`
- [ ] **Step 2:** Files tab: if !webrtcConnected → empty state + **Connect** button calling `RemoteSession.start(deviceIid)`
- [ ] **Step 3:** Replace `_mockRoots()` with lazy tree from `fsList`
- [ ] **Step 4:** Preview pane streams `fsRead` chunks (text/image)
- [ ] **Step 5:** Remote tab reuses same `RemoteSession` (don't duplicate PC)
- [ ] **Step 6:** `flutter analyze`

---

## Track 7 — E2E smoke test

**Checklist doc:** [`2026-09-21-webrtc-filesystem-e2e.md`](./2026-09-21-webrtc-filesystem-e2e.md) — prerequisites, local dev commands, expected results, troubleshooting, Tracks 0–6 gap audit.

- [x] **Step 1:** Write E2E doc (prerequisites, `dev_server.ps1` / `dev_agent.ps1` / `flutter run`, troubleshooting)
- [ ] **Step 2:** Run manual smoke tests per [E2E checklist](./2026-09-21-webrtc-filesystem-e2e.md#smoke-test-checklist) (after Track 6 UI wiring)

**Manual checklist** (details + expected results in E2E doc):

- [ ] Agent paired, cluster dot green — [§0](./2026-09-21-webrtc-filesystem-e2e.md#0-baseline--agent-online)
- [ ] Open Files → Connect → WebRTC dot green, badge Direct or Relay — [§1](./2026-09-21-webrtc-filesystem-e2e.md#1-webrtc-session--connect)
- [ ] List `C:\Users\{name}\Documents` — matches Explorer — [§2](./2026-09-21-webrtc-filesystem-e2e.md#2-directory-listing)
- [ ] Preview `spec.md` text — streams without full download to server — [§3](./2026-09-21-webrtc-filesystem-e2e.md#3-text-preview-streaming)
- [ ] Send 10 MB file phone → PC — progress UI, file appears on disk — [§4](./2026-09-21-webrtc-filesystem-e2e.md#4-file-send-phone--pc)
- [ ] Kill WebRTC — dots update; Files tab shows reconnect prompt — [§5](./2026-09-21-webrtc-filesystem-e2e.md#5-disconnect--reconnect)
- [ ] TURN path: force relay (block UDP) — still connects via Relay badge — [§6](./2026-09-21-webrtc-filesystem-e2e.md#6-turn-relay-path)

---

## Self-review (spec coverage)

| Requirement | Task |
|-------------|------|
| WebRTC file browse | Track 2, 4, 5, 6 |
| Content streaming | Track 4 `RemoteFsRead`, Track 6 preview |
| P2P, no server file storage | Architecture + Track 3 relay-only |
| Dual status dots | Track 6, docs done |
| TURN/STUN | Track 0 + Track 1 |
| Responsive Files UI | Done (mock); Track 6 keeps layout |
| Remote screen/input | Track 4 video + existing Remote tab |

No TBD placeholders remain in task steps above.

---

## Execution handoff

Start wave 1 immediately after this plan is saved — subagent per track (`plan-execution.mdc`). Do not ask inline vs subagent.
