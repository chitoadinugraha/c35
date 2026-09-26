# Platform mail (LOCKED draft — Track D1)

Status: **implemented (M2)** 2026-09-26 — `mod_mail` in `c35-server`; admin/group RPCs partial.

Platform email for c35 users and sites: personal **`{alien_id}@alienai.id`**, optional **site mailboxes**, and **customer mail domains** onboarded in Cloudflare (Email Sending + Email Routing). Implemented in Rust crate **`mod_mail`** (port from CSA `mod_mail` @ git `e34b9bf2` on `D:\csa_site_published`).

**Not** the same subsystem as HTTP custom domains (`site.domain`). See [Separation from `site.domain`](#separation-from-sitedomain).

## Reference

| Source | Path |
|--------|------|
| CSA `mod_mail` (deleted on CSA HEAD) | `git show e34b9bf2:crates/mod_mail/` |
| CSA agent notes | `e34b9bf2:.agents/mods/mail.md` |
| CSA proto (wire names) | `e34b9bf2:_/protos/mail/mail.proto` — band **20600–20699** |
| c35 DDL | [`_/schemas/mail.sql`](../schemas/mail.sql) |
| c35 identity | [`_/schemas/identity.sql`](../schemas/identity.sql) — all `owner_iid` / `site_iid` FKs |

## Architecture

```
ai.identity(kind=user)     alien_id → personal mailbox {alien_id}@alienai.id
ai.identity(kind=site)     site_iid → optional site mailbox(es)

mail.domain                CF zone registry (sending + routing flags)
mail.mailbox               address + kind (personal | site)
mail.mailbox_member        per-user read | write on site/shared mailboxes
mail.message               inbound + outbound rows per mailbox

Inbound:  CF Email Routing / Worker → HTTP webhook → insert mail.message
Outbound: ReqMailSend → queue row → SMTP (preferred) or CF Worker send_email
```

Datastore: YSQL schema **`mail`** (separate from **`site`**). Registry rows still point at **`ai.identity`** — same pattern as `site.config.site_iid`.

## Personal mailbox

- One **personal** mailbox per user: address **`{alien_id}@alienai.id`** (lowercase unique).
- Provision on first mail access or on identity create / role grant (CSA: `ensure_personal_mailbox` on `ReqMailAccountGet` and `provision_on_role_grant`) — exact hook is implementation detail in M2.
- `mail.mailbox.kind = 'personal'`, `owner_iid` = user `iid`, `site_iid` NULL.
- Domain for platform addresses: seeded row **`alienai.id`** in `mail.domain` with `sending_enabled` and `routing_enabled` true.

## Site mailbox

- `kind = 'site'`, `site_iid` → `ai.identity(id)` where `kind = 'site'`.
- `owner_iid` = site owner (denormalized for sync indexes; must match `identity.owner_iid` for that site).
- Optional `label`, `subscriber_limit` (default **1000**, enforced on broadcast/send — CSA parity).
- Members in `mail.mailbox_member`: `member_iid` + `access` **`read`** | **`write`** (maps CSA `uid` + ACL).
- Admin create/update/delete via mail admin RPCs (CSA: root / `director`); personal mailbox is not deletable.

## `mail.domain` — Cloudflare zone onboard

Customer **mail** on their own hostname (e.g. `mail.example.com` or `example.com` for addresses `@example.com`) requires the zone to exist in the Cloudflare account and to be registered in **`mail.domain`**. This is **independent** of pointing HTTP at `site.alienai.id`.

| Column / concept | Role |
|------------------|------|
| `hostname` | Apex or delegated mail domain (unique, lowercased) |
| `zone_id` | Cloudflare zone id after lookup |
| `sending_enabled` | Email Sending onboarded for the zone |
| `routing_enabled` | Email Routing / catch-all worker wired |
| `setup_error` | Last onboard failure (human-readable) |

**Admin RPCs (CSA parity):** `mail_domain_list`, `mail_domain_add`, `mail_domain_fix`.

**`domain_add` flow (port `domain.rs` + `cloudflare.rs` @ e34b9bf2):**

1. Normalize hostname; reject if not in CF account.
2. Upsert `mail.domain` row.
3. Enable **Email Sending** for the zone (API).
4. Configure **Email Routing** — catch-all → receive worker / HTTP endpoint (worker name from env, e.g. `receive_worker_name()`).
5. Persist flags + `setup_error` on partial failure; `domain_fix` re-runs failed steps.

**Env (cluster):**

- `CLOUDFLARE_API_TOKEN` — zone read, Email Routing, Email Sending as needed.
- `MAIL_INBOUND_SECRET` — webhook HMAC (see inbound).
- Outbound: `MAIL_SMTP_*` and/or `MAIL_OUTBOUND_WORKER_URL` (see outbound).

Platform zone **`alienai.id`** is seeded in SQL; ops still run one-time CF Email Sending onboard for the apex (CSA script: `setup_cf_email_sending.ps1`).

## Inbound webhook

HTTP endpoint: **`POST /v1/mail/inbound`** on `c35-server` (CSA was `POST /a/mail/inbound`):

- **Auth:** `MAIL_INBOUND_SECRET` — HMAC-SHA256 of body in `X-Mail-Signature` (`sha256=<hex>`) or `Authorization: Bearer <secret>` (`verify_inbound_signature`).
- **JSON body:** `from`, `to`, `subject`, `text` / `html`, optional `message_id` for dedup → `mail.message.external_id`.
- **Attachments (optional):** `[{ "name", "mime", "data" }]` base64 — store via `mod_file` CAS, write `attachments_json` array `{ path, name, mime, size }` (paths `/fs/{blake3}`).
- **Routing:** Resolve `to` → mailbox by `lower(address)`; insert `direction = 'in'`, `status = 'received'`, set `read_at` NULL.
- **Limits (v1):** max **10** attachments, **5 MB** each (CSA inbound).

Emit event `mail.message.received` for push/offline (CSA `events.rs`).

## Outbound

`ReqMailSend` (and broadcast) inserts `direction = 'out'`, `status = 'queued'`, then relay:

1. **`MAIL_SMTP_HOST`** set → SMTP (lettre), TLS per `MAIL_SMTP_*`. Preferred for arbitrary recipients. Cloudflare Email Service: `smtp.mx.cloudflare.net:465`, user **`api_token`** (literal username), password = API token with **Email Sending: Edit**.
2. Else **`MAIL_OUTBOUND_WORKER_URL`** → Worker `send_email` (verified routing destinations only).
3. Else `status = 'failed'`, error `outbound not configured`.

From address must use a domain present in `mail.domain` with sending enabled. Personal send uses caller's mailbox address (`{alien_id}@alienai.id`).

Attachments: client uploads to `/fs/{hash}` first; server validates paths exist in file store before send.

## Separation from `site.domain`

| | **HTTP custom domain** (`site.domain`) | **Platform mail** (`mail.*`) |
|---|----------------------------------------|------------------------------|
| Purpose | Serve guest site HTML on customer `Host` | Receive/send email on customer or platform domains |
| DNS proof | CNAME/A to **`site.alienai.id`** (grey) | Zone in Cloudflare + CF Email Routing/Sending APIs |
| Code | `mod_site` — verify RPC, `tls_sync`, cert-manager | `mod_mail` — domain onboard, webhook, SMTP/worker |
| DB | `site.domain.hostname`, `verified_ts`, `tls_status` | `mail.domain`, `mail.mailbox`, `mail.message` |
| Orange `alienai.id` | Guest paths `/{alien_id}/…` only | Inbound `*@alienai.id` via CF routing to webhook |

A customer can verify HTTP without mail onboard, and vice versa. Product UX may link the two later; **no shared verify RPC** in v1.

## Access control (c35 mapping)

CSA used `identity_user` + global roles `partner`, `director`, `root`. c35 maps to:

- **Use mail (inbox/send):** authenticated user with personal mailbox or `mail.mailbox_member` row (CSA: partner or root for first provision).
- **Mailbox admin:** global role (e.g. `director`) or platform admin flag — TBD in M2 (`access.rs` port).
- **Domain admin:** same as mailbox admin for `mail_domain_*`.

Fine-grained site staff roles (`identity_grant` on `site_iid`) may grant mailbox membership without site HTTP manage — membership is explicit in `mail.mailbox_member`.

## Wire / proto (future M1)

Port message names from CSA `mail.proto` with c35 field renames:

- `uid` → caller / `owner_iid` / `member_iid`
- `site_id` → `site_iid`
- New `mail.proto` under `_/schemas/proto/c35/` — **do not** reuse CSA pb numbers blindly if wire conflicts.

## Attachments JSON

```json
[
  { "path": "/fs/<64-char-blake3-hex>", "name": "invoice.pdf", "mime": "application/pdf", "size": 48291 }
]
```

## Out of scope (this spec)

- `mail_group` mailing lists (CSA table — later wave if needed).
- Legacy `mail_account` table (replaced by personal `mail.mailbox`).
- Domain registrar purchase flow.
- Storing raw MIME in YB (bodies in row text fields + JSON attachments only).

## Verification (after M1+)

```powershell
cd servers
cargo build -p server_ai
cargo test -p c35_mod_mail
```

E2E: external mail to `{alien_id}@alienai.id` → webhook → row in app; send out via SMTP smoke script.
