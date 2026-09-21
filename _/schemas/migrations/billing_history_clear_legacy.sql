-- Clear pre-currency usage dedupe rows (history used raw USD from ai.log)
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT '';
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS amount_native NUMERIC(20, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS deducted_native NUMERIC(20, 4) NOT NULL DEFAULT 0;

DELETE FROM ai.billing_usage_dedupe WHERE currency = '' OR amount_native = 0;
