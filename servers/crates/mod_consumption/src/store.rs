use sqlx::PgPool;

use c35_store::snowflake_id;

use super::day::{snowflake_max_at_ms, snowflake_min_at_ms};
use super::types::{ConsumptionFood, ConsumptionItem, DEFAULT_CALORIE_GOAL};

pub async fn prefs_calorie_goal(pool: &PgPool, owner_iid: i64) -> Result<i32, String> {
    let row = sqlx::query_scalar::<_, i32>(
        "SELECT calorie_goal_kcal FROM ai.consumption_prefs WHERE owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.unwrap_or(DEFAULT_CALORIE_GOAL))
}

pub async fn nutrition_sum_day(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
) -> Result<(i32, i32, i32, i32, i32), String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    let row = sqlx::query_as::<_, (i64, i64, i64, i64, i64)>(
        "SELECT
           COALESCE(SUM((ci.calories * ci.qty)::int), 0),
           COALESCE(SUM((ci.protein * ci.qty)::int), 0),
           COALESCE(SUM((ci.fat * ci.qty)::int), 0),
           COALESCE(SUM((ci.carbs * ci.qty)::int), 0),
           COUNT(DISTINCT ci.consumption_id)
         FROM ai.consumption_item ci
         JOIN ai.consumption c ON c.id = ci.consumption_id AND c.owner_iid = ci.owner_iid
         WHERE ci.owner_iid = $1 AND c.is_archived = false AND c.deleted_ts IS NULL AND ci.deleted_ts IS NULL
           AND ci.consumption_id >= $2 AND ci.consumption_id <= $3",
    )
    .bind(owner_iid)
    .bind(id_min)
    .bind(id_max)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok((row.0 as i32, row.1 as i32, row.2 as i32, row.3 as i32, row.4 as i32))
}

pub async fn food_duplicate_today(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
    photo_hash: &str,
    meal_fingerprint: &str,
) -> Result<Option<(i64, String)>, String> {
    if photo_hash.trim().is_empty() && meal_fingerprint.trim().is_empty() {
        return Ok(None);
    }
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    if !photo_hash.trim().is_empty() {
        let row = sqlx::query_scalar::<_, i64>(
            "SELECT id FROM ai.consumption
             WHERE owner_iid = $1 AND is_archived = false AND deleted_ts IS NULL AND photo_hash = $2
               AND id >= $3 AND id <= $4
             ORDER BY id DESC LIMIT 1",
        )
        .bind(owner_iid)
        .bind(photo_hash.trim())
        .bind(id_min)
        .bind(id_max)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if let Some(id) = row {
            return Ok(Some((id, "photo".into())));
        }
    }
    if !meal_fingerprint.trim().is_empty() {
        let row = sqlx::query_scalar::<_, i64>(
            "SELECT id FROM ai.consumption
             WHERE owner_iid = $1 AND is_archived = false AND deleted_ts IS NULL AND meal_fingerprint = $2
               AND id >= $3 AND id <= $4
             ORDER BY id DESC LIMIT 1",
        )
        .bind(owner_iid)
        .bind(meal_fingerprint.trim())
        .bind(id_min)
        .bind(id_max)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if let Some(id) = row {
            return Ok(Some((id, "meal".into())));
        }
    }
    Ok(None)
}

pub async fn food_put(
    pool: &PgPool,
    owner_iid: i64,
    note: &str,
    photo_hash: &str,
    pics: &[String],
    meal_fingerprint: &str,
    meal_type: &str,
    items: &[ConsumptionItem],
) -> Result<i64, String> {
    let id = snowflake_id();
    let pics_json = serde_json::to_value(pics).unwrap_or_else(|_| serde_json::json!([]));
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    sqlx::query(
        "INSERT INTO ai.consumption (id, owner_iid, note, photo_hash, pics_json, meal_fingerprint, meal_type, logged_ts, updated_ts)
         VALUES ($1,$2,$3,$4,$5,$6,$7,NOW(),NOW())",
    )
    .bind(id)
    .bind(owner_iid)
    .bind(note)
    .bind(photo_hash)
    .bind(&pics_json)
    .bind(meal_fingerprint)
    .bind(meal_type)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;

    food_item_replace_tx(&mut tx, owner_iid, id, items).await?;
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(id)
}

pub async fn food_update(
    pool: &PgPool,
    owner_iid: i64,
    consumption_id: i64,
    items: &[ConsumptionItem],
    meal_fingerprint: &str,
) -> Result<(), String> {
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let n = sqlx::query(
        "UPDATE ai.consumption SET meal_fingerprint = $3, updated_ts = NOW()
         WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(consumption_id)
    .bind(owner_iid)
    .bind(meal_fingerprint)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .rows_affected();
    if n == 0 {
        return Err("consumption not found".into());
    }
    food_item_replace_tx(&mut tx, owner_iid, consumption_id, items).await?;
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn food_delete(pool: &PgPool, owner_iid: i64, consumption_id: i64) -> Result<bool, String> {
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let n = sqlx::query(
        "UPDATE ai.consumption SET deleted_ts = NOW(), updated_ts = NOW()
         WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(consumption_id)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?
    .rows_affected();
    if n == 0 {
        return Ok(false);
    }
    sqlx::query(
        "UPDATE ai.consumption_item SET deleted_ts = NOW(), updated_ts = NOW()
         WHERE consumption_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(consumption_id)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(true)
}

pub async fn food_get_latest_today(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
) -> Result<Option<ConsumptionFood>, String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    let row = sqlx::query_scalar::<_, i64>(
        "SELECT id FROM ai.consumption
         WHERE owner_iid = $1 AND is_archived = false AND deleted_ts IS NULL
           AND id >= $2 AND id <= $3
         ORDER BY id DESC LIMIT 1",
    )
    .bind(owner_iid)
    .bind(id_min)
    .bind(id_max)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    if let Some(id) = row {
        return food_get(pool, owner_iid, id).await;
    }
    Ok(None)
}

async fn food_item_replace_tx(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    owner_iid: i64,
    consumption_id: i64,
    items: &[ConsumptionItem],
) -> Result<(), String> {
    sqlx::query("DELETE FROM ai.consumption_item WHERE consumption_id = $1 AND owner_iid = $2")
        .bind(consumption_id)
        .bind(owner_iid)
        .execute(&mut **tx)
        .await
        .map_err(|e| e.to_string())?;
    for (idx, it) in items.iter().enumerate() {
        let obj_id = if it.obj_id > 0 {
            it.obj_id
        } else {
            let n1 = it.name.trim().to_ascii_lowercase();
            let n2 = it.name_id.trim().to_ascii_lowercase();
            sqlx::query_scalar::<_, i64>(
                "SELECT obj_id FROM ai.object_alias WHERE name_norm = $1 OR name_norm = $2 LIMIT 1"
            )
            .bind(&n1)
            .bind(&n2)
            .fetch_optional(&mut **tx)
            .await
            .unwrap_or(None)
            .unwrap_or(0)
        };
        sqlx::query(
            "INSERT INTO ai.consumption_item
             (consumption_id, owner_iid, idx, name, name_id, qty, pic, obj_id,
              calories, protein, fat, carbs, fiber, sugar, sodium,
              potassium, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
              calcium, iron, magnesium, phosphorus, zinc, copper)
             VALUES ($1,$2,$3,$4,$5,$6,'',$7,$8,$9,$10,$11,$12,$13,$14,
                     0,0,0,0,0,0,0,0,0,0,0,0)",
        )
        .bind(consumption_id)
        .bind(owner_iid)
        .bind(idx as i16)
        .bind(&it.name)
        .bind(&it.name_id)
        .bind(it.qty)
        .bind(obj_id)
        .bind(it.calories)
        .bind(it.protein)
        .bind(it.fat)
        .bind(it.carbs)
        .bind(it.fiber)
        .bind(it.sugar)
        .bind(it.sodium)
        .execute(&mut **tx)
        .await
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub async fn food_get(pool: &PgPool, owner_iid: i64, consumption_id: i64) -> Result<Option<ConsumptionFood>, String> {
    let row = sqlx::query_as::<_, (i64, String, String, String, String)>(
        "SELECT id, note, photo_hash, meal_fingerprint, meal_type FROM ai.consumption
         WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(consumption_id)
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if let Some((id, note, photo_hash, meal_fingerprint, meal_type)) = row {
        let items = food_items_load(pool, owner_iid, id).await?;
        return Ok(Some(ConsumptionFood {
            id: id.to_string(),
            note,
            items,
            photo_hash,
            meal_fingerprint,
            meal_type,
        }));
    }
    Ok(None)
}

pub async fn food_list_day(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
) -> Result<Vec<ConsumptionFood>, String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    let rows = sqlx::query_as::<_, (i64, String, String, String, String)>(
        "SELECT id, note, photo_hash, meal_fingerprint, meal_type FROM ai.consumption
         WHERE owner_iid = $1 AND is_archived = false AND deleted_ts IS NULL
           AND id >= $2 AND id <= $3
         ORDER BY id DESC LIMIT 100",
    )
    .bind(owner_iid)
    .bind(id_min)
    .bind(id_max)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    for (id, note, photo_hash, meal_fingerprint, meal_type) in rows {
        let items = food_items_load(pool, owner_iid, id).await?;
        out.push(ConsumptionFood {
            id: id.to_string(),
            note,
            items,
            photo_hash,
            meal_fingerprint,
            meal_type,
        });
    }
    Ok(out)
}

async fn food_items_load(pool: &PgPool, owner_iid: i64, consumption_id: i64) -> Result<Vec<ConsumptionItem>, String> {
    let rows = sqlx::query_as::<_, (String, String, f32, i32, i32, i32, i32, i32, i32, i32, i64)>(
        "SELECT name, name_id, qty, calories, protein, fat, carbs, fiber, sugar, sodium, COALESCE(obj_id, 0)
         FROM ai.consumption_item
         WHERE consumption_id = $1 AND owner_iid = $2 AND deleted_ts IS NULL
         ORDER BY idx ASC",
    )
    .bind(consumption_id)
    .bind(owner_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(rows
        .into_iter()
        .map(|(name, name_id, qty, calories, protein, fat, carbs, fiber, sugar, sodium, obj_id)| ConsumptionItem {
            name,
            name_id,
            qty,
            obj_id,
            calories,
            protein,
            fat,
            carbs,
            fiber,
            sugar,
            sodium,
        })
        .collect())
}
