-- App/platform config (releases, feature flags, LLM routing).
CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.config (
    key          VARCHAR(256) PRIMARY KEY,
    value        JSONB NOT NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Alien AI escalation chain: flash-lite family only (same billing tier).
-- Edit models[] to add/remove entries (e.g. gemini-3.8-flash-lite when available).
INSERT INTO ai.config (key, value) VALUES (
    'llm.alien_chain',
    '{"models":["gemini-3.1-flash-lite","gemini-3.5-flash-lite","gemini-3.8-flash-lite"]}'::jsonb
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- CF AI Gateway: DB overrides env when fields are set. Secrets usually stay in env.
INSERT INTO ai.config (key, value) VALUES (
    'llm.cf_gateway',
    '{"enabled":true,"gateway_id":"default"}'::jsonb
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- Manual wallet top-up bank details (shown in app).
INSERT INTO ai.config (key, value) VALUES (
    'billing.manual_transfer',
    '{"bank":"BCA","account":"0113543750","name":"PT Percepatan Akhir Semesta","min_idr":50000,"min_usd":10}'::jsonb
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- LLM catalog (platform). Prices in micro-USD per million tokens (µUSD/M).
CREATE TABLE IF NOT EXISTS ai.llm_model (
    id                  TEXT PRIMARY KEY,
    provider            VARCHAR(32) NOT NULL,
    label               VARCHAR(128) NOT NULL,
    provider_model      TEXT NOT NULL,
    input_micro_per_m   BIGINT NOT NULL DEFAULT 150000,
    output_micro_per_m  BIGINT NOT NULL DEFAULT 600000,
    supports_thinking   BOOL NOT NULL DEFAULT false,
    enabled             BOOL NOT NULL DEFAULT true,
    is_default          BOOL NOT NULL DEFAULT false,
    sort_order          INT NOT NULL DEFAULT 500,
    family              VARCHAR(32) NOT NULL DEFAULT '',
    version_rank        INT NOT NULL DEFAULT 0,
    source              VARCHAR(16) NOT NULL DEFAULT 'seed',
    synced_at           TIMESTAMPTZ,
    deleted_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ai_llm_model_list ON ai.llm_model (sort_order) WHERE deleted_at IS NULL AND enabled = true;

INSERT INTO ai.llm_model (id, provider, label, provider_model, input_micro_per_m, output_micro_per_m, supports_thinking, enabled, is_default, sort_order, family, version_rank, source) VALUES
    ('alienai', 'alienai', 'Alien AI', 'gemini-3.1-flash-lite', 75000, 300000, true, true, true, 0, 'flash-lite', 310, 'pinned'),
    ('gemini-3.1-flash-lite', 'google', 'Gemini 3.1 Flash Lite', 'gemini-3.1-flash-lite', 75000, 300000, true, true, false, 100, 'flash-lite', 310, 'seed'),
    ('gpt-4o', 'openai', 'GPT-4o', 'gpt-4o', 250000, 1000000, false, true, false, 200, 'gpt-4o', 0, 'seed'),
    ('claude-sonnet-4-5', 'anthropic', 'Claude Sonnet 4.5', 'anthropic/claude-sonnet-4-5', 300000, 1500000, false, true, false, 300, 'claude', 45, 'seed')
ON CONFLICT (id) DO UPDATE SET
    label = EXCLUDED.label,
    provider = EXCLUDED.provider,
    provider_model = EXCLUDED.provider_model,
    input_micro_per_m = EXCLUDED.input_micro_per_m,
    output_micro_per_m = EXCLUDED.output_micro_per_m,
    supports_thinking = EXCLUDED.supports_thinking,
    enabled = EXCLUDED.enabled,
    is_default = EXCLUDED.is_default,
    sort_order = EXCLUDED.sort_order,
    family = EXCLUDED.family,
    version_rank = EXCLUDED.version_rank,
    source = EXCLUDED.source,
    updated_at = NOW();
