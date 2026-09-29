-- ==============================================================================
-- c35 — Billing v2 migration (billing_account → billing_profile + billing_wallet)
-- One-time, idempotent migration script.
-- Applies after billing.sql v2 schema tables exist.
-- See _/docs/billing.md and _/docs/billing-implementation.md Phase 1
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. Prerequisites & identity column
-- ------------------------------------------------------------------------------
ALTER TABLE ai.identity
    ADD COLUMN IF NOT EXISTS billing_profile_iid BIGINT;

-- ------------------------------------------------------------------------------
-- 1. Populate billing_profile from billing_account (for users that don't have a profile yet)
-- Uses ba.id * 10 + 1 (with overflow guard for large 18-digit seed IDs like 990000000000000001)
-- ------------------------------------------------------------------------------
INSERT INTO ai.billing_profile (
    id, owner_iid, plan_tier, default_wallet_currency,
    alien_allow_5h_used, alien_allow_5h_limit,
    alien_allow_weekly_used, alien_allow_weekly_limit,
    window_5h_start, window_weekly_start,
    commission_available_usd, commission_earned_usd,
    commission_available_idr, commission_earned_idr,
    created_ts, updated_ts
)
SELECT
    CASE
        WHEN ba.id <= 922337203685477580 THEN ba.id * 10 + 1
        ELSE ba.id + 9
    END AS id,
    ba.owner_iid,
    ba.plan_tier,
    COALESCE(NULLIF(ba.billing_currency, ''), 'IDR') AS default_wallet_currency,
    ba.alien_allow_5h_used,
    ba.alien_allow_5h_limit,
    ba.alien_allow_weekly_used,
    ba.alien_allow_weekly_limit,
    ba.window_5h_start,
    ba.window_weekly_start,
    ba.commission_available_usd,
    ba.commission_earned_usd,
    ba.commission_available_idr,
    ba.commission_earned_idr,
    ba.created_ts,
    ba.updated_ts
FROM ai.billing_account ba
WHERE NOT EXISTS (
    SELECT 1 FROM ai.billing_profile bp 
    WHERE bp.owner_iid = ba.owner_iid AND bp.deleted_ts IS NULL
)
AND ba.deleted_ts IS NULL
ON CONFLICT (id) DO NOTHING;

-- Backfill identity.billing_profile_iid for migrated and existing profiles
UPDATE ai.identity i
SET billing_profile_iid = bp.id,
    updated_ts = NOW()
FROM ai.billing_profile bp
WHERE bp.owner_iid = i.id
  AND (i.billing_profile_iid IS NULL OR i.billing_profile_iid <> bp.id)
  AND bp.deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- 2. Populate billing_wallet IDR wallet from billing_account.balance_idr
-- Uses ba.id * 10 + 2 (with overflow guard for large seed IDs)
-- ------------------------------------------------------------------------------
INSERT INTO ai.billing_wallet (
    id, owner_iid, currency, balance, is_default, name, created_ts, updated_ts
)
SELECT
    CASE
        WHEN ba.id <= 922337203685477580 THEN ba.id * 10 + 2
        ELSE ba.id + 1
    END AS id,
    ba.owner_iid,
    'IDR',
    ba.balance_idr,
    (ba.billing_currency = 'IDR') AS is_default,
    'Personal IDR',
    ba.created_ts,
    NOW()
FROM ai.billing_account ba
WHERE ba.balance_idr > 0
AND NOT EXISTS (
    SELECT 1 FROM ai.billing_wallet bw
    WHERE bw.owner_iid = ba.owner_iid AND bw.currency = 'IDR' AND bw.deleted_ts IS NULL
)
AND ba.deleted_ts IS NULL
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 3. Populate billing_wallet USD wallet from billing_account.balance_usd
-- Uses ba.id * 10 + 3 (with overflow guard for large seed IDs)
-- ------------------------------------------------------------------------------
INSERT INTO ai.billing_wallet (
    id, owner_iid, currency, balance, is_default, name, created_ts, updated_ts
)
SELECT
    CASE
        WHEN ba.id <= 922337203685477580 THEN ba.id * 10 + 3
        ELSE ba.id + 2
    END AS id,
    ba.owner_iid,
    'USD',
    ba.balance_usd,
    (ba.billing_currency = 'USD') AS is_default,
    'Personal USD',
    ba.created_ts,
    NOW()
FROM ai.billing_account ba
WHERE ba.balance_usd > 0
AND NOT EXISTS (
    SELECT 1 FROM ai.billing_wallet bw
    WHERE bw.owner_iid = ba.owner_iid AND bw.currency = 'USD' AND bw.deleted_ts IS NULL
)
AND ba.deleted_ts IS NULL
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 3b. Ensure users with 0 balances in both currencies get a default wallet
-- ------------------------------------------------------------------------------
INSERT INTO ai.billing_wallet (
    id, owner_iid, currency, balance, is_default, name, created_ts, updated_ts
)
SELECT
    CASE
        WHEN ba.id <= 922337203685477580 THEN ba.id * 10 + 2
        ELSE ba.id + 1
    END AS id,
    ba.owner_iid,
    COALESCE(NULLIF(ba.billing_currency, ''), 'IDR') AS currency,
    0,
    TRUE,
    'Personal ' || COALESCE(NULLIF(ba.billing_currency, ''), 'IDR'),
    ba.created_ts,
    NOW()
FROM ai.billing_account ba
WHERE ba.deleted_ts IS NULL
AND NOT EXISTS (
    SELECT 1 FROM ai.billing_wallet bw
    WHERE bw.owner_iid = ba.owner_iid AND bw.deleted_ts IS NULL
)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 4. Ensure exactly one is_default = TRUE per owner in billing_wallet
-- If user has both wallets but neither is default (edge case), set IDR as default
-- ------------------------------------------------------------------------------
UPDATE ai.billing_wallet bw
SET is_default = TRUE, updated_ts = NOW()
WHERE bw.currency = 'IDR'
AND bw.deleted_ts IS NULL
AND NOT EXISTS (
    SELECT 1 FROM ai.billing_wallet bw2
    WHERE bw2.owner_iid = bw.owner_iid AND bw2.is_default = TRUE AND bw2.deleted_ts IS NULL
);

-- Fallback: if user still has no default wallet, set the earliest wallet as default
UPDATE ai.billing_wallet bw
SET is_default = TRUE, updated_ts = NOW()
WHERE bw.deleted_ts IS NULL
AND NOT EXISTS (
    SELECT 1 FROM ai.billing_wallet bw2
    WHERE bw2.owner_iid = bw.owner_iid AND bw2.is_default = TRUE AND bw2.deleted_ts IS NULL
)
AND bw.id = (
    SELECT bw3.id FROM ai.billing_wallet bw3
    WHERE bw3.owner_iid = bw.owner_iid AND bw3.deleted_ts IS NULL
    ORDER BY bw3.created_ts ASC, bw3.id ASC
    LIMIT 1
);

-- ------------------------------------------------------------------------------
-- 5. Add FK-ready columns to legacy tables (nullable for now — Phase 3 prep)
-- ------------------------------------------------------------------------------
-- Add wallet_id column to billing_topup_request (nullable, FK to billing_wallet)
ALTER TABLE ai.billing_topup_request 
    ADD COLUMN IF NOT EXISTS wallet_id BIGINT REFERENCES ai.billing_wallet(id);

-- Add wallet_id to billing_reservation
ALTER TABLE ai.billing_reservation
    ADD COLUMN IF NOT EXISTS wallet_id BIGINT REFERENCES ai.billing_wallet(id);

-- Add wallet_id to billing_usage_dedupe (no FK on this one — it's a PK table, FK would be expensive)
ALTER TABLE ai.billing_usage_dedupe
    ADD COLUMN IF NOT EXISTS wallet_id BIGINT;

-- ------------------------------------------------------------------------------
-- 6. Backfill wallet_id on legacy tables for existing rows
-- ------------------------------------------------------------------------------
-- Backfill billing_topup_request.wallet_id where we can match owner+currency
UPDATE ai.billing_topup_request tr
SET wallet_id = bw.id, updated_ts = NOW()
FROM ai.billing_wallet bw
WHERE bw.owner_iid = tr.owner_iid
AND bw.currency = 'IDR'
AND bw.deleted_ts IS NULL
AND tr.wallet_id IS NULL
AND tr.amount_idr > 0;

UPDATE ai.billing_topup_request tr
SET wallet_id = bw.id, updated_ts = NOW()
FROM ai.billing_wallet bw
WHERE bw.owner_iid = tr.owner_iid
AND bw.currency = 'USD'
AND bw.deleted_ts IS NULL
AND tr.wallet_id IS NULL
AND tr.amount_usd > 0;

-- Fallback for remaining unlinked topup requests to user's default wallet
UPDATE ai.billing_topup_request tr
SET wallet_id = bw.id, updated_ts = NOW()
FROM ai.billing_wallet bw
WHERE bw.owner_iid = tr.owner_iid
AND bw.is_default = TRUE
AND bw.deleted_ts IS NULL
AND tr.wallet_id IS NULL;

-- Backfill billing_reservation.wallet_id (IDR match)
UPDATE ai.billing_reservation res
SET wallet_id = bw.id, updated_ts = NOW()
FROM ai.billing_wallet bw
WHERE bw.owner_iid = res.owner_iid
AND bw.currency = 'IDR'
AND bw.deleted_ts IS NULL
AND res.wallet_id IS NULL;

-- Fallback for remaining unlinked reservations to user's default wallet
UPDATE ai.billing_reservation res
SET wallet_id = bw.id, updated_ts = NOW()
FROM ai.billing_wallet bw
WHERE bw.owner_iid = res.owner_iid
AND bw.is_default = TRUE
AND bw.deleted_ts IS NULL
AND res.wallet_id IS NULL;

-- Backfill billing_usage_dedupe.wallet_id matching owner and currency
UPDATE ai.billing_usage_dedupe ud
SET wallet_id = bw.id
FROM ai.billing_wallet bw
WHERE bw.owner_iid = ud.owner_iid
AND bw.currency = ud.currency
AND bw.deleted_ts IS NULL
AND ud.wallet_id IS NULL
AND ud.currency <> '';

-- Fallback for legacy billing_usage_dedupe rows (empty currency or unmatched)
UPDATE ai.billing_usage_dedupe ud
SET wallet_id = bw.id
FROM ai.billing_wallet bw
WHERE bw.owner_iid = ud.owner_iid
AND bw.is_default = TRUE
AND bw.deleted_ts IS NULL
AND ud.wallet_id IS NULL;

-- ------------------------------------------------------------------------------
-- 7. Verification summary
-- ------------------------------------------------------------------------------
SELECT 'billing_profile rows' AS label, COUNT(*)::bigint AS count FROM ai.billing_profile WHERE deleted_ts IS NULL
UNION ALL
SELECT 'billing_wallet rows' AS label, COUNT(*)::bigint AS count FROM ai.billing_wallet WHERE deleted_ts IS NULL
UNION ALL
SELECT 'billing_wallet default rows' AS label, COUNT(*)::bigint AS count FROM ai.billing_wallet WHERE is_default = TRUE AND deleted_ts IS NULL
UNION ALL
SELECT 'billing_topup_request with wallet_id' AS label, COUNT(*)::bigint AS count FROM ai.billing_topup_request WHERE wallet_id IS NOT NULL
UNION ALL
SELECT 'billing_reservation with wallet_id' AS label, COUNT(*)::bigint AS count FROM ai.billing_reservation WHERE wallet_id IS NOT NULL
UNION ALL
SELECT 'billing_usage_dedupe with wallet_id' AS label, COUNT(*)::bigint AS count FROM ai.billing_usage_dedupe WHERE wallet_id IS NOT NULL
UNION ALL
SELECT 'identity with billing_profile_iid' AS label, COUNT(*)::bigint AS count FROM ai.identity WHERE billing_profile_iid IS NOT NULL;
