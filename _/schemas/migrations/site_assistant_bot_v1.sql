-- Site assistant bot link (Wave 2 site AI).
-- Choice: dedicated column on site.config (source of truth) with assistant_bot_iid
-- mirrored into capabilities_json for boot/editor clients until all readers use SiteConfig.assistant_bot_iid.

ALTER TABLE site.config
    ADD COLUMN IF NOT EXISTS assistant_bot_iid BIGINT NULL REFERENCES ai.identity(id);

CREATE INDEX IF NOT EXISTS idx_site_config_assistant_bot
    ON site.config (assistant_bot_iid)
    WHERE assistant_bot_iid IS NOT NULL AND deleted_ts IS NULL;
