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

| Field | Table | Scope |
|-------|-------|-------|
| Pin | `chat_member.pinned_ts` | per user |
| Archive | `chat_member.archived_ts` | per user |
| Unread | `chat_member.unread_count` | per user |
| `#tag`, title | `chat` | thread metadata |

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

## Related docs

- Shell UI: [ui.md](ui.md)
- Billing: [billing.md](billing.md)

Canonical DDL: [`../schemas/chat.sql`](../schemas/chat.sql)
