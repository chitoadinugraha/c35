# Task execution orchestration — multitask plan

> **Status (2026-10-15):** Core waves **implemented in repo**. Deploy + YB migration + live `inst_put` still required.

**Goal:** Recipe | skill | prompt paths, `task.chunk_fanout`, chat links, heal policy.

**Spec:** [task-execution.md](../task-execution.md)

## Shipped in code

| Wave | Deliverable | Location |
|------|-------------|----------|
| W1 | `parent_run_id`, `source_msg_id`, `last_msg_id` | `_/schemas/migrations/20261015_task_run_parent_msg.sql`, `task.proto`, `mod_task/store.rs`, `run_start.rs` |
| W2 | `task.chunk_fanout` + cancel children | `mod_task/recipes/chunk_fanout.rs` |
| W3 | Recipe registry | `mod_task/recipes/registry.rs` |
| W4 | Inst seeds | `_/schemas/inst.sql` (`inst.task.migration`, `inst.task.cron_device`) |
| W5 | Tasks → chat link | `ui_task_master_detail.dart`, `page_ai_home.dart` |
| W6 | `heal_mode` + agent retry/off | `skill.proto`, `skill.sql`, `skill_heal.rs`, `mod_skill/rpc.rs` |
| W7 | `data.shell_chunk` stub | `mod_task/recipes/data_shell_chunk.rs` |
| W8 | Build verify | `cargo build -p server_ai`, `c_remote_windows`, `dart analyze` (touched UI) |

## Ops checklist (you)

- [ ] Apply `_/schemas/migrations/20261015_task_run_parent_msg.sql` on cluster YB
- [ ] `inst_put` for `inst.task.migration` and `inst.task.cron_device` (git seed alone is not live)
- [ ] `.\_\scripts\deploy\publish_server.ps1` after migration
- [ ] Optional: publish remote agent if paired PCs need `heal_mode`

## Example orchestrator prompt (chat → `task.run_start`)

```json
{
  "recipe": "task.chunk_fanout",
  "child_recipe": "data.shell_chunk",
  "device_iid": 0,
  "total": 9000,
  "chunk_size": 3000,
  "parallel_children": 2,
  "stagger_ms": 1000,
  "child_params": {}
}
```

## Deferred

- Unified Activity feed (delegate + task in one list)
- Flutter skill editor heal_mode picker
- `command_template` agent shell bridge for `data.shell_chunk`
- Checkpoint resume across server restart
