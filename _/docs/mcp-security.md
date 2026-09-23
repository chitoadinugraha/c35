# MCP security (REMINDER)

**Read before enabling MCP agent HTTP or committing MCP config.**

See also [mcps/README.md](../mcps/README.md) and `.cursor/rules/mcp-config.mdc`.

## Threat model

The c35 MCP stack has two layers:

| Layer | Runs where | Risk |
|-------|------------|------|
| **Node `c35` MCP** (`_/mcps/inst`) | Developer IDE only | Direct YSQL read/write when `DATABASE_URL` is set |
| **`/v1/mcp/agent` on server_ai** | Cluster HTTP | Executes cluster tools as a fixed test user |

Neither layer uses end-user JWT auth. Treat both as **privileged operator tooling**, not user-facing API.

---

## `/v1/mcp/agent` (server_ai)

Route: `POST /v1/mcp/agent`  
Header: `X-C35-Mcp-Key: <C35_MCP_AGENT_KEY>`

### Defaults (release builds)

| Env | Release | Debug dev |
|-----|---------|-----------|
| `C35_MCP_AGENT_ENABLED` | **off** unless `1` / `true` | **on** (debug_assertions) |
| `C35_MCP_AGENT_KEY` | required, **≥32 chars**, not a known weak value | required; weak dev keys rejected too |

Known weak keys are always rejected: `dev-mcp-agent-key`, `dev-mcp-agent-change-me`.

Key comparison uses constant-time equality (`subtle`).

### Owner lock (all actions)

Every action (`tool_exec`, `prompt_compose`, `prompt_run`) runs **only** as **`owner_iid = 33000`** (Automated Tester).  
Requests with any other `owner_iid` return **403 Forbidden**.

This prevents MCP key holders from impersonating real users (99000, etc.).

### Production checklist

1. Set `C35_MCP_AGENT_ENABLED=1` **only** if you need agent HTTP in that environment.
2. Generate a strong key: `openssl rand -hex 32`
3. Set the same key in server_ai env and local MCP config (`C35_MCP_AGENT_KEY`).
4. Prefer **cluster-internal** network policy — do not expose `/v1/mcp/agent` on public ingress unless required.
5. Rotate key if leaked; treat like a service account secret.

---

## Node c35 MCP (IDE)

### Secrets in config files

`.agents/plugins/c35/mcp_config.json` and `.cursor/mcp.json` often hold:

- `DATABASE_URL` (production YSQL)
- `C35_MCP_AGENT_KEY`

**Do not commit real credentials.** Use local overrides or secret injection. Rotate DB password if configs were shared or pushed.

### Direct DB tools

| Tool | Risk |
|------|------|
| `inst_put` / `inst_delete` | Writes `ai.inst` for all users |
| `log_tail` + `global=true` | Cross-user logs |
| `trace_get` without `owner_iid` | Trace for any `req_id` |
| `msg_find` / `msg_get` | Default owner **99000** — real user data |

Use **`owner_iid=33000`** for automated tests; use **99000** only when intentionally inspecting your own chats.

### MCP client requirements

- `C35_MCP_AGENT_KEY` — **required** (no fallback in code)
- `tool_exec` sends `tool_name` + `args_json` (server contract)
- Owner is always test **33000** from the client; server enforces the same

---

## Related identities

| iid | Use |
|-----|-----|
| **33000** | Automated tests — only owner allowed on `/v1/mcp/agent` |
| **99000** | Chito — MCP log/msg inspection defaults |

See `.cursor/rules/agent-debug.mdc` and `.cursor/rules/automated-tester.mdc`.

---

## When expense / chat features ship

User-facing expense and consumption paths use normal session auth (`ctx.owner_iid`).  
They do **not** depend on MCP agent HTTP. Safe to deploy without enabling `/v1/mcp/agent`.
