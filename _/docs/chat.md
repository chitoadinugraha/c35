# Chat model (LOCKED)

Status: **locked** 2026-09-20

## Overview

All conversations use **`ai.chat`** + **`ai.chat_msg`**. **`ai.chat_member`** drives the **Home inbox** for **`prompt`** threads only.

| Kind | UI | Home inbox | Status |
|------|-----|------------|--------|
| **`prompt`** | Home | ✅ yes | **now** |
| **`direct`** | TBD | ❌ no | **deferred** (schema reserved) |
| **`bot_peer`** | Bots page | ❌ no | **now** |

There is **no space table**. Prompt chats bind to the signed-in **`user` identity**.

---

## Home inbox (header list)

Master column on Home = **AI chat threads only** (`kind = prompt`).

**Not in Home inbox:** user-to-user (`direct`, deferred), bot channel threads (`bot_peer` → Bots page).

### Sort order

```
ORDER BY pinned_ts DESC NULLS LAST, last_msg_ts DESC
```

- **`last_msg_ts`** — newest activity on top
- **`pinned_ts`** — pinned threads float above
- Card time = **`last_msg_ts`**

### Query shape

```sql
SELECT c.*, m.pinned_ts, m.unread_count, m.last_msg_ts, m.last_msg_preview
FROM ai.chat_member m
JOIN ai.chat c ON c.id = m.chat_id
WHERE m.member_iid = $user_iid
  AND m.deleted_ts IS NULL
  AND m.archived_ts IS NULL
  AND c.kind = 'prompt'
  AND c.deleted_ts IS NULL
ORDER BY m.pinned_ts DESC NULLS LAST, m.last_msg_ts DESC;
```

On new message: update `chat.last_msg_ts` + preview, then the owner's `chat_member` row.

### Per-user list UX

| Field | Table | Scope | UI Indicator |
|-------|-------|-------|--------------|
| Pin | `chat_member.pinned_ts` | per user | Pinned icon at top |
| Archive | `chat_member.archived_ts` | per user | Archived section |
| Unread | `chat_member.unread_count` | per user | Unread badge |
| Status | `chat_member.last_msg_status` | per user | Spinner (`streaming`), Blue dot (`done`), Red dot (`error`) |
| Relative Time | `chat_member.last_msg_ts` | per user | `now`, `5m ago`, `2h ago`, or Date |
| `#tag`, title | `chat` | thread metadata | Title |

Clicking a chat clears the unread dot (`unread_count = 0`, dot dismissed).

### Prompt Execution Resilience (NATS JetStream)

Prompt turns are submitted via `ReqPrompt` and enqueued onto NATS JetStream stream `C35_CHAT_PROMPT`:
1. Worker leases the job with `ack_wait = 60s` (heartbeat).
2. Worker publishes deltas to `c35.user.{owner_iid}.chat.{chat_id}`.
3. Client WebSocket on any server pod subscribes to the user subject and delivers frames to app.
4. **Crash recovery:** If a server pod restarts or crashes during a turn, JetStream redelivers unacknowledged prompt jobs to another surviving pod. The client reconnects, re-subscribes, and resumes without losing state.

---

## Kind: `prompt` (personal AI)

```
chat.kind = prompt
chat.owner_iid = user.iid
chat.model = LLM preference
chat_member: one row (member_iid = owner)
```

- User ↔ AI; assistant uses `role=assistant`.
- Canvas / UI blocks on assistant messages (`blocks_json`).
- Billing trace on assistant turns (see [billing.md](billing.md)).
- No `ai_reply_enabled` (abort in-flight turn only).

### Mentions (composer `@`)

`ReqPromptSend.mention_ids[]` — zero or more refs (`iid:{snowflake}`, `catalog:{id}`).

Server resolves all refs → **`MentionContext`** (sites, devices, …). Prompt includes `[MENTION TARGETS]` and `[SITE CONTEXTS]` (multi-site). See [site-ai.md](site-ai.md).

| Mention kind | `topic_id` | Force tools (baseline) |
|--------------|------------|------------------------|
| `site` identity | `web.builder` | `site.draft_put`, `site.publish`, `site.product_put` |
| `remote` / `iot` | `device` | `device.screenshot` |
| catalog `@research` | `research` | via `inst` |

**Multi-site:** compare/report turns may mention 2+ sites; writes still require explicit `site_iid` when ambiguous. Reads use `site.query.run`.

---

### Turn Execution Modes (`tool_mode`)

Each `ReqPromptSend` specifies `tool_mode` to define tool boundary and safety:

- **`tool_mode = "agent"` (Default)**:
  - Full tool orchestration.
  - Matches cluster tools, device control skills, and Tool RAG retrieval.
  - Model can invoke modifying operations (file writes, shell execution, device control).

- **`tool_mode = "ask"`**:
  - Pure conversational or read-only advisory mode.
  - Invoked persistently via the mode pill or one-shot via the `/ask <query>` slash command.
  - Filters `eligible_tools` strictly to `readonly = true` or `vec![]`.
  - Tool RAG is bypassed (`rag_skipped = true, reason = "ask_mode"`), reducing latency, GPU overhead, and token cost.

---

## Kind: `direct` (user ↔ user) — **DEFERRED**

Tables exist (`chat.kind=direct`, `chat_direct_pair`, `chat_member` × 2) for a future release.

- **Not shown in Home inbox**
- **No UI in Phase 1**
- When shipped later: likely separate Messages page or contact flow — not mixed with AI prompt list

---

## Kind: `bot_peer` (bot channel conversation)

Bots page — **not** in Home inbox.

```
chat.kind = bot_peer
chat.bot_iid, channel_id, peer_key, peer_name, peer_pic
chat.ai_reply_enabled  -- stop toggles THIS conversation only
```

List: `WHERE bot_iid = ? ORDER BY last_msg_ts DESC`.

Bot LLM model is fixed on the **bot identity** (`identity.meta.model`), not per conversation. Billing: dedicated bot plan or fallback to owner personal quota — see [billing-plans.md](billing-plans.md).

### Stop (bot_peer only)

**Scope:** one `chat.id` — not the bot, not the channel.

| `ai_reply_enabled` | Behavior |
|--------------------|----------|
| `true` | AI auto-replies; staff can send manual messages |
| `false` | AI silent; staff manual send still works (`source=staff`) |

---

## Messages (`ai.chat_msg`)

| source | Used when |
|--------|-----------|
| `prompt` | Home AI user/assistant turns |
| `user` | Direct user-to-user (**deferred**) |
| `external` | Telegram/WhatsApp peer (bot_peer) |
| `staff` | Operator manual send (bot_peer) |

---

## Sync

See [sync.md](sync.md).

```sql
-- Home inbox delta (prompt only)
WHERE chat_member.member_iid = $user AND chat_member.updated_ts > $since
  AND chat.kind = 'prompt'

-- bot_peer (Bots page)
WHERE chat.bot_iid = $bot AND chat.updated_ts > $since
```

---

## Wire (proto)

See [`../schemas/proto/c35/chat.proto`](../schemas/proto/c35/chat.proto).

| Message | Purpose |
|---------|---------|
| `Chat`, `ChatMember`, `ChatMsg` | Row shapes |
| `ReqInboxList` | Home inbox (**prompt only**) |
| `ReqPrompt` / `ResPromptDelta` | AI streaming |
| `ReqChatStop` | bot_peer stop (**one chat**) |
| `ReqChatSend` | Staff manual send |

---

## Transactional Safety & Multi-Row Consistency

All multi-row operations across chats and messages execute within atomic database transactions (`pool.begin()`):
1. **Chat Creation (`chat_ensure`)**: Atomic creation of `ai.chat` and initial `ai.chat_member` row prevents dangling unlinked chat threads.
2. **Chat Activity Touch (`chat_touch`)**: Atomically updates both the master thread (`ai.chat.last_msg_ts`, `ai.chat.last_msg_preview`) and user inbox member state (`ai.chat_member.last_msg_ts`, `ai.chat_member.last_msg_preview`, `ai.chat_member.last_msg_status`).
3. **Bot Peer Staff Send (`chat_send`)**: Inserts into `ai.chat_msg` and updates `ai.chat` preview/timestamp in a single transaction.
4. **Channel Message Ingestion (`chat_msg_external_put` / `chat_msg_assistant_put`)**: Message insertion and conversation preview updates are committed together, guaranteeing thread list and message history never fall out of sync.

---

## Context compaction (long threads)

Prompt threads can exceed model context limits. Server-side **compaction** keeps prompts within budget without deleting UI history.

| Layer | What |
|-------|------|
| Token packing | Newest messages fill a token budget (replaces hard `LIMIT 20`) |
| Rolling summary | Older turns compressed into `ai.chat.context_summary` |
| Memory | Durable facts extracted to `ai.memory` on compact + per-turn gate + idle backfill |

Full spec: [context-compaction.md](context-compaction.md).

---

## Related docs

- Shell UI: [ui.md](ui.md)
- Billing: [billing.md](billing.md)
- Context compaction: [context-compaction.md](context-compaction.md)

Canonical DDL: [`../schemas/chat.sql`](../schemas/chat.sql)

