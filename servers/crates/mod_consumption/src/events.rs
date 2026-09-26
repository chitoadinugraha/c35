use async_nats::Client;
use c35_mod_event::{event_emit, kinds, EventCtx};
use serde_json::json;
use sqlx::PgPool;

use super::types::ConsumptionItem;

fn meal_calories(items: &[ConsumptionItem]) -> i32 {
    items
        .iter()
        .map(|i| (i.calories as f64 * i.qty as f64).round() as i32)
        .sum()
}

pub async fn consumption_meal_emit(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    kind: &'static str,
    consumption_id: i64,
    items: &[ConsumptionItem],
    source: &str,
    req_id: Option<&str>,
) {
    let item_count = items.len();
    let calories = meal_calories(items);
    let mut ctx = EventCtx::for_owner(owner_iid, "c35-server");
    ctx.req_id = req_id.map(|s| s.to_string());
    let meta = json!({
        "consumption_id": consumption_id,
        "item_count": item_count,
        "calories": calories,
        "source": source,
    });
    let _ = event_emit(pool, nats, ctx, kind, meta).await;
}

pub async fn consumption_meal_deleted_emit(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    consumption_id: i64,
    source: &str,
) {
    let ctx = EventCtx::for_owner(owner_iid, "c35-server");
    let meta = json!({
        "consumption_id": consumption_id,
        "source": source,
        "item_count": 0,
        "calories": 0,
    });
    let _ = event_emit(pool, nats, ctx, kinds::CONSUMPTION_MEAL_DELETED, meta).await;
}