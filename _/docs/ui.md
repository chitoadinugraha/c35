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
| Referral tree | Referral page (copy cs_agent) |
| Lock | Session lock |
| Logout | Sign out |

**No space picker.** Personal AI is Home; bots/devices/sites are separate pages.

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
- Custom **UI blocks** renderable inside messages
- Canvas: document/slide editor when AI produces canvas content

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
   - **Behavior**: Inserts `@displayLabel ` in-line into the prompt, preserving natural grammatical context, while activating the corresponding entity context in the backend turn.
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

Build **exactly** like `D:\cs_agent` — UI and root user management unchanged in behavior. Wire adapts to c35 identity schema.

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
- 3-step wizard: Basic info (name, instructions, avatar) → Connect channels (Telegram, WhatsApp Meta, WhatsApp Device) → Assets.
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

Master/detail list of **`kind IN ('remote', 'iot')`** for owner. Supports order, pin, archive.

### Device row (remote)

Each remote row shows name + type subtitle (e.g. `CHITO` / `windows`) and **two trailing dots**:

| Dot | Meaning |
|-----|---------|
| Left (WebRTC) | App ↔ device data plane — files, screen, media |
| Right (cluster) | Agent ↔ server — presence, tasks |

IoT rows keep a single online dot.

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

Remote agent attaches skills/tasks to device **identity id**.

### Files tab (remote)

**Transport:** SCTP data channel `remote-fs` (protobuf `RemoteFs*`). Requires **WebRTC connected** (left dot on device row). Bytes are app ↔ device direct — not stored on cluster unless user saves elsewhere. See [`remote.md`](remote.md#files-tab--browse-copy-stream).

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

**Download** — toolbar or context menu; pick a local folder; `RemoteFsTransfer.downloadRemote` (files + folder trees).

**Mutations** — New folder (`fsMkdir`), Rename (`fsRename`), Delete (`fsDelete` + confirm). Drive roots cannot be deleted.

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
