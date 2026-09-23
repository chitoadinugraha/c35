-- c35 — Admin balance / commission adjustments with reason audit trail
-- Apply after billing.sql

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
