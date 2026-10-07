-- Live session tools (call.end, future live-only tools) use topic `live`.
UPDATE ai.live_offer
SET tool_topics = ARRAY['general', 'live']::TEXT[], updated_ts = NOW()
WHERE id = 'live.alienai';
