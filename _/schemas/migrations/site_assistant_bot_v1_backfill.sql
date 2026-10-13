-- Backfill site.config.assistant_bot_iid for existing sites (run after site_assistant_bot_v1.sql).
-- Promotes capabilities_json and links existing site_assistant bots; does not create new identity rows.
-- To create missing bots, run: cd servers && cargo run -p c35_mod_site --bin site_assistant_bot_backfill_once

-- 1) Column from capabilities_json when the bot exists.
UPDATE site.config sc
SET
    assistant_bot_iid = (sc.capabilities_json ->> 'assistant_bot_iid')::bigint,
    updated_ts = NOW()
WHERE sc.deleted_ts IS NULL
  AND sc.assistant_bot_iid IS NULL
  AND (sc.capabilities_json ->> 'assistant_bot_iid') ~ '^[0-9]+$'
  AND (sc.capabilities_json ->> 'assistant_bot_iid')::bigint > 0
  AND EXISTS (
      SELECT 1
      FROM ai.identity i
      WHERE i.id = (sc.capabilities_json ->> 'assistant_bot_iid')::bigint
        AND i.kind = 'bot'
        AND i.deleted_ts IS NULL
  );

-- 2) Link configs to existing site_assistant bots (meta.parent_site_iid).
UPDATE site.config sc
SET
    assistant_bot_iid = b.id,
    capabilities_json = sc.capabilities_json
        || jsonb_build_object('assistant_bot_iid', b.id),
    updated_ts = NOW()
FROM ai.identity b
WHERE sc.deleted_ts IS NULL
  AND sc.assistant_bot_iid IS NULL
  AND b.kind = 'bot'
  AND b.deleted_ts IS NULL
  AND b.meta ->> 'source' = 'site_assistant'
  AND (b.meta ->> 'parent_site_iid')::bigint = sc.site_iid
  AND NOT EXISTS (
      SELECT 1
      FROM site.config sc2
      WHERE sc2.deleted_ts IS NULL
        AND sc2.assistant_bot_iid = b.id
        AND sc2.site_iid <> sc.site_iid
  );
