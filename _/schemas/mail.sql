-- ==============================================================================
-- c35 — Platform mail schema (draft — Wave 4 M1)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: mail
--
-- Personal @alienai.id mailboxes + site mailboxes; CF zone onboard in mod_mail.
-- Apply after: identity.sql
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS mail;

-- ------------------------------------------------------------------------------
-- Registered sending/routing domains (CF zone)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS mail.domain (
    hostname                    VARCHAR(253) PRIMARY KEY,
    zone_id                     VARCHAR(64) NOT NULL DEFAULT '',
    sending_enabled             BOOLEAN NOT NULL DEFAULT FALSE,
    routing_enabled             BOOLEAN NOT NULL DEFAULT FALSE,
    setup_error                 TEXT NOT NULL DEFAULT '',

    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- Mailboxes (personal or site-bound)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS mail.mailbox (
    id                          BIGINT PRIMARY KEY,
    address                     VARCHAR(320) NOT NULL,
    kind                        VARCHAR(16) NOT NULL DEFAULT 'personal',
    owner_iid                   BIGINT REFERENCES ai.identity(id),
    site_iid                    BIGINT REFERENCES ai.identity(id),
    label                       VARCHAR(128) NOT NULL DEFAULT '',
    subscriber_limit            INT NOT NULL DEFAULT 0,

    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts                  TIMESTAMPTZ,

    CONSTRAINT chk_mail_mailbox_kind CHECK (kind IN ('personal', 'site')),
    CONSTRAINT uq_mail_mailbox_address UNIQUE (address)
);

CREATE INDEX IF NOT EXISTS idx_mail_mailbox_owner ON mail.mailbox (owner_iid)
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_mail_mailbox_site ON mail.mailbox (site_iid)
    WHERE deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Mailbox ACL (notify / shared access)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS mail.mailbox_member (
    mailbox_id                  BIGINT NOT NULL REFERENCES mail.mailbox(id),
    member_iid                  BIGINT NOT NULL REFERENCES ai.identity(id),
    access                      VARCHAR(16) NOT NULL DEFAULT 'read',

    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (mailbox_id, member_iid),
    CONSTRAINT chk_mail_member_access CHECK (access IN ('read', 'write'))
);

-- ------------------------------------------------------------------------------
-- Messages (inbound + outbound)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS mail.message (
    id                          BIGINT PRIMARY KEY,
    mailbox_id                  BIGINT NOT NULL REFERENCES mail.mailbox(id),
    direction                   VARCHAR(8) NOT NULL,
    from_addr                   VARCHAR(320) NOT NULL DEFAULT '',
    to_addr                     VARCHAR(320) NOT NULL DEFAULT '',
    subject                     VARCHAR(998) NOT NULL DEFAULT '',
    body_text                   TEXT NOT NULL DEFAULT '',
    body_html                     TEXT NOT NULL DEFAULT '',
    attachments_json            JSONB NOT NULL DEFAULT '[]',
    status                      VARCHAR(16) NOT NULL DEFAULT 'received',
    error                       TEXT NOT NULL DEFAULT '',
    is_archived                 BOOLEAN NOT NULL DEFAULT FALSE,
    read_ts                     TIMESTAMPTZ,
    external_id                 VARCHAR(256),

    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_ts                     TIMESTAMPTZ,

    CONSTRAINT chk_mail_message_direction CHECK (direction IN ('in', 'out')),
    CONSTRAINT chk_mail_message_status CHECK (
        status IN ('received', 'queued', 'sent', 'failed')
    )
);

CREATE INDEX IF NOT EXISTS idx_mail_message_mailbox_created
    ON mail.message (mailbox_id, created_ts DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_mail_message_external_id
    ON mail.message (external_id)
    WHERE external_id IS NOT NULL AND btrim(external_id) <> '';

-- ------------------------------------------------------------------------------
-- Broadcast groups (per mailbox)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS mail.group (
    group_id                    TEXT PRIMARY KEY,
    owner_iid                   BIGINT NOT NULL REFERENCES ai.identity(id),
    mailbox_id                  BIGINT NOT NULL REFERENCES mail.mailbox(id),
    name                        TEXT NOT NULL,
    description                 TEXT NOT NULL DEFAULT '',
    emails_json                 JSONB NOT NULL DEFAULT '[]'::jsonb,

    created_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mail_group_mailbox
    ON mail.group (mailbox_id, created_ts DESC);

-- ------------------------------------------------------------------------------
-- Seed: platform domain
-- ------------------------------------------------------------------------------

INSERT INTO mail.domain (hostname, zone_id, sending_enabled, routing_enabled)
VALUES ('alienai.id', '', TRUE, TRUE)
ON CONFLICT (hostname) DO NOTHING;
