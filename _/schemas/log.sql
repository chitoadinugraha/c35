-- ==============================================================================
-- c35 — Log schema (LOCKED 2026-09-20)
-- Apply after identity.sql (+ billing.sql for FK context)
-- Single table: audit timeline + billing trace (no log_billing / usage tables)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.log (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    kind                VARCHAR(32) NOT NULL,
    topic               VARCHAR(32) NOT NULL DEFAULT '',
    dv                  TEXT NOT NULL DEFAULT '',

    req_id              VARCHAR(64) NOT NULL DEFAULT '',
    chat_id             BIGINT,
    task_id             BIGINT,
    device_iid          BIGINT REFERENCES ai.identity(id),

    text                TEXT NOT NULL DEFAULT '',
    model               VARCHAR(64) NOT NULL DEFAULT '',

    tokens_in           INT NOT NULL DEFAULT 0,
    tokens_out          INT NOT NULL DEFAULT 0,
    duration_ms         INT NOT NULL DEFAULT 0,
    cost_usd            NUMERIC(12, 6) NOT NULL DEFAULT 0,

    meta                JSONB NOT NULL DEFAULT '{}',

    event_kind          VARCHAR(64) NOT NULL DEFAULT '',
    subject             TEXT NOT NULL DEFAULT '',
    class               VARCHAR(16) NOT NULL DEFAULT 'trace',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_log_kind CHECK (
        kind IN ('conn', 'error', 'system', 'llm', 'tool', 'task')
    ),
    CONSTRAINT chk_log_cost_nonneg CHECK (cost_usd >= 0)
);

CREATE INDEX IF NOT EXISTS idx_log_owner_sync
    ON ai.log (owner_iid, updated_ts);

CREATE INDEX IF NOT EXISTS idx_log_chat
    ON ai.log (chat_id, created_ts DESC)
    WHERE chat_id IS NOT NULL AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_log_req
    ON ai.log (req_id)
    WHERE req_id <> '';

CREATE INDEX IF NOT EXISTS idx_log_owner_kind
    ON ai.log (owner_iid, kind, created_ts DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_log_live_tail
    ON ai.log (owner_iid, dv, topic, created_ts DESC)
    WHERE deleted_ts IS NULL;

-- MCP log tail / trace (created_ts DESC)
CREATE INDEX IF NOT EXISTS idx_log_owner_created_desc
    ON ai.log (owner_iid, created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_log_created_desc
    ON ai.log (created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_log_owner_req_created
    ON ai.log (owner_iid, req_id, created_ts DESC)
    WHERE deleted_ts IS NULL AND req_id <> '';

CREATE INDEX IF NOT EXISTS idx_log_owner_event_kind_created
    ON ai.log (owner_iid, event_kind, created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL AND event_kind <> '';

CREATE INDEX IF NOT EXISTS idx_log_class_owner_created
    ON ai.log (owner_iid, class, created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL;

ALTER TABLE ai.billing_usage_dedupe DROP CONSTRAINT IF EXISTS fk_billing_usage_dedupe_log;
ALTER TABLE ai.billing_usage_dedupe
    ADD CONSTRAINT fk_billing_usage_dedupe_log
    FOREIGN KEY (log_id) REFERENCES ai.log(id);
