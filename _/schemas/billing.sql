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
        status IN ('pending', 'approved', 'rejected', 'cancelled')
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

    meta                    JSONB NOT NULL DEFAULT '{}',
    settled_ts              TIMESTAMPTZ,
    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_billing_reservation_req UNIQUE (req_id),
    CONSTRAINT chk_billing_reservation_status CHECK (
        status IN ('held', 'settled', 'refunded')
    )
);

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

    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (owner_iid, req_id)
);

ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT '';
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS amount_native NUMERIC(20, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_usage_dedupe ADD COLUMN IF NOT EXISTS deducted_native NUMERIC(20, 4) NOT NULL DEFAULT 0;

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
    created_ts               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO ai.billing_plan (
    slug, name, scope, sort_order, price_usd, duration_months,
    alien_allow_5h_usd, alien_allow_weekly_usd,
    msgs_limit, channels_limit, concurrent_limit, caps_json, overage_enabled, is_active
) VALUES
    ('free', 'Free', 'user', 10, 0, 1, 0.05, 1.00, 0, 0, 0, '{}', FALSE, TRUE),
    ('plus', 'Plus', 'user', 20, 9.99, 1, 0.25, 5.00, 0, 0, 0, '{}', TRUE, TRUE),
    ('pro', 'Pro', 'user', 30, 29.99, 1, 1.00, 20.00, 0, 0, 0, '{}', TRUE, TRUE),
    ('bot.small', 'Bot Small', 'bot', 40, 3.00, 1, 0.10, 2.00, 2000, 1, 3, '{"outbound_per_sec":1}', TRUE, TRUE),
    ('bot.medium', 'Bot Medium', 'bot', 50, 6.00, 1, 0.25, 5.00, 10000, 2, 8, '{"outbound_per_sec":3}', TRUE, TRUE),
    ('bot.large', 'Bot Large', 'bot', 60, 12.00, 1, 0.50, 10.00, 50000, 5, 15, '{"outbound_per_sec":8}', TRUE, TRUE),
    ('device.office_light', 'Office Light', 'device', 70, 28.00, 1, 0.40, 8.00, 0, 0, 1, '{}', TRUE, TRUE),
    ('device.office_pro', 'Office Pro', 'device', 80, 57.00, 1, 1.00, 20.00, 0, 0, 3, '{}', TRUE, TRUE)
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
    updated_ts = NOW();

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

    PRIMARY KEY (plan_slug, currency),
    CONSTRAINT chk_billing_plan_price_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_billing_plan_price_amount_nonneg CHECK (amount >= 0)
);

INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
    ('plus', 'IDR', 49000, 'monthly'),
    ('plus', 'USD', 4.99, 'monthly'),
    ('pro', 'IDR', 149000, 'monthly'),
    ('pro', 'USD', 14.99, 'monthly'),
    ('bot.small', 'IDR', 60000, 'monthly'),
    ('bot.small', 'USD', 5.99, 'monthly'),
    ('bot.medium', 'IDR', 120000, 'monthly'),
    ('bot.medium', 'USD', 11.99, 'monthly'),
    ('bot.large', 'IDR', 240000, 'monthly'),
    ('bot.large', 'USD', 23.99, 'monthly'),
    ('device.office_light', 'IDR', 39000, 'monthly'),
    ('device.office_light', 'USD', 3.99, 'monthly'),
    ('device.office_pro', 'IDR', 99000, 'monthly'),
    ('device.office_pro', 'USD', 9.99, 'monthly')
ON CONFLICT (plan_slug, currency) DO UPDATE SET
    amount = EXCLUDED.amount,
    billing_period = EXCLUDED.billing_period,
    is_active = EXCLUDED.is_active,
    updated_ts = NOW();

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
-- v2 FK targets (Phase 3 — parallel columns on legacy tables until migration)
-- billing_topup_request.wallet_id → billing_wallet(id)
-- billing_reservation.wallet_id → billing_wallet(id)
-- billing_usage_dedupe.wallet_id, deducted_amount, currency, fx_rate_id
-- ------------------------------------------------------------------------------

