-- site.domain DNS/TLS verify metadata (H3)
ALTER TABLE site.domain
    ADD COLUMN IF NOT EXISTS verify_error VARCHAR(512) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS tls_error TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS last_verify_ts TIMESTAMPTZ;
