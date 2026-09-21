-- ==============================================================================
-- c35 — Chat schema (LOCKED 2026-09-20)
-- Apply after identity.sql
--
-- Chat kinds:
--   prompt    — Home inbox: personal AI (user ↔ assistant) ONLY
--   direct    — DEFERRED: user ↔ user (schema reserved; NOT in Home inbox)
--   bot_peer  — Bots page: one external user on one bot channel
--
-- Inbox (Home): chat_member + kind=prompt only, sorted by last_msg_ts DESC
-- Stop (bot_peer only): chat.ai_reply_enabled — per conversation, NOT per bot/channel
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Chat threads
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.chat (
    id                  BIGINT PRIMARY KEY,
    kind                VARCHAR(16) NOT NULL,

    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),   -- sync/billing anchor
    title               VARCHAR(128) NOT NULL DEFAULT 'Chat',
    tag                 VARCHAR(64) NOT NULL DEFAULT '',
    model               VARCHAR(64) NOT NULL DEFAULT 'cloud',         -- prompt kind only

    -- bot_peer only
    bot_iid             BIGINT REFERENCES ai.identity(id),
    channel_id          TEXT NOT NULL DEFAULT '',
    peer_key            TEXT NOT NULL DEFAULT '',                       -- external platform user id
    peer_name           VARCHAR(128) NOT NULL DEFAULT '',
    peer_pic            TEXT,
    ai_reply_enabled    BOOLEAN NOT NULL DEFAULT TRUE,

    last_msg_ts         TIMESTAMPTZ NOT NULL DEFAULT NOW(),           -- inbox sort key (global thread)
    last_msg_preview    VARCHAR(255) NOT NULL DEFAULT '',

    meta                JSONB NOT NULL DEFAULT '{}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_chat_kind CHECK (kind IN ('prompt', 'direct', 'bot_peer')),
    CONSTRAINT chk_chat_bot_peer_fields CHECK (
        kind <> 'bot_peer'
        OR (bot_iid IS NOT NULL AND channel_id <> '' AND peer_key <> '')
    ),
    CONSTRAINT chk_chat_prompt_fields CHECK (
        kind <> 'prompt'
        OR (bot_iid IS NULL AND channel_id = '' AND peer_key = '')
    ),
    CONSTRAINT chk_chat_direct_fields CHECK (
        kind <> 'direct'
        OR (bot_iid IS NULL AND channel_id = '' AND peer_key = '')
    )
);

-- One thread per external peer per channel per bot
CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_bot_peer
    ON ai.chat (bot_iid, channel_id, peer_key)
    WHERE kind = 'bot_peer' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_owner_sync
    ON ai.chat (owner_iid, updated_ts);

CREATE INDEX IF NOT EXISTS idx_chat_bot_peer_list
    ON ai.chat (bot_iid, last_msg_ts DESC)
    WHERE kind = 'bot_peer' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_bot_peer_stopped
    ON ai.chat (bot_iid, ai_reply_enabled, last_msg_ts DESC)
    WHERE kind = 'bot_peer' AND deleted_ts IS NULL AND ai_reply_enabled = FALSE;

-- ------------------------------------------------------------------------------
-- 1:1 user-to-user dedup (DEFERRED — not in Home inbox; schema reserved)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.chat_direct_pair (
    iid_a               BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    iid_b               BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    chat_id             BIGINT NOT NULL UNIQUE REFERENCES ai.chat(id) ON DELETE CASCADE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (iid_a, iid_b),
    CONSTRAINT chk_chat_direct_pair_order CHECK (iid_a < iid_b)
);

-- ------------------------------------------------------------------------------
-- Inbox membership — per-user list, pin, archive, unread
-- Home inbox: prompt only. direct deferred (not shown in Home list).
-- bot_peer: Bots page (by bot_iid, not inbox)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.chat_member (
    chat_id             BIGINT NOT NULL REFERENCES ai.chat(id) ON DELETE CASCADE,
    member_iid          BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,

    last_read_msg_id    BIGINT,
    unread_count        INT NOT NULL DEFAULT 0,

    last_msg_ts         TIMESTAMPTZ NOT NULL DEFAULT NOW(),           -- denorm from chat; inbox sort
    last_msg_preview    VARCHAR(255) NOT NULL DEFAULT '',

    pinned_ts           TIMESTAMPTZ,
    archived_ts         TIMESTAMPTZ,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (chat_id, member_iid)
);

-- Home inbox: prompt threads only (direct deferred)
CREATE INDEX IF NOT EXISTS idx_chat_member_inbox
    ON ai.chat_member (member_iid, pinned_ts DESC NULLS LAST, last_msg_ts DESC)
    WHERE deleted_ts IS NULL AND archived_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_member_inbox_archived
    ON ai.chat_member (member_iid, archived_ts DESC, last_msg_ts DESC)
    WHERE deleted_ts IS NULL AND archived_ts IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chat_member_sync
    ON ai.chat_member (member_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Messages
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.chat_msg (
    id                  BIGINT PRIMARY KEY,
    chat_id             BIGINT NOT NULL REFERENCES ai.chat(id) ON DELETE CASCADE,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    req_id              VARCHAR(64) NOT NULL DEFAULT '',
    sender_iid          BIGINT NOT NULL REFERENCES ai.identity(id),
    role                VARCHAR(16) NOT NULL,
    source              VARCHAR(16) NOT NULL DEFAULT 'prompt',      -- prompt | user | external | staff

    content             TEXT NOT NULL DEFAULT '',
    thought             TEXT NOT NULL DEFAULT '',
    attachments         JSONB NOT NULL DEFAULT '[]',
    blocks_json         JSONB NOT NULL DEFAULT '[]',

    tokens_in           INT NOT NULL DEFAULT 0,
    tokens_out          INT NOT NULL DEFAULT 0,
    duration_ms         INT NOT NULL DEFAULT 0,
    cost_usd            NUMERIC(12, 6) NOT NULL DEFAULT 0,

    status              VARCHAR(16) NOT NULL DEFAULT 'done',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_chat_msg_role CHECK (role IN ('user', 'assistant', 'system')),
    CONSTRAINT chk_chat_msg_source CHECK (source IN ('prompt', 'user', 'external', 'staff')),
    CONSTRAINT chk_chat_msg_status CHECK (status IN ('streaming', 'done', 'interrupted', 'error'))
);

CREATE INDEX IF NOT EXISTS idx_chat_msg_stream
    ON ai.chat_msg (chat_id, id DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_msg_sync
    ON ai.chat_msg (chat_id, updated_ts);

CREATE INDEX IF NOT EXISTS idx_chat_msg_req
    ON ai.chat_msg (req_id);

CREATE INDEX IF NOT EXISTS idx_chat_msg_owner_sync
    ON ai.chat_msg (owner_iid, updated_ts);

ALTER TABLE ai.chat_msg ADD COLUMN IF NOT EXISTS cost_usd NUMERIC(12, 6) NOT NULL DEFAULT 0;
ALTER TABLE ai.chat_msg ADD COLUMN IF NOT EXISTS error_text TEXT NOT NULL DEFAULT '';
