# Mention brackets + chat cache sync (safe & consistent)

> **For agentic workers:** Subagent-driven parallel tracks. Model **inherit** only. Verify per `verify-after-edit.mdc`.

**Goal:** One consistent mention story end-to-end: `[@iid:…]` / `[@catalog:…]` in stored text, chip tokens in UI, `mention_ids[]` on wire; local cache must not outlive server history clears.

**Architecture:** Bracket format is locked in [`_/specs/mention.md`](../mention.md). Client emits wire text via `composerMentionTextForWire`; server normalizes on every user `chat_msg` insert. Client replaces (not merge-only) messages on `chatMsgList` when reconciling; drops prefs when inbox says empty thread.

## Status (2026-09-27)

All tracks shipped in tree; **deploy server + app** for production.

- [x] **Track A — Server inserts** — `mention_content_normalize` on prompt turn and followup user-message paths in `mod_chat`.
- [x] **Track B — Client wire + retry** — `_composerSend` uses `composerMentionTextForWire`; `msgPutFromServer` fills `mentionIdsJson` from brackets.
- [x] **Track C — Sync safety** — `msgsSyncStaleFromServer` / `msgsReloadFromServer` on reconnect; empty inbox clears local msgs.
- [x] **Track D — Tests + docs** — Flutter/Rust tests; [`mention.md`](../mention.md) + plan index in `structure.md`.

## Tracks (summary)

| Track | Status |
|-------|--------|
| A — Server inserts | done |
| B — Client wire + retry | done |
| C — Sync safety | done |
| D — Tests + docs | done — see [`mention.md`](../mention.md) |

## Safety rules (regression guards)

1. **Retry** — `retryLastTurnPrep` keeps user row; wire text must match server normalize (brackets).
2. **Stream** — stale `reqId` ignored; reconcile uses `msgsReloadFromServer`, not merge-only.
3. **Display** — `msgUserContentForDisplay` + `composerMentionDisplayRestore` handle brackets, plain `iid:`, and tokens.
4. **No raw FFFC in empty catalog** — `composerMentionUserContentDisplay` strips to readable text.

## Verification

```powershell
cd servers
cargo build -p server_ai
cargo test -p c35_mod_chat mention_content --

cd ../clients/app
flutter test test/composer_mention_text_test.dart test/chat_store_test.dart
flutter analyze
```

## Out of scope (follow-up)

- `ai.chat_msg.meta.mention_ids` column (server JSON mirror)
- `[@file:…]` implementation (documented only)
