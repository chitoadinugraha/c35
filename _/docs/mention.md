# Mentions — composer, wire, and message brackets (LOCKED)

Status: **locked** 2026-09-27

How `@` mentions work from the Flutter composer through **`ReqPrompt`** into **`ai.chat_msg`**, without losing context on retry, reload, or server sync.

Related: [chat.md](chat.md) (inbox + prompt threads), [inst.md](inst.md) (steering), [site-ai.md](site-ai.md) (site/device tool scope), [ui.md](ui.md) (composer UX).

---

## Why two representations?

| Representation | Where | Purpose |
|----------------|--------|---------|
| **`mention_ids[]`** on `ReqPrompt` | Wire RPC | Tool eligibility, topic/inst compose, `MentionContext` — **machine routing** |
| **`[@kind:payload]`** in message **text** | `ai.chat_msg.content` (+ client local JSON) | **Stable, parseable** mention markers in the conversation transcript |
| **Composer chip tokens** (`U+FFFC`…`U+FFFD`) | In-app draft + local prefs only | Rich UI while editing; must not be the only copy of “who was mentioned” |

Plain `iid:972798…` embedded in sentences was fragile (false positives, ugly reload). **Bracket mentions** are the canonical **stored** form in message bodies.

**Rule:** New mention types MUST use the same `[@kind:…]` pattern in stored text and map to a canonical id in `mention_ids[]` (see below). Do not invent a third ad-hoc string format.

---

## Bracket syntax (message text)

```
[@<kind>:<payload>]
```

| Part | Constraint |
|------|------------|
| `<kind>` | Lowercase ASCII identifier: `iid`, `catalog`, … future `file`, `topic`, … |
| `<payload>` | No `]` characters; opaque to the parser except kind-specific normalization |
| Whole token | Case-insensitive match for `<kind>` only where noted in code |

### Registered kinds (now)

| Bracket | Meaning | Canonical `mention_ids[]` entry | Resolved via |
|---------|---------|----------------------------------|--------------|
| `[@iid:<snowflake>]` | Any **identity** row (device, site, bot, user, …) | `iid:<snowflake>` | `mention_ref_parse` → `MentionRef::Iid` |
| `[@catalog:<id>]` | Catalog chip (`@research`, `@image-high`, …) | `catalog:<id>` | `mention_ref_parse` → `MentionRef::Catalog` |
| `[@drive:<relative/path>]` | File on **Alien AI Drive** (owner cloud volume) | `drive:<relative/path>` | `mention_ref_parse` → `MentionRef::Drive` |

Examples:

```text
Open Chrome on [@iid:97279816209936384]
Compare [@iid:111] and [@iid:222] sales
Use [@catalog:research] for this question
Summarize [@drive:reports/q1.csv]
```

### Future kinds (same pattern — register before shipping)

| Planned bracket | Payload | Canonical ref (proposed) | Notes |
|-----------------|---------|---------------------------|--------|
| `[@file:<blake3>]` | CAS hash | `file:<hash>` or attachment ref | Tie to `MsgAttachment` / CAS |
| `[@topic:<topic_id>]` | `ai.topic.id` | `topic:<id>` | Only if topic becomes mentionable in text |

**Adding a kind (checklist):**

1. Document the row in this file (table above).
2. **Client:** extend `composerMentionIdFromBracket` / `composerMentionBracketForId` in `composer_mention_text.dart`.
3. **Server:** extend `mention_id_from_bracket` / `mention_bracket_for_id` in `mention_content.rs` and `mention_ref_parse` if it is a new canonical prefix.
4. **Collect:** ensure `composerMentionIdsCollect` and `mention_content_bracket_ids` (or shared helper) extract ids for sticky/local JSON.
5. **Tests:** Dart `composer_mention_text_test.dart` + Rust `mention_content` tests.
6. **Legacy:** accept old plain `iid:<digits>` in text; normalize to brackets on **new writes** only.

---

## Canonical refs (`mention_ids[]`)

Separate from brackets — used on **`ReqPrompt.mention_ids`** and inst triggers (`mention:<id>`).

| Prefix | Example | Parser |
|--------|---------|--------|
| `iid:` | `iid:97279816209936384` | `mention_registry.rs` |
| `catalog:` | `catalog:research` | same |
| `drive:` | `drive:reports/q1.csv` | `MentionRef::Drive` (synthetic resolve; see [`drive.md`](drive.md)) |
| bare digits | `972798…` | Treated as iid (legacy) |
| `device:` / `site:` | `device:42` | Alias → iid |

**Do not** put `[@iid:…]` strings inside `mention_ids[]`; keep canonical refs. Brackets belong in **text**.

---

## End-to-end pipeline

```
Composer (chips) ──composerMentionTextForWire──► ReqPrompt.text  (brackets)
                 └── mention_ids[] ─────────────► ReqPrompt.mention_ids

Server prompt_turn ──mention_content_normalize──► ai.chat_msg.content (brackets)
                  └── mention_resolve_all ─────► [MENTION TARGETS] / tools

Client history ──composerMentionDisplayRestore──► chips in bubble
              └── msgUserContentForDisplay + mentionIdsJson
```

### Client (`clients/app`)

| Piece | Role |
|-------|------|
| `composerMentionTextForWire` | Draft tokens → `[@…]` for send/follow-up/retry |
| `composerMentionDisplayRestore` | Server/history text → chip tokens for UI |
| `composerMentionIdsCollect` | Parse tokens, brackets, legacy plain `iid:` |
| `MsgRow.mentionIdsJson` | Local prefs backup per user message |
| `ChatRow.stickyMentionIds` | Per-chat composer selection persistence |
| `msgsReloadFromServer` | Server content wins; infer `mentionIdsJson` from brackets |

Wire send path: `page_ai_home.dart` `_composerSend` always uses **`wireText`** from `composerMentionTextForWire`, not display labels alone.

### Server (`servers/crates/mod_chat`)

| Piece | Role |
|-------|------|
| `mention_content_normalize` | Insert user rows: normalize brackets + plain `iid:` |
| `chat_mention_context_commit` | Merge `sticky_mention_ids` into `ai.chat.meta`; auto-bind single device |
| `bound_device_prompt_prepare` | Inject bound device into turn when chat is device-scoped |
| `mention_resolve_all` | Build `MentionContext` for prompt block |

User message INSERT paths that must normalize: **prompt turn**, **follow-up queue**, **follow-up steer** (`prompt_followup/`).

---

## Preserving conversation context

Context is lost when mentions exist only in UI state or human labels. Use **all** applicable layers:

| Layer | Store | Survives |
|-------|--------|----------|
| Message body | `[@iid:…]` in `content` | Server history, other devices, reload |
| Turn list | `ReqPrompt.mention_ids` | Tool/topic for that turn (also `ai.prompt_run.mention_ids_json`) |
| Per-message local | `mentionIdsJson` in app prefs | Hot restart before server fetch |
| Per-chat sticky | `ChatRow.stickyMentionIds` + `ai.chat.meta.sticky_mention_ids` | Composer @ selection across turns |
| Device thread | `ai.chat.bound_device_iid` | Remote/device-scoped chats |

**Sync hygiene:** When server history is cleared (`chat_history_clear` or empty inbox preview), client must **replace** local messages from `chatMsgList`, not merge-only — see [chat.md](chat.md) and plan `plans/2026-09-27-mention-brackets-chat-sync.md`.

**Retry safety:** Retry updates the **same user row** (`msgUserTurnRetry`); wire text stays bracket-normalized; do not duplicate user bubbles.

---

## LLM-visible text

After normalize, the model sees bracket form in user content (and labels in `[MENTION TARGETS]`). Display labels in the app come from the mention catalog (`CatalogMention.displayLabel`), not from stripping brackets to raw ids in the bubble.

---

## Schemas & seeds

| Asset | Path |
|-------|------|
| Mention catalog seeds | [`_/schemas/mention.sql`](../schemas/mention.sql) |
| Topic ↔ mention inst | [`_/schemas/topic.sql`](../schemas/topic.sql) |
| Proto | `ReqPrompt.mention_ids`, `ChatMsg.content` in [`_/schemas/proto/c35/chat.proto`](../schemas/proto/c35/chat.proto) |

---

## Verification

```powershell
cd clients/app
flutter test test/composer_mention_text_test.dart test/chat_store_test.dart

cd ../../servers
cargo test -p c35_mod_chat mention_content --
cargo build -p server_ai
```

Prompt steering regression: `prompt_compose` / `prompt_run` with device mention phrase — see `.cursor/rules/prompt-run-test.mdc`.
