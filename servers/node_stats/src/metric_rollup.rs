use std::collections::HashMap;

use anyhow::Result;
use c35_proto::{DiskDeviceStat, NodeStat, VolumeStat};
use chrono::{DateTime, Timelike, Utc};
use sqlx::PgPool;
use tracing::warn;

#[derive(Clone, Debug, Default)]
struct NodeAccum {
    cpu_max: f64,
    mem_used_max: u64,
    mem_total_last: u64,
    net_in_max: f64,
    net_out_max: f64,
}

#[derive(Clone, Debug, Default)]
struct DiskAccum {
    disk_used_last: u64,
    disk_total_last: u64,
    read_max: f64,
    write_max: f64,
}

#[derive(Clone, Debug, Default)]
struct VolumeAccum {
    namespace: String,
    pvc_name: String,
    vol_used_last: u64,
    vol_capacity_last: u64,
}

#[derive(Clone, Debug)]
struct MinuteBucket {
    minute: DateTime<Utc>,
    node_name: String,
    node: NodeAccum,
    disks: HashMap<String, DiskAccum>,
    volumes: HashMap<String, VolumeAccum>,
}

impl MinuteBucket {
    fn new(minute: DateTime<Utc>, node_name: String) -> Self {
        Self {
            minute,
            node_name,
            node: NodeAccum::default(),
            disks: HashMap::new(),
            volumes: HashMap::new(),
        }
    }
}

pub struct MetricRollup {
    bucket: MinuteBucket,
    pool: Option<PgPool>,
}

impl MetricRollup {
    pub fn new(node_name: String, pool: Option<PgPool>) -> Self {
        let minute = truncate_minute(Utc::now());
        Self {
            bucket: MinuteBucket::new(minute, node_name),
            pool,
        }
    }

    pub fn observe_node(&mut self, stat: &NodeStat) {
        let ts = sample_ts(stat.ts_ms);
        self.advance(ts);
        let n = &mut self.bucket.node;
        n.cpu_max = n.cpu_max.max(stat.cpu_pct);
        n.mem_used_max = n.mem_used_max.max(stat.mem_used_bytes);
        n.mem_total_last = stat.mem_total_bytes;
        n.net_in_max = n.net_in_max.max(stat.net_in_bps);
        n.net_out_max = n.net_out_max.max(stat.net_out_bps);
        for d in &stat.devices {
            self.observe_disk(d);
        }
    }

    pub fn observe_volume(&mut self, stat: &VolumeStat) {
        let ts = sample_ts(crate::host::now_ms());
        self.advance(ts);
        let key = volume_key(&stat.namespace, &stat.pvc_name);
        let v = self.bucket.volumes.entry(key).or_insert_with(|| VolumeAccum {
            namespace: stat.namespace.clone(),
            pvc_name: stat.pvc_name.clone(),
            vol_used_last: 0,
            vol_capacity_last: 0,
        });
        v.vol_used_last = stat.used_bytes;
        v.vol_capacity_last = stat.capacity_bytes;
    }

    fn observe_disk(&mut self, d: &DiskDeviceStat) {
        let acc = self.bucket.disks.entry(d.device.clone()).or_default();
        acc.disk_used_last = d.used_bytes;
        acc.disk_total_last = d.total_bytes;
        acc.read_max = acc.read_max.max(d.read_bps);
        acc.write_max = acc.write_max.max(d.write_bps);
    }

    fn advance(&mut self, ts: DateTime<Utc>) {
        let m = truncate_minute(ts);
        if m > self.bucket.minute {
            let flush = self.bucket.clone();
            self.bucket = MinuteBucket::new(m, flush.node_name.clone());
            if let Some(pool) = self.pool.clone() {
                tokio::spawn(async move {
                    if let Err(e) = flush_minute(&pool, &flush).await {
                        warn!(error = %e, "ops_metric_1m flush failed");
                    }
                });
            }
        }
    }
}

async fn flush_minute(pool: &PgPool, bucket: &MinuteBucket) -> Result<()> {
    let node = &bucket.node;
    upsert_row(
        pool,
        bucket.minute,
        "node",
        &bucket.node_name,
        &bucket.node_name,
        Some(node.cpu_max),
        Some(node.mem_used_max as i64),
        Some(node.mem_total_last as i64),
        Some(node.net_in_max),
        Some(node.net_out_max),
        None,
        None,
        None,
        None,
        None,
        None,
        None,
        None,
        None,
    )
    .await?;

    for (device, d) in &bucket.disks {
        let entity_id = format!("{}/{}", bucket.node_name, device);
        upsert_row(
            pool,
            bucket.minute,
            "disk",
            &entity_id,
            &bucket.node_name,
            None,
            None,
            None,
            None,
            None,
            Some(device.as_str()),
            Some(d.disk_used_last as i64),
            Some(d.disk_total_last as i64),
            Some(d.read_max),
            Some(d.write_max),
            None,
            None,
            None,
            None,
        )
        .await?;
    }

    for (_key, v) in &bucket.volumes {
        let entity_id = format!("{}/{}", v.namespace, v.pvc_name);
        upsert_row(
            pool,
            bucket.minute,
            "volume",
            &entity_id,
            &bucket.node_name,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            Some(v.namespace.as_str()),
            Some(v.pvc_name.as_str()),
            Some(v.vol_used_last as i64),
            Some(v.vol_capacity_last as i64),
        )
        .await?;
    }
    Ok(())
}

#[allow(clippy::too_many_arguments)]
async fn upsert_row(
    pool: &PgPool,
    ts_min: DateTime<Utc>,
    entity_type: &str,
    entity_id: &str,
    node_name: &str,
    cpu_max: Option<f64>,
    mem_used_max: Option<i64>,
    mem_total_last: Option<i64>,
    net_in_max: Option<f64>,
    net_out_max: Option<f64>,
    disk_device: Option<&str>,
    disk_used_last: Option<i64>,
    disk_total_last: Option<i64>,
    disk_read_max: Option<f64>,
    disk_write_max: Option<f64>,
    vol_namespace: Option<&str>,
    vol_pvc: Option<&str>,
    vol_used_last: Option<i64>,
    vol_capacity_last: Option<i64>,
) -> Result<()> {
    sqlx::query(
        r"
        INSERT INTO ai.ops_metric_1m (
            ts_min, entity_type, entity_id, node_name,
            cpu_max, mem_used_max, mem_total_last,
            net_in_max, net_out_max,
            disk_device, disk_used_last, disk_total_last, disk_read_max, disk_write_max,
            vol_namespace, vol_pvc, vol_used_last, vol_capacity_last
        ) VALUES (
            $1, $2, $3, $4,
            $5, $6, $7,
            $8, $9,
            $10, $11, $12, $13, $14,
            $15, $16, $17, $18
        )
        ON CONFLICT (ts_min, entity_type, entity_id) DO UPDATE SET
            node_name = EXCLUDED.node_name,
            cpu_max = COALESCE(GREATEST(ai.ops_metric_1m.cpu_max, EXCLUDED.cpu_max), EXCLUDED.cpu_max),
            mem_used_max = COALESCE(GREATEST(ai.ops_metric_1m.mem_used_max, EXCLUDED.mem_used_max), EXCLUDED.mem_used_max),
            mem_total_last = COALESCE(EXCLUDED.mem_total_last, ai.ops_metric_1m.mem_total_last),
            net_in_max = COALESCE(GREATEST(ai.ops_metric_1m.net_in_max, EXCLUDED.net_in_max), EXCLUDED.net_in_max),
            net_out_max = COALESCE(GREATEST(ai.ops_metric_1m.net_out_max, EXCLUDED.net_out_max), EXCLUDED.net_out_max),
            disk_device = COALESCE(EXCLUDED.disk_device, ai.ops_metric_1m.disk_device),
            disk_used_last = COALESCE(EXCLUDED.disk_used_last, ai.ops_metric_1m.disk_used_last),
            disk_total_last = COALESCE(EXCLUDED.disk_total_last, ai.ops_metric_1m.disk_total_last),
            disk_read_max = COALESCE(GREATEST(ai.ops_metric_1m.disk_read_max, EXCLUDED.disk_read_max), EXCLUDED.disk_read_max),
            disk_write_max = COALESCE(GREATEST(ai.ops_metric_1m.disk_write_max, EXCLUDED.disk_write_max), EXCLUDED.disk_write_max),
            vol_namespace = COALESCE(EXCLUDED.vol_namespace, ai.ops_metric_1m.vol_namespace),
            vol_pvc = COALESCE(EXCLUDED.vol_pvc, ai.ops_metric_1m.vol_pvc),
            vol_used_last = COALESCE(EXCLUDED.vol_used_last, ai.ops_metric_1m.vol_used_last),
            vol_capacity_last = COALESCE(EXCLUDED.vol_capacity_last, ai.ops_metric_1m.vol_capacity_last)
        ",
    )
    .bind(ts_min)
    .bind(entity_type)
    .bind(entity_id)
    .bind(node_name)
    .bind(cpu_max)
    .bind(mem_used_max)
    .bind(mem_total_last)
    .bind(net_in_max)
    .bind(net_out_max)
    .bind(disk_device)
    .bind(disk_used_last)
    .bind(disk_total_last)
    .bind(disk_read_max)
    .bind(disk_write_max)
    .bind(vol_namespace)
    .bind(vol_pvc)
    .bind(vol_used_last)
    .bind(vol_capacity_last)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn pg_pool_from_env() -> Option<PgPool> {
    let url = std::env::var("DATABASE_URL").ok().filter(|s| !s.trim().is_empty())?;
    match sqlx::postgres::PgPoolOptions::new()
        .max_connections(2)
        .connect(&url)
        .await
    {
        Ok(pool) => Some(pool),
        Err(e) => {
            warn!(error = %e, "DATABASE_URL connect failed; skipping YB rollup");
            None
        }
    }
}

fn sample_ts(ts_ms: i64) -> DateTime<Utc> {
    DateTime::from_timestamp_millis(ts_ms).unwrap_or_else(Utc::now)
}

pub fn truncate_minute(ts: DateTime<Utc>) -> DateTime<Utc> {
    ts.with_second(0)
        .and_then(|t| t.with_nanosecond(0))
        .unwrap_or(ts)
}

fn volume_key(namespace: &str, pvc_name: &str) -> String {
    format!("{namespace}/{pvc_name}")
}
