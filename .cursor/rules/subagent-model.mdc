---
description: HARD BAN on *-fast subagent models — Task/multitask must use inherit unless user names a non-fast model
alwaysApply: true
---

# Subagent model (no fast downgrade)

Same as global `~/.cursor/rules/subagent-model.mdc` — enforced in this repo.

## Hard rule

Before **every** `Task` call (multitask, parallel tracks, Bugbot, explore):

- **`model`: `"inherit"` or omit** — never `composer-2.5-fast` or any `*-fast` slug.
- **Never** assign a faster model to "simple" tracks.
- **Exception only:** user explicitly names an allowed non-fast model in this conversation.

Used `*-fast` already? Redispatch with `inherit`.

## Pre-dispatch check

Confirm `model` is absent or `"inherit"` before every `Task`. Otherwise do not dispatch.
