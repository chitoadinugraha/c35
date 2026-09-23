-- ==============================================================================
-- c35 — Skill schema (LOCKED 2026-09-20)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: ai
--
-- Port: cs_agent skill + catalog; scope uses device_iid (not space_id).
-- Sync: owner-scoped rows with created_ts, updated_ts, deleted_ts.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

-- ------------------------------------------------------------------------------
-- Skill (taught / imported / catalog-linked)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.skill (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    scope               VARCHAR(16) NOT NULL DEFAULT 'user',   -- user | device | team | global
    device_iid          BIGINT NOT NULL DEFAULT 0,               -- when scope=device
    team_iid            BIGINT NOT NULL DEFAULT 0,               -- when scope=team

    title               VARCHAR(256) NOT NULL DEFAULT '',
    hash_blake3         VARCHAR(64) NOT NULL DEFAULT '',
    body_md             TEXT NOT NULL DEFAULT '',

    source              VARCHAR(32) NOT NULL DEFAULT 'taught',   -- taught | ai_explore | catalog | import
    catalog_id          BIGINT NOT NULL DEFAULT 0,
    catalog_variant_id  BIGINT NOT NULL DEFAULT 0,
    catalog_release_id  BIGINT NOT NULL DEFAULT 0,
    author_name         VARCHAR(128) NOT NULL DEFAULT '',

    tags_json           JSONB NOT NULL DEFAULT '[]',
    phrases_json        JSONB NOT NULL DEFAULT '[]',
    auto_run            BOOLEAN NOT NULL DEFAULT TRUE,
    surface             VARCHAR(32) NOT NULL DEFAULT '',
    target_app          VARCHAR(64) NOT NULL DEFAULT '',
    url_pattern         TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_skill_scope CHECK (
        scope IN ('user', 'device', 'team', 'global')
    )
);

CREATE INDEX IF NOT EXISTS idx_skill_owner_sync
    ON ai.skill (owner_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_skill_device_sync
    ON ai.skill (device_iid, updated_ts)
    WHERE device_iid <> 0;
CREATE INDEX IF NOT EXISTS idx_skill_scope
    ON ai.skill (owner_iid, scope, updated_ts);

-- ------------------------------------------------------------------------------
-- Skill step (UI automation tape)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.skill_step (
    id                  BIGINT PRIMARY KEY,
    skill_id            BIGINT NOT NULL REFERENCES ai.skill(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    ord                 INT NOT NULL DEFAULT 0,
    kind                VARCHAR(32) NOT NULL DEFAULT 'click',
    label               VARCHAR(512) NOT NULL DEFAULT '',
    ax_target_json      JSONB NOT NULL DEFAULT '{}',
    screenshot_hash     VARCHAR(64) NOT NULL DEFAULT '',
    comment             TEXT NOT NULL DEFAULT '',
    secret_id           BIGINT,
    tape_local_only_json JSONB NOT NULL DEFAULT '{}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_skill_step_skill
    ON ai.skill_step (skill_id, ord);
CREATE INDEX IF NOT EXISTS idx_skill_step_sync
    ON ai.skill_step (skill_id, updated_ts);

-- ------------------------------------------------------------------------------
-- Secret (encrypted credentials referenced by skill steps)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.skill_secret (
    id                  BIGINT PRIMARY KEY,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    label               VARCHAR(128) NOT NULL DEFAULT '',
    ciphertext          BYTEA NOT NULL,
    nonce               BYTEA NOT NULL,
    key_version         SMALLINT NOT NULL DEFAULT 1,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_skill_secret_owner
    ON ai.skill_secret (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Skill catalog (marketplace registry — server-wide, not owner-synced)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.skill_catalog (
    id                  BIGINT PRIMARY KEY,
    author_iid          BIGINT NOT NULL REFERENCES ai.identity(id),
    author_name         VARCHAR(128) NOT NULL DEFAULT '',
    slug                VARCHAR(128) NOT NULL,
    title               VARCHAR(256) NOT NULL,
    summary             TEXT NOT NULL DEFAULT '',
    body_md             TEXT NOT NULL DEFAULT '',
    steps_json          JSONB NOT NULL DEFAULT '[]',
    required_tools_json JSONB NOT NULL DEFAULT '[]',
    tags_json           JSONB NOT NULL DEFAULT '[]',
    source              VARCHAR(32) NOT NULL DEFAULT 'community',
    source_url          TEXT NOT NULL DEFAULT '',
    install_count       INT NOT NULL DEFAULT 0,
    rating              NUMERIC(3, 2) NOT NULL DEFAULT 5.0,
    is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
    status              VARCHAR(16) NOT NULL DEFAULT 'published',
    default_variant_key VARCHAR(64) NOT NULL DEFAULT 'default',
    price_usd           NUMERIC(12, 4) NOT NULL DEFAULT 0,
    price_idr           NUMERIC(14, 2) NOT NULL DEFAULT 0,
    billing_period      VARCHAR(16) NOT NULL DEFAULT 'free',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_skill_catalog_slug
    ON ai.skill_catalog (LOWER(slug))
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_skill_catalog_installs
    ON ai.skill_catalog (install_count DESC)
    WHERE deleted_ts IS NULL;

CREATE TABLE IF NOT EXISTS ai.skill_catalog_variant (
    id                  BIGINT PRIMARY KEY,
    catalog_id          BIGINT NOT NULL REFERENCES ai.skill_catalog(id),
    variant_key         VARCHAR(64) NOT NULL,
    platform            VARCHAR(32) NOT NULL DEFAULT 'any',
    surface             VARCHAR(32) NOT NULL DEFAULT 'any',
    target_app          VARCHAR(64) NOT NULL DEFAULT '',
    url_pattern         TEXT NOT NULL DEFAULT '',
    phrases_json        JSONB NOT NULL DEFAULT '[]',
    required_tools_json JSONB NOT NULL DEFAULT '[]',
    priority            INT NOT NULL DEFAULT 0,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT uq_skill_catalog_variant UNIQUE (catalog_id, variant_key)
);

CREATE INDEX IF NOT EXISTS idx_skill_catalog_variant_catalog
    ON ai.skill_catalog_variant (catalog_id, priority DESC);

CREATE TABLE IF NOT EXISTS ai.skill_catalog_release (
    id                  BIGINT PRIMARY KEY,
    variant_id          BIGINT NOT NULL REFERENCES ai.skill_catalog_variant(id),
    semver              VARCHAR(32) NOT NULL DEFAULT '1.0.0',
    min_agent_build     INT NOT NULL DEFAULT 0,
    max_agent_build     INT NOT NULL DEFAULT 0,
    body_md             TEXT NOT NULL DEFAULT '',
    hash_blake3         VARCHAR(64) NOT NULL DEFAULT '',
    changelog           TEXT NOT NULL DEFAULT '',
    is_current          BOOLEAN NOT NULL DEFAULT TRUE,
    published_ts        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_skill_catalog_release_variant
    ON ai.skill_catalog_release (variant_id, is_current)
    WHERE deleted_ts IS NULL;

CREATE TABLE IF NOT EXISTS ai.skill_catalog_rating (
    catalog_id          BIGINT NOT NULL REFERENCES ai.skill_catalog(id),
    rater_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    stars               SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (catalog_id, rater_iid)
);

-- ==============================================================================
-- Phase 7: Self-Learning Skill System + Alien AI Public Skill Library
-- ==============================================================================

-- Self-learning circuit breaker fields
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS patch_epoch          INT NOT NULL DEFAULT 0;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS patch_count          INT NOT NULL DEFAULT 0;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS last_patched_ts      TIMESTAMPTZ;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS consecutive_ok       INT NOT NULL DEFAULT 0;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS detected_app_version VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS auto_submit          BOOLEAN NOT NULL DEFAULT FALSE;
-- auto_submit default: TRUE for source='ai_explore', FALSE for source='taught'|'catalog'|'import'

-- Version range for catalog variants
ALTER TABLE ai.skill_catalog_variant
    ADD COLUMN IF NOT EXISTS target_app_version_min VARCHAR(32) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS target_app_version_max VARCHAR(32) NOT NULL DEFAULT '';

-- Success metrics for ranking
ALTER TABLE ai.skill_catalog_release
    ADD COLUMN IF NOT EXISTS success_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fail_count    INT NOT NULL DEFAULT 0;

-- Contributor tracking + pending_review state for Alien AI Public Skill Library
ALTER TABLE ai.skill_catalog
    ADD COLUMN IF NOT EXISTS contributor_iids_json JSONB NOT NULL DEFAULT '[]';
-- status column already exists as VARCHAR(16); extend allowed values to include 'pending_review' | 'rejected'
-- No constraint change needed as there is no CHECK on status currently

CREATE INDEX IF NOT EXISTS idx_skill_auto_submit
    ON ai.skill (owner_iid, consecutive_ok, auto_submit)
    WHERE deleted_ts IS NULL AND auto_submit = TRUE;

-- Self-learning source values:
--   taught     = manually recorded by user in teach mode
--   ai_explore = AI explored first-time and auto-recorded (auto_submit defaults TRUE)
--   catalog    = installed from Alien AI Public Skill Library
--   import     = imported from file

