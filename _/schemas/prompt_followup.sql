CREATE TABLE IF NOT EXISTS ai.prompt_followup (
    id                  TEXT PRIMARY KEY,
    req_id              TEXT NOT NULL,
    chat_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL,
    seq                 INT NOT NULL,
    kind                TEXT NOT NULL,
    status              TEXT NOT NULL DEFAULT 'pending',
    text                TEXT NOT NULL DEFAULT '',
    attachments_json    TEXT NOT NULL DEFAULT '[]',
    source              TEXT NOT NULL DEFAULT 'app',
    external_dedup_key  TEXT,
    reject_reason       TEXT,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_ts        TIMESTAMPTZ,
    CONSTRAINT chk_prompt_followup_kind CHECK (kind IN ('steer', 'queue')),
    CONSTRAINT chk_prompt_followup_status CHECK (
        status IN ('pending', 'delivered', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_prompt_followup_source CHECK (source IN ('app', 'channel'))
);

CREATE INDEX IF NOT EXISTS idx_prompt_followup_req_pending
    ON ai.prompt_followup (req_id, seq)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_prompt_followup_chat_pending
    ON ai.prompt_followup (chat_id, created_ts DESC)
    WHERE status = 'pending';

CREATE UNIQUE INDEX IF NOT EXISTS uq_prompt_followup_external_dedup
    ON ai.prompt_followup (external_dedup_key)
    WHERE external_dedup_key IS NOT NULL AND status = 'pending';
