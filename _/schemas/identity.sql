-- ==============================================================================
-- c35 — Identity schema (LOCKED 2026-09-20)
-- Database: c35 (YugabyteDB YSQL / PostgreSQL 14+ compatible)
-- Schema: ai
--
-- Rules:
--   - Every actor is one row: user | team | bot | remote | iot | site
--   - Subtypes via `type` column (NOT compound kind like remote-windows)
--   - handle renamed to alien_id
--   - org/group renamed to team
--   - All syncable tables use created_ts, updated_ts, deleted_ts
--   - bot type=chat; multiple channels (telegram, whatsapp, …) in meta.channels[]
--   - All access (team membership, site staff, bot/iot share) → ai.identity_grant only
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

-- ------------------------------------------------------------------------------
-- Identity
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.identity (
    id              BIGINT PRIMARY KEY,                         -- snowflake iid
    kind            VARCHAR(16) NOT NULL,                       -- user | team | bot | remote | iot | site
    type            VARCHAR(32) NOT NULL DEFAULT '',            -- windows | android | chat | switch | business | …
    alien_id        VARCHAR(64),                                -- globally unique slug (was handle)
    name            VARCHAR(128) NOT NULL,
    pic             TEXT,

    owner_iid       BIGINT REFERENCES ai.identity(id),          -- user/team that owns this row
    referred_by_iid BIGINT REFERENCES ai.identity(id),          -- referral upline (users)

    locale          VARCHAR(16) NOT NULL DEFAULT 'en_US',
    tz              VARCHAR(64) NOT NULL DEFAULT 'UTC',
    billing_iid     BIGINT REFERENCES ai.identity(id),          -- LEGACY: wallet owner (use billing_profile_iid)
    billing_profile_iid BIGINT,                                 -- billing_profile.id (v2)

    meta            JSONB NOT NULL DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    CONSTRAINT chk_identity_kind CHECK (
        kind IN ('user', 'team', 'bot', 'remote', 'iot', 'site')
    )
);

-- Self-ownership convention: user/team rows should have owner_iid = id (enforced in app on insert)

CREATE UNIQUE INDEX IF NOT EXISTS idx_identity_alien_id
    ON ai.identity (LOWER(alien_id))
    WHERE alien_id IS NOT NULL AND alien_id <> '';

CREATE INDEX IF NOT EXISTS idx_identity_kind_type
    ON ai.identity (kind, type)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_identity_owner_kind
    ON ai.identity (owner_iid, kind, updated_ts)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_identity_sync
    ON ai.identity (id, updated_ts);

CREATE INDEX IF NOT EXISTS idx_identity_referred
    ON ai.identity (referred_by_iid, created_ts DESC)
    WHERE kind = 'user' AND deleted_ts IS NULL;

-- Optional generated label: remote/windows, iot/switch
-- ALTER TABLE ai.identity ADD COLUMN IF NOT EXISTS kind_type TEXT
--   GENERATED ALWAYS AS (kind || COALESCE('/' || NULLIF(type, ''), '')) STORED;

-- ------------------------------------------------------------------------------
-- Access grants (team membership, site staff, bot/remote/iot/site share)
-- One table for all RBAC — replaces team_member, asset_grant, site_member
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.identity_grant (
    id              BIGINT PRIMARY KEY,
    resource_iid    BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    grantee_iid     BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,

    role            VARCHAR(16) NOT NULL DEFAULT 'member',
    permissions     TEXT[] NOT NULL DEFAULT '{}',               -- fine-grained, e.g. gate:open
    is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,

    meta            JSONB NOT NULL DEFAULT '{}',                -- role_tags, compensations, …

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    CONSTRAINT uq_identity_grant UNIQUE (resource_iid, grantee_iid)
);

-- "What can this user access?"
CREATE INDEX IF NOT EXISTS idx_identity_grant_grantee
    ON ai.identity_grant (grantee_iid, updated_ts)
    WHERE deleted_ts IS NULL;

-- "Who can access this resource?"
CREATE INDEX IF NOT EXISTS idx_identity_grant_resource
    ON ai.identity_grant (resource_iid, updated_ts)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_identity_grant_pinned
    ON ai.identity_grant (grantee_iid, is_pinned)
    WHERE deleted_ts IS NULL AND is_pinned = TRUE;

-- role by resource kind (validated in app):
--   resource kind=team  → owner | admin | member
--   resource kind=site  → owner | manage | staff | guest
--   resource kind=bot|remote|iot → admin | member | readonly

-- ------------------------------------------------------------------------------
-- Auth providers (email, phone, password, OAuth, API keys)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.identity_provider (
    id              BIGINT PRIMARY KEY,
    identity_iid    BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,

    kind            VARCHAR(32) NOT NULL,                       -- email | phone | password | google | api_key | …
    identifier      VARCHAR(255) NOT NULL,
    secret_hash     VARCHAR(255),

    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at     TIMESTAMPTZ,

    meta            JSONB NOT NULL DEFAULT '{}',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    CONSTRAINT uq_identity_provider UNIQUE (kind, identifier)
);

CREATE INDEX IF NOT EXISTS idx_idp_lookup
    ON ai.identity_provider (kind, LOWER(identifier));

CREATE INDEX IF NOT EXISTS idx_idp_identity
    ON ai.identity_provider (identity_iid, is_primary);

CREATE UNIQUE INDEX IF NOT EXISTS uq_idp_email
    ON ai.identity_provider (LOWER(identifier))
    WHERE kind = 'email' AND identifier <> '';

-- ------------------------------------------------------------------------------
-- Session PIN + single-active-client lock
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.identity_pin (
    identity_iid    BIGINT PRIMARY KEY REFERENCES ai.identity(id) ON DELETE CASCADE,
    pin_hash        VARCHAR(255) NOT NULL,
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai.identity_session_lock (
    identity_iid    BIGINT PRIMARY KEY REFERENCES ai.identity(id) ON DELETE CASCADE,
    active_dv       TEXT NOT NULL DEFAULT '',
    active_client_id TEXT NOT NULL DEFAULT '',
    unlock_mode     VARCHAR(32) NOT NULL DEFAULT 'tap',
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- Client installs (Flutter app, remote agent, IoT firmware)
-- dv = device id (DV), client_id = app install id
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.identity_client (
    identity_iid    BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    dv              TEXT NOT NULL,
    client_id       TEXT NOT NULL DEFAULT '',
    platform        INT NOT NULL DEFAULT 0,
    label_user      TEXT NOT NULL DEFAULT '',
    label_auto      TEXT NOT NULL DEFAULT '',
    os_name         TEXT NOT NULL DEFAULT '',
    session_hash    VARCHAR(64) NOT NULL DEFAULT '',
    app_build       BIGINT NOT NULL DEFAULT 0,
    app_version_name TEXT NOT NULL DEFAULT '',
    last_ws_ts_ms   BIGINT NOT NULL DEFAULT 0,

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    PRIMARY KEY (identity_iid, dv)
);

CREATE INDEX IF NOT EXISTS idx_identity_client_sync
    ON ai.identity_client (identity_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Auth sessions
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.auth_session (
    id              BIGINT PRIMARY KEY,
    identity_iid    BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    token_hash      VARCHAR(64) NOT NULL UNIQUE,
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    expires_at      TIMESTAMPTZ NOT NULL,

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auth_session_token
    ON ai.auth_session (token_hash, expires_at);

-- Billing wallet stub moved to billing.sql — apply after identity.sql
-- ------------------------------------------------------------------------------
-- Referral (port behavior from cs_agent)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.referral_code (
    code            VARCHAR(64) PRIMARY KEY,
    issued_by_iid   BIGINT NOT NULL REFERENCES ai.identity(id),
    used_count      INT NOT NULL DEFAULT 0,
    expires_at      TIMESTAMPTZ,
    meta            JSONB NOT NULL DEFAULT '{}',

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ai.referral_code ADD COLUMN IF NOT EXISTS meta JSONB NOT NULL DEFAULT '{}';

CREATE TABLE IF NOT EXISTS ai.referral_share (
    parent_iid      BIGINT NOT NULL REFERENCES ai.identity(id),
    child_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    share_percent   NUMERIC(5, 2) NOT NULL DEFAULT 0,

    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (parent_iid, child_iid)
);

-- ------------------------------------------------------------------------------
-- Seed: automated tester (agents, MCP prompt/tool tests, integration tests)
-- Fixed iid 33000 — do not reassign. "uid 33000" in docs means this owner_iid.
-- ------------------------------------------------------------------------------

INSERT INTO ai.identity (
    id, kind, type, alien_id, name, owner_iid, locale, tz, meta, is_active, created_ts, updated_ts
) VALUES (
    33000,
    'user',
    '',
    'automated-tester',
    'Alien AI Automated Tester',
    33000,
    'en_US',
    'Asia/Jakarta',
    '{"global_roles":["tester"],"is_automated_tester":true}'::jsonb,
    TRUE,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    kind = EXCLUDED.kind,
    type = EXCLUDED.type,
    alien_id = EXCLUDED.alien_id,
    name = EXCLUDED.name,
    owner_iid = EXCLUDED.owner_iid,
    locale = EXCLUDED.locale,
    tz = EXCLUDED.tz,
    meta = EXCLUDED.meta,
    is_active = EXCLUDED.is_active,
    updated_ts = NOW(),
    deleted_ts = NULL;

-- ------------------------------------------------------------------------------
-- Seed: platform skill catalog author (marketplace seed rows)
-- Fixed iid 33001 — author_iid FK for ai.skill_catalog
-- ------------------------------------------------------------------------------

INSERT INTO ai.identity (
    id, kind, type, alien_id, name, owner_iid, locale, tz, meta, is_active, created_ts, updated_ts
) VALUES (
    33001,
    'bot',
    'catalog',
    'skill-catalog',
    'Alien Skill Catalog',
    33001,
    'en_US',
    'Asia/Jakarta',
    '{"is_platform_catalog":true}'::jsonb,
    TRUE,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    kind = EXCLUDED.kind,
    type = EXCLUDED.type,
    alien_id = EXCLUDED.alien_id,
    name = EXCLUDED.name,
    owner_iid = EXCLUDED.owner_iid,
    meta = EXCLUDED.meta,
    is_active = EXCLUDED.is_active,
    updated_ts = NOW(),
    deleted_ts = NULL;
