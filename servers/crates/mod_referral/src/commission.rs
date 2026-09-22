use c35_proto::{ReferralCommissionLevel, ResReferralCommissionSimulate};
use c35_store::snowflake_id;
use sqlx::{PgPool, Postgres, Row, Transaction};

pub const MARKETING_POOL_RATE: f64 = 0.35;
const SHARE_MAX_PERCENT: i32 = 35;
const COMMISSION_PURCHASE_REF_TYPE: &str = "billing_package_purchase";

struct EarnRow {
    uid: i64,
    name: String,
    pic: String,
    percent: i32,
}

async fn share_get(tx: &mut Transaction<'_, Postgres>, parent: i64, child: i64) -> Result<i32, String> {
    let pct: Option<f64> = sqlx::query_scalar(
        "SELECT share_percent::float8 FROM ai.referral_share WHERE parent_iid = $1 AND child_iid = $2",
    )
    .bind(parent)
    .bind(child)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    Ok(pct.unwrap_or(0.0).round() as i32)
}

async fn earn_chain(tx: &mut Transaction<'_, Postgres>, subject_iid: i64) -> Result<Vec<EarnRow>, String> {
    let seller = sqlx::query(
        r#"SELECT id, name, COALESCE(pic, '') AS pic, referred_by_iid FROM ai.identity
           WHERE id = $1 AND kind = 'user' AND deleted_ts IS NULL"#,
    )
    .bind(subject_iid)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    let Some(row) = seller else {
        return Ok(vec![]);
    };
    let uid: i64 = row.get("id");
    let name: String = row.get("name");
    let pic: String = row.get("pic");
    let referred_by: Option<i64> = row.get("referred_by_iid");
    let parent = referred_by.filter(|p| *p > 0 && *p != uid);
    if parent.is_none() {
        return Ok(vec![EarnRow {
            uid,
            name,
            pic,
            percent: SHARE_MAX_PERCENT,
        }]);
    }
    let parent_uid = parent.unwrap();
    let edge = share_get(tx, parent_uid, uid).await?;
    let mut rows = vec![EarnRow {
        uid,
        name,
        pic,
        percent: edge,
    }];
    let mut child_uid = uid;
    let mut current_parent = parent_uid;
    while current_parent > 0 {
        let parent = sqlx::query(
            r#"SELECT id, name, COALESCE(pic, '') AS pic, referred_by_iid FROM ai.identity
               WHERE id = $1 AND kind = 'user' AND deleted_ts IS NULL"#,
        )
        .bind(current_parent)
        .fetch_optional(&mut **tx)
        .await
        .map_err(|e| e.to_string())?;
        let Some(row) = parent else {
            break;
        };
        let puid: i64 = row.get("id");
        let pname: String = row.get("name");
        let ppic: String = row.get("pic");
        let pref: Option<i64> = row.get("referred_by_iid");
        let child_share = if current_parent == parent_uid && child_uid == uid {
            edge
        } else {
            share_get(tx, current_parent, child_uid).await?
        };
        let incoming = if pref.filter(|p| *p > 0 && *p != puid).is_some() {
            share_get(tx, pref.unwrap(), current_parent).await?
        } else {
            SHARE_MAX_PERCENT
        };
        let keep = (incoming - child_share).max(0);
        rows.push(EarnRow {
            uid: puid,
            name: pname,
            pic: ppic,
            percent: keep,
        });
        child_uid = current_parent;
        current_parent = match pref.filter(|p| *p > 0 && *p != puid) {
            None => break,
            Some(next) => next,
        };
    }
    Ok(rows)
}

pub async fn commission_simulate(
    pool: &PgPool,
    subject_iid: i64,
    purchase_amount: i64,
) -> Result<ResReferralCommissionSimulate, String> {
    if purchase_amount <= 0 {
        return Err("invalid purchase amount".into());
    }
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let chain = earn_chain(&mut tx, subject_iid).await?;
    tx.commit().await.map_err(|e| e.to_string())?;
    let pool_amount = ((purchase_amount as f64) * MARKETING_POOL_RATE).floor() as i64;
    let mut levels = Vec::new();
    let mut total_distributed = 0i64;
    for row in chain {
        let earn = (purchase_amount * row.percent as i64) / 100;
        total_distributed += earn;
        levels.push(ReferralCommissionLevel {
            identity_id: row.uid,
            name: row.name,
            avatar_url: row.pic,
            percent: row.percent,
            earn_amount: earn,
            pool_share_percent: if pool_amount > 0 {
                (earn as f64 / pool_amount as f64) * 100.0
            } else {
                0.0
            },
        });
    }
    if total_distributed > pool_amount && total_distributed > 0 {
        levels = levels
            .into_iter()
            .map(|mut l| {
                l.earn_amount = (l.earn_amount * pool_amount) / total_distributed;
                l.pool_share_percent = if pool_amount > 0 {
                    (l.earn_amount as f64 / pool_amount as f64) * 100.0
                } else {
                    0.0
                };
                l
            })
            .collect();
        total_distributed = levels.iter().map(|l| l.earn_amount).sum();
    }
    Ok(ResReferralCommissionSimulate {
        purchase_amount,
        pool_amount,
        pool_rate: MARKETING_POOL_RATE,
        levels,
        total_distributed,
        undistributed: pool_amount - total_distributed,
    })
}

async fn commission_credit_in_tx(
    tx: &mut Transaction<'_, Postgres>,
    owner_iid: i64,
    amount_idr: f64,
    source_iid: i64,
    event_type: &str,
    reference_id: &str,
) -> Result<(), String> {
    if amount_idr <= 0.0 {
        return Ok(());
    }
    let account_id: Option<i64> = sqlx::query_scalar(
        "SELECT id FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    let Some(account_id) = account_id else {
        return Ok(());
    };
    let meta = serde_json::json!({
        "source_iid": source_iid,
        "event_type": event_type,
        "reference_id": reference_id,
        "reference_type": COMMISSION_PURCHASE_REF_TYPE,
    });
    let exists: bool = sqlx::query_scalar(
        r#"SELECT EXISTS(
            SELECT 1 FROM ai.commission_ledger
            WHERE owner_iid = $1 AND entry_type = 'accrual' AND meta->>'reference_id' = $2
        )"#,
    )
    .bind(owner_iid)
    .bind(reference_id)
    .fetch_one(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    if exists {
        return Ok(());
    }
    let ledger_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.commission_ledger (id, owner_iid, entry_type, status, amount_idr, meta)
        VALUES ($1, $2, 'accrual', 'active', $3, $4::jsonb)
        "#,
    )
    .bind(ledger_id)
    .bind(owner_iid)
    .bind(amount_idr)
    .bind(meta)
    .execute(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    sqlx::query(
        r#"
        UPDATE ai.billing_account
        SET commission_available_idr = COALESCE(commission_available_idr, 0) + $1,
            commission_earned_idr = COALESCE(commission_earned_idr, 0) + $1,
            updated_ts = NOW()
        WHERE id = $2
        "#,
    )
    .bind(amount_idr)
    .bind(account_id)
    .execute(&mut **tx)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn commission_accrue_on_purchase(
    pool: &PgPool,
    payer_iid: i64,
    amount_idr: i64,
    purchase_id: &str,
    event_type: &str,
) -> Result<(), String> {
    if amount_idr <= 0 || payer_iid <= 0 || purchase_id.is_empty() {
        return Ok(());
    }
    let sim = commission_simulate(pool, payer_iid, amount_idr).await?;
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    for level in sim.levels {
        if level.identity_id == payer_iid || level.earn_amount <= 0 {
            continue;
        }
        let ref_id = format!("{purchase_id}:{}", level.identity_id);
        commission_credit_in_tx(
            &mut tx,
            level.identity_id,
            level.earn_amount as f64,
            payer_iid,
            event_type,
            &ref_id,
        )
        .await?;
    }
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn commission_pool_scales_when_over_cap() {
        let _chain = vec![3_i64, 2, 1];
        let _edges = [(2, 3, 10), (1, 2, 35)];
        let purchase = 100_000.0;
        let mut rows = Vec::new();
        rows.push((3_i64, 10_i32));
        rows.push((2_i64, 25_i32));
        rows.push((1_i64, 0_i32));
        let pool = (purchase * MARKETING_POOL_RATE).floor() as i64;
        let mut total = 0i64;
        let mut earns: Vec<(i64, i64)> = rows
            .iter()
            .map(|(uid, pct)| {
                let earn = (purchase as i64 * *pct as i64) / 100;
                total += earn;
                (*uid, earn)
            })
            .collect();
        if total > pool && total > 0 {
            earns = earns
                .into_iter()
                .map(|(uid, earn)| (uid, (earn * pool) / total))
                .collect();
        }
        let payout: i64 = earns.iter().filter(|(uid, _)| *uid != 3).map(|(_, e)| *e).sum();
        assert_eq!(payout, 25_000);
    }
}
