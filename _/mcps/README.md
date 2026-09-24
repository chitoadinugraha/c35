# c35 MCP server (`c35`)

Single project MCP for Cursor + Antigravity. v0.2.0 — inst, log, msg, prompt/tool via HTTP.

**Security:** read [`_/docs/mcp-security.md`](../docs/mcp-security.md) before enabling agent HTTP or storing credentials in config.

Global YSQL: **`yb` / `alienai-yb`** in `~/.cursor/mcp.json`.

## Config (two files — keep in sync)

| IDE | File |
|-----|------|
| Antigravity (canonical) | `.agents/plugins/c35/mcp_config.json` |
| Cursor | `.cursor/mcp.json` |

```powershell
.\_\scripts\dev\sync_mcp_config.ps1
```

See `.cursor/rules/mcp-config.mdc`.

## Setup

```powershell
cd _/mcps/inst
npm install
npm run build
```

Add to `servers/server_ai/.env.local` (see [`mcp-security.md`](../docs/mcp-security.md)):

```env
C35_MCP_AGENT_ENABLED=1
C35_MCP_AGENT_KEY=<openssl rand -hex 32>
```

Use the **same** key in MCP config env. Restart `dev_server.ps1` after server or env changes. Reload MCP in IDE.

## Env (MCP)

| Variable | Default | Purpose |
|----------|---------|---------|
| `DATABASE_URL` | required | YSQL `c35` — **do not commit** |
| `C35_DEBUG_OWNER_IID` | `99000` | Chito — log/msg defaults |
| `C35_TEST_OWNER_IID` | `33000` | Automated tests / agent HTTP owner |
| `C35_SERVER_URL` | `http://127.0.0.1:8080` | `tool_exec`, `prompt_*` |
| `C35_MCP_AGENT_KEY` | **required** | Must match server; no code fallback |

## Tools

| Tool | Description |
|------|-------------|
| `log_tail` | Tail `ai.log` **DESC** by `created_ts`; `owner_iid` default 99000; `global=true` for all owners |
| `trace_get` | Full trace for one `req_id` (ASC) |
| `msg_get` | Message + trace by `msg_id` or `req_id` |
| `msg_find` | Search messages by content |
| `tool_exec` | Cluster tool via HTTP — default **33000**, **99000** (`owner_iid` / `uid`) |
| `prompt_compose` | Inst + tool pick preview + compose trace |
| `prompt_run` | Full prompt turn + inline **trace** (`trace.lines`, `trace.trace`) |
| `inst_list` / `inst_get` / `inst_put` / `inst_delete` | `ai.inst` CRUD |

## Indexes (fast tail)

- `idx_log_owner_created_desc` — `(owner_iid, created_ts DESC, id DESC)`
- `idx_log_created_desc` — global tail without owner
- `idx_log_owner_req_created` — trace by req_id
- `idx_chat_msg_owner_created_desc` — message search

## Identities

| iid | Use |
|-----|-----|
| **33000** | Automated tests — only owner on `/v1/mcp/agent` |
| **99000** | Chito — inspect real logs/messages |
