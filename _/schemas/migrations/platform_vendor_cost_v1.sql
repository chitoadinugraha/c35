-- ==============================================================================
-- c35 — Platform vendor cost v1
-- Run after billing.sql on existing DBs.
-- See _/docs/plans/2026-09-24-platform-vendor-billing-multitask.md Track A
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- platform_vendor_cost
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.platform_vendor_cost (
    id                  BIGINT PRIMARY KEY,
    vendor              VARCHAR(32) NOT NULL,
    category            VARCHAR(32) NOT NULL,
    sku                 VARCHAR(128) NOT NULL DEFAULT '',
    description         TEXT NOT NULL DEFAULT '',

    period_start        DATE NOT NULL,
    period_end          DATE NOT NULL,

    amount_native       NUMERIC(20, 6) NOT NULL,
    currency            VARCHAR(3) NOT NULL DEFAULT 'USD',
    amount_usd          NUMERIC(12, 6) NOT NULL,

    source              VARCHAR(32) NOT NULL DEFAULT 'api',
    external_ref        VARCHAR(256) NOT NULL DEFAULT '',
    status              VARCHAR(16) NOT NULL DEFAULT 'estimated',

    fetched_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    meta                JSONB NOT NULL DEFAULT '{}',
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_platform_vendor CHECK (vendor IN ('oci','gcp','cf','wasabi')),
    CONSTRAINT chk_platform_vendor_cat CHECK (
        category IN ('compute','storage','network','dns','ai_api','other')
    ),
    CONSTRAINT chk_platform_vendor_status CHECK (status IN ('estimated','finalized')),
    CONSTRAINT chk_platform_vendor_source CHECK (source IN ('api','csv','manual'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_platform_vendor_cost_ref
    ON ai.platform_vendor_cost (vendor, external_ref)
    WHERE external_ref <> '' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_platform_vendor_cost_period
    ON ai.platform_vendor_cost (period_start, period_end, vendor)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- billing_usage_dedupe: AI wholesale COGS per turn
-- ------------------------------------------------------------------------------

ALTER TABLE ai.billing_usage_dedupe
    ADD COLUMN IF NOT EXISTS cost_wholesale_usd NUMERIC(12, 6) NOT NULL DEFAULT 0;
