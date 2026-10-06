ALTER TABLE ai.live_offer
    ADD COLUMN IF NOT EXISTS tool_topics TEXT[] NOT NULL DEFAULT '{}';

UPDATE ai.live_offer
SET tool_topics = ARRAY['general']::TEXT[], updated_ts = NOW()
WHERE id = 'live.alienai' AND (tool_topics IS NULL OR tool_topics = '{}');
