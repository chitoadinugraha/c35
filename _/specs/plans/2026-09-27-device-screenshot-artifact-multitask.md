# Device screenshot artifact (CAS + trace preview) — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Persist the exact JPEG sent to the LLM for `device.screenshot` / `device.input` post-screenshot in CAS, index with **14-day TTL**, and show an **expandable preview** on trace tool chips (marked/SoM frame).

**Architecture:** After remote agent returns `jpeg_bytes`, server `cas_put` (blake3) → row in `ai.tool_artifact` linking `owner_iid`, `req_id`, `tool_call_id`, `device_iid`, dimensions, flags (`som`, `marker`). Tool JSON to LLM unchanged for vision (`image_base64`); trace `ai.log` stores **slim** `meta` + `output_preview` without base64. Flutter trace reads `screenshot_hash` / signed URL and renders thumbnail in `UiMsgTraceToolChip`. Daily sweeper deletes expired artifact rows and optionally CAS blobs only referenced by expired artifacts.

**Tech Stack:** Rust (`mod_chat`, `mod_file`, `mod_log`), YSQL (`_/schemas/`), Flutter (`clients/app` trace widgets), existing CAS (`ai.file_blob_meta`).

## Global Constraints

- Read `spec.md`, `_/specs/remote.md`, `_/specs/log.md`, `_/schemas/file.sql` before coding.
- Do not store base64 in `ai.log` (keep previews &lt; 4KB).
- Screenshot bytes = **post-overlay** agent JPEG (SoM + red marker already applied).
- TTL **14 days** from `created_ts` (`expires_ts = created_ts + interval '14 days'`).
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p mod_chat` when tests added; `cd clients/app && flutter analyze`; parse edited `.ps1` if any.
- Subagent `model`: **inherit** only.
- Do not git commit unless user asks.

---

## Multitask Map

```
Track 0 (Schema)     ──┬──► Track 1 (CAS persist + device tools)
                       └──► Track 4 (Eviction job)

Track 1              ──► Track 2 (Turn tracer slim meta)
Track 2              ──► Track 3 (Flutter trace preview UI)

All                  ──► Track 5 (Docs + verify)
```

| Track | Focus | Depends |
|-------|-------|---------|
| **0** | `ai.tool_artifact` DDL + migrate hook | — |
| **1** | `device_screenshot_persist` helper; wire `device.rs` screenshot + `screenshot_after` | 0 |
| **2** | `TurnTracer::tool_result` strip `image_base64`; `meta.screenshot` object | 1 |
| **3** | Flutter: `TraceBranch` / chip expandable image via CAS URL | 2 |
| **4** | `tool_artifact_evict` (SQL + optional cron RPC / script) | 0 |
| **5** | `_/specs/remote.md`, `_/specs/log.md`; integration notes | 1–4 |

**Wave 1 (parallel):** Tracks **0**, **4** (schema + evict skeleton)  
**Wave 2 (parallel):** Tracks **1**, **2**  
**Wave 3:** Track **3**  
**Wave 4:** Track **5**  
**Wave 3b (parallel with 3):** Track **6** — MCP debug (below)

---

## Track 6 — MCP debug (artifact + vision)

| MCP tool | HTTP `action` | Purpose |
|----------|---------------|---------|
| `tool_artifact_list` | `tool_artifact_list` | List CAS screenshot rows for `req_id` |
| `tool_artifact_fetch` | `tool_artifact_fetch` | One artifact; `include_base64`, optional `save_path` (Node writes `.jpg`) |
| `trace_screenshot` | `trace_screenshot` | Latest `device.screenshot` / `device.input` artifact for turn |
| `device_screenshot` (extended) | `tool_exec` | `marker_x` / `marker_y` / `quality`; `device_iid` string snowflake |

Server: `mod_chat/mcp_tool_artifact.rs` + `mod_file::tool_artifact_{list,get}`.

- [x] Implement Track 6 (in progress with main tracks)
- [ ] Document in `_/mcps/README.md` and `agent-debug.mdc` after MCP rebuild + reload

---

## Track 0 — Schema `ai.tool_artifact`

**File:** `_/schemas/tool_artifact.sql` (new); register in migrate list after `file.sql`.

```sql
CREATE TABLE IF NOT EXISTS ai.tool_artifact (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL,
    req_id          TEXT NOT NULL,
    tool_call_id    TEXT NOT NULL DEFAULT '',
    tool_id         TEXT NOT NULL,           -- device.screenshot
    device_iid      BIGINT NOT NULL DEFAULT 0,
    hash_blake3     VARCHAR(64) NOT NULL REFERENCES ai.file_blob_meta(hash_blake3),
    width           INT NOT NULL DEFAULT 0,
    height          INT NOT NULL DEFAULT 0,
    meta_json       JSONB NOT NULL DEFAULT '{}',  -- som, marker_x, marker_y, axtree_len (not full tree in row)
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_ts      TIMESTAMPTZ NOT NULL,
    deleted_ts      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_tool_artifact_req ON ai.tool_artifact (owner_iid, req_id) WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_tool_artifact_expires ON ai.tool_artifact (expires_ts) WHERE deleted_ts IS NULL;
```

- [ ] Add migration / schema.rs mirror if project uses generated schema module.
- [ ] `expires_ts` default in app: `Utc::now() + 14 days`.

---

## Track 1 — Server persist on capture

**New:** `servers/crates/mod_chat/src/tools/device_screenshot_artifact.rs` (or under `mod_device` if cleaner — prefer `mod_chat` near `device.rs`).

```rust
// pub async fn device_screenshot_artifact_put(
//   pool, owner_iid, req_id, tool_call_id, device_iid, jpeg: &[u8], w, h, som, marker, axtree_text
// ) -> Result<(hash, url)>
```

Steps:

- [ ] `cas_put` via `c35_mod_file::{cas_put, cas_dir_default}` + CAS secret from env (same as `img.rs`).
- [ ] `INSERT ai.tool_artifact` with snowflake `id`.
- [ ] `meta_json`: `{ "som": bool, "marker": bool, "axtree_chars": n }` — optional store first 2KB of `axtree_text` if needed for trace expand.

**Wire** `servers/crates/mod_chat/src/tools/builtin/device.rs`:

- [ ] After successful capture, call artifact put when `ctx.req_id` available (add to `ToolContext` if missing — check `ToolContext` for `req_id`).
- [ ] Extend tool JSON: `image_hash`, `image_url` (signed CAS URL), keep `image_base64` for LLM.
- [ ] Same for `screenshot_after` branch in `device.input`.

**Tests:**

- [ ] `mod_chat` test with `C35_TEST_DB=1`: mock or stub cas if needed; at minimum unit test JSON shaping / preview strip.

---

## Track 2 — Trace logging (slim)

**File:** `servers/crates/mod_chat/src/turn_tracer.rs`

- [ ] Before serializing `result` for `output_preview`, clone and remove `image_base64` (and nested `llm.image_base64`).
- [ ] Add `meta.screenshot`: `{ "hash", "url", "width", "height", "som", "marker" }` when tool is `device.screenshot` or `device.input` with image.
- [ ] Keep human `text` line short: e.g. `device.screenshot 1280x782 hash=abc…`.

---

## Track 3 — Flutter trace preview

**Files:**

- `clients/app/lib/c/trace/trace_view.dart` — extend `TraceBranch` / `MsgTraceToolChip` with `screenshotHash`, `screenshotUrl`, `screenshotW`, `screenshotH`.
- `clients/app/lib/widgets/ai/msg_trace_view.dart` — `UiMsgTraceToolChip`: if screenshot URL/hash, show chevron expand → `Image.network` or existing CAS fetch helper (grep `cas` / `file_hash` in app).
- `clients/app/lib/widgets/ai/ui_agent_tool_accordion.dart` — pass through expanded detail.

- [ ] Parse from `log.meta['screenshot']` first; fallback `traceToolJsonFromLog` fields `image_hash` / `image_url`.
- [ ] Widget test: chip with hash shows expand affordance.

---

## Track 4 — Eviction (14d)

**New:** `servers/crates/mod_file/src/tool_artifact.rs` or `mod_chat/src/tool_artifact_store.rs`

- [ ] `tool_artifact_evict_stale(pool, before: DateTime)` → soft-delete rows `expires_ts < now`.
- [ ] Optional: delete CAS blob when no other references (count refs from `ai.tool_artifact` + mail attachments etc.) — **YAGNI v1:** only soft-delete artifact rows; CAS dedupe keeps bytes until separate GC.
- [ ] Hook: admin cron / `node_stats` tick / documented `ps1` dev script — pick one minimal path.

---

## Track 5 — Docs

- [ ] `_/specs/remote.md` § Computer Use — artifact retention 14d, trace preview.
- [ ] `_/specs/log.md` — `meta.screenshot` on `kind=tool` rows.

---

## Acceptance

1. Run `device.screenshot` on a paired device → `ai.tool_artifact` row + CAS hash.
2. `trace_get` / app trace for that `req_id` shows tool chip with expandable JPEG (same as LLM).
3. `ai.log` tool row has no multi-KB base64 in `text`/`output_preview`.
4. Evict script removes rows past `expires_ts`.
