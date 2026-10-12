# Site AI — editor, channels, guest chat/call — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks and does not implement all lanes inline. Subagent **model: inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship **Site → AI** as the owner hub for (1) **Knowledge** facts, (2) **Channels** (site-scoped messaging like Bots, via one assistant bot per site), (3) **guest web chat + live call** on published sites (dual renderer), with cart-aware FAB placement and billing on the **site owner** (same model as bots borrowing owner pools).

**Architecture:** **Knowledge** stays in draft `meta.knowledge[]` + `meta.ai_assistant` (web toggles/copy). **Channels** are not a second channel stack — each site gets **`assistant_bot_iid`** (`kind=bot`, `meta.parent_site_iid`) reusing `mod_channel` + Bots channel connect UI. **Guest web** chat/call is a **guest surface** (HTTP/SSE or WS), not a row in Channels; context = published site + knowledge + optional cart session. **Flutter preview is canonical** for guest chrome; web matches per `site-guest-dual-renderer-parity.mdc`.

**Tech stack:** Flutter `widgets/sites/editor/ui_site_ai_editor.dart`, `guest_site/*`, Bots channel widgets (`widgets/bots/io_channel_*`); Rust `mod_site` (`site_boot.rs`, `render.rs`), new `mod_site` guest assistant routes or `wire_http` guest module; `mod_chat` guest turn pipeline; `mod_channel` unchanged wire; protos `site.proto` + new guest assistant messages; static `clients/web/static/site-guest/site-guest.v1.js`.

**Specs (read first, revise in Wave 0):** [`spec.md`](../../spec.md) · [`_/specs/site.md`](../site.md) · [`_/specs/site-ai.md`](../site-ai.md) · [`_/specs/channels.md`](../channels.md) · [`_/specs/chat.md`](../chat.md) · [`_/specs/live-call.md`](../live-call.md) · [`_/specs/billing-plans.md`](../billing-plans.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md)

**Related plans:** [`2026-10-11-site-preview-web-renderer-parity-multitask.md`](2026-10-11-site-preview-web-renderer-parity-multitask.md) · [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) (cart bar / `Pesan` — FAB must respect commerce chrome)

**Reference (behavior port, not architecture):** `D:\csa_site_published` guest chat bubble + cart tools + call UI.

---

## Global constraints

- **Dual renderer:** Any guest FAB, chat sheet, or call overlay change in `guest_site/**` ships with `render.rs` + `site-guest.v1.js` + `site-guest-components.md` in the **same PR**.
- **No provider web grounding** on LLM/live paths (`web-grounding-cluster-only.mdc`); guest assistant uses cluster `web.search` only via normal tool catalog if ever enabled for site scope.
- **Guest web chat/call ≠ Channels list row** — Channels = Telegram / WhatsApp / … only.
- **Billing:** No `site` plan SKU in v1. Charge **`site.config.owner_iid`** user pools (and optional **`assistant_bot_iid`** bot subscription if owner buys `bot.*` on that bot). Document in `billing.md` / `site.md`.
- **RBAC:** Site AI editor requires site staff grant (same as draft edit). Guest endpoints are **public** with rate limit + captcha where required (`captcha` plans).
- **Publish:** Knowledge + `ai_assistant` must appear in **published** boot JSON, not draft-only.
- UTF-8 sources; verify per [`verify-after-edit.mdc`](../../.cursor/rules/verify-after-edit.mdc). After server/static: `publish_server.ps1` + **site publish** for live URLs.

---

## Locked decisions (Wave 0 → specs)

| Topic | Decision |
|-------|----------|
| **Editor list layout** | One scroll: section header **Knowledge**, rows, section header **Channels**, rows; footer cards **AI Chat** / **AI Call** (unchanged role). |
| **`+` control** | Split menu: **Add knowledge** \| **Connect channel** (no single-purpose `+` only). |
| **AI Chat/Call cards** | Remove **Manage** link; tap card body → settings pane; **toggle only** toggles on/off (toggle outside ink target). |
| **Assistant bot** | `site.config.assistant_bot_iid` (BIGINT FK, migration) OR `capabilities_json.assistant_bot_iid` until migration — **prefer column** in Wave 2. Bot `meta_json`: `{ "parent_site_iid": <site>, "source": "site_assistant" }`. Auto-create inactive bot on first **Connect channel** or explicit **Enable channels** if none. |
| **Knowledge in prompts** | On guest + channel turns: inject `[SITE KNOWLEDGE]` from **published** meta (cap N facts / chars). Draft preview uses draft meta. |
| **Guest chat tools** | v1: `site.guest.cart.get`, `site.guest.cart.patch` (server-side session keyed by `visitor_id` + `site_iid`) mirroring CSA cart semantics; optional bridge to client cart state via boot token. Commerce: `site.tx.preview` / guest order tools only if `capabilities.commerce`. |
| **Guest call** | Reuse **Live** stack with `scope=site_guest`, `site_iid`, owner billing; UI = speakerphone + timer + end (no Home inbox). |
| **FAB placement** | Default: bottom-right stack (chat above call). When sticky cart bar visible: chat icon **left of `Pesan`**, outside dark bar; call stays bottom-right or stacks above chat — match Flutter first, port to JS. |
| **Search** | Single search filters **knowledge titles/content only** in v1; channel filter deferred (optional chip). |

---

## Gap analysis

| Area | c35 today | Target |
|------|-----------|--------|
| Site AI editor | Knowledge list + footer cards with **Manage**; whole-row ink includes toggle | Section headers; split `+`; card tap UX |
| Channels on site | None | List connected channels for `assistant_bot_iid`; connect flows reused from Bots |
| Assistant bot link | None | `site.config` + ensure/create bot |
| Guest boot | No `ai_assistant` / knowledge | `site_boot.rs` + publish doc merge |
| Guest chat UI | None in `guest_site` / JS | FAB + panel + streaming |
| Guest call UI | None | FAB + live session overlay |
| Guest API | No guest prompt/live | New HTTP routes + rate limits |
| `inst` / tools | Home `@site` only | Guest-scoped inst or dedicated `inst.site.guest.*` rows |
| Billing trace | N/A | `owner_iid` on guest turns |

---

## File map

| File / area | Responsibility |
|-------------|----------------|
| `_/schemas/migrations/site_assistant_bot_v1.sql` | `site.config.assistant_bot_iid` nullable FK → `ai.identity` |
| `_/schemas/proto/c35/site.proto` | `SiteConfig` field; guest assistant RPC messages (chat turn, live token) |
| `servers/crates/mod_site/src/site_assistant.rs` *(new)* | Ensure bot, load channels summary, published knowledge slice |
| `servers/crates/mod_site/src/site_boot.rs` | `ai_assistant`, `knowledge_public`, `assistant` flags |
| `servers/crates/mod_chat/src/site_guest_turn.rs` *(new)* | Guest prompt pipeline: fixed `site_iid`, knowledge inject, cart tools |
| `servers/crates/wire_http/src/site_guest_assistant.rs` *(new)* | Public routes: chat SSE, live setup, captcha gate |
| `clients/app/lib/widgets/sites/editor/ui_site_ai_editor.dart` | Headers, split `+`, card UX, channels section |
| `clients/app/lib/widgets/sites/editor/ui_site_ai_channels.dart` *(new)* | Channel list + navigate to shared connect sheets |
| `clients/app/lib/guest_site/guest_site_assistant.dart` *(new)* | FAB, chat panel, call overlay |
| `clients/app/lib/guest_site/guest_site_view.dart` | Host assistant layer + cart inset |
| `clients/web/static/site-guest/site-guest.v1.js` | `c35GuestAssistant` chat/call + cart bar positioning |
| `servers/crates/mod_site/src/render.rs` | Optional assistant chrome hooks / data attributes |
| `_/schemas/inst.sql` | `inst.site.guest.chat` (+ commerce phrases) |
| `_/specs/site.md` | Guest assistant + assistant bot sections |

---

## Wave map

```
WAVE 0  S0   Spec lock + proto sketch (no behavior)

WAVE 1  (parallel — editor only, shippable alone)
  E1   Knowledge/Channels headers + split + menu
  E2   AI Chat/Call card tap vs toggle isolation
  E3   Widget tests: site AI editor interactions

WAVE 2  (parallel — assistant bot backend)
  B1   Migration + SiteConfig sync field
  B2   site_assistant_ensure_bot(site_iid) + meta.parent_site_iid
  B3   API: site assistant get (bot_iid, channel summaries) for editor
  B4   Tests: ensure idempotent, grant owner

WAVE 3  (parallel — channels UI on site)
  C1   ui_site_ai_channels: list from assistant bot meta.channels[]
  C2   Reuse io_channel_* connect; write back identity meta via IdentityApi
  C3   Empty state + channel row (platform icon, status, tap → manage/disconnect)
  C4   Hide Channels section header when owner lacks channel capability? (always show; connect may fail with friendly error)

WAVE 4  (parallel — boot + publish)
  P1   Merge published knowledge + ai_assistant into boot JSON
  P2   Flutter GuestSiteBoot parse fields
  P3   Tests: fixture JSON round-trip (Rust + Dart)

WAVE 5  (parallel — guest chat server)
  G1   visitor_id cookie/header contract (align commerce member area if shipped)
  G2   POST /v1/site/guest-assistant/chat (stream) + captcha/rate limit
  G3   site_guest_turn: knowledge block, commerce tools, billing owner_iid
  G4   inst.site.guest.chat seed + prompt_compose tests (owner 33000, site fixture)
  G5   Integration test: cart patch tool updates session

WAVE 6  (parallel — guest live call server)
  L1   POST /v1/site/guest-assistant/live/setup (ephemeral token, site scope)
  L2   Wire to mod_live with owner billing + site knowledge inject
  L3   Feature flag: require ai_assistant.call_enabled in boot

WAVE 7  (parallel — dual renderer UI)
  U1   guest_site_assistant.dart: chat panel (reuse home chat widgets where possible)
  U2   Call overlay: timer, speaker, end
  U3   FAB layout rules vs GuestSiteCart bar
  U4   site-guest.v1.js parity + build.ps1
  U5   flutter test guest_site_view_test + manual E2E script

WAVE 8  (ship)
  V1   cargo test mod_site mod_chat (touched crates)
  V2   check_no_provider_grounding.ps1 -Changed
  V3   verify_flutter_app.ps1
  V4   publish_server + publish one test site (99000 gucicha)
  V5   Docs: _/docs/en/sites/ai.md (prompt + ui tag `both`)
```

---

## Wave 0 — Spec lock

- [ ] **S0.1** Add **Site guest assistant** section to [`_/specs/site.md`](../site.md): assistant bot, knowledge publish, web chat/call surfaces, billing owner, link this plan.
- [ ] **S0.2** Add **Site editor AI** subsection: Knowledge vs Channels headers; web chat/call cards; not in Channels list.
- [ ] **S0.3** Add short **Guest turn** note to [`_/specs/site-ai.md`](../site-ai.md) (read-only for Home `@site`; separate guest pipeline).
- [ ] **S0.4** [`_/specs/billing.md`](../billing.md): guest site AI usage bills `site.config.owner_iid`; optional bot plan on `assistant_bot_iid`.
- [ ] **S0.5** Sketch proto messages in [`_/schemas/proto/c35/site.proto`](../../schemas/proto/c35/site.proto) (`ReqSiteAssistantGet`, `ReqSiteGuestAssistantChat`, `ResSiteGuestAssistantChat` stream TBD in wire.proto).
- [ ] **S0.6** Row in [`_/specs/site-guest-components.md`](../site-guest-components.md): `data-guest-assistant`, boot keys `ai_assistant`, `knowledge_preview`.

---

## Wave 1 — Site editor UX

**Track E1 — List structure**

- [ ] **E1.1** Replace flat knowledge-only toolbar with: search (knowledge only) + `PopupMenuButton` / split `+`: **Add knowledge**, **Connect channel**.
- [ ] **E1.2** Insert `UiSiteEditorSectionHeader(title: 'Knowledge')` above knowledge list.
- [ ] **E1.3** Insert `UiSiteEditorSectionHeader(title: 'Channels')` above channel list (widget from Wave 3 can be placeholder `SizedBox` until C1 lands).
- [ ] **E1.4** Empty knowledge copy: “No knowledge yet” under Knowledge header only; channels empty: “No channels yet” + CTA “Connect channel”.

**Track E2 — Footer cards**

- [ ] **E2.1** `_AiFeatureRow`: remove `Manage` + chevron; wrap icon+text in `InkWell`/`GestureDetector`; place `UiSiteCatalogActiveSwitch` in separate `Listener`/`GestureDetector` with `onTap` absorbing navigation.
- [ ] **E2.2** Confirm toggle does not trigger `onOpenSettings` (widget test).

**Track E3 — Tests**

- [ ] **E3.1** `clients/app/test/ui_site_ai_editor_test.dart`: pump editor with mock API; tap card → pane change; tap toggle → no pane change.

**Verify:** `.\_\scripts\dev\verify_flutter_app.ps1`

---

## Wave 2 — Assistant bot (server)

- [ ] **B2.1** Migration `site_assistant_bot_v1.sql`: `assistant_bot_iid BIGINT NULL REFERENCES ai.identity(id)`.
- [ ] **B2.2** Proto + sync: `SiteConfig.assistant_bot_iid`; regenerate Dart/Rust wire.
- [ ] **B2.3** `site_assistant_ensure_bot(pool, site_iid, owner_iid)`: if null, create `kind=bot`, `type=chat`, name `{site name} AI`, `meta.active=false`, `meta.parent_site_iid`, set config column.
- [ ] **B2.4** `ReqSiteAssistantGet` → `{ assistant_bot_iid, channels: [...] }` parsed from bot meta (read-only for editor).
- [ ] **B2.5** Test: double ensure returns same iid; deleted bot recreates.

**Verify:** `cd servers; cargo test -p c35_mod_site site_assistant`

---

## Wave 3 — Channels section (app)

- [ ] **C3.1** `ui_site_ai_channels.dart`: `ListView` of `botChannelsParse(meta)` for assistant bot; load bot via `IdentityApi` + `SiteApi` config.
- [ ] **C3.2** **Connect channel** from E1 menu → `site_assistant_ensure_bot` then open same flow as Bots page (`ioChannelTelegramConnectShow`, WhatsApp pair, etc.) with `botIid = assistant_bot_iid`.
- [ ] **C3.3** Row tap → channel detail / disconnect (reuse `io_channel_pick_grid` patterns).
- [ ] **C3.4** Bots nav: optional badge “Site” on bots that have `parent_site_iid` (nice-to-have; can defer).

**Verify:** manual connect on staging bot; flutter analyze clean.

---

## Wave 4 — Boot contract

- [ ] **P4.1** `site_boot_build`: include `ai_assistant` object, `knowledge[]` (title+content, cap 50 items / 32k chars total).
- [ ] **P4.2** `guest_site_boot.dart`: parse `chatEnabled`, `callEnabled`, intros, placeholders.
- [ ] **P4.3** `guest_design_test.rs` + `guest_site_design_test.dart`: fixture with `ai_assistant` + one knowledge row.

---

## Wave 5 — Guest chat (server + inst)

- [ ] **G5.1** Rate limit key: `(site_iid, visitor_id, ip)`; optional captcha after N turns/day.
- [ ] **G5.2** Implement `site_guest_turn` modeled on `prompt_turn` but: fixed mention `site_iid`, no Home inbox persist (optional `ai.chat` row kind `site_guest` for staff transcript — **locked: store staff-visible log in `ai.log` only v1**).
- [ ] **G5.3** Tools: cart get/patch; `site.product` read via boot/catalog; no cross-site.
- [ ] **G5.4** Seed `inst.site.guest.chat` with commerce phrases; `prompt_compose` / `prompt_run` with site fixture **33000**.
- [ ] **G5.5** HTTP handler CORS: guest origins `alienai.id` + custom domains.

**Verify:** `.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed`; `cargo test -p c35_mod_chat` guest tests.

---

## Wave 6 — Guest live call (server)

- [ ] **L6.1** Guest live setup endpoint; reject when `call_enabled` false in published meta.
- [ ] **L6.2** Reuse live-call audio path; inject same knowledge block as chat.
- [ ] **L6.3** Billing: attribute usage to `owner_iid` with `scope=site_guest` in usage meta.

**Verify:** manual call on preview against dev server; log tail `ai.log`.

---

## Wave 7 — Dual renderer UI

- [ ] **U7.1** `GuestSiteAssistantHost`: reads boot; if `chat_enabled` show chat FAB; if `call_enabled` show call FAB.
- [ ] **U7.2** Chat panel: bottom sheet or side panel; stream from guest chat API; show tool traces only in dev.
- [ ] **U7.3** When `GuestSiteCart` sticky bar visible, position chat control adjacent to **Pesan** (Row in cart chrome — Flutter); mirror in JS `c35GuestCart` bar DOM.
- [ ] **U7.4** Call UI: full-screen or bottom sheet with elapsed timer, end button, loudspeaker default.
- [ ] **U7.5** `guest_site_view_test.dart`: boot with chat on → finds FAB; cart nonempty → chat not overlapping Pesan (golden or pump layout).

**Verify:** `clients/web/static/site-guest/build.ps1`; `cargo test -p mod_site guest_design`; flutter guest tests.

---

## Wave 8 — Ship checklist

- [ ] **V8.1** All waves merged; specs updated.
- [ ] **V8.2** User guide `_/docs/en/sites/ai.md` + `id/` counterpart (`docs-guides.mdc`).
- [ ] **V8.3** `publish_server.ps1` — **Publish summary** in PR.
- [ ] **V8.4** Republish **Gucicha** (or 99000 commerce site); screenshot parity app preview vs `alienai.id`.

---

## Manual E2E script (owner 99000)

1. Sites → Gucicha → AI: add knowledge row; enable AI Chat; connect WhatsApp channel (assistant bot).
2. Publish site.
3. Open guest URL: confirm chat FAB; ask product price; add to cart via chat tool; confirm cart bar updates.
4. Enable AI Call; start call; confirm timer + end; check `ai.log` billing row on owner.
5. Toggle chat off in draft → publish → FAB hidden.

---

## Deferred (explicit non-goals v1)

- Site-scoped billing SKU (`site.plan.*`).
- Instagram / LINE channels beyond existing Bots providers.
- Guest login / cross-device chat history (tie to member area Wave 8 commerce plan).
- Staff replying inside guest thread from Home inbox.
- Web channel as a Channels row (web stays **AI Chat** card only).

---

## Subagent dispatch (suggested)

| Wave | Parallel tracks |
|------|-----------------|
| 1 | E1, E2, E3 |
| 2 | B1–B5 single track or B2+B4 parallel |
| 3 | C1–C3 |
| 4 | P1–P3 |
| 5 | G2+G3 vs G4+G5 |
| 6 | L1–L3 |
| 7 | U1–U2 (Flutter) vs U4 (JS) after P4 |
| 8 | V docs vs V publish |

Parent merges only after each track’s verify block passes.
