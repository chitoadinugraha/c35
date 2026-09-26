-- ==============================================================================
-- c35   Platform ops metrics (1-minute rollups)
-- Live: NATS c35.stats.* @ 2s + JetStream KV c35_stats (latest).
-- History: c_node_stats flushes UTC-minute buckets when DATABASE_URL is set.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.ops_metric_1m (
    ts_min              TIMESTAMPTZ NOT NULL,
    entity_type         TEXT NOT NULL,
    entity_id           TEXT NOT NULL,
    node_name           TEXT NOT NULL DEFAULT '',

    cpu_max             DOUBLE PRECISION,
    mem_used_max        BIGINT,
    mem_total_last      BIGINT,
    net_in_max          DOUBLE PRECISION,
    net_out_max         DOUBLE PRECISION,

    disk_device         TEXT,
    disk_used_last      BIGINT,
    disk_total_last     BIGINT,
    disk_read_max       DOUBLE PRECISION,
    disk_write_max      DOUBLE PRECISION,

    vol_namespace       TEXT,
    vol_pvc             TEXT,
    vol_used_last       BIGINT,
    vol_capacity_last   BIGINT,

    PRIMARY KEY (ts_min, entity_type, entity_id),

    CONSTRAINT chk_ops_metric_entity CHECK (entity_type IN ('node', 'disk', 'volume'))
);

CREATE INDEX IF NOT EXISTS idx_ops_metric_1m_node_ts
    ON ai.ops_metric_1m (node_name, ts_min DESC);

CREATE INDEX IF NOT EXISTS idx_ops_metric_1m_type_ts
    ON ai.ops_metric_1m (entity_type, ts_min DESC);
