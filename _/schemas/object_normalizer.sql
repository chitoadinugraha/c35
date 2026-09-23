-- ==============================================================================
-- c35 — Product & Object Normalizer Taxonomy (LOCKED 2026-09-23)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: ai
--
-- Language-neutral knowledge graph / taxonomy DAG for product & expense normalization.
-- Links raw store receipt lines and natural language prompts to canonical objects.
-- UI: Root admin curation for unverified aliases (like ai.inst).
-- Apply after: identity.sql
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

-- ------------------------------------------------------------------------------
-- 1. Language-Neutral Knowledge Graph Node
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.object_normalizer (
    id                  BIGINT PRIMARY KEY,                      -- numeric standard ID (e.g. Google Product Taxonomy ID) or snowflake
    slug                VARCHAR(64) UNIQUE NOT NULL,             -- stable identifier: 'milk', 'beverage', 'internet'
    parent_id           BIGINT REFERENCES ai.object_normalizer(id), -- direct parent node in DAG/tree
    path                TEXT NOT NULL,                           -- materialized path: 'consumable.drink.milk'
    depth               SMALLINT NOT NULL DEFAULT 0,             -- tree depth (0=root domain, 1=category, 2=subcat, 3=item)
    l1_category_id      BIGINT REFERENCES ai.object_normalizer(id), -- direct L1 category ancestor (for zero-overhead GROUP BY)
    l2_category_id      BIGINT REFERENCES ai.object_normalizer(id), -- direct L2 subcategory ancestor
    kind                VARCHAR(32) NOT NULL DEFAULT 'category', -- 'domain' | 'category' | 'brand' | 'service' | 'item'

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crucial for subtree queries: matching 'consumable.drink.milk%' as a B-tree range scan
CREATE INDEX IF NOT EXISTS idx_obj_normalizer_path_ops
    ON ai.object_normalizer (path text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_obj_normalizer_parent
    ON ai.object_normalizer (parent_id);
CREATE INDEX IF NOT EXISTS idx_obj_normalizer_l1
    ON ai.object_normalizer (l1_category_id);
CREATE INDEX IF NOT EXISTS idx_obj_normalizer_l2
    ON ai.object_normalizer (l2_category_id);

-- ------------------------------------------------------------------------------
-- 2. Multilingual Aliases, OCR Variants & Embeddings
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.object_alias (
    id                  BIGINT PRIMARY KEY,                      -- snowflake
    obj_id              BIGINT NOT NULL REFERENCES ai.object_normalizer(id) ON DELETE CASCADE,
    lang                VARCHAR(16) NOT NULL DEFAULT 'raw',      -- 'en', 'id', 'zh', or 'raw' for store receipt OCR
    name                VARCHAR(255) NOT NULL,                   -- display/source string: 'Milk', 'Susu', 'INDMILK'
    name_norm           VARCHAR(255) NOT NULL,                   -- lowercase trimmed: 'milk', 'susu', 'indmilk'
    is_canonical        BOOLEAN NOT NULL DEFAULT FALSE,          -- default display name for this (obj_id, lang)
    ehash               VARCHAR(64) NOT NULL DEFAULT '',         -- blake3 hash of embedding in ai.embed_cache
    verified            BOOLEAN NOT NULL DEFAULT FALSE,          -- reviewed by root admin (vs auto-created by LLM)

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_obj_alias_lookup
    ON ai.object_alias (name_norm);
CREATE INDEX IF NOT EXISTS idx_obj_alias_lang_lookup
    ON ai.object_alias (lang, name_norm);
CREATE INDEX IF NOT EXISTS idx_obj_alias_obj_id
    ON ai.object_alias (obj_id);
CREATE INDEX IF NOT EXISTS idx_obj_alias_unverified
    ON ai.object_alias (verified, created_ts DESC)
    WHERE verified = FALSE;

-- ------------------------------------------------------------------------------
-- 3. Language Word / Token Normalizer (Abbreviations & Shorthand)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.word_normalizer (
    lang                VARCHAR(16) NOT NULL,                    -- 'id', 'en', etc.
    term                VARCHAR(64) NOT NULL,                    -- shorthand/token: 'grg', 'aym', 'choc'
    replacement         VARCHAR(64) NOT NULL,                    -- expanded word: 'goreng', 'ayam', 'chocolate'
    category            VARCHAR(32) NOT NULL DEFAULT 'retail',   -- 'retail' | 'pos' | 'measurement'
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (lang, term)
);

CREATE INDEX IF NOT EXISTS idx_word_normalizer_lookup
    ON ai.word_normalizer (lang, term);

-- ------------------------------------------------------------------------------
-- 4. Deterministic Slug Normalizer Function
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ai.slug_norm(raw TEXT) RETURNS TEXT AS $$
BEGIN
    IF raw IS NULL OR TRIM(raw) = '' THEN
        RETURN '';
    END IF;
    RETURN TRIM(BOTH '_' FROM 
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                LOWER(raw), 
                '[^a-z0-9]+', '_', 'g'     -- replace any non-alphanumeric run with a single '_'
            ), 
            '_+', '_', 'g'                 -- collapse duplicate '_'
        )
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ------------------------------------------------------------------------------
-- 5. Starter Seeds: Core Domains, Categories, Word Replacements & Aliases
-- ------------------------------------------------------------------------------

-- Root Domains (Depth 0)
INSERT INTO ai.object_normalizer (id, slug, parent_id, path, depth, kind) VALUES
    (1000, 'consumable', NULL, 'consumable', 0, 'domain'),
    (2000, 'service',    NULL, 'service',    0, 'domain'),
    (3000, 'goods',      NULL, 'goods',      0, 'domain')
ON CONFLICT (id) DO NOTHING;

-- L1 Categories (Depth 1)
INSERT INTO ai.object_normalizer (id, slug, parent_id, path, depth, l1_category_id, kind) VALUES
    (1100, 'drink',     1000, 'consumable.drink',     1, 1100, 'category'),
    (1200, 'food',      1000, 'consumable.food',      1, 1200, 'category'),
    (2100, 'utility',   2000, 'service.utility',      1, 2100, 'category'),
    (2200, 'transport', 2000, 'service.transport',    1, 2200, 'category')
ON CONFLICT (id) DO NOTHING;

-- L2 Subcategories (Depth 2)
INSERT INTO ai.object_normalizer (id, slug, parent_id, path, depth, l1_category_id, l2_category_id, kind) VALUES
    (1110, 'milk',        1100, 'consumable.drink.milk',           2, 1100, 1110, 'category'),
    (1120, 'coffee',      1100, 'consumable.drink.coffee',         2, 1100, 1120, 'category'),
    (2110, 'internet',    2100, 'service.utility.internet',        2, 2100, 2110, 'category'),
    (2120, 'electricity', 2100, 'service.utility.electricity',   2, 2100, 2120, 'category')
ON CONFLICT (id) DO NOTHING;

-- Multilingual Aliases (EN & ID)
INSERT INTO ai.object_alias (id, obj_id, lang, name, name_norm, is_canonical, verified) VALUES
    -- Consumable / Drink / Milk
    (100001, 1100, 'en', 'Drink',     'drink',     TRUE, TRUE),
    (100002, 1100, 'id', 'Minuman',   'minuman',   TRUE, TRUE),
    (100003, 1110, 'en', 'Milk',      'milk',      TRUE, TRUE),
    (100004, 1110, 'id', 'Susu',      'susu',      TRUE, TRUE),
    -- Service / Utility / Internet
    (200001, 2100, 'en', 'Utility',   'utility',   TRUE, TRUE),
    (200002, 2100, 'id', 'Utilitas',  'utilitas',  TRUE, TRUE),
    (200003, 2110, 'en', 'Internet',  'internet',  TRUE, TRUE),
    (200004, 2110, 'id', 'Internet',  'internet',  TRUE, TRUE),
    (200005, 2120, 'en', 'Electricity', 'electricity', TRUE, TRUE),
    (200006, 2120, 'id', 'Listrik',   'listrik',   TRUE, TRUE),
    -- Common Indonesian raw receipt / provider aliases
    (300001, 2110, 'raw', 'BIZNET',   'biznet',    FALSE, TRUE),
    (300002, 2110, 'raw', 'INDIHOME', 'indihome',  FALSE, TRUE),
    (300003, 2120, 'raw', 'PLN',      'pln',       FALSE, TRUE),
    (300004, 2120, 'raw', 'TOKEN LISTRIK', 'token listrik', FALSE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Word Normalizer Seeds (ID & EN)
INSERT INTO ai.word_normalizer (lang, term, replacement, category) VALUES
    -- Indonesian Food & Retail Shorthands
    ('id', 'grg',   'goreng',     'retail'),
    ('id', 'bkr',   'bakar',      'retail'),
    ('id', 'aym',   'ayam',       'retail'),
    ('id', 'cklt',  'cokelat',    'retail'),
    ('id', 'strw',  'strawberry', 'retail'),
    ('id', 'kcl',   'kecil',      'retail'),
    ('id', 'bsr',   'besar',      'retail'),
    ('id', 'btl',   'botol',      'retail'),
    ('id', 'kntg',  'kantong',    'retail'),
    ('id', 'tp',    'tanpa',      'retail'),
    ('id', 'pdz',   'pedas',      'retail'),
    ('id', 'mnm',   'minuman',    'retail'),
    ('id', 'susu',  'milk',       'retail'),

    -- English Retail Shorthands
    ('en', 'choc',  'chocolate',  'retail'),
    ('en', 'strw',  'strawberry', 'retail'),
    ('en', 'btl',   'bottle',     'retail'),
    ('en', 'sm',    'small',      'retail'),
    ('en', 'md',    'medium',     'retail'),
    ('en', 'lg',    'large',      'retail'),
    ('en', 'org',   'organic',    'retail'),
    ('en', 'wht',   'white',      'retail')
ON CONFLICT (lang, term) DO UPDATE SET replacement = EXCLUDED.replacement;

