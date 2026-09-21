-- ==============================================================================
-- c35 — Instruction macros (phrase/trigger steering)
-- Port: cs_agent agent.inst → ai.inst
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.inst (
    id              TEXT PRIMARY KEY,
    scope           TEXT NOT NULL DEFAULT 'global',
    kind            TEXT NOT NULL DEFAULT 'task',
    topic_id        TEXT NOT NULL DEFAULT '',
    topics          TEXT[] NOT NULL DEFAULT '{}',
    inst            TEXT NOT NULL,
    phrases         TEXT[] NOT NULL DEFAULT '{}',
    triggers        TEXT[] NOT NULL DEFAULT '{}',
    priority        INT NOT NULL DEFAULT 0,
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    def_hash        TEXT NOT NULL DEFAULT '',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_inst_enabled
    ON ai.inst (enabled, priority DESC)
    WHERE deleted_ts IS NULL;

-- Seed: web search steering (global)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.web_search',
    'global',
    'task',
    '',
    '[WEB] Ground factual answers with web.search. Use for current events, prices, weather, or anything that may have changed.',
    ARRAY['search', 'cari', 'googling', 'browse', 'latest', 'terbaru', 'kapan', 'weather', 'cuaca', 'harga'],
    ARRAY['tool_include:web.search'],
    100,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: @research mention steering
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.mention.research',
    'global',
    'mention',
    'research',
    '[MENTION: @research] Deep research mode: use web.search to discover sources, web.visit to read key pages, and web.research to synthesize a thorough answer with citations.',
    ARRAY[]::TEXT[],
    ARRAY['tool_include:web.research', 'tool_include:web.visit', 'tool_include:web.search'],
    125,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: @image mention steering
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.mention.image',
    'global',
    'mention',
    'image',
    '[MENTION: @image] Call img.generate to create, draw, or render the requested image.',
    ARRAY[]::TEXT[],
    ARRAY['tool_include:img.generate'],
    130,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: image generation task steering
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.task.img_generate',
    'global',
    'task',
    '',
    '[IMAGE GENERATION] When the user asks to generate, create, draw, paint, or render an image, artwork, logo, icon, illustration, or graphic, call img.generate with an expanded English visual prompt and appropriate aspect_ratio. When img.generate succeeds and returns file_hash, display the image using markdown: ![<short title>](https://f.alienai.id/fs/<file_hash>).',
    ARRAY[
        'buat gambar', 'buatkan gambar', 'bikin gambar', 'generate image', 'create image',
        'draw ', 'lukis', 'illustration', 'buat logo', 'buat icon', 'render image'
    ],
    ARRAY['tool_include:img.generate'],
    140,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: food consumption logging (personal assistant)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.consumption_add',
    'role:personal_assistant',
    'task',
    '',
    '[FOOD] User wants to log food consumption. Call consumption.add when a photo or description is available. \
The meal card shows headline, coach, and macros — reply with at most one short sentence; do not repeat numbers or tables.',
    ARRAY[
        'catat konsumsi', 'catat makanan', 'catat konsumsi makanan',
        'track food', 'log meal', 'track food consumption'
    ],
    ARRAY['tool_include:consumption.add'],
    140,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: nutrition recap, food recommendations, historical queries
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.consumption_coach',
    'role:personal_assistant',
    'task',
    '',
    '[NUTRITION] For food recommendations, daily recap, or "how much X did I eat", call consumption.today first. \
Use day_id yesterday for past days. Pass item_query for specific foods (e.g. mie, noodle). \
Give warm, concise coaching in the user language — praise good balance, gently nudge when over goal.',
    ARRAY[
        'rekomendasi makan', 'food recommendation', 'what should i eat', 'apa yang harus dimakan',
        'berapa kalori', 'how many calories', 'nutrition recap', 'ringkasan nutrisi',
        'berapa banyak', 'how much', 'kemarin', 'yesterday', 'mie', 'noodle', 'nasi'
    ],
    ARRAY['tool_include:consumption.today'],
    135,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;
