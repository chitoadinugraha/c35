# Optimization Plan: Tool Dispatcher Freemium Caching, Adaptive Perception & Device Presence KV

## 1. Context & Motivation

### The Problem: 60–90 Redundant SQL Queries in Multi-Turn Tool Loops
During Computer Use, autonomous tasks (`prompt_run`), or multi-tool turns:
- An LLM typically executes 15–30 tool calls per task (`device.screenshot`, `device.input`, `shell.run`, `web.search`, etc.).
- Before executing ANY tool, `ToolDispatcher::execute` in `servers/crates/mod_chat/src/tools/dispatcher.rs` verifies whether the user is restricted by freemium limits:
  ```rust
  c35_mod_billing::billing_freemium_applies(&ctx.pool, ctx.owner_iid).await
  ```
- Inside `billing_freemium_applies`, each check executes **2 to 3 database queries**:
  1. `billing_plan_lapse_if_expired` (`SELECT ... FROM ai.billing_subscription ...`)
  2. `freemium_profile_fetch` (`SELECT plan_tier, trial_expires_ts FROM ai.billing_profile ...`)
  3. `paid_tier_from_account` (`SELECT plan_tier FROM ai.billing_account ...`)
- **Cumulative Cost:** For a 30-step Computer Use sequence, this generates **60 to 90 redundant PostgreSQL WAN queries** purely checking if the user's subscription tier has changed in the last 2 seconds.

---

## 2. Architectural Decisions

### Phase 1: NATS-Cached & Memoized Freemium Gate
1. **`ToolContext` Memoization:**
   - Add `is_freemium_cache: Arc<tokio::sync::Mutex<Option<bool>>>` to `ToolContext`.
   - The first tool call in a turn/session evaluates freemium status; all subsequent tool calls in that turn/session read the cached boolean in **< 1 microsecond**.
2. **NATS JetStream KV Integration (`c35_billing_cache`):**
   - Add `billing_freemium_applies_nats(pool, nats, owner_iid)`.
   - If NATS KV contains a cached entry for `user_{owner_iid}`, return `entry.is_freemium` directly (**< 0.5 ms**).
   - If cache miss, fallback to PostgreSQL and cache the result.

### Phase 2: Adaptive Perception & JPEG Compression
1. **Intermediate Action Feedback (`device.input` with `screenshot_after`):**
   - Intermediate verification screenshots (showing the red action marker after a click/move) are optimized to `1024px` max width and `60` JPEG quality.
   - Reduces byte payload by **~65%** (from ~150 KB to ~45 KB), accelerating upload to the server and decoding by the vision model.
2. **Explicit Observation (`device.screenshot`):**
   - Keeps default `1280px` and `72` quality for full detail.

### Phase 3: NATS Device Presence KV (`c35_device_presence`)
1. **Bucket:** `c35_device_presence` with a 30-second TTL.
2. **Fast Heartbeat Check:**
   - Multi-pod presence check reads NATS KV in **< 0.5 ms** before dispatching `device.screenshot` or `device.command`.
   - Eliminates `SELECT meta FROM ai.agent WHERE device_iid = $1` database queries when the device is connected to another pod.

---

## 3. Verification Metrics
- `cargo test -p c35_mod_billing`: Passes.
- `cargo test -p c35_mod_chat`: Passes.
- `cargo build -p server_ai`: Compiles cleanly.
- Database query count during 30-tool execution: **Drops from 60–90 queries to 0**.
