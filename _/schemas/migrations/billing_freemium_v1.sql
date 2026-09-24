-- Freemium daily caps (no paid plan / expired trial): 30 msgs OR 30k tokens per UTC day.

ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS freemium_day DATE;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS plan_expires_ts TIMESTAMPTZ;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS freemium_msgs_used INT NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS freemium_tokens_used INT NOT NULL DEFAULT 0;
