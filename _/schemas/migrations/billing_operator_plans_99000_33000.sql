-- Operator / test identities: fixed plan tiers (re-runnable).
-- 33000 automated-tester -> Pro; 99000 chito -> Ultra
-- Ring limits live on ai.billing_profile (not inflated billing_account alien_allow_*).
-- Apply: run against c35 YSQL after identity + billing_plan seeds.

-- 99000 -- billing account (wallet + tier only; legacy account rings not used when profile exists)
INSERT INTO ai.billing_account (
    id, owner_iid, name, balance_usd, balance_idr, plan_tier, updated_ts
) VALUES (
    990000000000000001,
    99000,
    'Personal',
    500,
    50000000,
    'ultra',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    owner_iid = EXCLUDED.owner_iid,
    plan_tier = 'ultra',
    balance_usd = GREATEST(ai.billing_account.balance_usd, EXCLUDED.balance_usd),
    balance_idr = GREATEST(ai.billing_account.balance_idr, EXCLUDED.balance_idr),
    updated_ts = NOW(),
    deleted_ts = NULL;

UPDATE ai.billing_account SET
    plan_tier = 'ultra',
    updated_ts = NOW(),
    deleted_ts = NULL
WHERE owner_iid = 99000;

-- 33000 -- ensure Pro on legacy account (wallet/tier only)
UPDATE ai.billing_account SET
    plan_tier = 'pro',
    updated_ts = NOW(),
    deleted_ts = NULL
WHERE owner_iid = 33000;

-- billing_profile 99000 Ultra (rings + monthly pools from plan)
INSERT INTO ai.billing_profile (
    id, owner_iid, plan_tier, default_wallet_currency,
    alien_pool_limit_idr, alien_pool_used_idr,
    frontier_pool_limit_idr, frontier_pool_used_idr,
    pool_period_start, plan_expires_ts
) VALUES (
    990000000000000010,
    99000,
    'ultra',
    'IDR',
    2000000,
    0,
    400000,
    0,
    NOW(),
    NOW() + INTERVAL '10 years'
) ON CONFLICT (id) DO UPDATE SET
    owner_iid = EXCLUDED.owner_iid,
    plan_tier = 'ultra',
    alien_pool_limit_idr = EXCLUDED.alien_pool_limit_idr,
    frontier_pool_limit_idr = EXCLUDED.frontier_pool_limit_idr,
    plan_expires_ts = EXCLUDED.plan_expires_ts,
    updated_ts = NOW(),
    deleted_ts = NULL;

-- billing_profile 33000 Pro pools shell
INSERT INTO ai.billing_profile (
    id, owner_iid, plan_tier, default_wallet_currency,
    alien_pool_limit_idr, alien_pool_used_idr,
    frontier_pool_limit_idr, frontier_pool_used_idr,
    pool_period_start, plan_expires_ts
) VALUES (
    330000000000000010,
    33000,
    'pro',
    'IDR',
    565000,
    0,
    115000,
    0,
    NOW(),
    NOW() + INTERVAL '10 years'
) ON CONFLICT (id) DO UPDATE SET
    owner_iid = EXCLUDED.owner_iid,
    plan_tier = 'pro',
    alien_pool_limit_idr = EXCLUDED.alien_pool_limit_idr,
    frontier_pool_limit_idr = EXCLUDED.frontier_pool_limit_idr,
    plan_expires_ts = EXCLUDED.plan_expires_ts,
    updated_ts = NOW(),
    deleted_ts = NULL;

-- Apply 5h/7d ring limits from ai.billing_plan (alien + scaled frontier rings)
UPDATE ai.billing_profile p
SET
    plan_tier = bp.tier,
    alien_allow_5h_limit = bp.alien_allow_5h_usd,
    alien_allow_weekly_limit = bp.alien_allow_weekly_usd,
    frontier_allow_5h_limit = CASE
        WHEN bp.alien_pool_idr_monthly > 0 THEN
            bp.alien_allow_5h_usd * (bp.frontier_pool_idr_monthly / bp.alien_pool_idr_monthly)
        ELSE 0
    END,
    frontier_allow_weekly_limit = CASE
        WHEN bp.alien_pool_idr_monthly > 0 THEN
            bp.alien_allow_weekly_usd * (bp.frontier_pool_idr_monthly / bp.alien_pool_idr_monthly)
        ELSE 0
    END,
    alien_pool_limit_idr = 0,
    frontier_pool_limit_idr = 0,
    alien_pool_used_idr = 0,
    frontier_pool_used_idr = 0,
    plan_expires_ts = COALESCE(p.plan_expires_ts, NOW() + INTERVAL '10 years'),
    updated_ts = NOW()
FROM ai.billing_plan bp
WHERE p.owner_iid IN (33000, 99000)
  AND p.deleted_ts IS NULL
  AND bp.slug = p.plan_tier
  AND bp.is_active = TRUE;

UPDATE ai.identity i SET
    billing_profile_iid = p.id,
    updated_ts = NOW()
FROM ai.billing_profile p
WHERE i.id = p.owner_iid
  AND i.id IN (33000, 99000)
  AND p.deleted_ts IS NULL;
