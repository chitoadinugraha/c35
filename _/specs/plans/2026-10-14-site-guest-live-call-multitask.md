# Site guest Live Call — multitask plan

> **For agentic workers:** Use `plan-execution.mdc` — dispatch one `Task` subagent per track; **model: inherit** only. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace the **placeholder** guest call overlay (timer only) with a **real duplex voice** session on published and **draft** storefronts (using product/knowledge/cart context, billed to site owner), and **harden Flutter Web live call audio** against browser background tab throttling and GC jitter.

**Architecture:** Add **`POST /v1/site/guest-assistant/live/setup`** (public HTTP, like guest chat). Setup validates `site_iid`, `visitor_id`, `call_enabled`, published vs `boot_mode: draft`, rate-limits, holds billing on **`site.config.owner_iid`**, registers a **guest-scoped** Live ticket (`scope=site_guest`). WebSocket uses existing **`/v1/live/ws`** with a **guest ticket path** (no logged-in user JWT). Live setup builds system prompt from shared **`site_guest_context`** (knowledge + `[SITE PRODUCTS]` + site inst/tools) — same rules as `site_guest_turn.rs`. Flutter and web guest UIs call setup on **Start call**, then run mic/audio via a thin wrapper around **`LiveCallSession`** (app) or a **ported minimal live client** (static JS). Additionally, harden `LivePcmPlayoutWeb` with 60–100ms lookahead queueing to survive 1Hz background tab throttling.

**Tech stack:** Rust `wire_http`, `mod_live`, `mod_chat` (`site_guest_*`), `mod_billing`; protos `site.proto` (+ optional `live.proto` claim fields); Flutter `guest_site/*`, `c/live/live_call_session.dart`, `c/live/live_pcm_playout_web.dart`; static `clients/web/static/site-guest/site-guest.v1.js`.

**Related:** [`2026-10-12-site-ai-guest-assistant-multitask.md`](2026-10-12-site-ai-guest-assistant-multitask.md) (Wave 6 stub) · [`live-call.md`](../live-call.md) · [`site-guest-components.md`](../site-guest-components.md) · guest chat draft fix (`boot_mode`, `site_guest_product_prompt_block`).

**Reference (UX only):** `D:\csa_site_published` guest call FAB + speakerphone chrome — not Alpine architecture.

## Global constraints

- Read [`spec.md`](../../spec.md), [`live-call.md`](../live-call.md), [`site-guest-components.md`](../site-guest-components.md), [`site-ai.md`](../site-ai.md) before coding.
- **Dual renderer:** Flutter `guest_site/**` + `site-guest.v1.js` + `site-guest-components.md` in the **same PR** per track that touches call UI.
- **No provider web grounding** on Live (`web-grounding-cluster-only.mdc`); guest live tools = guest cart (+ `site.tx.preview` if commerce) only.
- **No Chromium STT** (`voice-no-chromium-stt.mdc`); uplink is Live/Gemini audio path only.
- **Billing:** `owner_iid` = site owner; `ai.log` / usage meta `scope: site_guest`, `site_iid`, `visitor_id`.
- **Draft preview:** `boot_mode: draft` on setup (parity with guest chat); unpublished sites allowed when draft.
- Verify: `cd servers; cargo build -p server_ai`; `cargo test -p c35_mod_live -p c35_mod_chat`; `.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed`; `.\_\scripts\dev\verify_flutter_app.ps1`; `clients/web/static/site-guest/build.ps1`.
- Subagent **model: inherit** only (`subagent-model.mdc`).

## Current gap (baseline)

| Layer | Chat | Call |
|-------|------|------|
| HTTP API | `POST /v1/site/guest-assistant/chat` | **Missing** |
| Server turn / Live | `site_guest_turn` | **No guest Live ticket / prompt** |
| WS auth | N/A | `/v1/live/ws` requires **user session JWT** — blocks anonymous guests |
| Flutter UI | `GuestSiteChatPanel` → API | Timer placeholder in `guest_site_assistant.dart` |
| Web UI | `c35GuestAssistant.sendChat` | `startCall()` placeholder copy |
| Flutter Web audio | N/A | 20ms timer throttled to 1Hz in background tab; 50 nodes/s GC pressure |

---

## Multitask map

```
WAVE 0   Spec + proto sketch (parallel)
WAVE 1   Shared guest context (Rust) — chat + live use one builder
WAVE 2   Guest Live setup HTTP + billing + rate limit
WAVE 3   Live ticket + WS guest auth + proxy prompt/tools
WAVE 4   inst.site.guest.call + live offer config
WAVE 5   Flutter guest call UI + Web playout background hardening
WAVE 6   Web guest call UI + build.ps1
WAVE 7   Tests + manual E2E + ship checklist
```

| Wave | Tracks | Depends |
|------|--------|---------|
| **0** | S0 spec rows, proto messages | — |
| **1** | R1 `site_guest_context` module | 0 |
| **2** | H1 HTTP setup handler | 1 |
| **3** | L1 ticket claims, L2 `live_ws` guest path, L3 `live_proxy` guest branch | 2 |
| **4** | I1 inst seed, I2 default `live` offer id env | 1 |
| **5** | F1 session wrapper, F2 overlay UX, F3 web audio background hardening | 3 |
| **6** | W1 JS live client, W2 replace placeholder strings | 3, 5 patterns |
| **7** | V1–V4 verify + docs | all |

**Parallel wave 1:** **0**  
**Parallel wave 2:** **1** + **4** (inst can start after 1’s scope constants)  
**Parallel wave 3:** **2**  
**Parallel wave 4:** **3**  
**Parallel wave 5:** **5** + **6** (after 3 lands)  
**Wave 6:** **7**

---

## Wave 0 — Spec lock

- [x] **S0.1** [`site-guest-components.md`](../site-guest-components.md): expand **Call** row — setup URL, `boot_mode`, WS shape, billing owner; remove “placeholder” wording when implemented.
- [x] **S0.2** [`live-call.md`](../live-call.md): new subsection **Guest storefront Live Call** — not `ReqLiveStart` on app WS; HTTP setup; anonymous `visitor_id`; contrast with Home Live Call.
- [x] **S0.3** [`site.md`](../site.md): guest assistant bullet for **voice call** (published + draft preview).
- [x] **S0.4** [`_/schemas/proto/c35/site.proto`](../../schemas/proto/c35/site.proto):

```protobuf
message ReqSiteGuestAssistantLiveSetup {
  int64 site_iid = 1;
  string visitor_id = 2;
  string boot_mode = 3;  // "published" | "draft"
  string locale = 4;
  string req_id = 5;
}
message ResSiteGuestAssistantLiveSetup {
  bool ok = 1;
  string error = 2;
  string req_id = 3;
  string live_session_id = 4;
  string ws_path = 5;   // full path+query for guest WS (includes guest ticket)
  int32 max_duration_sec = 6;  // optional cap hint for UI
}
```

- [x] **S0.5** Decide **live offer id** for guest (document in spec): e.g. catalog row `live.site-guest` or reuse `live.alienai` with `scope=site_guest` in claims — **one chosen default** + `C35_GUEST_LIVE_OFFER_ID` env override.

---

## Wave 1 — Shared guest context (Rust)

**Files:** `servers/crates/mod_chat/src/site_guest_context.rs` (new), refactor `site_guest_turn.rs` to call it.

- [x] **R1.1** Extract from `site_guest_turn`: `guest_site_row_load`, knowledge/products blocks, `GuestSiteDataMode`, `guest_chat_enabled` gate → `site_guest_context_prepare(pool, site_iid, data_mode) -> GuestSiteContext { site, owner_iid, meta, system_blocks, commerce, ... }`.
- [x] **R1.2** `site_guest_live_system_prompt(ctx, inst_block, time_block) -> String` — concatenates `[SITE CONTEXT]`, knowledge, products (if commerce), chat intro, inst.
- [x] **R1.3** `site_guest_tool_catalog` + compose inst for `role:site_guest` reused by live setup (same `inst.site.guest.chat` until **I1** adds call-specific inst).
- [x] **R1.4** Unit tests: draft vs published meta selection; product block present when commerce.

**Verify:** `cargo test -p c35_mod_chat site_guest`

---

## Wave 2 — HTTP live setup

**Files:** `servers/crates/wire_http/src/site_guest_assistant.rs`, `site_guest_live.rs` (new in `mod_chat` or `mod_live`).

- [x] **H2.1** Route `POST /v1/site/guest-assistant/live/setup` + OPTIONS CORS (same origins/headers as guest chat, include `authorization` for optional staff preview).
- [x] **H2.2** Body: `site_iid`, `visitor_id`, optional `boot_mode`, `locale`, `req_id`; validate non-empty visitor (header `x-visitor-id` fallback).
- [x] **H2.3** Rate limit: `(site_iid, visitor_id, ip)` — stricter than chat (e.g. **6/hour**, **2 concurrent** per visitor); return `429` + `Retry-After`.
- [x] **H2.4** Load context via **R1**; reject if `!call_enabled` in meta (`ai_assistant.call_enabled`).
- [x] **H2.5** `C35_LIVE_ENABLED` gate (same as `live_start_rpc`); friendly error if off.
- [x] **H2.6** Billing hold on **owner_iid** for chosen live offer (`live_billing_gate_*`); `req_id` = snowflake or client-supplied.
- [x] **H2.7** Register guest live session → return `ResSiteGuestAssistantLiveSetup` with `ws_path` (see Wave 3).

**Verify:** integration test with mock pool or `33000` fixture if available; manual `curl` on dev API.

---

## Wave 3 — Live session + WebSocket (guest)

**Files:** `mod_live/src/session.rs`, `wire_ws/src/live_ws.rs`, `mod_live/src/google.rs` (and openai/grok if guest must support all offers — **default: single offer family**), `mod_live/src/proxy.rs` or entry in `live_proxy_run`.

- [x] **L3.1** Extend `LiveTicketClaims` (or parallel `GuestLiveTicketClaims`) with:

  - `scope: "site_guest"`
  - `site_iid`, `visitor_id`
  - `data_mode: "draft" | "published"`
  - `guest_system_prompt` snapshot **or** ids to rebuild on connect (prefer **snapshot** capped ~32k chars for cross-pod)

- [x] **L3.2** `guest_live_session_register(...) -> (sid, token, ws_path)` — stores ticket in memory map; signs token; **no** `owner_session_prepare_for_live` (no Home L1 session).

- [x] **L3.3** **`live_ws_handler`:** if `jwt` query absent/invalid, attempt **guest** `live_guest_session_take(sid, token)` when token verifies `scope=site_guest`; do **not** require `auth_session_resolve`.

- [x] **L3.4** `LiveSessionTicket` extension: `guest: Option<GuestLiveMeta>` (site_iid, visitor_id, frozen tool catalog / mention context).

- [x] **L3.5** In `live_proxy_run` / provider setup: when `guest` set, use **guest system prompt** + **guest tool declarations** (cart get/patch, optional tx preview); `TurnCtx.run_kind = "site_guest_live"`; wire tool exec to same handlers as chat (`guest_visitor_id`, `site_iid` on ctx).

- [x] **L3.6** Usage reporting on session end: `scope: site_guest`, `kind: site_guest_live`, same owner billing as chat.

- [x] **L3.7** Session max duration env `C35_GUEST_LIVE_MAX_SEC` (default **900**); server closes WS with reason when exceeded.

**Verify:** `cargo test -p c35_mod_live`; manual WS connect with returned `ws_path` on dev; `log_tail` shows live + tool rows for owner **99000** test site.

---

## Wave 4 — Inst + catalog

- [x] **I4.1** Seed [`inst.sql`](../../schemas/inst.sql) `inst.site.guest.call` — `scope: role:site_guest`, `topic_id: site.guest`, phrases for voice (“call”, “telepon”, “bicara”, order/menu), body: short voice style + use cart tools for orders; `include_tools` same as chat; exclude web tools.
- [x] **I4.2** Live setup compose: match `inst.site.guest.call` + `inst.site.guest.chat` (or call-only if call inst supersedes).
- [x] **I4.3** `ai.live_offer` seed or config doc for guest offer id; document retail $/min for guest in [`billing.md`](../billing.md) one line.

**Verify:** `prompt_compose` MCP — phrase “berapa harga …” with guest scopes (fixture site **33000**).

---

## Wave 5 — Flutter UI

**Files:** `guest_site_assistant.dart`, new `guest_site_live_call.dart`, `c/site/guest_assistant_api.dart`, optional `guest_site_live_call_session.dart`.

- [x] **F5.1** `GuestAssistantApi.liveSetup(siteIid, visitorId, bootMode)` → parse `ws_path`, `live_session_id`, errors.
- [x] **F5.2** `GuestSiteLiveCallController`:
  - On **Start**: mic permission (`stt_mic_permission`), `unlockWebAudioPlayback()` when `kIsWeb`, POST setup, connect WebSocket using **guest ws_path** (extend `LiveCallSession.connectGuest(Uri)` or parse path from setup — **no** `ReqLiveStart`, **no** user JWT).
  - Reuse downlink jitter buffer, speaker toggle, captions optional (subtitle line under timer).
  - On **End**: hang up WS, dispose mic, show error snackbar on failure.

- [x] **F5.3** Replace placeholder overlay in `guest_site_assistant.dart`:
  - States: idle → connecting → active → error
  - Show `call_intro`, elapsed timer, **speaker** toggle, **mute**, **End call**
  - Remove “placeholder” copy

- [x] **F5.4** FAB: call button disabled while connecting; chat FAB unchanged; cart dock rules unchanged.

- [x] **F5.5** `boot_mode: draft` passed from `widget.boot.mode` (same as chat).

- [x] **F5.6** Widget tests: `call_enabled: true` → finds call FAB; tap start → mock API returns error still shows error UI (inject `http.Client` or stub at API layer if pattern exists).

- [x] **F5.7** **Flutter Web Live Audio Hardening** (`live_pcm_playout_web.dart` & `live_call_session.dart`):
  - Increase stream batch pump from 20ms to 60–100ms when running on web to reduce `AudioBufferSourceNode` creation by 60–80%.
  - Implement forward-scheduled lookahead queue (150–300ms) in Web Audio timeline so browser background-tab throttling (clamping `Timer.periodic` to 1000ms) does not starve audio playout while the user is multitasking across tabs.

**Verify:** `flutter test test/guest_site_view_test.dart test/live_call_session_test.dart`; manual draft preview on **99000** site with `call_enabled`.

---

## Wave 6 — Web guest UI

**Files:** `clients/web/static/site-guest/src/site-guest.v1.js`, `site-guest.v1.css`, `build.ps1`.

- [x] **W6.1** `assistantBootMode()` reuse for setup `boot_mode` (already used for chat).
- [x] **W6.2** `startCall()` flow:
  1. Mic permission (`getUserMedia` audio only)
  2. `POST .../live/setup` with `visitor_id`, `site_iid`, `boot_mode`
  3. Open WebSocket from `ws_path` (absolute URL: `assistantApiBase()` host + path)
  4. Binary audio framing: same `0xC3 0x35` + `LiveWsAudio` as app (document byte layout in comment; port minimal encoder/decoder from Dart or existing live web notes in [`2026-10-12-live-call-flutter-web-multitask.md`](2026-10-12-live-call-flutter-web-multitask.md))

- [x] **W6.3** UI: replace “live session placeholder” with connecting spinner, live indicator, end button; optional caption div.

- [x] **W6.4** Autoplay: unlock audio on **call FAB click** (same gesture chain as Live web plan).

- [x] **W6.5** Run `build.ps1`; commit both `src/` and minified `site-guest.v1.js`.

**Verify:** Published or `?draft=1` page on localhost guest host; one full call smoke in Chrome.

---

## Wave 7 — Tests, docs, ship

- [x] **V7.1** Rust: `guest_live_setup_rejects_call_disabled`, `guest_live_ticket_verify`, `guest_ws_take_without_jwt` (unit).
- [x] **V7.2** `check_no_provider_grounding.ps1 -Changed`
- [x] **V7.3** Optional user guide: `_/docs/en/sites/ai.md` / `id/` — tag `both`, one paragraph on voice call on storefront.
- [x] **V7.4** `publish_server.ps1` — **Publish summary** in PR/commit notes.
- [x] **V7.5** Manual E2E script (in plan artifact or comment):
  1. Enable **Call** in Site → AI, draft preview
  2. Ask price by voice → matches catalog
  3. “Tambah 1 … ke keranjang” → `site.guest.cart.patch` in `ai.log`
  4. Published URL same flow

---

## Follow-ups (out of scope for this plan)

- **Cart UI sync** after live tool patch (shared with chat — server cart vs `GuestSiteCartController`).
- **SSE streaming** for guest chat (HTTP JSON only today).
- **Guest Live on custom domains** — CORS already mirrors chat; verify per-domain smoke.
- **Channels** (WhatsApp/Telegram site bot) — separate from voice call.

---

## Risk notes

| Risk | Mitigation |
|------|------------|
| WS auth change breaks Home Live | Guest path only when ticket `scope=site_guest`; existing JWT path unchanged |
| Cross-pod guest ticket | Signed claims + billing `req_id` check (same as owner live) |
| Web audio fragility | Reuse Live web hardening doc; fail with clear “use Chrome / allow mic” |
| Prompt drift chat vs live | **Wave 1** single `site_guest_context` builder |

---

## Agent dispatch checklist

When executing, dispatch tracks **1 → 2 → 3** sequentially; **5** and **6** in parallel after **3**; **4** can overlap **2–3**. Each track ends with verify commands from **Global constraints**.
