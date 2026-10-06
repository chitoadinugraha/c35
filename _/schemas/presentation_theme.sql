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
),
(
    'lavender',
    'presentation.theme.lavender.label',
    80,
    'iconify://mdi:auto-fix',
    '{"canvas_bg":"#0E0C1A","card_bg":"#161326","border":"#2E254C","accent":"#A855F7","accent2":"#EC4899","text":"#FAF5FF","subtext":"#D8B4FE","badge_bg":"#3B185F","bullet_card_bg":"#1AA855F7","gradient_from":"#2A1647","gradient_to":"#0E0C1A"}'::jsonb,
    ARRAY['amethyst','purple','violet']::TEXT[]
),
(
    'cream',
    'presentation.theme.cream.label',
    90,
    'iconify://mdi:book-open-page-variant',
    '{"canvas_bg":"#FDFBF7","card_bg":"#FFFFFF","border":"#E7E1D8","accent":"#C2410C","accent2":"#D97706","text":"#1C1917","subtext":"#78716C","badge_bg":"#FFEDD5","bullet_card_bg":"#0CC2410C","gradient_from":"#FAF5EE","gradient_to":"#FDFBF7"}'::jsonb,
    ARRAY['editorial','paper','minimal','warm']::TEXT[]
),
(
    'monochrome',
    'presentation.theme.monochrome.label',
    100,
    'iconify://mdi:circle-half-full',
    '{"canvas_bg":"#09090B","card_bg":"#131316","border":"#27272A","accent":"#E4E4E7","accent2":"#71717A","text":"#FAFAFA","subtext":"#A1A1AA","badge_bg":"#27272A","bullet_card_bg":"#12FFFFFF","gradient_from":"#202024","gradient_to":"#09090B"}'::jsonb,
    ARRAY['bw','slate','silver','zinc']::TEXT[]
),
(
    'forest',
    'presentation.theme.forest.label',
    110,
    'iconify://mdi:pine-tree',
    '{"canvas_bg":"#08130B","card_bg":"#102014","border":"#1E3A24","accent":"#84CC16","accent2":"#A3E635","text":"#F7FEE7","subtext":"#BEF264","badge_bg":"#1A2E05","bullet_card_bg":"#1A84CC16","gradient_from":"#16331C","gradient_to":"#08130B"}'::jsonb,
    ARRAY['moss','nature','sage','botanical']::TEXT[]
),
(
    'sakura',
    'presentation.theme.sakura.label',
    120,
    'iconify://mdi:flower',
    '{"canvas_bg":"#FFF5F5","card_bg":"#FFFFFF","border":"#FED7D7","accent":"#E11D48","accent2":"#FB7185","text":"#1C1917","subtext":"#831843","badge_bg":"#FFE4E6","bullet_card_bg":"#0DE11D48","gradient_from":"#FCE7F3","gradient_to":"#FFF5F5"}'::jsonb,
    ARRAY['blossom','rose-light','pastel','floral']::TEXT[]
),
(
    'cyberpunk',
    'presentation.theme.cyberpunk.label',
    130,
    'iconify://mdi:controller',
    '{"canvas_bg":"#070614","card_bg":"#100E26","border":"#282054","accent":"#F43F5E","accent2":"#00F5FF","text":"#FDF4FF","subtext":"#E879F9","badge_bg":"#3B0764","bullet_card_bg":"#1AF43F5E","gradient_from":"#2B1055","gradient_to":"#070614"}'::jsonb,
    ARRAY['synthwave','neon','tokyo','gaming']::TEXT[]
),
(
    'coffee',
    'presentation.theme.coffee.label',
    140,
    'iconify://mdi:coffee',
    '{"canvas_bg":"#120C0A","card_bg":"#1C1411","border":"#362520","accent":"#D97706","accent2":"#EA580C","text":"#FEF3C7","subtext":"#D1A074","badge_bg":"#2C1810","bullet_card_bg":"#1AD97706","gradient_from":"#2B1710","gradient_to":"#120C0A"}'::jsonb,
    ARRAY['mocha','espresso','leather','artisan']::TEXT[]
),
(
    'aurora',
    'presentation.theme.aurora.label',
    150,
    'iconify://mdi:weather-night',
    '{"canvas_bg":"#040E1A","card_bg":"#091B30","border":"#13365C","accent":"#2DD4BF","accent2":"#818CF8","text":"#F0FDFA","subtext":"#5EEAD4","badge_bg":"#134E4A","bullet_card_bg":"#1A2DD4BF","gradient_from":"#0F3559","gradient_to":"#040E1A"}'::jsonb,
    ARRAY['teal','boreal','nordic']::TEXT[]
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
('en', 'presentation.theme.lavender.label', 'presentation', 'Lavender Amethyst'),
('en', 'presentation.theme.cream.label', 'presentation', 'Editorial Cream'),
('en', 'presentation.theme.monochrome.label', 'presentation', 'Bauhaus Slate'),
('en', 'presentation.theme.forest.label', 'presentation', 'Forest Botanical'),
('en', 'presentation.theme.sakura.label', 'presentation', 'Sakura Blossom'),
('en', 'presentation.theme.cyberpunk.label', 'presentation', 'Neo Cyberpunk'),
('en', 'presentation.theme.coffee.label', 'presentation', 'Artisan Coffee'),
('en', 'presentation.theme.aurora.label', 'presentation', 'Boreal Aurora'),
('id', 'presentation.theme.dark.label', 'presentation', 'Dark Neon'),
('id', 'presentation.theme.midnight.label', 'presentation', 'Midnight Indigo'),
('id', 'presentation.theme.emerald.label', 'presentation', 'Emerald Modern'),
('id', 'presentation.theme.sunset.label', 'presentation', 'Sunset Glow'),
('id', 'presentation.theme.ocean.label', 'presentation', 'Ocean Deep'),
('id', 'presentation.theme.ruby.label', 'presentation', 'Ruby Noir'),
('id', 'presentation.theme.gold.label', 'presentation', 'Royal Gold'),
('id', 'presentation.theme.arctic.label', 'presentation', 'Arctic Light'),
('id', 'presentation.theme.lavender.label', 'presentation', 'Lavender Amethyst'),
('id', 'presentation.theme.cream.label', 'presentation', 'Editorial Cream'),
('id', 'presentation.theme.monochrome.label', 'presentation', 'Bauhaus Slate'),
('id', 'presentation.theme.forest.label', 'presentation', 'Forest Botanical'),
('id', 'presentation.theme.sakura.label', 'presentation', 'Sakura Blossom'),
('id', 'presentation.theme.cyberpunk.label', 'presentation', 'Neo Cyberpunk'),
('id', 'presentation.theme.coffee.label', 'presentation', 'Artisan Coffee'),
('id', 'presentation.theme.aurora.label', 'presentation', 'Boreal Aurora')
ON CONFLICT (lang, key) DO UPDATE SET text = EXCLUDED.text, updated_ts = NOW();
