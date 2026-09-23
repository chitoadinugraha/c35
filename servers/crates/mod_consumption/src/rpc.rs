use c35_proto::{Consumption, ConsumptionItem as PbItem, Nutrition, ReqConsumptionList, ReqConsumptionPut, ResConsumptionList, ResConsumptionPut};
use serde_json::json;
use sqlx::PgPool;

use crate::{
    consumption_food_block, consumption_today, day_bounds_ms, food_get, food_update, meal_fingerprint,
    nutrition_sum_day, prefs_calorie_goal, resolve_day_id, ConsumptionItem, ConsumptionToday,
};

fn item_to_pb(i: &ConsumptionItem, idx: i32) -> PbItem {
    PbItem {
        idx,
        name: i.name.clone(),
        name_id: i.name_id.clone(),
        qty: i.qty,
        pic: String::new(),
        nutrition: Some(Nutrition {
            calories: i.calories,
            protein: i.protein,
            fat: i.fat,
            carbs: i.carbs,
            fiber: i.fiber,
            sugar: i.sugar,
            sodium: i.sodium,
            ..Default::default()
        }),
    }
}

fn food_to_pb(food: &crate::ConsumptionFood) -> Consumption {
    Consumption {
        id: food.id.parse().unwrap_or(0),
        note: food.note.clone(),
        photo_hash: food.photo_hash.clone(),
        meal_fingerprint: food.meal_fingerprint.clone(),
        meal_type: c35_proto::ConsumeMealType::Other as i32,
        items: food
            .items
            .iter()
            .enumerate()
            .map(|(i, it)| item_to_pb(it, i as i32))
            .collect(),
        ..Default::default()
    }
}

pub async fn consumption_list_rpc(pool: &PgPool, owner_iid: i64, locale: &str, req: ReqConsumptionList) -> ResConsumptionList {
    let day = if req.day_id.trim().is_empty() {
        None
    } else {
        Some(req.day_id.as_str())
    };
    let today = consumption_today(pool, owner_iid, locale, day).await.unwrap_or_else(|_| ConsumptionToday::default());
    ResConsumptionList {
        consumptions: today.meals.iter().map(food_to_pb).collect(),
    }
}

pub async fn consumption_put_rpc(pool: &PgPool, owner_iid: i64, locale: &str, req: ReqConsumptionPut) -> Result<ResConsumptionPut, String> {
    let doc = req.consumption.ok_or_else(|| "consumption required".to_string())?;
    let id = doc.id;
    if id == 0 {
        return Err("consumption.id required".into());
    }
    if doc.deleted_ts_ms > 0 {
        crate::food_delete(pool, owner_iid, id).await?;
        return Ok(ResConsumptionPut {
            consumption: Some(doc),
            blocks_json: "[]".into(),
        });
    }
    let items: Vec<ConsumptionItem> = doc
        .items
        .iter()
        .map(|i| {
            let n = i.nutrition.clone().unwrap_or_default();
            ConsumptionItem {
                name: i.name.clone(),
                name_id: i.name_id.clone(),
                qty: i.qty,
                calories: n.calories,
                protein: n.protein,
                fat: n.fat,
                carbs: n.carbs,
                fiber: n.fiber,
                sugar: n.sugar,
                sodium: n.sodium,
                ..Default::default()
            }
        })
        .collect();
    if items.is_empty() {
        return Err("items required".into());
    }
    let fingerprint = meal_fingerprint(&items);
    food_update(pool, owner_iid, id, &items, &fingerprint).await?;
    let food = food_get(pool, owner_iid, id).await?.ok_or_else(|| "not found".to_string())?;
    let day = resolve_day_id("today", locale);
    let (start, end) = day_bounds_ms(&day, locale).unwrap_or((0, i64::MAX));
    let goal = prefs_calorie_goal(pool, owner_iid).await.unwrap_or(2000);
    let (so_far, _, _, _, meals_logged) = nutrition_sum_day(pool, owner_iid, start, end).await.unwrap_or((0, 0, 0, 0, 0));
    let block = consumption_food_block(&food, locale, true, false, "", so_far, so_far, goal, meals_logged);
    Ok(ResConsumptionPut {
        consumption: Some(food_to_pb(&food)),
        blocks_json: serde_json::to_string(&json!([block])).unwrap_or_else(|_| "[]".into()),
    })
}
