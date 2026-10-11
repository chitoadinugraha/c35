-- Batched CAS orphan GC (__MIN_AGE_DAYS__ days). No recursive CTE.

WITH candidate AS (
    SELECT m.hash_blake3, m.size_bytes, m.created_ts
    FROM ai.file_blob_meta m
    WHERE m.store = 'inline'
      AND m.mime_type IN ('image/webp', 'image/jpeg')
      AND m.size_bytes < 65536
      AND m.created_ts < NOW() - (__MIN_AGE_DAYS__::text || ' days')::interval
      AND NOT EXISTS (
          SELECT 1 FROM ai.drive_file d
          WHERE d.deleted_ts IS NULL AND lower(d.hash_blake3) = m.hash_blake3
      )
      AND NOT EXISTS (
          SELECT 1 FROM ai.tool_artifact t
          WHERE t.deleted_ts IS NULL AND t.expires_ts > NOW()
            AND lower(t.hash_blake3) = m.hash_blake3
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.member_face f
          WHERE f.deleted_ts IS NULL AND lower(f.file_hash) = m.hash_blake3
      )
      AND NOT EXISTS (
          SELECT 1 FROM ai.chat_msg cm
          WHERE cm.attachments::text LIKE '%' || m.hash_blake3 || '%'
             OR coalesce(cm.blocks_json::text, '') LIKE '%' || m.hash_blake3 || '%'
             OR cm.content LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM mail.message mm
          WHERE mm.attachments_json::text LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM ai.prompt_run pr
          WHERE pr.attachments_json LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM ai.config c
          WHERE c.value::text LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM ai.identity i
          WHERE i.is_active AND coalesce(i.pic, '') LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.product p
          WHERE p.deleted_ts IS NULL
            AND (p.pic LIKE '%' || m.hash_blake3 || '%' OR p.product_json::text LIKE '%' || m.hash_blake3 || '%')
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.object o
          WHERE o.deleted_ts IS NULL AND o.pic LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.post po
          WHERE po.deleted_ts IS NULL
            AND (po.thumb LIKE '%' || m.hash_blake3 || '%' OR po.media_json::text LIKE '%' || m.hash_blake3 || '%')
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.draft d
          WHERE d.deleted_ts IS NULL AND d.doc_json::text LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.publish pu
          WHERE pu.deleted_ts IS NULL AND pu.doc_json::text LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM site.render r
          WHERE r.body IS NOT NULL AND convert_from(r.body, 'UTF8') LIKE '%' || m.hash_blake3 || '%'
      )
      AND NOT EXISTS (
          SELECT 1 FROM ai.file_blob_meta p
          WHERE p.hash_blake3 <> m.hash_blake3
            AND (
              lower(coalesce(p.variants->>'thumb', '')) = m.hash_blake3
              OR lower(coalesce(p.variants->>'small', '')) = m.hash_blake3
              OR lower(coalesce(p.variants->>'doc_index', '')) = m.hash_blake3
              OR p.variants::text LIKE '%' || m.hash_blake3 || '%'
            )
      )
)