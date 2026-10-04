-- c35 presentation slide themes
CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.presentation_theme (
    id              TEXT PRIMARY KEY,
    label_key       TEXT NOT NULL,
    sort            INT NOT NULL DEFAULT 0,
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    icon            TEXT NOT NULL DEFAULT '',
    tokens_json     JSONB NOT NULL,
    aliases         TEXT[] NOT NULL DEFAULT '{}',
    def_hash        TEXT NOT NULL DEFAULT 'seed',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ai.presentation_theme ADD COLUMN IF NOT EXISTS icon TEXT NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_presentation_theme_enabled_sort
    ON ai.presentation_theme (enabled, sort ASC, id ASC);

INSERT INTO ai.presentation_theme (id, label_key, sort, icon, tokens_json, aliases) VALUES
(
    'dark',
    'presentation.theme.dark.label',
    0,
    'iconify://mdi:flash',
    '{"canvas_bg":"#0D0D11","card_bg":"#141418","border":"#26262C","accent":"#F97316","accent2":"#06B6D4","text":"#F4F4F5","subtext":"#A1A1AA","badge_bg":"#261810","bullet_card_bg":"#14FFFFFF","gradient_from":"#1A1A22","gradient_to":"#0E0E12"}'::jsonb,
    ARRAY[]::TEXT[]
),
(
    'midnight',
    'presentation.theme.midnight.label',
    10,
    'iconify://mdi:moon-waning-crescent',
    '{"canvas_bg":"#0B0F19","card_bg":"#0F172A","border":"#1E293B","accent":"#6366F1","accent2":"#38BDF8","text":"#F8FAFC","subtext":"#94A3B8","badge_bg":"#1E1B4B","bullet_card_bg":"#1A6366F1","gradient_from":"#1E1B4B","gradient_to":"#0F172A"}'::jsonb,
    ARRAY['indigo']::TEXT[]
),
(
    'emerald',
    'presentation.theme.emerald.label',
    20,
    'iconify://mdi:leaf',
    '{"canvas_bg":"#041C16","card_bg":"#062820","border":"#0D4236","accent":"#10B981","accent2":"#34D399","text":"#ECFDF5","subtext":"#6EE7B7","badge_bg":"#064E3B","bullet_card_bg":"#1A10B981","gradient_from":"#064E3B","gradient_to":"#041C16"}'::jsonb,
    ARRAY['corporate','mint']::TEXT[]
),
(
    'sunset',
    'presentation.theme.sunset.label',
    30,
    'iconify://mdi:white-balance-sunny',
    '{"canvas_bg":"#140814","card_bg":"#1E101E","border":"#3A1A38","accent":"#EC4899","accent2":"#F59E0B","text":"#FFF1F2","subtext":"#FDA4AF","badge_bg":"#3B0764","bullet_card_bg":"#1AEC4899","gradient_from":"#3B0764","gradient_to":"#180816"}'::jsonb,
    ARRAY['coral','pink']::TEXT[]
),
(
    'ocean',
    'presentation.theme.ocean.label',
    40,
    'iconify://mdi:waves',
    '{"canvas_bg":"#030712","card_bg":"#0B1220","border":"#1E3A5F","accent":"#22D3EE","accent2":"#3B82F6","text":"#F0F9FF","subtext":"#7DD3FC","badge_bg":"#0C4A6E","bullet_card_bg":"#1A22D3EE","gradient_from":"#0C4A6E","gradient_to":"#030712"}'::jsonb,
    ARRAY['cyan','aqua']::TEXT[]
),
(
    'ruby',
    'presentation.theme.ruby.label',
    50,
    'iconify://mdi:gem',
    '{"canvas_bg":"#0F0507","card_bg":"#1A0A0E","border":"#4A1D28","accent":"#FB7185","accent2":"#F43F5E","text":"#FFF1F2","subtext":"#FDA4AF","badge_bg":"#4C0519","bullet_card_bg":"#1AFB7185","gradient_from":"#4C0519","gradient_to":"#0F0507"}'::jsonb,
    ARRAY['rose','red']::TEXT[]
),
(
    'gold',
    'presentation.theme.gold.label',
    60,
    'iconify://mdi:crown',
    '{"canvas_bg":"#0A0908","card_bg":"#14110E","border":"#3D3428","accent":"#FACC15","accent2":"#F59E0B","text":"#FEFCE8","subtext":"#FDE68A","badge_bg":"#422006","bullet_card_bg":"#1AFACC15","gradient_from":"#422006","gradient_to":"#0A0908"}'::jsonb,
    ARRAY['amber','yellow']::TEXT[]
),
(
    'arctic',
    'presentation.theme.arctic.label',
    70,
    'iconify://mdi:snowflake',
    '{"canvas_bg":"#F1F5F9","card_bg":"#FFFFFF","border":"#CBD5E1","accent":"#0369A1","accent2":"#0284C7","text":"#0F172A","subtext":"#475569","badge_bg":"#E0F2FE","bullet_card_bg":"#140369A1","gradient_from":"#E2E8F0","gradient_to":"#F8FAFC"}'::jsonb,
    ARRAY['light','white']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
    label_key = EXCLUDED.label_key,
    sort = EXCLUDED.sort,
    icon = EXCLUDED.icon,
    tokens_json = EXCLUDED.tokens_json,
    aliases = EXCLUDED.aliases,
    updated_ts = NOW();

INSERT INTO ai.translation (lang, key, category, text) VALUES
('en', 'presentation.theme.dark.label', 'presentation', 'Dark Neon'),
('en', 'presentation.theme.midnight.label', 'presentation', 'Midnight Indigo'),
('en', 'presentation.theme.emerald.label', 'presentation', 'Emerald Modern'),
('en', 'presentation.theme.sunset.label', 'presentation', 'Sunset Glow'),
('en', 'presentation.theme.ocean.label', 'presentation', 'Ocean Deep'),
('en', 'presentation.theme.ruby.label', 'presentation', 'Ruby Noir'),
('en', 'presentation.theme.gold.label', 'presentation', 'Royal Gold'),
('en', 'presentation.theme.arctic.label', 'presentation', 'Arctic Light'),
('id', 'presentation.theme.dark.label', 'presentation', 'Dark Neon'),
('id', 'presentation.theme.midnight.label', 'presentation', 'Midnight Indigo'),
('id', 'presentation.theme.emerald.label', 'presentation', 'Emerald Modern'),
('id', 'presentation.theme.sunset.label', 'presentation', 'Sunset Glow'),
('id', 'presentation.theme.ocean.label', 'presentation', 'Ocean Deep'),
('id', 'presentation.theme.ruby.label', 'presentation', 'Ruby Noir'),
('id', 'presentation.theme.gold.label', 'presentation', 'Royal Gold'),
('id', 'presentation.theme.arctic.label', 'presentation', 'Arctic Light')
ON CONFLICT (lang, key) DO UPDATE SET text = EXCLUDED.text, updated_ts = NOW();
