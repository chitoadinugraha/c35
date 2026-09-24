# Bots + Devices Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship reusable `UIMasterDetail`, Bots page (3-pane), and Devices page (2-pane) per `_/docs/ui.md`, with mock `UIRemoteDevice`, grant-based pin/order/archive, and Add Device dropdown (pair code + flash coming soon).

**Architecture:** Device/bot records live on `ai.identity`; per-user list prefs (pin, sort order, archive) live on `ai.identity_grant.meta_json` (+ `is_pinned` column). `UIMasterDetail` is a shared layout primitive (CSA `masterDetail` pattern). Server adds small WS RPCs; minimal `mod_device` stub handles pair-by-code only.

**Tech Stack:** Flutter (`clients/app`), Rust (`servers/crates/*`), protobuf (`_/schemas/proto/c35/`), YugabyteDB.

## Global Constraints

- Read `spec.md` + `_/docs/ui.md` + `_/docs/identity.md` + `_/docs/chat.md` before coding.
- Naming: `ui_` widgets, `page_` pages, `l()` / `lError()` for logging.
- Pair code: 10 chars `[A-Z0-9]`, display `XXXXX-XXXXX` (`spec.md`).
- Bots: 3-pane (`nav | master | detail`). Devices: 2-pane (`master | detail`).
- `bot_peer` stop scope: per `chat.id` only (`ai_reply_enabled`).
- Verify: `cargo build -p server_ai` for Rust; `flutter analyze` in `clients/app` for Dart.
- Do not commit unless user asks.

---

## Multitask Map

```
Track 0 (Proto)     ──┬──► Track 2A (identity_list + grant_patch)
                      ├──► Track 2B (bot_peer_list + chat_stop/send)
                      └──► Track 2C (mod_device pair stub)

Track 1 (Flutter UI primitives) ──► Track 3 (Pages + API wiring)

Parallel start:
  • Agent A → Track 0 (finish first, ~30 min)
  • Agent B → Track 1 (no server deps)
After Track 0:
  • Agent C → Track 2A + 2B + 2C (can split 2B/2C to separate agents)
After Track 1 + Track 2:
  • Agent D → Track 3
  • Agent E → Track 4 (verify)
```

---

## Track 0 — Proto contracts (blocks server)

### Task 0.1: Extend `identity.proto`

**Files:**
- Modify: `_/schemas/proto/c35/identity.proto`
- Modify: `_/schemas/proto/c35/wire.proto` (WsReq/WsRes + InvokeReq if needed)

**Interfaces — produces:**

```protobuf
message IdentityRow {
  int64 iid = 1;
  string kind = 2;           // bot | remote | iot | site
  string type = 3;
  string alien_id = 4;
  string name = 5;
  string pic = 6;
  string meta_json = 7;
  int64 owner_iid = 8;
  int64 updated_ts_ms = 9;
}

// Per-viewer list row: identity + grant prefs for caller
message IdentityListRow {
  IdentityRow identity = 1;
  string grant_role = 2;       // admin | member | readonly | "" if owner-only implicit
  bool is_pinned = 3;
  int32 sort_order = 4;        // from grant.meta_json.sort_order, default 500
  int64 archived_ts_ms = 5;    // from grant.meta_json.archived_ts_ms, 0 = not archived
}

message ReqIdentityList {
  repeated string kinds = 1;   // e.g. ["bot"], ["remote","iot"]
  bool include_archived = 2;
}

message ResIdentityList {
  repeated IdentityListRow rows = 1;
}

message ReqIdentityGrantPatch {
  int64 resource_iid = 1;
  optional bool is_pinned = 2;
  optional int32 sort_order = 3;
  optional bool archived = 4;  // true = set archived_ts_ms=now, false = clear
}

message ResIdentityGrantPatch {
  IdentityListRow row = 1;
}
```

Wire slots (pick unused numbers in `WsReq`/`WsRes`):
- `identity_list = 27`, `identity_grant_patch = 28`

- [ ] **Step 1:** Add messages above to `identity.proto`
- [ ] **Step 2:** Add WsReq/WsRes oneof entries in `wire.proto`
- [ ] **Step 3:** Regen proto (next task)

---

### Task 0.2: Add `device.proto` (pair only)

**Files:**
- Create: `_/schemas/proto/c35/device.proto`
- Modify: `_/schemas/proto/c35/wire.proto` (import + InvokeReq or WsReq)

**Interfaces — produces:**

```protobuf
syntax = "proto3";
package c35;
import "c35/identity.proto";

// Client submits pairing code from agent/IoT screen (XXXXX-XXXXX or raw 10 chars)
message ReqDevicePair {
  string code = 1;
}

message ResDevicePair {
  IdentityListRow device = 1;
}
```

Use **InvokeReq** field `device_pair = 102` (HTTP invoke, same as channel connect).

- [ ] **Step 1:** Create `device.proto`
- [ ] **Step 2:** Wire into `InvokeReq`/`InvokeRes` in `wire.proto`
- [ ] **Step 3:** Register in `servers/crates/proto/build.rs` if not auto-discovered

---

### Task 0.3: Add `ReqBotPeerList` to `chat.proto`

**Files:**
- Modify: `_/schemas/proto/c35/chat.proto`
- Modify: `_/schemas/proto/c35/wire.proto`

**Interfaces — produces:**

```protobuf
message ReqBotPeerList {
  int64 bot_iid = 1;
  bool include_archived = 2;  // reserved; bot_peer uses chat row only for now
  int32 limit = 3;
}

message ResBotPeerList {
  repeated Chat chats = 1;
}
```

Wire: `bot_peer_list = 29` on WsReq/WsRes.

Note: `ReqChatStop` / `ReqChatSend` / `ResChatStop` / `ResChatSend` already exist — only server handlers missing.

- [ ] **Step 1:** Add messages to `chat.proto`
- [ ] **Step 2:** Add WsReq/WsRes entries

---

### Task 0.4: Regenerate protobuf

**Files:**
- Regen: `servers/crates/proto/`
- Regen: `clients/app/lib/c/pb/c35/`

- [ ] **Step 1:** Run existing protoc script (check `_/scripts/` or `servers/crates/proto/build.rs` pattern used in repo)
- [ ] **Step 2:** `cargo build -p server_ai` — must compile
- [ ] **Step 3:** `cd clients/app && flutter analyze` — generated files must parse

---

## Track 1 — Flutter UI primitives (parallel with Track 0)

### Task 1.1: `UIMasterDetail`

**Files:**
- Create: `clients/app/lib/widgets/ui/ui_master_detail.dart`

**Interfaces — produces:**

```dart
class UiMasterDetail extends StatelessWidget {
  const UiMasterDetail({
    super.key,
    this.nav,
    required this.master,
    required this.detailBuilder,
    this.selectedId,
    this.onSelectedIdChanged,
    this.breakpoint = 720,
    this.navWidth = 200,
    this.masterWidth = 320,
    this.onDrillBack,
    this.emptyDetail,
  });

  final Widget? nav;
  final Widget master;
  final Widget Function(String? id) detailBuilder;
  final String? selectedId;
  final ValueChanged<String?>? onSelectedIdChanged;
  final double breakpoint;
  final double navWidth;
  final double masterWidth;
  final VoidCallback? onDrillBack;
  final Widget? emptyDetail;
}
```

**Behavior (copy CSA `UiSiteProductsSection`):**
- Wide + `nav != null`: `Row(nav | master | Expanded(detail))`
- Wide + `nav == null`: `Row(SizedBox(masterWidth, master) | Expanded(detail))`
- Narrow + no selection: show `nav ?? master`
- Narrow + selection: show detail + optional back via `onDrillBack`
- `selectedId` null on wide → auto-pick first item (caller passes list length check)

- [ ] **Step 1:** Implement widget with divider colors matching Home (`0xFF27272A` border, `0xFF0C0C10` master bg)
- [ ] **Step 2:** `flutter analyze`

---

### Task 1.2: `UIInDevicePair` dialog

**Files:**
- Create: `clients/app/lib/widgets/devices/in_device_pair.dart`

**Interfaces — produces:**

```dart
Future<IdentityListRow?> inDevicePairAsk(BuildContext context);
```

**UI:**
- Title: `Pair device`
- TextField: hint `XXXXX-XXXXX`, uppercase, auto-insert hyphen after 5 chars
- Validate: exactly 10 `[A-Z0-9]` after stripping hyphen
- Actions: Cancel / Pair
- Returns `null` on cancel; on Pair calls callback param OR returns normalized code for caller to invoke API

- [ ] **Step 1:** Implement dialog + formatter
- [ ] **Step 2:** `flutter analyze`

---

### Task 1.3: Mock `UIRemoteDevice`

**Files:**
- Create: `clients/app/lib/widgets/devices/ui_remote_device.dart`

**Interfaces:**

```dart
class UiRemoteDevice extends StatelessWidget {
  const UiRemoteDevice({super.key, required this.deviceName, this.online = false});
  final String deviceName;
  final bool online;
}
```

**UI (mock):**
- Dark panel with placeholder screen (`AspectRatio 16/9`, centered `Icons.desktop_windows_outlined`)
- Toolbar row: mouse / keyboard / fullscreen icons (disabled or no-op)
- Badge: Online (green) / Offline (muted)
- Subtitle: `Remote control — coming soon`

- [ ] **Step 1:** Implement mock widget
- [ ] **Step 2:** `flutter analyze`

---

### Task 1.4: Row widgets

**Files:**
- Create: `clients/app/lib/widgets/bots/ui_bot_peer_row.dart`
- Create: `clients/app/lib/widgets/devices/ui_device_row.dart`

**`UiBotPeerRow`:** avatar + peer name, channel icon overlay, last msg preview, time, red stop icon when `!aiReplyEnabled`, unread badge.

**`UiDeviceRow`:** icon by kind (`remote` → laptop, `iot` → smart device), name, type subtitle, pin indicator, online dot from `meta_json.last_seen` if present.

- [ ] **Step 1:** Implement both rows
- [ ] **Step 2:** `flutter analyze`

---

## Track 2 — Server (after Track 0)

### Task 2A: `identity_list` + `identity_grant_patch`

**Files:**
- Create: `servers/crates/mod_identity/src/identity_list.rs`
- Create: `servers/crates/mod_identity/src/identity_grant_patch.rs`
- Modify: `servers/crates/mod_identity/src/lib.rs`
- Modify: `servers/crates/wire_ws/src/session.rs`

**Query `identity_list`:**

```sql
SELECT i.*, g.role, COALESCE(g.is_pinned, false), g.meta
FROM ai.identity i
LEFT JOIN ai.identity_grant g
  ON g.resource_iid = i.id AND g.grantee_iid = $caller AND g.deleted_ts IS NULL
WHERE i.deleted_ts IS NULL
  AND i.kind = ANY($kinds)
  AND (i.owner_iid = $caller OR g.grantee_iid = $caller)
ORDER BY COALESCE(g.is_pinned, false) DESC,
         COALESCE((g.meta->>'sort_order')::int, 500),
         i.updated_ts DESC
```

Filter archived: skip rows where `(g.meta->>'archived_ts_ms')::bigint > 0` unless `include_archived`.

**`identity_grant_patch`:**
- Upsert grant row for `(resource_iid, grantee_iid)` — **create owner grant on pair** (Task 2C)
- Patch `is_pinned`, merge `sort_order` / `archived_ts_ms` into `meta` JSONB
- Verify `can(user, resource)` before write

- [ ] **Step 1:** Implement `identity_list`
- [ ] **Step 2:** Implement `identity_grant_patch`
- [ ] **Step 3:** Wire in `wire_ws/src/session.rs`
- [ ] **Step 4:** `cargo build -p server_ai`

---

### Task 2B: `bot_peer_list` + `chat_stop` + `chat_send`

**Files:**
- Create: `servers/crates/mod_chat/src/bot_peer.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Modify: `servers/crates/wire_ws/src/session.rs`

**`bot_peer_list`:**

```sql
SELECT * FROM ai.chat
WHERE kind = 'bot_peer' AND bot_iid = $1 AND deleted_ts IS NULL
  AND owner_iid = $caller
ORDER BY last_msg_ts DESC
LIMIT $limit
```

Verify caller owns bot (`identity.owner_iid = caller` or grant).

**`chat_stop`:** `UPDATE ai.chat SET ai_reply_enabled = $stopped WHERE id = $1 AND kind = 'bot_peer' AND owner_iid = $caller`

**`chat_send`:** Insert `chat_msg` with `source = staff`, role = assistant or dedicated staff role per proto; push `SyncPush.chat_msg`.

Reference: `mod_channel/src/inbound.rs` for external msg shape.

- [ ] **Step 1:** `bot_peer_list`
- [ ] **Step 2:** `chat_stop` handler (proto already exists)
- [ ] **Step 3:** `chat_send` handler
- [ ] **Step 4:** Wire WS + `cargo build -p server_ai`

---

### Task 2C: Minimal `mod_device` + `device_pair`

**Files:**
- Create: `servers/crates/mod_device/Cargo.toml`
- Create: `servers/crates/mod_device/src/lib.rs`
- Create: `servers/crates/mod_device/src/device_pair.rs`
- Modify: `servers/Cargo.toml` workspace members
- Modify: `servers/crates/server_ai/Cargo.toml` (dep)
- Modify: `servers/crates/wire_http/src/invoke.rs`

**Pair logic (stub v1):**
1. Normalize code: strip hyphen, uppercase, len 10
2. Lookup pending pair on identity: `meta->>'pairing_code' = $code` AND `kind IN ('remote','iot')` AND not expired
3. On success: set `owner_iid = caller`, clear pairing code from meta, upsert `identity_grant(resource, caller, admin)`, return `IdentityListRow`
4. On fail: 400 friendly error

**Agent-side code generation** (remotes, later): agent registers with pairing code in meta until claimed.

- [ ] **Step 1:** Scaffold `mod_device` crate
- [ ] **Step 2:** Implement `device_pair`
- [ ] **Step 3:** Wire `InvokeReq.device_pair` in `invoke.rs`
- [ ] **Step 4:** `cargo build -p server_ai`

---

## Track 3 — Flutter pages + API (after Track 1 + 2)

### Task 3.1: Client APIs + stores

**Files:**
- Create: `clients/app/lib/c/device/device_api.dart`
- Create: `clients/app/lib/c/device/device_store.dart`
- Create: `clients/app/lib/c/bot/bot_api.dart`
- Create: `clients/app/lib/c/bot/bot_store.dart`
- Modify: `clients/app/lib/c/chat/chat_conn.dart` (add WS methods)

**`device_api.dart`:**

```dart
Future<ResIdentityList> identityList(List<String> kinds, {bool includeArchived = false});
Future<ResIdentityGrantPatch> identityGrantPatch(ReqIdentityGrantPatch req);
Future<ResDevicePair> devicePair(String code);  // invoke
```

**`bot_api.dart`:**

```dart
Future<ResBotPeerList> botPeerList(int botIid);
Future<ResChatStop> chatStop(int chatId, bool stopped);
Future<ResChatSend> chatSend(int chatId, String text);
```

Stores: `ChangeNotifier` with list state, selection ids, load/refresh methods.

- [ ] **Step 1:** Extend `ChatConn` with new WS RPCs
- [ ] **Step 2:** Implement APIs + stores
- [ ] **Step 3:** `flutter analyze`

---

### Task 3.2: `page_bots.dart` (3-pane)

**Files:**
- Create: `clients/app/lib/pages/page_bots.dart`
- Create: `clients/app/lib/widgets/bots/ui_bot_nav_list.dart`
- Create: `clients/app/lib/widgets/bots/ui_bot_peer_list.dart`
- Create: `clients/app/lib/widgets/bots/ui_bot_conversation.dart`

**Layout:**

```
UiPage(
  body: UiMasterDetail(
    nav: UiBotNavList(bots, selectedBotId, onSelect),
    master: UiBotPeerList(peers, selectedChatId, onSelect),
    detailBuilder: (id) => UiBotConversation(chatId: id, ...),
  ),
)
```

**Detail pane:**
- Reuse Home message list + `msg_trace_view` renderer
- Top bar: peer name, Stop/Resume toggle (`chat_stop`)
- Composer: staff send (`chat_send`)
- Stop indicator syncs back to master row

**Nav:** load `identityList(['bot'])` on init; auto-select first bot.

- [ ] **Step 1:** Build page shell with `UiMasterDetail`
- [ ] **Step 2:** Wire nav + master + detail to stores
- [ ] **Step 3:** Handle narrow drill-back
- [ ] **Step 4:** `flutter analyze`

---

### Task 3.3: `page_devices.dart` (2-pane) + Add dropdown

**Files:**
- Create: `clients/app/lib/pages/page_devices.dart`
- Create: `clients/app/lib/widgets/devices/ui_device_detail.dart`
- Create: `clients/app/lib/widgets/devices/ui_device_add_menu.dart`

**Add device dropdown (required):**

```dart
// ui_device_add_menu.dart — PopupMenuButton on trailing toolbar
PopupMenuButton<String>(
  icon: Icon(Icons.add),
  onSelected: (v) => switch (v) {
    'pair' => _onAddPair(),
    'flash' => _onFlashComingSoon(),
    _ => null,
  },
  itemBuilder: (_) => [
    PopupMenuItem(value: 'pair', child: ListTile(
      leading: Icon(Icons.link),
      title: Text('Add device'),
      subtitle: Text('Enter pairing code'),
    )),
    PopupMenuItem(value: 'flash', child: ListTile(
      leading: Icon(Icons.usb),
      title: Text('Flash device'),
      subtitle: Text('Coming soon'),
      enabled: false,  // or enabled + snackbar
    )),
  ],
);
```

**`_onAddPair`:** `final code = await inDevicePairAsk(context)` → `devicePair(code)` → refresh list → select new device.

**`_onFlashComingSoon`:** `ScaffoldMessenger.showSnackBar('Flash device — coming soon')`

**Layout:**

```
UiPage(
  trailing: UiDeviceAddMenu(...),
  body: UiMasterDetail(
    master: device list (search, pin/archive menu),
    detailBuilder: (id) => UiDeviceDetail(device),
  ),
)
```

**`UiDeviceDetail` tabs:**
| kind | tabs |
|------|------|
| `remote` | Remote (`UiRemoteDevice` mock), Task (stub), Skill (stub), Settings (name edit stub) |
| `iot` | Control (stub), Wiring (stub) |

Pin/archive/order: call `identityGrantPatch` on row menu actions.

- [ ] **Step 1:** `UiDeviceAddMenu` + pair dialog flow
- [ ] **Step 2:** Page shell + master list
- [ ] **Step 3:** Detail tabs with mock remote
- [ ] **Step 4:** Pin/archive via grant patch
- [ ] **Step 5:** `flutter analyze`

---

### Task 3.4: Wire navigation from Home

**Files:**
- Modify: `clients/app/lib/pages/page_ai_home.dart`

Replace:

```dart
void _openBots() => Navigator.push(... PageNavStub ...);
void _openDevices() => Navigator.push(... PageNavStub ...);
```

With `PageBots(conn: _conn)` and `PageDevices(conn: _conn)`.

- [ ] **Step 1:** Swap stubs for real pages
- [ ] **Step 2:** Pass shared `ChatConn` or create page-scoped connections consistently with Home

---

## Track 4 — Verification

### Task 4.1: End-to-end checklist

- [ ] `cargo build -p server_ai`
- [ ] `cargo test -p mod_chat` (if tests added)
- [ ] `cd clients/app && flutter analyze`
- [ ] Manual: Home → avatar → Bots opens 3-pane (empty state OK)
- [ ] Manual: Home → avatar → Devices opens 2-pane
- [ ] Manual: Devices → Add → Add device → pair dialog shows
- [ ] Manual: Devices → Add → Flash device → "Coming soon"
- [ ] Manual (with test data): pair code flow returns device row
- [ ] Manual: Bots → select bot → peer list → conversation → stop toggle

---

## Data Model Reference

| Entity | Table | Per-user UI prefs |
|--------|-------|-------------------|
| Device (remote/iot) | `ai.identity` | `ai.identity_grant` (`is_pinned`, `meta.sort_order`, `meta.archived_ts_ms`) |
| Bot | `ai.identity` | grant optional for shared bots; nav sort by name/updated |
| Bot conversation | `ai.chat` (`bot_peer`) | stop = `chat.ai_reply_enabled` (not grant) |

**Owner grant:** Always upsert `identity_grant(resource_iid=device, grantee_iid=owner, role=admin)` on pair/create so pin/order/archive uses one code path.

---

## Out of Scope (this plan)

- Real `UIRemoteDevice` streaming (WebRTC/agent) — mock only
- USB OTG flash flow — "Coming soon" menu item only
- IoT control/wiring implementation — stub tabs
- Bot create/edit UI on nav pane — list only
- `ReqChatListen` realtime subscription — optional follow-up; manual refresh OK for v1
- Sites page — reuse `UIMasterDetail` later (Phase 8)

---

## Self-Review (spec coverage)

| Spec requirement | Task |
|------------------|------|
| Bots 3-pane | 1.1, 3.2 |
| Bot nav list | 3.2 |
| Bot peer cards + stop icon | 1.4, 3.2 |
| Staff send + stop per conversation | 2B, 3.2 |
| Devices master/detail | 1.1, 3.3 |
| Pin/order/archive on devices | 2A, 3.3 |
| Remote tabs + mock UIRemoteDevice | 1.3, 3.3 |
| IoT tabs stub | 3.3 |
| Pair code `XXXXX-XXXXX` | 0.2, 1.2, 2C, 3.3 |
| Flash device coming soon | 3.3 |
| Shared message renderer | 3.2 (reuse Home widgets) |

---

## Agent Assignment Cheat Sheet

| Agent | Tasks | Est. |
|-------|-------|------|
| **A** | 0.1–0.4 | 1h |
| **B** | 1.1–1.4 | 2h |
| **C** | 2A | 1.5h |
| **D** | 2B | 1.5h |
| **E** | 2C | 1h |
| **F** | 3.1–3.4 | 3h |
| **G** | 4.1 | 30m |

**Critical path:** A → (C+D+E) → F → G. B can run fully parallel to A/C/D/E.
