use serde::Serialize;
use sqlx::{PgPool, Row};

#[derive(Debug, Clone, Serialize)]
pub struct ScopeUsageRow {
    pub scope_kind: String,
    pub scope_iid: i64,
    pub label: String,
    pub alien_id: String,
    pub attributed_bytes: i64,
    pub blob_count: i64,
}

#[derive(Debug, Clone, Serialize)]
pub struct StorageUsageReport {
    pub billable_owner_iid: i64,
    pub total_bytes: i64,
    pub distinct_blob_count: i64,
    pub scopes_attributed_sum_bytes: i64,
    pub personal: ScopeUsageRow,
    pub sites: Vec<ScopeUsageRow>,
    pub bots: Vec<ScopeUsageRow>,
    pub mailboxes: Vec<ScopeUsageRow>,
}

#[derive(Debug, Clone, Serialize)]
pub struct SingleScopeUsage {
    pub scope_kind: String,
    pub scope_iid: i64,
    pub label: String,
    pub alien_id: String,
    pub attributed_bytes: i64,
    pub blob_count: i64,
}

pub async fn storage_usage_account(
    pool: &PgPool,
    billable_owner_iid: i64,
    include_breakdown: bool,
) -> Result<StorageUsageReport, sqlx::Error> {
    let total_bytes: i64 = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(m.size_bytes), 0)::bigint
        FROM (
            SELECT DISTINCT hash_blake3 FROM ai.blob_ref WHERE billable_owner_iid = $1
        ) d
        JOIN ai.file_blob_meta m ON m.hash_blake3 = d.hash_blake3
        "#,
    )
    .bind(billable_owner_iid)
    .fetch_one(pool)
    .await?;

    let distinct_blob_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(DISTINCT hash_blake3)::bigint FROM ai.blob_ref WHERE billable_owner_iid = $1",
    )
    .bind(billable_owner_iid)
    .fetch_one(pool)
    .await?;

    let scopes_attributed_sum_bytes: i64 = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(m.size_bytes), 0)::bigint
        FROM ai.blob_ref br
        JOIN ai.file_blob_meta m ON m.hash_blake3 = br.hash_blake3
        WHERE br.billable_owner_iid = $1
        "#,
    )
    .bind(billable_owner_iid)
    .fetch_one(pool)
    .await?;

    let personal = if include_breakdown {
        scope_usage_row(pool, "user", billable_owner_iid, billable_owner_iid).await?
    } else {
        empty_scope_row("user", billable_owner_iid)
    };

    let sites = if include_breakdown {
        list_scope_usage(pool, billable_owner_iid, "site").await?
    } else {
        Vec::new()
    };
    let bots = if include_breakdown {
        list_scope_usage(pool, billable_owner_iid, "bot").await?
    } else {
        Vec::new()
    };
    let mailboxes = if include_breakdown {
        list_scope_usage(pool, billable_owner_iid, "mailbox").await?
    } else {
        Vec::new()
    };

    Ok(StorageUsageReport {
        billable_owner_iid,
        total_bytes,
        distinct_blob_count,
        scopes_attributed_sum_bytes,
        personal,
        sites,
        bots,
        mailboxes,
    })
}

fn empty_scope_row(kind: &str, scope_iid: i64) -> ScopeUsageRow {
    ScopeUsageRow {
        scope_kind: kind.to_string(),
        scope_iid,
        label: String::new(),
        alien_id: String::new(),
        attributed_bytes: 0,
        blob_count: 0,
    }
}

async fn list_scope_usage(
    pool: &PgPool,
    billable_owner_iid: i64,
    scope_kind: &str,
) -> Result<Vec<ScopeUsageRow>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT br.scope_iid,
               COALESCE(SUM(m.size_bytes), 0)::bigint AS bytes,
               COUNT(*)::bigint AS blob_count
        FROM ai.blob_ref br
        JOIN ai.file_blob_meta m ON m.hash_blake3 = br.hash_blake3
        WHERE br.billable_owner_iid = $1 AND br.scope_kind = $2
        GROUP BY br.scope_iid
        ORDER BY bytes DESC
        "#,
    )
    .bind(billable_owner_iid)
    .bind(scope_kind)
    .fetch_all(pool)
    .await?;

    let mut out = Vec::new();
    for r in rows {
        let scope_iid: i64 = r.get("scope_iid");
        let row = scope_usage_row(pool, scope_kind, scope_iid, billable_owner_iid).await?;
        out.push(row);
    }
    Ok(out)
}

async fn scope_usage_row(
    pool: &PgPool,
    scope_kind: &str,
    scope_iid: i64,
    billable_owner_iid: i64,
) -> Result<ScopeUsageRow, sqlx::Error> {
    let agg = sqlx::query(
        r#"
        SELECT COALESCE(SUM(m.size_bytes), 0)::bigint AS bytes,
               COUNT(*)::bigint AS blob_count
        FROM ai.blob_ref br
        JOIN ai.file_blob_meta m ON m.hash_blake3 = br.hash_blake3
        WHERE br.billable_owner_iid = $3 AND br.scope_kind = $1 AND br.scope_iid = $2
        "#,
    )
    .bind(scope_kind)
    .bind(scope_iid)
    .bind(billable_owner_iid)
    .fetch_one(pool)
    .await?;
    let attributed_bytes: i64 = agg.get("bytes");
    let blob_count: i64 = agg.get("blob_count");

    let (label, alien_id) = match scope_kind {
        "user" => {
            let row = sqlx::query(
                "SELECT name, COALESCE(alien_id, '') AS alien_id FROM ai.identity WHERE id = $1",
            )
            .bind(scope_iid)
            .fetch_optional(pool)
            .await?;
            row.map(|r| (r.get::<String, _>("name"), r.get::<String, _>("alien_id")))
                .unwrap_or_default()
        }
        "site" | "bot" => {
            let row = sqlx::query(
                "SELECT name, COALESCE(alien_id, '') AS alien_id FROM ai.identity WHERE id = $1",
            )
            .bind(scope_iid)
            .fetch_optional(pool)
            .await?;
            row.map(|r| (r.get::<String, _>("name"), r.get::<String, _>("alien_id")))
                .unwrap_or_default()
        }
        "mailbox" => {
            let row = sqlx::query(
                "SELECT COALESCE(label, '') AS label, address FROM mail.mailbox WHERE id = $1 AND deleted_ts IS NULL",
            )
            .bind(scope_iid)
            .fetch_optional(pool)
            .await?;
            row.map(|r| {
                let addr: String = r.get("address");
                let lbl: String = r.get("label");
                if lbl.is_empty() {
                    (addr.clone(), addr)
                } else {
                    (lbl, addr)
                }
            })
            .unwrap_or_default()
        }
        _ => (String::new(), String::new()),
    };

    Ok(ScopeUsageRow {
        scope_kind: scope_kind.to_string(),
        scope_iid,
        label,
        alien_id,
        attributed_bytes,
        blob_count,
    })
}

pub async fn storage_usage_scope(
    pool: &PgPool,
    scope_kind: &str,
    scope_iid: i64,
    billable_owner_iid: i64,
) -> Result<SingleScopeUsage, sqlx::Error> {
    let row = scope_usage_row(pool, scope_kind, scope_iid, billable_owner_iid).await?;
    Ok(SingleScopeUsage {
        scope_kind: row.scope_kind,
        scope_iid: row.scope_iid,
        label: row.label,
        alien_id: row.alien_id,
        attributed_bytes: row.attributed_bytes,
        blob_count: row.blob_count,
    })
}
