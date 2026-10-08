-- Context window max (tokens) for prompt meter + compaction. 0 = infer at read time.
ALTER TABLE ai.llm_model ADD COLUMN IF NOT EXISTS context_tokens INT NOT NULL DEFAULT 0;

UPDATE ai.llm_model SET context_tokens = 1048576 WHERE id = 'alienai' AND context_tokens = 0;
UPDATE ai.llm_model SET context_tokens = 1048576 WHERE provider = 'google' AND deleted_at IS NULL AND context_tokens = 0;
UPDATE ai.llm_model SET context_tokens = 200000 WHERE provider = 'anthropic' AND deleted_at IS NULL AND context_tokens = 0;
UPDATE ai.llm_model SET context_tokens = 128000 WHERE provider IN ('openai', 'deepseek', 'xai', 'moonshot', 'meta', 'mistral', 'qwen', 'cohere') AND deleted_at IS NULL AND context_tokens = 0;
