# Skill (LOCKED)

Status: **locked** 2026-09-20

Automations the AI can run on behalf of the user — taught interactively, imported, or installed from catalog.

## Reference

| Project | Borrow |
|---------|--------|
| `D:\cs_agent` | `agent.skill`, `skill_step`, `skill_catalog*`, `secret` |
| c35 identity | `device_iid` replaces `space_id`; scope adds `team` |

## Scope

| Scope | Binding | Use |
|-------|---------|-----|
| `user` | owner_iid | Personal assistant on any surface |
| `device` | device_iid (remote/iot identity) | Run on paired Windows/Android agent |
| `team` | team_iid | Shared team playbook |
| `global` | platform | Root-curated defaults |

## Tables

See [`../schemas/skill.sql`](../schemas/skill.sql).

| Table | Synced | Notes |
|-------|--------|-------|
| `skill` | yes | Main doc; `hash_blake3` of body |
| `skill_step` | yes | UI automation tape |
| `skill_secret` | yes | Encrypted credentials for steps |
| `skill_catalog*` | server | Marketplace registry; not owner-delta synced |

## Wire

Proto: [`../schemas/proto/c35/skill.proto`](../schemas/proto/c35/skill.proto)

- `ReqSkillList` / `ReqSkillPut` — CRUD
- `ReqSkillCatalogList` / `ReqSkillCatalogInstall` — marketplace

Sync collection name: `skill` (includes steps inline on full get).

## UI (future)

- Teach mode on Devices page (record steps → `skill_put`).
- Skill picker in prompt tools (match `phrases_json`, `url_pattern`, `target_app`).
- Catalog browser (Phase 7+).

## Task execution

Skills attach to `ai.task` / `ai.task_run` (see [remote.md](remote.md)). A task may reference `skill_id`; dispatch is NATS JetStream → agent server session.

## Deferred

- Self-healing / auto-repair when UI changes.
- Cron scheduler worker (`task_trigger.kind=cron`) — table ready; worker is follow-up.
