-- ==============================================================================
-- c35 — File CAS (inline blobs for avatars; disk shard optional)
-- Apply after embed.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.file_blob_meta (
    hash_blake3      VARCHAR(64) PRIMARY KEY,
    size_bytes       BIGINT NOT NULL,
    mime_type        TEXT NOT NULL,
    is_inline        BOOLEAN NOT NULL DEFAULT TRUE,
    created_ts       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai.file_blob_inline (
    hash_blake3      VARCHAR(64) PRIMARY KEY REFERENCES ai.file_blob_meta(hash_blake3) ON DELETE CASCADE,
    bytes            BYTEA NOT NULL
);
