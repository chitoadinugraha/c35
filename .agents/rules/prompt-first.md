---
description: Prompt-first product direction. User guides in _/docs, engineering specs in _/specs.
alwaysApply: true
---

# Prompt first

Cursor: [`.cursor/rules/prompt-first.mdc`](../../.cursor/rules/prompt-first.mdc). Guide index: [`_/docs/README.md`](../../_/docs/README.md).

Alien AI is chat-first. Build the prompt path (tool + `ai.inst`) before adding a screen.

## Where to write

| Folder | What |
|---|---|
| `_/docs/` | User guides the site renders. Linked from the repo `README.md`. |
| `_/specs/` | Engineering specs. Tutorials do not go here. |

## UI only when

- **Sensitive:** passwords, tokens, payments, delete confirmation, privacy, preferences.
- **Hands-on:** product editing and POS, where the screen is faster than a sentence.

Those still get a prompt when one can be built. Everything else (consumption, bookkeeping, reporting, bots, sites, mail) is prompt-first. If a screen already exists, the chat path still has to work.

A prompt may start a destructive or paid action. The confirm stays on the screen.

## Guide shape

Tag each article `prompt`, `ui`, or `both`. Write `en/` and `id/` as separate files, screenshots included.

```md
# Create a bot
path: prompt

Ask: "Create a bot named Rasa for WhatsApp orders."
```

```md
# Edit a product
path: both

## On the screen
1. Open the product.

## In chat
Ask: "Set the price of Americano to 28000."
```
