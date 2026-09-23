---
description: Read spec.md and relevant _/docs/ before implementing or changing behavior
alwaysApply: true
---

# Read spec before implementing

Before implementing features, changing behavior, or making architectural decisions:

1. Read [`spec.md`](../../spec.md) for locked decisions, phase scope, and the docs index
2. Read the relevant module doc(s) under `_/docs/` (e.g. `identity.md`, `chat.md`, `ui.md`)
3. Check `_/schemas/` for SQL and proto contracts when touching data or wire types

If code and docs disagree, match the docs — or revise the doc first, then implement.

Do not invent architecture, naming, or scope beyond what the specs define.
