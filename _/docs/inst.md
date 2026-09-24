# Instruction macros (`inst`) — LOCKED

Status: **locked** 2026-09-22

Phrase- and context-driven **prompt steering** for the Home assistant and bot channels. Inst tells the LLM *how* to behave; [tools](server.md) tell it *what* it can call.

Port: `cs_agent` `agent.inst` → `ai.inst`.

---

## Model (Type B only)

All platform steering lives in **`ai.inst`** (database). Seeds ship in [`../schemas/inst.sql`](../schemas/inst.sql).

| Approach | Status |
|----------|--------|
| **B — DB rows** (`ai.inst`) | **Now** — single source of truth |
| ~~A — Rust `inst!` macro / hardcoded strings~~ | **Removed** — migrate to seeds (e.g. `inst.core.assistant`) |

**Not merged into `ai.inst`** (different layers):

| Layer | Store | Purpose |
|-------|-------|---------|
| Topic chain | `ai.topic.inst` | Inherited topic instructions (`extend` chain) |
| Bot personality | `identity.meta_json.inst_base` | Per-bot base prompt (Bots page) |

---

## Table: `ai.inst`

```sql
ai.inst (
  id          TEXT PRIMARY KEY,      -- e.g. inst.consumption_coach
  scope       TEXT NOT NULL,         -- global | role:personal_assistant | partner:<pid> | …
  kind        TEXT NOT NULL,         -- task | mention | topic | trigger
  topic_id    TEXT,                  -- for kind=mention|topic
  topics      TEXT[],                -- optional topic filter for kind=task
  inst        TEXT NOT NULL,         -- instruction body (injected into system prompt)
  phrases     TEXT[],                -- substring match (kind=task)
  triggers    TEXT[],                -- tool_include/exclude + signal triggers
  priority    INT,
  enabled     BOOLEAN,
  def_hash    TEXT,                  -- seed provenance
  created_ts, updated_ts, deleted_ts
)
```

Naming: `inst.<domain>.<action>` — e.g. `inst.consumption_add`, `inst.core.assistant`.

---

## Kinds

| `kind` | When it applies |
|--------|-----------------|
| `task` | User text contains any `phrases[]` entry (case-insensitive substring) |
| `mention` | Composer `@mention` id matches `topic_id` (see `ai.mention.inst_id`) |
| `topic` | Active `topic_id` matches row `topic_id` |
| `trigger` | Any `triggers[]` entry matches context signals (e.g. `always`) |

Multiple rows can match one turn. Higher `priority` wins ordering; all matched `inst` bodies are concatenated.

---

## Triggers (tool steering)

Entries in `triggers[]`:

| Prefix | Effect |
|--------|--------|
| `tool_include:<name>` | Force tool into turn catalog (e.g. `consumption.add`) |
| `tool_exclude:<name>` | Drop tool (e.g. `img.generate` on food photos) |
| `always` | `kind=trigger` — applies every turn (platform baseline) |
| `mention:<id>` | Match when mention id present |
| `topic:<id>` | Match when topic id active |

Tool names use dot form: `consumption.add`, `web.search`.

### Site / commerce (Phase 9)

| `inst` id | `kind` | `topic_id` / phrases | `tool_include` |
|-----------|--------|----------------------|----------------|
| `inst.web.builder` | mention | `web.builder` | `site.draft_put`, `site.publish`, `site.product_put`, … |
| `inst.site.commerce` | topic | `site.commerce` | `site.tx.put`, `site.tx.preview`, `site.tx.debt_pay` |
| `inst.site.compare` | task | compare, lebih untung, which is more profitable | `site.query.run` |
| `inst.site.report` | task | laporan, report, sales today | `site.query.run` |

Steering detail: [site-ai.md](site-ai.md). Compare inst must instruct the model to pass **all** `site_iids` from `[SITE CONTEXTS]`.

---

## Compose pipeline (per prompt turn)

```
ReqPrompt.text + mention_ids + topic_id
  → inst_list (enabled rows, scoped)
  → inst_pick (phrase / mention / topic / trigger match)
  → inst_matched_prompt → [INST:<id>]\n<body>  → system prompt
  → inst_tool_directives → force_include / tool_exclude
  → compose_tools_and_inst → final tool list + inst_block
```

Implementation: `servers/crates/mod_chat` — `inst.rs`, `inst_macro.rs`, `compose/mod.rs`, `prompt_turn.rs`.

Trace: turn tracer records `inst_ids` for debugging.

---

## Scope

`scope` limits which chat context may load a row:

| Scope | Typical use |
|-------|-------------|
| `global` | Web search, image gen, core assistant |
| `role:personal_assistant` | Home / consumption / health |
| `partner:<pid>` | Partner-owned steering (future) |

**Rule:** `inst_pick` must filter by active scope before phrase match.

---

## Runtime cache + NATS

**Do not** query `ai.inst` on every turn in production.

1. **Startup:** load all `enabled` rows into in-memory cache (`mod_chat`).
2. **Invalidate:** subscribe to NATS subject `c35.inst.{inst_id}` (payload: `inst_id` or tombstone).
3. **On message:** reload that row (or remove from cache).

Publish after any MCP or SQL mutation that changes `ai.inst`.

Partner/root UI (later) uses the same table; MCP is the admin API until UI ships.

---

## MCP admin (partner / root)

Two surfaces share the same semantics:

| Surface | Path |
|---------|------|
| **MCP server** | [`_/mcps/inst/`](../../_/mcps/inst/) — stdio MCP for Cursor/agents |
| **HTTP invoke** | `POST /v1/invoke` — protobuf `ReqInstList` / `ReqInstGet` / `ReqInstPut` / `ReqInstDelete` (session auth + RBAC) |

Rust implementation: `servers/crates/mod_chat/src/inst_admin.rs`.

### Tools

| Tool | Action |
|------|--------|
| `inst_list` | List/filter by `scope`, `kind`, `enabled`; `include_deleted` optional |
| `inst_get` | Get one row by `id` |
| `inst_put` | Upsert by `id`; `inst` body required; `enabled` defaults `true`; `updated_ts = NOW()` |
| `inst_delete` | Soft-delete (`deleted_ts = NOW()`); publish invalidation |

After `inst_put` / `inst_delete`, publish NATS `c35.inst.{inst_id}` (payload: inst id text). `InstCache` (Track 2) reloads that row.

### MCP setup (Cursor)

```json
{
  "mcpServers": {
    "c35": {
      "command": "node",
      "args": ["<repo>/_/mcps/inst/dist/index.js"],
      "env": {
        "DATABASE_URL": "postgresql://…",
        "NATS_URL": "nats://…"
      }
    }
  }
}
```

Build: `cd _/mcps/inst && npm install && npm run build`. See [`_/mcps/inst/README.md`](../../_/mcps/inst/README.md).

### RBAC (HTTP invoke)

- **Root** — all scopes (including `global`)
- **Partner** — rows where `scope = partner:<viewer_iid>` only

MCP server has no session RBAC (cluster-admin use); prefer HTTP invoke from the app when partner UI ships.

---

## Adding steering for a feature

1. Add seed in [`../schemas/inst.sql`](../schemas/inst.sql) (`INSERT … ON CONFLICT DO NOTHING` + `UPDATE` for live fixes).
2. Phrases: real user language (ID + EN), substring match — e.g. `enaknya makan apa`, `track food`.
3. `inst` body: tell model which tool to call first and how to reply (short; UI blocks show numbers).
4. `triggers`: `tool_include` / `tool_exclude` as needed.
5. Run MCP `inst_put` on live cluster or apply migration.

Example (food recommendation):

```sql
-- inst.consumption_coach
inst  = '[NUTRITION] Call consumption.today first …'
phrases = ARRAY['rekomendasi makan', 'enaknya makan apa', 'makan apa']
triggers = ARRAY['tool_include:consumption.today', 'tool_exclude:img.generate']
scope = 'role:personal_assistant'
kind = 'task'
```

---

## Related

| Doc | Link |
|-----|------|
| Consumption tools | [consumption.md](consumption.md) |
| Composer @mentions | [`../schemas/mention.sql`](../schemas/mention.sql) |
| Image gen / edit tiers | [`image.md`](image.md) |
| Topics | [`../schemas/topic.sql`](../schemas/topic.sql) (if present) / catalog proto |
| Chat turn | [chat.md](chat.md) |
| NATS conventions | [sync.md](sync.md) |

---

## Deferred

- Partner / root Flutter admin UI (UITable or settings page)
- Embedding-based inst match (phrase substring only for now)
