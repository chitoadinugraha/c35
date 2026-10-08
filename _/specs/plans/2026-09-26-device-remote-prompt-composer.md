# Device Remote prompt composer + bound chat contexts

> **Status:** implemented (v1 — server bound meta + RPCs, Remote composer + history sheet)
> **Goal:** Remote toolbar chat toggle with inline mini-composer, popup dense history, **+** new context, and **resume** among device-bound prompt threads — locked `@device` mention, normal Home inbox, no merge with unbound Home chats.

**Read first:** [`spec.md`](../../spec.md), [`_/specs/chat.md`](../chat.md), [`_/specs/remote.md`](../remote.md), [`_/specs/ui.md`](../ui.md), [`_/schemas/chat.sql`](../../_schemas/chat.sql), [`_/schemas/proto/c35/chat.proto`](../../_/schemas/proto/c35/chat.proto).

**Subagent model:** `inherit` only (repo rule). **Do not** use `*-fast` models.

---

## Product rules (locked for this plan)

| Rule | Behavior |
|------|----------|
| **Surface** | Devices → Remote tab → bottom bar (left of pan): **chat icon** toggles mini-composer **below** Ctrl / Alt / Win row (same expand pattern as virtual keyboard). |
| **Popup** | Chat icon secondary action (tap chevron / long-press / “History”) opens sheet: **dense** message list, **context switcher**, **+ New context**. |
| **Default context** | On open Remote for device **D**: use **last active** `chat_id` for **D** (client prefs), validated server-side; if missing/invalid → create first context or pick most recent bound thread (see server). |
| **+ New context** | New `kind=prompt` chat with `meta.bound_device_iid = D`; composer targets it; appears in Home inbox like any prompt thread. |
| **Resume** | User picks another bound thread for **D** from popup list; load history via `ReqChatMsgList`; sends use that `chat_id`. |
| **Locked mention** | Every send: `mention_ids` includes `iid:{device_iid}`; UI chip **not removable**; also set `device_iids: [device_iid]` on `ReqPrompt`. |
| **No Home bleed** | Do **not** reuse last global Home `chat_id` when opening Remote. Unbound Home chats (generic “New chat”) stay separate. |
| **No Home import (v1)** | Do not list or attach unbound Home threads in device popup. Optional v2: explicit “Continue on device” from Home. |
| **Many contexts per device** | **No** unique “one chat per device” constraint — multiple bound threads allowed; list by `last_msg_ts`. |
| **Archive** | If user archived a device-bound thread on Home, **resume** from Remote may still use it (show in list with archived badge) or **unarchive on send** — default: **unarchive on send** via existing `ReqChatPatch`. |
| **IoT + remote** | Same binding; `meta.bound_device_kind` optional (`remote` \| `iot`) for title/icon only. |
| **Log noise** | Remove `l('device files roots: …')` in `ui_device_files.dart` (unrelated cleanup, same release OK). |

---

## Architecture

**Server:** Store device binding on `ai.chat.meta` (`bound_device_iid`, optional `bound_device_kind`). New RPCs list/create bound contexts. **`ReqPrompt`** validation: when `chat.meta.bound_device_iid > 0`, require owner, enforce device mention + merge `device_iids`. Creation of bound chats only through **`ReqChatDeviceContextCreate`** (not `chat_id=0` on arbitrary prompt).

**Client:** `DevicePromptContextStore` per device (or one store keyed by `device_iid`) using `ChatConn` — active `chat_id`, thread list, message cache for popup, prefs `device_prompt_active_chat_{device_iid}`. **`UiDeviceDetail`** wires `deviceIid` + `chatConn` into remote bottom chrome. Prompt stream via existing `ChatConn.promptSend` / attach; optional thin inline assistant bubbles in popup only (v1: list + streaming tail).

**Inbox:** Bound chats remain `kind=prompt`; Home sidebar unchanged except optional subtitle from `meta_json` (track 6, optional).

---

## Schema / meta (no new table v1)

Use existing `ai.chat.meta` JSONB:

```json
{
  "bound_device_iid": 123456789,
  "bound_device_kind": "remote"
}
```

**Index (migration):**

```sql
CREATE INDEX IF NOT EXISTS idx_chat_prompt_bound_device
  ON ai.chat (owner_iid, ((meta->>'bound_device_iid')::bigint), last_msg_ts DESC)
  WHERE kind = 'prompt'
    AND deleted_ts IS NULL
    AND (meta->>'bound_device_iid') IS NOT NULL
    AND (meta->>'bound_device_iid') <> '0';
```

**Files:** [`_/schemas/chat.sql`](../../_schemas/chat.sql) (canonical comment + index), [`_/schemas/migrations/`](../../_schemas/migrations/) `20260926_device_prompt_context_v1.sql`.

Document keys in [`_/specs/chat.md`](../chat.md) new subsection **Device-bound prompt contexts**.

---

## Proto / wire

Add to [`_/schemas/proto/c35/chat.proto`](../../_schemas/proto/c35/chat.proto):

```protobuf
message ReqChatDeviceContextList {
  int64 device_iid = 1;
  bool include_archived = 2;
  int32 limit = 3;   // default 20, max 50
}

message ResChatDeviceContextList {
  repeated Chat chats = 1;
  repeated ChatMember members = 2;
}

message ReqChatDeviceContextCreate {
  int64 device_iid = 1;
  string title = 2;  // empty → server uses device display name + short suffix
}

message ResChatDeviceContextCreate {
  Chat chat = 1;
  ChatMember member = 2;
}
```

Wire [`_/schemas/proto/c35/wire.proto`](../../_schemas/proto/c35/wire.proto) (pick unused field numbers, e.g. **144–145**):

- `ReqChatDeviceContextList chat_device_context_list = 144;`
- `ReqChatDeviceContextCreate chat_device_context_create = 145;`
- Matching `Res*` in `WsRes`.

**Codegen:**

```powershell
.\_\scripts\protoc.ps1
cd servers; cargo build -p server_ai
```

---

## File map (planned)

| File | Responsibility |
|------|----------------|
| `servers/crates/mod_chat/src/device_context.rs` | list, create, meta helpers, ownership checks |
| `servers/crates/mod_chat/src/prompt_turn.rs` | bound-chat validation on prompt |
| `servers/crates/wire_ws/src/session.rs` | WS handlers |
| `clients/app/lib/c/remote/device_prompt_context.dart` | store: active chat, list, create, prefs, send wrapper |
| `clients/app/lib/widgets/devices/in_device_prompt_composer.dart` | slim composer (text, send, locked chip, Agent/Ask pill optional) |
| `clients/app/lib/widgets/devices/ui_device_prompt_sheet.dart` | popup: dense history + context list + **+** |
| `clients/app/lib/widgets/devices/ui_remote_device.dart` | chat icon + expand column (or extract `ui_remote_bottom_bar.dart`) |
| `clients/app/lib/widgets/devices/ui_device_detail.dart` | pass `deviceIid`, `chatConn`, device row into remote |
| `clients/app/lib/c/chat/chat_conn.dart` | RPC wrappers for new requests |
| `clients/app/lib/widgets/ai/in_composer.dart` | optional: `lockedMentionIds` param (if reusing chips); else keep device composer separate |
| `clients/app/lib/widgets/devices/ui_device_files.dart` | remove roots log line |

---

## Implementation tracks

| Track | Work | Depends |
|-------|------|---------|
| **0** | Docs draft + SQL index migration + proto/wire + codegen | — |
| **1** | `mod_chat/device_context.rs` — list, create, meta parse | 0 |
| **2** | `prompt_turn` bound validation + `device_iids` merge | 1 |
| **3** | `wire_ws` handlers + `ChatConn` Dart RPC | 0, 1 |
| **4** | `DevicePromptContextStore` + prefs + send helper | 3 |
| **5** | Remote UI: icon, mini-composer, mutual exclude with VKB | 4 |
| **6** | Popup sheet: history, switch context, **+**, streaming tail | 4, 5 |
| **7** | Home inbox polish (optional subtitle/icon from meta) + docs lock | 1 |
| **8** | Tests, analyze, manual QA checklist | all |

### Parallel waves

| Wave | Tracks (parallel) |
|------|-------------------|
| **1** | **0** |
| **2** | **1** + **3** (Rust handler stubs after 0 proto) |
| **3** | **2** + **4** |
| **4** | **5** + **7** |
| **5** | **6** |
| **6** | **8** |

---

## Track details

### Track 0 — Schema, proto, docs

- [ ] Add migration + index; update `chat.sql` comment block for `meta.bound_device_iid`.
- [ ] Extend `chat.proto` + `wire.proto`; run `protoc.ps1`; `cargo build -p server_ai`.
- [ ] Add **Device-bound prompt contexts** section to `_/specs/chat.md` (invariants, RPC names, UI surfaces).
- [ ] Add short **Remote AI composer** bullet to `_/specs/remote.md` + `_/specs/ui.md` Devices section.

**Acceptance:** Proto compiles; migration applies on dev YB; docs describe locked mention + multi-context.

---

### Track 1 — Server `device_context`

**Create** `servers/crates/mod_chat/src/device_context.rs`:

- `chat_device_context_list(pool, owner_iid, req)`  
  - Verify caller owns device (`ai.identity` grant/owner check — match `mod_device` patterns).  
  - `WHERE c.kind='prompt' AND c.owner_iid=$owner AND (c.meta->>'bound_device_iid')::bigint = $device AND c.deleted_ts IS NULL`  
  - Join `chat_member`; respect `include_archived`; `ORDER BY c.last_msg_ts DESC`; `LIMIT`.

- `chat_device_context_create(pool, owner_iid, req)`  
  - Same ownership check.  
  - `snowflake_id()` insert `ai.chat` with title (device name or `title`), `meta` JSON bound fields.  
  - Insert `chat_member` in same transaction (mirror `chat_ensure`).

- Export from `mod_chat/lib.rs`.

**Acceptance:** Unit/integration test with `C35_TEST_DB=1` — create two contexts for same device; list returns both ordered by activity.

---

### Track 2 — Prompt validation

In `prompt_turn` after `chat_ensure` / when `req.chat_id > 0`:

- Load `meta.bound_device_iid` for chat.  
- If `bound > 0`:  
  - Assert chat owner matches `owner_iid`.  
  - Assert `bound` is in resolved mentions **or** inject `iid:{bound}` server-side (prefer inject + log if client omitted).  
  - Union `req.device_iids` with `bound`.  
- Reject with clear wire error if chat is bound to **different** device than mention/device_iids.

**Do not** auto-bind on random `chat_id=0` Home prompts.

**Acceptance:** Test — bound chat + wrong device mention fails; correct mention succeeds; `device_iids` populated on run row.

---

### Track 3 — Wire + `ChatConn`

- `wire_ws/session.rs`: dispatch list/create.  
- `clients/app/lib/c/chat/chat_conn.dart`:  
  - `chatDeviceContextList(...)`  
  - `chatDeviceContextCreate(...)`

**Acceptance:** Manual invoke from dev harness or flutter test mock — list returns after create.

---

### Track 4 — `DevicePromptContextStore`

**Create** `clients/app/lib/c/remote/device_prompt_context.dart`:

- Fields: `deviceIid`, active `chatId`, `contexts[]`, `messages[]` (popup cache), `composerOpen`, `streaming` state.
- `init()`: read prefs → `chatDeviceContextList` → if active id not in list, pick latest or `create`.
- `contextCreate()` → **+** button.
- `contextSelect(chatId)` → persist prefs, reload messages.
- `promptSend(text, {toolMode})` → build `ReqPrompt` with `chatId`, `mention_ids: ['iid:$deviceIid']`, `device_iids: [deviceIid]`, stream via `chatConn.promptSend`.
- Listen `PromptStreamEvent` / `onPromptRunPush` for active chat to refresh preview + append assistant delta in popup.
- On successful `prompt_start`, patch local active id; optionally call `chatPatch` unarchive if needed.

**Acceptance:** Store unit test (mock conn) for prefs + active id selection logic.

---

### Track 5 — Remote toolbar UI

Modify `ui_remote_device.dart` (or extract bottom bar widget):

- Add **chat** icon **left of** pan button (match amber/zinc styling).
- Toggle `_promptOpen` — when open, show `InDevicePromptComposer` below modifier row; when VKB open, close prompt (mutually exclusive).
- Props from parent: `DevicePromptContextStore` or callbacks.

Modify `ui_device_detail.dart`:

- Instantiate store when Remote tab active / device row known.
- Pass `deviceIid`, `chatConn`, device display name into remote widget.

**Acceptance:** Manual — icon toggles composer; VKB and composer don’t stack; send disabled when offline (match remote gating).

---

### Track 6 — Popup sheet

**Create** `ui_device_prompt_sheet.dart`:

- `showModalBottomSheet` / side panel on wide layout (follow Devices master/detail breakpoints).
- Top: current context title + dropdown/list of contexts (preview + relative time).
- **+ New context** FAB or header button → `contextCreate`.
- Body: `ListView` dense tiles (role, 1-line content, time); load more via `chatMsgList` pagination.
- Bottom: same mini-composer or pinned send bar.
- During active stream: show typing indicator on last assistant row; scroll to bottom.

**Acceptance:** Manual — switch context shows different histories; **+** creates new empty thread; send appears in Home inbox after sync.

---

### Track 7 — Home inbox polish (optional but recommended)

- When rendering Home chat list row, if `meta_json.bound_device_iid > 0`, show device glyph + truncated device name (resolve from local device cache / identity list).
- No filter hide — threads stay in main inbox.

**Acceptance:** Device-bound thread recognizable on Home; tapping opens Home chat (not required to deep-link Devices in v1).

---

### Track 8 — Verification

**Rust:**

```powershell
cd servers
cargo test -p mod_chat device_context
cargo build -p server_ai
```

**Flutter:**

```powershell
cd clients/app
flutter analyze
flutter test test/chat_store_test.dart
```

**Manual QA**

1. Devices → Remote → chat icon → send “list files” → trace shows device tools / mention gate.
2. **+** → new context → old history not visible until resumed from popup.
3. Two devices → two separate bound thread lists.
4. Home generic new chat ≠ Remote default context.
5. Archive thread on Home → resume on Remote → send unarchives (if policy enabled).
6. No `device files roots:` line in debug log when browsing Files tab.

**Rollout**

- Wire additive proto — **no** `min` bump.
- Ship server migration before or with app.
- No agent publish required.

---

## Open decisions (defaults chosen)

| Question | Default |
|----------|---------|
| First visit, no contexts | Auto-**create** first bound chat (title = device name) |
| Composer feature parity | v1: text + Agent/Ask pill; no attachments/voice in mini composer |
| Inline bubbles on stream canvas | v1: popup/sheet only; optional toast “Reply in chat panel” |
| `InComposer` reuse | Prefer **`InDevicePromptComposer`** slim duplicate to avoid pulling full Home deps into Remote |
| Server inject missing mention | **Yes** if `bound_device_iid` set (defense in depth) |

---

## Out of scope (v1)

- Import unbound Home chat into device context.
- Deep link Home row → Devices Remote with composer open.
- Separate inbox section “Device chats only”.
- Flash IoT Device flow (separate menu item).

---

## Agent execution checklist

When implementing with subagents:

1. Wave 1 → **Track 0** complete before parallel Rust/Dart RPC.
2. Each track PR/commit should pass its **Acceptance** + `verify-after-edit.mdc` checks.
3. Update this plan **Status** to `implemented` when wave 6 manual QA passes.
4. Do not edit locked docs without matching behavior (`read-spec-before-implement.mdc`).
