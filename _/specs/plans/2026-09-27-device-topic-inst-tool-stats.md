# Device topic inst, tool eligibility, WS fs tools, tool usage stats

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the user @mentions a paired device, activate **`device` topic** steering (facts-only, no guessing), **feed the right WS tools** (`device.screenshot`, `device.command`, later `device.fs.*`), and add **ops visibility** into which tools actually ran (weekly/monthly) from **`ai.log`**.

**Architecture:** Type B only — **`ai.inst`** + **`include_tools` / `exclude_tools`** on `kind=topic`, `topic_id=device`; align Rust **`mention_force_tools`** and tool **`always` / `topics`** metadata with that inst. Automation stays on **agent WS** (command, screenshot, future fs RPC) — **never WebRTC** for LLM (`_/specs/remote.md`). Tool stats = SQL on **`ai.log`** where `kind='tool'` and `meta.tool` (extend **`admin_log_report`** or sibling RPC).

**Tech Stack:** YSQL `ai.inst` / `ai.topic` / `ai.log`, Rust `mod_chat` / `mod_device` / `mod_admin`, protobuf `wire.proto` + `remote.proto`, MCP `prompt_compose` / `prompt_run`.

## Global Constraints

- Read [`spec.md`](../../spec.md), [`_/specs/inst.md`](../../_/specs/inst.md), [`_/specs/remote.md`](../../_/specs/remote.md), [`.cursor/rules/prompt-steering.mdc`](../../.cursor/rules/prompt-steering.mdc).
- **No new hardcoded steering strings in Rust** — device behavior copy lives in **`inst.sql`** seeds.
- **Subagent model:** `inherit` only (never `*-fast`).
- Verify server: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_chat` when touching compose/tools.
- Verify steering: MCP **`prompt_compose`** then **`prompt_run`** with `owner_iid=99000`, text like `what is on @Desktop recycle bin?` + device in `mention_ids` — assert `device.screenshot` and **`device.command`** fed, inst includes **`inst.device.facts`**, answer uses command output not icon guess.
- Do not commit unless user asks.

---

## Multitask Map

```
Track 1 (inst + topic seeds + docs)
Track 2 (tool metadata + mention_force_tools + compose tests)
         │
         ├──► Track 5 (MCP prompt_run verify)     Wave 3
Track 3 (tool usage stats from ai.log)  ── Wave 1 parallel
Track 4 (WS fs RPC + device.fs.* tools) ── Wave 2 (after 1–2)
Track 6 (optional trace UI screenshot thumb) ── Wave 4 / skip
```

| Track | Focus | Depends | Wave |
|-------|--------|---------|------|
| **1** | `inst.device.facts`, `ai.topic` `device`, `inst.md` / `chat.md` | — | **1** |
| **2** | `device.command` on `device` topic, `mention_force_tools`, tests | 1 (inst ids stable) | **1** (parallel with 1 if seeds merged first) |
| **3** | Tool usage aggregation (`admin_tool_report` or extend log report) + optional index | — | **1** |
| **4** | Agent WS `ReqRemoteFs*`, `device.fs.list` / `device.fs.read` readonly tools | 1–2 | **2** |
| **5** | End-to-end MCP + mention_context tests | 1–2 | **3** |
| **6** | Flutter trace sheet: thumbnail from `meta.output_preview` / image (optional) | — | **4** |

**Wave 1:** Tracks **1 + 2 + 3** (three subagents).  
**Wave 2:** Track **4**.  
**Wave 3:** Track **5**.  
**Wave 4:** Track **6** if desired.

---

## Locked design

### Topic activation (no new `always_include_mentions` column)

- Client sends **`mention_ids`** including `iid:{device}` for inline chips.
- Server **`mention_resolve_all`** → identity rows with **`topic_id = device`**.
- **`mention_active_topics`** → primary topic **`device`** when any device resolved (unless explicit `req.topic_id` set).
- **`inst_pick`** with **`kind=topic`, `topic_id=device`** applies **`inst.device.facts`**.
- **`[MENTION TARGETS]`** block lists each device ref + **iid** for `device_iid` on tools.

### Inst seed: `inst.device.facts`

| Field | Value |
|-------|--------|
| `id` | `inst.device.facts` |
| `kind` | `topic` |
| `topic_id` | `device` |
| `priority` | `140` (above generic task rows, below `inst.core.assistant` trigger if both match — both may apply; facts block is additive) |
| `include_tools` | `device.screenshot`, `device.command` |
| `exclude_tools` | `device.input`, `computer_use.delegate` (delegate only when user asks multi-step automation — optional: drop exclude and steer in body) |
| `inst` body | Facts-only contract: use **`device_iid` from [MENTION TARGETS]**; never guess; recycle bin / paths → **`device.command`** (or **`device.fs.list`** after Track 4); screen layout → **`device.screenshot`**; multi-device disambiguation; report tool errors |

Tune **`inst.mention.device_read`** (task + screen phrases) — keep narrow; do not duplicate full device facts.

### Topic seed: `ai.topic` id `device`

Insert row (extend chain optional):

- `label_key`: `topic.device.label`
- `inst`: one-line persona (“Remote device questions use tools on the mentioned PC…”)
- `extend`: `general`
- Add translation keys in `translation.sql` if label is keyed.

### Tool metadata (Track 2)

| Tool | Change |
|------|--------|
| **`device.screenshot`** | Keep `always: ["device", "computer_use"]`, `readonly: true` |
| **`device.command`** | Add **`always: ["device"]`** OR `topics: ["device", "computer_use"]` so Home @device turns feed shell without delegate |
| **`device.input`** | Keep **`computer_use`** only |
| **`mention_force_tools`** | Include **`device.command`** when `mention_has_device` (mirror inst; avoid RAG dropping shell) |

Files:

- `servers/crates/mod_chat/src/tools/builtin/device.rs`
- `servers/crates/mod_chat/src/mention_tool_registry.rs`
- `servers/crates/mod_chat/tests/mention_registry_test.rs` — update expectations

### Tool usage stats (Track 3)

**Source:** `ai.log` rows where:

```sql
kind = 'tool' AND class = 'trace' AND deleted_ts IS NULL
AND COALESCE(meta->>'tool', '') <> ''
```

**Metrics:**

| Metric | SQL idea |
|--------|-----------|
| Calls per tool (range) | `GROUP BY meta->>'tool'` + `COUNT(*)` + filters on `created_ts` |
| OK vs fail | `FILTER` on `meta->>'ok'` or `topic = 'tool_error'` |
| Weekly / monthly | `date_trunc('week'|'month', created_ts)` |
| Avg latency | `AVG(duration_ms)` |
| Zero calls in N days | `DISTINCT tool` anti-join window |
| Never in prod | Registered tool names from `cluster_tools()` minus ever-distinct `meta.tool` (report as second table or export list in Rust) |

**Implementation options (pick one in Track 3):**

1. **Extend `ReqAdminLogReport`** / `log_report.rs` with optional `group_by=tool` and second table widget — minimal proto change in `report.proto`.
2. **New `ReqAdminToolUsageReport`** in `report.proto` + `mod_admin` handler — clearer API.

**Optional migration** (`_/schemas/migrations/YYYYMMDD_log_tool_meta_index.sql`):

```sql
CREATE INDEX IF NOT EXISTS idx_log_tool_trace_created
  ON ai.log ((meta->>'tool'), created_ts DESC)
  WHERE deleted_ts IS NULL AND kind = 'tool' AND class = 'trace';
```

**Exclude:** voice-only `kind=tool` rows without `meta.tool` (or document separate `topic` filter).

Docs: short section in [`_/specs/log.md`](../../_/specs/log.md) “Tool execution analytics”.

### WS fs tools (Track 4) — automation plane

**Not WebRTC.** Reuse `remotes/c_remote_core/src/webrtc/fs.rs` helpers from a new agent WS handler.

**Proto:** Add to `wire.proto` `WsReq` / `WsRes` oneofs (mirror `ReqRemoteCommand` pattern):

- `ReqRemoteFsList` / `ResRemoteFsList`
- `ReqRemoteFsRead` / `ResRemoteFsRead` (cap read length server-side)

**Server:** `mod_device/remote_signaling.rs` — pending map + NATS reply like command; timeout.

**Agent:** `c_remote_core` session — dispatch to shared `fs_list` / `fs_read` (max bytes e.g. 256KB for LLM).

**Tools:**

| Tool | readonly | notes |
|------|----------|--------|
| **`device.fs.list`** | yes | `device_iid`, `path` |
| **`device.fs.read`** | yes | `device_iid`, `path`, `offset`, `max_bytes` |

Register in `device.rs`, `topics`/`always` like screenshot, **`include_tools`** on `inst.device.facts` after shipped.

---

## Track 1 — Inst + topic seeds + docs

**Files:** `_/schemas/inst.sql`, `_/schemas/topic.sql`, `_/schemas/translation.sql` (if needed), `_/specs/inst.md`, `_/specs/chat.md`

- [ ] **1.1** Add `INSERT`/`UPDATE` for **`inst.device.facts`** with `include_tools` / `exclude_tools` columns (not legacy `tool_include:` only).
- [ ] **1.2** Add **`ai.topic`** row **`device`** + translation label.
- [ ] **1.3** Document in **`inst.md`**: device mention → **`device` topic**; **`kind=topic`** inst; facts-only; multi-device; difference vs **`computer_use`** delegate.
- [ ] **1.4** Update **`chat.md`** mention table if needed (`device.screenshot` + **`device.command`** on mention).

**Verify:** Apply SQL on dev YB; `inst_list` MCP shows new row enabled.

---

## Track 2 — Tool eligibility + force_tools + tests

**Files:** `device.rs`, `mention_tool_registry.rs`, `mention_registry_test.rs`, `compose_test.rs`

- [ ] **2.1** Set **`device.command`** eligible on **`device`** topic (`always` and/or `topics`).
- [ ] **2.2** Add **`device.command`** to **`mention_force_tools`** when device mention present.
- [ ] **2.3** Test: `mention_force_tools` includes screenshot + command.
- [ ] **2.4** Test: `compose_tools_and_inst` with mocked device mention → **`device.command`** in fed set (extend `compose_test.rs` / `mention_context_test.rs`).

**Verify:** `cd servers && cargo test -p c35_mod_chat`

---

## Track 3 — Tool usage stats

**Files:** `mod_admin/src/log_report.rs` or new `tool_usage_report.rs`, `report.proto`, `wire.proto`, `_/schemas/migrations/*_log_tool_meta_index.sql`, `_/specs/log.md`

- [ ] **3.1** Implement SQL aggregation (since/until ms, optional `owner_iid`, limit top N tools).
- [ ] **3.2** Expose via admin RPC (root-only like existing log report).
- [ ] **3.3** Return UI widgets: total tool calls, table `tool_id | calls | ok | fail | avg_ms`, optional weekly breakdown.
- [ ] **3.4** Optional index migration + doc section.

**Verify:** Root admin report with `since_ms` last 7 days; spot-check against manual `yb_query` on `device.screenshot`.

---

## Track 4 — WS fs RPC + LLM tools

**Files:** `_/schemas/proto/c35/wire.proto`, `remote.proto` (if needed), `mod_device/remote_signaling.rs`, `remotes/c_remote_core/src/...`, `device.rs`, `inst.sql` (add fs to `include_tools`)

- [ ] **4.1** Proto + regenerate Dart/Rust pb (app only if WS not used from Flutter for LLM path — server+agent only).
- [ ] **4.2** Agent handler calling existing fs module.
- [ ] **4.3** Server round-trip with timeout + error mapping (`fail_class` like command).
- [ ] **4.4** Register **`device.fs.list`** / **`device.fs.read`** readonly tools.
- [ ] **4.5** Add tools to **`inst.device.facts`** `include_tools`; inst line: prefer fs list for directories when available.

**Verify:** `cargo build -p c_remote_windows`; integration test or manual MCP `tool_exec` list path on 99000 device (if online).

---

## Track 5 — MCP verification

- [ ] **5.1** `prompt_compose` — device mention phrase + `mention_ids` with real `iid:` → `inst.device.facts` in trace, **`device.command`** fed.
- [ ] **5.2** `prompt_run` — recycle bin question → **`device.command`** or fs in trace, not LLM-only first hop.
- [ ] **5.3** Document checklist in this plan footer or `prompt-run-test.mdc` example row.

---

## Track 6 — Trace UI screenshot (optional)

**Files:** `clients/app/lib/widgets/ai/ui_msg_trace_sheet.dart`, `trace_view.dart`

- [ ] **6.1** For `kind=tool` + `device.screenshot`, decode truncated `image_base64` from trace meta for thumbnail in sheet (cap size, no full chat embed).

---

## Acceptance (whole feature)

1. @device + factual question → **`inst.device.facts`** in compose trace; **`device.command`** + **`device.screenshot`** fed.
2. Recycle bin / dir questions steered to **command or fs**, not desktop icon inference.
3. Admin (or documented SQL) shows **tool call counts** per week/month from **`ai.log`**.
4. (Track 4) **Structured directory listing** without WebRTC viewer session.

---

## Handoff: dispatch order

```text
Wave 1 Task A → Track 1 (inst + topic + docs)
Wave 1 Task B → Track 2 (tools + tests)
Wave 1 Task C → Track 3 (tool stats)
Wave 2 Task D → Track 4 (WS fs)
Wave 3 Task E → Track 5 (MCP verify)
```

After Wave 1–3, run **`publish_server.ps1`** when merging to cluster (user-driven).

---

## Reference SQL (tool stats ad-hoc)

```sql
SELECT meta->>'tool' AS tool_id, COUNT(*) AS calls
FROM ai.log
WHERE deleted_ts IS NULL AND kind = 'tool' AND class = 'trace'
  AND created_ts >= NOW() - INTERVAL '30 days'
  AND meta->>'tool' IS NOT NULL
GROUP BY 1 ORDER BY 2 DESC;
```
