use anyhow::Result;
use c35_proto::{
    ReqScopeInstructionGet, ReqScopeInstructionPut, ResScopeInstructionGet, ResScopeInstructionPut,
    ScopeInstruction,
};
use chrono::Utc;
use sqlx::PgPool;

use crate::scope_instruction::{scope_instruction_get, scope_instruction_put, ScopeInstructionRow};

fn row_to_proto(row: &ScopeInstructionRow, updated_ts_ms: i64) -> ScopeInstruction {
    ScopeInstruction {
        id: row.id,
        owner_iid: row.owner_iid,
        scope_kind: row.scope_kind.clone(),
        scope_iid: row.scope_iid,
        mode: row.mode.clone(),
        body: row.body.clone(),
        updated_ts_ms,
    }
}

async fn updated_ts_ms(pool: &PgPool, row: &ScopeInstructionRow) -> i64 {
    if row.id <= 0 {
        return 0;
    }
    sqlx::query_scalar::<_, Option<chrono::DateTime<Utc>>>(
        "SELECT updated_ts FROM ai.scope_instruction WHERE id = $1",
    )
    .bind(row.id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .flatten()
    .map(|t| t.timestamp_millis())
    .unwrap_or(0)
}

pub async fn scope_instruction_get_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqScopeInstructionGet,
) -> Result<ResScopeInstructionGet> {
    let row = scope_instruction_get(pool, caller_iid, &req.scope_kind, req.scope_iid).await?;
    let ts = updated_ts_ms(pool, &row).await;
    Ok(ResScopeInstructionGet {
        instruction: Some(row_to_proto(&row, ts)),
    })
}

pub async fn scope_instruction_put_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqScopeInstructionPut,
) -> Result<ResScopeInstructionPut> {
    let row = scope_instruction_put(
        pool,
        caller_iid,
        &req.scope_kind,
        req.scope_iid,
        &req.mode,
        &req.body,
    )
    .await?;
    let ts = updated_ts_ms(pool, &row).await;
    Ok(ResScopeInstructionPut {
        instruction: Some(row_to_proto(&row, ts)),
    })
}
