-- ==============================================================================
-- c35 — Billing pools v3 (IDR pools + promotions)
-- Run after billing.sql on existing DBs.
-- See _/docs/billing-implementation.md Phase 4b, _/docs/billing-plans.md
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- billing_promotion
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_promotion (
    id                      BIGINT PRIMARY KEY,
    code                    VARCHAR(64) NOT NULL DEFAULT '',
    type                    VARCHAR(32) NOT NULL,
    audience                VARCHAR(16) NOT NULL DEFAULT 'multi',
    name                    VARCHAR(128) NOT NULL DEFAULT '',
    base_plan_slug          VARCHAR(32) REFERENCES ai.billing_plan(slug),
    pool_multiplier         NUMERIC(8, 4) NOT NULL DEFAULT 1,
    alien_pool_idr          NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_idr       NUMERIC(16, 2) NOT NULL DEFAULT 0,
    duration_days           INT NOT NULL DEFAULT 0,
    duration_minutes        INT NOT NULL DEFAULT 0,
    max_claims_total        INT NOT NULL DEFAULT 0,
    max_claims_per_email    INT NOT NULL DEFAULT 1,
    valid_from              TIMESTAMPTZ,
    valid_to                TIMESTAMPTZ,
    scope                   VARCHAR(16) NOT NULL DEFAULT 'user',
    meta                    JSONB NOT NULL DEFAULT '{}',
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_iid          BIGINT NOT NULL REFERENCES ai.identity(id),
    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_billing_promotion_type CHECK (
        type IN ('signup_trial', 'demo_trial', 'discount', 'custom_package')
    ),
    CONSTRAINT chk_billing_promotion_audience CHECK (
        audience IN ('single', 'multi')
    ),
    CONSTRAINT chk_billing_promotion_scope CHECK (
        scope IN ('user', 'bot', 'device')
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_promotion_code
    ON ai.billing_promotion (code)
    WHERE code <> '';

CREATE INDEX IF NOT EXISTS idx_billing_promotion_type_active
    ON ai.billing_promotion (type, is_active);

-- ------------------------------------------------------------------------------
-- billing_promotion_claim
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_promotion_claim (
    id                      BIGINT PRIMARY KEY,
    promotion_id            BIGINT NOT NULL REFERENCES ai.billing_promotion(id),
    owner_iid               BIGINT NOT NULL REFERENCES ai.identity(id),
    email                   VARCHAR(255) NOT NULL DEFAULT '',
    expires_ts              TIMESTAMPTZ,
    alien_pool_used_idr     NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_used_idr  NUMERIC(16, 2) NOT NULL DEFAULT 0,
    meta                    JSONB NOT NULL DEFAULT '{}',
    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_billing_promotion_claim_promo_email UNIQUE (promotion_id, email)
);

CREATE INDEX IF NOT EXISTS idx_billing_promotion_claim_owner
    ON ai.billing_promotion_claim (owner_iid, created_ts DESC);

CREATE INDEX IF NOT EXISTS idx_billing_promotion_claim_promotion
    ON ai.billing_promotion_claim (promotion_id, created_ts DESC);

-- ------------------------------------------------------------------------------
-- billing_plan — pool template columns
-- ------------------------------------------------------------------------------

ALTER TABLE ai.billing_plan
    ADD COLUMN IF NOT EXISTS alien_pool_idr_monthly NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_plan
    ADD COLUMN IF NOT EXISTS frontier_pool_idr_monthly NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_plan
    ADD COLUMN IF NOT EXISTS pool_multiplier NUMERIC(8, 4) NOT NULL DEFAULT 1;
ALTER TABLE ai.billing_plan
    ADD COLUMN IF NOT EXISTS tier VARCHAR(16) NOT NULL DEFAULT '';

-- ------------------------------------------------------------------------------
-- billing_profile — IDR pools
-- ------------------------------------------------------------------------------

ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS alien_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS alien_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS frontier_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS frontier_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS pool_period_start TIMESTAMPTZ;
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS trial_expires_ts TIMESTAMPTZ;
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS active_promotion_id BIGINT REFERENCES ai.billing_promotion(id);

-- ------------------------------------------------------------------------------
-- billing_subscription — IDR pools
-- ------------------------------------------------------------------------------

ALTER TABLE ai.billing_subscription
    ADD COLUMN IF NOT EXISTS alien_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription
    ADD COLUMN IF NOT EXISTS alien_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription
    ADD COLUMN IF NOT EXISTS frontier_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription
    ADD COLUMN IF NOT EXISTS frontier_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription
    ADD COLUMN IF NOT EXISTS pool_period_start TIMESTAMPTZ;

-- ------------------------------------------------------------------------------
-- billing_reservation — pool deduct audit
-- ------------------------------------------------------------------------------

ALTER TABLE ai.billing_reservation
    ADD COLUMN IF NOT EXISTS promotion_id BIGINT REFERENCES ai.billing_promotion(id);
ALTER TABLE ai.billing_reservation
    ADD COLUMN IF NOT EXISTS pool VARCHAR(16);
ALTER TABLE ai.billing_reservation
    ADD COLUMN IF NOT EXISTS pool_deduct_idr NUMERIC(16, 4);

-- ------------------------------------------------------------------------------
-- billing_plan_price — PK must include billing_period (yearly + monthly per plan)
-- ------------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'billing_plan_price_pkey'
          AND conrelid = 'ai.billing_plan_price'::regclass
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
        WHERE c.conname = 'billing_plan_price_pkey'
          AND c.conrelid = 'ai.billing_plan_price'::regclass
          AND a.attname = 'billing_period'
    ) THEN
        ALTER TABLE ai.billing_plan_price DROP CONSTRAINT billing_plan_price_pkey;
        ALTER TABLE ai.billing_plan_price
            ADD PRIMARY KEY (plan_slug, currency, billing_period);
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- Backfill profile pools from legacy USD allowance (best effort)
-- ------------------------------------------------------------------------------

UPDATE ai.billing_profile p SET
    alien_pool_limit_idr = ROUND(
        COALESCE(p.alien_allow_weekly_limit, 0) * 0.83
        * COALESCE((
            SELECT micro_per_usd::numeric / 1000000
            FROM ai.billing_fx_rate
            WHERE currency = 'IDR'
            ORDER BY effective_from DESC
            LIMIT 1
        ), 17630),
        2
    ),
    frontier_pool_limit_idr = ROUND(
        COALESCE(p.alien_allow_weekly_limit, 0) * 0.17
        * COALESCE((
            SELECT micro_per_usd::numeric / 1000000
            FROM ai.billing_fx_rate
            WHERE currency = 'IDR'
            ORDER BY effective_from DESC
            LIMIT 1
        ), 17630),
        2
    ),
    pool_period_start = COALESCE(p.pool_period_start, p.window_weekly_start, NOW())
WHERE p.alien_pool_limit_idr = 0
  AND COALESCE(p.alien_allow_weekly_limit, 0) > 0;

-- ------------------------------------------------------------------------------
-- Reseed billing_plan (Lite–Ultra + bot/device SKUs)
-- ------------------------------------------------------------------------------

INSERT INTO ai.billing_plan (
    slug, name, scope, sort_order, price_usd, duration_months,
    alien_allow_5h_usd, alien_allow_weekly_usd,
    msgs_limit, channels_limit, concurrent_limit,
    caps_json, overage_enabled, is_active,
    alien_pool_idr_monthly, frontier_pool_idr_monthly, pool_multiplier, tier
) VALUES
    ('lite', 'Lite', 'user', 10, 3.50, 1, 0.05, 1.00, 0, 2, 0,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     FALSE, TRUE, 100000, 20000, 1, 'lite'),
    ('plus', 'Plus', 'user', 20, 7.00, 1, 0.25, 5.00, 0, 2, 0,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     TRUE, TRUE, 400000, 80000, 4, 'plus'),
    ('pro', 'Pro', 'user', 30, 20.00, 1, 1.00, 20.00, 0, 3, 0,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     TRUE, TRUE, 1000000, 200000, 10, 'pro'),
    ('ultra', 'Ultra', 'user', 40, 65.00, 1, 4.00, 80.00, 0, 5, 0,
     '{"outbound_gap_ms":8000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":true}',
     TRUE, TRUE, 4000000, 800000, 40, 'ultra'),
    ('bot.lite', 'Bot Lite', 'bot', 50, 2.50, 1, 0, 0, 0, 1, 3,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     TRUE, TRUE, 0, 0, 0, 'bot.lite'),
    ('bot.small', 'Bot Small', 'bot', 60, 5.50, 1, 0, 0, 0, 3, 8,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     TRUE, TRUE, 0, 0, 0, 'bot.small'),
    ('device.light', 'Device Light', 'device', 70, 30.00, 1, 0.40, 8.00, 0, 0, 1,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     TRUE, TRUE, 1000000, 200000, 10, 'device.light'),
    ('device.medium', 'Device Medium', 'device', 80, 60.00, 1, 1.00, 20.00, 0, 0, 3,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false}',
     TRUE, TRUE, 2000000, 400000, 20, 'device.medium')
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    scope = EXCLUDED.scope,
    sort_order = EXCLUDED.sort_order,
    price_usd = EXCLUDED.price_usd,
    duration_months = EXCLUDED.duration_months,
    alien_allow_5h_usd = EXCLUDED.alien_allow_5h_usd,
    alien_allow_weekly_usd = EXCLUDED.alien_allow_weekly_usd,
    msgs_limit = EXCLUDED.msgs_limit,
    channels_limit = EXCLUDED.channels_limit,
    concurrent_limit = EXCLUDED.concurrent_limit,
    caps_json = EXCLUDED.caps_json,
    overage_enabled = EXCLUDED.overage_enabled,
    is_active = EXCLUDED.is_active,
    alien_pool_idr_monthly = EXCLUDED.alien_pool_idr_monthly,
    frontier_pool_idr_monthly = EXCLUDED.frontier_pool_idr_monthly,
    pool_multiplier = EXCLUDED.pool_multiplier,
    tier = EXCLUDED.tier,
    updated_ts = NOW();

UPDATE ai.billing_plan
SET is_active = FALSE, updated_ts = NOW()
WHERE slug IN ('free', 'bot.medium', 'bot.large', 'device.office_light', 'device.office_pro');

-- ------------------------------------------------------------------------------
-- Reseed billing_plan_price (IDR yearly + monthly)
-- ------------------------------------------------------------------------------

INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
    ('lite', 'IDR', 49000, 'yearly'),
    ('lite', 'IDR', 59000, 'monthly'),
    ('plus', 'IDR', 99000, 'yearly'),
    ('plus', 'IDR', 109000, 'monthly'),
    ('pro', 'IDR', 309000, 'yearly'),
    ('pro', 'IDR', 349000, 'monthly'),
    ('ultra', 'IDR', 1000000, 'yearly'),
    ('ultra', 'IDR', 1200000, 'monthly'),
    ('bot.lite', 'IDR', 39000, 'yearly'),
    ('bot.lite', 'IDR', 49000, 'monthly'),
    ('bot.small', 'IDR', 89000, 'yearly'),
    ('bot.small', 'IDR', 99000, 'monthly'),
    ('device.light', 'IDR', 499000, 'yearly'),
    ('device.light', 'IDR', 599000, 'monthly'),
    ('device.medium', 'IDR', 999000, 'yearly'),
    ('device.medium', 'IDR', 1109000, 'monthly')
ON CONFLICT (plan_slug, currency, billing_period) DO UPDATE SET
    amount = EXCLUDED.amount,
    is_active = EXCLUDED.is_active,
    updated_ts = NOW();

UPDATE ai.billing_plan_price
SET is_active = FALSE, updated_ts = NOW()
WHERE plan_slug IN ('free', 'bot.medium', 'bot.large', 'device.office_light', 'device.office_pro');

-- ------------------------------------------------------------------------------
-- Seed signup trial promotion
-- ------------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'billing_profile_active_promotion_id_fkey'
    ) THEN
        ALTER TABLE ai.billing_profile
            ADD CONSTRAINT billing_profile_active_promotion_id_fkey
            FOREIGN KEY (active_promotion_id) REFERENCES ai.billing_promotion(id);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'billing_reservation_promotion_id_fkey'
    ) THEN
        ALTER TABLE ai.billing_reservation
            ADD CONSTRAINT billing_reservation_promotion_id_fkey
            FOREIGN KEY (promotion_id) REFERENCES ai.billing_promotion(id);
    END IF;
END $$;

INSERT INTO ai.billing_promotion (
    id, code, type, audience, name, base_plan_slug,
    pool_multiplier, alien_pool_idr, frontier_pool_idr,
    duration_days, max_claims_per_email, scope, is_active, created_by_iid
)
SELECT
    900000000000000001,
    'SIGNUPTRIAL',
    'signup_trial',
    'multi',
    'Signup Trial',
    'lite',
    0.25,
    25000,
    5000,
    7,
    1,
    'user',
    TRUE,
    i.id
FROM ai.identity i
ORDER BY i.id
LIMIT 1
ON CONFLICT (id) DO UPDATE SET
    code = EXCLUDED.code,
    type = EXCLUDED.type,
    audience = EXCLUDED.audience,
    name = EXCLUDED.name,
    base_plan_slug = EXCLUDED.base_plan_slug,
    pool_multiplier = EXCLUDED.pool_multiplier,
    alien_pool_idr = EXCLUDED.alien_pool_idr,
    frontier_pool_idr = EXCLUDED.frontier_pool_idr,
    duration_days = EXCLUDED.duration_days,
    max_claims_per_email = EXCLUDED.max_claims_per_email,
    scope = EXCLUDED.scope,
    is_active = EXCLUDED.is_active,
    updated_ts = NOW();
