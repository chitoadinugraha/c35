# Chat message feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the chat owner mark an assistant reply Good or Bad, pick a seeded reason, add a comment, and see that note plus a thank-you as a thread under the same message.

**Architecture:** Feedback is not a `ai.chat_msg` row and is never packed into the next prompt. A reason catalog plus one vote per `(msg_id, rater_iid)` plus a post table hold the thread. The menu section only collects the thumb; a sheet collects reason and comment; `ReqChatMsgFeedbackPut` upserts the vote and one system thank-you post. Opening a chat loads `ReqChatMsgFeedbackList` and paints threads under assistant bubbles.

**Tech Stack:** YSQL (`_/schemas`), prost + Dart protoc (`chat.proto`, `wire.proto`), `c35_mod_chat` + `wire_ws`, Flutter menu/sheet/thread.

## Global Constraints

- Home prompt chats only. Do not add this menu or thread to `ui_bot_conversation.dart`.
- Trace stays root-only (`msgCanTrace`). Good / Bad show only when the bubble is assistant and `msg.id > 0`.
- Thumb icons use menu text color `#F4F4F5` (`ChatMessageMenuStyle.rowText`). No green/red.
- One section at the bottom of the bubble menu: row 1 is Trace and Copy message ID (or Copy request ID when `msgId == 0`); row 2 is Good Answer and Bad Answer.
- Reason is required. Slug `other` requires a non-empty comment. Other comments are optional.
- One current vote per message per rater. Changing it updates the same row and the same system post. It does not insert a second thank-you.
- Clearing (vote unspecified) sets `deleted_ts` on the vote and its posts. The thread disappears.
- Thank-you is a persisted `system` post, not a snackbar.
- Do not write feedback into `ai.chat_msg`, `ai.log`, or prompt history (`context_pack_history`).
- Do not build a reply composer. Staff replies are a later insert into `ai.chat_feedback_post`.
- Do not `git commit` unless the user asks.
- New `.sql` / `.rs` / `.dart` / `.md` files must be UTF-8. After edits run `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Server verify: `cd servers; cargo build -p server_ai`.
- App verify: `._\scripts\dev\verify_flutter_app.ps1` plus the widget test named in Task 4.

## Locked copy

| Vote | Locale prefix `id` | Else |
|------|--------------------|------|
| bad | Terima kasih. Catatanmu kami simpan untuk jawaban berikutnya. | Thanks. We'll use this note on the next answer. |
| good | Terima kasih. Senang jawaban ini membantu. | Thanks. Glad this answer helped. |

Server picks the string from `ReqChatMsgFeedbackPut.locale`.

## Locked reasons

Seed `ai.chat_feedback_reason` with these ids. `vote` is `good` or `bad`.

| id | slug | vote | sort | label_en | label_id |
|----|------|------|------|----------|----------|
| 1 | accurate | good | 10 | Correct | Benar |
| 2 | helpful | good | 20 | Solved the request | Menyelesaikan permintaan |
| 3 | followed | good | 30 | Followed instructions | Mengikuti instruksi |
| 4 | right_tool | good | 40 | Right tool or data | Tool atau data yang tepat |
| 5 | clear | good | 50 | Clear | Jelas |
| 6 | wrong | bad | 10 | Wrong answer | Jawaban salah |
| 7 | incomplete | bad | 20 | Incomplete | Kurang atau tidak selesai |
| 8 | ignored | bad | 30 | Ignored instructions | Tidak mengikuti instruksi |
| 9 | wrong_tool | bad | 40 | Wrong or missing tool | Tool salah atau tidak dipanggil |
| 10 | hallucinated | bad | 50 | Made up data | Mengarang data |
| 11 | bad_format | bad | 60 | Broken layout | Tampilan rusak |
| 12 | other | bad | 70 | Other | Lainnya |

---

## File map

| File | Responsibility |
|------|----------------|
| `_/schemas/chat_feedback.sql` | Catalog, vote, posts. Canonical DDL. |
| `_/schemas/migrations/20261004_chat_feedback_v1.sql` | `\i ../chat_feedback.sql` for a live cluster that does not boot-apply. |
| `servers/crates/store/src/schema.rs` | Include the new file immediately after `chat`. |
| `_/schemas/proto/c35/chat.proto` | Enums and RPC messages. |
| `_/schemas/proto/c35/wire.proto` | WsReq/WsRes fields 172–174. |
| `_/docs/chat.md` | Short section so later edits match the spec. |
| `servers/crates/mod_chat/src/chat_feedback.rs` | reason list, put, list. |
| `servers/crates/mod_chat/src/lib.rs` | `mod` + `pub use`. |
| `servers/crates/wire_ws/src/session.rs` | Three match arms. |
| `servers/crates/mod_chat/tests/chat_feedback_test.rs` | DB test behind `C35_TEST_DB=1`, plus pure tests for thank-you and validation that do not need a DB. |
| `clients/app/lib/widgets/ai/ui_chat_message_menu.dart` | `ChatMessageMenuButtonRow`. |
| `clients/app/lib/widgets/ai/ui_msg_context_menu.dart` | One feedback section. |
| `clients/app/lib/widgets/ai/ui_msg_feedback_sheet.dart` | Reason list + comment + save. |
| `clients/app/lib/widgets/ai/ui_msg_feedback_thread.dart` | Thread under the assistant body. |
| `clients/app/lib/c/chat/chat_conn.dart` | Three RPC methods. |
| `clients/app/lib/c/store/chat_store.dart` | `feedbackByMsgId`, load, put, clear. |
| `clients/app/lib/pages/page_ai_home.dart` | Wire menu, sheet, thread. |
| `clients/app/test/ui_msg_feedback_menu_test.dart` | Menu rows. |
| `clients/app/test/ui_msg_feedback_thread_test.dart` | Thread shows comment and thank-you. |

## Waves

| Wave | Tasks | Why together |
|------|-------|----------------|
| 1 | 1–3 | SQL, proto, docs, codegen. Later tasks import these names. |
| 2 | 4 and 5 in parallel | Menu widget does not need the server. Server does not need the menu. |
| 3 | 6 then 7 | Sheet and thread need generated Dart types and `ChatConn` methods, which need the server messages from wave 1. Task 7 needs the sheet from task 6. |

---

### Task 1: Schema

**Files:**
- Create: `_/schemas/chat_feedback.sql`
- Create: `_/schemas/migrations/20261004_chat_feedback_v1.sql`
- Modify: `servers/crates/store/src/schema.rs`

**Interfaces:**
- Consumes: `ai.chat_msg(id)`, `ai.chat(id)`, `ai.identity(id)`
- Produces: tables `ai.chat_feedback_reason`, `ai.chat_msg_feedback`, `ai.chat_feedback_post`

- [ ] **Step 1: Write `_/schemas/chat_feedback.sql`**

```sql
-- c35 chat answer feedback. Not a chat_msg row. Never packed into prompt history.

CREATE TABLE IF NOT EXISTS ai.chat_feedback_reason (
    id          SMALLINT PRIMARY KEY,
    slug        VARCHAR(32) NOT NULL,
    vote        VARCHAR(8) NOT NULL,
    label_en    TEXT NOT NULL,
    label_id    TEXT NOT NULL,
    sort        INT NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_chat_feedback_reason_slug UNIQUE (slug),
    CONSTRAINT chk_chat_feedback_reason_vote CHECK (vote IN ('good', 'bad'))
);

INSERT INTO ai.chat_feedback_reason (id, slug, vote, label_en, label_id, sort) VALUES
    (1,  'accurate',     'good', 'Correct',                  'Benar',                          10),
    (2,  'helpful',      'good', 'Solved the request',       'Menyelesaikan permintaan',       20),
    (3,  'followed',     'good', 'Followed instructions',    'Mengikuti instruksi',            30),
    (4,  'right_tool',   'good', 'Right tool or data',       'Tool atau data yang tepat',      40),
    (5,  'clear',        'good', 'Clear',                    'Jelas',                          50),
    (6,  'wrong',        'bad',  'Wrong answer',             'Jawaban salah',                  10),
    (7,  'incomplete',   'bad',  'Incomplete',               'Kurang atau tidak selesai',      20),
    (8,  'ignored',      'bad',  'Ignored instructions',     'Tidak mengikuti instruksi',      30),
    (9,  'wrong_tool',   'bad',  'Wrong or missing tool',    'Tool salah atau tidak dipanggil', 40),
    (10, 'hallucinated', 'bad',  'Made up data',             'Mengarang data',                 50),
    (11, 'bad_format',   'bad',  'Broken layout',            'Tampilan rusak',                 60),
    (12, 'other',        'bad',  'Other',                    'Lainnya',                        70)
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    vote = EXCLUDED.vote,
    label_en = EXCLUDED.label_en,
    label_id = EXCLUDED.label_id,
    sort = EXCLUDED.sort;

CREATE TABLE IF NOT EXISTS ai.chat_msg_feedback (
    id          BIGINT PRIMARY KEY,
    msg_id      BIGINT NOT NULL REFERENCES ai.chat_msg(id) ON DELETE CASCADE,
    chat_id     BIGINT NOT NULL REFERENCES ai.chat(id) ON DELETE CASCADE,
    owner_iid   BIGINT NOT NULL REFERENCES ai.identity(id),
    rater_iid   BIGINT NOT NULL REFERENCES ai.identity(id),
    req_id      VARCHAR(64) NOT NULL DEFAULT '',
    vote        VARCHAR(8) NOT NULL,
    reason_id   SMALLINT NOT NULL REFERENCES ai.chat_feedback_reason(id),
    comment     TEXT NOT NULL DEFAULT '',
    created_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts  TIMESTAMPTZ,
    CONSTRAINT chk_chat_msg_feedback_vote CHECK (vote IN ('good', 'bad'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_msg_feedback_msg_rater
    ON ai.chat_msg_feedback (msg_id, rater_iid);

CREATE INDEX IF NOT EXISTS idx_chat_msg_feedback_chat
    ON ai.chat_msg_feedback (chat_id, msg_id)
    WHERE deleted_ts IS NULL;

CREATE TABLE IF NOT EXISTS ai.chat_feedback_post (
    id           BIGINT PRIMARY KEY,
    feedback_id  BIGINT NOT NULL REFERENCES ai.chat_msg_feedback(id) ON DELETE CASCADE,
    author_iid   BIGINT NULL REFERENCES ai.identity(id),
    author_role  VARCHAR(16) NOT NULL,
    text         TEXT NOT NULL,
    created_ts   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts   TIMESTAMPTZ,
    CONSTRAINT chk_chat_feedback_post_role CHECK (author_role IN ('system', 'user', 'staff'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_feedback_post_system
    ON ai.chat_feedback_post (feedback_id)
    WHERE author_role = 'system' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_feedback_post_feedback
    ON ai.chat_feedback_post (feedback_id, created_ts)
    WHERE deleted_ts IS NULL;
```

`author_iid` is NULL for the automatic thank-you. Proto field `author_iid = 0` means that NULL.

- [ ] **Step 2: Migration file**

`_/schemas/migrations/20261004_chat_feedback_v1.sql` contains only:

```sql
-- Live cluster one-off. Fresh boot applies chat_feedback.sql via SCHEMA_APPLY_ORDER.
\i ../chat_feedback.sql
```

- [ ] **Step 3: Register in `schema.rs`**

After `CHAT_SQL`:

```rust
pub const CHAT_FEEDBACK_SQL: &str = include_str!("../../../../_/schemas/chat_feedback.sql");
```

In `SCHEMA_APPLY_ORDER`, immediately after `("chat", CHAT_SQL)`:

```rust
("chat_feedback", CHAT_FEEDBACK_SQL),
```

- [ ] **Step 4: UTF-8 check**

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

Expected: no UTF-16 files.

---

### Task 2: Protobuf and codegen

**Files:**
- Modify: `_/schemas/proto/c35/chat.proto` (append before end of file)
- Modify: `_/schemas/proto/c35/wire.proto` (WsReq field block and WsRes field block)
- Generated: `clients/app/lib/c/pb/c35/chat.pb.dart`, `wire.pb.dart`, and prost via `c35_proto`

**Interfaces:**
- Consumes: Task 1 column names
- Produces: `ChatFeedbackVote`, `ChatFeedbackAuthorRole`, `ChatFeedbackReason`, `ChatFeedbackPost`, `ChatMsgFeedback`, `ReqChatFeedbackReasonList`, `ResChatFeedbackReasonList`, `ReqChatMsgFeedbackPut`, `ResChatMsgFeedbackPut`, `ReqChatMsgFeedbackList`, `ResChatMsgFeedbackList`. Wire names `chat_feedback_reason_list = 172`, `chat_msg_feedback_put = 173`, `chat_msg_feedback_list = 174` on both `WsReq` and `WsRes`.

- [ ] **Step 1: Append to `chat.proto`**

```protobuf
enum ChatFeedbackVote {
  CHAT_FEEDBACK_VOTE_UNSPECIFIED = 0;
  CHAT_FEEDBACK_VOTE_GOOD = 1;
  CHAT_FEEDBACK_VOTE_BAD = 2;
}

enum ChatFeedbackAuthorRole {
  CHAT_FEEDBACK_AUTHOR_ROLE_UNSPECIFIED = 0;
  CHAT_FEEDBACK_AUTHOR_ROLE_SYSTEM = 1;
  CHAT_FEEDBACK_AUTHOR_ROLE_USER = 2;
  CHAT_FEEDBACK_AUTHOR_ROLE_STAFF = 3;
}

message ChatFeedbackReason {
  int32 id = 1;
  string slug = 2;
  ChatFeedbackVote vote = 3;
  string label = 4;
  int32 sort = 5;
}

message ChatFeedbackPost {
  int64 id = 1;
  int64 feedback_id = 2;
  int64 author_iid = 3;
  ChatFeedbackAuthorRole author_role = 4;
  string text = 5;
  int64 created_ts_ms = 6;
}

message ChatMsgFeedback {
  int64 id = 1;
  int64 msg_id = 2;
  int64 chat_id = 3;
  ChatFeedbackVote vote = 4;
  int32 reason_id = 5;
  string reason_slug = 6;
  string reason_label = 7;
  string comment = 8;
  int64 updated_ts_ms = 9;
  repeated ChatFeedbackPost posts = 10;
}

message ReqChatFeedbackReasonList {
  string locale = 1;
  ChatFeedbackVote vote = 2;
}

message ResChatFeedbackReasonList {
  repeated ChatFeedbackReason reasons = 1;
}

message ReqChatMsgFeedbackPut {
  int64 msg_id = 1;
  int64 chat_id = 2;
  ChatFeedbackVote vote = 3;
  int32 reason_id = 4;
  string comment = 5;
  string locale = 6;
}

message ResChatMsgFeedbackPut {
  ChatMsgFeedback feedback = 1;
}

message ReqChatMsgFeedbackList {
  int64 chat_id = 1;
  string locale = 2;
}

message ResChatMsgFeedbackList {
  repeated ChatMsgFeedback feedback = 1;
}
```

`vote = CHAT_FEEDBACK_VOTE_UNSPECIFIED` on put clears the vote. There is no separate Get RPC.

- [ ] **Step 2: Wire fields**

In `message WsReq`, after `ReqTaskRunCancelDevice task_run_cancel_device = 171;`:

```protobuf
    ReqChatFeedbackReasonList chat_feedback_reason_list = 172;
    ReqChatMsgFeedbackPut chat_msg_feedback_put = 173;
    ReqChatMsgFeedbackList chat_msg_feedback_list = 174;
```

In `message WsRes`, after `ResTaskRunCancelDevice task_run_cancel_device = 171;`:

```protobuf
    ResChatFeedbackReasonList chat_feedback_reason_list = 172;
    ResChatMsgFeedbackPut chat_msg_feedback_put = 173;
    ResChatMsgFeedbackList chat_msg_feedback_list = 174;
```

- [ ] **Step 3: Generate**

```powershell
.\_\scripts\protoc.ps1
cd servers
cargo build -p c35_proto
```

Expected: both succeed. Dart types exist on `chat.pb.dart` and `WsReq` has `chatFeedbackReasonList`, `chatMsgFeedbackPut`, `chatMsgFeedbackList`.

- [ ] **Step 4: UTF-8 check** on the proto files (generated Dart from protoc is already UTF-8).

---

### Task 3: Doc

**Files:**
- Modify: `_/docs/chat.md` after the Messages table (around the `ai.chat_msg` source table)

**Interfaces:**
- Consumes: table and RPC names from Tasks 1–2
- Produces: a spec section later tasks must not contradict

- [ ] **Step 1: Add this section**

```markdown
## Answer feedback

Owner rating of one assistant `ai.chat_msg`. Not a transcript row. `context_pack_history` must not read these tables.

| Table | Holds |
|-------|--------|
| `ai.chat_feedback_reason` | Seeded good/bad reasons |
| `ai.chat_msg_feedback` | One vote per `(msg_id, rater_iid)` |
| `ai.chat_feedback_post` | Thread. v1 inserts one `author_role=system` thank-you. `author_iid` NULL. |

| RPC | Wire |
|-----|------|
| `ReqChatFeedbackReasonList` | 172 |
| `ReqChatMsgFeedbackPut` | 173. `vote=0` clears (`deleted_ts` on the vote and its posts). |
| `ReqChatMsgFeedbackList` | 174. Active votes for one `chat_id`. |

Home bubble menu only. Trace stays root-only. Good / Bad require `msg.id > 0`.
```

---

### Task 4: Menu section

**Files:**
- Modify: `clients/app/lib/widgets/ai/ui_chat_message_menu.dart`
- Modify: `clients/app/lib/widgets/ai/ui_msg_context_menu.dart`
- Create: `clients/app/test/ui_msg_feedback_menu_test.dart`

**Interfaces:**
- Consumes: `ChatMessageMenuAction`, `msgBubbleMenuItems`
- Produces: `ChatMessageMenuButtonRow` with `List<ChatMessageMenuAction> actions` (always 2). `msgBubbleMenuItems` gains `VoidCallback? onGoodAnswer` and `VoidCallback? onBadAnswer`. When both are non-null and `isAssistant` and `msgId > 0`, the last section is one divider plus two button rows. Trace and copy stay in row 1 even when Good/Bad are hidden (root trace rules unchanged). When `canTrace` is false, row 1 is a single Copy action (not a button row). When both Trace and Copy exist, they are one `ChatMessageMenuButtonRow` and there is no divider between them.

- [ ] **Step 1: Failing widget test**

`clients/app/test/ui_msg_feedback_menu_test.dart`:

```dart
import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('trace and copy message id share one row; good and bad share the next', (tester) async {
    late List<ChatMessageMenuItem> items;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      items = msgBubbleMenuItems(
        context,
        plainText: 'hello',
        viewerIsRoot: true,
        isAssistant: true,
        reqId: 'req-1',
        msgId: 42,
        onGoodAnswer: () {},
        onBadAnswer: () {},
      );
      return const SizedBox.shrink();
    })));

    final rows = items.whereType<ChatMessageMenuButtonRow>().toList();
    expect(rows, hasLength(2));
    expect(rows[0].actions.map((a) => a.label).toList(), ['Trace', 'Copy message ID']);
    expect(rows[1].actions.map((a) => a.label).toList(), ['Good Answer', 'Bad Answer']);
    final traceIndex = items.indexOf(rows[0]);
    final feedbackIndex = items.indexOf(rows[1]);
    expect(items[traceIndex - 1], isA<ChatMessageMenuDivider>());
    expect(items.sublist(traceIndex + 1, feedbackIndex).whereType<ChatMessageMenuDivider>(), isEmpty);
  });

  testWidgets('good and bad hidden when msg id is missing', (tester) async {
    late List<ChatMessageMenuItem> items;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      items = msgBubbleMenuItems(
        context,
        plainText: 'hello',
        viewerIsRoot: true,
        isAssistant: true,
        reqId: 'req-1',
        msgId: 0,
        onGoodAnswer: () {},
        onBadAnswer: () {},
      );
      return const SizedBox.shrink();
    })));
    expect(items.whereType<ChatMessageMenuButtonRow>().length, 1);
    expect(items.any((i) => i is ChatMessageMenuAction && i.label == 'Good Answer'), isFalse);
  });
}
```

- [ ] **Step 2: Run the test**

```powershell
cd clients/app
flutter test test/ui_msg_feedback_menu_test.dart
```

Expected: FAIL because `ChatMessageMenuButtonRow` and the callbacks do not exist.

- [ ] **Step 3: Implement the row and the section**

In `ui_chat_message_menu.dart`, add:

```dart
class ChatMessageMenuButtonRow extends ChatMessageMenuItem {
  const ChatMessageMenuButtonRow({required this.actions});

  final List<ChatMessageMenuAction> actions;
}
```

In `_ChatMessageMenuPanel.build`, handle `ChatMessageMenuButtonRow` by a `Row` of two `Expanded` children. Each child reuses the existing menu row look (icon 16, label 13, `rowText` for both icon and label). Hit targets are the two halves. Do not render a shortcut. If `actions.length != 2`, render nothing.

In `msgBubbleMenuItems`, replace the separate Trace block and Copy block with:

1. Build optional Trace action (same behavior as today: dismiss menu, `showMsgTraceBottomSheet`).
2. Build optional Copy action (same clipboard snackbar as today).
3. If both exist, emit one divider (if not already emitted by earlier sections; keep a divider before this section) and one `ChatMessageMenuButtonRow`.
4. If only Copy exists, emit the divider and a normal `ChatMessageMenuAction`.
5. If `onGoodAnswer != null && onBadAnswer != null && isAssistant && msgId > 0`, emit `ChatMessageMenuButtonRow` with labels `Good Answer` (`Icons.thumb_up_alt_outlined`) and `Bad Answer` (`Icons.thumb_down_alt_outlined`). Callbacks dismiss the menu via `ContextMenuController.removeAny()` then call the callback. Do not insert a divider between row 1 and row 2.

Pass the two callbacks through `msgBubbleContextMenu` into `msgBubbleMenuItems`. `page_ai_home.dart` stays unchanged in this task (callbacks default null, so Good/Bad stay hidden until Task 7).

- [ ] **Step 4: Re-run the widget test.** Expected: PASS.

- [ ] **Step 5: UTF-8 check.**

---

### Task 5: Server handlers

**Files:**
- Create: `servers/crates/mod_chat/src/chat_feedback.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Modify: `servers/crates/wire_ws/src/session.rs`
- Create: `servers/crates/mod_chat/tests/chat_feedback_test.rs`

**Interfaces:**
- Consumes: proto messages from Task 2, `c35_store::snowflake::snowflake_id`, `crate::inbox::ts_ms` if that helper is `pub` (otherwise duplicate the millis conversion locally: `chrono::DateTime::timestamp_millis`)
- Produces:
  - `pub async fn chat_feedback_reason_list(pool: &PgPool, req: ReqChatFeedbackReasonList) -> Result<ResChatFeedbackReasonList>`
  - `pub async fn chat_msg_feedback_put(pool: &PgPool, rater_iid: i64, req: ReqChatMsgFeedbackPut) -> Result<ResChatMsgFeedbackPut>`
  - `pub async fn chat_msg_feedback_list(pool: &PgPool, rater_iid: i64, req: ReqChatMsgFeedbackList) -> Result<ResChatMsgFeedbackList>`
  - `pub fn feedback_thanks(vote: &str, locale: &str) -> &'static str`
  - `pub fn feedback_comment_ok(slug: &str, comment: &str) -> bool`

- [ ] **Step 1: Pure tests (no DB)** in `chat_feedback_test.rs`

```rust
use c35_mod_chat::{feedback_comment_ok, feedback_thanks};

#[test]
fn thanks_id_and_en() {
    assert_eq!(
        feedback_thanks("bad", "id-ID"),
        "Terima kasih. Catatanmu kami simpan untuk jawaban berikutnya."
    );
    assert_eq!(feedback_thanks("good", "id-ID"), "Terima kasih. Senang jawaban ini membantu.");
    assert_eq!(
        feedback_thanks("bad", "en-US"),
        "Thanks. We'll use this note on the next answer."
    );
    assert_eq!(feedback_thanks("good", "en"), "Thanks. Glad this answer helped.");
}

#[test]
fn other_requires_comment() {
    assert!(!feedback_comment_ok("other", "  "));
    assert!(feedback_comment_ok("other", "harusnya 3 slide"));
    assert!(feedback_comment_ok("wrong", ""));
}
```

`feedback_thanks`: if `locale` trimmed, lowercased, starts with `id`, use the Indonesian sentence; otherwise English. Unknown vote returns `""`.

`feedback_comment_ok`: slug `other` requires `comment.trim()` non-empty; every other slug returns true.

- [ ] **Step 2: Run**

```powershell
cd servers
cargo test -p c35_mod_chat --test chat_feedback_test thanks_id_and_en other_requires_comment
```

Expected: FAIL until the functions exist, then PASS after Step 3. `lib.rs` must `pub use` them for the integration test crate to see them. If the test crate cannot see crate-private fns, `pub use` from `lib.rs`.

- [ ] **Step 3: `chat_feedback.rs` behavior**

`chat_feedback_reason_list`: `SELECT id, slug, vote, label_en, label_id, sort FROM ai.chat_feedback_reason WHERE active ORDER BY sort, id`. If `req.vote` is good, add `AND vote = 'good'`. If bad, `AND vote = 'bad'`. Unspecified returns both. Label is `label_id` when `req.locale` starts with `id` (case-insensitive), else `label_en`. Map vote string to `ChatFeedbackVote`.

`chat_msg_feedback_put`:

1. Reject `msg_id == 0` or `chat_id == 0` with `anyhow!("msg_id required")` / `chat_id required`.
2. Load the message. Caller must be a non-deleted `ai.chat_member` of `chat_id`. Message must be `role = 'assistant'`, `deleted_ts IS NULL`, `m.chat_id = req.chat_id`, `m.id = req.msg_id`. Also select `m.req_id` and `c.owner_iid`. Miss → `anyhow!("message not found")`.
3. If `req.vote` is unspecified: `UPDATE ai.chat_msg_feedback SET deleted_ts = NOW(), updated_ts = NOW() WHERE msg_id = $1 AND rater_iid = $2 AND deleted_ts IS NULL`. Then soft-delete posts of that feedback id. Return `ResChatMsgFeedbackPut { feedback: None }` (proto3: default empty message is fine; client treats `feedback.id == 0` as cleared).
4. If vote is good or bad: load reason `WHERE id = $reason AND active`. Reject missing reason. Reject when `reason.vote` does not equal `good`/`bad` for the request. Reject when `!feedback_comment_ok(&slug, &comment)`.
5. Upsert vote. Look up existing row by `(msg_id, rater_iid)` including soft-deleted.
   - None: `INSERT` with `snowflake_id()`, `owner_iid` from the chat, `rater_iid`, `req_id` from the message, trimmed comment, `deleted_ts` NULL.
   - Some: `UPDATE` vote, reason_id, comment, `updated_ts = NOW()`, `deleted_ts = NULL`.
6. Thank-you: `INSERT ... WHERE NOT EXISTS` a live system post, or `UPDATE` the live system post `text` to `feedback_thanks` when the vote changes. Never insert a second system post. `author_iid` NULL, `author_role = 'system'`, id from `snowflake_id()` on insert.
7. Return the same shape as one list element (vote, reason slug, localized label, comment, posts with `created_ts_ms`).

`chat_msg_feedback_list`: member check on `chat_id` (same join as put). Select votes `deleted_ts IS NULL` for that chat and `rater_iid`. Attach live posts ordered by `created_ts, id`. Empty chat returns an empty list, not an error. `chat_id == 0` → `anyhow!("chat_id required")`. `reason_label` uses `req.locale` the same way as the reason list (`id` prefix → `label_id`, else `label_en`). Timestamps use `crate::inbox::ts_ms` (`pub(crate)`).

Wire arms in `session.rs`, same shape as `ChatPatch`:

| Body | Function | Error code |
|------|----------|------------|
| `ChatFeedbackReasonList` | `chat_feedback_reason_list` | `chat_feedback_reason_list_failed` |
| `ChatMsgFeedbackPut` | `chat_msg_feedback_put` | `chat_msg_feedback_put_failed` |
| `ChatMsgFeedbackList` | `chat_msg_feedback_list` | `chat_msg_feedback_list_failed` |

- [ ] **Step 4: DB test, skipped unless `C35_TEST_DB=1`**

Follow `prompt_followup_test.rs`: if env is not `1`, return. When set, use the test pool pattern already in that file. Assert: put bad + reason `ignored` + comment inserts one system post; second put with a new comment still yields one system post; put with `other` and empty comment errors; unspecified vote then list returns no row.

If `C35_TEST_DB` is unset, the skip is success for this step. Do not claim the DB test ran.

- [ ] **Step 5:** `cd servers; cargo build -p server_ai` and `cargo test -p c35_mod_chat --test chat_feedback_test`.

---

### Task 6: Sheet and client RPC

**Files:**
- Modify: `clients/app/lib/c/chat/chat_conn.dart`
- Create: `clients/app/lib/widgets/ai/ui_msg_feedback_sheet.dart`
- Create: `clients/app/test/ui_msg_feedback_sheet_test.dart`

**Interfaces:**
- Consumes: generated `ReqChatFeedbackReasonList`, `ReqChatMsgFeedbackPut`, `ChatFeedbackVote`, `ChatFeedbackReason`
- Produces:
  - `ChatConn.chatFeedbackReasonList({String locale = '', ChatFeedbackVote vote = ChatFeedbackVote.CHAT_FEEDBACK_VOTE_UNSPECIFIED})`
  - `ChatConn.chatMsgFeedbackPut({required int msgId, required int chatId, required ChatFeedbackVote vote, int reasonId = 0, String comment = '', String locale = ''})`
  - `ChatConn.chatMsgFeedbackList({required int chatId, String locale = ''})`
  - `Future<ChatMsgFeedback?> showMsgFeedbackSheet(BuildContext context, {required ChatConn conn, required int msgId, required int chatId, required ChatFeedbackVote vote, String locale = ''})`
  - Sheet pops the `ChatMsgFeedback` from a successful put. Cancel pops null. Client treats `feedback.id == 0` as cleared (not used by the sheet).

- [ ] **Step 1: `ChatConn` methods**

Mirror `chatHistoryClear`: `_rpc<Res...>(WsReq(...), (res) => res.chat...)`. Pass `Int64` for ids.

- [ ] **Step 2: Sheet widget test**

Pump `showMsgFeedbackSheet` is awkward. Instead test a public `MsgFeedbackSheet` widget with injected reasons and an `onSave` callback:

```dart
class MsgFeedbackSheet extends StatefulWidget {
  const MsgFeedbackSheet({
    super.key,
    required this.vote,
    required this.reasons,
    required this.onSave,
    this.initialReasonId = 0,
    this.initialComment = '',
    this.saving = false,
  });
  final ChatFeedbackVote vote;
  final List<ChatFeedbackReason> reasons;
  final int initialReasonId;
  final String initialComment;
  final bool saving;
  final void Function(int reasonId, String comment) onSave;
}
```

Test: reasons render as radio labels; Save disabled until one reason is selected; selecting `other` (slug) keeps Save disabled until the text field is non-empty; selecting `wrong` enables Save with an empty comment; Save calls `onSave` with that id and trimmed comment.

`showMsgFeedbackSheet` loads reasons via `conn.chatFeedbackReasonList(locale: locale, vote: vote)`, then presents this widget in `showModalBottomSheet` using the same colors as `showMsgTraceSheet` (`0xFF18181B`, top radius 16). Title is `Good Answer` or `Bad Answer`. Save calls `chatMsgFeedbackPut` and `Navigator.pop(context, res.feedback)`.

- [ ] **Step 3: `flutter test test/ui_msg_feedback_sheet_test.dart`** PASS.

---

### Task 7: Thread on the Home timeline

**Files:**
- Create: `clients/app/lib/widgets/ai/ui_msg_feedback_thread.dart`
- Modify: `clients/app/lib/c/store/chat_store.dart`
- Modify: `clients/app/lib/pages/page_ai_home.dart`
- Create: `clients/app/test/ui_msg_feedback_thread_test.dart`

**Interfaces:**
- Consumes: `ChatMsgFeedback`, `ChatFeedbackPost`, `ChatFeedbackAuthorRole`, sheet from Task 6, menu callbacks from Task 4
- Produces:
  - `ChatStore.feedbackFor(int msgId) -> ChatMsgFeedback?` (`id == 0` or missing → null)
  - `ChatStore.feedbackReplace(ChatMsgFeedback row)` and `ChatStore.feedbackClear(int msgId)`
  - `ChatStore.feedbackPull(ChatConn conn, int chatId, {required String locale})` calls `chatMsgFeedbackList` and replaces the map for that chat (drop previous rows whose `chatId` matches, then insert)
  - `UiMsgFeedbackThread({required ChatMsgFeedback feedback})`

- [ ] **Step 1: Thread widget test**

Build `UiMsgFeedbackThread` with a `ChatMsgFeedback` vote bad, `reasonLabel` `Tidak mengikuti instruksi`, comment `harusnya 3 slide`, one system post with the Indonesian bad thank-you. Expect those three strings. A feedback with `id == 0` is not built by the page (widget itself can still render). System post shows the prefix `Alien AI`.

- [ ] **Step 2: Widget**

Column, left border 2px `Color(0xFF3F3F46)`, padding left 10, top 8. Text style 13px, color `#A1A1AA` for the reason line, `#F4F4F5` for the comment and posts. Reason line: `Good answer` or `Bad answer` plus ` · ` plus `reasonLabel`. Comment paragraph only when `comment.trim()` is not empty. Each post: `Alien AI` when `authorRole` is system, otherwise the raw text only for v1 system posts (staff prefix is `Alien AI` too only for system; staff posts still render `text` with prefix `Alien` so a future row is visible). Keep the prefix map: system → `Alien AI`, staff → `Alien AI`, user → no prefix.

- [ ] **Step 3: Store**

`Map<int, ChatMsgFeedback> _feedbackByMsg = {}`. `feedbackPull` after a successful list. Call `feedbackPull` at the end of `msgsPullFromServer` when `chatId > 0`. Locale argument: pass `CatalogTranslationCache.instance.lang` from the page by adding an optional `locale` param to `msgsPullFromServer` defaulting to `''`. When `''`, server returns English labels; the page must pass the real lang. Find the existing `msgsPullFromServer` call sites in `page_ai_home.dart` and pass `locale: CatalogTranslationCache.instance.lang`.

- [ ] **Step 4: Page**

In `_threadContextMenu` / `msgBubbleContextMenu`, pass:

```dart
onGoodAnswer: !isUser && m.id > 0 ? () => unawaited(_feedback(m, ChatFeedbackVote.CHAT_FEEDBACK_VOTE_GOOD)) : null,
onBadAnswer: !isUser && m.id > 0 ? () => unawaited(_feedback(m, ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD)) : null,
```

`_feedback` opens `showMsgFeedbackSheet` with `locale: CatalogTranslationCache.instance.lang`. On a non-null result, `feedbackReplace` and `setState`.

Under `UiMsgUsage` in the assistant branch of the message builder (the `if (!hasError) UiMsgUsage` block), if `feedbackFor(m.id)` is non-null, add `UiMsgFeedbackThread`.

- [ ] **Step 5: Tests and app check**

```powershell
cd clients/app
flutter test test/ui_msg_feedback_menu_test.dart test/ui_msg_feedback_sheet_test.dart test/ui_msg_feedback_thread_test.dart
```

From repo root: `._\scripts\dev\verify_flutter_app.ps1` and `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.

From `servers`: `cargo build -p server_ai`.

---

## Out of scope

- Reply box, staff inbox, push notification
- Bot peer / channel transcripts
- Writing a row into `ai.chat_msg` or `ai.log`
- Changing Trace visibility
- Snackbar after save

## Spec coverage

| Requirement | Task |
|-------------|------|
| Trace + Copy message ID one row | 4 |
| Good / Bad row, text-colored thumbs | 4 |
| Reason catalog table | 1 |
| Vote table, one per msg+rater | 1, 5 |
| Post table for a later reply | 1, 5 |
| Comment textarea, `other` required | 5, 6 |
| Thank-you persisted, vote-specific copy | 5, 7 |
| Thread under the answer in history | 7 |
| Not in the model prompt | 1, 3 (separate tables; no `context_pack` edit) |
| Clear vote hides the thread | 5, 7 |
| Edit does not duplicate thank-you | 5 |
