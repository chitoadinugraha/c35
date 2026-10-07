use anyhow::Result;
use c35_proto::{ReqMemoryDelete, ReqMemoryList, ResMemoryDelete, ResMemoryList, UserMemory};
use sqlx::PgPool;

pub async fn memory_list_rpc(pool: &PgPool, owner_iid: i64, req: ReqMemoryList) -> Result<ResMemoryList> {
    let limit = if req.limit <= 0 { 100 } else { req.limit.min(200) };
    let rows = sqlx::query_as::<_, (i64, i64, Option<i64>, String, String, String, f64)>(
        "SELECT id, owner_iid, bot_iid, category, key, content, confidence::float8 \
         FROM ai.memory \
         WHERE owner_iid = $1 AND is_active = true AND deleted_ts IS NULL \
         ORDER BY updated_ts DESC \
         LIMIT $2",
    )
    .bind(owner_iid)
    .bind(limit as i64)
    .fetch_all(pool)
    .await?;

    let items = rows
        .into_iter()
        .map(|(id, owner, bot_iid, category, key, content, confidence)| UserMemory {
            id,
            owner_iid: owner,
            bot_iid: bot_iid.unwrap_or(0),
            category,
            key,
            content,
            confidence,
        })
        .collect();

    Ok(ResMemoryList { items })
}

pub async fn memory_delete_rpc(pool: &PgPool, owner_iid: i64, req: ReqMemoryDelete) -> Result<ResMemoryDelete> {
    if req.id <= 0 {
        return Ok(ResMemoryDelete { ok: false });
    }
    let res = sqlx::query(
        "UPDATE ai.memory SET is_active = false, deleted_ts = NOW(), updated_ts = NOW() \
         WHERE id = $1 AND owner_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(req.id)
    .bind(owner_iid)
    .execute(pool)
    .await?;
    Ok(ResMemoryDelete { ok: res.rows_affected() > 0 })
}
