# Inst platform implementation

**Date:** 2026-09-22  
**Spec:** [`_/docs/inst.md`](../../_/docs/inst.md)  
**Rule:** [`.cursor/rules/inst.mdc`](../../.cursor/rules/inst.mdc)

## Goal

Type B only: DB-backed `ai.inst`, in-memory cache, NATS invalidation, MCP admin. Remove hardcoded `CLUSTER_SYSTEM`. Then consumption phrase fixes (separate follow-up).

## Tracks (parallel)

### Track 1 — Migrate baseline + scope filter

- Seed `inst.core.assistant` in `_/schemas/inst.sql` (`kind=trigger`, `triggers=['always']`, `scope=global`) with body from current `CLUSTER_SYSTEM`
- Remove `CLUSTER_SYSTEM` from `tool_loop.rs`; rely on composed `inst_block` from prompt_turn (ensure always inst is picked)
- Implement `scope` filtering in `inst_pick` / `compose_tools_and_inst` (pass active scope e.g. `role:personal_assistant` for Home, `global` for bots or union)
- Tests: always inst applies; scoped inst does not leak

### Track 2 — Cache + NATS

- `InstCache` in `mod_chat`: load all enabled rows on first use / server init hook
- Subscribe NATS `c35.inst.*` (or per-id); on message reload row or evict
- Replace per-turn `inst_list_enabled(pool)` with cache read
- Document subject in `_/docs/sync.md` under NATS section
- Publish invalidation from `inst_put` path (Track 3) and any SQL migration hook if present

### Track 3 — MCP CRUD

- MCP tools: `inst_list`, `inst_get`, `inst_put`, `inst_delete` (user-yb or new server MCP — follow existing MCP patterns in repo)
- `inst_put` / `inst_delete` write `ai.inst`, bump `updated_ts`, publish `c35.inst.{id}`
- Root-only for `global` scope; partner scoped to `partner:<pid>` (RBAC stub OK if no partner auth yet)

## Verify

```powershell
cd servers
cargo test -p c35_mod_chat
cargo build -p server_ai
```

## Follow-up (next session)

- Consumption: expand `inst.consumption_coach` phrases; week-range on `consumption.today`
- Partner/root Flutter UI
