# Task execution — recipes, skills, and LLM boundaries

Status: **locked** 2026-10-15

How `ai.task` / `ai.task_run` execute work on paired devices and on the server. Scheduling and NATS dispatch stay in [remote.md](remote.md). Skills and self-learning are in [skill.md](skill.md). Browser batch recipes: [plans/2026-09-30-task-multitask-browser-worker.md](plans/2026-09-30-task-multitask-browser-worker.md). **Orchestration** (parent job, million-row fan-out, Activity links): [plans/2026-10-15-task-execution-orchestration-multitask.md](plans/2026-10-15-task-execution-orchestration-multitask.md).

## Principle

**Durable work runs without an LLM in the hot loop.** The model plans parameters, starts or schedules runs, and verifies summaries — not one inference per row, cron tick, or API call.

| Anti-pattern | Preferred |
|--------------|-----------|
| `delegate.run` for million-row or hour-long batch | `task.run_start` + **recipe** or **chunk orchestrator** |
| Free-text `prompt` on every 5 AM cron | `skill_id` + **skill tape** (or deterministic recipe) |
| Open-ended self-heal on IoT / API | **Retry + alert**; heal only for UI drift |

## What `task.prompt` means

`ai.task.prompt` and per-run `ai.task_run.prompt` are **opaque payloads**. Dispatch chooses the executor from shape and fields:

| Kind | Detection | Executor | LLM each run? |
|------|-----------|----------|----------------|
| **Recipe** | `prompt` is JSON with `"recipe": "<name>"` | Server `mod_task` worker | **No** (optional `llm.on_ambiguous` per recipe, default off) |
| **Skill** | `skill_id > 0` on task or run | Agent `skill_tape::play` | **No** on success |
| **Prompt** | Plain text, no recipe JSON, `skill_id = 0` | Agent exploration / catalog match / LLM | **Often yes** |

## Scheduled automation (cron / once / webhook)

Prefer `skill_id` + cron for fixed device routines. See [remote.md](remote.md).

## Self-heal (agent)

`heal_mode` on `ai.skill`: `ui` (default) | `retry` | `off`. See [skill.md](skill.md).

## Large batch (chunk orchestration)

Orchestrator recipe: `task.chunk_fanout`. Parent/child via `parent_run_id`. Chat links: `source_msg_id`, `last_msg_id`.

## Chat tools

Durable batch: `task.run_start`, not `delegate.run`. Inst: `inst.task.migration`, `inst.task.cron_device`, `inst.task.browser_worker`.
