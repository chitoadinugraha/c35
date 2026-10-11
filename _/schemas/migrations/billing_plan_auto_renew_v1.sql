-- Play subscription vs prepaid wallet: drives Renew at vs Expired at in app UI.
ALTER TABLE ai.billing_profile
    ADD COLUMN IF NOT EXISTS plan_auto_renew BOOLEAN NOT NULL DEFAULT FALSE;
