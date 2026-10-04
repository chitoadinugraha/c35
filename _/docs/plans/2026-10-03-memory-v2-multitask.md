# Memory v2 — Multitask Implementation Plan

> **For agentic workers:** Dispatch independent tracks as subagents (`model: inherit`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make long-term memory (`ai.memory`) cheaper, faster and more accurate: fix extraction model + billing, move extraction off the reply path, replace the one-line extractor prompt with an add/update/delete extractor, store embeddings at write time and recall with hybrid (pinned + FTS + vector), add `memory.save` / `memory.forget` tools, and refresh docs.

**Baseline (today):**
- Extract: `memory_extract.rs` — `gemini-2.0-flash`, 1-line `EXTRACT_SYSTEM`, last user+assistant turn only, max 2 writes, conf >= 0.85, awaited inside the turn.
- Recall: `memory.rs` `memory_retrieve` — FTS (`plainto_tsquery`, AND) → embed re-rank of FTS hits; per-candidate doc embeds (up to 32) inside an 800 ms timeout; `embedding_json` unused.
- Billing bug: cost uses constant `"gemini-2.0-flash"`, but `gemini_model()` resolves to the catalog/Alien default.
- Doc drift: `context-compaction.md` L28 says "no extraction wired"; L229 says embeddings "not billed" but code bills the query embed.

## Global Constraints

- Read `spec.md`, `_/docs/context-compaction.md`, `_/docs/chat.md`, `_/docs/billing.md`, `_/docs/inst.md` first. **Update docs first** (Track 0), then code.
- Memory failure **fails open** — never block or fail a user turn.
- Never hard-delete memories from the extractor; **soft delete** (`deleted_ts`) only.
- Schema changes are additive (`ALTER ... ADD COLUMN IF NOT EXISTS`); confirm with user before anything destructive (`ask_confirm.mdc`).
- New tools need a paired `ai.inst` macro seeded first in `inst.sql` (`inst.mdc`) + NATS cache invalidation.
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_chat` (crate name per workspace); `cd clients/app && flutter analyze` if UI touched.
- Do not commit unless asked.

---

## Multitask Map

```
Track 0 (Docs/spec) ──┬──► Track 1 (Model + billing + async)
                      ├──► Track 2 (Extractor v2)
                      └──► Track 3 (Embed at write + hybrid recall)

Track 1 ──► Track 2
Track 3 ──► Track 4 (Tools: memory.save / memory.forget + inst)
Track 2 + 3 + 4 ──► Track 5 (Prompt block framing + tracing)
Track 4 ──► Track 6 (Settings UI, optional)
All ──► Track 7 (Tests + verify + doc cross-check)
```

| Track | Focus | Depends |
|-------|-------|---------|
| **0** | Docs: `context-compaction.md` § Phase 3 rewrite, fix stale lines, `chat.md` row | — |
| **1** | Extract/compact use resolved Alien default; correct billing name; background extraction | 0 |
| **2** | Extractor v2: richer prompt, existing-memory context, add/update/delete actions, key normalization | 0, 1 |
| **3** | Schema: embedding at write; hybrid recall (pinned + FTS-OR + vector, sim floor); drop per-candidate embeds | 0 |
| **4** | Tools `memory.save`, `memory.forget` (+ `memory.list` optional) + inst macro | 3 |
| **5** | `## Memory` framing text, caps, trace fields | 2, 3, 4 |
| **6** | Flutter memory list/forget (optional, separate approval) | 4 |
| **7** | Tests, `cargo build`, doc cross-check, manual `prompt_run` test | all |

**Wave 1:** Track 0
**Wave 2 (parallel):** Tracks 1 + 3
**Wave 3 (parallel):** Tracks 2 + 4
**Wave 4:** Track 5
**Wave 5:** Track 7 (Track 6 only if approved)

---

## Track 0 — Docs first

**Files:** `_/docs/context-compaction.md`, `_/docs/chat.md`, `_/schemas/memory.sql`, `_/docs/inst.md` (if new macro)

- [ ] Rewrite § Phase 3 with: extractor actions (`add|update|delete`), related-memory context, categories (`preference|fact|task|identity`), key normalization, soft delete rule.
- [ ] Add § Recall (hybrid): pinned (`category in (identity, preference)`, cap 3), FTS (OR-tsquery), vector (cosine >= floor), merge/dedupe, cap 8 rows / ~800 chars.
- [ ] Fix L28 ("no extraction wired") and L229 (embedding billing: query embed is billed, doc embeds are platform COGS, write-time embeds platform COGS).
- [ ] Document constants: `MEMORY_RECALL_LIMIT=8`, `MEMORY_RECALL_CHAR_CAP=800`, `MEMORY_SIM_FLOOR=0.55`, `MEMORY_PINNED_LIMIT=3`, `MEMORY_RELATED_CONTEXT=5`.
- [ ] Document extraction model rule: resolved via `gemini_model("alienai")`, billed by **resolved** name.

## Track 1 — Model, billing, async extraction

**Files:** `memory_extract.rs`, `context_compact.rs`, `channel_prompt_turn.rs`, `prompt_turn.rs`, `context_billing.rs`

- [ ] Replace `MEMORY_EXTRACT_MODEL` / `CONTEXT_COMPACT_MODEL` constants with `gemini_model("alienai")`; compute `billing_cost_usd(&resolved, in, out)` using the resolved name.
- [ ] Add `memory_extract_spawn(...)`: `tokio::spawn` after reply; on completion, **do not block** the turn. Billing: the turn's `billing_usage_report` is already sent, so report extraction as a follow-up `billing_usage_report` with `req_id = "memx-{req_id}"` (best-effort, skip if unaffordable — same policy as idle backfill). Document the choice in Track 0.
- [ ] Keep `memory_extract_batch` (compaction/idle) synchronous — it is already off the reply path.
- [ ] Skip gate: `tool_mode = ask`, errored turn, `assistant_text < 50` chars (existing), or user text is trivially short with no digits/names (cheap heuristic, optional).
- [ ] Remove now-unused `memory_extract_*` fields from the per-turn billing struct only if nothing else reads them; otherwise keep for the compaction path.

**Acceptance:** turn completion time no longer includes the extraction call; billing log shows resolved model name.

## Track 2 — Extractor v2

**Files:** `memory_extract.rs`, `memory.rs` (new `memory_related()` helper)

- [ ] New `EXTRACT_SYSTEM`: durable-fact policy, category definitions, key naming (`snake_case`, stable noun phrases e.g. `diet_restriction`, not sentences), 3–4 short few-shot examples, "skip ephemeral/greeting/assistant-only facts", "return `[]` when unsure".
- [ ] Output schema: `{"actions":[{"op":"add|update|delete","key":"…","category":"…","content":"…","confidence":0.0-1.0}]}`.
- [ ] Before the call, fetch up to `MEMORY_RELATED_CONTEXT` related existing memories (FTS or vector on the transcript) and include them as "Existing memories" so the model reuses keys and detects contradictions.
- [ ] Apply: `add/update` → `memory_put` (upsert by key); `delete` → soft delete, only if confidence >= 0.9. Keep `MEMORY_EXTRACT_MAX_PER_TURN=2` for the per-turn gate; compaction batch may allow more (cap 6).
- [ ] Per-turn transcript: last **2** user/assistant exchanges (not 1) to catch multi-turn facts.
- [ ] Parser stays tolerant (`{...}` extraction); fall back to the legacy `candidates` shape for one release.
- [ ] Unit tests: parse legacy + new shape, reject low-confidence, ignore `ephemeral`, delete threshold.

## Track 3 — Embed at write + hybrid recall

**Files:** `_/schemas/memory.sql`, `memory.rs`, `crates/store/src/schema.rs` (bundle hash), `mod_llm` embed helpers

- [ ] Schema (additive): `embedding_json` already exists — add `embed_model VARCHAR(48) NOT NULL DEFAULT ''`, optional `pinned BOOLEAN NOT NULL DEFAULT FALSE`. Update the schema bundle hash per `schema-migrate.md`.
- [ ] `memory_put`: after upsert, compute document embedding (`EMBED_TASK_DOCUMENT`, 768) and store in `embedding_json` + `embed_model`; failure is non-fatal (row stays FTS-only). Re-embed when content changes.
- [ ] Backfill job: small one-shot (`memory_embed_backfill`) over rows with null `embedding_json` (batched, rate-limited), runnable from `c35_migrate` or an admin NATS trigger. Confirm with user before running on prod.
- [ ] `memory_retrieve_impl` rewrite:
  1. **Pinned:** `category IN ('identity','preference')` or `pinned`, newest first, cap `MEMORY_PINNED_LIMIT`.
  2. **FTS-OR:** `to_tsquery` with OR-joined stemmed tokens (not `plainto_tsquery` AND) → top 16.
  3. **Vector:** one query embed (existing `embed_cached`); cosine against stored `embedding_json` of up to N=200 active rows for the owner (skip rows with mismatched `embed_model`); keep >= `MEMORY_SIM_FLOOR`.
  4. Merge, dedupe by key, rank: pinned first, then `0.6*cosine + 0.3*fts_norm + 0.1*recency`, cap `MEMORY_RECALL_LIMIT` rows / `MEMORY_RECALL_CHAR_CAP` chars.
- [ ] **Remove** the per-candidate `embed_cached` doc loop (the main latency risk).
- [ ] Timeout: keep 800 ms for the query embed; DB work must not be inside the embed wait. On timeout, fall back to pinned + FTS (no empty block).
- [ ] Empty query keeps current "latest N" behavior.
- [ ] Tests: ranking order, similarity floor, mismatched `embed_model` skipped, FTS-OR matches conversational query, timeout fallback.

## Track 4 — Memory tools

**Files:** `tools/` (new `memory_tools.rs`), tool registry, `_/schemas/inst.sql` (seed first), `_/docs/inst.md`

- [ ] `memory.save {key, content, category?}` → `memory_put` (owner scope; bot scope when in bot channel). Returns saved key.
- [ ] `memory.forget {key | query}` → soft delete matching rows (query: top vector/FTS match above 0.8, return what was forgotten so the model can confirm).
- [ ] (Optional) `memory.list` → keys + content, capped at 20.
- [ ] Inst macro seeded first in `inst.sql`: triggers on "remember", "forget", "don't remember", "my preference is…"; instructs the model to call the tool and confirm briefly. Invalidate runtime cache via NATS per `inst.mdc`.
- [ ] Tool cost: free (no LLM). Embedding at write is platform COGS.
- [ ] Authorization: tools operate only on `owner_iid` of the turn; no cross-owner key access.

## Track 5 — Prompt block + tracing

**Files:** `memory.rs` (`memory_prompt_block`), `turn_tracer.rs`

- [ ] Replace bare `## Memory` list with a framed block:
  ```
  ## Memory
  Known facts about the user. Use naturally; do not recite. If the user's current message conflicts, trust the user and (if a memory tool is available) update it.
  - key: content
  ```
- [ ] Keep ordering stable (pinned first, then by key) so repeated turns hit the KV prefix cache where recall is unchanged. Block stays **before** the time/location tail.
- [ ] `MemoryRetrieveTrace`: add `pinned_count`, `fts_count`, `vector_count`, `db_ms`, `fallback` (`none|fts|timeout`). Surface in trace label.

## Track 6 — Settings UI (optional, needs approval)

**Files:** `clients/app/lib/...` (per `ui-page.mdc`), `_/schemas/proto/c35/*.proto`, wire handlers

- [ ] Memory list page under profile/settings: list (key, content, category, updated), delete, edit.
- [ ] Wire: `ReqMemoryList / ReqMemoryDelete / ReqMemoryUpdate` (+ responses) — only add after Track 4 is stable.
- [ ] Friendly errors only; technical details in server log.

## Track 7 — Verify

- [ ] `cd servers && cargo build -p server_ai`
- [ ] `cargo test -p` for `mod_chat` (and `mod_billing` if touched)
- [ ] `flutter analyze` (only if Track 6)
- [ ] Manual: use `prompt_run` (see `.cursor/rules/prompt-run-test.mdc`) — scenarios:
  1. "My name is X, I'm vegetarian" → memory rows `name`, `diet_restriction`.
  2. New session: "what should I eat tonight?" → vegetarian memory recalled (vector path, FTS would miss).
  3. "Actually I eat fish now" → `diet_restriction` updated, not duplicated.
  4. "Forget my diet" → soft deleted; next recall excludes it.
  5. Latency: turn completion time before/after (extraction off the path); trace shows `memory` branch ms.
  6. Billing: `ai.log.meta` model name matches resolved model; follow-up `memx-` usage row present.
- [ ] Doc cross-check: constants in code == constants in `context-compaction.md`.

---

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Extractor wrongly deletes | Soft delete, conf >= 0.9, only on explicit contradiction, audit via `source_req_id` |
| Vector recall injects noise | Similarity floor, 8-row / 800-char cap, pinned limited to 3 |
| `embedding_json` scan cost | Cap at 200 rows per owner scan; add pgvector/ANN only if owners exceed this |
| Embedding model change | `embed_model` column; mismatched rows skipped, re-embedded by backfill |
| Follow-up billing for background extraction unaffordable | Skip silently (same as idle backfill); never error |
| Prompt cache churn | Stable ordering; memory block only changes when recall set changes |

## Rollout order (suggested)

1. Track 0 + 1 (small, immediate savings/latency win, fixes billing bug)
2. Track 3 (fixes recall; biggest quality gain)
3. Track 2 (better writes)
4. Track 4 + 5 (user control)
5. Track 6 only on request

## Decisions needed from user

1. Extraction billing: follow-up `memx-{req_id}` usage row (proposed) vs absorb as platform COGS.
2. Run embedding backfill on prod automatically, or manual trigger only?
3. Include Track 6 (settings UI) in this effort?
