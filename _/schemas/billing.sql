-- ==============================================================================
-- c35 — Billing schema (LOCKED 2026-09-20)
-- Apply after identity.sql
-- Wallet, quota rings, top-up, reservation, usage dedupe
-- Audit + cost rows: log.sql (single log table)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Wallet (one primary per user; identity.billing_iid → id)
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

    created_ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (owner_iid, req_id)
);

CREATE INDEX IF NOT EXISTS idx_billing_usage_dedupe_account
    ON ai.billing_usage_dedupe (billing_account_id, created_ts DESC);
