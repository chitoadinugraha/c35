use anyhow::{anyhow, Result};
use c35_proto::{ReqIdentityDelete, ResIdentityDelete};
use sqlx::{PgPool, Row};

pub async fn identity_delete(pool: &PgPool, caller_iid: i64, req: ReqIdentityDelete) -> Result<ResIdentityDelete> {
    let iid = req.iid;
    if iid <= 0 {
        return Ok(ResIdentityDelete {
            ok: false,
            error: "iid required".into(),
        });
    }
    let row = sqlx::query(
        r#"
        SELECT kind, owner_iid
        FROM ai.identity
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(iid)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(ResIdentityDelete {
            ok: false,
            error: "identity not found".into(),
        });
    };
    let owner_iid: i64 = row.get("owner_iid");
    if owner_iid != caller_iid {
        return Ok(ResIdentityDelete {
            ok: false,
            error: "forbidden".into(),
        });
    }
    let kind: String = row.get("kind");
    let mut tx = pool.begin().await?;
    sqlx::query("UPDATE ai.identity SET deleted_ts = NOW(), updated_ts = NOW() WHERE id = $1")
        .bind(iid)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE ai.identity_grant SET deleted_ts = NOW(), updated_ts = NOW() WHERE resource_iid = $1 AND deleted_ts IS NULL")
        .bind(iid)
        .execute(&mut *tx)
        .await?;
    if kind == "bot" {
        sqlx::query("UPDATE ai.chat SET deleted_ts = NOW(), updated_ts = NOW() WHERE bot_iid = $1 AND deleted_ts IS NULL")
            .bind(iid)
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok(ResIdentityDelete {
        ok: true,
        error: String::new(),
    })
}

pub async fn identity_kind_get(pool: &PgPool, iid: i64) -> Result<String> {
    let kind = sqlx::query_scalar::<_, Option<String>>(
        "SELECT kind FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(iid)
    .fetch_optional(pool)
    .await?
    .flatten()
    .ok_or_else(|| anyhow!("identity not found"))?;
    Ok(kind)
}
