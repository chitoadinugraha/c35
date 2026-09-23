# c35-inst MCP server

Admin CRUD for `ai.inst` instruction macros. Publishes NATS `c35.inst.{id}` after put/delete so `InstCache` reloads.

## Env

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | yes | Postgres/Yugabyte connection string (`ai` schema) |
| `NATS_URL` | no | NATS server URL for cache invalidation |
| `NATS_USER` / `NATS_PASS` | no | NATS credentials |

## Setup

```bash
cd _/mcps/inst
npm install
npm run build
```

## Cursor MCP config

```json
{
  "mcpServers": {
    "c35-inst": {
      "command": "node",
      "args": ["D:/c35/_/mcps/inst/dist/index.js"],
      "env": {
        "DATABASE_URL": "postgresql://csa:...@yb-tservers.yugabyte.svc.cluster.local:5433/csa",
        "NATS_URL": "nats://nats.c35.svc.cluster.local:4222"
      }
    }
  }
}
```

## Tools

- `inst_list` — list/filter rows
- `inst_get` — get by id
- `inst_put` — upsert (id + inst body required)
- `inst_delete` — soft-delete

Server-side RPC equivalents live in `c35_mod_chat::inst_admin` via HTTP `/v1/invoke` (protobuf `ReqInst*`).
