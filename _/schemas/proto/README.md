# c35 protobuf

Wire contracts for Flutter client ↔ `server_ai`. SQL remains source of truth in `_/schemas/*.sql`.

## Layout

```
proto/c35/
  types.proto         — Empty, Err
  identity.proto      — IdentityProfile, NavCounts, IdentityGrant
  session.proto       — ReqSessionInit, ResSessionInit
  chat.proto          — Chat, ChatMember, ChatMsg, prompt, stop, send
  billing.proto       — BillingAccount, top-up, NATS push shapes
  log.proto           — Log, LogPush
  skill.proto         — Skill, catalog, teach/automation
  task.proto          — Task, task_run, NATS act/ev, TaskRunPush
  remote.proto        — WebRTC signaling, RemoteInputEvent
  consumption.proto   — Meals, nutrition, water
  hint.proto          — HintItem, HintCatalog, ReqHintTouch (Home empty-state chips)
  site.proto          — SiteDoc blocks, draft, publish, product, contact, object
  collection.proto    — TableDef, ReqCollectionDefList (UITable metadata)
  tx.proto            — POS transactions (id.alienai → site.tx_* tables)
  sync.proto          — ReqSync, ResSync, SyncPush
  wire.proto          — WsReq, WsRes, InvokeReq, InvokeRes
```

## Codegen

Rust (`prost`) and Dart (`protoc_plugin`) from repo root once `servers/crates/proto` exists:

```bash
protoc -I _/schemas/proto --dart_out=clients/app/lib/c/pb _/schemas/proto/c35/*.proto
```

## Conventions

| Wire | SQL |
|------|-----|
| `int64 *_ms` | `TIMESTAMPTZ` |
| `int64 iid` | `BIGINT` snowflake |
| `deleted_ts_ms = 0` | `deleted_ts IS NULL` |
| `*_json` string fields | `JSONB` columns |
| `SiteDoc` / `SiteBlock` | `site.draft.doc_json` |
| `TableDef.collection` | `site.product`, `site.contact`, … |

## Connect flow

```
WS /v1/ws?since=<ms>&jwt=...&locale=...&tz=...
  → WsReq.session_init
  ← WsRes.session_init (profile + billing + nav + prompt inbox + sync delta)
```

## Docs

- [site.md](../../docs/site.md)
- [tx.md](../../docs/tx.md)
- [ui.md](../../docs/ui.md)
- [roadmap.md](../../docs/roadmap.md)
