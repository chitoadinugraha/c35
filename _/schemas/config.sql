-- App/platform config (releases, feature flags, LLM routing).
CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.config (
    key          VARCHAR(256) PRIMARY KEY,
    value        JSONB NOT NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Alien AI escalation chain: flash-lite family only (same billing tier).
-- Populated automatically from provider catalog sync (empty = auto).
INSERT INTO ai.config (key, value) VALUES (
    'llm.alien_chain',
    '{"models":[]}'::jsonb
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

-- img.generate draft default: "lite" = gemini-3.1-flash-lite-image 1K; "flash" = gemini-3.1-flash-image 1K.
-- Env C35_IMAGE_DEFAULT_TIER overrides this row. HD (2K) is unchanged (@image_high / quality hd).
INSERT INTO ai.config (key, value) VALUES (
    'image.default_tier',
    '{"tier":"lite"}'::jsonb
)
ON CONFLICT (key) DO NOTHING;

-- Manual wallet top-up bank details (shown in app).
INSERT INTO ai.config (key, value) VALUES (
    'billing.manual_transfer',
    '{"bank":"BCA","account":"0113543750","name":"PT Percepatan Akhir Semesta","min_idr":50000,"min_usd":10}'::jsonb
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- Remote agent releases (OTA via GET /version/remote-windows). Bump on deploy.
INSERT INTO ai.config (key, value) VALUES (
    'app.release.c35.remote-windows',
    '{"version":1,"versionName":"0.1.0","min":0,"hash":"","size":0}'::jsonb
)
ON CONFLICT (key) DO NOTHING;

INSERT INTO ai.config (key, value) VALUES (
    'app.release.c35.remote-browser',
    '{"version":1,"versionName":"0.1.0","min":0,"hash":"","size":0}'::jsonb
)
ON CONFLICT (key) DO NOTHING;

INSERT INTO ai.config (key, value) VALUES (
    'app.release.c35.remote-android',
    '{"version":0,"versionName":"0.0.0","min":0,"apkHash":"","apkSize":0}'::jsonb
)
ON CONFLICT (key) DO NOTHING;

-- c35-server cluster image generation (GET /version/server). Bump on publish_server.ps1.
INSERT INTO ai.config (key, value) VALUES (
    'app.release.c35.server',
    '{"version":1,"versionName":"1.0.0","min":0,"url":"https://api.alienai.id/livez"}'::jsonb
)
ON CONFLICT (key) DO NOTHING;

-- FFmpeg sidecar for remote Windows agent (GET /version/ffmpeg-windows, NATS c35.release.ffmpeg-windows).
-- { version, versionName, min, hash, size } — min = minimum remote-windows agent build (0 = any).
INSERT INTO ai.config (key, value) VALUES (
    'app.release.c35.ffmpeg-windows',
    '{"version":0,"versionName":"0.0.0","min":0,"hash":"","size":0}'::jsonb
)
ON CONFLICT (key) DO NOTHING;

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
    ('alienai', 'alienai', 'Alien AI', '', 75000, 300000, true, true, true, 0, 'flash-lite', 0, 'pinned'),
    ('gpt-4o', 'openai', 'GPT-4o', 'openai/gpt-4o', 250000, 1000000, false, true, false, 200, 'gpt-4o', 0, 'seed'),
    ('gpt-4o-mini', 'openai', 'GPT-4o mini', 'openai/gpt-4o-mini', 150000, 600000, false, true, false, 210, 'gpt-4o', 0, 'seed'),
    ('gpt-4.1', 'openai', 'GPT-4.1', 'openai/gpt-4.1', 200000, 800000, false, true, false, 220, 'gpt-4', 41, 'seed'),
    ('gpt-4.1-mini', 'openai', 'GPT-4.1 mini', 'openai/gpt-4.1-mini', 40000, 160000, false, true, false, 230, 'gpt-4', 41, 'seed'),
    ('claude-sonnet-4-5', 'anthropic', 'Claude Sonnet 4.5', 'anthropic/claude-sonnet-4-5', 300000, 1500000, false, true, false, 300, 'claude', 45, 'seed'),
    ('claude-3-5-haiku-latest', 'anthropic', 'Claude 3.5 Haiku', 'anthropic/claude-3-5-haiku-latest', 80000, 400000, false, true, false, 310, 'claude', 35, 'seed'),
    ('deepseek-chat', 'deepseek', 'DeepSeek Chat', 'deepseek/deepseek-chat', 140000, 280000, false, true, false, 400, 'chat', 0, 'seed'),
    ('deepseek-reasoner', 'deepseek', 'DeepSeek Reasoner', 'deepseek/deepseek-reasoner', 550000, 2190000, true, true, false, 410, 'reasoner', 0, 'seed'),
    ('grok-2-latest', 'xai', 'Grok 2', 'x-ai/grok-2-latest', 200000, 1000000, false, true, false, 500, 'grok', 2, 'seed')
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
