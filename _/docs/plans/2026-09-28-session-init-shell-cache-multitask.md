# Session init shell cache (avatar menu + page zero) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the avatar menu and Home shell server-authoritative on connect with instant stale paint from local cache — one ReqSessionInit round trip, no extra balance HTTP on open, roles/email refreshed from profile.

**Architecture:** Extend IdentityProfile with email + global_roles. Add Flutter SessionInitCache (uid-scoped protobuf persist, same pattern as HintStore). On boot: restore cache, WS connect, sessionInit with since_ms watermark, merge, persist. Remove redundant billingSummaryGet on menu open. Realtime billing still via NATS (unchanged).

**Tech Stack:** Protobuf _/schemas/proto/c35/identity.proto, session.proto, Rust mod_identity, Flutter clients/app, SharedPreferences + base64 pb bytes.

## Global Constraints

- Read spec.md, _/docs/sync.md, _/docs/ui.md, _/docs/billing.md, _/docs/identity.md before coding.
- Do not put Speak / voice prefs in session init — stay VoicePrefs (device-local).
- Rule (locked): no separate balance/profile HTTP on app open (billing.md, sync.md).
- Proto regen: .\_\scripts\protoc.ps1; verify cd servers && cargo build -p server_ai and cd clients/app && flutter analyze.
- Server deploy after Rust wire changes: .\_\scripts\deploy\publish_server.ps1 (cluster buildkit, arm64).
- Do not commit unless user asks.

---

## File map (target)

| Path | Responsibility |
|------|----------------|
| _/schemas/proto/c35/identity.proto | email, global_roles on IdentityProfile |
| servers/crates/mod_identity/src/identity_profile_get.rs | Read roles + email from meta |
| clients/app/lib/c/session/session_init_cache.dart | New — restore / persist / sinceMs per uid |
| clients/app/lib/c/store/chat_store.dart | sessionInitMerge, since_ms on request, cache persist |
| clients/app/lib/pages/page_ai_home.dart | Boot: SessionInitCache.restore() before connect |
| clients/app/lib/widgets/ui/ui_account_menu.dart | No billingSummaryGet when init/cache suffices |
| clients/app/lib/c/auth/auth_service.dart | Sign-out: SessionInitCache.clearForUid |
| clients/app/test/session_init_cache_test.dart | Round-trip persist + restore |
| _/docs/sync.md | Client cache keys (implementation truth) |

---

## Multitask map

Parallel wave 1:
  Agent A → Track 1 (proto + protoc + compile smoke)
  Agent B → Track 4 (SessionInitCache + unit test)

Parallel wave 2 (after Track 1):
  Agent C → Track 2 (server profile: email + global_roles)
  Agent D → Track 3 (merge, boot, menu, since_ms, sign-out)

Wave 3: Agent E → Track 5 (docs + QA)
Wave 4: publish_server.ps1 (Track 6)

| Track | Delivers | Blocked by |
|-------|----------|------------|
| 1 | Proto + generated Rust/Dart | — |
| 2 | Server fills new profile fields | 1 |
| 3 | End-to-end client behavior | 1, 4 |
| 4 | SessionInitCache + test | — |
| 5 | Docs + QA | 2, 3 |
| 6 | Cluster rollout | 2, 3 |

---

## Track 1 — Proto + codegen

### Task 1.1: Extend IdentityProfile

Files: Modify _/schemas/proto/c35/identity.proto

Add fields 15 email (string), 16 global_roles (repeated string).

- [ ] Edit proto (comments: meta.email, meta.global_roles per identity.md).
- [ ] Run .\_\scripts\protoc.ps1.
- [ ] cd servers && cargo build -p server_ai.
- [ ] cd clients/app && flutter analyze.

---

## Track 2 — Server profile slice

### Task 2.1: identity_profile_get

Files: Modify servers/crates/mod_identity/src/identity_profile_get.rs

- email from meta.email
- global_roles from meta.global_roles JSON array
- If is_root and root not in list, append root
- cargo build -p server_ai; spot-check session init for finance user

---

## Track 4 — Client SessionInitCache

### Task 4.1: Module clients/app/lib/c/session/session_init_cache.dart

Keys: c35.session_init.since_ms.$uid, c35.session_init.pb.$uid (base64 ResSessionInit).

Restore: billing to AppStore; nav to ChatStore + mailInboxBus; profile to Session.identityMerge; optional models. Do not hydrate inbox from blob.

API: restore(), persist(init), sinceMs(), clearForUid(uid).

### Task 4.2: clients/app/test/session_init_cache_test.dart — flutter test

---

## Track 3 — Wire merge, boot, menu

- chat_store: pass sinceMs from cache; full profile merge; persist after merge
- page_ai_home: SessionInitCache.restore() before _connConnect
- ui_account_menu: drop menu-open billingSummaryGet (placeholder until init)
- auth sign-out: clear cache
- flutter analyze + manual cold-start menu test

---

## Track 5 — Docs + QA

- Update _/docs/sync.md cache table
- QA: badges, billing rings, nav, mail, speak local, sign-out clears cache

---

## Track 6 — Deploy

- publish_server.ps1 after Track 2; Publish summary c35-server

---

## Out of scope

- wallets[] billing v2, full inbox in blob, real settings_json, secure storage upgrade (SessionInitCache backend swap only)

---

## Agent dispatch

Wave 1: Tracks 1 + 4 parallel. Wave 2: Tracks 2 + 3. Wave 3: Track 5. Wave 4: Track 6 deploy.
