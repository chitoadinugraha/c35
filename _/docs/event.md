# Events (LOCKED)

Status: **locked** 2026-09-26 (0-user restructure)

Domain **timeline** + trigger bus. Distinct from **state pushes** (`c35.user.{iid}.balance`, `.chat.*`, …) and from **LLM/tool trace** rows in `ai.log` (no NATS fanout).

See also [log.md](log.md) (storage), [sync.md](sync.md) (NATS), [consumption.md](consumption.md), [nats.md](nats.md).

---

## Planes

| Plane | Examples | NATS | `ai.log` |
|-------|----------|------|----------|
| **Event** | sign-in, meal logged, channel connected | Yes — `c35.user.{iid}.ev.*` or `c35.ev.*` | Yes — `class=event` |
| **Error** | sign-in failed, channel error | Yes | Yes — `class=error` |
| **State** | balance, chat delta, task run | Yes — `c35.user.{iid}.app.*`, not `ev` | No (domain tables) |
| **Trace** | LLM turn, tool exec, billing | **No** (DB + `req_id` only) | Yes — `class=trace`, `kind=llm\|tool\|task` |

**Rule:** Never publish `class=trace` on NATS. Admin / MCP use SQL (`log_tail`, `trace_get`) for prompt debugging.

---

## NATS subjects

### Owner timeline (app WS does **not** subscribe this — use admin `ReqLogSubscribe` or triggers)

```text
c35.user.{owner_iid}.ev.{slug}
```

`slug` is kebab-case, stable, trigger-friendly (`sign-in`, `meal-logged`, …).

### Scoped (owner in payload)

```text
c35.ev.device.{device_iid}.{slug}
c35.ev.bot.{bot_iid}.{slug}
c35.ev.channel.{owner_iid}.{platform}.{channel_id}.{slug}
c35.ev.platform.{slug}
```

### Deprecated (do not use for new code)

```text
log.{owner_iid}.{dv}.{topic}
```

Put `dv` on the row / `Event` protobuf, not in the subject.

---

## Catalog fields (`def_event!`)

| Field | Role |
|-------|------|
| `kind` | Stable id — SQL, triggers, code (`user.sign_in`). Never translate. |
| `slug` | Last segment of subject (`sign-in`) |
| `scope` | `User` \| `Device` \| `Bot` \| `Channel` \| `Platform` |
| `class` | `event` \| `error` |
| `desc` | Short technical (LLM / ops) |
| `txt` | **Locale templates** in catalog (`en`, `id`, …) — `$name`, `$alien_id`, payload tokens. Not stored per locale in YB. |
| `pb` | Optional protobuf payload type in `event.proto` |

---

## Copy & language (LOCKED)

| Audience | Where copy comes from |
|----------|------------------------|
| **Ops / MCP / root** | **`ai.log.text`** — **English only**, rendered at emit from `txt.en` + `meta` vars. Single column, aligned with `log_tail`, SQL, FTS. |
| **End-user event log** (in-app, rare) | **Catalog `txt`** at **read time** — `render(event_kind, viewer_locale, meta + identity)`. No extra languages in YB. |
| **Triggers / filters** | **`event_kind`** + **`meta`** — never depend on stored prose. |

Rules:

1. **Do not** store Indonesian (or other locales) on the row — users almost never open an event timeline; avoid YB bloat.
2. **Do** store one English line on emit for us: `text = render_txt(en, vars)`.
3. **Do** keep full `txt: { en, id, … }` in `def_event!` / docs for client + server read-path rendering.
4. **Search:** prefer `event_kind`, `owner_iid`, `meta`, and English `text`. Natural-language search (later) may **translate the query to English** before matching (LLM or fixed phrase map) — index/search target stays English in DB.
5. Changing catalog `txt` updates future user UI strings for old rows; stored English `text` stays as emitted (ops audit). Filter by `event_kind` when wording drift matters.

Emit pipeline (target: `c35_mod_event::event_emit`):

1. Resolve catalog entry by `kind`
2. Fill `subject` from `scope` + `slug` + context ids
3. Build `vars` from identity + payload + `meta`
4. Set `text` = **English only** (`txt.en` + vars)
5. INSERT `ai.log` (`event_kind`, `subject`, `class`, `meta`, `text`, …)
6. NATS publish exact `subject` with `EventPush` (payload: `event_kind`, `meta` — no localized strings)
7. (Later) `event_trigger_topic` wildcard match → task / notify

---

## Storage (`ai.log` columns — migration)

Append-only. Trace rows and event rows share the table.

| Column | Events | Trace (LLM) |
|--------|--------|-------------|
| `event_kind` | `user.sign_in`, `consumption.meal_logged`, … | empty |
| `subject` | filled NATS subject | empty |
| `class` | `event` \| `error` | `trace` |
| `kind` | `conn` \| `system` (legacy bucket) | `llm` \| `tool` \| `task` |
| `topic` | copy of `slug` (query compat) | tool name / hop |
| `text` | **English** rendered line (`txt.en` at emit); empty if render skipped | LLM/tool summary (trace) |
| `meta` | facts (ids, counts — no secrets) | trace JSON |
| `req_id` | optional | required when part of a turn |

Meta keys: use `sess_id`, `conn_id` — not `session_token` / keys containing `session` (redaction).

---

## Catalog — auth & session

| kind | slug | scope | txt (en) |
|------|------|-------|----------|
| `user.sign_in` | `sign-in` | User | `$name signed in` |
| `user.sign_out` | `sign-out` | User | `$name signed out` |
| `user.sign_in_failed` | `sign-in-failed` | User | `Sign-in failed` |
| `user.connected` | `connected` | User | `$name connected` |
| `user.disconnected` | `disconnected` | User | `$name disconnected` |

Emit: `mod_identity` (sign-in/out/OAuth), `wire_ws` (app WS after JWT ok / on close).

Payload (`EventUserSession`): `method`, `platform`, `app_build`, `sess_id`, `conn_id` (snowflakes only).

---

## Catalog — admin (referral / identity)

Emit from `mod_admin::admin_user_put` after successful DB commit. `owner_iid` = **actor** (who performed the change). Query promotions with `event_kind = admin.user_roles_updated` and `meta->roles_added`. Full RBAC matrix: [`referral.md`](referral.md).

| kind | slug | scope | txt (en) |
|------|------|-------|----------|
| `admin.user_profile_updated` | `user-profile-updated` | User | `$name updated user $target_iid profile ($fields)` |
| `admin.user_referrer_updated` | `user-referrer-updated` | User | `$name changed referrer for user $target_iid` |
| `admin.user_roles_updated` | `user-roles-updated` | User | `$name updated roles for user $target_iid` |

Meta: `actor_iid`, `target_iid`, `roles_before`, `roles_after`, `roles_added`, `roles_removed`, `from_referred_by_iid`, `to_referred_by_iid`, `fields`, `source`.

---

## Catalog — consumption

Emit when a meal row is **persisted** or **removed** (app RPC, tool, or any future writer). One event per successful `food_put` / `food_update` / `food_delete` — centralize in `mod_consumption::store` so tools and RPC do not duplicate.

| kind | slug | class | txt (en) | txt (id) |
|------|------|-------|----------|----------|
| `consumption.meal_logged` | `meal-logged` | event | `$name logged $item_count items · $calories kcal` | `$name mencatat $item_count item · $calories kkal` |
| `consumption.meal_updated` | `meal-updated` | event | `$name updated a meal · $calories kcal` | `$name memperbarui makanan · $calories kkal` |
| `consumption.meal_deleted` | `meal-deleted` | event | `$name removed a meal` | `$name menghapus catatan makan` |

Subject: `c35.user.{owner_iid}.ev.meal-logged` (etc.).

`meta` (all kinds): `consumption_id`, `day_id`, `item_count`, `calories`, `meal_fingerprint`, `source` (`app` \| `tool` \| `rpc`), optional `req_id` when from chat tool.

Payload (`EventConsumptionMeal`): same ids + top item names for triggers (no photos / PII).

**Not events:** `consumption.today` read-only glance, coach copy, LLM blocks — no emit.

---

## Catalog — channel / device (migrate existing `log_put` lifecycle)

Reuse slugs already in [server.md](server.md) channel log table where possible; subjects move to `c35.ev.channel.*` or owner `ev.*` when user-visible.

| kind | slug | scope |
|------|------|-------|
| `channel.connected` | `connected` | Channel |
| `channel.disconnected` | `disconnected` | Channel |
| `device.agent_connected` | `agent-connected` | Device |
| `device.agent_disconnected` | `agent-disconnected` | Device |
| `drive.file_updated` | `drive-file-updated` | User |
| `drive.file_deleted` | `drive-file-deleted` | User |

---

## Triggers (phase 2)

Table `ai.event_trigger` + `ai.event_trigger_topic` (csa `trigger_events` pattern):

- On emit: index exact `subject` + wildcard expansions (`c35.user.*.ev.meal-logged`, `c35.user.99000.ev.*`)
- Match → enqueue `ai.task_run` / NATS notify / webhook

Example rules:

- “When I log a meal over 800 kcal” → `consumption.meal_logged` + meta filter
- “When user 99000 signs in” → `c35.user.99000.ev.sign-in`

---

## Wire

Protobuf: `_/schemas/proto/c35/event.proto` ( `Event`, `EventPush`, payload messages).

Client: handle unsolicited `EventPush` on existing `c35.user.{iid}.>` subscription (new WS body or dedicated fanout).

---

## Implementation status

| Piece | Status |
|-------|--------|
| This doc + cursor rule | Done |
| Multitask plan | [`plans/2026-09-26-event-bus-multitask.md`](plans/2026-09-26-event-bus-multitask.md) |
| `event.proto`, `ai.log` migration, `c35_mod_event` | **Shipped** |
| Auth / WS / consumption emits | **Shipped** (`sign_in_failed` on bad password) |
| MCP `log_tail` / `log_find` grep | **Shipped** |
| `admin_log_list` filters (`event_kind`, `class`, …) | **Shipped** |
| Admin fanout `c35.user.*.ev.>`, `c35.ev.>` | **Shipped** (one NATS publish per `event_emit`; each matching subscription receives one copy) |
| Channel lifecycle (`connect` / `disconnect` meta+WA/TG) | Partial (pair/inbound/worker still legacy trace `log_put`) |
| `event_trigger` tables | Later |

### NATS delivery (not duplicated publish)

- `event_emit` publishes **once** to the exact `subject` (e.g. `c35.user.99000.ev.sign-in`).
- A client subscribed to `c35.user.99000.>` receives **one** message for that publish.
- A separate subscriber on `c35.user.*.ev.>` also receives **one** message (wildcard match, not a second publish).
- Admin fanout uses **two** subscriptions (`c35.user.*.ev.>` and `c35.ev.>`); owner events match only the first — not both.
