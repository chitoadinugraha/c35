-- ==============================================================================
-- c35 — Billing finance v1 (receive accounts, commission withdraw, topup statuses)
-- Run after billing.sql on existing DBs.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- billing_account — pending commission balances (withdraw in-flight)
-- ------------------------------------------------------------------------------

ALTER TABLE ai.billing_account
    ADD COLUMN IF NOT EXISTS commission_pending_usd NUMERIC(12, 4) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_account
    ADD COLUMN IF NOT EXISTS commission_pending_idr NUMERIC(14, 2) NOT NULL DEFAULT 0;

-- ------------------------------------------------------------------------------
-- billing_receive_account — manual transfer destination accounts
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
-- commission_withdraw_request — payout review queue
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

-- ------------------------------------------------------------------------------
-- billing_topup_request — extend status values
-- ------------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_billing_topup_status'
          AND conrelid = 'ai.billing_topup_request'::regclass
    ) THEN
        ALTER TABLE ai.billing_topup_request DROP CONSTRAINT chk_billing_topup_status;
    END IF;
    ALTER TABLE ai.billing_topup_request ADD CONSTRAINT chk_billing_topup_status CHECK (
        status IN (
            'pending', 'pending_review', 'approved', 'rejected', 'cancelled',
            'settled', 'failed', 'expired'
        )
    );
END $$;

CREATE INDEX IF NOT EXISTS idx_billing_topup_manual_pending
    ON ai.billing_topup_request (provider, status, created_ts DESC)
    WHERE provider = 'manual' AND deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Seed default IDR receive account (BCA — matches billing_topup.dart)
-- ------------------------------------------------------------------------------

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
