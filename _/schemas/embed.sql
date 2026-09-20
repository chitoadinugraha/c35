-- ==============================================================================
-- c35 — LLM embed cache (LOCKED 2026-09-20)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: ai
--
-- Durable Gemini embed dedupe cache — partition by model, point get on key.
-- Port: csa embed.sql / id.alienai a_embed_cache (Scylla → YB here).
--
--   model   "{embed_model}@{dimensions}"  e.g. gemini-embedding-2@768
--   key     blake3 hex of (text + task + dimensions)
--   embedding = little-endian float32 array (BYTEA)
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.embed_cache (
    model               TEXT NOT NULL,
    key                 TEXT NOT NULL,                          -- blake3 hex
    text                TEXT,
    embedding           BYTEA,
    task                TEXT,
    token_in            INT,
    ts_ms               BIGINT,                                 -- unix ms when cached

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (model, key)
);

CREATE INDEX IF NOT EXISTS idx_embed_cache_ts
    ON ai.embed_cache (model, ts_ms DESC);
