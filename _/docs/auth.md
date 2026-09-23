# Authentication & Referral Specification

Status: **active** 2026-09-23

## Overview

All authentication in c35 flows over **HTTPS REST endpoints** targeting `https://api.alienai.id` (used consistently across production and local environments). WebSocket connections require a valid session JWT token obtained via these auth endpoints.

---

## 1. Transport & Base URLs

* **Auth API Host**: `https://api.alienai.id` (configured in `C35Config.authApiBase` and `C35Config.providerAuthBase`).
* **Transport**: HTTP REST (JSON) with Bearer token authentication in `Authorization` and `X-Session-Token` headers.
* **Session Cookie**: `cs_session=<token>` (HTTP-only, 30 days expiry).

### Core Endpoints

| Method | Path | Auth Required | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/v1/auth/signin` | No | Password login with identifier (Alien ID, email, or phone) |
| `POST` | `/v1/auth/signup` | No | Create user account with optional referral code |
| `POST` | `/v1/auth/signout` | Yes | Invalidate session token and clear cookies |
| `GET` | `/v1/auth/me` | Yes | Return current user identity and balances |
| `GET` | `/a/auth/google` | No | Initiate Google OAuth flow |
| `GET` | `/a/auth/google/result` | No | Poll Google OAuth result by `client_id` |
| `GET` | `/v1/auth/referral/lookup` | No | Live referral code check and issuer card preview |
| `POST` | `/v1/auth/referral/claim` | Yes | Claim referral code post-login and receive Rp. 10.000 bonus |
| `POST` | `/v1/auth/referral/dismiss` | Yes | Dismiss the first-time referral code prompt permanently |
| `GET` | `/v1/auth/alien_id/check` | No / Yes | Live check if an Alien ID is valid and available |
| `POST` | `/v1/auth/alien_id/claim` | Yes | Set Alien ID for the current account |

---

## 2. Nullable Alien ID (`alien_id`)

Alien ID is the human-readable handle (slug) for an identity (e.g. `@chito`).

### Rules

1. **Default is `NULL`**:
   * Newly registered accounts (via Password signup or Google OAuth) default to `alien_id = NULL`.
   * **Do NOT auto-generate handles** based on email prefixes (e.g. `user_1` or `john_doe`).
2. **No Conflicts**:
   * PostgreSQL / YugabyteDB unique partial index:
     ```sql
     CREATE UNIQUE INDEX IF NOT EXISTS idx_identity_alien_id
         ON ai.identity (LOWER(alien_id))
         WHERE alien_id IS NOT NULL AND alien_id <> '';
     ```
   * Multiple rows with `NULL` or empty `alien_id` coexist without uniqueness violations.
3. **Claiming Alien ID**:
   * Users can claim an Alien ID in **Settings** (`PageSettings` via `_AlienIdDialog` & `InAlienIdSignup`).
   * When setting an Alien ID:
     * Valid characters: lowercase letters `[a-z]`, digits `[0-9]`, `_`, `-`.
     * Minimum length: standard is **7 characters**.
     * Short Alien IDs (< 7 characters) require an unlocked special referral code (such as `CHITOKERENSEKALI9999`) or an issuer referral code with `allow_short_id = true`.
     * Validated on the server side (`POST /v1/auth/alien_id/claim` and `ai.identity` uniqueness check).

---

## 3. Referral Code System

### A. Live Validation & Preview (`InReferralCode`)

The client provides debounced (300ms) validation via `InReferralCode`:
* Calls `GET /v1/auth/referral/lookup?code=<CODE>`.
* Special codes (such as `CHITOKERENSEKALI9999`) resolve immediately without a network roundtrip as "Alien AI" issuer with short ID permissions.
* For database codes, returns:
  * `valid`: boolean
  * `code`: normalized uppercase code
  * `issuer_name`: display name of referrer
  * `issuer_pic`: profile avatar URL of referrer
  * `allow_short_id`: boolean

### B. First-Time Sign-In Dialog

When a user signs in (via Google or password):
* If the user has **no referrer** (`referred_by_iid IS NULL`), has **not dismissed** the prompt (`meta.referral_prompt_dismissed != true`), and has **no alien_id** or is a fresh login:
* The app presents a dialog:
  > **Do you have a Referral Code?**
  > *Get Rp. 10.000 if you enter the referral code.*
* The dialog embeds `InReferralCode` with real-time feedback and an issuer card preview.
* If user inputs a valid code and taps **Claim**:
  * Calls `POST /v1/auth/referral/claim`.
  * The server links `ai.identity.referred_by_iid = parent_iid`.
  * Creates an edge `ai.referral_share (parent_iid, child_iid, 25%)`.
  * Increments `used_count` in `ai.referral_code`.
  * Credits **Rp. 10.000** bonus balance to `ai.billing_account`.
  * Marks `meta.referral_prompt_dismissed = true`.
* If user taps **"I don't have one"**:
  * Calls `POST /v1/auth/referral/dismiss` (and updates local session).
  * Permanently suppresses the dialog for this account.

---

## 4. Google OAuth Flow

1. Client opens browser to `https://api.alienai.id/a/auth/google` with `client_id` (UUIDv4) and deep-link return URL.
2. Server validates Google token and checks `ai.identity_provider` by `google_sub` or verified email.
3. If new user:
   * Inserts into `ai.identity` with `alien_id = NULL` and initial balance.
   * Inserts into `ai.identity_provider` (kind = `google`).
4. Generates session token in `ai.auth_session`.
5. Client polls `GET https://api.alienai.id/a/auth/google/result?client_id=<id>`.
6. Client receives session token and enters app.
7. Upon app entry, the first-time referral prompt appears if the account has no referrer.
