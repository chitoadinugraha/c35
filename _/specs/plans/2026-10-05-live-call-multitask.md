# Live Call (welcome chip + `live_offer` + Gemini Live) — Multitask Plan

> **For agentic workers:** Use `plan-execution.mdc` — dispatch one `Task` subagent per track below; **model: inherit** only. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Home welcome **Call** control with family-aware label, variant submenu, **~$/min** retail hint, and server-backed **`live_offer`** catalog — v1 ships **Gemini Live** for **Alien AI + Gemini + Gemini Thinker**; **ChatGPT / Grok** rows visible but disabled until their realtime backends exist.

**Architecture:** Separate **`ai.live_offer`** (not chat `ai.llm_model` sync). Composer **text** model only drives **primary button label** and **submenu scope**; backend always uses **`live_offer.provider_model`**. Session init returns `LiveCatalog`; Flutter renders `UiLiveCallChip` beside hint chips. Phase 2 adds **`mod_live`** WebSocket proxy to Google Live API (`gemini-3.8-live*`), billing per minute + turn context rules.

**Tech Stack:** YSQL (`_/schemas/`), protobuf (`live.proto`, `session.proto`), Rust (`mod_live`, `mod_billing`, `wire_ws`), Flutter (`page_ai_home`, prefs), Google Gemini Live API (WSS).

**Design locked (2026-10-05):**

| Composer family | Primary label | Submenu on click |
|-----------------|---------------|------------------|
| `alienai` / `auto` | **Call Alien AI** | Alien AI only (or full menu — v1: **Alien only**) |
| `google` (any Gemini slug) | **Call Gemini** | **Call Gemini** + **Call Gemini Thinker** |
| `openai` | **Call ChatGPT** | ChatGPT only (when enabled) |
| `xai` | **Call Grok** | Grok only (when enabled) |
| Other (Claude, DeepSeek, …) | **Live Call** | **All enabled** offers (Alien, Gemini, Thinker, ChatGPT, Grok) |

- **No** Live SKUs in main prompt model picker.
- **No** routing by `gemini*` prefix on chat ids; use **`live_offer.id`** + **`family`**.
- Flash-lite **alien chain** remains **text-only**; Live uses **`gemini-3.8-live`** / **`gemini-3.8-live-extended-thinking`** only.

## Global Constraints

- Read `spec.md`, `_/specs/chat.md`, `_/specs/billing.md`, `_/specs/ui.md` before coding.
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p mod_live` when crate exists; `.\_\scripts\dev\verify_flutter_app.ps1`; `check_utf8_sources.ps1 -Changed -Fix`.
- Proto/SQL changes: regenerate Dart pb, register schema in `servers/crates/store/src/schema.rs`.
- Subagent model: **inherit** (not `*-fast`).
- Do not commit unless user asks.
- Cluster: apply new schema + optional `ai.config` seeds; **server rollout** for Live proxy (Track C).
- Retail markup: **1.5×** wholesale (`RETAIL_MARKUP`) unless product marks Alien Live as included pool.

---

## Multitask map

```
Track 0 (Schema + proto)     ──► Track A + Track B
Track A (Server catalog)     ──► Track C
Track B (Flutter UI)         ──► Track D (E2E UX)
Track A + Track B            ──► Track D
Track C (Gemini Live proxy)  ──► Track D
Track E (ChatGPT/Grok)       ──► optional later
Track F (Docs + ops)         ──► after Track D
```

| Track | Focus | Depends |
|-------|--------|---------|
| **0** | `ai.live_offer`, `live.proto`, session init field, seeds | — |
| **A** | Rust load cache, `live_offers()`, billing constants, `live_start` stub RPC | 0 |
| **B** | `UiLiveCallChip`, persona mapping, prefs, hero layout, translations | 0 |
| **C** | Google Live WSS proxy, audio relay, settle billing | A |
| **D** | Wire `PageLiveCall`, permissions, connect flow, widget tests | B (+ C for real audio) |
| **E** | OpenAI Realtime / xAI adapters (enable rows) | C |
| **F** | `_/specs/live-call.md`, cluster migration note | D |

**Parallel wave 1:** Track **0** (single agent — gate for all)  
**Parallel wave 2:** Track **A** + Track **B**  
**Parallel wave 3:** Track **C** + Track **D** (UI shell can land before C; audio needs C)  
**Wave 4:** Track **F**; Track **E** when product asks  

---

## Track 0 — Schema, proto, session init

### Task 0.1: SQL `ai.live_offer`

**Files:**

- Create: `_/schemas/live_offer.sql`
- Modify: `servers/crates/store/src/schema.rs` (append to `SCHEMA_APPLY_ORDER` after `llm` / before or after `hint` — keep alphabetical doc in `_/schemas/README.md`)
- Create: `_/schemas/migrations/20261005_live_offer_v1.sql` (`\i ../live_offer.sql` for live clusters)

**Table (sketch):**

```sql
CREATE TABLE ai.live_offer (
    id                  TEXT PRIMARY KEY,       -- live.alienai, live.gemini, live.gemini.thinker, ...
    family              TEXT NOT NULL,          -- alienai | gemini | openai | xai
    label_key           TEXT NOT NULL,          -- i18n via translation.sql
    provider            TEXT NOT NULL,          -- google | openai | xai
    provider_model      TEXT NOT NULL,          -- gemini-3.8-live, ...
    inst_id             TEXT NOT NULL DEFAULT '',
    input_usd_per_min   DOUBLE PRECISION NOT NULL DEFAULT 0,
    output_usd_per_min  DOUBLE PRECISION NOT NULL DEFAULT 0,
    enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    sort                INT NOT NULL DEFAULT 0,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);
```

**Seeds (wholesale $/min — tune from [Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing)):**

| id | family | provider_model | enabled v1 | inst_id |
|----|--------|----------------|------------|---------|
| `live.alienai` | alienai | `gemini-3.8-live` | yes | Alien persona inst (e.g. general topic chain or dedicated `inst.live.alienai`) |
| `live.gemini` | gemini | `gemini-3.8-live` | yes | lighter Gemini / empty |
| `live.gemini.thinker` | gemini | `gemini-3.8-live-extended-thinking` | yes | — |
| `live.chatgpt` | openai | TBD OpenAI realtime id | **false** | — |
| `live.grok` | xai | TBD | **false** | — |

- [ ] Table + seeds + README row.
- [ ] Migration file for manual cluster apply.

### Task 0.2: Proto `live.proto` + session

**Files:**

- Create: `_/schemas/proto/c35/live.proto`
- Modify: `_/schemas/proto/c35/session.proto` — `import "c35/live.proto";` + `LiveCatalog live = 14;` on `ResSessionInit`
- Modify: `_/schemas/proto/c35/wire.proto` — `ReqLiveStart` / `ResLiveStart` / optional `LiveSessionPush` on app WS (field numbers per next free slot)
- Regenerate: `clients/app/lib/c/pb/**` (repo script / `protoc` flow used elsewhere)

**Messages:**

```protobuf
message LiveOffer {
  string id = 1;
  string family = 2;           // alienai | gemini | openai | xai
  string label = 3;            // server-resolved EN; client uses label_key + catalogT
  string label_key = 4;
  string provider = 5;
  bool enabled = 6;
  double retail_usd_per_min = 7;  // server-computed display (in+out wholesale * markup blended)
  double input_usd_per_min = 8;   // optional detail
  double output_usd_per_min = 9;
}

message LiveCatalog {
  int64 updated_ts_ms = 1;
  repeated LiveOffer offers = 2;
}

message ReqLiveStart {
  string offer_id = 1;         // live.gemini.thinker
  string locale = 2;
  string req_id = 3;
}

message ResLiveStart {
  string error = 1;
  string live_session_id = 2;
  string ws_path = 3;          // e.g. /v1/live/ws?token=...
  // or ephemeral token fields if client connects directly with server-minted secret
}
```

- [ ] Proto merged; Dart + Rust build clean.

### Task 0.3: Translations

**Files:**

- Modify: `_/schemas/translation.sql` — keys `live.alienai.label`, `live.gemini.label`, `live.gemini.thinker.label`, `live.chatgpt.label`, `live.grok.label`, `home.liveCall`, `home.liveCallPricePerMin`, `live.soon`
- Modify: `clients/app/lib/c/catalog/catalog_translation_cache.dart` — mirror EN/ID
- Modify: `clients/app/assets/translations/en.json`, `id.json` if still used for home strings

- [ ] ID copy: **Panggil Alien AI**, **Panggil Gemini**, **Panggil Gemini Thinker**, **Panggil ChatGPT**, **Panggil Grok**, **Panggilan Live**.

---

## Track A — Server catalog + stub start

### Task A.1: Crate `mod_live` (catalog)

**Files:**

- Create: `servers/crates/mod_live/Cargo.toml`, `src/lib.rs`, `src/live_offer.rs`, `src/live_catalog.rs`
- Modify: `servers/Cargo.toml` workspace + `server_ai` deps
- Modify: `servers/crates/wire_ws/src/session.rs` — after `prompt_models()`, set `res.live = live_catalog_get(&pool).await?`

**Interfaces:**

- `live_catalog_reload(pool) -> Result<()>`
- `live_offers_enabled() -> Vec<LiveOfferRow>` (in-memory cache like `llm_catalog`)
- `live_offer_get(id) -> Option<LiveOfferRow>`
- `live_retail_usd_per_min(row) -> f64` — `(input_usd_per_min + output_usd_per_min) * RETAIL_MARKUP` or documented blend

- [ ] `cargo build -p server_ai`
- [ ] Session init returns non-empty `live.offers` in dev.

### Task A.2: Billing holds (stub)

**Files:**

- Modify: `servers/crates/mod_billing/src/billing_cost.rs` — `LIVE_CALL_HOLD_USD`, default minute estimates from `live_offer`
- Create: `servers/crates/mod_live/src/billing.rs` — gate/settle/abort pattern mirroring `mod_voice`

- [ ] `live_start` without proxy still runs billing gate + immediate abort with friendly error if Live disabled (`C35_LIVE_ENABLED=0` default until Track C).

### Task A.3: RPC `live_start` stub

**Files:**

- Modify: `servers/crates/wire_ws/src/...` — handle `ReqLiveStart`
- Return error `"Live call is not available yet"` or success with `ws_path` only when `C35_LIVE_ENABLED=1`

- [ ] Flutter can invoke RPC without crash.

---

## Track B — Flutter welcome Call chip

### Task B.1: Model + store

**Files:**

- Create: `clients/app/lib/c/live/live_offer.dart` — `LiveOffer` from proto, `liveOfferLabel()`, `liveRetailPerMinLabel()`
- Create: `clients/app/lib/c/live/live_call_ui.dart` — **`liveCallPrimaryLabel(AgentModel m)`**, **`liveCallMenuOffers(List<LiveOffer> all, AgentModel m)`** implementing locked submenu rules
- Create: `clients/app/lib/c/settings/live_call_prefs.dart` — `live_offer_last`, `live_persona_last`
- Modify: `clients/app/lib/c/store/chat_store.dart` — `List<LiveOffer> liveOffers = []`, merge from `sessionInitMerge` / cache

- [ ] Unit tests: `clients/app/test/live_call_ui_test.dart` — matrix for alienai / google / openai / xai / claude composer × expected primary + menu ids.

### Task B.2: Widget `UiLiveCallChip`

**Files:**

- Create: `clients/app/lib/widgets/ai/ui_live_call_chip.dart`

**Behavior:**

- Props: `AgentModel composerModel`, `List<LiveOffer> offers`, `VoidCallback? onStart(String offerId)`, `bool loading`
- Primary: family label + **`· ~$X/min`** from cheapest enabled offer in **menu scope** (or selected default offer)
- Trailing ▾ when menu has **>1** row; else single tap starts default offer for family
- Menu: `PopupMenuButton` / `MenuAnchor` — disabled rows show `(Soon)` / `live.soon`
- Style: match `UiHints` chip (`_chipBg`, border) — visually sibling to consumption chip

- [ ] Widget test: Gemini composer → menu length 2; Claude → primary "Live Call" → menu all enabled.

### Task B.3: Hero layout

**Files:**

- Modify: `clients/app/lib/pages/page_ai_home.dart` — `_threadHero()`:

```dart
Wrap(
  alignment: WrapAlignment.center,
  spacing: 8,
  runSpacing: 8,
  children: [
    UiLiveCallChip(...),
    UiHints(...),
  ],
)
```

- `_liveCallStart(offerId)` → `Navigator.push` `PageLiveCall(offerId: ...)`

- [ ] Empty chat shows **Call** left of consumption hint (visual check).

### Task B.4: `PageLiveCall` shell (pre-audio)

**Files:**

- Create: `clients/app/lib/pages/page_live_call.dart`

- Offer title, price/min, **Connect** button → `ReqLiveStart`
- Show server error / "Coming soon" when stub
- Mic permission placeholder

- [ ] Navigate from chip; back pops to home.

---

## Track C — Gemini Live proxy (v1 audio)

### Task C.1: WebSocket route

**Files:**

- Create: `servers/crates/mod_live/src/session.rs`, `src/google_live.rs`
- Modify: `server_ai` axum/ws router — authenticated upgrade, map `live_session_id` → owner, offer, inst-composed system instruction

**Flow:**

1. Client `ReqLiveStart(offer_id)` → billing gate → create `ai.live_session` row (optional) or in-memory registry → return short-lived token
2. Client WSS → server proxies to `wss://generativeai.googleapis.com/.../BidiGenerateContent` (or SDK-equivalent)
3. PCM 16k uplink / 24k downlink; optional transcript events on `LiveSessionPush`

**Env:** `GOOGLE_API_KEY` / existing Google keys; `C35_LIVE_ENABLED=1`

- [ ] Manual smoke: 30s call, row in `ai.log` with `sku: live_audio`.

### Task C.2: SQL session table (optional but recommended)

**Files:**

- Extend `_/schemas/live_offer.sql` or add `live_session.sql` — `owner_iid`, `offer_id`, `req_id`, `started_ts`, `ended_ts`, `cost_usd`

- [ ] Supports debugging + future reconnect.

### Task C.3: Flutter audio loop

**Files:**

- Create: `clients/app/lib/c/live/live_call_session.dart` — WSS client, `record` stream uplink, `audioplayers` or native buffer downlink
- Modify: `page_live_call.dart` — wire session

- [ ] Android smoke first; document Windows/macOS gaps if any.

### Task C.4: Context + cost controls

- [ ] Server sets `contextWindowCompression` defaults per Google best practices.
- [ ] Cap max session duration (config) + user-visible end reason.

---

## Track D — Integration & acceptance

### Task D.1: Session init cache

**Files:**

- Modify: `clients/app/lib/c/session/session_init_cache.dart` — persist `live` catalog

- [ ] Offline: empty offers → chip hidden or disabled with copy.

### Task D.2: Freemium / billing gate

- [ ] If freemium hides paid models, Live chip respects same policy (mirror `agentModelsForBilling` pattern).

### Task D.3: Acceptance checklist

- [ ] Composer **Gemini** → **Call Gemini · ~$/min** → menu **2** rows only.
- [ ] Composer **ChatGPT** → **Call ChatGPT** (disabled → Soon).
- [ ] Composer **Claude** → **Live Call** → menu shows all **enabled** offers.
- [ ] Prompt picker **never** lists `*live*`.
- [ ] `cargo build -p server_ai`; `verify_flutter_app.ps1`; widget tests pass.

---

## Track E — ChatGPT / Grok (deferred)

- [ ] Enable `live.chatgpt` / `live.grok` rows when OpenAI Realtime + xAI endpoints exist.
- [ ] Separate adapter modules — **do not** route through Gemini Live.
- [ ] Same `UiLiveCallChip`; only `enabled` flips + submenu single row.

---

## Track F — Docs & ops

**Files:**

- Create: `_/specs/live-call.md` — catalog, UX rules, billing, env flags, rollout
- Modify: `_/specs/README.md` index link

**Ops:**

- [ ] `migrate_db.ps1` or MCP SQL apply `live_offer` on btm cluster.
- [ ] `publish_server.ps1` after Track C.
- [ ] No `min` bump unless wire breaks old clients (new optional proto field — **no min bump** for v1 UI-only).

---

## File index (quick)

| Area | Paths |
|------|--------|
| SQL | `_/schemas/live_offer.sql`, `migrations/20261005_live_offer_v1.sql` |
| Proto | `_/schemas/proto/c35/live.proto`, `session.proto`, `wire.proto` |
| Server | `servers/crates/mod_live/**`, `wire_ws/session.rs`, `mod_billing/billing_cost.rs` |
| Client | `c/live/**`, `widgets/ai/ui_live_call_chip.dart`, `pages/page_live_call.dart`, `page_ai_home.dart` |
| Tests | `clients/app/test/live_call_ui_test.dart` |
| i18n | `translation.sql`, `catalog_translation_cache.dart`, `en.json` / `id.json` |

---

## Review gates

| Gate | Criteria |
|------|----------|
| **G0** | Schema + proto on cluster; session init returns offers |
| **G1** | Welcome chip UX matches locked table; tests green |
| **G2** | End-to-end Alien AI + Gemini Live audio on Android |
| **G3** | Docs + billing rows sane for 5 min call sample |

---

## Status

- [ ] Track 0
- [ ] Track A
- [ ] Track B
- [ ] Track C
- [ ] Track D
- [ ] Track E (optional)
- [ ] Track F
