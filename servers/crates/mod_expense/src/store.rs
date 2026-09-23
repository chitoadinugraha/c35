use c35_mod_tx::{tx_delete, tx_put};
use c35_proto::{
    ReqTxPut, Tx, TxData, TxInputSource, TxItem, TxPayment, TxPaymentMethod, TxPrompt, TxState,
    TxType,
};
use sqlx::PgPool;

use super::day::{snowflake_max_at_ms, snowflake_min_at_ms};
use super::fingerprint::{expense_total_minor, item_name_label};
use super::types::{ExpenseDetectResult, ExpenseItem, ExpenseReceipt, ExpenseTodaySummary, DEFAULT_CURRENCY};

pub async fn spending_sum_day(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
) -> Result<(i64, i32), String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    let row = sqlx::query_as::<_, (i64, i64)>(
        "SELECT COALESCE(SUM(total), 0), COUNT(*)
         FROM site.tx
         WHERE site_iid = $1 AND owner_iid = $1 AND ty = 'purchase' AND state = 'ok'
           AND deleted_ts IS NULL AND tx_id >= $2 AND tx_id <= $3",
    )
    .bind(owner_iid)
    .bind(id_min)
    .bind(id_max)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok((row.0, row.1 as i32))
}

pub async fn expense_duplicate_today(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
    photo_hash: &str,
    fingerprint: &str,
) -> Result<Option<(i64, String)>, String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    if !photo_hash.trim().is_empty() {
        let row = sqlx::query_scalar::<_, i64>(
            "SELECT tx_id FROM site.tx
             WHERE site_iid = $1 AND owner_iid = $1 AND ty = 'purchase' AND state = 'ok'
               AND deleted_ts IS NULL AND tx_id >= $2 AND tx_id <= $3
               AND tx_data_json->'proofs' ? $4
             ORDER BY tx_id DESC LIMIT 1",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .bind(photo_hash.trim())
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if let Some(id) = row {
            return Ok(Some((id, "photo".into())));
        }
    }
    if !fingerprint.trim().is_empty() {
        let row = sqlx::query_scalar::<_, i64>(
            "SELECT tx_id FROM site.tx
             WHERE site_iid = $1 AND owner_iid = $1 AND ty = 'purchase' AND state = 'ok'
               AND deleted_ts IS NULL AND tx_id >= $2 AND tx_id <= $3
               AND tx_data_json->'prompt'->>'desc' = $4
             ORDER BY tx_id DESC LIMIT 1",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .bind(fingerprint.trim())
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if let Some(id) = row {
            return Ok(Some((id, "receipt".into())));
        }
    }
    Ok(None)
}

fn payment_method_to_proto(method: &str) -> TxPaymentMethod {
    match method.trim().to_ascii_lowercase().as_str() {
        "card" => TxPaymentMethod::Card,
        "transfer" => TxPaymentMethod::Transfer,
        "qris" => TxPaymentMethod::Qris,
        "wallet" => TxPaymentMethod::Wallet,
        "debt" => TxPaymentMethod::Debt,
        _ => TxPaymentMethod::Cash,
    }
}

fn build_tx(
    owner_iid: i64,
    detect: &ExpenseDetectResult,
    photo_hash: &str,
    pics: &[String],
    fingerprint: &str,
    _note: &str,
) -> Tx {
    let total = expense_total_minor(&detect.items);
    let headline = if detect.headline.is_empty() {
        item_name_label(&detect.items, "id")
    } else {
        detect.headline.clone()
    };
    let items = detect
        .items
        .iter()
        .map(|i| TxItem {
            site_iid: owner_iid,
            owner_iid,
            obj_id: i.obj_id,
            price: i.price_minor,
            qty: i.qty.round() as i32,
            note: i.name.clone(),
            total_price: i.total_minor,
            total_net: i.total_minor,
            ..Default::default()
        })
        .collect();
    let proofs: Vec<String> = if photo_hash.is_empty() {
        pics.to_vec()
    } else if pics.contains(&photo_hash.to_string()) {
        pics.to_vec()
    } else {
        let mut p = vec![photo_hash.to_string()];
        p.extend(pics.iter().cloned());
        p
    };
    Tx {
        site_iid: owner_iid,
        r#type: i32::from(TxType::Purchase),
        state: i32::from(TxState::Ok),
        input_source: i32::from(TxInputSource::Ai),
        desc: headline,
        subject_name: detect.subject.clone(),
        items,
        payments: vec![TxPayment {
            method: i32::from(payment_method_to_proto(&detect.payment_method)),
            amount: total,
            ..Default::default()
        }],
        tx_data: Some(TxData {
            proofs,
            prompt: Some(TxPrompt {
                pics: pics.to_vec(),
                desc: fingerprint.to_string(),
            }),
            ..Default::default()
        }),
        ..Default::default()
    }
}

pub async fn expense_put(
    pool: &PgPool,
    caller_iid: i64,
    detect: &ExpenseDetectResult,
    photo_hash: &str,
    pics: &[String],
    fingerprint: &str,
    note: &str,
) -> Result<i64, String> {
    let tx = build_tx(caller_iid, detect, photo_hash, pics, fingerprint, note);
    let res = tx_put(pool, caller_iid, ReqTxPut { tx: Some(tx) }, None)
        .await
        .map_err(|e| e.to_string())?;
    Ok(res.tx.map(|t| t.tx_id).unwrap_or(0))
}

pub async fn expense_delete(pool: &PgPool, caller_iid: i64, tx_id: i64) -> Result<bool, String> {
    tx_delete(pool, caller_iid, caller_iid, tx_id)
        .await
        .map_err(|e| e.to_string())
}

pub async fn expense_get_latest_today(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
) -> Result<Option<ExpenseReceipt>, String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    let row = sqlx::query_scalar::<_, i64>(
        "SELECT tx_id FROM site.tx
         WHERE site_iid = $1 AND owner_iid = $1 AND ty = 'purchase' AND state = 'ok'
           AND deleted_ts IS NULL AND tx_id >= $2 AND tx_id <= $3
         ORDER BY tx_id DESC LIMIT 1",
    )
    .bind(owner_iid)
    .bind(id_min)
    .bind(id_max)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if let Some(id) = row {
        return expense_get(pool, owner_iid, id).await;
    }
    Ok(None)
}

pub async fn expense_get(pool: &PgPool, owner_iid: i64, tx_id: i64) -> Result<Option<ExpenseReceipt>, String> {
    let row = sqlx::query_as::<_, (i64, String, String, i64, serde_json::Value)>(
        "SELECT tx_id, \"desc\", subject_name, total, tx_data_json
         FROM site.tx
         WHERE site_iid = $1 AND owner_iid = $1 AND tx_id = $2 AND ty = 'purchase'
           AND deleted_ts IS NULL",
    )
    .bind(owner_iid)
    .bind(tx_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if let Some((tx_id, desc, subject_name, total, tx_data)) = row {
        let items = expense_items_load(pool, owner_iid, tx_id).await?;
        let photo_hash = tx_data
            .get("proofs")
            .and_then(|p| p.as_array())
            .and_then(|a| a.first())
            .and_then(|h| h.as_str())
            .unwrap_or("")
            .to_string();
        let payment_method = expense_payment_method(pool, owner_iid, tx_id).await?;
        return Ok(Some(ExpenseReceipt {
            tx_id: tx_id.to_string(),
            headline: desc,
            subtitle: subject_name,
            coach: String::new(),
            total_minor: total,
            currency: DEFAULT_CURRENCY.into(),
            saved: true,
            duplicate: false,
            duplicate_reason: String::new(),
            photo_hash,
            payment_method,
            items,
            today: ExpenseTodaySummary::default(),
        }));
    }
    Ok(None)
}

async fn expense_payment_method(pool: &PgPool, owner_iid: i64, tx_id: i64) -> Result<String, String> {
    let row = sqlx::query_scalar::<_, String>(
        "SELECT method FROM site.tx_payment
         WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
         ORDER BY payment_id LIMIT 1",
    )
    .bind(owner_iid)
    .bind(tx_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(row.unwrap_or_else(|| "cash".into()))
}

pub async fn expense_list_day(
    pool: &PgPool,
    owner_iid: i64,
    day_start_ms: i64,
    day_end_ms: i64,
) -> Result<Vec<ExpenseReceipt>, String> {
    let id_min = snowflake_min_at_ms(day_start_ms);
    let id_max = snowflake_max_at_ms(day_end_ms);
    let rows = sqlx::query_as::<_, (i64,)>(
        "SELECT tx_id FROM site.tx
         WHERE site_iid = $1 AND owner_iid = $1 AND ty = 'purchase' AND state = 'ok'
           AND deleted_ts IS NULL AND tx_id >= $2 AND tx_id <= $3
         ORDER BY tx_id DESC LIMIT 100",
    )
    .bind(owner_iid)
    .bind(id_min)
    .bind(id_max)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    for (tx_id,) in rows {
        if let Some(r) = expense_get(pool, owner_iid, tx_id).await? {
            out.push(r);
        }
    }
    Ok(out)
}

async fn expense_items_load(pool: &PgPool, owner_iid: i64, tx_id: i64) -> Result<Vec<ExpenseItem>, String> {
    let rows = sqlx::query_as::<_, (String, i64, i32, i64, i64)>(
        "SELECT note, obj_id, qty, price, total_net
         FROM site.tx_item
         WHERE site_iid = $1 AND tx_id = $2 AND deleted_ts IS NULL
         ORDER BY item_id ASC",
    )
    .bind(owner_iid)
    .bind(tx_id)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(rows
        .into_iter()
        .map(|(name, obj_id, qty, price, total)| ExpenseItem {
            name: name.clone(),
            name_id: name,
            qty: qty as f32,
            obj_id,
            price_minor: price,
            total_minor: total,
        })
        .collect())
}

pub fn receipt_from_detect(
    tx_id: i64,
    detect: &ExpenseDetectResult,
    photo_hash: &str,
    saved: bool,
    duplicate: bool,
    duplicate_reason: &str,
    today: ExpenseTodaySummary,
    locale: &str,
) -> ExpenseReceipt {
    let total = expense_total_minor(&detect.items);
    let headline = if detect.headline.is_empty() {
        item_name_label(&detect.items, locale)
    } else {
        detect.headline.clone()
    };
    ExpenseReceipt {
        tx_id: if tx_id > 0 { tx_id.to_string() } else { String::new() },
        headline,
        subtitle: detect.subject.clone(),
        coach: String::new(),
        total_minor: total,
        currency: DEFAULT_CURRENCY.into(),
        saved,
        duplicate,
        duplicate_reason: duplicate_reason.to_string(),
        photo_hash: photo_hash.to_string(),
        payment_method: detect.payment_method.clone(),
        items: detect.items.clone(),
        today,
    }
}
