-- Guest member portal: Alien user linked to a site (customer, not staff grant).
CREATE TABLE IF NOT EXISTS site.customer (
    site_iid        BIGINT NOT NULL REFERENCES ai.identity(id),
    user_iid        BIGINT NOT NULL REFERENCES ai.identity(id),
    contact_id      BIGINT NOT NULL DEFAULT 0,
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,
    PRIMARY KEY (site_iid, user_iid)
);

CREATE INDEX IF NOT EXISTS idx_site_customer_user
    ON site.customer (user_iid)
    WHERE deleted_ts IS NULL;
