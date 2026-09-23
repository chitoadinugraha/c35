-- ==============================================================================
-- c35 — Home hint catalog, per-user asset touch, precompiled hint bundles
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

-- Platform catalog (consumption, expense, …)
CREATE TABLE IF NOT EXISTS ai.hint (
    id              TEXT PRIMARY KEY,
    scope           TEXT NOT NULL DEFAULT 'role:personal_assistant',
    label_key       TEXT NOT NULL,
    icon            TEXT NOT NULL DEFAULT '',
    action          TEXT NOT NULL DEFAULT 'send_text',
    send_text_key   TEXT NOT NULL DEFAULT '',
    inst_id         TEXT NOT NULL DEFAULT '',
    sort            INT NOT NULL DEFAULT 0,
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_hint_sync
    ON ai.hint (updated_ts)
    WHERE deleted_ts IS NULL;

-- Per-user recent asset access (site, device, …)
CREATE TABLE IF NOT EXISTS ai.user_asset_touch (
    user_iid            BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    asset_iid           BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    asset_kind          TEXT NOT NULL,
    last_accessed_ts    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,
    PRIMARY KEY (user_iid, asset_iid)
);

CREATE INDEX IF NOT EXISTS idx_user_asset_touch_recent
    ON ai.user_asset_touch (user_iid, last_accessed_ts DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_user_asset_touch_asset
    ON ai.user_asset_touch (asset_iid)
    WHERE deleted_ts IS NULL;

-- Materialized HintCatalog protobuf per user (one row; compiled_locale for staleness)
CREATE TABLE IF NOT EXISTS ai.hint_bundle (
    user_iid            BIGINT PRIMARY KEY REFERENCES ai.identity(id) ON DELETE CASCADE,
    updated_ts_ms       BIGINT NOT NULL DEFAULT 0,
    compiled_locale     VARCHAR(16) NOT NULL DEFAULT 'en',
    body                BYTEA NOT NULL DEFAULT ''::bytea,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seeds
INSERT INTO ai.hint (id, scope, label_key, icon, action, send_text_key, inst_id, sort) VALUES
(
    'hint.consumption_add',
    'role:personal_assistant',
    'hint.consumption_add.label',
    'mdi:restaurant',
    'pick_image',
    'hint.consumption_add.send_text',
    'inst.consumption_add',
    10
),
(
    'hint.expense_add',
    'role:personal_assistant',
    'hint.expense_add.label',
    'mdi:receipt',
    'send_text',
    'hint.expense_add.send_text',
    '',
    20
)
ON CONFLICT (id) DO NOTHING;
