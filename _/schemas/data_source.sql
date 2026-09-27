-- ==============================================================================
-- c35 — Bot data sources (synced external knowledge)
-- Status: LOCKED 2026-09-27 — see _/docs/data_source.md
-- Apply after identity.sql, embed.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.data_source (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    bot_iid         BIGINT REFERENCES ai.identity(id),
    source_kind     VARCHAR(32) NOT NULL,
    name            VARCHAR(128) NOT NULL,
    config          JSONB NOT NULL DEFAULT '{}',

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    CONSTRAINT chk_data_source_kind CHECK (source_kind <> ''),
    CONSTRAINT chk_data_source_name CHECK (name <> '')
);

CREATE INDEX IF NOT EXISTS idx_data_source_owner
    ON ai.data_source (owner_iid, updated_ts DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_data_source_bot
    ON ai.data_source (bot_iid, updated_ts DESC)
    WHERE deleted_ts IS NULL AND bot_iid IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_data_source_kind
    ON ai.data_source (source_kind)
    WHERE deleted_ts IS NULL;

-- --------------------------------------------------------------------------
-- Sync metadata (1:1 with data_source)
-- --------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.data_source_sync (
    data_source_id      BIGINT PRIMARY KEY REFERENCES ai.data_source(id) ON DELETE CASCADE,
    source_kind         VARCHAR(32) NOT NULL,
    snapshot_hash       VARCHAR(64) NOT NULL DEFAULT '',
    row_count           INT NOT NULL DEFAULT 0,
    status              VARCHAR(16) NOT NULL DEFAULT 'ok',
    error_msg           TEXT,
    synced_ts           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_data_source_sync_kind
    ON ai.data_source_sync (source_kind);

CREATE INDEX IF NOT EXISTS idx_data_source_sync_status
    ON ai.data_source_sync (status)
    WHERE status <> 'ok';

CREATE INDEX IF NOT EXISTS idx_data_source_sync_due
    ON ai.data_source_sync (synced_ts ASC)
    WHERE status IN ('ok', 'error', 'stale');

-- --------------------------------------------------------------------------
-- Searchable chunks (replaced wholesale on snapshot change)
-- --------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.data_source_chunk (
    id                  BIGINT PRIMARY KEY,
    data_source_id      BIGINT NOT NULL REFERENCES ai.data_source(id) ON DELETE CASCADE,
    chunk_key           VARCHAR(128) NOT NULL,
    source_kind         VARCHAR(32) NOT NULL,
    content             TEXT NOT NULL,
    content_hash        VARCHAR(64) NOT NULL,
    meta                JSONB NOT NULL DEFAULT '{}',
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tsv                 tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,

    CONSTRAINT uq_data_source_chunk_key UNIQUE (data_source_id, chunk_key)
);

CREATE INDEX IF NOT EXISTS idx_data_source_chunk_source
    ON ai.data_source_chunk (data_source_id);

CREATE INDEX IF NOT EXISTS idx_data_source_chunk_fts
    ON ai.data_source_chunk USING GIN (tsv);
