# Schemas

SQL and protobuf sources for c35. Applied when the **schema bundle hash** changes (see [`_/docs/schema-migrate.md`](../docs/schema-migrate.md)).

## Apply order

Registered in `servers/crates/store/src/schema.rs` (`SCHEMA_APPLY_ORDER`). On boot, `server_ai` calls `migrate_startup` (skip when `ai.config` `c35.schema_version` matches). Force apply: `cd servers && cargo run -p c35_store --bin c35_migrate -- apply` or `.\_\scripts\dev\migrate_db.ps1`.

```
1. identity.sql
2. mail.sql           ← creates YSQL schema mail (requires identity.sql)
3. billing.sql
4. chat.sql
5. prompt_run.sql    ← durable AI prompt job queue (JetStream worker)
6. asset_tag.sql
7. log.sql
8. embed.sql
9. data_source.sql
10. inst.sql
11. topic.sql
12. mention.sql
13. translation.sql
14. hint.sql
15. memory.sql
16. skill.sql
17. task.sql
18. consumption.sql
19. object_normalizer.sql
20. site.sql         ← creates YSQL schema site
21. tx.sql           ← site.tx_* (requires site.sql)
22. file.sql
23. drive.sql         ← owner drive path index (requires file.sql / CAS)
24. channel.sql
25. config.sql
```

One-time data migrations live in `_/schemas/migrations/` — run manually when upgrading legacy DBs (not on every boot).

## YSQL schema layout

| Schema | Contents |
|--------|----------|
| **`ai`** | Platform: identity, grants, chat, billing, log, skill, … |
| **`mail`** | Platform mail: domain (CF onboard), mailbox, message |
| **`site`** | Site payload + POS: config, draft, product, tx, … |
| **`file`** | CAS blobs (later) |

Site **registry** stays in `ai.identity(kind=site)` — `site.*` tables FK to `ai.identity(id)`.

## Files

| File | Status | Description |
|------|--------|-------------|
| [identity.sql](identity.sql) | **locked** | Identity, grants, auth, referral |
| [mail.sql](mail.sql) | **draft** | `mail.*` — domains, mailboxes, messages |
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
| [drive.sql](drive.sql) | **locked** | Owner drive path index (`ai.drive_file`) |
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
