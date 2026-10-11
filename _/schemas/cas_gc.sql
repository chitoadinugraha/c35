-- CAS inline orphan audit/delete (see _/scripts/dev/cleanup_cas_orphans.ps1).
-- Placeholders __MIN_AGE_DAYS__ are replaced by the driver.

WITH RECURSIVE
chat_hashes AS (
    SELECT DISTINCT lower(m[1]) AS hash
    FROM ai.chat_msg cm,
    LATERAL regexp_matches(
        coalesce(cm.attachments::text, '')
            || ' '
            || coalesce(cm.blocks_json::text, '')
            || ' '
            || coalesce(cm.content, ''),
        '[0-9a-f]{64}',
        'gi'
    ) AS m
    WHERE m[1] ~ '^[0-9a-f]{64}$'
),
mail_hashes AS (
    SELECT DISTINCT lower(m[1]) AS hash
    FROM mail.message mm,
    LATERAL regexp_matches(coalesce(mm.attachments_json::text, ''), '[0-9a-f]{64}', 'gi') AS m
    WHERE m[1] ~ '^[0-9a-f]{64}$'
),
config_hashes AS (
    SELECT DISTINCT lower(m[1]) AS hash
    FROM ai.config c,
    LATERAL regexp_matches(coalesce(c.value::text, ''), '[0-9a-f]{64}', 'gi') AS m
    WHERE m[1] ~ '^[0-9a-f]{64}$'
),
prompt_hashes AS (
    SELECT DISTINCT lower(m[1]) AS hash
    FROM ai.prompt_run pr,
    LATERAL regexp_matches(coalesce(pr.attachments_json, ''), '[0-9a-f]{64}', 'gi') AS m
    WHERE m[1] ~ '^[0-9a-f]{64}$'
),
site_text_hashes AS (
    SELECT DISTINCT lower(m[1]) AS hash
    FROM (
        SELECT pic || product_json::text AS blob FROM site.product WHERE deleted_ts IS NULL
        UNION ALL
        SELECT pic FROM site.object WHERE deleted_ts IS NULL
        UNION ALL
        SELECT thumb || media_json::text FROM site.post WHERE deleted_ts IS NULL
        UNION ALL
        SELECT doc_json::text FROM site.draft WHERE deleted_ts IS NULL
        UNION ALL
        SELECT doc_json::text FROM site.publish WHERE deleted_ts IS NULL
        UNION ALL
        SELECT file_hash FROM site.member_face WHERE deleted_ts IS NULL        UNION ALL
        SELECT convert_from(body, 'UTF8') FROM site.render WHERE body IS NOT NULL
    ) s(blob),
    LATERAL regexp_matches(coalesce(s.blob, ''), '[0-9a-f]{64}', 'gi') AS m
    WHERE m[1] ~ '^[0-9a-f]{64}$'
),
identity_hashes AS (
    SELECT DISTINCT lower(m[1]) AS hash
    FROM ai.identity i,
    LATERAL regexp_matches(coalesce(i.pic, ''), '[0-9a-f]{64}', 'gi') AS m
    WHERE i.is_active = true AND m[1] ~ '^[0-9a-f]{64}$'
),
roots AS (
    SELECT hash FROM chat_hashes
    UNION
    SELECT hash FROM mail_hashes
    UNION
    SELECT hash FROM config_hashes
    UNION
    SELECT hash FROM prompt_hashes
    UNION
    SELECT hash FROM site_text_hashes
    UNION
    SELECT hash FROM identity_hashes
    UNION
    SELECT lower(hash_blake3) FROM ai.drive_file
    WHERE deleted_ts IS NULL AND hash_blake3 ~ '^[0-9a-f]{64}$'
    UNION
    SELECT lower(hash_blake3) FROM ai.tool_artifact
    WHERE deleted_ts IS NULL AND expires_ts > NOW() AND hash_blake3 ~ '^[0-9a-f]{64}$'
),
kept AS (
    SELECT hash FROM roots
    UNION
    SELECT lower(v.val)
    FROM kept k
    JOIN ai.file_blob_meta m ON m.hash_blake3 = k.hash
    CROSS JOIN LATERAL jsonb_each_text(m.variants) AS v(key, val)
    WHERE v.val ~ '^[0-9a-f]{64}$'
),
orphans AS (
    SELECT m.hash_blake3, m.size_bytes, m.created_ts
    FROM ai.file_blob_meta m
    WHERE m.store = 'inline'
      AND m.created_ts < NOW() - (__MIN_AGE_DAYS__::text || ' days')::interval
      AND NOT EXISTS (SELECT 1 FROM kept k WHERE k.hash = m.hash_blake3)
)