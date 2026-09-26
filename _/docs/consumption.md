# Consumption (LOCKED)

Status: **locked** 2026-09-20

Personal food and water tracking — health tools on the Home assistant, not site-scoped.

## Reference

| Project | Borrow |
|---------|--------|
| `E:\Project Archive\id.alienai` | Full nutrition fields on `ConsumeFoodItem` |
| `D:\cs_agent` | Meal type, photo_hash, meal_fingerprint, YB row shape |

## Owner

**User identity only** (`owner_iid` = signed-in user). Never attached to site or team.

## Tables

See [`../schemas/consumption.sql`](../schemas/consumption.sql).

| Table | Synced | Notes |
|-------|--------|-------|
| `consumption` | yes | Header; id = snowflake (day query by id range) |
| `consumption_item` | yes | Denormalized nutrition totals per line |
| `consumption_water` | yes | Daily ml rollup keyed by `day_id` (YYYY-MM-DD) |
| `consumption_prefs` | yes | Calorie + water goals |

## Events

After a meal is saved, updated, or deleted, emit domain events (not on read/tools glance). Catalog: [event.md](event.md) — `consumption.meal_logged`, `meal_updated`, `meal_deleted` → NATS `c35.user.{owner_iid}.ev.meal-logged` (etc.). Emit from `mod_consumption::store` on successful write.

## Meal types

`other` | `breakfast` | `lunch` | `dinner` | `snack` | `dessert` | `late_night`

Maps to `ConsumeMealType` enum in proto.

## Wire

Proto: [`../schemas/proto/c35/consumption.proto`](../schemas/proto/c35/consumption.proto)

- `ReqConsumptionList` — by day or recent
- `ReqConsumptionPut` — log meal (AI or manual)
- `ReqConsumptionWaterAdd` — +250 ml tap
- `ReqConsumptionPrefsGet/Put` — goals

Sync collections: `consumption`, `consumption_water`.

## AI tools (future)

LLM callable tools (like id.alienai `consume.food.log`):

- Photo → items + nutrition estimate
- Voice/text → structured `ConsumptionPut`

## Deferred

- Exercise / sleep tracking
- Integration with external health APIs
