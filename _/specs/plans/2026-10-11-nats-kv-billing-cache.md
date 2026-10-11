# Billing Performance - NATS JetStream KV Gate Cache

> **Status:** Active (2026-10-11)  
> **Goal:** Eliminate the ~1,300 ms WAN database roundtrip delay during prompt prepare, talk mode turns, and live call connection by caching billing gate eligibility in NATS JetStream KV.

---

## 1. Problem Statement

Every prompt turn in `prompt_turn.rs` and live call initialization in `live_billing_gate` executes multiple sequential/parallel queries to the database across WAN:
1. `billing_account_ensure`: queries `ai.billing_account`, checks rolling windows, ensures `ai.billing_profile`, checks plan lapse, and autoclaims signup trial (3–4 SQL queries).
2. `billing_resolve`: queries `ai.billing_subscription` and `ai.billing_account`.
3. `billing_freemium_applies`: queries freemium entitlement.
4. `billing_gate_scoped` & `billing_gate_with_hold_model`: queries rings, window roll, in-flight reservations, and held totals.

Over WAN (100–200 ms RTT), these queries aggregate to **1,200 ms – 1,500 ms of latency** before prompt compilation or live audio streaming can even begin.

---

## 2. Architecture & Design Decisions

### A. Shared Distributed NATS JetStream KV (`c35_billing_cache`)
- **Bucket:** `c35_billing_cache`
- **Bucket TTL:** `max_age = 30s` (automatic key eviction by NATS).
- **History:** 1 (latest state only).
- **Stateless Pods:** Pods maintain **0 bytes** of heap state for users. No local memory leaks.
- **Load Balancer Friendly:** A turn hitting Pod 1 writes the cache entry; the next turn on Pod 2 reads it in **~1–2 ms** over the cluster socket.

### B. Cached Data Structure (`BillingGateCache`)
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BillingGateCache {
    pub owner_iid: i64,
    pub billing_account_id: i64,
    pub plan_tier: String,
    pub is_freemium: bool,
    pub has_sufficient_allowance: bool,
    pub cached_at_secs: i64,
}
```

### C. Safety & Guardrails
1. **Authoritative ACID Settlement Still in Postgres:**  
   Post-turn token deduct and financial usage settlement (`billing_usage_report`, `live_billing_settle`) **always** write authoritatively to Postgres.
2. **Critically Low Balance Bypass:**  
   If a user has exhausted their allowance rings and their wallet balance is critically low (`< $0.05`), the cache is bypassed to avoid overdraft.
3. **Instant Invalidation on Write:**  
   Any payment webhook, plan upgrade, top-up, or manual adjustment immediately deletes the NATS KV key `user/{owner_iid}` (and publishes `c35.billing.invalidate.{owner_iid}`).
4. **Graceful Fallback:**  
   If NATS is unavailable, disconnected, or in unit tests, all code immediately falls back to direct Postgres queries without error.

---

## 3. Implementation Steps

1. **`c35_nats` (`servers/crates/system/nats/src/billing_kv.rs`)**:
   - Provide `billing_kv_ensure(client: &Client) -> anyhow::Result<Store>`
   - Provide `billing_kv_get`, `billing_kv_put`, `billing_kv_invalidate`
2. **`c35_mod_billing` (`servers/crates/mod_billing/src/billing_cache.rs`)**:
   - Wrap fast-path gate check using NATS KV store when available.
   - Fall back to standard `billing_account_ensure` + `billing_gate_with_hold_model` on miss or near-empty balance.
3. **`prompt_turn.rs` & `live_billing_gate`**:
   - Wire the cached gate lookup into Stage 1 before DB fallbacks.
4. **Verification**:
   - Run `cargo check -p c35_nats`, `cargo test -p c35_mod_billing`, `cargo test -p c35_mod_chat`, `cargo build -p server_ai`.
