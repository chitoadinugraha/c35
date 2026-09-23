---
description: Fixed test identity (iid 33000) for agents, MCP, and integration tests
alwaysApply: true
---

# Alien AI Automated Tester

Mirrored for Cursor: [`.cursor/rules/automated-tester.mdc`](../../.cursor/rules/automated-tester.mdc)

## Test identity (locked)

| Field | Value |
|-------|-------|
| **Name** | Alien AI Automated Tester |
| **owner_iid / iid** | **33000** (fixed; docs may say "uid 33000" — same id) |
| **alien_id** | `automated-tester` |
| **global_roles** | `tester` |
| **meta** | `is_automated_tester: true` |

Seed: [`_/schemas/identity.sql`](../../_/schemas/identity.sql) (also billing + consumption prefs seeds).

## When to use

Use **owner_iid = 33000** for any automated test unless the scenario explicitly needs another user:

- MCP prompt / tool tests (`consumption.today`, seed meals, assert UI blocks)
- SQL fixtures and `C35_TEST_DB=1` integration tests
- Agent-driven QA against live YB

Do **not** use your personal account (**99000** — see `agent-debug.mdc`) or ephemeral snowflake users when a shared fixture is enough.

## Env constants

Prefer these names in MCP config, scripts, and tests:

```
C35_TEST_OWNER_IID=33000
```

## Rules

1. **Seed before assert** — insert or reset test data for 33000; never assume empty DB.
2. **Scope data** — all rows must use `owner_iid = 33000` (consumption, chat, billing, etc.).
3. **No production side effects** — do not run destructive ops against non-test identities.
4. **Billing** — seeded wallet on 33000; prompts should not fail on quota for normal test runs.
