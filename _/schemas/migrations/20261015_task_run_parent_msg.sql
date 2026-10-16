-- Parent orchestrator + chat deep links on task_run; skill heal policy
ALTER TABLE ai.task_run ADD COLUMN IF NOT EXISTS parent_run_id BIGINT NOT NULL DEFAULT 0;
ALTER TABLE ai.task_run ADD COLUMN IF NOT EXISTS source_msg_id BIGINT NOT NULL DEFAULT 0;
ALTER TABLE ai.task_run ADD COLUMN IF NOT EXISTS last_msg_id BIGINT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_task_run_parent
    ON ai.task_run (parent_run_id, created_ts DESC)
    WHERE parent_run_id <> 0 AND deleted_ts IS NULL;

ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS heal_mode VARCHAR(16) NOT NULL DEFAULT 'ui';
