use crate::{require_root, AdminError};
use c35_proto::{OpsMetric1mRow, ReqAdminOpsPeaks, ResAdminOpsPeaks};
use sqlx::{PgPool, QueryBuilder, Row};

pub async fn admin_ops_peaks(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminOpsPeaks,
) -> Result<ResAdminOpsPeaks, AdminError> {
    require_root(pool, viewer_iid).await?;
    let since = chrono::DateTime::from_timestamp_millis(req.since_ms)
        .ok_or_else(|| AdminError::bad("since_ms invalid"))?;
    let until = chrono::DateTime::from_timestamp_millis(req.until_ms)
        .ok_or_else(|| AdminError::bad("until_ms invalid"))?;

    let mut qb = QueryBuilder::new(
        r#"
        SELECT
            (EXTRACT(EPOCH FROM ts_min) * 1000)::bigint AS ts_min_ms,
            entity_type, entity_id, node_name,
            cpu_max, mem_used_max, mem_total_last, net_in_max, net_out_max,
            disk_device, disk_used_last, disk_total_last,
            vol_namespace, vol_pvc, vol_used_last, vol_capacity_last
        FROM ai.ops_metric_1m
        WHERE ts_min >= "#,
    );
    qb.push_bind(since);
    qb.push(" AND ts_min < ");
    qb.push_bind(until);
    if let Some(t) = req.entity_type.as_deref().filter(|s| !s.is_empty()) {
        qb.push(" AND entity_type = ");
        qb.push_bind(t);
    }
    if let Some(n) = req.node_name.as_deref().filter(|s| !s.is_empty()) {
        qb.push(" AND node_name = ");
        qb.push_bind(n);
    }
    qb.push(" ORDER BY ts_min ASC LIMIT 10000");

    let rows = qb
        .build()
        .fetch_all(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;

    let mut peak_cpu_max = 0.0f64;
    let mut peak_mem_pct_max = 0.0f64;
    let mut out = Vec::with_capacity(rows.len());
    for r in rows {
        let entity_type: String = r.get("entity_type");
        let cpu_max: Option<f64> = r.get("cpu_max");
        let mem_used_max: Option<i64> = r.get("mem_used_max");
        let mem_total_last: Option<i64> = r.get("mem_total_last");
        if entity_type == "node" {
            if let Some(cpu) = cpu_max {
                peak_cpu_max = peak_cpu_max.max(cpu);
            }
            if let (Some(used), Some(total)) = (mem_used_max, mem_total_last) {
                if total > 0 {
                    peak_mem_pct_max =
                        peak_mem_pct_max.max(used as f64 / total as f64 * 100.0);
                }
            }
        }
        out.push(OpsMetric1mRow {
            ts_min_ms: r.get("ts_min_ms"),
            entity_type,
            entity_id: r.get("entity_id"),
            node_name: r.get("node_name"),
            cpu_max,
            mem_used_max,
            net_in_max: r.get("net_in_max"),
            net_out_max: r.get("net_out_max"),
            disk_device: r.get("disk_device"),
            disk_used_last: r.get("disk_used_last"),
            disk_total_last: r.get("disk_total_last"),
            vol_namespace: r.get("vol_namespace"),
            vol_pvc: r.get("vol_pvc"),
            vol_used_last: r.get("vol_used_last"),
            vol_capacity_last: r.get("vol_capacity_last"),
        });
    }

    Ok(ResAdminOpsPeaks {
        rows: out,
        peak_cpu_max,
        peak_mem_pct_max,
    })
}