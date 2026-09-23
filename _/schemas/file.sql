-- ==============================================================================
-- c35 — File CAS (LOCKED 2026-09-21)
-- inline <512 KiB → ai.file_blob_inline; large → S3 (store=s3, loc JSON)
-- variants JSON on canonical hash: { thumb, small, poster } → blake3 hashes
-- Apply after embed.sql (before channel.sql in migrate order)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.file_blob_meta (
    hash_blake3      VARCHAR(64) PRIMARY KEY,
    size_bytes       BIGINT NOT NULL,
    mime_type        TEXT NOT NULL,
    is_inline        BOOLEAN NOT NULL DEFAULT TRUE,
    store            TEXT NOT NULL DEFAULT 'inline',
    loc              JSONB NOT NULL DEFAULT '{}',
    variants         JSONB NOT NULL DEFAULT '{}',
    created_ts       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_file_blob_store CHECK (store IN ('inline', 's3', 'disk'))
);

CREATE TABLE IF NOT EXISTS ai.file_blob_inline (
    hash_blake3      VARCHAR(64) PRIMARY KEY REFERENCES ai.file_blob_meta(hash_blake3) ON DELETE CASCADE,
    bytes            BYTEA NOT NULL
);

-- Idempotent column adds for existing deployments
ALTER TABLE ai.file_blob_meta ADD COLUMN IF NOT EXISTS store TEXT NOT NULL DEFAULT 'inline';
ALTER TABLE ai.file_blob_meta ADD COLUMN IF NOT EXISTS loc JSONB NOT NULL DEFAULT '{}';
ALTER TABLE ai.file_blob_meta ADD COLUMN IF NOT EXISTS variants JSONB NOT NULL DEFAULT '{}';
