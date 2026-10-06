-- billing_rings_v4: profile 5h/7d rings for alien + frontier; retire monthly IDR pools on profile.

ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS frontier_allow_5h_used NUMERIC(12, 6) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS frontier_allow_5h_limit NUMERIC(12, 6) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS frontier_allow_weekly_used NUMERIC(12, 6) NOT NULL DEFAULT 0;
ALTER TABLE ai.billing_profile ADD COLUMN IF NOT EXISTS frontier_allow_weekly_limit NUMERIC(12, 6) NOT NULL DEFAULT 0;

UPDATE ai.billing_profile
SET alien_pool_used_idr = 0,
    alien_pool_limit_idr = 0,
    frontier_pool_used_idr = 0,
    frontier_pool_limit_idr = 0,
    updated_ts = NOW()
WHERE deleted_ts IS NULL
  AND (alien_pool_limit_idr <> 0 OR frontier_pool_limit_idr <> 0
       OR alien_pool_used_idr <> 0 OR frontier_pool_used_idr <> 0);
