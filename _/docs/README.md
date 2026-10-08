# Alien AI guides

These pages are the product manual. The site renders this folder. Engineering specs stay in [`_/specs`](../specs/README.md).

## How Alien AI works

You do the work in chat. Type what you want on Home. The app should carry it out: a bot, a booking, a meal log, a report, a page on your site.

Use a screen when the chat is the wrong tool:

- **Sensitive.** Passwords, channel tokens, payments, delete confirmation, privacy, and preferences.
- **Hands-on.** Product editing and POS, where tapping the screen is faster than writing a sentence.

Those screens still get a prompt when we can build one. A prompt may start a payment or a delete. The confirmation stays on the screen.

## What a page looks like

Each guide has a headline, one short paragraph, then steps. The top of the page says which path is real today:

| Tag | How to write it |
|---|---|
| `prompt` | Lead with the sentence to type, then what comes back. |
| `ui` | Numbered screen steps, one screenshot each. |
| `both` | Screen steps first (POS, product edit), then the sentence that does the same job. |

English and Indonesian are separate files, including screenshots, because the app itself is translated.

```text
_/docs/
  README.md
  en/
    bots/create.md
    bots/images/01-open-bots.png
  id/
    bots/create.md
    bots/images/01-open-bots.png
```

## Guides

Pages land here as we write them. Until a page exists, the task is still done in chat when the product can do it.

| Guide | Path |
|---|---|
| Create a bot | prompt |
| Connect a channel | ui |
| Edit a product | both |
| Run the POS | both |
| Log a meal or an expense | prompt |
| Ask for a report | prompt |
