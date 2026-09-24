-- ==============================================================================
-- c35 — LLM embed cache (LOCKED 2026-09-20)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: ai
--
-- Durable Gemini embed dedupe cache — partition by model, point get on key.
-- Port: csa embed.sql / id.alienai a_embed_cache (Scylla → YB here).
--
--   model   "{embed_model}@{dimensions}"  e.g. gemini-embedding-2@768
--   key     blake3 hex of (text + NUL + task + NUL + dimensions)
--   embedding = little-endian float32 array (BYTEA)
--
-- Retention: sliding access window (NOT fixed TTL). Rows persist while accessed
-- within EMBED_CACHE_RETENTION_DAYS (30). embed_cache_evict_stale() deletes
-- rows where accessed_ts_ms is older than the cutoff.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.embed_cache (
    model               TEXT NOT NULL,
    key                 TEXT NOT NULL,                          -- blake3 hex
    text                TEXT,
    embedding           BYTEA,
    task                TEXT,
    token_in            INT,
    ts_ms               BIGINT,                                 -- unix ms last written
    accessed_ts_ms      BIGINT,                                 -- unix ms last read or write

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (model, key)
);

ALTER TABLE ai.embed_cache ADD COLUMN IF NOT EXISTS accessed_ts_ms BIGINT;

UPDATE ai.embed_cache
SET accessed_ts_ms = COALESCE(accessed_ts_ms, ts_ms, (EXTRACT(EPOCH FROM created_ts) * 1000)::BIGINT)
WHERE accessed_ts_ms IS NULL;

CREATE INDEX IF NOT EXISTS idx_embed_cache_accessed
    ON ai.embed_cache (model, accessed_ts_ms DESC);

CREATE INDEX IF NOT EXISTS idx_embed_cache_ts
    ON ai.embed_cache (model, ts_ms DESC);
