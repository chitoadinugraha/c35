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
| Referral tree | Referral page (copy cs_agent) |
| Lock | Session lock |
| Logout | Sign out |

**No space picker.** Personal AI is Home; bots/devices/sites are separate pages.

## Home (personal AI chat)

- Home master column = **AI inbox** (`prompt` only) — sorted by **`last_msg_ts`** — see [chat.md](chat.md)
- User-to-user chat (`direct`) is **deferred** — not in Home inbox
- Binds to signed-in **`user` identity** — `chat.kind = prompt`
- Master/detail chat list + conversation
- Inbox lists **`prompt`** AI threads only via `chat_member`, sorted by `last_msg_ts`
- Features: pinned, archived, `#tag` search
- Message renderer: input/output tokens, duration, cost (copy cs_agent `msg_trace_view`)
- Custom **UI blocks** renderable inside messages
- Canvas: document/slide editor when AI produces canvas content

### Chat row menu

- Rename
- Tag (tag editor dialog; `#tag` derived from title)
- Pin
- Archive
- Archive Below (when messages exist below)

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
| Remote | `UIRemoteDevice` — mouse, keyboard, screen |
| Task | Scheduled/one-shot tasks |
| Skill | Manual + automatic (self-learned) skills; Teach button |
| Settings | Name, instructions, device config |

Remote agent attaches skills/tasks to device **identity id**.

## Sites page (3-pane) — Phase 8

Same 3-pane pattern as Bots. POS lives in detail pane (Phase 9).

```
nav: site list → master: Design | Data tabs → detail: preview / product admin / POS
```

- **Design** — prompt edits `SiteDoc` blocks; live preview iframe
- **Data** — products, contacts, objects (fixed admin forms)
- **POS** — id.alienai tx editor (Phase 9)

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

## Flutter project

```
clients/app/
  lib/
    c/           core (conn, store, api)
    pages/       page_home, page_bots, page_devices, page_sites, …
    widgets/     ui_*, io_*, in_*
```

Naming follows user conventions: `ui_`, `io_`, `in_` prefixes; `l()` for logging.
