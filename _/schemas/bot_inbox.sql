-- ==============================================================================
-- Bot inbox analytics (channel user messages on bot_peer threads)
-- Apply after chat.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.bot_inbox_day (
    bot_iid             BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    day                 DATE NOT NULL,
    channel_id          TEXT NOT NULL,
    user_msg_count      BIGINT NOT NULL DEFAULT 0,
    active_chat_count   BIGINT NOT NULL DEFAULT 0,
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (bot_iid, day, channel_id)
);

CREATE INDEX IF NOT EXISTS idx_bot_inbox_day_bot_day
    ON ai.bot_inbox_day (bot_iid, day DESC);

CREATE TABLE IF NOT EXISTS ai.bot_inbox_question (
    bot_iid             BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    day                 DATE NOT NULL,
    channel_id          TEXT NOT NULL,
    fingerprint         TEXT NOT NULL,
    sample_text         TEXT NOT NULL DEFAULT '',
    count               BIGINT NOT NULL DEFAULT 0,
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (bot_iid, day, channel_id, fingerprint)
);

CREATE INDEX IF NOT EXISTS idx_bot_inbox_question_bot_day
    ON ai.bot_inbox_question (bot_iid, day DESC);

CREATE TABLE IF NOT EXISTS ai.bot_inbox_chat_touch (
    bot_iid             BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    day                 DATE NOT NULL,
    channel_id          TEXT NOT NULL,
    chat_id             BIGINT NOT NULL REFERENCES ai.chat(id) ON DELETE CASCADE,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (bot_iid, day, channel_id, chat_id)
);

-- Hot path: list peer messages in a day window
CREATE INDEX IF NOT EXISTS idx_chat_msg_bot_peer_user_ts
    ON ai.chat_msg (chat_id, created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL AND role = 'user' AND source = 'external';
