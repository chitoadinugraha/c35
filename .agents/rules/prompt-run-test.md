# Prompt run testing (MCP)

After changing **inst**, **tool selection**, **consumption/expense tools**, or **compose/RAG** behavior, verify with the **`c35` MCP `prompt_run`** tool.

## When to run

- Fixed wrong tool fed / missing tool call
- Added or changed `inst` phrases / triggers
- Changed tool descriptions, `rag_phrases`, or vector index
- User reports "AI should have called X but didn't"

## How to run

```
prompt_run {
  text: "<exact user phrase>",
  locale: "id-ID",
  owner_iid: 99000
}
```

| owner_iid | Use |
|-----------|-----|
| **33000** (default) | Automated regression |
| **99000** (`uid` alias ok) | Chito real data |

`prompt_compose` — inst + tool filter only (no LLM).

## Read the response

- `text` — assistant reply
- `blocks_json` — UI blocks
- `trace.lines` / `trace.trace` — tool filter, prepare, llm_call, tool execution
- `trace.trace[].meta` — `trace_tool_filter` with `fed`, `sim`, `ranker`

Do not claim fixed without at least `prompt_compose` on the failing phrase; prefer `prompt_run` for tool-call bugs.
