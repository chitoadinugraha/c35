-- ==============================================================================
-- c35 — Chat topics (persona + tool eligibility context)
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.topic (
    id              TEXT PRIMARY KEY,
    label_key       TEXT NOT NULL,
    inst            TEXT NOT NULL DEFAULT '',
    extend          TEXT NOT NULL DEFAULT '',
    sort            INT NOT NULL DEFAULT 0,
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    def_hash        TEXT NOT NULL DEFAULT '',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_topic_enabled_sort
    ON ai.topic (enabled, sort ASC, id ASC);

-- Seed: default chat topic
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'general',
    'topic.general.label',
    'You are a helpful, concise assistant. Answer clearly and ask clarifying questions when needed.',
    '',
    0,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: deep research topic
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'research',
    'topic.research.label',
    'Deep research mode: gather multiple sources with web.search, read key pages with web.visit, and synthesize a thorough answer with citations.',
    'general',
    10,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: image generation topic
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'image',
    'topic.image.label',
    'Image mode: when the user wants visuals, call img.generate with a rich English prompt and suitable aspect ratio.',
    'general',
    20,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;
