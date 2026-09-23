# Schemas

SQL and protobuf sources for c35. Applied by `server_ai` on boot (idempotent).

## Apply order

Applied by `c35_store::migrate_apply` on `server_ai` boot and via `.\_\scripts\dev\migrate_db.ps1`.

```
1. identity.sql
2. billing.sql
3. chat.sql
4. prompt_run.sql    ← durable AI prompt job queue (JetStream worker)
5. asset_tag.sql
6. log.sql
7. embed.sql
8. inst.sql
9. topic.sql
10. mention.sql
11. translation.sql
12. hint.sql
13. memory.sql
14. skill.sql
15. task.sql
16. consumption.sql
17. object_normalizer.sql
18. site.sql         ← creates YSQL schema site
19. tx.sql           ← site.tx_* (requires site.sql)
20. file.sql
21. channel.sql
22. config.sql
```

One-time data migrations live in `_/schemas/migrations/` — run manually when upgrading legacy DBs (not on every boot).

## YSQL schema layout

| Schema | Contents |
|--------|----------|
| **`ai`** | Platform: identity, grants, chat, billing, log, skill, … |
| **`site`** | Site payload + POS: config, draft, product, tx, … |
| **`file`** | CAS blobs (later) |

Site **registry** stays in `ai.identity(kind=site)` — `site.*` tables FK to `ai.identity(id)`.

## Files

| File | Status | Description |
|------|--------|-------------|
| [identity.sql](identity.sql) | **locked** | Identity, grants, auth, referral |
| [billing.sql](billing.sql) | **locked** | Wallet, quota, top-up, reservation, dedupe |
| [chat.sql](chat.sql) | **locked** | Chat, member, messages (prompt + bot_peer; direct deferred) |
| [log.sql](log.sql) | **locked** | Unified audit + billing trace |
| [embed.sql](embed.sql) | **locked** | LLM embed dedupe cache (`ai.embed_cache`) |
| [skill.sql](skill.sql) | **locked** | Skill, steps, secrets, catalog |
| [consumption.sql](consumption.sql) | **locked** | Food log, nutrition items, water, prefs |
| [prompt_run.sql](prompt_run.sql) | **locked** | Durable prompt turn jobs (queue, checkpoint, subagent runs) |
| [hint.sql](hint.sql) | **locked** | Home hints: catalog, user_asset_touch, hint_bundle |
| [object_normalizer.sql](object_normalizer.sql) | **locked** | Product/expense taxonomy DAG (normalizer nodes + aliases) |
| [site.sql](site.sql) | **locked** | `site.*` — doc, publish, render, catalog, domain |
| [tx.sql](tx.sql) | **locked** | `site.tx_*` — POS (id.alienai model) |
| [file.sql](file.sql) | **locked** | CAS: inline + S3 + variants |
| [`proto/`](proto/) | **locked** | Protobuf wire contracts (`c35/*.proto`) |

## Conventions (LOCKED)

### Syncable rows

Every syncable table includes:

```sql
created_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
deleted_ts  TIMESTAMPTZ          -- NULL = live; set = tombstone
```

### Indexes

Owner-scoped collections:

```sql
CREATE INDEX idx_{table}_owner_sync ON site.{table} (owner_iid, updated_ts);
-- or ai.{table} for platform tables
```

Site-scoped collections:

```sql
CREATE INDEX idx_{table}_site_sync ON site.{table} (site_iid, updated_ts);
```

### Identity

- `kind`: `user` | `team` | `bot` | `remote` | `iot` | `site`
- `type`: subtype (`windows`, `chat`, `switch`, …) — **not** encoded in kind
- `alien_id`: globally unique slug (was `handle`)

### Access

- **`identity.owner_iid`** — primary owner (user or team)
- **`identity_grant`** — all RBAC (team membership, site staff, resource share)

### Site layout

- Guest pages = block-composed **`site.draft.doc_json`** (SiteDoc)
- Catalog/CRM = **`site.product`**, **`site.contact`**, **`site.object`**
- Admin UI = **UITable** driven by [`collection.proto`](proto/c35/collection.proto)

See [`../docs/roadmap.md`](../docs/roadmap.md), [`../docs/site.md`](../docs/site.md).
