# Identity model (LOCKED)

Status: **locked** 2026-09-20

## Purpose

Every actor in c35 — human, team, bot, remote PC, IoT device, website — is one row in `ai.identity` with a snowflake `id` (iid). This enables:

- Unified URLs: `/<alien_id>` when slug is set
- Unified ownership, billing, logging, and sync
- No separate "space" table (removed vs cs_agent)

## Terminology

| Term | Meaning |
|------|---------|
| **iid** | `identity.id` — snowflake BIGINT, globally unique (see [snowflake.md](snowflake.md)) |
| **alien_id** | Human-friendly globally unique slug (renamed from **handle**) |
| **owner_iid** | Identity that owns this row (user or team) |
| **team** | Business/org group (renamed from org/group) |

### alien_id rules

- Characters: `[a-z0-9_-]` only
- Globally unique across all identities
- Defaults to `NULL` on signup and Google OAuth (never auto-derived from email)
- Unique partial index on `LOWER(alien_id) WHERE alien_id IS NOT NULL AND alien_id <> ''`
- User sets/claims alien_id in settings via `InAlienIdSignup` (min 7 chars unless unlocked by referral code)

## kind + type (not compound kind)

Use two columns. **Do not** use kinds like `remote-windows`.

### kind (coarse category)

| kind | Description |
|------|-------------|
| `user` | Human account |
| `team` | Business / organization |
| `bot` | Chatbot identity (Telegram, WhatsApp, …) |
| `remote` | Paired remote-control agent (PC, phone) |
| `iot` | Firmware device (switch, gate, media player) |
| `site` | Website / business front (POS lives here later) |

### type (subtype within kind)

| kind | type values | notes |
|------|-------------|-------|
| `user` | `''` | empty |
| `team` | `''` | empty |
| `bot` | `chat` | channel platform(s) in `meta.channels[]` |
| `remote` | `windows`, `android`, `macos`, `linux` | agent platform |
| `iot` | `switch`, `gate`, `media_player`, … | firmware class |
| `site` | `business`, `personal`, … | site class |

Platform-specific detail (Telegram vs WhatsApp, ESP32 vs C3) goes in **`meta` JSONB**, not new kind values.

### Why not `remote-windows` as kind?

- Mixes two dimensions into one enum that grows forever
- Harder validation and indexing
- `WHERE kind = 'remote'` is equally simple and cleaner

Optional convenience (generated, not queried as primary):

```sql
kind_type TEXT GENERATED ALWAYS AS (
  kind || COALESCE('/' || NULLIF(type, ''), '')
) STORED
```

## Ownership & access

### Primary owner (`identity.owner_iid`)

```
user/team row           → owner_iid = id (self-owned)
bot / remote / iot / site → owner_iid = user.iid OR team.iid
```

`owner_iid` is the **billing/ownership anchor**, not the full ACL.

### Universal grants (`ai.identity_grant`)

**One grant table for everything** — team membership, site staff, shared bots/devices/IoT. No `team_member`, no per-kind grant tables.

```sql
identity_grant(resource_iid, grantee_iid, role, permissions[], is_pinned, meta)
```

| Column | Meaning |
|--------|---------|
| `resource_iid` | Identity being accessed (team, site, bot, remote, iot, …) |
| `grantee_iid` | User who receives access (`kind=user` only) |
| `role` | Meaning depends on `resource.kind` (see below) |
| `permissions` | Optional fine-grained flags, e.g. `gate:open`, `pos:sale` |
| `is_pinned` | User pinned this resource in UI |
| `meta` | Extra: `role_tags`, staff `compensations`, … |

#### Team membership = grant on team identity

```
resource_iid = team.iid
grantee_iid  = user.iid
role         = owner | admin | member
```

Creating a team: insert `identity(kind=team)` + grant `(team, founder, owner)`.

Adding a member: insert grant `(team, user, member)`.

#### Site staff = grant on site identity

(replaces csa `site_member`)

```
resource_iid = site.iid
grantee_iid  = user.iid
role         = owner | manage | staff | guest
```

Staff extras (`role_tags`, payroll) → `meta` JSONB.

#### Bot / remote / IoT share = grant on resource identity

```
resource_iid = bot.iid | remote.iid | iot.iid
grantee_iid  = user.iid
role         = admin | member | readonly
```

Same pattern as id.alienai `asset_access` and cs_bots `asset_grant`, but `resource_iid` points at `identity` rows directly (no separate asset table).

### Access check (server)

```
can(user, resource) :=
  resource.owner_iid = user.iid
  OR exists grant(resource, user) with live deleted_ts
  OR (
       resource.owner_iid = team.iid
       AND exists grant(team, user, role IN (owner, admin))
     )
```

Team **admin+** gets implicit access to resources owned by that team (derived — not stored as duplicate grants).

### Why no separate `team_member` table?

Same access pattern everywhere:

- One query: grants where `grantee_iid = ?` → everything user can open
- One sync index: `(grantee_iid, updated_ts)`
- One RPC: `identity_grant_put`, `identity_grant_list`
- Matches cs_bots rule: never create `bot_grant`, `device_grant`, `site_grant`, …

Referral forest still uses `identity.referred_by_iid` on users — not grants.

## Bot model

```
kind = bot
type = chat          -- always "chat" for messaging bots
meta.channels[]      -- multiple platforms on ONE bot identity
```

**One bot → many channels.** A single `identity` row represents the bot; Telegram, WhatsApp (Meta API), WhatsApp (device/wa-rust), and future platforms are entries in `meta.channels[]` — not separate bot identities.

Example `meta`:

```json
{
  "channels": [
    {
      "id": "01JABC…",
      "platform": "telegram",
      "status": "connected",
      "secret_id": 123,
      "bot_username": "@mybot",
      "channel_id": "…"
    },
    {
      "id": "01JDEF…",
      "platform": "whatsapp",
      "provider": "meta_api",
      "status": "connected",
      "secret_id": 456,
      "phone": "+62…"
    },
    {
      "id": "01JGHI…",
      "platform": "whatsapp",
      "provider": "linked_device",
      "status": "pairing",
      "secret_id": 789,
      "session": { "qr_raw": "…", "pair_watch_until_ms": 0 }
    }
  ]
}
```

Rules:

- **`type=chat`** is fixed for all messaging bots; do not create `type=telegram` etc.
- Platform/provider live **inside each channel object**, not in `identity.type`.
- Bots page nav lists bot identities (`kind=bot`); master pane lists conversations **per channel** (avatar + small channel icon).
- Stop/intervention is **per `bot_peer` chat row** (one external user + channel) — not per bot, not per channel globally.
- No separate channel table in Phase 1 — channels are JSONB on the bot identity row (same pattern as cs_agent `space.meta.channels[]`).

## Remote device model

```
kind = remote
type = windows | android | …
owner_iid = pairing user (or team)
meta = { hostname, agent_version, last_seen, pairing_code, … }
```

- Remote agent (`remotes/c_remote_*`) registers as this identity on pair.
- Devices page: combined list of `kind IN ('remote', 'iot')` for owner.
- Skills/tasks attach to device identity id (`device_iid`).
- Computer use always flows through server session (WS / Alien Beacon) — see [remote.md](remote.md).

## IoT model

```
kind = iot
type = switch | gate | media_player | …
owner_iid = user or team
```

Pairing: 10-char code or USB OTG flash (ESP). Media player also via `alienai.id/mp/`.

## Site model

```
kind = site
type = business | personal | …
owner_iid = user or team
```

Business features (POS, reservation) are **site-scoped**, rendered in Sites page (Devices-like tabs + UITable). Layout via Home prompt.

## Related tables

| Table | Purpose |
|-------|---------|
| `ai.identity` | Core actor row |
| `ai.identity_provider` | Email, phone, password, OAuth, API keys |
| `ai.identity_pin` | Session PIN |
| `ai.identity_session_lock` | Single active device lock |
| `ai.identity_client` | Client installs per identity (was identity_device) |
| `ai.identity_grant` | All access: team membership, site staff, resource share |
| `ai.auth_session` | Login sessions |
| `ai.billing_profile` | Plan tier + quota rings (one per user) |
| `ai.billing_wallet` | Native balances per currency (see [`billing.md`](billing.md)) |
| `ai.billing_account` | **Legacy** — dual USD/IDR wallet (migrate away) |

Canonical DDL: [`../schemas/identity.sql`](../schemas/identity.sql)

## Referral

- `referred_by_iid` on `user` identities
- Referral forest UI: port from `D:\cs_agent` unchanged in behavior
- Referral codes/shares: separate tables (see cs_agent `referral_code`, `referral_share`)

## Migration notes from prior projects

| Old | c35 |
|-----|-----|
| `handle` | `alien_id` |
| `group` / `org` | `team` |
| `team_member` / `group_member` | `identity_grant` on team identity |
| `asset_grant` (cs_bots) | `identity_grant` on resource identity |
| `site_member` (csa) | `identity_grant` on site identity |
| `agent.space` (prompt/windows/chat_bot) | Removed; use `identity` kinds |
| Space picker | Removed; page-based navigation |
| cs_agent local replica | Removed; server delta sync only |

---

## Identity deletion & resource teardown

When an identity is deleted via `identity_delete` (`wire_ws`):
1. **Kind-Specific Teardown**:
   - **`bot`**: Calls `bot_channels_disconnect_all` before dropping records:
     - Telegram: Deletes remote webhooks from Telegram servers via `/deleteWebhook`.
     - WhatsApp Device: Calls worker `/v1/channel/{bot_iid}/{channel_id}/stop` with `wipe_session: true`, disconnecting the client and deleting SQLite session files.
     - Channels: Unlinks and removes all associated `c35_channel` rows.
2. **Database Cascade (Atomic Transaction)**:
   - Soft-deletes the identity in `ai.identity`.
   - Soft-deletes all associated access grants in `ai.identity_grant` (`resource_iid = $1`).
   - If `kind == "bot"`, soft-deletes all bot conversation threads in `ai.chat` (`bot_iid = $1`).
   - All three updates are executed within an atomic database transaction (`pool.begin()`).


