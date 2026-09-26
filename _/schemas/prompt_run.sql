CREATE TABLE IF NOT EXISTS ai.prompt_run (
    req_id              TEXT PRIMARY KEY,
    chat_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL,
    parent_req_id       TEXT,
    kind                TEXT NOT NULL DEFAULT 'main',
    status              TEXT NOT NULL DEFAULT 'queued',
    topic_id            TEXT NOT NULL DEFAULT 'general',
    device_iid          BIGINT NOT NULL DEFAULT 0,
    text                TEXT NOT NULL DEFAULT '',
    mention_ids_json    JSONB NOT NULL DEFAULT '[]',
    tool_mode           TEXT NOT NULL DEFAULT 'agent',
    model               TEXT NOT NULL DEFAULT '',
    attachments_json    TEXT NOT NULL DEFAULT '[]',
    locale              TEXT NOT NULL DEFAULT '',
    cancel_requested    BOOLEAN NOT NULL DEFAULT FALSE,
    turn_count          INT NOT NULL DEFAULT 0,
    max_turns           INT NOT NULL DEFAULT 100,
    fail_class          TEXT,
    fail_reason         TEXT,
    checkpoint_json     JSONB NOT NULL DEFAULT '{}',
    budget_usd_cap      NUMERIC(12, 6) NOT NULL DEFAULT 0.50,
    accumulated_cost_usd NUMERIC(12, 6) NOT NULL DEFAULT 0,
    tokens_in           INT NOT NULL DEFAULT 0,
    tokens_out          INT NOT NULL DEFAULT 0,
    cost_usd            NUMERIC(12, 6) NOT NULL DEFAULT 0,
    duration_ms         INT NOT NULL DEFAULT 0,
    lease_pod           TEXT,
    lease_expires_ts    TIMESTAMPTZ,
    delivery_count      INT NOT NULL DEFAULT 0,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_prompt_run_status CHECK (
        status IN ('queued','running','waiting_child','done','failed','cancelled')
    ),
    CONSTRAINT chk_prompt_run_kind CHECK (
        kind IN ('main','research','computer_use','site_build','channel')
    )
);

ALTER TABLE ai.prompt_run ADD COLUMN IF NOT EXISTS steer_delivered_count INT NOT NULL DEFAULT 0;

ALTER TABLE ai.prompt_run DROP CONSTRAINT IF EXISTS chk_prompt_run_kind;
ALTER TABLE ai.prompt_run ADD CONSTRAINT chk_prompt_run_kind CHECK (
    kind IN ('main','research','computer_use','site_build','channel')
);

CREATE INDEX IF NOT EXISTS idx_prompt_run_chat ON ai.prompt_run (chat_id, created_ts DESC);
CREATE INDEX IF NOT EXISTS idx_prompt_run_parent ON ai.prompt_run (parent_req_id) WHERE parent_req_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prompt_run_owner_status ON ai.prompt_run (owner_iid, status, updated_ts DESC);
