CREATE TABLE IF NOT EXISTS ai.device_egress_lease (
    lease_id BIGINT PRIMARY KEY,
    device_iid BIGINT NOT NULL,
    owner_iid BIGINT NOT NULL,
    req_id TEXT NOT NULL DEFAULT '',
    secret_hash TEXT NOT NULL,
    allow_hosts_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    expires_ts TIMESTAMPTZ NOT NULL,
    revoked_ts TIMESTAMPTZ,
    created_ts TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_egress_lease_device
    ON ai.device_egress_lease (device_iid)
    WHERE revoked_ts IS NULL;
