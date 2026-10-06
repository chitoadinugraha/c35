# Live Call tool bundles + mention resume

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax. Dispatch one Task per track. Model: inherit only.

**Goal:** A Live Call declares a small topic bundle (not the full tool registry). An explicit site or device mention swaps that bundle by resuming Gemini on the server while the app socket stays up. Talk shows the same sticky mention chip and does not reconnect.

**Architecture:** `live_tool_select` picks declarations from `ToolDefinition.topics`, the offer allowlist, the mention kind, and the existing staff and mention gates, capped at 32. Gemini Live accepts tools only in `BidiGenerateContentSetup`, so a mention change closes the Google socket and opens a new one with `sessionResumption.handle`. Native-audio Live has no context cache. On resume, prior turns stay in the handle and are not replayed. If the handle is missing or rejected, the server sends a short text `clientContent` transcript. The Flutter chip is the same sticky mention the server uses.

**Tech Stack:** Rust (`c35_mod_live`, `c35_mod_chat` tool defs), YSQL `ai.live_offer`, Flutter (`page_live_call`, `ui_talk_stage`), Gemini Live WebSocket (`gemini-3.8-live`).

## Global Constraints

- Gemini Developer API (`generativelanguage.googleapis.com` Bidi). No Vertex mid-session system-role update.
- Tools and system instruction change only on a new setup. Model id stays the same.
- No `CachedContent` and no input-cache id. Do not bill or code as if one exists.
- Resumption handle lives in memory on the proxy task. It is valid for 2 hours after the Google socket ends. It is not a cache key.
- The client live WebSocket never receives `{"type":"hangup"}` for a mention swap.
- Swap only on an explicit mention commit (chip set or clear). No speech-topic classifier. No per-utterance RAG.
- Talk (`ReqPrompt.talk`) keeps `prompt_turn`. No Gemini reconnect on Talk.
- Cap `LIVE_TOOL_DECL_CAP = 32`. Debounce mention swaps for 8 seconds. PCM buffer during a swap is at most 4 seconds (drop oldest).
- Do not swap while a tool call is in flight or before `generationComplete` of the current assistant turn. Queue one pending mention.
- An unknown tool name still returns `toolResponse` with an error object. Do not drop the Google socket.
- Staff and admin tools stay off Live even if their topic is listed.
- Site-builder tools (`web.builder`, `site.commerce`) are declared only while a site identity is the active mention.
- Device tools (`device`, `computer_use`) are declared when the caller has a paired remote, or the active mention is a device.
- `live.gemini` and `live.gemini.thinker` keep `tool_topics` empty (no cluster tools) unless a later product change says otherwise.
- Verify: from `servers/`, `cargo test -p c35_mod_live live_tool -- --test-threads=8` and `cargo build -p server_ai`. Flutter: `.\_\scripts\dev\verify_flutter_app.ps1`. Then `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Update `_/docs/live-call.md` in Track E before calling the behavior shipped.
- Do not commit unless the user asks. Do not `docker build` arm64 locally.

## Locked decisions

| Decision | Choice |
|---|---|
| Initial catalog | Offer `tool_topics` intersect tool `topics`, then mention and staff gates, then cap |
| `live.alienai` topics | `general` at setup. Device topics are added by the selector when a remote exists. Site topics are added only for a site mention |
| Mid-call tool RAG | No |
| Mention swap | Server-side Google reconnect plus resumption handle |
| History on successful resume | Handle only, plus one text pin line. Do not resend `[RECENT CHAT HISTORY]` |
| History on failed resume | Last 6 `ai.chat_msg` text rows as `clientContent`, each trimmed to 500 chars. No PCM replay |
| Chip | One primary chip, center of the Live page and the Talk stage. Tap clears. Label comes from the mention catalog |

---

## Multitask map

```
Wave 1 (parallel):  Track A + Track B + Track C
Wave 2 (parallel):  Track D (needs A and B) + Track C2 (needs C)
Wave 3:             Track E after D
```

| Track | Focus | Depends |
|---|---|---|
| A | `live_tool_select` and offer `tool_topics` | none |
| B | `sessionResumption`, `contextWindowCompression`, text seed on a fresh setup | none |
| C | `UiMentionChip` on Talk and Live (display and clear) | none |
| C2 | Live page sends mention JSON. Talk writes the sticky mention for the next prompt | C |
| D | Mention swap state machine in `google.rs` | A, B |
| E | `_/docs/live-call.md` | D |

**Parallel wave 1:** Track A, Track B, Track C.

---

## Track A: Tool bundle selector

### Task A1: `tool_topics` on `ai.live_offer`

**Files:**

- Modify: `_/schemas/live_offer.sql`
- Create: `_/schemas/migrations/20261006_live_offer_tool_topics.sql`
- Modify: `servers/crates/mod_live/src/catalog.rs` (`LiveOfferRow.tool_topics: Vec<String>`)

**SQL:**

```sql
ALTER TABLE ai.live_offer
    ADD COLUMN IF NOT EXISTS tool_topics TEXT[] NOT NULL DEFAULT '{}';

UPDATE ai.live_offer
SET tool_topics = ARRAY['general']::TEXT[], updated_ts = NOW()
WHERE id = 'live.alienai';
```

Keep the `INSERT ... ON CONFLICT` in `live_offer.sql` in sync. `live.alienai` writes `ARRAY['general']`. Every other seeded offer writes `'{}'`.

`live_catalog_reload` selects `tool_topics`. An empty array stays `vec![]`. `live_catalog_defaults` sets the same values.

- [ ] Add the column and the `live.alienai` update in both SQL files.
- [ ] Extend `LiveOfferRow`, `live_catalog_reload`, and `live_catalog_defaults`.
- [ ] From `servers/`: `cargo build -p c35_mod_live`.

### Task A2: `live_tool_select`

**Files:**

- Create: `servers/crates/mod_live/src/tool_select.rs`
- Modify: `servers/crates/mod_live/src/lib.rs` (`pub mod tool_select;`)
- Test: `tool_select.rs` under `#[cfg(test)]`

**Produces:**

```rust
pub const LIVE_TOOL_DECL_CAP: usize = 32;

pub fn live_tool_select(
    tools: &[ToolDef],
    offer_topics: &[String],
    mention: &MentionContext,
    staff: &StaffView,
    caps: &SiteCapabilityView,
) -> Vec<ToolDef>
```

**Rules, in order:**

1. If `offer_topics` is empty, return an empty vec.
2. Drop tools that fail `tool_staff_eligible` or `tool_mention_eligible`.
3. Drop tools whose `requires_global_roles` is non-empty. Live never declares staff tools.
4. Start `active_topics` as a copy of `offer_topics`.
5. If `mention.devices` is non-empty, add `device` and `computer_use` when missing.
6. Add `web.builder` and `site.commerce` only when `mention.default_site_iid` is `Some`. Owning a site is not a mention. Task D sets `default_site_iid` only when the mention frame names that site. Stop the current `google.rs` behavior that sets it whenever `sites.len() == 1` for this selector. Single-device auto-resolve stays.
7. Keep a tool when any of its `topics` is in `active_topics`, or when `topics` is empty and `general` is active.
8. Stable-sort by tool name. Truncate to `LIVE_TOOL_DECL_CAP`.

- [ ] Write these tests with small `ToolDef` values. Do not boot the full dispatcher.

```rust
#[test]
fn live_tool_select_empty_offer_declares_nothing() {}

#[test]
fn live_tool_select_general_keeps_web_and_memory_drops_presentation() {}

#[test]
fn live_tool_select_adds_device_topics_when_devices_present() {}

#[test]
fn live_tool_select_site_topics_only_when_default_site_set() {}

#[test]
fn live_tool_select_caps_at_32() {}
```

- [ ] `cargo test -p c35_mod_live live_tool_select -- --test-threads=8` fails first.
- [ ] Implement `live_tool_select`.
- [ ] Re-run the same test. Expected: pass.

---

## Track B: Resume handle and text seed

### Task B1: Setup fields and handle store

**Files:**

- Create: `servers/crates/mod_live/src/resume.rs`
- Modify: `servers/crates/mod_live/src/lib.rs`
- Modify: `servers/crates/mod_live/src/google.rs` (the `setup_obj` built before the first `g_tx.send`)

**Produces:**

```rust
pub struct LiveResume {
    pub handle: Option<String>,
}

impl LiveResume {
    pub fn note_server_msg(&mut self, v: &serde_json::Value);
    pub fn setup_fields(&self) -> serde_json::Value;
}

pub fn live_text_seed(rows: &[(String, String)]) -> Vec<serde_json::Value>;
```

`setup_fields` returns JSON merged into `setup_obj`:

```json
{
  "sessionResumption": {},
  "contextWindowCompression": { "slidingWindow": {} }
}
```

When `handle` is `Some`, `sessionResumption.handle` is that string. Always send `sessionResumption` so Google emits handles on a fresh session.

`note_server_msg` reads `sessionResumptionUpdate`. Store `newHandle` only when `resumable` is true and the handle is non-empty.

`live_text_seed` takes up to 6 `(role, content)` rows, oldest first. Skip blanks. Trim each content to 500 chars. Map `assistant` to `model`. One `clientContent` message per row:

```json
{
  "clientContent": {
    "turns": [{ "role": "user", "parts": [{ "text": "..." }] }],
    "turnComplete": true
  }
}
```

- [ ] Unit-test: handle stored only when resumable; `live_text_seed` maps `assistant` to `model` and trims to 500.
- [ ] `cargo test -p c35_mod_live live_text_seed -- --test-threads=8` fails first, then passes.
- [ ] In `google.rs`, merge `setup_fields()` into the initial setup. Call `note_server_msg` on each decoded Google JSON frame (text and binary UTF-8).
- [ ] On a fresh session (`handle` is `None`), after `setupComplete`, send `live_text_seed` of the last 6 chat rows. Remove the `[RECENT CHAT HISTORY]` append from `full_system`. Keep time, location, paired-device, and site blocks in the system instruction.

This task does not open a second Google socket. Track D does that.

---

## Track C: Mention chip

### Task C1: Chip widget

**Files:**

- Create: `clients/app/lib/widgets/ai/ui_mention_chip.dart`
- Create: `clients/app/test/ui_mention_chip_test.dart`
- Modify: `clients/app/lib/widgets/ai/ui_talk_stage.dart`
- Modify: `clients/app/lib/pages/page_live_call.dart`
- Modify: `clients/app/lib/pages/page_ai_home.dart` (pass label into `UiTalkStage`)

```dart
class UiMentionChip extends StatelessWidget {
  const UiMentionChip({super.key, required this.label, required this.onClear});
  final String label;
  final VoidCallback onClear;
}
```

Place it in the center column, under the timer and above the transcript. Hide it when `label` is empty. Talk gets optional `mentionLabel` and `onMentionClear` on `UiTalkStage`. Live binds the same widget to `LiveCallSession.mentionLabel` (empty until C2).

Talk clear uses the existing sticky-mention and `bound_device` clear path in `page_ai_home`. It does not touch a live socket.

- [ ] Widget test: label `Desk` is visible; tap close calls `onClear` once; empty label builds no chip.
- [ ] `flutter test test/ui_mention_chip_test.dart` from `clients/app` fails first.
- [ ] Implement and place the chip.
- [ ] Re-run the test, then `.\_\scripts\dev\verify_flutter_app.ps1`.

### Task C2: Send the mention

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart`
- Modify: `clients/app/lib/pages/page_live_call.dart`
- Modify: `clients/app/lib/pages/page_ai_home.dart`

**Produces on `LiveCallSession`:**

- `mentionLabel` and `switching` as `ValueNotifier`
- `Future<void> setMention({required String mentionId, required String label})`
- `Future<void> clearMention()`

`setMention` sends this text frame only when `ready` is true:

```json
{"type":"mention","mention_ids":["iid:<snowflake>"]}
```

`clearMention` sends `{"type":"mention","mention_ids":[]}`.

On `{"live":"mention","label":"...","switching":true}` or `switching:false`, update the notifiers. Do not set `ready` false while switching. Hangup stays `{"type":"hangup"}`.

The Live page picks a device or site from the same mention catalog the composer uses, then calls `setMention`.

Talk `onMentionClear` removes that id from `_mentionIds` and from the chat sticky or bound device. The next Talk send omits it.

---

## Track D: Mention swap on the Google socket

**Files:**

- Modify: `servers/crates/mod_live/src/google.rs`
- Modify: `servers/crates/mod_live/src/bin/live_device_tool_smoke.rs` so the smoke binary calls `live_tool_select`
- Test: `live_swap_should_run` in `servers/crates/mod_live/src/resume.rs`

**Consumes:** `live_tool_select`, `LiveResume`, `live_text_seed`.

Client text is `{"type":"mention","mention_ids":["iid:N"]}` or `[]`.

```rust
struct LiveSwap {
    mention_ids: Vec<String>,
    last_swap: Option<std::time::Instant>,
    tool_inflight: bool,
    generation_open: bool,
    pending: Option<Vec<String>>,
    pcm_buf: Vec<u8>,
}

pub fn live_swap_should_run(
    now: std::time::Instant,
    last: Option<std::time::Instant>,
    tool_inflight: bool,
    generation_open: bool,
) -> bool
```

`live_swap_should_run` is false when a tool is in flight, generation is open, or `last` is within 8 seconds. Otherwise true.

**Behavior:**

1. Initial setup calls `live_tool_select` with `offer.tool_topics`. `default_site_iid` stays `None` until a site mention. `mention.devices` still lists paired remotes so device topics attach.
2. Equal mention ids: ignore. Debounce or busy: keep one `pending` slot (latest wins).
3. When the swap runs: tell the client `switching: true`, stop forwarding PCM, append it to `pcm_buf` (cap `4 * 16000 * 2` bytes, drop from the front).
4. Close the Google sink. Connect again with the same model, a system instruction that names the site or device, `sessionResumption.handle` when present, and `tool_decls` of the new `live_tool_select` result.
5. After `setupComplete`, if the handle was accepted, send one `clientContent` turn `Now focused on: <name>`. Do not send `live_text_seed`. If connect fails or the first message is an error, open one more socket with no handle, then send `live_text_seed` from the last 6 `ai.chat_msg` rows.
6. Flush `pcm_buf` as `realtimeInput.audio`. Send `{"live":"mention","mention_ids":[...],"label":"<name>","switching":false}`.
7. If `pending` is set, swap once more.
8. `tool_inflight` is true from `toolCall` until that `toolResponse` is written. `generation_open` is true from the first model audio or text of a turn until `generationComplete` or `turnComplete`.
9. If the dispatcher has no such tool, respond with `{"error":"unknown tool"}` inside `functionResponse`. This still applies after a swap drops a tool.
10. Log `live: tool decls` with the count on every setup.

Extract `live_google_setup(...)` for the first socket and the swap socket. Extract `live_exec_tool_calls` so the text and binary paths do not each grow a second copy.

- [ ] Test `live_swap_should_run` for inflight, generation open, debounce, and the idle case.
- [ ] `cargo test -p c35_mod_live live_swap_should_run -- --test-threads=8`.
- [ ] Implement the state machine.
- [ ] `cargo test -p c35_mod_live --lib -- --test-threads=8` and `cargo build -p server_ai` from `servers/`.

Manual check: start `live.alienai` and confirm the setup log count is far below the full registry. Set a site mention and confirm a second setup log that includes site tools, with no client hangup.

---

## Track E: Docs

**Files:**

- Modify: `_/docs/live-call.md` section "Unified Tool Pipeline & Device Awareness"

Replace the sentence that says all eligible cluster tools are sent in the initial setup. State instead:

- Setup declares the `live_tool_select` result. Offer topics, plus device topics when a remote is paired, plus site topics only for an active site mention. Cap 32.
- The mention chip sends `{"type":"mention"}`. The server resumes Gemini with a new setup. The app socket stays up.
- The resumption handle keeps spoken context. There is no Gemini input cache. A failed resume seeds text `clientContent` from the last 6 stored turns.
- Talk uses the same chip and the normal prompt pipeline.

- [ ] Edit the doc.
- [ ] `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.

---

## Coverage

| Requirement | Task |
|---|---|
| Full registry stays off the Live wire | A2, D |
| Topic split: general, device, site | A2 |
| Offer controls the base topics | A1 |
| Explicit mention swap, not speech RAG | D, C2 |
| User does not see a hangup | D |
| Resumption handle, no input cache | B1, D |
| Compact text seed only for a fresh session or a failed resume | B1, D |
| New setup changes instruction and tools; model stays | D |
| Chip on Live and Talk; Talk does not reconnect | C1, C2 |
| Debounce, no swap mid-tool or mid-generation, PCM buffer | D |
| Unknown tool returns an error response | D |
| `ai.chat_msg` is kept | D only reads it for the seed |

## Out of scope

- Per-utterance vector RAG on Live
- OpenAI Realtime and Grok Voice tool bundles
- Context-cache billing
- Changing the Gemini model on resume
- Detecting a site or device from the transcript
