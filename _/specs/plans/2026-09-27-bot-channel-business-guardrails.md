# Bot Channel Business Guardrails Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship business-focused defaults for Telegram/WhatsApp bot channels: keep **Strict mode**, add **Auto Block Spammer** (10 out-of-scope refusals → stop that peer conversation), disable **voice** on channels, accept **inbound images only** with size limits, and align docs with behavior.

**Architecture:** Bot policy lives in `identity(kind=bot).meta` (`strict_mode`, `auto_block_spammer`). Strict mode continues to emit compose signal `bot:strict` → `inst.bot.strict`. Out-of-scope refusals prefix a machine token `[bot-oos]` (stripped before outbound); `mod_channel` increments `ai.chat.meta.strict_oos_count` per `bot_peer` and sets `ai_reply_enabled = false` at threshold (same semantics as manual Stop). Inbound rejects voice/non-image/large blobs before CAS download or STT; outbound is text (+ optional image blocks from LLM), no TTS voice replies on channels.

**Tech Stack:** Rust (`mod_chat`, `mod_channel`, `channel_whatsapp_device`), Flutter (`clients/app`), SQL seeds (`_/schemas/inst.sql`), docs (`_/specs/channels.md`, `_/specs/identity.md`, `_/specs/ui.md`).

## Global Constraints

- Read `spec.md`, `_/specs/channels.md`, `_/specs/identity.md`, `_/specs/ui.md`, `_/specs/chat.md`, `_/specs/inst.md` before coding.
- Bot identity: `kind=bot`, `type=chat`; platforms in `meta.channels[]` only.
- Keep user-facing label **Strict mode**; meta key stays `strict_mode`; compose signal stays `bot:strict`.
- New meta key: `auto_block_spammer` (bool, default `true`); effective only when `strict_mode == true`.
- Do not rename to "Limited Mode".
- Per-peer block uses existing `ai.chat.ai_reply_enabled` on `kind=bot_peer` (see `_/schemas/chat.sql`).
- Counter in `ai.chat.meta` JSON (no migration): `strict_oos_count` (integer).
- Constants (lock in one Rust module, e.g. `mod_channel/src/policy.rs`):
  - `BOT_OOS_MARKER`: `[bot-oos]`
  - `AUTO_BLOCK_OOS_THRESHOLD`: `10`
  - `CHANNEL_INBOUND_IMAGE_MAX_BYTES`: `5_242_880` (5 MiB) — adjust in review if needed
  - `CHANNEL_UNSUPPORTED_REPLY`: short bilingual-friendly template (owner language agnostic; prefer English + polite ID line or single EN line — pick one in Task 0)
- Verify: `cd servers && cargo build -p server_ai`; `cd remotes && cargo build -p c_remote_windows` only if untouched; `cd servers && cargo test -p c35_mod_channel`; `cd servers/channel_whatsapp_device && cargo test` if worker touched; `cd clients/app && flutter analyze`.
- Server deploy: `.\_\scripts\deploy\publish_server.ps1` after `mod_chat` / `mod_channel` changes.
- Worker deploy: `.\_\scripts\deploy\publish_channel_whatsapp_device.ps1` only if `servers/channel_whatsapp_device/**` changes.
- Do not commit unless user asks.

---

## Multitask Map

```
Track 0 (Docs + inst seed) ──► Track 2 (OOS marker + auto-block) depends inst text
Track 1 (Bot meta defaults) ──► Track 2 + Track 5 (Flutter meta)

Parallel wave 1:
  • Agent A → Track 0
  • Agent B → Track 1
  • Agent C → Track 3 (inbound media/voice) — can start after Track 0 constants agreed
  • Agent D → Track 4 (outbound no-voice)
  • Agent E → Track 5 (Flutter toggles)

Track 2 (auto-block) ──► after Track 0 + Track 1

Track 6 (Tests) ──► after Tracks 2–4

Track 7 (Deploy + manual E2E) ──► after Track 6
```

**Dependency summary**

| Track | Blocks | Blocked by |
|-------|--------|------------|
| 0 | 2 | — |
| 1 | 2, 5 | — |
| 2 | 6, 7 | 0, 1 |
| 3 | 6, 7 | 0 (constants) |
| 4 | 6, 7 | — |
| 5 | 7 | 1 (meta keys) |
| 6 | 7 | 2, 3, 4 |
| 7 | — | 6 |

---

## Track 0 — Docs + inst contract (`[bot-oos]`)

### Task 0.1: Document bot meta policy fields

**Files:**
- Modify: `_/specs/identity.md` — add `strict_mode`, `auto_block_spammer`, `inst_base`, `web_search` to bot meta example.
- Modify: `_/specs/ui.md` — Bots create wizard: Strict mode + Auto Block Spammer (visible only when Strict on).
- Modify: `_/specs/channels.md` — replace § Voice / broad media with: text + inbound images (size cap), no channel voice; auto-block behavior; OOS marker (internal, stripped).

**Acceptance:**
- [ ] Docs describe threshold 10, counter reset on in-scope reply, unblock via existing Stop/resume on Bots page.
- [ ] Docs state worker + Meta + Telegram paths share same policy at server inbound.

### Task 0.2: Update `inst.bot.strict` for OOS marker

**Files:**
- Modify: `_/schemas/inst.sql` — append to `inst.bot.strict` body (UPDATE block):

  When refusing because the user message is **out of scope** for this business, the **first line** of the assistant reply MUST be exactly `[bot-oos]` on its own line, then a blank line, then the polite refusal visible to the customer. When answering in scope, do NOT include `[bot-oos]`.

**Acceptance:**
- [ ] Seed applies on deploy/migrate path used by team (note: production DB may need manual `UPDATE ai.inst` or migration script — document in plan footer).
- [ ] No change to `triggers` / `exclude_tools` arrays.

---

## Track 1 — Bot meta parsing + defaults

### Task 1.1: Extend `BotTurnMeta`

**Files:**
- Modify: `servers/crates/mod_chat/src/bot_meta.rs`
- Modify: `servers/crates/mod_identity/src/identity_put.rs` — default `auto_block_spammer: true` when missing (mirror `strict_mode`).

**Interfaces:**

```rust
pub struct BotTurnMeta {
    pub strict_mode: bool,
    pub auto_block_spammer: bool,
    pub web_search: bool,
}

pub fn bot_auto_block_enabled(meta: &BotTurnMeta) -> bool {
    meta.strict_mode && meta.auto_block_spammer
}
```

**Acceptance:**
- [ ] Unit tests in `bot_meta.rs` or `mod_chat` tests for defaults and `bot_auto_block_enabled` gating.

### Task 1.2: Load bot policy in channel turn path

**Files:**
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs` — load `BotTurnMeta` (already loads bot meta); no compose change needed beyond existing `bot:strict`.

**Acceptance:**
- [ ] `cargo build -p server_ai` passes.

---

## Track 2 — Auto block spammer (server)

### Task 2.1: Policy module + OOS strip/count

**Files:**
- Create: `servers/crates/mod_channel/src/policy.rs`
- Modify: `servers/crates/mod_channel/src/lib.rs` — `mod policy; pub use policy::*` as needed.

**Functions (suggested):**

```rust
pub fn reply_oos_strip(reply: &str) -> (String, bool); // strips leading [bot-oos] line(s), returns (clean, was_oos)
pub const AUTO_BLOCK_OOS_THRESHOLD: u32 = 10;
```

**Acceptance:**
- [ ] Tests: strip with/without marker; marker only on first line; preserve body newlines.

### Task 2.2: Peer counter + block in DB

**Files:**
- Modify: `servers/crates/mod_channel/src/peer.rs` — helpers:

```rust
pub async fn chat_strict_oos_count_get/set/reset(pool, chat_id) -> Result<u32>;
pub async fn chat_ai_reply_set(pool, chat_id, enabled: bool) -> Result<()>;
pub async fn chat_strict_oos_apply(
    pool, bot_iid, chat_id, owner_iid, was_oos: bool, auto_block: bool,
) -> Result<Option<BlockedInfo>>; // Some when newly blocked at threshold
```

**Behavior:**
- If `was_oos`: increment count; else reset to 0.
- If `auto_block && count >= 10`: `ai_reply_enabled = false`; optional log via existing `log_put` (topic `channel`, text English) with meta `bot_iid`, `chat_id`, `peer`, `strict_oos_count`.
- Do **not** emit new `event_kind` unless registered in `_/specs/event.md` (v1: system log only).

**Acceptance:**
- [ ] SQL uses `meta = jsonb_set` on `ai.chat.meta` for `strict_oos_count`.

### Task 2.3: Wire into `execute_channel_turn`

**Files:**
- Modify: `servers/crates/mod_channel/src/turn.rs`

**Flow after `channel_prompt_turn` succeeds:**
1. Load bot meta → `bot_auto_block_enabled`.
2. `(reply, was_oos) = reply_oos_strip(&reply)`.
3. If auto block enabled: `chat_strict_oos_apply(...)`.
4. If newly blocked: optionally replace outbound with nothing extra (last reply already sent refusal on 10th) OR skip duplicate — **on 10th OOS still deliver that refusal once**, then block before next inbound.
5. Pass stripped `reply` to `channel_reply_nats` / `chat_msg_assistant_put`.

**Acceptance:**
- [ ] Blocked peer: next inbound stored but no turn scheduled (`inbound.rs` already checks `chat_ai_reply_enabled`).

### Task 2.4: Reset counter on manual resume

**Files:**
- Modify: `servers/crates/mod_chat/src/bot_peer.rs` — in `chat_stop` when `stopped == false` (re-enable replies), reset `strict_oos_count` on that chat.

**Acceptance:**
- [ ] Test or manual note: Stop → Resume clears counter.

---

## Track 3 — Inbound: no voice, images only, size limit

### Task 3.1: Central inbound filter

**Files:**
- Modify: `servers/crates/mod_channel/src/policy.rs` — `inbound_attachment_allowed(mime, size_bytes) -> bool` (image/* only, size ≤ max).
- Modify: `servers/crates/mod_channel/src/inbound.rs`

**Behavior:**
| Inbound | Action |
|---------|--------|
| Voice / audio (`is_voice` or audio mime) | Do not STT; set user-visible stub message; reply once with `CHANNEL_UNSUPPORTED_REPLY` if text would otherwise be empty; schedule turn only if owner policy allows text stub |
| Non-image attachment | Drop attachment; append note to message or use stub |
| Image over size cap | Skip CAS; ignore attachment |
| Text-only | unchanged |

**Simplify:** Remove or bypass `transcribe_voice_logged` call when channel policy is always no-voice (delete STT path for channels in v1, or guard with `channel_voice_enabled() -> false`).

**Acceptance:**
- [ ] Empty message after filter → return early (no turn), same as today `empty channel message`.

### Task 3.2: Telegram / WhatsApp Meta parsers

**Files:**
- Modify: `servers/crates/mod_channel/src/telegram/mod.rs` — do not attach voice/audio/video/document/sticker for channel policy (or mark for filter in inbound).
- Modify: `servers/crates/mod_channel/src/whatsapp/mod.rs` — same for Meta cloud payload.

**Acceptance:**
- [ ] Update `mod_channel/tests/outbound_telegram_test.rs` / parser unit tests if present.

### Task 3.3: Media upload webhook size cap

**Files:**
- Modify: `servers/crates/mod_channel/src/webhook.rs` — `DefaultBodyLimit::max(CHANNEL_INBOUND_IMAGE_MAX_BYTES)` on media upload route only.

**Acceptance:**
- [ ] Oversize upload returns 413 or 400 without CAS write.

### Task 3.4: WhatsApp device worker inbound

**Files:**
- Modify: `servers/channel_whatsapp_device/src/media.rs` — only `image_message` uploads; audio/video/document/sticker → text stub + no upload (or skip publish); voice → unsupported stub, `is_voice: false` for server (no speak typing).

**Acceptance:**
- [ ] `cargo build -p channel_whatsapp_device` + unit tests in `media.rs` if added.

---

## Track 4 — Outbound: no voice on channels

### Task 4.1: Disable TTS / voice outbound

**Files:**
- Modify: `servers/crates/mod_channel/src/outbound.rs` — force `speak = false` in `channel_reply_nats` / `deliver_telegram` / `deliver_whatsapp*` (ignore inbound `is_voice` for outbound).
- Modify: `servers/crates/mod_channel/src/typing.rs` — always `typing`, never `record_voice`.

**Acceptance:**
- [ ] Adjust or remove tests that expect `sendVoice` / `wa_cloud_send_audio` in `mod_channel/tests/*`.

### Task 4.2: Fix channel vision prompt (optional but recommended)

**Files:**
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs` — align `attach_prompt` with `prompt_turn.rs` (`[image: /fs/{hash}]` for `image/*`).

**Acceptance:**
- [ ] Image-only inbound can be seen by multimodal turn.

---

## Track 5 — Flutter: toggles on bot create

### Task 5.1: Auto Block Spammer UI

**Files:**
- Modify: `clients/app/lib/widgets/bots/in_bot_create.dart`

**UI:**
- State: `_autoBlockSpammer = true`.
- Meta JSON: `'auto_block_spammer': _strictMode && _autoBlockSpammer` (when strict off, persist `false` or omit — server defaults handle merge).
- Below Strict mode `SwitchListTile`, when `_strictMode`:
  - Title: **Auto Block Spammer**
  - Subtitle: **Auto block user who send 10+ unrelated messages**
- When user turns Strict off, hide second toggle (keep local state for if they turn Strict back on).

**Acceptance:**
- [ ] `flutter analyze` clean.

### Task 5.2 (Optional v1.1): Bot settings edit

**Files:** TBD — no edit screen today; meta only on create. If owner must change flags later, add small sheet from Bots nav (out of scope unless user requests in same sprint).

---

## Track 6 — Tests

### Task 6.1: Rust unit tests

**Files:**
- Create/extend: `servers/crates/mod_channel/src/policy.rs` `#[cfg(test)]`
- Create: `servers/crates/mod_channel/tests/auto_block_test.rs` (optional integration with pool mock — prefer pure unit + inbound filter tests)

**Cases:**
- [ ] OOS strip + count increment logic (pure).
- [ ] Threshold 10 blocks (mock pool or sqlx test if repo pattern exists).
- [ ] Inbound voice → no STT, unsupported reply path.
- [ ] Non-image attachment dropped.

### Task 6.2: Regression

**Commands:**

```powershell
cd servers
cargo test -p c35_mod_channel
cargo build -p server_ai
cd ../clients/app
flutter analyze
```

---

## Track 7 — Deploy + manual E2E

### Task 7.1: Publish server

```powershell
.\_\scripts\deploy\publish_server.ps1
```

If worker changed:

```powershell
.\_\scripts\deploy\publish_channel_whatsapp_device.ps1
```

### Task 7.2: Apply inst seed on cluster DB

Run UPDATE from `_/schemas/inst.sql` for `inst.bot.strict` on production YB (or ship one-off admin SQL).

### Task 7.3: Manual E2E checklist

- [ ] Create bot: Strict on, Auto Block on.
- [ ] Telegram or WhatsApp: send 10 off-topic messages → bot refuses with normal text (no `[bot-oos]` visible).
- [ ] 11th message: no bot reply; Bots UI shows stopped conversation.
- [ ] Resume conversation → counter reset; bot replies again.
- [ ] Send voice note → unsupported template (no transcription bill).
- [ ] Send PDF → ignored / text-only handling.
- [ ] Send image under 5 MiB → bot can describe (if vision path fixed in 4.2).

---

## Production DB note

`inst.bot.strict` text change does not auto-apply from git alone. After deploy, execute the `UPDATE ai.inst SET inst = ... WHERE id = 'inst.bot.strict'` portion from `_/schemas/inst.sql` against `c35` YB, then reload inst cache if server caches (restart rollout suffices).

---

## Out of scope (this plan)

- Rename Strict → Limited Mode.
- Configurable threshold in UI (hardcode 10 in v1).
- New NATS `event_kind` for peer blocked (system log only v1).
- Bot edit screen for policy toggles (optional Task 5.2).
- Home app `prompt_run` behavior (unchanged).

---

## Agent dispatch checklist (execution wave)

| Wave | Task tool description | Tracks |
|------|------------------------|--------|
| 1 | Docs + inst SQL + bot_meta defaults | 0, 1 |
| 1 | Inbound media/voice filter + worker | 3 |
| 1 | Outbound no-voice + channel attach_prompt | 4 |
| 1 | Flutter create toggles | 5 |
| 2 | Auto-block policy module + turn wiring + chat_stop reset | 2 |
| 3 | Tests + build verify | 6 |
| 4 | Publish + E2E | 7 |

Each subagent: `model: inherit`; run verify per `verify-after-edit.mdc` for touched areas.
