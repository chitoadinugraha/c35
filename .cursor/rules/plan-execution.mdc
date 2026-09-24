---
description: Multitask and plans always use subagents — never ask inline vs subagent
alwaysApply: true
---

# Multitask + plan execution

Same as global `~/.cursor/rules/plan-execution.mdc` — enforced in this repo.

## Default: subagents (no prompt)

For **multitask** work (2+ independent tracks, parallel waves, implementation plans, multitask maps):

- **Always Subagent-driven** — dispatch `Task` subagents; do not implement all tracks in the parent session.
- **Never ask** which execution mode. Forbidden:
  - "Subagent-driven vs Inline — which approach?"
  - "Two execution options…"

**Exception only:** user explicitly says inline / single-session / no subagents.

## When to dispatch

| Trigger | Action |
|---------|--------|
| Plan with tracks (e.g. `_/docs/plans/*.md`) | One `Task` per task; parallel wave = multiple `Task` in one turn |
| User says multitask / parallel tracks | Dispatch immediately |
| Plan handoff after writing | Start wave 1 — no execution-mode question |

## With other rules

- **Model:** `subagent-model.mdc` — `inherit` only unless user named a model.
- **Verify:** `verify-after-edit.mdc` after each track's edits.
