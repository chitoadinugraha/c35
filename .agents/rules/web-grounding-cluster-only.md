# Web grounding — cluster tools only

Cursor: [`.cursor/rules/web-grounding-cluster-only.mdc`](../../.cursor/rules/web-grounding-cluster-only.mdc)

## Hard rule

Never add **provider-native web grounding** (`googleSearch`, `groundingConfig`, OpenAI `web_search` tool type, etc.). Use cluster **`web.search`** / **`web.visit`** / **`web.research`** only.

## Verify

```powershell
.\_\scripts\dev\check_no_provider_grounding.ps1
```

Runtime guard: `c35_mod_llm::gemini_request_reject_provider_grounding`.

Steering: `inst.web_search` + Rust web pipeline (`prompt-run-test.md`).
