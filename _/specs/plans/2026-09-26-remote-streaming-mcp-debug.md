# Remote streaming + MCP debug — multitask plan

**Date:** 2026-09-26  
**Goal:** Reliable Hyper-V / Windows remote screen streaming, correct presence UI, and MCP tooling so agents can debug and operate **Chito’s devices (owner_iid 99000)** without touching other users’ hardware.

**Status:** **Implemented** 2026-09-26 (rebuild Flutter app, Windows agent, MCP `npm run build`, reload Cursor MCP; redeploy `server_ai` for HTTP actions + billing bypass).

---

## Already landed (client + policy — prior + this pass)

| Change | Files |
|--------|--------|
| No “Session Paused” while Devices page open; disconnect 60s after **leaving** Devices | `remote_session.dart`, `page_devices.dart`, `ui_remote_device.dart` |
| **Alien AI Cloud** label + `last_seen_ts_ms` presence fix | `device_store.dart`, `ui_device_row.dart`, `ui_device_detail.dart` |
| Prefer SCTP MJPEG over empty VP8 track | `ui_remote_device.dart` |
| Doc: leave-devices disconnect | `_/specs/remote.md` |

Rebuild Flutter desktop before judging remaining video issues.

---

## Multitask map (7 tracks)

| Track | Name | Depends on | Delivers |
|-------|------|------------|----------|
| **A** | WebRTC video path (agent) | — | Real VP8 frames **or** stop advertising empty video track |
| **B** | Capture hardening (Hyper-V) | — | GDI/DXGI diagnostics, lock-screen/VM runbook |
| **C** | Client polish | A optional | FPS for video track, presence push refresh |
| **D** | MCP device observability | — | `device_list`, `device_get`, `device_log_tail` |
| **E** | MCP agent HTTP + billing bypass | D | New actions; `device.*` works for MCP allowlist owners |
| **F** | First-class MCP wrappers | E | `device_screenshot`, `device_command` (typed args) |
| **G** | Policy + docs | F | Cursor rule, `mcp-security.md`, `agent-debug.mdc` |

**Parallel waves**

- **Wave 1:** A + B + D (independent)
- **Wave 2:** C (after A), E (after D)
- **Wave 3:** F + G

---

## Track A — WebRTC video path (Windows agent)

### Problem

Agent adds VP8 `screen` track but `set_track_handler` only logs — Flutter may show black if SCTP is slow or absent.

```56:58:remotes/c_remote_windows/src/main.rs
    c_remote_core::webrtc::set_track_handler(std::sync::Arc::new(|_v_track, _a_track| {
        info!("WebRTC media tracks (video+audio) connected and ready");
    }));
```

### Option A1 (preferred): Implement encode loop

| File | Work |
|------|------|
| `remotes/c_remote_windows/src/video_stream.rs` (new) | VP8 encode from `capture_screen_diff_opt` / DXGI; sample write to `TrackLocalStaticSample` |
| `remotes/c_remote_windows/src/main.rs` | Wire handler to spawn video (+ optional audio) tasks |
| `remotes/c_remote_core/src/webrtc/session.rs` | Confirm codec negotiation matches encoder (VP8) |

**Verify:** Local `dev_agent.ps1` + app → Remote tab shows picture with **no** SCTP frames; FPS > 0 on video path.

### Option A2 (smaller): No fake track

| File | Work |
|------|------|
| `remotes/c_remote_core/src/webrtc/session.rs` | Add track only when handler registers encoder **or** env `C35_WEBRTC_VIDEO=0` |
| Client | Already prefers MJPEG when `screenFrame != null` |

**Verify:** SCTP-only stream stable at 15–25 fps in toolbar.

**Pick one in implementation** — do not ship both long-term.

---

## Track B — Capture hardening (Hyper-V / VM)

### Problem

DXGI often fails in VMs; static desktop yields low SCTP fps; lock screen yields black frames.

| File | Work |
|------|------|
| `remotes/c_remote_windows/src/screen_capture.rs` | On repeated GDI failure, log **once** at `warn` with HRESULT / context |
| `remotes/c_remote_windows/src/pair_loop.rs` or tray | Surface “desktop not capturable” hint in agent log |
| `_/specs/remote.md` | **Hyper-V checklist:** logged-in console session, disable Enhanced Session if capture breaks, run agent from install not one-off Downloads copy |

**Verify:** VM with visible Explorer → agent log contains `desktop screen streaming started`; MCP `device_screenshot` (Track E) returns non-empty JPEG.

---

## Track C — Client polish

| Item | File | Work |
|------|------|------|
| FPS counter | `remote_session.dart` | Count video renderer frames OR document SCTP-only FPS |
| Presence refresh | `device_store.dart` | On WS `identity` push or timer refresh while Devices page visible (if push missing, 30s poll) |
| Dot order tooltip | `ui_device_row.dart` | Optional: “WebRTC” before “Alien AI Cloud” in tooltip text for clarity |

**Verify:** Right dot green within 2 min of agent connect without manual full app restart.

---

## Track D — MCP device observability (Node `_/mcps/inst`)

Add tools that **do not** require LLM/billing — SQL + existing log patterns.

| Tool | Input | Output |
|------|-------|--------|
| `device_list` | `owner_iid` (default 99000) | Remote `ai.identity` rows: `id`, `name`, `type`, `online`, `last_seen_ts_ms`, `agent_version` |
| `device_get` | `device_iid`, `owner_iid` | One row + derived `cloud_online`, `meta` subset |
| `device_log_tail` | `device_iid` or `owner_iid`, `q`, `limit` | `ai.log` where `topic` ILIKE `conn/agent%` and text mentions device or webrtc |

**Files**

- `_/mcps/inst/src/device.ts` (new) — queries via existing `db.ts` pool
- `_/mcps/inst/src/index.ts` — register
- `_/specs/mcp-security.md` — document tools + owner scope

**Verify**

```text
device_list { owner_iid: 99000 }
device_log_tail { owner_iid: 99000, q: "webrtc", limit: 20 }
```

---

## Track E — Server: MCP agent actions + billing bypass

### E1 — `device_list` / `device_get` on HTTP agent (optional mirror of D)

If IDE should work without `DATABASE_URL`, add to `mcp_agent.rs`:

| Action | Handler |
|--------|---------|
| `device_list` | `mod_device::devices_for_owner(owner_iid)` |
| `device_get` | Single device + grant check |

### E2 — Freemium bypass for MCP `device.*`

**Problem:** `tool_exec` → dispatcher blocks `device.screenshot` on freemium (Chito hit this).

| File | Work |
|------|------|
| `mod_chat/src/tools/dispatcher.rs` | If `ctx.req_id` is MCP agent path **or** add `ToolContext.mcp_agent: bool`, skip freemium gate for `device.command`, `device.input`, `device.screenshot`, `computer_use.delegate` when `mcp_agent_owner_allowed(owner_iid)` |
| `mod_chat/src/mcp_agent.rs` | Pass flag into `ToolContext` |

**Verify**

```text
tool_exec { tool: "device.screenshot", owner_iid: 99000, args: { device_iid: <vm> } }
```

Returns JPEG metadata / base64 length, not paid-plan error.

---

## Track F — Typed MCP wrappers (ergonomic)

Thin wrappers over `tool_exec` (default `owner_iid: 99000`):

| Tool | Maps to |
|------|---------|
| `device_screenshot` | `device.screenshot` |
| `device_command` | `device.command` |
| `device_input` | `device.input` |

**Files:** `_/mcps/inst/src/agent_http.ts` or `device_agent.ts`

**Verify:** Same as E2 with simpler schema (`device_iid` required).

---

## Track G — Policy, Cursor rules, docs

### G1 — Cursor rule (owner consent)

Create `.cursor/rules/device-control-chito.mdc` (always apply):

- **Allowed:** Operate remote devices owned by **99000** via MCP (`device_*`, `tool_exec` device tools, `computer_use.delegate`) when user asks to debug/fix remote or computer use.
- **Forbidden:** `device.*` against devices not owned by 99000 unless user **explicitly** names another `owner_iid` and device.
- **Default regression:** **33000** + tester fixtures only.
- **Before destructive commands:** Confirm `device_get` owner matches intended account.

Mirror: `.agents/rules/device-control-chito.md`  
Run: `.\_\scripts\dev\sync_mcp_config.ps1` if MCP env docs change.

### G2 — Doc updates

| Doc | Add |
|-----|-----|
| `_/specs/mcp-security.md` | Device MCP tools, 99000 consent model |
| `_/specs/remote.md` | Link to this plan; MCP debug workflow |
| `.cursor/rules/agent-debug.mdc` | Row in MCP table for `device_list` / `device_log_tail` |

---

## Acceptance checklist (end-to-end)

1. Hyper-V VM paired; **both** status dots green (WebRTC + Alien AI Cloud).
2. Remote tab shows live desktop **> 5 minutes** view-only without pause overlay.
3. Leave Devices **> 1 min** → WebRTC dot gray; reconnect on re-enter.
4. MCP: `device_list` → VM id; `device_log_tail` → recent webrtc lines.
5. MCP: `device_screenshot` with `owner_iid: 99000` returns image (no billing block).
6. Agent in Cursor follows `device-control-chito` rule (no cross-user control).

---

## Test plan (per track)

| Track | Command |
|-------|---------|
| A/B | `cd remotes; cargo build -p c_remote_windows` (workspace `remotes/`) |
| C/D/F | `cd _/mcps/inst; npm run build` |
| C | `cd clients/app; flutter analyze` + manual Remote tab |
| E | `cd servers; cargo build -p server_ai` |
| E/F | MCP `tool_exec` / new tools against `127.0.0.1:8080` or cluster |

---

## Out of scope (later)

- Live WebRTC ICE/session state MCP (needs server-side session registry export).
- Tail agent **local** `%LOCALAPPDATA%\AlienAI\logs` from MCP (no wire yet — use `device.command` to `type` log on VM).
- Public ingress for `/v1/mcp/agent` (keep internal / dev).
