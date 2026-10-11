DROP TABLE IF EXISTS cas_kept;
CREATE TEMP TABLE cas_kept (hash text PRIMARY KEY);

INSERT INTO cas_kept(hash)
SELECT lower(hash_blake3) FROM ai.drive_file WHERE deleted_ts IS NULL AND hash_blake3 ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT lower(hash_blake3) FROM ai.tool_artifact
WHERE deleted_ts IS NULL AND expires_ts > NOW() AND hash_blake3 ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT lower(file_hash) FROM site.member_face
WHERE deleted_ts IS NULL AND file_hash ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(m[1])
FROM ai.chat_msg cm,
LATERAL regexp_matches(
    coalesce(cm.attachments::text, '') || ' ' || coalesce(cm.blocks_json::text, '') || ' ' || coalesce(cm.content, ''),
    '[0-9a-f]{64}', 'gi') AS m
WHERE m[1] ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(m[1])
FROM mail.message mm,
LATERAL regexp_matches(coalesce(mm.attachments_json::text, ''), '[0-9a-f]{64}', 'gi') AS m
WHERE m[1] ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(m[1])
FROM ai.prompt_run pr,
LATERAL regexp_matches(coalesce(pr.attachments_json, ''), '[0-9a-f]{64}', 'gi') AS m
WHERE m[1] ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(m[1])
FROM ai.config c,
LATERAL regexp_matches(coalesce(c.value::text, ''), '[0-9a-f]{64}', 'gi') AS m
WHERE m[1] ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(m[1])
FROM ai.identity i,
LATERAL regexp_matches(coalesce(i.pic, ''), '[0-9a-f]{64}', 'gi') AS m
WHERE i.is_active AND m[1] ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(m[1])
FROM (
    SELECT pic || product_json::text AS blob FROM site.product WHERE deleted_ts IS NULL
    UNION ALL SELECT pic FROM site.object WHERE deleted_ts IS NULL
    UNION ALL SELECT thumb || media_json::text FROM site.post WHERE deleted_ts IS NULL
    UNION ALL SELECT doc_json::text FROM site.draft WHERE deleted_ts IS NULL
    UNION ALL SELECT doc_json::text FROM site.publish WHERE deleted_ts IS NULL
) s(blob),
LATERAL regexp_matches(coalesce(s.blob, ''), '[0-9a-f]{64}', 'gi') AS m
WHERE m[1] ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

-- Expand variants from kept canonicals (4 waves)
INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(v.val)
FROM cas_kept k
JOIN ai.file_blob_meta m ON m.hash_blake3 = k.hash
CROSS JOIN LATERAL jsonb_each_text(m.variants) AS v(key, val)
WHERE v.val ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(v.val)
FROM cas_kept k
JOIN ai.file_blob_meta m ON m.hash_blake3 = k.hash
CROSS JOIN LATERAL jsonb_each_text(m.variants) AS v(key, val)
WHERE v.val ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(v.val)
FROM cas_kept k
JOIN ai.file_blob_meta m ON m.hash_blake3 = k.hash
CROSS JOIN LATERAL jsonb_each_text(m.variants) AS v(key, val)
WHERE v.val ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;

INSERT INTO cas_kept(hash)
SELECT DISTINCT lower(v.val)
FROM cas_kept k
JOIN ai.file_blob_meta m ON m.hash_blake3 = k.hash
CROSS JOIN LATERAL jsonb_each_text(m.variants) AS v(key, val)
WHERE v.val ~ '^[0-9a-f]{64}$'
ON CONFLICT DO NOTHING;