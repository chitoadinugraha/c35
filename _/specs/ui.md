# UI specification (LOCKED)

Status: **locked** 2026-09-20

## Design goals

- Mobile-first, single-space feel (no space picker)
- Simple enough for non-technical users
- Never show raw errors (ErrorBoundary-style); log technical detail server-side
- Compact chrome: custom appbar from `cs_agent`, layout from `alienai_proto`

## Shell layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Alien AI v…  [server ▼]  Title                    [canvas] [avatar]  _ □ × │
└─────────────────────────────────────────────────────────────────────────┘
│ chat list │                    chat detail                    │ canvas │
│ (drawer   │                                                   │ (end   │
│  mobile)  │                                                   │ drawer)│
└───────────┴───────────────────────────────────────────────────┴────────┘
```

### Title bar

| Element | Behavior |
|---------|----------|
| Server picker | Switch server host (from cs_agent) |
| Title | Current page/context name |
| Canvas toggle | Visible **only** when canvas content exists |
| Avatar | Opens user menu (see below) |

### Responsive behavior

| Breakpoint | Chat list | Canvas |
|------------|-----------|--------|
| Large | Master column (always visible) | Side panel, toggleable |
| Small | Start drawer | End drawer, toggleable |

## Avatar menu

On avatar tap:

```
┌──────────────────────────────┐
│  (avatar)  Name              │
│  Profile → Settings          │
│  Partner / Root menu         │
│  ○ 5h quota    ○ weekly quota│
│                              │
│  (🤖 5) (📱 9) (🌐 1)        │  ← counts
│                              │
│  🌳 referral  🔒 lock  ⎋ out │
└──────────────────────────────┘
```

| Action | Destination |
|--------|-------------|
| Profile | Settings page (copy cs_agent) |
| Partner/Root | Root admin menus |
| Bot icon + count | Bots page |
| Device icon + count | Devices page |
| Site icon + count | Sites page |
| Mail (staff / shared mailbox) | `PageMail` — CSA parity inbox + composer; see [mail.md](mail.md) |
| Notifications | History page. Unread count from `ReqNotifyList`. See [notify.md](notify.md) |
| Referral tree | Referral page (copy cs_agent) |
| Talk | Home surface switch. Same thread as Chat. See [Talk](#talk). |
| Lock | Session lock |
| Logout | Sign out |

**No space picker.** Personal AI is Home; bots/devices/sites are separate pages.

### Notifications

- **Entry:** avatar menu **Notifications** opens the history page (`ReqNotifyList`; tap sends `ReqNotifyRead`).
- Unread count comes from `ReqNotifyList` (`unread_only`).
- Deliver, banner vs local shade, and FCM: [notify.md](notify.md).

### Mail (platform email)

- **Entry:** avatar menu footer — **`9+` / `1`–`9` + mail icon** (left of referral tree); Settings tile when `Session.canUseMail`. Unread = sum of all mailboxes; loaded on **`ResSessionInit.nav`** (`mail_inbox_unread`, `mail_menu_visible`) and cached per uid in prefs until session init refreshes.
- **UI:** `clients/app/lib/pages/mail/page_mail.dart` — ported from CSA `e34b9bf2` (master/detail, AppFlowy composer, attachments, mailing lists, broadcast).
- **Wire:** `MailApi` → `ChatConn.rpc` / `WsReq` mail_* fields (see `_/schemas/proto/c35/mail.proto`).
- **Admin** (domain onboard, mailbox CRUD): server RPCs shipped; Flutter admin panel (`UiPartnerMailPanel` parity) — follow-up; use MCP/SQL or deploy after panel lands.

## Home (personal AI chat)

- Home master column = **AI inbox** (`prompt` only) — sorted by **`last_msg_ts`** — see [chat.md](chat.md)
- User-to-user chat (`direct`) is **deferred** — not in Home inbox
- Binds to signed-in **`user` identity** — `chat.kind = prompt`
- Master/detail chat list + conversation
- Inbox lists **`prompt`** AI threads only via `chat_member`, sorted by `last_msg_ts`
- Features: pinned, archived, `#tag` search
- **Empty-state hints** — server-precompiled chips (Track Consumption, Track Expense, recent sites with Visit/POS); cached in `SessionInit` — see [hint.md](hint.md)
- Message renderer: input/output tokens, duration, cost (copy cs_agent `msg_trace_view`)
- Custom **UI blocks** renderable inside messages (`presentation.deck`, `consumption.food`, `expense.glance`, `image`, `file`).
- Presentation slide decks: rendered via `UiSlideDeckCard` (100% native Flutter, zero WebView). Collapses into a small card with slide count and timestamp; expands to a 16:9 widescreen preview with pagination and slide-level patching (`presentation.md`).
- Canvas: document/slide editor when AI produces canvas content.

### Talk

Talk and Chat are two surfaces on one Home thread (`chat.kind = prompt`, same `chat_id`, same `ai.chat_msg` rows). Talk does not create a chat, a topic, or a message role. Turning Talk off shows the turns that were spoken in the normal transcript. Voice engines and billing stay in [voice.md](voice.md). Live Call is a separate realtime session ([live-call.md](live-call.md)).

| | Chat | Talk |
|---|---|---|
| Surface | Thread plus `InComposer` | `UiTalkStage` — latest exchange only |
| Entry | Default (`talkEnabled` false) | Avatar sheet **Talk Mode** toggle (left) or welcome **Call** chip (right) |
| Send | Composer, including its mic | Stage mic. Sets `ReqPrompt.talk` |
| Reply length | Unchanged | `inst.talk.brief` on that turn |
| Read aloud | Bubble menu **Read aloud** only (no auto TTS) | `VoicePrefs.talkSpeakEnabled` (default on); stage speaker toggles it; auto TTS after each Talk turn when on |

**Prefs.** `VoicePrefs.talkEnabled`, key `voice_talk_enabled`, default false. Device-local, same store as the other voice prefs. Avatar sheet: **Talk Mode** / **Chat Mode** chip (~45% width; idle styling matches **Call** chip; cyan when Talk is on) and full-title **Call** chip (~55%, same dropdown as welcome); picking an offer starts Live Call and turns Talk off.

**Page.** The existing home header stays. Leave Talk from the avatar sheet. On an empty thread (no user or assistant rows yet, not busy), the main area shows the same welcome as Chat (`home.heroTitle`, `home.heroSubtitle`, Alien icon, hint chips) via `_threadHero()`. Once there is a turn, the scroll shows the latest assistant text at a large size. That text is the live `msgStreamContent` stream. `UiMsgBlocks` for that assistant row render in the same scroll when `blocks_json` is non-empty.

**Status row** (centered above the transcript when listening, thinking, or usage stats; empty when idle):

| State | Copy |
|--------|------|
| Idle | *(empty)* |
| Mic open, no interim text | **Listening...** |
| Prompt in flight | **Thinking...** |
| Turn finished, usage setting on | `{in} · {out} · {duration}` |

**Transcript strip.** Rounded chip above the bottom bar. Shown only after the user has spoken text (including live STT while recording). Not shown on the empty idle state.

**Bottom bar.** Mic is centered; attach is bottom-aligned on the left screen edge; speaker and model icons are bottom-aligned on the right. Attach stages files until the next voice send, then the turn uses the same `_composerSend` as Chat. Mic uses `SttService` with **Talk VAD**: when **Auto send** (`VoicePrefs.sttAutoSend`, composer waveform menu) is on, silence auto-stops and sends like chat (slightly longer pauses: 1100ms / 1400ms); when off, tap mic again or **Send** on the transcript chip. Max recording **60s** then auto-send either way. Composer Chat mic keeps silence VAD (700ms / 1100ms). While a prompt is busy, the mic is Stop and calls `_abortPrompt`. The speaker icon toggles `talkSpeakEnabled` (Talk-only auto read-aloud). Starting the mic calls `TtsService.stop`. The model icon opens the same model sheet as Chat; the **active** model is pinned at the top in a card (checkmark, thinking chips when supported), with its provider group expanded.

**Wire.** `ReqPrompt.talk` (field 10) is true only for sends from this surface. Compose appends mention id `talk` to the in-memory inst match list. The id is not written onto the user message and is not a catalog mention. Inst id `inst.talk.brief`, kind `trigger`, trigger `mention:talk`. Chat sends leave `talk` false. See [inst.md](inst.md).

### Chat row menu

- Rename
- Tag (tag editor dialog; `#tag` derived from title)
- Pin
- Archive
- Archive Below (when messages exist below)

### Composer Controls: Mentions & Slash Commands

The prompt composer supports dual-channel intent modifiers:

1. **Entity Mentions (`@`)**:
   - **Trigger**: Typing `@` opens an auto-complete suggestion box of tools, remote devices, and builder sites.
   - **Behavior**: Inserts an in-line **chip** in the composer (object-replacement tokens). On send, message text on the wire and in **`ai.chat_msg.content`** uses the locked bracket form **`[@iid:<snowflake>]`** or **`[@catalog:<id>]`** so history reload keeps mention context. See **[mention.md](mention.md)**.
   - **Keyboard Navigation**: `ArrowDown`/`ArrowUp` to cycle, `Tab` or `Enter` to select, `Escape` to dismiss.

2. **Slash Commands (`/`)**:
   - **Trigger**: Typing `/` at the start of the composer opens the command palette.
   - **Available commands**:
     - `/ask <query>`: One-shot query executed with `tool_mode = 'ask'` (read-only conversational answering without tool mutations). Composer remains in default `Agent` mode for subsequent turns.
     - `/model`: Opens the model selection picker.
     - `/clear`: Resets the input draft and opens a new chat thread.
   - **Keyboard Navigation**: `ArrowDown`/`ArrowUp` to cycle, `Tab` or `Enter` to select, `Escape` to dismiss.

3. **Persistent Mode Pill**:
   - Located on the composer action bar: `⚡ Agent` (default, full tools & devices) ↔ `💬 Ask` (read-only, fast).
   - Tapping toggles `tool_mode` for persistent multi-turn conversations.

## Canvas Sidecar Workspace

Canvas transforms the chat from an ephemeral timeline into a dual-pane collaborative workspace for living documents, multi-file code, and reports.

### Trigger & Discovery
1. **Explicit Code Block Promotion**: Any code block rendered in assistant messages displays an `"Open in Canvas"` action in its header alongside the copy button.
2. **AI Canvas Artifacts**: When an AI turn produces structured canvas blocks (`kind: 'canvas.artifact'`), the sidecar automatically stages the artifact.
3. **Canvas Header Toggle**: The `[canvas]` button in the top title bar becomes active and displays a badge whenever an artifact is active in the current conversation.

### Layout & Responsiveness
- **Desktop (Large Breakpoint >= 720px)**:
  - 3-column split layout: `[chat list: 280px] | [chat detail: flex] | [canvas side panel: 440px-540px]`.
  - Resizable / collapsible side panel with smooth slide-in transition.
- **Mobile (Small Breakpoint < 720px)**:
  - Canvas opens inside a dedicated `endDrawer` with safe-area padding.

### Features & Capabilities
1. **Header Bar**:
   - Artifact title & file/language badge (e.g. `Dart`, `Python`, `Markdown`, `JSON`).
   - Version scrubber / dropdown (e.g. `v1`, `v2`, `v3`) with timestamps and restore capability.
   - One-click copy, download/export, and close button.
2. **Dual-Mode Viewer / Editor**:
   - **Editor / Code Tab**: Monospace editor with line numbering and direct bidirectional editing. Changes can be saved locally to form a new version snapshot.
   - **Preview Tab**: Formatted live preview for Markdown, HTML previews, or rich visual documents.
3. **Iterative AI Prompting**:
   - Quick action pill in the canvas footer: *"Iterate with AI"* opens the composer with an active context reference to the canvas artifact.

## Referral tree

Forest chart, node badges (Root / Partner / Director / …), and staff admin on user profiles. **RBAC and audit:** [`referral.md`](referral.md).

Build follows cs_agent UX (pan/zoom forest, share %, profile sheet, codes list). Wire uses c35 `ai.identity` + `admin_user_put` + `referral_tree_get`.

## Settings

Build **exactly** like `D:\cs_agent` — including language flag icon.

## Bots page (3-pane)

Pattern: `csa_site_published` site editor.

```
┌──────────┬─────────────────┬──────────────────────┐
│ bot list │ conversations   │ conversation detail  │
│ (nav)    │ (master)        │ (detail)             │
└──────────┴─────────────────┴──────────────────────┘
```

### Nav — bot list

Lists `identity(kind=bot, type=chat)` for current owner. Each row = one bot identity (may run Telegram + WhatsApp + … via `meta.channels[]`).

#### Bot Creation Wizard (`InBotCreate`)
- 4-step wizard: Basic info (name, avatar) → Connect channels (Telegram, WhatsApp Meta, WhatsApp Device) → Assets → Instructions & behavior (instructions, strict mode, block spammer, web search).
- Home chat can draft the same bot (`bot.draft`): purpose, instruction, and sheet access. The bot stays off. Channel connect stays in this wizard.
- **Draft Cancellation**: If setup is cancelled or dismissed after channels have been added, the client automatically triggers draft cleanup (`_cleanupDraft`), disconnecting all channels (deleting Telegram webhooks and terminating WhatsApp sessions) and deleting the draft identity to prevent orphaned sessions.

#### Bot Deletion Dialog (`IoBotDeleteDialog`)
Bot deletion uses the high-safety confirmation pattern (matching site deletion):
1. **Name Matching**: User must type the bot name or handle.
2. **Slide to Confirm (`UiSlideConfirm`)**: Unlocks once the name matches; user drags thumb across track.
3. **Countdown Timeout**: 3-second countdown (`3... 2... 1...`) with tabular figures.
4. **Action & Session Wipe**: Red "Permanently Delete Bot" button initiates deletion, halting workers, wiping disk sessions, removing webhooks, and deleting DB records.


### Master — conversation list

**One bot, many channels** — selecting a bot shows conversations across all its channels. One row per external user per channel (not one row per bot).

Card layout (Telegram/WhatsApp style):

```
┌────────────────────────────────────────┐
│ (user av) Title                  (time)│
│           last msg truncated  [stop?]  │
└────────────────────────────────────────┘
```

- Small channel icon bottom-right on avatar
- Red stop icon on master when **`ai_reply_enabled = false`** on that conversation (not whole bot/channel)
- Unread count when stopped (human intervention mode)

See [chat.md](chat.md) for full chat kinds and stop scope.

### Detail — conversation

- Full message thread
- Human operator can send manual messages (`chat_msg.source = staff`) anytime
- **Stop** button top — sets `chat.ai_reply_enabled = false` on **this conversation only**
- Resume re-enables AI auto-reply for this conversation only
- When stopped: red stop indicator on master card

## Devices page

Master/detail list of **`kind IN ('remote', 'iot')`** the caller owns or has a live grant on (shared devices included). Supports order, pin, archive. Account-menu device count uses the same set, excluding archived grants.

### Device row (remote)

Each remote row shows name + type subtitle (e.g. `CHITO` / `windows`) and **two trailing dots**:

| Dot | Meaning |
|-----|---------|
| Left (Alien AI Cloud) | Agent ↔ server — presence, tasks |
| Right (WebRTC) | App ↔ device data plane — files, screen, media |

When Alien AI Cloud is down, the type subtitle is **Device is offline**.

**WebRTC dot (right):** grey idle → orange connecting → green connected → red failed. **Connect-first:** no auto WebRTC on device select; **Connect** / **Retry** only in the center of the Remote pane (Files has its own **Connect**). Full color table: [remote.md § WebRTC dot colors](remote.md#webrtc-dot-colors-right--connect-first-locked).

**Cloud dot (left):** green when agent online, grey when offline (NATS `device_presence` push + `meta.last_seen_ts_ms`). Tooltip **Device is offline** when grey.

IoT rows keep a single online dot (green/grey).

### IoT device (`kind=iot`)

Tabs:

| Tab | Content |
|-----|---------|
| Control | Device controls |
| Wiring | Setup wiring diagram + debug controls |

### Remote device (`kind=remote`)

Tabs:

| Tab | Content |
|-----|---------|
| Remote | `UIRemoteDevice` — WebRTC screen + input |
| Files | WebRTC file explorer — tree-grid + preview (wide). See [Files tab](#files-tab-remote) below |
| Task | Scheduled/one-shot tasks |
| Skill | Manual + automatic (self-learned) skills; Teach button |
| Settings | Name, instructions, device config |

**`type=browser` (Remote browser):** same **two connection dots** (Cloud + Direct WebRTC). Remote tab reuses `UIRemoteDevice`; add tab strip for browser pages when shipped. **No Files tab in v1.** Subtitle: “Remote browser”. See [browser-remote.md](browser-remote.md).

Remote agent attaches skills/tasks to device **identity id**.

### Files tab (remote)

**Transport:** SCTP data channel `remote-fs` (protobuf `RemoteFs*`). Requires **WebRTC connected** (right dot on device row). Bytes are app ↔ device direct — not stored on cluster unless user saves elsewhere. See [`remote.md`](remote.md#files-tab--browse-copy-stream).

**Devices master column:** while a device is selected, **Transfers** shows slim progress bars for active uploads/copies (queued jobs for that device).

**Layout**

| Width | Explorer | Preview |
|-------|----------|---------|
| Wide (≥1024px) | Search + ops + sortable tree-grid | Right pane — text / image preview |
| Narrow | Full-width explorer | Tap previewable file → full-screen preview with back |

**Explorer chrome**

- **Search** — filter visible tree (expands matching branches).
- **`+`** — multi-select local file picker → upload into current folder.
- **Ops row** — Download, New folder, New file, Rename, Delete, Cut, Copy, Paste (toolbar tooltips document paste priority).
- **Column headers** — tap Name / Size / Type / Modified to sort (toggle asc/desc; Name keeps folders before files).
- **FAB** (when transfers active) — badge count; opens transfer sheet.

**Drive roots** — agent sends volume label + `RemoteFsDriveKind` (local / USB / network / DVD / RAM). Icons: `storage`, `usb`, `folder_shared`, etc.; amber tone matches folders.

**Upload from your computer (desktop)**

| Method | Behavior |
|--------|----------|
| **`+` or drag-drop** | Enqueue upload to selected folder |
| **Ctrl+C in Explorer → Ctrl+V in Files** | `Pasteboard.files()` → upload queue (files + local folders via tree upload) |

**Copy / paste inside Files**

| Action | Scope |
|--------|--------|
| **Copy** (toolbar, context menu, Ctrl+C) | Selected **file** on device → in-app clipboard (paths) |
| **Paste** (toolbar, Ctrl+V / Cmd+V) | If OS clipboard has files → **upload**; else if in-app clipboard → **duplicate on device** (read/write chunks, auto-rename collisions) |

**Download** — toolbar or context menu; `file_picker` save (single file on Android) or folder pick; `RemoteFsTransfer.downloadRemote` (files + folder trees).

**Mutations** — New folder (`fsMkdir`), Rename (`fsRename`), Delete (`fsDelete` + confirm). Drive roots cannot be deleted.

**Drive roots (Windows remote only)** — When `device.type` is `windows` (or other desktop agent), empty path lists volume roots with `RemoteFsDriveKind`. **Alien AI Drive** (`A:`) appears only on Windows agents with drive enabled — not on Android remotes ([`drive.md`](drive.md), [`remote.md`](remote.md#cross-platform-drive-vs-device-files)).

**Android client matrix** (Alien AI app on phone/tablet — browsing a **remote Windows** PC over WebRTC)

| Capability | Android | Notes |
|------------|---------|--------|
| Browse / list / sort | Supported | Same tree-grid; narrow width hides Size/Type/Modified columns |
| Text / image preview | Supported | Same caps (2 MB text, 512 KB image) |
| Upload (`+`) | Supported | `file_picker`; content URIs staged to app temp before chunk upload |
| Download | Supported | Single file → `saveFile`; multi-item / folder → SAF directory pick |
| In-app copy / cut / paste (device) | Supported | Duplicate on remote device |
| OS clipboard → upload | N/A | No Explorer-style file paths; use `+` picker |
| Drag-drop upload | N/A | Desktop only (`desktop_drop` not used on mobile) |
| Video play (WebRTC) | Supported | When agent ships media track (desktop agent) |
| Background transfers | Degraded | Snackbar warns to keep app open; no wakelock in v1 |
| Local ffmpeg OTA | N/A | Play build — agent-side tools only |

**Android remote device matrix** (`device.type == android` — Files tab shows **that paired phone’s** storage, not a PC)

Applies when the selected device is an Android **remote agent** (`id.alienai.remote`), from any client (desktop or mobile). Path grammar and SAF grants: [`remote-android.md`](remote-android.md#8-storage-paths-for-remote-fs-files-tab).

| Capability | Status | Notes |
|------------|--------|--------|
| Browse / list / sort | Target (W1) | Same `UiDeviceFiles` chrome; roots are `app:`, `shared:` (if exposed), `tree:{id}` — not `C:\` or `A:` |
| Text / image preview | Target (W1) | Same caps as desktop remote Files |
| Upload / download / mkdir / rename / delete | Target (W1) | Allowed under `app:…` and `tree:{id}/…` when the agent has write access; denied on bare `tree:{id}` without write grant |
| **Add folder** (SAF tree) | Agent app | `ACTION_OPEN_DOCUMENT_TREE` on remote agent — not the Flutter Files toolbar |
| In-app copy / cut / paste (on device) | Target (W1) | Same duplicate-via-chunks model as Windows remote |
| OS clipboard → upload (desktop client) | Supported | Same paste priority as §Copy / paste inside Files |
| Drag-drop upload | Desktop client only | Same as Windows-remote row above |
| Alien AI Drive (`A:`) root | **N/A** | Use Windows agent + [`drive.md`](drive.md); Android uses virtual roots only |
| `shell.run` in chat | Target (W2) | Allowlisted `/system/bin/sh` on agent — not PowerShell |

**Preview** — text-like extensions up to **2 MB**; images up to **512 KB** via chunked `RemoteFsRead` (banner when capped). Other types: use Download.

**Widgets:** `widgets/devices/ui_device_files.dart`, `widgets/devices/ui_device_fs_upload_panel.dart`, `c/remote/remote_fs_transfer.dart`.

## Sites page — Phase 8

Same shell pattern as **Devices** (master/detail + tabs). Layout editing is **prompt-primary** on Home; this page is operational admin.

```
nav: site list → detail tabs: Preview | Products | Contacts | Objects | Settings | Orders (Phase 9)
```

| Tab | UI | Editor |
|-----|-----|--------|
| **Preview** | iframe → `alienai.id/{alien_id}` | prompt + publish |
| **Products** | `UITable` (`site.product` + embed subtable) | table + prompt |
| **Contacts** | `UITable` (`site.contact`) | table + prompt |
| **Objects** | `UITable` (`site.object`) | table |
| **Settings** | fields: alien_id, domains, capabilities, publish | form |
| **Orders** | `UITable` list + tx ledger editor | id.alienai POS (Phase 9) |

### UITable

Generic Airtable-like grid driven by `TableDef` from [`collection.proto`](../schemas/proto/c35/collection.proto):

- Sort, filter, inline edit, add row
- Expand row → **subtable** (linked records, e.g. `site.product_embed`)
- Same normalized rows as prompt tools / sync

Widget: `widgets/ui/ui_table.dart` (new). Pattern reference: Devices **Files** tab (list + detail).

### Prompt editor

User edits layout on **Home**: *"@warung-siti make background more red"* → topic **`web.builder`** → `site_draft_put` / `site_publish`.

No CSA-style visual hub / card-style / effects panels as primary UI.

## Error handling

- Wrap app/sections in error boundary equivalent
- User sees friendly message (from cs_agent `ui_friendly_error`)
- Technical stack/details → `ai.log` + NATS live stream
- Never red screen of death

## Message renderer

One shared renderer for Home + Bots detail:

| Field | Display |
|-------|---------|
| tokens_in | Input tokens |
| tokens_out | Output tokens |
| duration_ms | Duration |
| cost_usd | Cost |

UI reference: `D:\cs_agent\clients\app\lib\widgets\ai\msg_trace_view.dart`

## Live log viewer (root/admin)

- Subscribes NATS `log.{iid}.{dv}.{topic}`
- Filterable table, live tail
- Topics: `sign-in`, `sign-out`, `prompt`, `connected`, `disconnected`, `error`, …

## Root console (root-only)

**Root console** = ops screen inside the Flutter app — **not** a public page on `alienai.id`. Visible only when the signed-in user has the **Root** badge (avatar menu → Partner/Root row).

| Section | UI | Purpose |
|---------|-----|---------|
| **Stats dashboard** | Default view on open | Per-node cards (multi-node): CPU/RAM bars, network In/Out bars, **Storages** (`sda (boot)`, `sdb`, …), **Volumes** (`yb-tserver`, `yb-master`, `nats` used/capacity) — passive NATS relay via WS `ReqStatsSubscribe` (`c35.stats.>`) |
| **Logs** | Action tile → `page_root_logs` | Search/tail `ai.log` by user, date range, text; live via WS `ReqLogSubscribe` |
| **Inst** | Action tile → `page_root_inst` | Edit `ai.inst` rows in `UITable` (prompt steering) without MCP |
| **Objects** | Action tile → `page_root_objects` | Curate `ai.object_alias` (unverified queue) in `UITable` — see [tx.md](tx.md) |

Audience: **root admin only**. Regular users never see the menu row or pages.

Pages: `page_root_console.dart`, `page_root_logs.dart`, `page_root_inst.dart`. Widgets under `widgets/admin/`. API: `c/admin/admin_api.dart`, `admin_stats_stream.dart`, `admin_log_stream.dart`.

See [sync.md](sync.md) for NATS subjects and [inst.md](inst.md) for inst schema.

## Flutter project

```
clients/app/
  lib/
    c/           core (conn, store, api)
    pages/       page_home, page_bots, page_devices, page_sites, …
    widgets/     ui_*, io_*, in_*
```

Naming follows user conventions: `ui_`, `io_`, `in_` prefixes; `l()` for logging.
