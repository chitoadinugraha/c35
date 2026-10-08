# Snowflake IDs (LOCKED)

Status: **locked** 2026-09-23

Implementation: `servers/crates/store/src/snowflake.rs` (`c35_store::snowflake_id`).

Aligned with CSA (`csa_site_published/crates/store/src/snowflake.rs`) — same bit layout and epoch so imported CSA identity / referral ids decode consistently.

## Bit layout (64-bit signed `i64`)

```
[ 42-bit timestamp | 10-bit worker | 12-bit sequence ]
```

| Field | Bits | Range | Notes |
|-------|------|-------|-------|
| **Timestamp** | 42 | ms since epoch | monotonic sort key |
| **Worker** | 10 | 0–1023 | unique per `c35-server` pod |
| **Sequence** | 12 | 0–4095 | per worker per millisecond |

**Epoch:** `1_767_225_600_000` — **2026-01-01 00:00:00 UTC** (`SNOWFLAKE_EPOCH_MS`).

Day-range queries (consumption, expense) use `snowflake_min_at_ms` / `snowflake_max_at_ms` from `c35_store` with shift `22` (= worker + sequence bits).

## Worker ID (not K8s node name)

| Env | Role |
|-----|------|
| `C35_WORKER_ID` | Explicit snowflake worker (0–1023). Use for local dev / tests. |
| `POD_NAME` | K8s pod name (downward API on `c35-server`). Hashed when `C35_WORKER_ID` unset. |
| `HOSTNAME` | Fallback when `POD_NAME` missing (local `cargo run`). |

**Do not confuse:**

| Name | What it is |
|------|------------|
| `C35_WORKER_ID` / worker bits | Snowflake allocator — must be unique per concurrent `c35-server` pod |
| `NODE_NAME` | K8s **host** name — used by `c35-node-stats` and ops dashboards only |
| `POD_NAME` | K8s pod name — input to worker-id hash |

### Assignment (production)

When `C35_WORKER_ID` is unset, worker id = **FNV-1a hash of `POD_NAME`**, masked to 10 bits; `0` maps to `1`:

```
worker = fnv1a(POD_NAME) & 0x3FF
if worker == 0 → 1
```

Stable for the lifetime of the pod. Two pods on the same physical node get different worker ids because pod names differ (`c35-server-abc12` vs `c35-server-xyz99`).

Override example (local):

```powershell
$env:C35_WORKER_ID = '2'
cargo run -p server_ai
```

## Multi-pod HA

`c35-server` runs **2+ replicas** (`_/deployments/c35-server/deployment.yaml`). Each replica:

1. Gets its own `POD_NAME` → unique worker id.
2. Generates snowflakes independently (in-process sequence counter).
3. Shares YB + NATS — no shared snowflake state required.

Collision requires same worker id **and** same millisecond **and** sequence overlap — prevented by per-pod worker hash.

## Usage

| Store | Column | Generator |
|-------|--------|-----------|
| `ai.identity` | `id` (iid) | server on create |
| `ai.chat`, `ai.chat_msg` | `id` | server |
| `ai.consumption` | `id` | server; encodes logged day for range queries |
| `ai.log` | `id` | server |
| Billing / referral / site rows | `id` | server |

Imported CSA rows (users, referral) may use legacy sequential ids — new rows use snowflake.

## API

```rust
use c35_store::{snowflake_id, snowflake_min_at_ms, snowflake_max_at_ms, SNOWFLAKE_EPOCH_MS};
```
