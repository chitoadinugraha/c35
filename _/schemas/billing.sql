-- ==============================================================================
-- c35 — Billing schema (LOCKED 2026-09-21)
-- Apply after identity.sql
-- Multi-wallet balances + profile quota + catalog prices
-- Audit + cost rows: log.sql (single log table)
-- See _/docs/billing.md and _/docs/billing-implementation.md
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- LEGACY: billing_account (dual USD/IDR — migrate to billing_profile + billing_wallet)
-- Kept for backward compat until Phase 3 server refactor completes.
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_account (
    id                          BIGINT PRIMARY KEY,
    owner_iid                   BIGINT NOT NULL REFERENCES ai.identity(id),

    name                        VARCHAR(64) NOT NULL DEFAULT 'Personal',
    balance_usd                 NUMERIC(12, 4) NOT NULL DEFAULT 0,
    balance_idr                 NUMERIC(16, 2) NOT NULL DEFAULT 0,
    plan_tier                   VARCHAR(32) NOT NULL DEFAULT 'free',

    alien_allow_5h_used         NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_5h_limit        NUMERIC(12, 6) NOT NULL DEFAULT 0.05,
    alien_allow_weekly_used     NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_weekly_limit      NUMERIC(12, 6) NOT NULL DEFAULT 1.00,
    window_5h_start             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    window_weekly_start         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    billing_currency            VARCHAR(3) NOT NULL DEFAULT 'IDR',
    fx_micro_per_usd            BIGINT NOT NULL DEFAULT 17630000000,

    commission_available_usd    NUMERIC(12, 4) NOT NULL DEFAULT 0,
    commission_earned_usd       NUMERIC(12, 4) NOT NULL DEFAULT 0,
    commission_available_idr    NUMERIC(14, 2) NOT NULL DEFAULT 0,
    commission_earned_idr       NUMERIC(14, 2) NOT NULL DEFAULT 0,
    commission_pending_usd      NUMERIC(12, 4) NOT NULL DEFAULT 0,
    commission_pending_idr      NUMERIC(14, 2) NOT NULL DEFAULT 0,

    meta                        JSONB NOT NULL DEFAULT '{}',
    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts                  TIMESTAMPTZ,

    CONSTRAINT chk_billing_balance_usd_nonneg CHECK (balance_usd >= 0),
    CONSTRAINT chk_billing_balance_idr_nonneg CHECK (balance_idr >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_owner
    ON ai.billing_account (owner_iid)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_sync
    ON ai.billing_account (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Top-up requests (manual approve Phase 1; provider webhooks later)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_topup_request (
    id                      BIGINT PRIMARY KEY,
    owner_iid               BIGINT NOT NULL REFERENCES ai.identity(id),
    billing_account_id      BIGINT NOT NULL REFERENCES ai.billing_account(id),

    amount_usd              NUMERIC(12, 4) NOT NULL DEFAULT 0,
    amount_idr              NUMERIC(16, 2) NOT NULL DEFAULT 0,
    provider                VARCHAR(32) NOT NULL DEFAULT 'manual',
    payment_type            VARCHAR(32) NOT NULL DEFAULT '',
    external_order_id       VARCHAR(128) NOT NULL DEFAULT '',
    proof_url               TEXT NOT NULL DEFAULT '',

    status                  VARCHAR(16) NOT NULL DEFAULT 'pending',
    reject_reason           TEXT NOT NULL DEFAULT '',
    reviewed_by_iid         BIGINT REFERENCES ai.identity(id),

    meta                    JSONB NOT NULL DEFAULT '{}',
    settled_ts              TIMESTAMPTZ,
    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts              TIMESTAMPTZ,

    CONSTRAINT chk_billing_topup_status CHECK (
        status IN (
            'pending', 'pending_review', 'approved', 'rejected', 'cancelled',
            'settled', 'failed', 'expired'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_billing_topup_owner
    ON ai.billing_topup_request (owner_iid, created_ts DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_topup_status
    ON ai.billing_topup_request (status, created_ts DESC)
    WHERE deleted_ts IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_topup_external_order
    ON ai.billing_topup_request (external_order_id)
    WHERE external_order_id <> '' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_topup_manual_pending
    ON ai.billing_topup_request (provider, status, created_ts DESC)
    WHERE provider = 'manual' AND deleted_ts IS NULL;

ALTER TABLE ai.billing_account
    ADD COLUMN IF NOT EXISTS commission_pending_usd NUMERIC(12, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_account
    ADD COLUMN IF NOT EXISTS commission_pending_idr NUMERIC(14, 2) NOT NULL DEFAULT 0;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_billing_topup_status'
          AND conrelid = 'ai.billing_topup_request'::regclass
    ) THEN
        ALTER TABLE ai.billing_topup_request DROP CONSTRAINT chk_billing_topup_status;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_billing_topup_status'
          AND conrelid = 'ai.billing_topup_request'::regclass
    ) THEN
        ALTER TABLE ai.billing_topup_request ADD CONSTRAINT chk_billing_topup_status CHECK (
            status IN (
                'pending', 'pending_review', 'approved', 'rejected', 'cancelled',
                'settled', 'failed', 'expired'
            )
        );
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- Receive accounts (manual bank transfer destinations)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_receive_account (
    id                  BIGINT PRIMARY KEY,
    bank_id             VARCHAR(32) NOT NULL DEFAULT '',
    account_number      VARCHAR(64) NOT NULL DEFAULT '',
    account_name        VARCHAR(128) NOT NULL DEFAULT '',
    currency            VARCHAR(3) NOT NULL DEFAULT 'IDR',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_default          BOOLEAN NOT NULL DEFAULT FALSE,
    label               VARCHAR(128) NOT NULL DEFAULT '',
    created_by_iid      BIGINT REFERENCES ai.identity(id),
    meta                JSONB NOT NULL DEFAULT '{}',
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_billing_receive_account_currency CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_receive_account_default_currency
    ON ai.billing_receive_account (currency)
    WHERE is_default = TRUE AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_receive_account_active
    ON ai.billing_receive_account (currency, is_active, updated_ts DESC)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Commission withdraw review queue
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.commission_withdraw_request (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    amount_usd          NUMERIC(12, 4) NOT NULL DEFAULT 0,
    amount_idr          NUMERIC(14, 2) NOT NULL DEFAULT 0,
    currency            VARCHAR(8) NOT NULL DEFAULT 'IDR',
    payout_method       VARCHAR(32) NOT NULL DEFAULT 'bank_transfer',
    bank_id             VARCHAR(32) NOT NULL DEFAULT '',
    account_number      VARCHAR(64) NOT NULL DEFAULT '',
    account_name        VARCHAR(128) NOT NULL DEFAULT '',
    note                TEXT NOT NULL DEFAULT '',
    transfer_proof_url  TEXT NOT NULL DEFAULT '',
    status              VARCHAR(16) NOT NULL DEFAULT 'pending',
    decline_reason      TEXT NOT NULL DEFAULT '',
    reviewed_by_iid     BIGINT REFERENCES ai.identity(id),
    reviewed_ts         TIMESTAMPTZ,
    meta                JSONB NOT NULL DEFAULT '{}',
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_commission_withdraw_status CHECK (
        status IN ('pending', 'approved', 'declined', 'cancelled')
    ),
    CONSTRAINT chk_commission_withdraw_payout_method CHECK (
        payout_method IN ('wallet_credit', 'bank_transfer')
    )
);

CREATE INDEX IF NOT EXISTS idx_commission_withdraw_status
    ON ai.commission_withdraw_request (status, created_ts DESC)
    WHERE deleted_ts IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_commission_withdraw_one_pending
    ON ai.commission_withdraw_request (owner_iid)
    WHERE status = 'pending' AND deleted_ts IS NULL;

INSERT INTO ai.billing_receive_account (
    id, bank_id, account_number, account_name, currency,
    is_active, is_default, label, created_by_iid
)
SELECT
    900000000000000002,
    'BCA',
    '0113543750',
    'PT Percepatan Akhir Semesta',
    'IDR',
    TRUE,
    TRUE,
    'BCA IDR default',
    i.id
FROM ai.identity i
ORDER BY i.id
LIMIT 1
ON CONFLICT (id) DO UPDATE SET
    bank_id = EXCLUDED.bank_id,
    account_number = EXCLUDED.account_number,
    account_name = EXCLUDED.account_name,
    currency = EXCLUDED.currency,
    is_active = EXCLUDED.is_active,
    is_default = EXCLUDED.is_default,
    label = EXCLUDED.label,
    updated_ts = NOW();

-- ------------------------------------------------------------------------------
-- In-flight escrow during LLM turn (req_id)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_reservation (
    id                      BIGINT PRIMARY KEY,
    req_id                  VARCHAR(64) NOT NULL,
    owner_iid               BIGINT NOT NULL REFERENCES ai.identity(id),
    billing_account_id      BIGINT NOT NULL REFERENCES ai.billing_account(id) ON DELETE CASCADE,

    held_usd                NUMERIC(12, 6) NOT NULL DEFAULT 0,
    held_idr                NUMERIC(14, 2) NOT NULL DEFAULT 0,
    status                  VARCHAR(16) NOT NULL DEFAULT 'held',

    promotion_id            BIGINT,
    pool                    VARCHAR(16),
    pool_deduct_idr         NUMERIC(16, 4),

    meta                    JSONB NOT NULL DEFAULT '{}',
    settled_ts              TIMESTAMPTZ,
    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_billing_reservation_req UNIQUE (req_id),
    CONSTRAINT chk_billing_reservation_status CHECK (
        status IN ('held', 'settled', 'refunded')
    )
);

ALTER TABLE ai.billing_reservation ADD COLUMN IF NOT EXISTS promotion_id BIGINT;
ALTER TABLE ai.billing_reservation ADD COLUMN IF NOT EXISTS pool VARCHAR(16);
ALTER TABLE ai.billing_reservation ADD COLUMN IF NOT EXISTS pool_deduct_idr NUMERIC(16, 4);

CREATE INDEX IF NOT EXISTS idx_billing_reservation_account
    ON ai.billing_reservation (billing_account_id, status);

CREATE INDEX IF NOT EXISTS idx_billing_reservation_owner
    ON ai.billing_reservation (owner_iid, created_ts DESC);

-- ------------------------------------------------------------------------------
-- Idempotent usage deduct (one charge per req_id per owner)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_usage_dedupe (
    owner_iid               BIGINT NOT NULL REFERENCES ai.identity(id),
    req_id                  VARCHAR(64) NOT NULL,
    cost_usd                NUMERIC(12, 6) NOT NULL DEFAULT 0,
    billing_account_id      BIGINT NOT NULL REFERENCES ai.billing_account(id),
    log_id                  BIGINT,
    currency                VARCHAR(3) NOT NULL DEFAULT '',
    amount_native           NUMERIC(20, 4) NOT NULL DEFAULT 0,
    deducted_native         NUMERIC(20, 4) NOT NULL DEFAULT 0,
    cost_wholesale_usd      NUMERIC(12, 6) NOT NULL DEFAULT 0,

    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (owner_iid, req_id)
);

ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT '';
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS amount_native NUMERIC(20, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS deducted_native NUMERIC(20, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS cost_wholesale_usd NUMERIC(12, 6) NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_billing_usage_dedupe_account
    ON ai.billing_usage_dedupe (billing_account_id, created_ts DESC);

-- ------------------------------------------------------------------------------
-- Referral commission ledger (stats + payout; accrual rows)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.commission_ledger (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    entry_type      VARCHAR(32) NOT NULL DEFAULT 'accrual',
    status          VARCHAR(32) NOT NULL DEFAULT 'active',
    amount_usd      NUMERIC(12, 4) NOT NULL DEFAULT 0,
    amount_idr      NUMERIC(14, 2) NOT NULL DEFAULT 0,
    meta            JSONB NOT NULL DEFAULT '{}',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_commission_ledger_owner_ts
    ON ai.commission_ledger (owner_iid, created_ts DESC);

-- ------------------------------------------------------------------------------
-- Admin balance / commission adjustments (root / director; reason audit trail)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_admin_adjustment (
    id                      BIGINT PRIMARY KEY,
    owner_iid               BIGINT NOT NULL REFERENCES ai.identity(id),
    billing_account_id      BIGINT NOT NULL REFERENCES ai.billing_account(id),
    kind                    VARCHAR(16) NOT NULL,
    amount_usd              NUMERIC(12, 4) NOT NULL DEFAULT 0,
    amount_idr              NUMERIC(16, 2) NOT NULL DEFAULT 0,
    currency                VARCHAR(3) NOT NULL DEFAULT 'IDR',
    direction               VARCHAR(8) NOT NULL,
    reason                  VARCHAR(32) NOT NULL,
    note                    TEXT NOT NULL DEFAULT '',
    adjusted_by_iid         BIGINT NOT NULL REFERENCES ai.identity(id),
    meta                    JSONB NOT NULL DEFAULT '{}',
    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_billing_admin_adjust_kind CHECK (
        kind IN ('balance', 'commission')
    ),
    CONSTRAINT chk_billing_admin_adjust_direction CHECK (
        direction IN ('credit', 'debit')
    ),
    CONSTRAINT chk_billing_admin_adjust_reason CHECK (
        reason IN (
            'promotional', 'compensation', 'correction', 'manual_accrual',
            'commission_clawback', 'refund', 'topup_manual', 'migration',
            'internal_test', 'withdraw_reversal', 'other'
        )
    ),
    CONSTRAINT chk_billing_admin_adjust_currency CHECK (
        currency ~ '^[A-Z]{3}$'
    )
);

CREATE INDEX IF NOT EXISTS idx_billing_admin_adjust_reason_ts
    ON ai.billing_admin_adjustment (reason, created_ts DESC);

CREATE INDEX IF NOT EXISTS idx_billing_admin_adjust_owner_ts
    ON ai.billing_admin_adjustment (owner_iid, created_ts DESC);

CREATE INDEX IF NOT EXISTS idx_billing_admin_adjust_kind_reason
    ON ai.billing_admin_adjustment (kind, reason, created_ts DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_commission_ledger_accrual_ref
    ON ai.commission_ledger (owner_iid, (meta->>'reference_id'))
    WHERE entry_type = 'accrual' AND COALESCE(meta->>'reference_id', '') <> '';

-- ------------------------------------------------------------------------------
-- Package purchases (referral code type=purchase)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_package_purchase (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    billing_account_id  BIGINT NOT NULL REFERENCES ai.billing_account(id),
    referral_code       VARCHAR(64) NOT NULL REFERENCES ai.referral_code(code),

    amount_usd          NUMERIC(12, 4) NOT NULL DEFAULT 0,
    amount_idr          NUMERIC(14, 2) NOT NULL DEFAULT 0,
    plan_tier           VARCHAR(32) NOT NULL DEFAULT '',
    duration_months     INT NOT NULL DEFAULT 0,

    meta                JSONB NOT NULL DEFAULT '{}',
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_package_purchase_owner
    ON ai.billing_package_purchase (owner_iid, created_ts DESC);

-- ------------------------------------------------------------------------------
-- Plan catalog + scoped subscriptions (bot / device / personal)
-- See _/docs/billing-plans.md
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_plan (
    slug                     VARCHAR(32) PRIMARY KEY,
    name                     VARCHAR(64) NOT NULL,
    scope                    VARCHAR(16) NOT NULL DEFAULT 'user',
    sort_order               INT NOT NULL DEFAULT 0,
    price_usd                NUMERIC(10, 2) NOT NULL DEFAULT 0,
    duration_months          INT NOT NULL DEFAULT 1,
    alien_allow_5h_usd       NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_weekly_usd   NUMERIC(12, 6) NOT NULL DEFAULT 0,
    msgs_limit               INT NOT NULL DEFAULT 0,
    channels_limit           INT NOT NULL DEFAULT 0,
    concurrent_limit         INT NOT NULL DEFAULT 0,
    caps_json                JSONB NOT NULL DEFAULT '{}',
    overage_enabled          BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                BOOLEAN NOT NULL DEFAULT TRUE,
    alien_pool_idr_monthly   NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_idr_monthly NUMERIC(16, 2) NOT NULL DEFAULT 0,
    pool_multiplier          NUMERIC(8, 4) NOT NULL DEFAULT 1,
    tier                     VARCHAR(16) NOT NULL DEFAULT '',
    created_ts               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ai.billing_plan ADD COLUMN IF NOT EXISTS alien_pool_idr_monthly NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_plan ADD COLUMN IF NOT EXISTS frontier_pool_idr_monthly NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_plan ADD COLUMN IF NOT EXISTS pool_multiplier NUMERIC(8, 4) NOT NULL DEFAULT 1;
ALTER TABLE ai.billing_plan ADD COLUMN IF NOT EXISTS tier VARCHAR(16) NOT NULL DEFAULT '';

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
     TRUE, TRUE, 175000, 35000, 4, 'plus'),
    ('pro', 'Pro', 'user', 30, 20.00, 1, 1.00, 20.00, 0, 3, 0,
     '{"outbound_gap_ms":10000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":false,"queue_priority_multiplier":5}',
     TRUE, TRUE, 565000, 115000, 10, 'pro'),
    ('ultra', 'Ultra', 'user', 40, 65.00, 1, 4.00, 80.00, 0, 5, 0,
     '{"outbound_gap_ms":8000,"outbound_gap_slow_ms":15000,"slow_model":"alienai","priority_queue":true,"queue_priority_multiplier":30}',
     TRUE, TRUE, 2000000, 400000, 40, 'ultra'),
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

CREATE TABLE IF NOT EXISTS ai.billing_subscription (
    id                          BIGINT PRIMARY KEY,
    owner_iid                   BIGINT NOT NULL REFERENCES ai.identity(id),
    scope                       VARCHAR(16) NOT NULL,
    scope_iid                   BIGINT NOT NULL,
    plan_slug                   VARCHAR(32) NOT NULL REFERENCES ai.billing_plan(slug),

    alien_allow_5h_used         NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_5h_limit        NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_weekly_used     NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_weekly_limit    NUMERIC(12, 6) NOT NULL DEFAULT 0,
    msgs_used                   INT NOT NULL DEFAULT 0,
    msgs_limit                  INT NOT NULL DEFAULT 0,

    window_5h_start             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    window_weekly_start         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    window_month_start          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_ts                  TIMESTAMPTZ,

    alien_pool_limit_idr        NUMERIC(16, 2) NOT NULL DEFAULT 0,
    alien_pool_used_idr         NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_limit_idr     NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_used_idr      NUMERIC(16, 2) NOT NULL DEFAULT 0,
    pool_period_start           TIMESTAMPTZ,

    meta                        JSONB NOT NULL DEFAULT '{}',
    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts                  TIMESTAMPTZ,

    CONSTRAINT chk_billing_subscription_scope CHECK (
        scope IN ('user', 'bot', 'device', 'team')
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_subscription_scope
    ON ai.billing_subscription (scope, scope_iid)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_subscription_owner
    ON ai.billing_subscription (owner_iid, scope, updated_ts DESC)
    WHERE deleted_ts IS NULL;

ALTER TABLE ai.billing_subscription ADD COLUMN IF NOT EXISTS alien_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription ADD COLUMN IF NOT EXISTS alien_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription ADD COLUMN IF NOT EXISTS frontier_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription ADD COLUMN IF NOT EXISTS frontier_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_subscription ADD COLUMN IF NOT EXISTS pool_period_start TIMESTAMPTZ;

-- ------------------------------------------------------------------------------
-- v2: Profile (quota + plan tier — one per user; NOT spendable balance)
-- identity.billing_profile_iid → id
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_profile (
    id                          BIGINT PRIMARY KEY,
    owner_iid                   BIGINT NOT NULL REFERENCES ai.identity(id),

    plan_tier                   VARCHAR(32) NOT NULL DEFAULT 'free',
    default_wallet_currency     VARCHAR(3) NOT NULL DEFAULT 'IDR',

    alien_allow_5h_used         NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_5h_limit        NUMERIC(12, 6) NOT NULL DEFAULT 0.05,
    alien_allow_weekly_used     NUMERIC(12, 6) NOT NULL DEFAULT 0,
    alien_allow_weekly_limit    NUMERIC(12, 6) NOT NULL DEFAULT 1.00,
    window_5h_start             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    window_weekly_start         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    alien_pool_limit_idr        NUMERIC(16, 2) NOT NULL DEFAULT 0,
    alien_pool_used_idr         NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_limit_idr     NUMERIC(16, 2) NOT NULL DEFAULT 0,
    frontier_pool_used_idr      NUMERIC(16, 2) NOT NULL DEFAULT 0,
    pool_period_start           TIMESTAMPTZ,
    trial_expires_ts            TIMESTAMPTZ,
    active_promotion_id         BIGINT,

    commission_available_usd    NUMERIC(12, 4) NOT NULL DEFAULT 0,
    commission_earned_usd       NUMERIC(12, 4) NOT NULL DEFAULT 0,
    commission_available_idr    NUMERIC(14, 2) NOT NULL DEFAULT 0,
    commission_earned_idr       NUMERIC(14, 2) NOT NULL DEFAULT 0,

    meta                        JSONB NOT NULL DEFAULT '{}',
    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts                  TIMESTAMPTZ,

    CONSTRAINT chk_billing_profile_currency CHECK (
        default_wallet_currency ~ '^[A-Z]{3}$'
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_profile_owner
    ON ai.billing_profile (owner_iid)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_profile_sync
    ON ai.billing_profile (owner_iid, updated_ts);

ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS alien_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS alien_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS frontier_pool_limit_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS frontier_pool_used_idr NUMERIC(16, 2) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS pool_period_start TIMESTAMPTZ;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS trial_expires_ts TIMESTAMPTZ;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS active_promotion_id BIGINT;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS freemium_day DATE;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS plan_expires_ts TIMESTAMPTZ;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS freemium_msgs_used INT NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS freemium_tokens_used INT NOT NULL DEFAULT 0;

-- ------------------------------------------------------------------------------
-- v2: Wallet (native balance per owner_iid + currency)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_wallet (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    currency        VARCHAR(3) NOT NULL,
    balance         NUMERIC(20, 4) NOT NULL DEFAULT 0,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    name            VARCHAR(64) NOT NULL DEFAULT '',

    meta            JSONB NOT NULL DEFAULT '{}',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    CONSTRAINT chk_billing_wallet_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_billing_wallet_balance_nonneg CHECK (balance >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_wallet_owner_currency
    ON ai.billing_wallet (owner_iid, currency)
    WHERE deleted_ts IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_wallet_default
    ON ai.billing_wallet (owner_iid)
    WHERE is_default = TRUE AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_billing_wallet_sync
    ON ai.billing_wallet (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- v2: Native catalog prices per (plan_slug, currency)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_plan_price (
    plan_slug       VARCHAR(32) NOT NULL REFERENCES ai.billing_plan(slug),
    currency        VARCHAR(3) NOT NULL,
    amount          NUMERIC(20, 4) NOT NULL,
    billing_period  VARCHAR(16) NOT NULL DEFAULT 'monthly',

    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (plan_slug, currency, billing_period),
    CONSTRAINT chk_billing_plan_price_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_billing_plan_price_amount_nonneg CHECK (amount >= 0)
);

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

INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
    ('lite', 'IDR', 49000, 'yearly'),
    ('lite', 'IDR', 59000, 'monthly'),
    ('plus', 'IDR', 99000, 'yearly'),
    ('plus', 'IDR', 105000, 'monthly'),
    ('pro', 'IDR', 309000, 'yearly'),
    ('pro', 'IDR', 340000, 'monthly'),
    ('ultra', 'IDR', 1000000, 'yearly'),
    ('ultra', 'IDR', 1200000, 'monthly'),
    ('bot.lite', 'IDR', 39000, 'yearly'),
    ('bot.lite', 'IDR', 49000, 'monthly'),
    ('bot.small', 'IDR', 89000, 'yearly'),
    ('bot.small', 'IDR', 99000, 'monthly'),
    ('device.light', 'IDR', 499000, 'yearly'),
    ('device.light', 'IDR', 599000, 'monthly'),
    ('device.medium', 'IDR', 999000, 'yearly'),
    ('device.medium', 'IDR', 1109000, 'monthly'),
    ('plus', 'USD', 4.99, 'monthly'),
    ('pro', 'USD', 14.99, 'monthly'),
    ('bot.small', 'USD', 5.99, 'monthly')
ON CONFLICT (plan_slug, currency, billing_period) DO UPDATE SET
    amount = EXCLUDED.amount,
    is_active = EXCLUDED.is_active,
    updated_ts = NOW();

UPDATE ai.billing_plan_price
SET is_active = FALSE, updated_ts = NOW()
WHERE plan_slug IN ('free', 'bot.medium', 'bot.large', 'device.office_light', 'device.office_pro');

-- ------------------------------------------------------------------------------
-- v2: Published FX rates (metered usage deduct only — NOT catalog checkout)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_fx_rate (
    id              BIGINT PRIMARY KEY,
    currency        VARCHAR(3) NOT NULL,
    micro_per_usd   BIGINT NOT NULL,
    effective_from  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_billing_fx_rate_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_billing_fx_rate_micro_pos CHECK (micro_per_usd > 0)
);

CREATE INDEX IF NOT EXISTS idx_billing_fx_rate_currency_effective
    ON ai.billing_fx_rate (currency, effective_from DESC);

INSERT INTO ai.billing_fx_rate (id, currency, micro_per_usd, effective_from)
VALUES (1, 'IDR', 17630000000, NOW())
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- v2: Direct plan purchase (provider checkout — no wallet credit)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.billing_purchase (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    plan_slug           VARCHAR(32) NOT NULL REFERENCES ai.billing_plan(slug),
    currency            VARCHAR(3) NOT NULL,
    amount              NUMERIC(20, 4) NOT NULL,

    provider            VARCHAR(32) NOT NULL DEFAULT 'manual',
    external_order_id   VARCHAR(128) NOT NULL DEFAULT '',
    status              VARCHAR(16) NOT NULL DEFAULT 'pending',

    scope               VARCHAR(16) NOT NULL DEFAULT 'user',
    scope_iid           BIGINT NOT NULL DEFAULT 0,

    meta                JSONB NOT NULL DEFAULT '{}',
    settled_ts          TIMESTAMPTZ,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_billing_purchase_status CHECK (
        status IN ('pending', 'settled', 'failed', 'cancelled')
    ),
    CONSTRAINT chk_billing_purchase_currency CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE INDEX IF NOT EXISTS idx_billing_purchase_owner
    ON ai.billing_purchase (owner_iid, created_ts DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_purchase_external_order
    ON ai.billing_purchase (external_order_id)
    WHERE external_order_id <> '';

-- ------------------------------------------------------------------------------
-- v3: Promotions (trials, custom packages, discounts)
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

-- ------------------------------------------------------------------------------
-- v2 FK targets (Phase 3 — parallel columns on legacy tables until migration)
-- billing_topup_request.wallet_id → billing_wallet(id)
-- billing_reservation.wallet_id → billing_wallet(id)
-- billing_usage_dedupe.wallet_id, deducted_amount, currency, fx_rate_id
-- ------------------------------------------------------------------------------

-- Seed: billing wallet for automated tester (owner_iid 33000)
INSERT INTO ai.billing_account (
    id, owner_iid, name, balance_usd, balance_idr, plan_tier,
    alien_allow_5h_limit, alien_allow_weekly_limit, updated_ts
) VALUES (
    330000000000000001,
    33000,
    'Personal',
    100,
    10000000,
    'pro',
    1.0,
    10.0,
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    owner_iid = EXCLUDED.owner_iid,
    balance_usd = GREATEST(ai.billing_account.balance_usd, EXCLUDED.balance_usd),
    balance_idr = GREATEST(ai.billing_account.balance_idr, EXCLUDED.balance_idr),
    alien_allow_5h_limit = GREATEST(ai.billing_account.alien_allow_5h_limit, EXCLUDED.alien_allow_5h_limit),
    alien_allow_weekly_limit = GREATEST(ai.billing_account.alien_allow_weekly_limit, EXCLUDED.alien_allow_weekly_limit),
    updated_ts = NOW(),
    deleted_ts = NULL;

UPDATE ai.billing_account SET
    balance_usd = GREATEST(balance_usd, 100),
    balance_idr = GREATEST(balance_idr, 10000000),
    alien_allow_5h_limit = GREATEST(alien_allow_5h_limit, 1.0),
    alien_allow_weekly_limit = GREATEST(alien_allow_weekly_limit, 10.0),
    updated_ts = NOW(),
    deleted_ts = NULL
WHERE owner_iid = 33000;
