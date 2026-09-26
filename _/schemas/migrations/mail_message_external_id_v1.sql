-- mail.message dedup for inbound webhook (M2)
ALTER TABLE mail.message
    ADD COLUMN IF NOT EXISTS external_id VARCHAR(256);

CREATE UNIQUE INDEX IF NOT EXISTS uq_mail_message_external_id
    ON mail.message (external_id)
    WHERE external_id IS NOT NULL AND btrim(external_id) <> '';
