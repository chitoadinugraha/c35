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
    verify_error        VARCHAR(512) NOT NULL DEFAULT '',
    tls_error           TEXT NOT NULL DEFAULT '',
    last_verify_ts      TIMESTAMPTZ,

    source              VARCHAR(16) NOT NULL DEFAULT 'byo', -- byo | bought
    mail_status         VARCHAR(16) NOT NULL DEFAULT '', -- empty | pending | ready | failed
    mail_error          TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_site_domain_source CHECK (source IN ('byo', 'bought'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_site_domain_hostname
    ON site.domain (LOWER(hostname))
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_site_domain_site
    ON site.domain (site_iid, updated_ts);

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

-- Domain registrar purchase (charged wallet, then CF register).
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
    -- CSA parity: reservable products use can_reserve (not is_reservable).
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

-- Global product-name → default Iconify id. Shared across sites.
-- name_key is product_icon_name_key(name). icon is an id from the Rust kind catalog.
CREATE TABLE IF NOT EXISTS site.product_icon (
    name_key    TEXT PRIMARY KEY,
    icon        TEXT NOT NULL,
    kind        TEXT NOT NULL,
    source      TEXT NOT NULL,          -- rule | llm
    model       TEXT NOT NULL DEFAULT '',
    created_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
-- Hub links (social / outbound URLs — source of truth for guest links hub)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.link (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    link_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    sort_order          INT NOT NULL DEFAULT 0,
    label               TEXT NOT NULL DEFAULT '',
    url                 TEXT NOT NULL DEFAULT '',
    icon                TEXT NOT NULL DEFAULT '',
    is_pinned           BOOLEAN NOT NULL DEFAULT FALSE,
    active              BOOLEAN NOT NULL DEFAULT TRUE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, link_id)
);

CREATE INDEX IF NOT EXISTS idx_site_link_site_sync
    ON site.link (site_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_site_link_site_order
    ON site.link (site_iid, sort_order, link_id)
    WHERE deleted_ts IS NULL AND active = TRUE;

-- ------------------------------------------------------------------------------
-- Social / storefront posts (hub feed source of truth)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.post (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    post_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    sort_order          INT NOT NULL DEFAULT 0,
    title               TEXT NOT NULL DEFAULT '',
    caption             TEXT NOT NULL DEFAULT '',
    body                TEXT NOT NULL DEFAULT '',
    media_json          JSONB NOT NULL DEFAULT '[]',
    on_storefront       BOOLEAN NOT NULL DEFAULT TRUE,
    thumb               TEXT NOT NULL DEFAULT '',
    feed_kind           TEXT NOT NULL DEFAULT 'post',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, post_id)
);

CREATE INDEX IF NOT EXISTS idx_site_post_site_sync
    ON site.post (site_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_site_post_site_storefront
    ON site.post (site_iid, sort_order, post_id)
    WHERE deleted_ts IS NULL AND on_storefront = TRUE;

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

-- ------------------------------------------------------------------------------
-- Queue (guest antrian — CSA parity minimal)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.queue (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    queue_id            BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    name                TEXT NOT NULL DEFAULT '',
    mode                VARCHAR(32) NOT NULL DEFAULT 'fifo',
    prefix              VARCHAR(16) NOT NULL DEFAULT '',
    last_ticket_no      INT NOT NULL DEFAULT 0,
    serving_ticket_no   INT NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    meta_json           JSONB NOT NULL DEFAULT '{}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, queue_id)
);

CREATE INDEX IF NOT EXISTS idx_site_queue_site_sync
    ON site.queue (site_iid, updated_ts)
    WHERE deleted_ts IS NULL;

CREATE TABLE IF NOT EXISTS site.queue_ticket (
    site_iid            BIGINT NOT NULL,
    ticket_id           BIGINT NOT NULL,
    queue_id            BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    ticket_no           INT NOT NULL DEFAULT 0,
    guest_name          TEXT NOT NULL DEFAULT '',
    guest_phone         TEXT NOT NULL DEFAULT '',
    status              VARCHAR(16) NOT NULL DEFAULT 'waiting',
    meta_json           JSONB NOT NULL DEFAULT '{}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, ticket_id),
    FOREIGN KEY (site_iid, queue_id) REFERENCES site.queue (site_iid, queue_id)
);

CREATE INDEX IF NOT EXISTS idx_site_queue_ticket_queue
    ON site.queue_ticket (site_iid, queue_id, ticket_no DESC)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- HR — work shifts, geo presence, face enrollment (CSA parity; ACL stays in ai.identity_grant)
-- Attendance events / payroll → later modules. No site_member table.
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.work_shift (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    shift_id            TEXT NOT NULL,
    name                TEXT NOT NULL DEFAULT '',
    attendance_method   VARCHAR(32) NOT NULL DEFAULT 'button',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order          INT NOT NULL DEFAULT 0,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, shift_id),
    CONSTRAINT chk_site_work_shift_id_nonempty CHECK (btrim(shift_id) <> ''),
    CONSTRAINT chk_site_work_shift_attendance_method CHECK (
        attendance_method IN ('button', 'gps', 'gps_selfie', 'gps_selfie_face', 'cctv_walkby')
    )
);

CREATE INDEX IF NOT EXISTS idx_site_work_shift_site_active
    ON site.work_shift (site_iid, sort_order)
    WHERE deleted_ts IS NULL AND is_active = TRUE;

CREATE TABLE IF NOT EXISTS site.work_shift_slot (
    site_iid            BIGINT NOT NULL,
    shift_id            TEXT NOT NULL,
    slot_id             TEXT NOT NULL,
    start_day           INT NOT NULL,
    start_min           INT NOT NULL,
    end_day             INT NOT NULL,
    end_min             INT NOT NULL,

    PRIMARY KEY (site_iid, shift_id, slot_id),
    FOREIGN KEY (site_iid, shift_id) REFERENCES site.work_shift (site_iid, shift_id) ON DELETE CASCADE,
    CONSTRAINT chk_site_work_shift_slot_id_nonempty CHECK (btrim(slot_id) <> ''),
    CONSTRAINT chk_site_work_shift_slot_start_day CHECK (start_day BETWEEN 0 AND 6),
    CONSTRAINT chk_site_work_shift_slot_start_min CHECK (start_min BETWEEN 0 AND 1439),
    CONSTRAINT chk_site_work_shift_slot_end_day CHECK (end_day BETWEEN 0 AND 6),
    CONSTRAINT chk_site_work_shift_slot_end_min CHECK (end_min BETWEEN 0 AND 1439)
);

-- Member-shift assignment (grantee is logical identity; no FK to identity_grant / site_member)
CREATE TABLE IF NOT EXISTS site.member_shift (
    site_iid            BIGINT NOT NULL,
    grantee_iid         BIGINT NOT NULL REFERENCES ai.identity(id),
    shift_id            TEXT NOT NULL,

    PRIMARY KEY (site_iid, grantee_iid, shift_id),
    FOREIGN KEY (site_iid, shift_id) REFERENCES site.work_shift (site_iid, shift_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_site_member_shift_grantee
    ON site.member_shift (site_iid, grantee_iid);

CREATE TABLE IF NOT EXISTS site.presence_location (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    location_id         TEXT NOT NULL,
    name                TEXT NOT NULL DEFAULT '',
    polygon             JSONB NOT NULL DEFAULT '[]',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order          INT NOT NULL DEFAULT 0,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, location_id),
    CONSTRAINT chk_site_presence_location_id_nonempty CHECK (btrim(location_id) <> '')
);

CREATE INDEX IF NOT EXISTS idx_site_presence_location_site_active
    ON site.presence_location (site_iid, sort_order)
    WHERE deleted_ts IS NULL AND is_active = TRUE;

-- Face enrollment photos (file hash via ai.file CAS). Empty embedding allowed until FaceNet ships.
CREATE TABLE IF NOT EXISTS site.member_face (
    face_id             BIGINT PRIMARY KEY,
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    grantee_iid         BIGINT NOT NULL REFERENCES ai.identity(id),
    file_hash           TEXT NOT NULL,
    embedding           REAL[] NOT NULL DEFAULT '{}',
    model_version       TEXT NOT NULL DEFAULT 'none',
    pose                TEXT NOT NULL DEFAULT '',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order          INT NOT NULL DEFAULT 0,
    created_by_iid      BIGINT REFERENCES ai.identity(id),

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_site_member_face_grantee_active
    ON site.member_face (site_iid, grantee_iid, sort_order)
    WHERE deleted_ts IS NULL AND is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_site_member_face_site_active
    ON site.member_face (site_iid)
    WHERE deleted_ts IS NULL AND is_active = TRUE;
