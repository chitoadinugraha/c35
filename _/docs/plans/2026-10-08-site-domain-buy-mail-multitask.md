# Site editor domains: buy, verify, email — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline.
>
> **Specs (read first, then revise in D0 before code):** [`spec.md`](../../../spec.md) · [`_/docs/site.md`](../../../_/docs/site.md) · [`_/docs/mail.md`](../../../_/docs/mail.md) · [`_/docs/billing.md`](../../../_/docs/billing.md)

**Goal:** Site Settings domains match the CSA editor (cards, Buy, Add, unverified 24h slot, Verify, HTTPS), and a bought domain is registered on Cloudflare, paid from the owner's wallet, then usable for site email.

**Architecture:**

- HTTP custom domains stay in `site.domain` + `mod_site` (`site_domain_verify`, `dns_cname_points_to`, `tls_sync`). CNAME target stays **`site.alienai.id`** (grey).
- **Buy** is a new registrar path: Cloudflare Registrar search/check/register using `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from the environment only. No token or account id defaults in source.
- **Charge** debits `ai.billing_wallet` in the registrar quote currency before any Cloudflare register call. No FX conversion. One currency in the UI. Registration failure credits the same wallet back.
- **Email** stays in `mail.domain` / `mod_mail`. Bought domains onboard Email Sending + Routing after DNS verify and get one site mailbox `{site.alien_id}@{hostname}`. Bring-your-own hostnames stay HTTP-only unless that zone is already in the Cloudflare account.

**Tech stack:** Rust `mod_site`, `mod_mail`, `mod_billing`; protobuf `site.proto` + `wire.proto`; YSQL `site.domain` + `site.domain_order`; Flutter site Settings.

## Global constraints

- Revise `site.md`, `mail.md`, and `billing.md` in D0 before behavior that contradicts those docs lands.
- Guest URLs stay `https://alienai.id/{alien_id}/…`. Custom host is a separate Host header.
- One verified hostname maps to one site (`uq_site_domain_hostname`).
- TLS private keys stay in Kubernetes. `site.domain` stores `tls_status` / errors only.
- Wallet debit uses the quote currency only (`USD` if Cloudflare quotes USD). Do not call `billing_fx_rate`. Do not show a second currency in the buy dialog.
- Cloudflare credentials come from env. Never copy tokens out of `D:\csa_site_published`.
- Bought rows are not deleted by the 24-hour pending sweep. Detach does not refund and does not delete the Cloudflare registration.
- Build from `servers/`: `cargo build -p server_ai`. Tests: `cargo test -p c35_mod_site`, `cargo test -p c35_mod_billing`, `cargo test -p c35_mod_mail` for crates touched. Flutter: `._\scripts\dev\verify_flutter_app.ps1`. UTF-8: `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Proto: `._\scripts\protoc.ps1` after `site.proto` / `wire.proto` edits.
- Do not commit unless the user asks.

## Product rules (locked)

| Case | DNS | Pending TTL | Email |
|------|-----|-------------|--------|
| **Bought** (`source=bought`) | We create a grey CNAME to `site.alienai.id` on the new zone | Never expires | After `verified_ts` is set: `mail.domain` onboard + mailbox `{alien_id}@{hostname}` |
| **Bring your own** (`source=byo`) | User CNAMEs to `site.alienai.id` (existing verify) | One unverified row, dropped 24h after `created_ts` | On verify, onboard only if Cloudflare already has the zone. Otherwise `mail_status` stays empty |

Buy sequence:

1. Search / check (no charge).
2. User confirms. Server checks the price again.
3. Insert `site.domain_order` and debit the wallet in one transaction (`status=charged`). If balance is short, stop with `insufficient_balance`. Do not call Cloudflare.
4. `POST /accounts/{account_id}/registrar/domains`. On failure, set `status=refunded`, credit the wallet, return the error. No `site.domain` row.
5. On success, set grey CNAME, insert `site.domain` (`source=bought`), set order `status=registered`, run existing verify. If verify succeeds, onboard mail. If DNS has not propagated, leave unverified; the Verify button retries mail onboard later.

## Explicitly out of scope

| Item | Notes |
|------|--------|
| Refund or cancel a Cloudflare registration from the editor | Detach only removes the c35 row |
| FX from USD into an IDR wallet | User tops up the quote currency |
| Mail for a BYO hostname whose zone is not in our Cloudflare account | HTTP + TLS only |
| CSA "Coming soon" buy stub | c35 completes registration |
| Wildcard domains | Future |

## Reference

| What | Where |
|------|--------|
| CSA domain cards | `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_custom_domain_section.dart` |
| CSA buy dialog (search UI only; button is Coming soon) | `D:\csa_site_published\clients\app\lib\widgets\site\io_custom_domain_buy_dialog.dart` |
| CSA registrar search/check | `D:\csa_site_published\crates\mod_site\src\cloudflare_registrar.rs` |
| c35 verify + TLS | `servers/crates/mod_site/src/site_domain.rs`, `dns_verify.rs`, `tls_sync.rs` |
| c35 Settings domains (table to replace) | `clients/app/lib/widgets/sites/editor/ui_site_settings_editor.dart` |
| Mail onboard (admin-gated today) | `servers/crates/mod_mail/src/domain.rs` `add_admin` |
| Wallet rows | `ai.billing_wallet` in `_/schemas/billing.sql` |

---

## Multitask map

```
WAVE 1 — Docs + schema (parallel)
  D0  Revise site.md, mail.md, billing.md
  S1  site.domain columns + site.domain_order

WAVE 2 — Contracts + isolated libraries (after S1; parallel)
  P1  Proto + protoc (search, check, buy)
  B1  Wallet debit + refund
  R1  Registrar search + check (no register)

WAVE 3 — Server behavior (after WAVE 2; H1 and M1 parallel, R2 after B1+R1+P1)
  H1  BYO 24h slot + source on list/put
  M1  Site-scoped mail onboard + site mailbox
  R2  Buy orchestration + verify hook

WAVE 4 — Editor (after P1 dart + R2 wire)
  F1  CSA-style domain section + buy dialog

WAVE 5 — Verify
  V1  cargo test + flutter verify on touched crates
```

### Agent assignments

| Wave | Track | Files only this track may edit |
|------|-------|--------------------------------|
| 1 | D0 | `_/docs/site.md`, `_/docs/mail.md`, `_/docs/billing.md` |
| 1 | S1 | `_/schemas/site.sql`, `_/schemas/migrations/site_domain_buy_v1.sql` |
| 2 | P1 | `_/schemas/proto/c35/site.proto`, `_/schemas/proto/c35/wire.proto`, generated pb |
| 2 | B1 | `servers/crates/mod_billing/src/domain_purchase.rs`, `mod_billing/src/lib.rs`, billing test |
| 2 | R1 | `servers/crates/mod_site/src/cloudflare_registrar.rs`, `mod_site/src/lib.rs`, registrar unit test |
| 3 | H1 | `servers/crates/mod_site/src/site_domain.rs`, `servers/crates/mod_site/tests/domain_pending_test.rs` |
| 3 | M1 | `servers/crates/mod_mail/src/domain.rs`, `mailbox.rs`, `lib.rs` |
| 3 | R2 | `servers/crates/mod_site/src/site_domain_buy.rs`, `wire_ws` session match arms, `mod_site/src/lib.rs` exports |
| 4 | F1 | `clients/app/lib/widgets/sites/editor/ui_site_domain_section.dart`, `io_site_domain_buy_dialog.dart`, `ui_site_settings_editor.dart`, `clients/app/lib/c/site/site_api.dart`, `clients/app/lib/c/site/site_domain.dart`, `clients/app/assets/translations/en.json`, `id.json` |

R2 may call B1 and M1. It must not reimplement wallet SQL or Cloudflare Email Routing.

---

# WAVE 1

## Track D0 — Docs

Update the three locked docs so later tracks match them.

`_/docs/site.md` Custom domains section, add:

- `source`: `byo` (default) or `bought`.
- BYO: at most one unverified hostname; `site_domain_list` deletes unverified `byo` rows older than 24 hours.
- Bought: registrar purchase, platform sets CNAME to `site.alienai.id`, row is kept until the user removes it.
- RPC list adds `ReqSiteDomainSearch`, `ReqSiteDomainCheck`, `ReqSiteDomainBuy`.

`_/docs/mail.md`:

- Replace the line that says registrar purchase is out of scope.
- Replace "no shared verify RPC" with: HTTP verify stays `site_domain_verify`. After a **bought** hostname becomes verified, `mod_site` calls `mod_mail` onboard. BYO onboards only when the zone is already in Cloudflare.
- Mailbox created: `{alien_id}@{hostname}`, kind `site`.

`_/docs/billing.md` wallets section, add a short subsection **Domain purchase**:

- Debit `billing_wallet` for `(owner_iid, quote_currency)` by the registrar amount.
- Insufficient balance returns `insufficient_balance` and does not register.
- Cloudflare register failure credits the same amount back.
- FX rates are not used for this charge.

## Track S1 — Schema

**Files:**

- Modify: `_/schemas/site.sql` (`site.domain` block)
- Create: `_/schemas/migrations/site_domain_buy_v1.sql`

`site.domain` gains:

```sql
source        VARCHAR(16) NOT NULL DEFAULT 'byo',  -- byo | bought
mail_status   VARCHAR(16) NOT NULL DEFAULT '',     -- '' | pending | ready | failed
mail_error    TEXT NOT NULL DEFAULT ''
```

Check constraint: `source IN ('byo', 'bought')`.

New table:

```sql
CREATE TABLE IF NOT EXISTS site.domain_order (
    id           BIGINT PRIMARY KEY,
    site_iid     BIGINT NOT NULL REFERENCES ai.identity(id),
    owner_iid    BIGINT NOT NULL REFERENCES ai.identity(id),
    hostname     VARCHAR(253) NOT NULL,
    currency     CHAR(3) NOT NULL,
    amount       NUMERIC(18, 4) NOT NULL,
    status       VARCHAR(16) NOT NULL, -- charged | registered | refunded | failed
    cf_zone_id   VARCHAR(64) NOT NULL DEFAULT '',
    error        TEXT NOT NULL DEFAULT '',
    created_ts   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Index: `(site_iid, created_ts DESC)`.

Migration file is the same `ALTER` / `CREATE` with `IF NOT EXISTS` so it can run on a live database. Do not drop existing domain rows.

---

# WAVE 2

## Track P1 — Proto

**`SiteDomain` new fields** (do not renumber 1-10 or 20-22):

```protobuf
string source = 11;       // byo | bought
string mail_status = 12;  // empty | pending | ready | failed
string mail_error = 13;
```

**New messages** at the end of the domain section in `site.proto`:

```protobuf
message SiteDomainSearchHit {
  string name = 1;
  bool registrable = 2;
  string reason = 3;
  string registration_cost = 4;
  string currency = 5;
}

message ReqSiteDomainSearch {
  int64 site_iid = 1;
  string query = 2;
}
message ResSiteDomainSearch {
  repeated SiteDomainSearchHit hits = 1;
}

message ReqSiteDomainCheck {
  int64 site_iid = 1;
  repeated string hostnames = 2;
}
message ResSiteDomainCheck {
  repeated SiteDomainSearchHit hits = 1;
}

message ReqSiteDomainBuy {
  int64 site_iid = 1;
  string hostname = 2;
}
message ResSiteDomainBuy {
  SiteDomain domain = 1;
  string error = 2;
}
```

**`wire.proto` `WsReq.body` / `WsRes.body`** use the next free field number **206** (205 is presence location):

| Field | Req | Res |
|-------|-----|-----|
| 206 | `ReqSiteDomainSearch site_domain_search` | `ResSiteDomainSearch site_domain_search` |
| 207 | `ReqSiteDomainCheck site_domain_check` | `ResSiteDomainCheck site_domain_check` |
| 208 | `ReqSiteDomainBuy site_domain_buy` | `ResSiteDomainBuy site_domain_buy` |

Run `._\scripts\protoc.ps1`. Commit generated Dart/Rust only as part of this track's files.

`site_domain_list` / `put` row mapping must read and write `source`, `mail_status`, `mail_error` once S1 columns exist. That mapping is Track H1 if P1 only changes proto. P1 stops at generated types.

## Track B1 — Wallet debit and refund

**Create** `servers/crates/mod_billing/src/domain_purchase.rs`. Export from `lib.rs`.

```rust
pub struct DomainCharge {
    pub order_id: i64,
    pub currency: String,
    pub amount: f64,
}

pub async fn domain_purchase_debit(
    pool: &PgPool,
    order_id: i64,
    owner_iid: i64,
    site_iid: i64,
    hostname: &str,
    currency: &str,
    amount: f64,
) -> Result<DomainCharge, String>;

pub async fn domain_purchase_refund(pool: &PgPool, order_id: i64) -> Result<(), String>;

pub async fn domain_purchase_mark(
    pool: &PgPool,
    order_id: i64,
    status: &str,
    cf_zone_id: &str,
    error: &str,
) -> Result<(), String>;
```

`domain_purchase_debit` in one transaction:

1. Reject unless `amount > 0` and `currency` matches `^[A-Z]{3}$`.
2. `UPDATE ai.billing_wallet SET balance = balance - $amount WHERE owner_iid = $1 AND currency = $2 AND deleted_ts IS NULL AND balance >= $amount`.
3. If no row updated, return `Err("insufficient_balance")`.
4. `INSERT INTO site.domain_order (..., status) VALUES (..., 'charged')`.

`domain_purchase_refund`: if status is `charged`, add `amount` back to that wallet and set status `refunded`. If status is already `refunded`, return Ok. If status is `registered`, return `Err("already_registered")`.

Unit-test the currency regex and the "already refunded / already registered" status guards as pure functions if the SQL path needs a database. Name the pure helper `domain_purchase_refund_allowed(status) -> Result<(), &'static str>`.

## Track R1 — Registrar search and check

**Create** `servers/crates/mod_site/src/cloudflare_registrar.rs`.

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct DomainHit {
    pub name: String,
    pub registrable: bool,
    pub reason: String,
    pub registration_cost: String,
    pub currency: String,
}

pub fn registrar_config() -> Result<(String, String), String>; // (token, account_id) from env
pub async fn cf_domain_search(query: &str, limit: u32) -> Result<Vec<DomainHit>, String>;
pub async fn cf_domain_check(domains: &[String]) -> Result<Vec<DomainHit>, String>;
```

- `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. Missing either returns `cloudflare registrar is not configured`.
- Search: `GET https://api.cloudflare.com/client/v4/accounts/{account_id}/registrar/domain-search?query=`.
- Check: `POST .../registrar/domain-check` with the domain list.
- Map Cloudflare availability + price into `DomainHit`. Unavailable domains stay in the list with `registrable=false`.
- Do not implement register in this track.

Test: `registrar_config` fails when either env var is unset (save/restore env in the test).

---

# WAVE 3

## Track H1 — Pending BYO slot

**Modify** `site_domain.rs`.

- `site_domain_list`: before returning, soft-delete (`deleted_ts = NOW()`) rows for that site where `source = 'byo'` AND `verified_ts IS NULL` AND `created_ts < NOW() - INTERVAL '24 hours'`.
- `site_domain_put`: new rows get `source = 'byo'` unless the caller passes `source = 'bought'` (only the buy track sets bought). Reject a new unverified `byo` when another unverified `byo` exists for the site: error `pending_domain_exists`.
- Select lists include `source`, `mail_status`, `mail_error`.
- `rows::domain_from_row` fills the new proto fields.

**Test** `servers/crates/mod_site/tests/domain_pending_test.rs` (pure, no DB):

```rust
fn byo_unverified_expires(created_age_hours: i64, source: &str, verified: bool) -> bool;

#[test]
fn bought_unverified_does_not_expire() {
    assert!(!byo_unverified_expires(48, "bought", false));
}
#[test]
fn byo_unverified_expires_after_24h() {
    assert!(byo_unverified_expires(25, "byo", false));
    assert!(!byo_unverified_expires(23, "byo", false));
    assert!(!byo_unverified_expires(48, "byo", true));
}
```

Export `byo_unverified_expires` from `site_domain.rs` (or `domain_pending.rs` if `site_domain.rs` should not grow). List SQL uses the same rule.

## Track M1 — Mail onboard for a site

Add to `mod_mail`:

```rust
pub async fn onboard_zone_for_site(pool: &PgPool, hostname: &str) -> Result<MailOnboard, String>;
pub async fn ensure_site_mailbox(
    pool: &PgPool,
    owner_iid: i64,
    site_iid: i64,
    address: &str,
) -> Result<i64, String>;
```

`MailOnboard`: `{ mail_status: String, mail_error: String }` with status `ready` or `failed`.

`onboard_zone_for_site`:

- Same Cloudflare Email Sending + Routing steps as `domain::add_admin`.
- Do **not** require `is_mail_admin`.
- If the zone is not in the account, return `mail_status=failed` and `mail_error` explaining the zone is not in Cloudflare. Do not create a mailbox in that case.
- Idempotent when `mail.domain` already has the hostname and both flags are true: return `ready`.

`ensure_site_mailbox`:

- Insert `mail.mailbox` kind `site` for `address` if missing.
- `owner_iid` is the site owner. `site_iid` is the site.
- Do not require mail admin. Refuse addresses whose domain part is not in `mail.domain`.

```rust
pub async fn zone_in_cloudflare(hostname: &str) -> Result<bool, String>;
```

Used by the buy/verify hook so BYO can skip mail when the zone is absent. Lookup: Cloudflare `GET /zones?name={apex}`.

## Track R2 — Buy + verify hook

**Create** `servers/crates/mod_site/src/site_domain_buy.rs`.

```rust
pub async fn site_domain_search(pool, caller_iid, req: ReqSiteDomainSearch) -> Result<ResSiteDomainSearch>;
pub async fn site_domain_check(pool, caller_iid, req: ReqSiteDomainCheck) -> Result<ResSiteDomainCheck>;
pub async fn site_domain_buy(pool, caller_iid, req: ReqSiteDomainBuy, out_tx) -> Result<ResSiteDomainBuy>;
pub async fn domain_mail_after_verify(pool, site_iid, domain_id) -> Result<()>;
```

Search and check: `site_grant_check(..., manage=true)`, then R1.

`site_domain_buy`:

1. Manage grant. Normalize hostname. Reject platform hosts (`host_is_primary`).
2. `cf_domain_check(&[hostname])`. Require `registrable` and a parseable cost `> 0`.
3. `domain_purchase_debit(...)`.
4. Register:

```rust
pub async fn cf_domain_register(hostname: &str) -> Result<CfRegistration, String>;
pub struct CfRegistration { pub zone_id: String }
```

`POST https://api.cloudflare.com/client/v4/accounts/{account_id}/registrar/domains` JSON `{ "name": hostname, "auto_renew": true, "privacy": true }`. Read `zone_id` from the result, or `GET /zones?name=` if the register body omits it.

5. Failure: `domain_purchase_refund`. Response `error` is the Cloudflare message. `domain` empty.
6. Success: create grey CNAME (`proxied: false`, content from `domain_cname_target()`, name = hostname). `domain_purchase_mark(..., "registered", zone_id, "")`.
7. Insert `site.domain` with `source=bought`, `verified_ts` null, `tls_status=pending`.
8. Call existing `site_domain_verify` logic (internal, not a second grant check). Then `domain_mail_after_verify`.

`domain_mail_after_verify` (also called at the end of `site_domain_verify` when `dns_verified` becomes true):

- Load `source`.
- `bought`: `onboard_zone_for_site`. On `ready`, `ensure_site_mailbox` at `{alien_id}@{hostname}` where `alien_id` comes from `ai.identity`.
- `byo`: `zone_in_cloudflare`. If false, leave `mail_status` empty and return. If true, same onboard + mailbox.
- Write `mail_status` and `mail_error` on `site.domain`.

Wire `wire_ws` `session.rs` match arms for fields 206, 207, 208. Errors: `site_domain_search_failed`, `site_domain_check_failed`, `site_domain_buy_failed`. `insufficient_balance` passes through as the client error string.

Test (pure): buy must not be attempted when check returns `registrable=false`. Function `buy_quote_ok(hit) -> Result<(f64, String), &'static str>` returns cost and currency or `unavailable` / `missing_price`.

---

# WAVE 4

## Track F1 — Editor UI

Replace the Settings domain `UITable` with a CSA-style section.

**Create** `ui_site_domain_section.dart`:

- One card per domain: hostname, close (confirm, then soft-delete via existing domain put/delete API).
- Unverified: Verify button + hint. BYO hint includes hours left from `created_ts_ms` (24h). Bought hint says DNS is being set up, no countdown.
- Verified: chips DNS verified, HTTPS ready / pending / failed / cluster-only. Failed shows Fix HTTPS (`force_tls`) and `tls_error`.
- `mail_status=ready`: chip that email is on. `failed`: `mail_error` in the card. Empty: no email chip.
- Buttons: **Buy domain**, **Add domain**. Add disabled when any unverified `byo` exists, with the pending-limit line.

**Create** `io_site_domain_buy_dialog.dart`:

- Search field, 450ms debounce, calls search then check.
- Rows show name and one price line (`USD 12.00 / year`). No second currency.
- Buy confirms in a dialog with that price, then calls `ReqSiteDomainBuy`.
- Errors: `insufficient_balance` tells the user to top up that currency. Other errors show the server string.

**Modify** `ui_site_settings_editor.dart` so the domain block is this section, not `UITable`.

**Modify** `site_api.dart` / `site_domain.dart` with `domainSearch`, `domainCheck`, `domainBuy`.

**Strings** in `en.json` and `id.json` under `site.domain.*`: buy, add, verify, fix HTTPS, pending limit, verify-within, email ready, email failed, insufficient balance, DNS setup hint. Follow existing key style in those files.

---

# WAVE 5

## Track V1 — Checks

From `servers/`:

```powershell
cargo test -p c35_mod_site domain_pending
cargo test -p c35_mod_site registrar_config
cargo test -p c35_mod_billing domain_purchase_refund_allowed
cargo test -p c35_mod_mail
cargo build -p server_ai
```

From repo root:

```powershell
.\_\scripts\dev\verify_flutter_app.ps1
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

Live Cloudflare register and a real wallet debit are not part of unit tests. V1 records that those need a configured token and a funded wallet.

---

## Self-review

| Requirement | Track |
|-------------|--------|
| CSA cards, verify, HTTPS, add | F1 |
| One unverified BYO, 24h drop | H1 |
| Bought never expires | H1 |
| Search and price check | R1, F1 |
| Charge quote currency, no FX, no dual display | B1, F1, D0 |
| Refund if register fails | B1, R2 |
| Register + grey CNAME | R2 |
| Email only after verify, bought always, BYO only if zone exists | M1, R2 |
| Mailbox `{alien_id}@{hostname}` | M1, R2 |
| No secrets from CSA source | R1 |
| Docs updated first | D0 |
