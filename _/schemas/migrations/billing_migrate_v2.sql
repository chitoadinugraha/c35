-- ==============================================================================
-- c35 — Billing v2 migration (billing_account → billing_profile + billing_wallet)
-- Run once on existing DBs after billing.sql v2 tables exist.
-- See _/docs/billing-implementation.md Phase 1
-- ==============================================================================

-- Add identity column if not present (idempotent for fresh identity.sql)
ALTER TABLE ai.identity
    ADD COLUMN IF NOT EXISTS billing_profile_iid BIGINT;

-- Migrate each legacy billing_account row
DO $$
DECLARE
    r RECORD;
    v_profile_id BIGINT;
    v_idr_wallet_id BIGINT;
    v_usd_wallet_id BIGINT;
    v_default_currency VARCHAR(3);
BEGIN
    FOR r IN
        SELECT *
        FROM ai.billing_account
        WHERE deleted_ts IS NULL
    LOOP
        v_default_currency := COALESCE(NULLIF(r.billing_currency, ''), 'IDR');

        -- Skip if already migrated
        IF EXISTS (
            SELECT 1 FROM ai.billing_profile p
            WHERE p.owner_iid = r.owner_iid AND p.deleted_ts IS NULL
        ) THEN
            CONTINUE;
        END IF;

        v_profile_id := r.id;  -- reuse snowflake id for profile

        INSERT INTO ai.billing_profile (
            id, owner_iid, plan_tier, default_wallet_currency,
            alien_allow_5h_used, alien_allow_5h_limit,
            alien_allow_weekly_used, alien_allow_weekly_limit,
            window_5h_start, window_weekly_start,
            commission_available_usd, commission_earned_usd,
            commission_available_idr, commission_earned_idr,
            meta, created_ts, updated_ts
        ) VALUES (
            v_profile_id, r.owner_iid, r.plan_tier, v_default_currency,
            r.alien_allow_5h_used, r.alien_allow_5h_limit,
            r.alien_allow_weekly_used, r.alien_allow_weekly_limit,
            r.window_5h_start, r.window_weekly_start,
            r.commission_available_usd, r.commission_earned_usd,
            r.commission_available_idr, r.commission_earned_idr,
            r.meta, r.created_ts, r.updated_ts
        );

        v_idr_wallet_id := v_profile_id + 1;
        v_usd_wallet_id := v_profile_id + 2;

        INSERT INTO ai.billing_wallet (
            id, owner_iid, currency, balance, is_default, name,
            created_ts, updated_ts
        ) VALUES (
            v_idr_wallet_id, r.owner_iid, 'IDR', r.balance_idr,
            v_default_currency = 'IDR', 'IDR Wallet',
            r.created_ts, r.updated_ts
        );

        INSERT INTO ai.billing_wallet (
            id, owner_iid, currency, balance, is_default, name,
            created_ts, updated_ts
        ) VALUES (
            v_usd_wallet_id, r.owner_iid, 'USD', r.balance_usd,
            v_default_currency = 'USD', 'USD Wallet',
            r.created_ts, r.updated_ts
        );

        UPDATE ai.identity
        SET billing_profile_iid = v_profile_id,
            updated_ts = NOW()
        WHERE id = r.owner_iid
          AND billing_profile_iid IS NULL;
    END LOOP;
END $$;
