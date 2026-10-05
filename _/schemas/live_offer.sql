-- ==============================================================================
-- c35 -- Live Call catalog (Gemini Live, future OpenAI/xAI realtime)
-- Not mixed into ai.llm_model chat picker sync.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.live_offer (
    id                  TEXT PRIMARY KEY,
    family              TEXT NOT NULL,
    label_key           TEXT NOT NULL,
    provider            TEXT NOT NULL,
    provider_model      TEXT NOT NULL,
    inst_id             TEXT NOT NULL DEFAULT '',
    input_usd_per_min   DOUBLE PRECISION NOT NULL DEFAULT 0,
    output_usd_per_min  DOUBLE PRECISION NOT NULL DEFAULT 0,
    enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    sort                INT NOT NULL DEFAULT 0,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_live_offer_list
    ON ai.live_offer (sort, id)
    WHERE deleted_ts IS NULL;

INSERT INTO ai.live_offer (id, family, label_key, provider, provider_model, inst_id, input_usd_per_min, output_usd_per_min, enabled, sort) VALUES
    ('live.alienai', 'alienai', 'live.alienai.label', 'google', 'gemini-3.8-live', 'inst.general', 0.005, 0.018, TRUE, 10),
    ('live.gemini', 'gemini', 'live.gemini.label', 'google', 'gemini-3.8-live', '', 0.005, 0.018, TRUE, 20),
    ('live.gemini.thinker', 'gemini', 'live.gemini.thinker.label', 'google', 'gemini-3.8-live-extended-thinking', '', 0.005, 0.018, TRUE, 21),
    ('live.chatgpt', 'openai', 'live.chatgpt.label', 'openai', 'gpt-4o-realtime-preview', '', 0.006, 0.024, FALSE, 30),
    ('live.grok', 'xai', 'live.grok.label', 'xai', 'grok-voice', '', 0.006, 0.024, FALSE, 40)
ON CONFLICT (id) DO UPDATE SET
    family = EXCLUDED.family,
    label_key = EXCLUDED.label_key,
    provider = EXCLUDED.provider,
    provider_model = EXCLUDED.provider_model,
    inst_id = EXCLUDED.inst_id,
    input_usd_per_min = EXCLUDED.input_usd_per_min,
    output_usd_per_min = EXCLUDED.output_usd_per_min,
    enabled = EXCLUDED.enabled,
    sort = EXCLUDED.sort,
    updated_ts = NOW();