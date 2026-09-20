# Schemas

SQL and protobuf sources for c35. Applied by `server_ai` on boot (idempotent).

## Apply order

```
1. identity.sql
2. billing.sql
3. chat.sql
4. log.sql
5. embed.sql
6. skill.sql
7. consumption.sql
8. site.sql
9. tx.sql
10. file.sql         (later)
```

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
| [site.sql](site.sql) | **locked** | Site satellites (doc, publish, product, contact, object) |
| [tx.sql](tx.sql) | **locked** | POS / transactions (id.alienai model, site_iid) |
| `file.sql` | planned | CAS blob_meta / blob_inline |
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
CREATE INDEX idx_{table}_sync ON ai.{table} (owner_iid, updated_ts);
```

Site-scoped collections:

```sql
CREATE INDEX idx_{table}_site_sync ON ai.{table} (site_iid, updated_ts);
```

### Identity

- `kind`: `user` | `team` | `bot` | `remote` | `iot` | `site`
- `type`: subtype (`windows`, `chat`, `switch`, …) — **not** encoded in kind
- `alien_id`: globally unique slug (was `handle`)

### Access

- **`identity.owner_iid`** — primary owner (user or team)
- **`identity_grant`** — all RBAC (team membership, site staff, resource share)

### Site layout

- Guest pages = block-composed **`site_draft.doc_json`** (SiteDoc)
- Catalog/CRM = **`site_product`**, **`site_contact`**, **`site_object`** (data, not layout)

See [`../docs/roadmap.md`](../docs/roadmap.md), [`../docs/site.md`](../docs/site.md).
