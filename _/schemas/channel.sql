-- ==============================================================================
-- c35 — Channel helpers (Telegram / WhatsApp Meta)
-- Apply after chat.sql
-- Channel config lives in ai.identity(kind=bot).meta.channels[] — not here.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.channel_msg_dedup (
    bot_iid             BIGINT NOT NULL REFERENCES ai.identity(id) ON DELETE CASCADE,
    channel_id          TEXT NOT NULL,
    external_msg_id     VARCHAR(191) NOT NULL,
    processed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (bot_iid, channel_id, external_msg_id)
);

CREATE INDEX IF NOT EXISTS idx_channel_msg_dedup_processed
    ON ai.channel_msg_dedup (processed_at);

CREATE TABLE IF NOT EXISTS ai.channel_inbound_msg (
    bot_iid             BIGINT NOT NULL,
    channel_id          TEXT NOT NULL,
    external_msg_id     VARCHAR(191) NOT NULL,
    chat_id             BIGINT NOT NULL REFERENCES ai.chat(id) ON DELETE CASCADE,
    chat_msg_id         BIGINT,
    text_preview        VARCHAR(500) NOT NULL DEFAULT '',
    processed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (bot_iid, channel_id, external_msg_id)
);

CREATE INDEX IF NOT EXISTS idx_channel_inbound_msg_chat
    ON ai.channel_inbound_msg (chat_id, processed_at DESC);
