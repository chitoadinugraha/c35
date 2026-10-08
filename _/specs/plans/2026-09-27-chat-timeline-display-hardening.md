# Chat timeline display + streaming state hardening

> **For agentic workers:** Use subagent-driven-development or executing-plans for implementation. Track steps with `- [ ]` checkboxes.

**Goal:** Eliminate wrong message text / infinite “thinking” in the Flutter Home chat when server data is correct (hot reload fixes UI).

**Architecture:** Treat `ChatStore` as source of truth; timeline widgets use **stable per-turn keys** (not mutable snowflake ids); streaming UI is driven by **`req_id` + server row status**, not list index; reconnect and chat open **reconcile** `promptBusy` from `chat_msg_list` / sync push.

**Tech stack:** Flutter (`clients/app`), `ChatStore`, `page_ai_home.dart`, `UiChatTimeline`, `chat_conn.dart`, existing `chat_store_test.dart`.

## Evidence (incident)

| Field | Value |
|-------|--------|
| Message id | `97484722463272960` |
| Role | `assistant` |
| Server `status` | `done` |
| Server content | “Besok adalah hari Senin, 28 September 2026.” |
| `req_id` | `bf63dd81-813e-48fe-9a81-d245152aef8a` |
| Symptom | Wrong user text + infinite thinking until hot reload |

**Conclusion:** Server committed a healthy turn; bug is **client render / local streaming state**.

## Global constraints

- No server API changes required for v1 (client-only).
- Match existing naming (`msgPut`, `promptBusyPut`, `chat_msg_list`).
- Verify: `cd clients/app && flutter analyze` and `flutter test` for touched tests.
- Do not claim cross-user leak fixes — scope is same-account UI integrity.

---

## Root causes to address

1. **Unstable list keys** — `ValueKey('${m.chatId}:${m.id}:${m.reqId}:${m.role}')` changes when local negative `id` merges to server snowflake → Flutter may reuse `Element` subtrees incorrectly.
2. **Index-based “live” streaming** — `promptingThis = promptBusy && i == lastIdx` ties spinner to **position**, not `req_id` (breaks with follow-ups, merges, or extra rows).
3. **Stale `promptBusy`** — WS stream `finally` missed (background, race, reconnect) while server row is already `done` → UI thinks turn never ended.
4. **Nested `ListenableBuilder` per row** — outer `itemCount` from one build, inner `rows[i]` from another → transient wrong `m` at index `i`.
5. **Composer submit snapshot** (secondary) — text read before `await casUpload` can desync composer vs sent text; fix to avoid future confusion.

---

## Status (2026-09-27)

Implemented in app: Tasks 1–6, 7 (toast), 9 (docs). Task 8 (dev overlay) deferred.

---

## Task 1 — Stable message identity (`client_msg_key`)

**Files:** `clients/app/lib/c/store/chat_store.dart`, `clients/app/lib/c/store/msg_row.dart` (or inline on `MsgRow`)

- [x] Add `String clientKey` on `MsgRow` (ULID or `req_id` + role for turns with `req_id`; ULID for orphans).
- [x] Set `clientKey` on optimistic insert in `page_ai_home.dart` `_composerSend` (user + assistant pair share turn context; user and assistant each get own key, assistant also stores `reqId`).
- [x] On `msgPut` / `_msgMerge`, **never change** `clientKey` when `id` upgrades local → server.
- [x] Persist `clientKey` in `_chatMsgsKey` JSON so reload keeps stability.

**Test:** `chat_store_test.dart` — merge server row by `req_id` keeps same `clientKey`.

---

## Task 2 — Timeline keys and item builder

**Files:** `clients/app/lib/pages/page_ai_home.dart`, `clients/app/lib/widgets/chat/ui_chat_timeline.dart`

- [x] Replace tile key with `ValueKey(m.clientKey)` (fallback: existing composite for legacy rows loaded without key).
- [x] Refactor `_threadBody` itemBuilder to a single `ListenableBuilder` wrapping the list (or pass `MsgRow m` from a prebuilt `List<MsgRow> rows` snapshot in one notifier callback) — **no** per-index builder that closes over stale `i` without resyncing `itemCount`.
- [x] Prefer `itemBuilder: (ctx, i) => _msgTile(rows[i], …)` where `rows` is the same list instance used for `itemCount`.

**Test:** Widget test optional; prioritize store tests + manual repro script below.

---

## Task 3 — Streaming UI by `req_id`, not index

**Files:** `page_ai_home.dart`, `clients/app/lib/c/chat/chat_inbox.dart` (`msgUsageStreaming`)

- [x] Add `ChatStore.promptLiveReqId` (mirror `pendingPromptReqId` while busy).
- [x] `promptingThis` := `promptBusyFor(m.chatId) && m.reqId.isNotEmpty && m.reqId == promptLiveReqId && m.role == 'assistant'`.
- [x] `msgUsageStreaming` — same `req_id` match for last assistant turn, not `i == lastAssistantIdx` alone.
- [x] `UiMsgTraceLoader(live: …)` uses the same rule.

**Test:** `chat_store_test.dart` — two assistant rows in one chat; only matching `req_id` is “live” when `promptBusyPut(true, reqId: …)`.

---

## Task 4 — Reconcile streaming state from server

**Files:** `page_ai_home.dart`, `chat_store.dart`, `chat_conn.dart` (reconnect listener exists)

- [x] Add `ChatStore.promptReconcileFromMsgs(int chatId, List<MsgRow> serverRows)`:
  - If local `promptBusy` but server assistant for `pendingPromptReqId` has `status == done` (or non-empty content + tokens) → `msgStreamEnd` fields from server row, `promptBusyPut(false)`.
  - If chat `lastMsgStatus == streaming` and not busy → `chatStatusStaleClear` (already partially exists).
- [x] Call reconcile after: `_selectChat`, `refreshFromConn`, `_reconnectedSub`, `_onSyncPush` (assistant msg with content).
- [x] On app resume (`WidgetsBindingObserver` in `page_ai_home` or `ChatConn`): `chatMsgList` + reconcile for active chat.

**Test:** Simulate store with busy + server-done assistant same `req_id` → reconcile clears busy.

---

## Task 5 — Stream lifecycle guard (watchdog)

**Files:** `page_ai_home.dart`

- [x] When starting `_composerSend`, record `promptWatchdog` `Timer` (e.g. 120s, configurable in debug).
- [x] On `end`/`fail`/`finally`, cancel timer.
- [x] On fire: `promptAbort` if still busy, then `msgStreamFail('Timed out')` or fetch `chatMsgList` + reconcile.
- [x] Log via `l()` with `req_id` for field debugging.

---

## Task 6 — Composer send integrity

**Files:** `clients/app/lib/widgets/ai/in_composer.dart`

- [x] Move `final text = _controller.text.trim()` to **immediately before** `_controller.clear()` / `onSend` (after uploads).
- [x] Optional: show small “Sending…” disable on field while `_submitting` (already partially gated).

**Test:** unit test with mock upload delay — text edited mid-flight sends latest (or block send while `_submitting`).

---

## Task 7 — Follow-up UX clarity (display-only)

**Files:** `page_ai_home.dart`, composer hint string

- [x] When `promptBusy` and user sends follow-up, append **optimistic user row** or toast: “Queued while current reply finishes” (product choice — at minimum toast).
- [x] Reduces “wrong last user bubble” confusion when follow-up does not add a row today.

---

## Task 8 — Dev diagnostics (tester/root only)

**Files:** `page_ai_home.dart` or `ui_msg_id.dart`

- [ ] Long-press message id (existing `UiMsgId`?) shows overlay: `id`, `req_id`, `clientKey`, `promptBusy`, `promptLiveReqId`.
- [ ] Helps confirm server vs local without hot reload.

---

## Task 9 — Docs

**Files:** `_/specs/chat.md` (short subsection)

- [x] Document `clientKey`, reconcile on reconnect, and that `promptBusy` is client-owned but must match server `chat_msg.status`.

---

## Verification matrix

| Scenario | Steps | Expected |
|----------|--------|----------|
| Normal turn | Send “besok hari apa?” | User + assistant match server; busy clears |
| Hot reload mid-stream | Send, hot reload during stream | After reload, reconcile or resume; no wrong bubble text |
| Pending chat migrate | New chat → server assigns id | Keys stable; streaming continues on correct assistant |
| Follow-up while busy | Send second line while streaming | No wrong user text on prior bubble; queue visible or toast |
| Reconnect | Kill WS during stream | Reconnect → reconcile → done or error |
| Message id spot check | Open chat containing `97484722463272960` | Assistant shows Monday answer; no infinite trace chips |

**Commands**

```powershell
cd clients/app
flutter analyze
flutter test test/chat_store_test.dart
```

---

## Rollout

1. Ship **Tasks 1–4** together (core fix).
2. **Task 5** watchdog in same release or immediate follow-up.
3. **Tasks 6–8** polish next app build.

## Out of scope (v1)

- Server prompt protocol changes.
- Cross-device push of client-only optimistic rows (server already correct).
- Clearing `SharedPreferences` chat cache on sign-out (separate hygiene task; optional Task 10).
