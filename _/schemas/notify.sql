CREATE TABLE IF NOT EXISTS ai.notify (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    title           TEXT NOT NULL DEFAULT '',
    body            TEXT NOT NULL DEFAULT '',
    fire_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status          VARCHAR(16) NOT NULL DEFAULT 'scheduled',
    channels        TEXT NOT NULL DEFAULT '',
    route_json      JSONB NOT NULL DEFAULT '{}',
    req_id          VARCHAR(64) NOT NULL DEFAULT '',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_ts         TIMESTAMPTZ,
    read_ts         TIMESTAMPTZ,
    deleted_ts      TIMESTAMPTZ,
    CONSTRAINT chk_notify_status CHECK (
        status IN ('scheduled', 'waiting', 'sent', 'read', 'cancelled')
    )
);

CREATE INDEX IF NOT EXISTS idx_notify_inbox
    ON ai.notify (owner_iid, created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_notify_due
    ON ai.notify (fire_at)
    WHERE status = 'scheduled' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_notify_wait_req
    ON ai.notify (req_id)
    WHERE status = 'waiting' AND deleted_ts IS NULL AND req_id <> '';

CREATE INDEX IF NOT EXISTS idx_notify_owner_sync
    ON ai.notify (owner_iid, updated_ts);

CREATE TABLE IF NOT EXISTS ai.app_conn (
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    client_id       TEXT NOT NULL,
    resumed         BOOLEAN NOT NULL DEFAULT FALSE,
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (owner_iid, client_id)
);

CREATE INDEX IF NOT EXISTS idx_app_conn_owner
    ON ai.app_conn (owner_iid, updated_ts DESC);

CREATE TABLE IF NOT EXISTS ai.fcm_token (
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    client_id       TEXT NOT NULL,
    token           TEXT NOT NULL,
    platform        VARCHAR(16) NOT NULL DEFAULT '',
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (owner_iid, client_id),
    CONSTRAINT chk_fcm_platform CHECK (platform IN ('android', 'ios'))
);
