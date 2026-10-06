# Prompt pipeline verification (MCP)

Spec: [`_/docs/inst.md`](../../_/docs/inst.md). Cursor: [`.cursor/rules/prompt-run-test.mdc`](../../.cursor/rules/prompt-run-test.mdc).

## Verify (hard rule)

Wrong chat / missing tool / pipeline bug: reproduce → fix in correct layer → **`prompt_compose`** → **`prompt_run`** before claiming fixed.

`owner_iid`: 99000 app-like, 33000 regression.

## Where steering lives

- **`ai.inst`**: when/how; tool **`description`** = what; **`rag_phrases`** = discovery
- **Not** new steering in `prompt_turn` except time/memory merge
- Git **`inst.sql`** → live **`inst_put`** (+ NATS cache)

## Excluded from no-hardcode: web tools

**`web.search`**, **`web.visit`**, **`web.research`** — Rust pipeline is allowed and expected:

- `WEB_GROUNDED_REPLY_RULE`, `user_wants_search`, prefetch/visit chain in `tool_loop.rs`
- `pick_visit_url`, `catalog_web_*`

Still use **`inst.web_search`** (and related inst rows) for phrases, include/exclude, and *when* to search.

**Every other tool:** inst + `compose_force_*` only — no Rust phrase prefetch, no `reply_rule` in tool JSON.

## Missing tools (compose first)

| Symptom | Fix layer |
|---------|-----------|
| `inst_ids: []` | Inst cache / pod |
| No inst match | `phrases`, scope, live row |
| Tool not eligible | `topics`, `always`; inst `include_tools` |
| Not fed | `rag_phrases`, `exclude_tools` |
| Fed, not called (non-web) | Inst + `compose_force_*` |
| Web not grounded | `inst.web_search` + Rust prefetch/defer |

Order: cache → eligibility → inst → RAG → force_* (web: also check Rust pipeline).

## Assert (`prompt_run`)

Tool fed + hop 1 tool when needed; `blocks_json`; honest `text`.
