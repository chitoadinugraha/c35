-- ==============================================================================
-- c35 — Asset tags (generic tagging for chat, skill, …)
-- Apply after chat.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.asset_tag (
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    kind            VARCHAR(32) NOT NULL,
    asset_id        BIGINT NOT NULL,
    tag             VARCHAR(32) NOT NULL,

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    PRIMARY KEY (owner_iid, kind, asset_id, tag),
    CONSTRAINT chk_asset_tag_kind CHECK (kind <> ''),
    CONSTRAINT chk_asset_tag_tag CHECK (tag <> '')
);

CREATE INDEX IF NOT EXISTS idx_asset_tag_owner_kind_tag
    ON ai.asset_tag (owner_iid, kind, tag)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_asset_tag_asset
    ON ai.asset_tag (owner_iid, kind, asset_id)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_asset_tag_sync
    ON ai.asset_tag (owner_iid, updated_ts);

-- Migrate legacy single chat.tag column
INSERT INTO ai.asset_tag (owner_iid, kind, asset_id, tag)
SELECT c.owner_iid, 'chat', c.id, c.tag
FROM ai.chat c
WHERE c.tag <> '' AND c.deleted_ts IS NULL
ON CONFLICT (owner_iid, kind, asset_id, tag) DO NOTHING;
