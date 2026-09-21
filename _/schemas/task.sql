-- ==============================================================================
-- c35 — Task schema (LOCKED 2026-09-21)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: ai
--
-- Port: cs_agent task + task_trigger + task_run; device_iid replaces space_id.
-- Dispatch: NATS JetStream (see _/docs/remote.md) — no YB polling for work.
-- Sync: owner-scoped rows with created_ts, updated_ts, deleted_ts.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

-- ------------------------------------------------------------------------------
-- Task definition (Devices → Task tab)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.task (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    device_iid          BIGINT NOT NULL REFERENCES ai.identity(id),

    name                VARCHAR(128) NOT NULL DEFAULT '',
    skill_id            BIGINT NOT NULL DEFAULT 0,
    prompt              TEXT NOT NULL DEFAULT '',
    model               VARCHAR(64) NOT NULL DEFAULT 'cloud',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_task_owner_sync
    ON ai.task (owner_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_task_device_sync
    ON ai.task (device_iid, updated_ts)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Task trigger (once | cron | webhook)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.task_trigger (
    id                  BIGINT PRIMARY KEY,
    task_id             BIGINT NOT NULL REFERENCES ai.task(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    kind                VARCHAR(16) NOT NULL DEFAULT 'once',
    label               VARCHAR(64) NOT NULL DEFAULT '',
    cron_expr           VARCHAR(64) NOT NULL DEFAULT '',
    timezone            VARCHAR(64) NOT NULL DEFAULT 'UTC',
    run_at              TIMESTAMPTZ,
    webhook_secret      VARCHAR(128) NOT NULL DEFAULT '',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_task_trigger_kind CHECK (
        kind IN ('once', 'cron', 'webhook')
    )
);

CREATE INDEX IF NOT EXISTS idx_task_trigger_task
    ON ai.task_trigger (task_id, updated_ts);
CREATE INDEX IF NOT EXISTS idx_task_trigger_owner_sync
    ON ai.task_trigger (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Task run (execution instance — server-orchestrated)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.task_run (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    device_iid          BIGINT NOT NULL REFERENCES ai.identity(id),

    task_id             BIGINT NOT NULL DEFAULT 0,
    trigger_id          BIGINT NOT NULL DEFAULT 0,
    chat_id             BIGINT NOT NULL DEFAULT 0,

    req_id              VARCHAR(64) NOT NULL DEFAULT '',
    status              VARCHAR(16) NOT NULL DEFAULT 'queued',

    prompt              TEXT NOT NULL DEFAULT '',
    skill_id            BIGINT NOT NULL DEFAULT 0,
    model               VARCHAR(64) NOT NULL DEFAULT 'cloud',

    step_index          INT NOT NULL DEFAULT 0,
    summary             TEXT NOT NULL DEFAULT '',
    error               TEXT NOT NULL DEFAULT '',

    lease_pod           VARCHAR(64) NOT NULL DEFAULT '',
    lease_expires_ts    TIMESTAMPTZ,
    nats_stream_seq     BIGINT NOT NULL DEFAULT 0,

    started_ts          TIMESTAMPTZ,
    finished_ts         TIMESTAMPTZ,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_task_run_status CHECK (
        status IN ('queued', 'leased', 'running', 'done', 'failed', 'cancelled')
    )
);

CREATE INDEX IF NOT EXISTS idx_task_run_owner_sync
    ON ai.task_run (owner_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_task_run_device_sync
    ON ai.task_run (device_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_task_run_device_status
    ON ai.task_run (device_iid, status, updated_ts)
    WHERE deleted_ts IS NULL AND status IN ('queued', 'leased', 'running');
CREATE INDEX IF NOT EXISTS idx_task_run_task
    ON ai.task_run (task_id, created_ts DESC)
    WHERE task_id <> 0;
