-- Restore list IDR prices; included pools = 2× monthly subscription (83/17 Alien/API).

UPDATE ai.billing_plan SET
    alien_pool_idr_monthly = 175000,
    frontier_pool_idr_monthly = 35000,
    updated_ts = NOW()
WHERE slug = 'plus';

UPDATE ai.billing_plan SET
    alien_pool_idr_monthly = 565000,
    frontier_pool_idr_monthly = 115000,
    updated_ts = NOW()
WHERE slug = 'pro';

UPDATE ai.billing_plan SET
    alien_pool_idr_monthly = 2000000,
    frontier_pool_idr_monthly = 400000,
    updated_ts = NOW()
WHERE slug = 'ultra';

INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
    ('lite', 'IDR', 49000, 'yearly'),
    ('lite', 'IDR', 59000, 'monthly'),
    ('plus', 'IDR', 99000, 'yearly'),
    ('plus', 'IDR', 105000, 'monthly'),
    ('pro', 'IDR', 309000, 'yearly'),
    ('pro', 'IDR', 340000, 'monthly'),
    ('ultra', 'IDR', 1000000, 'yearly'),
    ('ultra', 'IDR', 1200000, 'monthly')
ON CONFLICT (plan_slug, currency, billing_period) DO UPDATE SET
    amount = EXCLUDED.amount,
    updated_ts = NOW();
