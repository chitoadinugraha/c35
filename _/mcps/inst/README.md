# c35 MCP server

Debug toolkit for c35: `ai.inst` CRUD, log/msg trace queries, and server_ai agent HTTP helpers.

**Security:** [`_/docs/mcp-security.md`](../../docs/mcp-security.md)

## Env

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | yes | — | Postgres/Yugabyte connection string (`ai` schema) — do not commit |
| `NATS_URL` | no | — | NATS server URL for inst cache invalidation |
| `NATS_USER` / `NATS_PASS` | no | — | NATS credentials |
| `C35_DEBUG_OWNER_IID` | no | `99000` | Default owner for log/msg inspection |
| `C35_TEST_OWNER_IID` | no | `33000` | Owner for agent HTTP (server-enforced) |
| `C35_SERVER_URL` | no | `http://127.0.0.1:8080` | server_ai base URL |
| `C35_MCP_AGENT_KEY` | **yes** | — | Agent HTTP auth header; must match server |

## Setup

```bash
cd _/mcps/inst
npm install
npm run build
```

## Cursor MCP config

See `.agents/plugins/c35/mcp_config.json` (canonical) and run `sync_mcp_config.ps1` for Cursor.

## Source layout

| Module | Tools |
|--------|-------|
| `src/inst.ts` | `inst_list`, `inst_get`, `inst_put`, `inst_delete` |
| `src/log.ts` | `log_tail`, `trace_get` |
| `src/msg.ts` | `msg_get`, `msg_find` |
| `src/agent_http.ts` | `tool_exec`, `prompt_compose`, `prompt_run` |

Server-side RPC equivalents for inst live in `c35_mod_chat::inst_admin` via HTTP `/v1/invoke`.
