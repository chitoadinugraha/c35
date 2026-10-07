-- Revoke undocumented USD 10 / Rp 176.300 signup wallet seed (2026-10-07).
-- Preserves referral Rp 10.000 (when referred_by_iid is set) and skips operator / test
-- accounts and any owner with a settled top-up.

WITH targets AS (
    SELECT
        ba.id,
        ba.owner_iid,
        ba.balance_usd,
        ba.balance_idr,
        (i.referred_by_iid IS NOT NULL AND i.referred_by_iid > 0) AS has_ref
    FROM ai.billing_account ba
    INNER JOIN ai.identity i ON i.id = ba.owner_iid
    WHERE ba.deleted_ts IS NULL
      AND ba.owner_iid NOT IN (99000, 30000, 33000)
      AND (ba.balance_usd > 0 OR ba.balance_idr > 0)
      AND NOT EXISTS (
          SELECT 1
          FROM ai.billing_topup_request t
          WHERE t.owner_iid = ba.owner_iid
            AND t.status = 'settled'
            AND t.deleted_ts IS NULL
      )
),
computed AS (
    SELECT
        id,
        owner_iid,
        balance_usd AS old_usd,
        balance_idr AS old_idr,
        CASE
            WHEN has_ref THEN GREATEST(
                0::numeric,
                balance_idr - LEAST(176300::numeric, GREATEST(0::numeric, balance_idr - 10000::numeric))
            )
            ELSE GREATEST(0::numeric, balance_idr - LEAST(176300::numeric, balance_idr))
        END AS new_idr
    FROM targets
),
computed2 AS (
    SELECT
        *,
        old_idr - new_idr AS revoke_idr,
        LEAST(10::numeric, (old_idr - new_idr) / 17630.0) AS revoke_usd
    FROM computed
    WHERE old_idr > new_idr
)
UPDATE ai.billing_account ba
SET
    balance_idr = c2.new_idr,
    balance_usd = GREATEST(0::numeric, c2.old_usd - c2.revoke_usd),
    updated_ts = NOW()
FROM computed2 c2
WHERE ba.id = c2.id;