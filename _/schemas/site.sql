-- ==============================================================================
-- c35 — Site schema (LOCKED 2026-09-21)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: site
--
-- Site registry + ACL stay in ai (identity, identity_grant).
-- All site payload lives here — doc, catalog, domains, compiled render.
-- Guest layout = block-composed SiteDoc in site.draft.doc_json (see _/docs/site.md).
-- Apply after: identity.sql
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS site;

-- ------------------------------------------------------------------------------
-- Site config (1:1 with identity.kind=site)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.config (
    site_iid                    BIGINT PRIMARY KEY REFERENCES ai.identity(id),
    owner_iid                   BIGINT NOT NULL REFERENCES ai.identity(id),

    published_version_id        VARCHAR(64),
    inventory_costing_method    VARCHAR(8) NOT NULL DEFAULT 'fifo',
    tz                          VARCHAR(64) NOT NULL DEFAULT 'Asia/Jakarta',

    payroll_policy_json         JSONB NOT NULL DEFAULT '{}',
    presence_policy_json        JSONB NOT NULL DEFAULT '{}',
    capabilities_json           JSONB NOT NULL DEFAULT '{}',    -- commerce, booking, queue, …

    alien_id_changed_ts         TIMESTAMPTZ,

    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts                  TIMESTAMPTZ,

    CONSTRAINT chk_site_config_costing CHECK (
        inventory_costing_method IN ('fifo', 'lifo')
    )
);

CREATE INDEX IF NOT EXISTS idx_site_config_owner_sync
    ON site.config (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Custom domains (CNAME → alienai.id; TLS status only — certs in CF / cert-manager)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.domain (
    id                  BIGINT PRIMARY KEY,
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    hostname            VARCHAR(253) NOT NULL,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    verify_token        VARCHAR(64) NOT NULL DEFAULT '',
    verified_ts         TIMESTAMPTZ,
    tls_status          VARCHAR(32) NOT NULL DEFAULT 'pending',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_site_domain_hostname
    ON site.domain (LOWER(hostname))
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_site_domain_site
    ON site.domain (site_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Draft — block-composed SiteDoc (presentation only; data in site.product, …)
-- doc_json shape: { pages[], theme{}, meta{} }
-- Primary editor: Home prompt (@site / site name). UITable optional (Phase 8b).
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.draft (
    site_iid            BIGINT PRIMARY KEY REFERENCES ai.identity(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    doc_json            JSONB NOT NULL DEFAULT '{"pages":[],"theme":{},"meta":{}}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_site_draft_owner_sync
    ON site.draft (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Published snapshots (immutable guest read)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.publish (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    version_id          VARCHAR(64) NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    doc_json            JSONB NOT NULL DEFAULT '{"pages":[],"theme":{},"meta":{}}',
    render_hash         VARCHAR(64) NOT NULL DEFAULT '',      -- blake3 of static bundle (CAS later)

    published_ts        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active           BOOLEAN NOT NULL DEFAULT FALSE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, version_id)
);

CREATE INDEX IF NOT EXISTS idx_site_publish_site_active
    ON site.publish (site_iid, is_active, published_ts DESC)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Compiled guest HTML (server-side render output — CF-cacheable)
-- render_key examples: html:/, html:/posts/{id}
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.render (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    render_key          TEXT NOT NULL,
    content_type        TEXT NOT NULL DEFAULT 'text/html; charset=utf-8',
    body                BYTEA,
    etag                VARCHAR(64) NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (site_iid, render_key)
);

CREATE INDEX IF NOT EXISTS idx_site_render_site
    ON site.render (site_iid, updated_ts DESC);

-- ------------------------------------------------------------------------------
-- Product catalog (data — referenced by product_grid blocks + POS)
-- PK (site_iid, product_id) — id.alienai shape
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.product (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    product_id          BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    type                SMALLINT NOT NULL DEFAULT 0,
    name                TEXT NOT NULL DEFAULT '',
    "desc"              TEXT NOT NULL DEFAULT '',
    unit                TEXT NOT NULL DEFAULT '',
    sku                 TEXT NOT NULL DEFAULT '',
    rev                 BIGINT NOT NULL DEFAULT 0,

    can_sell            BOOLEAN NOT NULL DEFAULT FALSE,
    can_reserve         BOOLEAN NOT NULL DEFAULT FALSE,
    can_produce         BOOLEAN NOT NULL DEFAULT FALSE,
    recommended_guest   BOOLEAN NOT NULL DEFAULT FALSE,
    track_stock         BOOLEAN NOT NULL DEFAULT FALSE,
    stock_qty           INT NOT NULL DEFAULT 0,

    price               BIGINT NOT NULL DEFAULT 0,
    cost_price          BIGINT NOT NULL DEFAULT 0,
    pic                 TEXT NOT NULL DEFAULT '',
    category            TEXT NOT NULL DEFAULT '',
    obj_id              BIGINT NOT NULL DEFAULT 0,              -- references ai.object_normalizer(id)
    product_json        JSONB NOT NULL DEFAULT '{}',
    search_text         TEXT NOT NULL DEFAULT '',
    sort_order          INT NOT NULL DEFAULT 0,
    is_archived         BOOLEAN NOT NULL DEFAULT FALSE,

    ehash_search        VARCHAR(64) NOT NULL DEFAULT '',
    embed_model         VARCHAR(64) NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, product_id)
);

CREATE INDEX IF NOT EXISTS idx_site_product_site_sync
    ON site.product (site_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_site_product_site_sell
    ON site.product (site_iid, product_id)
    WHERE can_sell = TRUE AND is_archived = FALSE AND deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_site_product_search
    ON site.product USING gin (to_tsvector('simple', search_text))
    WHERE is_archived = FALSE AND deleted_ts IS NULL;

CREATE TABLE IF NOT EXISTS site.product_embed (
    site_iid            BIGINT NOT NULL,
    embed_id            BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    label               TEXT NOT NULL DEFAULT '',
    ehash_search        VARCHAR(64) NOT NULL DEFAULT '',
    embed_model         VARCHAR(64) NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, embed_id),
    FOREIGN KEY (site_iid, product_id) REFERENCES site.product (site_iid, product_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_site_product_embed_product
    ON site.product_embed (site_iid, product_id)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Contact (CRM / tx subject)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.contact (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    contact_id          BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    name                TEXT NOT NULL DEFAULT '',
    phone               TEXT NOT NULL DEFAULT '',
    email               TEXT NOT NULL DEFAULT '',
    address             TEXT NOT NULL DEFAULT '',
    note                TEXT NOT NULL DEFAULT '',
    meta_json           JSONB NOT NULL DEFAULT '{}',
    is_archived         BOOLEAN NOT NULL DEFAULT FALSE,

    ehash_search        VARCHAR(64) NOT NULL DEFAULT '',
    embed_model         VARCHAR(64) NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, contact_id)
);

CREATE INDEX IF NOT EXISTS idx_site_contact_site_sync
    ON site.contact (site_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_site_contact_site_name
    ON site.contact (site_iid, name)
    WHERE deleted_ts IS NULL AND is_archived = FALSE;

-- ------------------------------------------------------------------------------
-- Object (table, room, unit)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.object (
    id                  BIGINT PRIMARY KEY,
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    client_id           TEXT NOT NULL DEFAULT '',
    name                TEXT NOT NULL DEFAULT '',
    code                TEXT NOT NULL DEFAULT '',
    kind                TEXT NOT NULL DEFAULT '',
    product_id          BIGINT,
    can_order           BOOLEAN NOT NULL DEFAULT TRUE,
    can_be_reserved     BOOLEAN NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order          INT NOT NULL DEFAULT 0,
    "desc"              TEXT NOT NULL DEFAULT '',
    pic                 TEXT NOT NULL DEFAULT '',
    meta_json           JSONB NOT NULL DEFAULT '{}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_site_object_site
    ON site.object (site_iid, updated_ts);
CREATE UNIQUE INDEX IF NOT EXISTS uq_site_object_site_client
    ON site.object (site_iid, client_id)
    WHERE client_id <> '' AND deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Parent hub → child tenant link
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.parent_link (
    parent_site_iid     BIGINT NOT NULL REFERENCES ai.identity(id),
    child_site_iid      BIGINT NOT NULL REFERENCES ai.identity(id),
    status              VARCHAR(16) NOT NULL DEFAULT 'active',
    display_name        TEXT NOT NULL DEFAULT '',
    sort_order          INT NOT NULL DEFAULT 0,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (parent_site_iid, child_site_iid),
    CONSTRAINT chk_site_parent_link_distinct CHECK (parent_site_iid <> child_site_iid),
    CONSTRAINT chk_site_parent_link_status CHECK (status IN ('active', 'pending'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_site_parent_link_child
    ON site.parent_link (child_site_iid)
    WHERE deleted_ts IS NULL;
