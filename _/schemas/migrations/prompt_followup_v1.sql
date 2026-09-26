-- Live cluster: prompt follow-up queue + steer (Option B)
\i ../prompt_followup.sql

ALTER TABLE ai.prompt_run ADD COLUMN IF NOT EXISTS steer_delivered_count INT NOT NULL DEFAULT 0;

ALTER TABLE ai.prompt_run DROP CONSTRAINT IF EXISTS chk_prompt_run_kind;
ALTER TABLE ai.prompt_run ADD CONSTRAINT chk_prompt_run_kind CHECK (
    kind IN ('main','research','computer_use','site_build','channel')
);

UPDATE ai.billing_plan SET caps_json = caps_json || '{"prompt_followup_queue_max":0,"prompt_followup_steer_max":3}'::jsonb
WHERE slug = 'lite';

UPDATE ai.billing_plan SET caps_json = caps_json || '{"prompt_followup_queue_max":5,"prompt_followup_steer_max":20}'::jsonb
WHERE slug IN ('plus', 'pro', 'ultra');
