-- ==============================================================================
-- c35 -- Alien AI Drive path index (owner-scoped virtual volume)
-- Bytes in CAS (ai.file_blob_*); this table maps owner path -> blake3 hash
-- Apply after file.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.drive_file (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL,
    path            TEXT NOT NULL,
    hash_blake3     VARCHAR(64) NOT NULL,
    size_bytes      BIGINT NOT NULL,
    mime_type       TEXT NOT NULL DEFAULT 'application/octet-stream',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_drive_file_owner_path
    ON ai.drive_file (owner_iid, path)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_drive_file_owner
    ON ai.drive_file (owner_iid)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_drive_file_sync
    ON ai.drive_file (owner_iid, updated_ts);
