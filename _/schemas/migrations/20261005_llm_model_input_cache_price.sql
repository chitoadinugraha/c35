-- LLM catalog: prompt-cache read wholesale (micro-USD per 1M tokens). 0 = unknown / N/A.
ALTER TABLE ai.llm_model
    ADD COLUMN IF NOT EXISTS input_cache_micro_per_m BIGINT NOT NULL DEFAULT 0;
