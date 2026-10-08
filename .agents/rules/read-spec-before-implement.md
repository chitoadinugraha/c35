---
description: Read spec.md and relevant _/specs/ before implementing or changing behavior
alwaysApply: true
---

# Read spec before implementing

Before implementing features, changing behavior, or making architectural decisions:

1. Read [`spec.md`](../../spec.md) for locked decisions, phase scope, and the specs index
2. Read the relevant module spec under `_/specs/` (e.g. `identity.md`, `chat.md`, `ui.md`). User guides live in `_/docs/` and follow `prompt-first.md`
3. Check `_/schemas/` for SQL and proto contracts when touching data or wire types
4. App UI pushes use `c35.user.{iid}.app.*`. Lifecycle events use `.ev.*` or `c35.ev.*`. Do not publish LLM or tool traces on NATS.

If code and specs disagree, match the specs — or revise the spec first, then implement.

Do not invent architecture, naming, or scope beyond what the specs define.
