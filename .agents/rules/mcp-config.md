---
description: Keep Cursor and Antigravity MCP configs in sync when editing c35 MCP servers
alwaysApply: true
---

# c35 MCP config (Cursor + Antigravity)

Mirrored for Cursor: [`.cursor/rules/mcp-config.mdc`](../../.cursor/rules/mcp-config.mdc)

**Security:** [`_/docs/mcp-security.md`](../../_/docs/mcp-security.md) — do not commit `DATABASE_URL` or weak MCP keys.

## Two files — both must stay aligned

| IDE | File | Path style |
|-----|------|------------|
| **Antigravity** (canonical) | `.agents/plugins/c35/mcp_config.json` | Absolute `D:/c35/...` for `inst` dist |
| **Cursor** | `.cursor/mcp.json` | `${workspaceFolder}/...` for repo-relative paths |

Antigravity reads the plugin `mcp_config.json`. Cursor reads `.cursor/mcp.json` only — **not** the Antigravity file.

There is **no single auto-sync** today. Editing one without the other breaks one IDE.

## When you change MCP config

1. Edit **`.agents/plugins/c35/mcp_config.json`** first (canonical).
2. Run sync script:

```powershell
.\_\scripts\dev\sync_mcp_config.ps1
```

3. Or manually mirror the same `mcpServers` keys/env into `.cursor/mcp.json`, swapping `D:/c35` → `${workspaceFolder}`.
4. Reload MCP in both IDEs (Settings → Tools & MCP).

## Server naming

| Key | Role |
|-----|------|
| **`c35`** | Project MCP — c35 tools (`inst_*` today; prompt/msg/trace later). One server, many tools. |
| **`yb` / `alienai-yb`** | Global cluster YB MCP (`~/.cursor/mcp.json`) — generic SQL, any DB |

Do not add a second project YB server unless `c35` grows its own YSQL helpers.

## Build after TS changes

```powershell
cd _/mcps/inst
npm install
npm run build
```

See [`_/mcps/README.md`](../../_/mcps/README.md).
