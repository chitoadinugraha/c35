-- Backfill missing frontier 5h/7d ring limits from plan template; retire legacy monthly pools when rings exist.

UPDATE ai.billing_profile p
SET
    frontier_allow_5h_limit = CASE
        WHEN bp.alien_pool_idr_monthly > 0 THEN
            p.alien_allow_5h_limit * (bp.frontier_pool_idr_monthly / bp.alien_pool_idr_monthly)
        ELSE 0
    END,
    frontier_allow_weekly_limit = CASE
        WHEN bp.alien_pool_idr_monthly > 0 THEN
            p.alien_allow_weekly_limit * (bp.frontier_pool_idr_monthly / bp.alien_pool_idr_monthly)
        ELSE 0
    END,
    alien_pool_limit_idr = 0,
    alien_pool_used_idr = 0,
    frontier_pool_limit_idr = 0,
    frontier_pool_used_idr = 0,
    updated_ts = NOW()
FROM ai.billing_plan bp
WHERE p.deleted_ts IS NULL
  AND bp.slug = p.plan_tier
  AND bp.scope = 'user'
  AND bp.is_active = TRUE
  AND p.plan_tier NOT IN ('', 'free')
  AND (p.alien_allow_5h_limit > 0 OR p.alien_allow_weekly_limit > 0)
  AND p.frontier_allow_5h_limit <= 0
  AND p.frontier_allow_weekly_limit <= 0;

UPDATE ai.billing_profile p
SET
    alien_pool_limit_idr = 0,
    alien_pool_used_idr = 0,
    frontier_pool_limit_idr = 0,
    frontier_pool_used_idr = 0,
    updated_ts = NOW()
WHERE p.deleted_ts IS NULL
  AND (p.alien_pool_limit_idr <> 0 OR p.frontier_pool_limit_idr <> 0
       OR p.alien_pool_used_idr <> 0 OR p.frontier_pool_used_idr <> 0)
  AND (p.alien_allow_5h_limit > 0 OR p.alien_allow_weekly_limit > 0
       OR p.frontier_allow_5h_limit > 0 OR p.frontier_allow_weekly_limit > 0);
