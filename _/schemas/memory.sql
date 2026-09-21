-- ==============================================================================
-- c35 — Long-term user memory (FTS + optional embed recall)
-- Port: cs_bots ai.memory (owner_iid instead of uid)
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.memory (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    bot_iid             BIGINT REFERENCES ai.identity(id),

    category            VARCHAR(32) NOT NULL DEFAULT 'fact',
    key                 VARCHAR(64) NOT NULL,
    content             TEXT NOT NULL,

    confidence          NUMERIC(3, 2) NOT NULL DEFAULT 1.00,
    source_req_id       VARCHAR(36) NOT NULL DEFAULT '',
    content_hash        VARCHAR(64) NOT NULL DEFAULT '',
    embedding_json      JSONB,

    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    tsv                 tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_memory_owner_key_global
    ON ai.memory (owner_iid, key)
    WHERE bot_iid IS NULL AND deleted_ts IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_memory_owner_bot_key
    ON ai.memory (owner_iid, bot_iid, key)
    WHERE bot_iid IS NOT NULL AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_memory_owner_active
    ON ai.memory (owner_iid, is_active)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_memory_fts
    ON ai.memory USING GIN (tsv);
