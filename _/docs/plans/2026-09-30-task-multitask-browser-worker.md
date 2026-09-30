# Task multitask worker (parallel rows + progress + cost) - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **For Chito:** Builds on [2026-09-21-tasks.md](2026-09-21-tasks.md). Chat = **task spawner/manager**; server = **durable worker** with **`parallel`** slots, **% progress**, **time / tokens / cost** on the Task tab. First recipe: **browser.sheet_row_backfill** (Google Sheet + e-Pus).

**Goal:** Server-orchestrated multitask worker for browser (Chrome extension first): batch rows with `parallel` concurrent pipelines (e.g. 5), live **done/total (%)**, rollup **elapsed, tokens, USD** per `task_run`.

**Architecture:** One `ai.task_run` per Run now. Server **orchestrator** + **row pool** (`parallel` semaphore). Tools via `remote_device_browser_invoke`. e-Pus phases run in parallel; **Sheets writes serialized per `tab_id`** (extension queue). State in `task_run.meta_json`; metrics on `task_run`; `TaskRunPush` every row + every 2s while running. Recipe JSON in `task.prompt`.

**Tech stack:** `mod_task` (new), `mod_device`, `mod_chat` (`task.run_*`), Flutter `UiTaskMasterDetail`, `task.proto`, NATS per [remote.md](../remote.md).

## Global Constraints

- Read `spec.md`, `_/docs/remote.md`, `_/docs/browser-remote.md`, `_/docs/browser-extension.md`.
- No YB task polling sweeper.
- Worker v1 does not use extension `browser.task.run`.
- Verify: `cargo build -p server_ai`, `cargo test -p mod_task`, `flutter analyze`, `check_utf8_sources.ps1 -Changed`.

## Prerequisites

Ship with [2026-09-21-tasks.md](2026-09-21-tasks.md) Track 0-1 + Track 3: `mod_task` CRUD, `TaskRunPush`, Flutter `TaskApi` on WS (not mock).

## Multitask map

| Wave | Tracks |
|------|--------|
| 0 | Schema metrics + mod_task |
| 1 | A worker + B Flutter UI (parallel) |
| 2 | C sheet recipe |
| 3 | D chat tools + E verify |

| Track | Gate |
|-------|------|
| 0 | meta_json, tokens, cost, duration |
| A | pool parallel=5 test |
| B | % bar, time, tokens, cost live |
| C | 3 rows parallel=2 |
| D | prompt_compose task tools |
| E | smoke 33000 |

## Design (locked)

### Progress meta_json

`total`, `done`, `failed`, `skipped`, `pct`, `parallel`, `current_rows`, `checkpoint`. Summary: `12/87 (14%) - 5 parallel`.

### Metrics

Columns: meta_json, tokens_in, tokens_out, cost_usd, duration_ms. req_id prefix `task_run.{run_id}.row.{row}` for ai.log rollup.

### Recipe browser.sheet_row_backfill

JSON in task.prompt: tab_id, sheet columns B/C/G-L, `parallel` (1-10 in UI), epus search_url_template with {kartu}, limits.max_rows_per_run, llm.on_ambiguous default false.

### Safety

Max `parallel` e-Pus tabs; close each tab; one sheets tab_id; row_set serialized on extension.

### Agent S1

ActDeviceTaskRun delegate server for active_tasks; worker runs on server.

### Chat tools

`task.run_start`, `task.run_cancel`, `task.run_status`, `task.run_cancel_device` + inst seeds (`inst.task.browser_worker`).

## Stop, cancel, and guardrails

| Control | Tool / RPC | Behavior |
|---------|------------|----------|
| Stop one run | `task.run_cancel` / `ReqTaskRunCancel` | Sets in-memory cancel flag; marks `ai.task_run` cancelled if queued/leased/running; worker checks between rows |
| Stop all on device | `task.run_cancel_device` / `ReqTaskRunCancelDevice` | Cancels every active run for `device_iid`; UI "Stop all" |
| Status / progress | `task.run_status` | Single `run_id` or list by `device_iid` / `task_id`; returns `meta_json` pct and rollup metrics |

**Guardrails (server-enforced, v1):**

- `parallel` clamped **1..10** (`MAX_PARALLEL_CAP`) in recipe worker.
- `limits.max_rows_per_run` clamped **1..500** per run (`DEFAULT_MAX_ROWS` default 200).
- **Wall clock** cap **30 min** per run (`DEFAULT_MAX_WALL_MS`); recipe aborts with failed/cancelled status.
- **Sheets writes** serialized per extension `tab_id` (one writer queue); e-Pus browser tabs may run in parallel up to `parallel`.
- **One sheets tab_id** per recipe; close ephemeral e-Pus tabs after each row job.
- Do **not** start duplicate ad-hoc runs in a tight loop from chat if billing gate fails — surface error once.

**Not v1:** resume from checkpoint after server restart; per-row child `task_run` rows; extension `browser.task.run` as worker.

## Quota and billing

- Each `task.run_start` calls `billing_gate_with_hold_custom` with **`TASK_RUN_HOLD_USD` (0.05 USD)** on the run `req_id` (chat turn id when started from LLM tools).
- Row-level LLM/tool usage rolls into `ai.log` with req_id prefix `task_run.{run_id}.row.{row}`; worker persists **tokens_in/out**, **cost_usd**, **duration_ms** on `ai.task_run` at finish via `task_run_metrics_persist` + `task_run_billing_settle`.
- Insufficient balance/quota → start RPC error; inst tells model to ask user to top up, not spam retries.
- **`delegate.run`** subagents use separate holds (`CHILD_HOLD_USD`); durable batch sheet work should use **`task.run_start`**, not delegate.

## Track 0

- [ ] task.sql + task.proto metrics; mod_task CRUD + JetStream + TaskRunPush

## Track A

- [ ] Orchestrator, parallel pool, cancel, metrics rollup

## Track B

- [ ] Wire TaskApi; progress UI; parallel editor

## Track C

- [ ] range_read discover; row job; pool

## Track D

- [x] mod_chat `task.run_start`, `task.run_cancel`, `task.run_status`, `task.run_cancel_device`
- [x] `inst.task.browser_worker` seeds in `inst.sql`

## Track E

- [ ] Smoke + docs

## Out of scope v1

Per-row task_run children; extension browser.task.run worker; resume checkpoint; LLM every row.
