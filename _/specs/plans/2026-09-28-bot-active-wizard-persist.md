# Bot wizard persist + meta.active toggle - Multitask Plan

> **For agentic workers:** One Task per track in parallel waves. Subagent model: **inherit** only. Read spec.md, _/specs/identity.md, _/specs/channels.md before coding.

**Goal:** Keep draft bots after wizard step 1 (no rollback on close), refresh the bot list immediately, and gate channel AI replies with a bot-level On/Off toggle (`identity.meta.active`). Finish turns the bot on; new wizards create bots off until finish.

**Architecture:** Boolean `active` in bot meta JSON. Server defaults missing key to **true**. Inbound still logs messages but skips channel turn when inactive. Wizard stops identityDelete on cancel; sets active false on first put, true on finish.

**Tech Stack:** Rust mod_channel, mod_identity, mod_chat; Flutter in_bot_create, bot_store, ui_bot_peer_list, ui_bot_nav_list; en/id.json.

## Global Constraints

- Meta field: **active** (bool). Default when absent: **true**.
- Wizard step 1 Next: **active: false**. Finish: **active: true**.
- Per-chat Stop unchanged (ai.chat.ai_reply_enabled).
- Verify: cd servers && cargo build -p server_ai; cd clients/app && dart analyze on touched paths.
- Deploy server before client sets active false: publish_server.ps1.

---

## Multitask Map

| Track | Focus | Depends |
|-------|--------|---------|
| 0 | Docs (identity.md, channels.md) | - |
| 1 | bot_active parse + inbound gate | - |
| 2 | identity_put meta_merge default | - |
| 3 | bot_meta.dart + BotStore.botActivePut | 1 contract |
| 4 | Wizard: no cleanup, refreshBots, active flags | 2, 3 |
| 5 | UI toggle + off badge + i18n | 3 |
| 6 | Verify + deploy | all |

### Waves

| Wave | Parallel | Done when |
|------|----------|-----------|
| 1 | 0, 1, 2 | Gate live; docs locked |
| 2 | 3, 4 | Wizard persists; list updates after step 1 |
| 3 | 5 | Toggle in Bots UI |
| 4 | 6 | build + manual scenarios |

---

## Track 0 - Documentation

**Files:** _/specs/identity.md, _/specs/channels.md

Add to bot meta example: `"active": true`. Rules: false = no channel AI turns; default true if omitted; distinct from ai_reply_enabled per chat. Wizard creates active false until finish.

---

## Track 1 - Server gate

**Files:** servers/crates/mod_chat/src/bot_meta.rs, servers/crates/mod_channel/src/inbound.rs

Add:

```rust
pub fn bot_active_parse(meta: Option<&Value>) -> bool {
    meta.and_then(|m| m.get("active")).and_then(|v| v.as_bool()).unwrap_or(true)
}
pub async fn bot_active_load(pool: &PgPool, bot_iid: i64) -> bool;
```

In channel_inbound_handle after user message stored, before ChannelTurnJob schedule:

```rust
if !bot_active_load(&state.pool, bot_iid).await {
    return Ok((chat_id, peer_iid));
}
```

Keep dedup, peer chat, chat_msg_external_put when inactive.

---

## Track 2 - meta_merge

**Files:** servers/crates/mod_identity/src/identity_put.rs

In meta_merge after other defaults:

```rust
if out.get("active").is_none() {
    out["active"] = json!(true);
}
```

---

## Track 3 - Client store

**Files:** clients/app/lib/c/bot/bot_meta.dart (new), clients/app/lib/c/bot/bot_store.dart

- botActiveFromMetaJson(metaJson) -> bool default true
- botActivePut(botId, active) -> identityPut merged meta

---

## Track 4 - Wizard

**Files:** clients/app/lib/widgets/bots/in_bot_create.dart, bot_store.dart

- _botMetaJson: active false until finish
- _finish: active true
- Remove _cleanupDraft from _cancel and dispose
- After step 1 identityPut: widget.store.refreshBots() (+ optional botSelect)
- Snackbar on cancel: botCreate.savedDraftHint

---

## Track 5 - UI

**Files:** ui_bot_peer_list.dart (header Switch), ui_bot_nav_list.dart (Off pill), en.json, id.json

Keys: bots.activeLabel, bots.activeHint, bots.statusOff, botCreate.savedDraftHint, botCreate.finishTurnOn (optional Finish label)

---

## Track 6 - Verification

Manual:

1. Next on step 1 - bot in nav before Finish
2. Channel connected, active false - no AI reply
3. Finish - replies resume
4. Toggle off - no replies
5. Close wizard mid-flow - bot and channels remain
6. Delete bot still works

Automated: cargo build -p server_ai; dart analyze touched files.

---

## Execution (subagents)

Wave 1: Tracks 0, 1, 2 in parallel.
Wave 2: Tracks 3, 4.
Wave 3: Track 5.
Wave 4: Track 6 + publish_server.ps1.

Suggested commits: (1) channel gate (2) wizard persist (3) UI toggle.
