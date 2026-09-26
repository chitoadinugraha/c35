# WebRTC Filesystem — E2E Smoke Test Checklist

> **Parent plan:** [2026-09-21-webrtc-filesystem.md](./2026-09-21-webrtc-filesystem.md) (Track 7)

**Shipped (2026-09-26):** Files tab is live — real `remote-fs` listing, preview, upload (`fsWrite`), drag-drop, Explorer paste, device copy/paste, transfer progress. Canonical UX: [`ui.md`](../ui.md#files-tab-remote), wire/ops: [`remote.md`](../remote.md#files-tab--browse-copy-stream). Smoke steps below still apply; ignore “mock” / “blocked Track 6” notes unless re-auditing history.  
> **Spec:** [`_/docs/remote.md`](../../_/docs/remote.md)

Manual end-to-end verification for the app ↔ device WebRTC data plane (Files tab, status dots, TURN relay). Run this after Tracks 0–6 are implemented — see [Implementation gaps](#implementation-gaps-tracks-06) before testing.

---

## Prerequisites

### Cluster / infra

| Requirement | How to verify |
|-------------|---------------|
| **coturn running** in `c35` namespace | `kubectl get pods -n c35 -l app=coturn` → `Running` |
| **coturn secret** applied | `kubectl get secret coturn-secret -n c35` exists; `static-auth-secret` matches server env |
| **c35-server deployed** with `C35_TURN_SECRET` | [`_/deployments/c35-server/deployment.yaml`](../../_/deployments/c35-server/deployment.yaml) mounts `coturn-secret` → `C35_TURN_SECRET` |
| **DNS** | `turn.alienai.id` and `stun.alienai.id` → node external IP (`129.225.3.111`) |
| **Firewall UDP 3479** | STUN/TURN listener (c35 coturn; LiveKit uses **3478**) |
| **Firewall UDP 49160–49260** | TURN relay port range ([`configmap.yaml`](../../_/deployments/coturn/configmap.yaml)) |

Deploy or refresh coturn:

```powershell
# From repo root — replace secret placeholder first (see secret.yaml comments)
kubectl apply -f _/deployments/coturn/ -n c35
kubectl rollout status deployment/coturn -n c35
```

Optional coturn smoke test (from a machine with network access to `turn.alienai.id`):

```bash
turnutils_uclient -v -u test -w test turn.alienai.id -p 3479
```

(Expect auth failure with dummy creds — confirms UDP 3479 reachability. Real creds come from `ReqRemoteIceConfig`.)

### Paired agent

| Requirement | Notes |
|-------------|-------|
| **Windows agent built** | `cargo build -p c_remote_windows` from `remotes/` |
| **Device paired** to your account | Agent pairing window → app **Devices → + → Pair with code** |
| **Cluster dot** (right dot on device row) | Agent WS session online — green = control plane up |

### Local dev environment

| Requirement | Notes |
|-------------|-------|
| `servers/server_ai/.env.local` | Copy from [`.env.example`](../../servers/server_ai/.env.example) |
| `C35_TURN_SECRET` | Same value as cluster `coturn-secret` / `static-auth-secret` (empty = STUN-only; relay tests fail) |
| Flutter desktop or Android | WebRTC remote session is **not** supported on web (`remote_session.dart`) |
| Three terminals | Server, agent, app (order below) |

---

## Local dev — step-by-step

Use **three terminals** from repo root `D:\c35`.

### Terminal 1 — Server

```powershell
# Ensure servers/server_ai/.env.local exists and includes:
#   C35_TURN_SECRET=<same as coturn-secret>
#   C35_JWT_SECRET=dev-change-me
#   (YB/NATS from cluster .env.local as usual)

.\dev_server.ps1
```

**Expected:**

- `server_ai (watch) -> http://0.0.0.0:8080`
- No crash loop; `cargo build -p server_ai` succeeds on file changes
- HTTP `GET http://127.0.0.1:8080/livez` → 200 (optional curl check)

### Terminal 2 — Agent

```powershell
# Default server URL: http://127.0.0.1:8080
.\dev_agent.ps1

# Or console pairing code:
.\dev_agent.ps1 -Cli
```

**Expected:**

- Pairing window (or CLI) shows a **10-character code**
- After pairing in the app: agent stays running, logs show WS connected
- Device appears in app **Devices** list with **right (cluster) dot green**

### Terminal 3 — Flutter app

```powershell
cd clients\app
flutter run -d windows
# Android: flutter run -d <device_id>
```

**Expected:**

- App signs in (Google OAuth or existing session)
- **Devices** page lists the paired PC
- **Right dot** green when agent is connected to server

> `.\dev_app.ps1` is equivalent (wraps `flutter run -d windows`).

---

## Smoke test checklist

Check off each item during manual testing. **Expected results** describe pass criteria once Track 6 UI wiring is complete; items marked **(blocked)** need Track 6 before they can pass.

### 0. Baseline — agent online

- [ ] **Agent paired, cluster dot green**
  - **Steps:** Pair agent (see above). Open **Devices**, select the remote PC.
  - **Expected:** Trailing **right dot** (Agent / cluster) is green. Tooltip: "Agent (cluster)".
  - **Logs:** Agent `info` WS connected; server `remote_signaling_agent_register`.

### 1. WebRTC session — Connect

- [ ] **Open Files → Connect → WebRTC dot green, badge Direct or Relay**
  - **Steps:** Select device → **Files** tab. If not connected, tap **Connect** (or equivalent empty state).
  - **Expected:** **Left dot** (WebRTC) turns green within ~10s. Badge shows **Direct** (host/srflx) or **Relay** (TURN).
  - **Logs (app):** `remote session start`, `remote offer sent`, `remote answer applied`, `remote-fs channel state=open`.
  - **Logs (agent):** `webrtc session created`, `webrtc pc state` → `Connected`.
  - **(blocked)** Until Track 6: Files tab may still show mock tree; Connect button / dot wiring may be missing — verify via logs or temporary `RemoteSession.of(conn, iid).start()` if needed.

### 2. Directory listing

- [ ] **List `C:\Users\{name}\Documents` — matches Explorer**
  - **Steps:** In Files tab, expand tree to `C:\Users\<your-windows-user>\Documents`.
  - **Expected:** Folder names and file counts match Windows Explorer (same order not required). No server round-trip for file bytes.
  - **(blocked)** Requires Track 6: `UiDeviceFiles` wired to `RemoteFsApi.fsList()` instead of `_mockRoots()`.

### 3. Text preview (streaming)

- [ ] **Preview `spec.md` text — streams without full download to server**
  - **Steps:** Select a text file (e.g. repo `spec.md` copied to Documents, or any `.md` / `.txt`).
  - **Expected:** Preview pane shows content progressively via chunked `RemoteFsRead`; no upload to c35 CAS/server.
  - **Wire:** Only WS signaling + WebRTC `remote-fs` frames; server logs show no file payload storage.

### 4. File send (phone → PC)

- [ ] **Send 10 MB file phone → PC — progress UI, file appears on disk**
  - **Steps:** From Android app Files tab, use send/upload to target folder on PC.
  - **Expected:** Progress indicator; file lands on disk at chosen path; size matches source.
  - **(blocked)** Requires Track 6: `RemoteFsApi.fsWrite()` + upload UI (agent `fs_write` exists in `remotes/c_remote_core/src/webrtc/fs.rs`; Flutter client has no `fsWrite` yet).

### 5. Disconnect / reconnect

- [ ] **Kill WebRTC — dots update; Files tab shows reconnect prompt**
  - **Steps:** Stop agent (`taskkill` / close agent), or call `RemoteSession.stop()`, or disable network briefly.
  - **Expected:** **Left dot** gray within a few seconds; Files tab empty state / **Connect** prompt; **right dot** may also gray if agent fully stopped.
  - **Recovery:** Restart agent → cluster dot green → **Connect** again → left dot green.

### 6. TURN relay path

- [ ] **TURN path: force relay (block UDP) — still connects via Relay badge**
  - **Steps:**
    1. Confirm `C35_TURN_SECRET` set on server (local and/or cluster).
    2. Block direct UDP between app and agent (e.g. Windows Firewall outbound UDP to agent LAN IP, or test from restrictive NAT).
    3. Connect from Files tab.
  - **Expected:** Session still establishes; badge shows **Relay** (`RemoteConnectionMode.REMOTE_CONNECTION_MODE_RELAY`); list/preview still work (slower).
  - **(blocked)** Direct/Relay badge UI not wired until Track 6; until then check agent/app logs for `relay` ICE candidate selected.

---

## Troubleshooting

### WebRTC dot stays gray (left dot)

| Check | Action |
|-------|--------|
| Agent running? | `.\dev_agent.ps1`; cluster dot must be green first |
| Signaling | App logs: `remote offer sent` → agent `webrtc session created` → `remote answer applied` |
| Track 6 wiring | `page_devices.dart` may hardcode `webrtcConnected: false`; Files tab may not call `RemoteSession.start()` |
| Platform | Web platform unsupported; use Windows desktop or Android |
| ICE | App log / `chrome://webrtc-internals` (if available): any `failed` ICE state? |

### TURN / Relay fails

| Check | Action |
|-------|--------|
| Secret mismatch | `C35_TURN_SECRET` (server) must equal coturn `static-auth-secret` |
| UDP 3479 blocked | Open on firewall / cloud NSG toward `129.225.3.111` |
| Relay ports | Open UDP **49160–49260** on same host |
| STUN-only mode | If `C35_TURN_SECRET` empty, server returns STUN only — relay test will fail |
| DNS | `nslookup turn.alienai.id` → `129.225.3.111` |

Verify ICE config from server (authenticated WS):

- Response should include TURN URLs `turn:turn.alienai.id:3479?transport=udp` with non-empty `username` / `credential` when secret is set.

### Agent not answering offer

| Check | Action |
|-------|--------|
| Agent offline | Cluster dot gray — fix WS first (`C35_SERVER_URL`, JWT, network) |
| Wrong device | `device_iid` in offer must match paired agent |
| Session ID | Mismatched `session_id` drops signaling frames |
| Server relay | `remote_signaling_agent_frame` errors in server logs |
| Build stale | Rebuild agent: `cargo build -p c_remote_windows` |

### Mock data in Files tab (historical)

If the tree always showed `C:\Users\CHITO\...` regardless of disk, that was pre–Track 6 mock data. Current builds list real drives via `fsList('')`. If listing fails, check `remote-fs channel state=open` in logs.

---

## Implementation gaps (Tracks 0–6)

File audit before E2E (2026-09-21). Use this to know what should work vs what is still stubbed.

| Track | Status | Key files present | Gaps |
|-------|--------|-------------------|------|
| **0 — TURN** | Mostly done | `_/deployments/coturn/deployment.yaml`, `configmap.yaml`, `secret.yaml`; `_/docs/remote.md` ICE table | No `service.yaml` (hostNetwork — OK). Cluster apply / secret replace is manual. `turns:443` not configured. |
| **1 — ICE API** | Done | `servers/crates/mod_device/src/remote_ice_config.rs`, wired in `wire_ws/src/session.rs` | Local dev needs `C35_TURN_SECRET` in `.env.local` |
| **2 — Proto** | Done | `_/schemas/proto/c35/remote.proto`, Dart `remote.pb.dart` | — |
| **3 — Signaling** | Done | `remote_signaling.rs`, `wire_ws/agent_session.rs`, `session.rs` | — |
| **4 — Agent WebRTC + fs** | Mostly done | `remotes/c_remote_core/src/webrtc/{mod,session,fs}.rs`, `conn_ws.rs` | Screen capture is **stub** (TODO in `session.rs`); fs list/read/write implemented on agent |
| **5 — Flutter client** | Done | `remote_session.dart`, `remote_fs_api.dart`, `remote_fs_transfer.dart` | `fsList` / `fsRead` / `fsWrite`; upload queue + `pasteboard` |
| **6 — UI integration** | Done | `ui_device_files.dart`, `page_devices.dart`, `ui_device_fs_upload_panel.dart` | Tree-grid, sort, preview, transfers in master column |

**E2E impact:** Run smoke **§1–5** in the desktop app against a paired Windows agent. **§4** upload: use `+`, drag-drop, or Explorer **Ctrl+C** → Files **Ctrl+V** (Android picker path may differ).

---

## Quick reference

| Script | Purpose |
|--------|---------|
| `.\dev_server.ps1` | Local `server_ai` with cargo-watch |
| `.\dev_agent.ps1` | Build/run Windows agent + pairing UI |
| `flutter run` (in `clients/app`) | Flutter client |

| Port / URL | Use |
|------------|-----|
| `8080` | Local server (default) |
| UDP `3479` | c35 STUN/TURN |
| UDP `49160–49260` | TURN relay |
| `turn.alienai.id:3479` | ICE TURN/STUN host |
