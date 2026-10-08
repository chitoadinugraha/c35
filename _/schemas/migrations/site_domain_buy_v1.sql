-- site.domain purchase source, mailbox status, and site.domain_order.
-- Safe to re-run. Does not drop existing rows.

ALTER TABLE site.domain
    ADD COLUMN IF NOT EXISTS source VARCHAR(16) NOT NULL DEFAULT 'byo',
    ADD COLUMN IF NOT EXISTS mail_status VARCHAR(16) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS mail_error TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_site_domain_source'
          AND conrelid = 'site.domain'::regclass
    ) THEN
        ALTER TABLE site.domain
            ADD CONSTRAINT chk_site_domain_source
            CHECK (source IN ('byo', 'bought'));
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS site.domain_order (
    id                  BIGINT PRIMARY KEY,
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    hostname            VARCHAR(253) NOT NULL,
    currency            CHAR(3) NOT NULL,
    amount              NUMERIC(18, 4) NOT NULL,
    status              VARCHAR(16) NOT NULL, -- charged | registered | refunded | failed
    cf_zone_id          VARCHAR(64) NOT NULL DEFAULT '',
    error               TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_site_domain_order_site
    ON site.domain_order (site_iid, created_ts DESC);
