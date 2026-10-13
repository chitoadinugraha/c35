# Bot put + manage inst — implementation plan

**Goal:** Prompt-first on/off, rename, and instruction edits via `bot.put`; keep `bot.draft` for create/sheets.

| Track | Deliverable |
|-------|-------------|
| 1 | `bot.put` tool (`identity_put` merge) |
| 2 | `bot.draft` deactivate / `active` on update |
| 3 | `inst.bot.manage` seed + `inst.bot.draft` phrase split |
| 4 | Compose test + `cargo test -p c35_mod_chat` |

**Live inst:** After deploy, run `inst.bot.manage` INSERT from `_/schemas/inst.sql` or `inst_put`.
