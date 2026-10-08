---
description: Event-based logging — catalog, NATS subjects, no LLM trace on bus; triggers
globs: servers/crates/mod_event/**,servers/crates/mod_consumption/**,_/specs/event.md,_/specs/log.md
alwaysApply: false
---

# Event-based logging

Mirrored for Cursor: [`.cursor/rules/event-logging.mdc`](../../.cursor/rules/event-logging.mdc)

Read before adding observability, auth hooks, lifecycle logs, or automation triggers:

- [`_/specs/event.md`](../../_/specs/event.md) — locked catalog, NATS tree, consumption + auth kinds
- [`_/specs/log.md`](../../_/specs/log.md) — `ai.log` columns (trace + events share table)

## When to emit an event

Emit **`event_emit`** (target: `c35_mod_event`) when something **happened** that users, admins, or **triggers** should react to:

- Auth: sign-in, sign-out, failed sign-in
- Session: app WS connected / disconnected
- **Consumption:** meal logged, updated, deleted (after DB commit)
- Channel / device lifecycle (connected, disconnected, pair, …)

Do **not** emit for: LLM turns, tool hops, token usage, routine reads (`consumption.today`), billing math alone.

## NATS

| Do | Don't |
|----|--------|
| `c35.user.{owner_iid}.ev.{slug}` for owner timeline | `log.{iid}.{dv}.{topic}` for new code |
| `c35.ev.device.*`, `c35.ev.channel.*` for scoped facts | Put `dv` in the subject |
| Publish `EventPush` on exact `subject` | Publish `class=trace` rows |

App UI state (balance, chat, task run) publishes on `c35.user.{iid}.app.*`, not the legacy flat subjects. See `user-app-nats.md`.

## Code rules

1. **Register first** — add a `def_event!` row in the event catalog (`kind`, `slug`, `scope`, `txt`) in [`_/specs/event.md`](../../_/specs/event.md) before implementing emit.
2. **One pipeline** — call `event_emit` / `event_spawn`; do not hand-roll `log_put` for lifecycle unless `mod_event` is not merged yet (then match `event.md` subjects and fields and replace when crate lands).
3. **Centralize domain writes** — consumption events from `mod_consumption::store` (`food_put`, `food_update`, `food_delete`), not scattered in RPC + tools.
4. **Copy** — catalog holds `txt: { en, id, … }`. On emit: set `ai.log.text` to **English only** (`txt.en` + vars) for ops/MCP/FTS. User-facing UI: **render at read** from catalog + viewer locale + `meta` — do not store non-English on the row.
5. **Meta** — facts only; use `sess_id`, `conn_id`, `consumption_id`; never tokens/passwords. Avoid meta keys containing `session` (see `mod_log` redaction). Filter triggers by `event_kind` + `meta`, not localized prose.
6. **Trace / billing** — `log_put` or turn tracer for `kind=llm|tool|task` with `class=trace`; **no NATS publish** for those rows.
7. **Triggers** — design `kind` + `subject` so wildcards work (`c35.user.*.ev.meal-logged`).

## Consumption (required kinds)

| DB op | `event_kind` | slug |
|-------|----------------|------|
| New meal saved | `consumption.meal_logged` | `meal-logged` |
| Meal updated | `consumption.meal_updated` | `meal-updated` |
| Meal deleted | `consumption.meal_deleted` | `meal-deleted` |

Include `source`: `app` | `tool` | `rpc` in `meta`.

## Verify

After wiring emits: row in `ai.log` with `event_kind` + `subject`; NATS message on exact subject (root tail or `log_tail` / SQL). Do not claim triggers work until `event_trigger` tables exist.
