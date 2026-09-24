-- ==============================================================================
-- c35 — Composer @mentions (topic steering + tool includes)
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.mention (
    id              TEXT PRIMARY KEY,
    topic_id        TEXT,
    inst_id         TEXT,
    icon            TEXT NOT NULL DEFAULT '',
    color           TEXT NOT NULL DEFAULT '',
    sort            INT NOT NULL DEFAULT 0,
    label_key       TEXT NOT NULL,
    caption_key     TEXT NOT NULL DEFAULT '',
    search_terms    TEXT[] NOT NULL DEFAULT '{}',
    enabled         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_mention_enabled_sort
    ON ai.mention (enabled, sort ASC, id ASC);

CREATE INDEX IF NOT EXISTS idx_mention_topic
    ON ai.mention (topic_id)
    WHERE topic_id IS NOT NULL;

-- Seed: @research
INSERT INTO ai.mention (
    id, topic_id, inst_id, icon, color, sort, label_key, caption_key, search_terms
) VALUES (
    'research',
    'research',
    'inst.mention.research',
    'iconify://mdi:magnify-scan',
    '#3B82F6',
    10,
    'mention.research.label',
    'mention.research.caption',
    ARRAY['research', 'riset', 'investigate', 'deep dive', 'sources']
) ON CONFLICT (id) DO NOTHING;

-- Image generation is automatic (attachments + img.generate tool) — not a composer mention.
UPDATE ai.mention SET enabled = false WHERE id = 'image';

-- Seed: @image-high (pro Flash Image tier)
INSERT INTO ai.mention (
    id, topic_id, inst_id, icon, color, sort, label_key, caption_key, search_terms
) VALUES (
    'image_high',
    'image',
    'inst.mention.image_high',
    'iconify://mdi:image-filter-hdr',
    '#A855F7',
    15,
    'mention.image_high.label',
    'mention.image_high.caption',
    ARRAY['image high', 'pro image', 'hd image', 'flash image', 'logo', 'poster', 'high quality']
) ON CONFLICT (id) DO NOTHING;

-- Seed: @memorize
INSERT INTO ai.mention (
    id, topic_id, inst_id, icon, color, sort, label_key, caption_key, search_terms
) VALUES (
    'memorize',
    NULL,
    NULL,
    'iconify://mdi:brain',
    '#F59E0B',
    30,
    'mention.memorize.label',
    'mention.memorize.caption',
    ARRAY['remember', 'memorize', 'ingat', 'save', 'recall', 'memory']
) ON CONFLICT (id) DO NOTHING;
