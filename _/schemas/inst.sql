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
    include_tools   TEXT[] NOT NULL DEFAULT '{}',
    exclude_tools   TEXT[] NOT NULL DEFAULT '{}',
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

ALTER TABLE ai.inst ADD COLUMN IF NOT EXISTS include_tools TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE ai.inst ADD COLUMN IF NOT EXISTS exclude_tools TEXT[] NOT NULL DEFAULT '{}';

-- Seed: platform baseline assistant (every turn)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.core.assistant',
    'global',
    'trigger',
    '',
    'You are Alien AI, a personal cloud assistant. Use web_search for live lookups via SearXNG. Answer concisely in the user''s language. Never claim you searched unless the tool returned ok=true. Only call a tool when it clearly matches the user''s request. Never call img.generate unless the user explicitly asks to create, draw, or generate a new image — never to analyze, estimate, or describe an attached photo. When the user attaches an image and explicitly asks to edit, modify, retouch, or change it, call img.edit (not img.generate). For food photos or calorie questions, use consumption.add with photo_hash or answer from the attached image directly; do not generate or edit images.',
    ARRAY[]::TEXT[],
    ARRAY['always'],
    200,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.inst SET
    inst = 'You are Alien AI, a personal cloud assistant. Use web_search for live lookups via SearXNG. Answer concisely in the user''s language. Never claim you searched unless the tool returned ok=true. Only call a tool when it clearly matches the user''s request. Never call img.generate unless the user explicitly asks to create, draw, or generate a new image — never to analyze, estimate, or describe an attached photo. When the user attaches an image and explicitly asks to edit, modify, retouch, or change it, call img.edit (not img.generate). For food photos or calorie questions, use consumption.add with photo_hash or answer from the attached image directly; do not generate or edit images.',
    triggers = ARRAY['always'],
    priority = 200,
    updated_ts = NOW()
WHERE id = 'inst.core.assistant';

-- Seed: web search steering (global)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.web_search',
    'global',
    'task',
    '',
    'Ground factual answers by calling the web.search tool (then web.visit when you need page text). Do not reply with plain-text search queries or [WEB] lines. Use for current events, prices, weather, cinema schedules, or anything that may have changed. When [USER LOCATION] is set and the question is local (weather, bioskop, terdekat, near me), include that city or region in the web.search query unless the user named a different place.',
    ARRAY['search', 'cari', 'googling', 'browse', 'latest', 'terbaru', 'kapan', 'weather', 'cuaca', 'harga', 'film', 'bioskop', 'tayang', 'jadwal', 'sekarang', 'nonton', 'cinema', 'jadwal nonton', 'apa yang', 'hari ini'],
    ARRAY['tool_include:web.search'],
    100,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.inst SET
    inst = 'Ground factual answers by calling the web.search tool (then web.visit when you need page text). Do not reply with plain-text search queries or [WEB] lines. Use for current events, prices, weather, cinema schedules, or anything that may have changed. When [USER LOCATION] is set and the question is local (weather, bioskop, terdekat, near me), include that city or region in the web.search query unless the user named a different place.',
    phrases = ARRAY['search', 'cari', 'googling', 'browse', 'latest', 'terbaru', 'kapan', 'weather', 'cuaca', 'harga', 'film', 'bioskop', 'tayang', 'jadwal', 'sekarang', 'nonton', 'cinema', 'jadwal nonton', 'apa yang', 'hari ini'],
    updated_ts = NOW()
WHERE id = 'inst.web_search';

-- Seed: @research mention steering
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.mention.research',
    'global',
    'mention',
    'research',
    '[MENTION: @research] Deep research mode: use web.search to discover sources, web.visit to read key pages, and web.research to synthesize a thorough answer with citations. For multi-part questions (compare, multi-region, or several independent sub-questions), call delegate.run with topic_id=research once per sub-question so children can run in parallel.',
    ARRAY[]::TEXT[],
    ARRAY['tool_include:web.research', 'tool_include:web.visit', 'tool_include:web.search', 'tool_include:delegate.run'],
    125,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: device read-only screen queries (screenshot only, no input/command)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.mention.device_read',
    'global',
    'task',
    'device',
    '[DEVICE READ] User wants to see what is on a remote device screen. Call device.screenshot only — do not send input or run shell commands.',
    ARRAY[
        'what''s on screen', 'whats on screen', 'what is on screen', 'show screen',
        'show me the screen', 'lihat layar', 'tampilkan layar', 'apa di layar'
    ],
    ARRAY['tool_include:device.screenshot', 'tool_exclude:device.input', 'tool_exclude:device.command'],
    128,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.inst SET
    inst = '[MENTION: @research] Deep research mode: use web.search to discover sources, web.visit to read key pages, and web.research to synthesize a thorough answer with citations. For multi-part questions (compare, multi-region, or several independent sub-questions), call delegate.run with topic_id=research once per sub-question so children can run in parallel.',
    triggers = ARRAY['tool_include:web.research', 'tool_include:web.visit', 'tool_include:web.search', 'tool_include:delegate.run'],
    updated_ts = NOW()
WHERE id = 'inst.mention.research';

-- Seed: @image-high mention steering (always Flash Image hd tier)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.mention.image_high',
    'global',
    'mention',
    'image_high',
    '[MENTION: @image-high] Always use img.generate or img.edit with quality=hd. Server routes to Gemini Flash Image at 2K. Use for logos, posters, text-in-image, and pro-quality output.',
    ARRAY[]::TEXT[],
    ARRAY['tool_include:img.generate', 'tool_include:img.edit'],
    130,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.inst SET
    inst = '[MENTION: @image-high] Always use img.generate or img.edit with quality=hd. Server routes to Gemini Flash Image at 2K. Use for logos, posters, text-in-image, and pro-quality output.',
    triggers = ARRAY['tool_include:img.generate', 'tool_include:img.edit'],
    updated_ts = NOW()
WHERE id = 'inst.mention.image_high';

-- Seed: research multitask via delegate.run
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.task.delegate_research',
    'global',
    'task',
    'research',
    '[RESEARCH MULTITASK] When the user asks to compare options, cover multiple regions, or answer several independent research questions in one message, spawn one delegate.run child per sub-question with topic_id=research and a focused goal. Synthesize the child summaries into one answer with citations.',
    ARRAY[
        'compare', 'vs', 'versus', 'bandingkan', 'perbandingan',
        'multi region', 'multi-region', 'beberapa kota', 'several cities',
        'rust vs go', 'jakarta', 'singapore', 'tokyo'
    ],
    ARRAY['tool_include:delegate.run'],
    128,
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
    '[IMAGE GENERATION] When the user asks to generate, create, draw, paint, or render a new image from scratch, call img.generate with an expanded English visual prompt and aspect_ratio. Default tier is Flash-Lite (quality draft). Use quality=hd for logos, posters, or text-in-image, or when @image-high is active. When img.generate succeeds, display: ![<short title>](https://f.alienai.id/fs/<file_hash>). Never use img.generate to edit an attached photo — use img.edit.',
    ARRAY[
        'buat gambar', 'buatkan gambar', 'bikin gambar', 'generate image', 'create image',
        'draw ', 'lukis', 'illustration', 'buat logo', 'buat icon', 'render image'
    ],
    ARRAY['tool_include:img.generate'],
    140,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: image editing task steering
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.task.img_edit',
    'global',
    'task',
    '',
    '[IMAGE EDIT] When the user attaches an image and asks to modify, edit, retouch, remove background, change colors, add/remove objects, or restyle it, call img.edit (not img.generate). Pass source_hash from the attachment hash or explicit hash. Use an expanded English edit prompt. When img.edit succeeds, display the result with markdown: ![<short title>](https://f.alienai.id/fs/<file_hash>).',
    ARRAY[
        'edit this', 'edit gambar', 'ubah gambar', 'remove background', 'hapus background',
        'change background', 'ganti background', 'retouch', 'edit foto', 'modify image'
    ],
    ARRAY['tool_include:img.edit', 'tool_exclude:img.generate'],
    145,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.inst SET
    inst = '[IMAGE EDIT] When the user attaches an image and asks to modify, edit, retouch, remove background, change colors, add/remove objects, or restyle it, call img.edit (not img.generate). Pass source_hash from the attachment hash or explicit hash. Use an expanded English edit prompt. When img.edit succeeds, display the result with markdown: ![<short title>](https://f.alienai.id/fs/<file_hash>).',
    phrases = ARRAY[
        'edit this', 'edit gambar', 'ubah gambar', 'remove background', 'hapus background',
        'change background', 'ganti background', 'retouch', 'edit foto', 'modify image'
    ],
    triggers = ARRAY['tool_include:img.edit', 'tool_exclude:img.generate'],
    priority = 145,
    updated_ts = NOW()
WHERE id = 'inst.task.img_edit';

-- Seed: food consumption logging (personal assistant)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.consumption_add',
    'role:personal_assistant',
    'task',
    '',
    '[FOOD] User wants to log food consumption. Call consumption.add when a photo or description is available. \
When the user asks how many calories are in an attached food photo, call consumption.add with photo_hash (or answer from the attached image) — never img.generate. \
The meal card displays structured details. As personal companion, reply warmly and naturally in 1-2 conversational sentences: \
- NEVER use robotic confirmations like "Konsumsi ... Anda telah berhasil dicatat". \
- If repeat_food_today is true: playfully notice the repeat (e.g. "Makan Indomie lagi nih? Piring kedua hari ini ya 😄 Jangan lupa air putih ya!"). \
- If pct_of_goal > 85% or over budget: praise the food but give a gentle friendly nudge about today''s calories (e.g. "Nasi gorengnya kelihatan lezat! Tapi hati-hati hari ini sudah masuk sekian kalori, nanti malam cari yang enteng ya."). \
- If well within budget: give an encouraging, cheerful reaction praising the meal.',
    ARRAY[
        'catat konsumsi', 'catat makanan', 'catat konsumsi makanan',
        'track food', 'log meal', 'track food consumption',
        'berapa kalori', 'how many calories', 'kalori makanan', 'kalori makanan ini', 'calories in this'
    ],
    ARRAY['tool_include:consumption.add', 'tool_exclude:img.generate', 'tool_exclude:img.edit'],
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
    '[NUTRITION COACH & RECOMMENDATIONS] \
When the user asks for food recommendations (e.g. "enaknya makan apa", "rekomendasi makan", "what should I eat", "makan apa ya"), daily recap, or historical nutrition queries: \
1. Always call consumption.today first. For meal recommendations, pass days: 3 to inspect recent multi-day eating patterns. \
2. Structure 2-3 tailored meal recommendations based on: \
   - current_meal_slot (breakfast / lunch / dinner / snack) \
   - calories_remaining (ensure recommended options comfortably fit within today''s remaining calorie budget) \
   - protein_deficit_g and macro balance (if carbs/fat are high and protein is low, prioritize high-protein, fresh options) \
   - recent_frequent_foods (avoid recommending items the user has already eaten frequently in the past few days; suggest complementary variety like vegetables/soup). \
3. Deliver the recommendation warmly in the user language with conversational wit, specifying estimated calories, protein, and why it fits today. \
Do not call img.generate for nutrition questions.',
    ARRAY[
        'enaknya makan apa', 'makan apa ya', 'mau makan apa', 'saran makan',
        'makan malam apa', 'sarapan apa', 'makan siang apa', 'rekomendasi makanan',
        'rekomendasi makan', 'food recommendation', 'what should i eat', 'apa yang harus dimakan',
        'nutrition recap', 'ringkasan nutrisi',
        'berapa banyak', 'how much', 'kemarin', 'yesterday', 'mie', 'noodle', 'nasi'
    ],
    ARRAY['tool_include:consumption.today', 'tool_exclude:img.generate'],
    135,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Keep live DB in sync with tightened food / image tool steering.
UPDATE ai.inst SET
    inst = '[FOOD] User wants to log food consumption. Call consumption.add when a photo or description is available. When the user asks how many calories are in an attached food photo, call consumption.add with photo_hash (or answer from the attached image) — never img.generate. The meal card shows nutrition details — your reply is the only warm coach text (do not repeat the card headline). Reply in 1-2 natural sentences in the user language. NEVER use robotic confirmations like "Konsumsi ... telah berhasil dicatat" or repeat the headline verbatim. Use meal_hints (high_sodium, high_fat, high_kcal, high_sugar), items macros, daily, weekly, recent_meal_names, repeat_count_today: when meal_hints.high_sodium, mention sodium gently (e.g. natriumnya agak tinggi, perbanyak air putih); if repeat_food_today or repeat_count_today > 1, gently note the repeat; if pct_of_goal > 85% or over budget, nudge lightly on remaining calories; otherwise react to the food specifically.',
    phrases = ARRAY[
        'catat konsumsi', 'catat makanan', 'catat konsumsi makanan',
        'track food', 'log meal', 'track food consumption',
        'berapa kalori', 'how many calories', 'kalori makanan', 'kalori makanan ini', 'calories in this'
    ],
    include_tools = ARRAY['consumption.add'],
    exclude_tools = ARRAY['img.generate'],
    triggers = '{}',
    updated_ts = NOW()
WHERE id = 'inst.consumption_add';

UPDATE ai.inst SET
    inst = '[NUTRITION COACH & RECOMMENDATIONS] When the user asks what they ate (food history / recap: "apa aja yang aku makan", hari ini, kemarin, minggu lalu, riwayat makan, what did I eat): MUST call consumption.today first — never claim you lack access without calling the tool. For meal recommendations (e.g. "enaknya makan apa", "rekomendasi makan", "what should I eat"): call consumption.today first with days: 3 to inspect recent patterns, then give 2-3 tailored suggestions using current_meal_slot, calories_remaining, protein_deficit_g, and recent_frequent_foods. Reply warmly in the user language. Do not call img.generate for nutrition questions.',
    phrases = ARRAY[
        'apa aja yang aku makan', 'apa yang aku makan', 'makan hari ini', 'riwayat makan',
        'minggu lalu', 'what did i eat', 'food history', 'meal recap',
        'enaknya makan apa', 'makan apa ya', 'mau makan apa', 'saran makan',
        'makan malam apa', 'sarapan apa', 'makan siang apa', 'rekomendasi makanan',
        'rekomendasi makan', 'food recommendation', 'what should i eat', 'apa yang harus dimakan',
        'nutrition recap', 'ringkasan nutrisi',
        'berapa banyak', 'how much', 'kemarin', 'yesterday', 'mie', 'noodle', 'nasi'
    ],
    include_tools = ARRAY['consumption.today'],
    exclude_tools = ARRAY['img.generate'],
    triggers = '{}',
    updated_ts = NOW()
WHERE id = 'inst.consumption_coach';

-- Backfill include_tools / exclude_tools from legacy tool_include:/tool_exclude: triggers
UPDATE ai.inst SET
    include_tools = COALESCE(
        (SELECT array_agg(substring(t FROM 14) ORDER BY t)
         FROM unnest(triggers) AS t WHERE t LIKE 'tool_include:%'),
        '{}'::text[]
    ),
    exclude_tools = COALESCE(
        (SELECT array_agg(substring(t FROM 14) ORDER BY t)
         FROM unnest(triggers) AS t WHERE t LIKE 'tool_exclude:%'),
        '{}'::text[]
    )
WHERE cardinality(include_tools) = 0
  AND cardinality(exclude_tools) = 0
  AND EXISTS (
      SELECT 1 FROM unnest(triggers) AS t
      WHERE t LIKE 'tool_include:%' OR t LIKE 'tool_exclude:%'
  );

UPDATE ai.inst SET triggers = COALESCE(
    (SELECT array_agg(t ORDER BY t)
     FROM unnest(triggers) AS t
     WHERE t NOT LIKE 'tool_include:%' AND t NOT LIKE 'tool_exclude:%'),
    '{}'::text[]
)
WHERE EXISTS (
    SELECT 1 FROM unnest(triggers) AS t
    WHERE t LIKE 'tool_include:%' OR t LIKE 'tool_exclude:%'
);

-- Seed: food consumption deletion / cancel
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.consumption_delete',
    'role:personal_assistant',
    'task',
    '',
    '[FOOD] User wants to delete or cancel a logged food consumption entry. Call consumption.delete with consumption_id if known, or without arguments to cancel the most recent meal today. Do not call img.generate.',
    ARRAY[
        'hapus catatan makan', 'hapus makanan', 'batal catat makan', 'hapus log makan',
        'delete meal', 'cancel meal', 'remove food log', 'delete food'
    ],
    ARRAY['tool_include:consumption.delete', 'tool_exclude:img.generate'],
    140,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: expense tracking & amount normalization (personal assistant)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.expense_add',
    'role:personal_assistant',
    'task',
    '',
    '[EXPENSE] User wants to log an expense or purchase. Call expense.add with line items, quantity, and amount (personal ledger: owner_iid = caller). \
[AMOUNT INFERENCE] Infer realistic IDR major units: small numbers for food/daily items mean thousands (18 → 18000, 6.5 → 6500), while electronics/rent mean millions (18 → 18000000, 2.5 → 2500000). Suffixes k/rb = ×1,000, jt/m = ×1,000,000. \
Reply briefly with recorded item, amount, and category — never invent prices.',
    ARRAY[
        'catat pengeluaran', 'track expense', 'beli ', 'bayar ', 'catat struk',
        'log expense', 'tambah pengeluaran', 'catat pembelian', 'pengeluaran baru'
    ],
    ARRAY['tool_include:expense.add', 'tool_exclude:img.generate'],
    138,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

-- Seed: expense spending queries (personal assistant)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.expense_query',
    'role:personal_assistant',
    'task',
    '',
    '[EXPENSE QUERY] User asks about spending, purchases, or expense totals. Call expense.summary. \
For today use day_id: today; for yesterday use day_id: yesterday; for a specific date use YYYY-MM-DD. \
For multi-day ranges (e.g. last week, past 7 days) pass days (1-30). \
For category filters (food, transport, groceries) pass category_path as taxonomy prefix (e.g. consumable.food for food/makanan). \
For item-specific searches pass item_query. Reply with totals and a brief warm summary — never invent amounts. Do not call img.generate.',
    ARRAY[
        'berapa pengeluaran', 'how much did i spend', 'pengeluaran hari ini', 'spend on food',
        'pengeluaran minggu lalu', 'total belanja', 'spending today', 'yesterday spending',
        'pengeluaran kemarin', 'how much on transport', 'pengeluaran makanan', 'belanja berapa',
        'expense summary', 'total pengeluaran', 'berapa belanja', 'how much did i spend on'
    ],
    ARRAY['tool_include:expense.summary', 'tool_exclude:img.generate'],
    137,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

-- Seed: site layout / theme editing via Home prompt
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.web.builder',
    'global',
    'mention',
    'web.builder',
    '[WEB.BUILDER] User is editing a site (layout, theme, blocks). Resolve site from @alien_id or site name. \
Use site_draft_put to change SiteDoc blocks and theme_json only — validate block props against known types. \
Use site_publish after substantive layout changes. For products/contacts/objects prefer site_product_put / site_contact_put or tell user to use Sites UITable. \
Catalog and tx writes are single-site only: one site_iid per call — default when exactly one site in [SITE CONTEXTS]; require explicit site_iid when multiple sites are mentioned. \
For sales reports, profit compare, or analytics across sites use site.query.run — not write tools. \
Never invent checkout, prices, or stock — use site.tx.put for money/stock mutations. Never mutate shared block catalog schemas.',
    ARRAY[
        'site', 'website', 'toko', 'warung', 'landing', 'homepage',
        'background', 'theme', 'layout', 'hero', 'publish site', 'ubah tampilan'
    ],
    ARRAY[
        'tool_include:site.draft_put',
        'tool_include:site.publish',
        'tool_include:site.product_put',
        'tool_include:site.contact_put'
    ],
    120,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    kind = EXCLUDED.kind,
    topic_id = EXCLUDED.topic_id,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

-- Seed: site commerce / POS topic steering
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.site.commerce',
    'global',
    'topic',
    'site.commerce',
    '[SITE.COMMERCE] User is working with POS / transactions on a site. \
Use site.tx.put for sales, purchases, and stock movements; site.tx.preview before finalize; site.tx.debt_pay for debt or installment payments. \
Writes require exactly one site_iid per call — default from [SITE CONTEXTS] only when one site is mentioned; pass site_iid explicitly when multiple sites. \
Never invent prices, stock, or totals — use tx tools only.',
    ARRAY[]::TEXT[],
    ARRAY[
        'tool_include:site.tx.put',
        'tool_include:site.tx.preview',
        'tool_include:site.tx.debt_pay'
    ],
    118,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    kind = EXCLUDED.kind,
    topic_id = EXCLUDED.topic_id,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

-- Seed: multi-site profit compare via query catalog
INSERT INTO ai.inst (
    id, scope, kind, topic_id, topics, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.site.compare',
    'global',
    'task',
    '',
    ARRAY['web.builder', 'site.commerce'],
    '[SITE.COMPARE] User wants to compare profitability or performance across mentioned sites. \
Call site.query.run with query_id tx.profit_summary and pass ALL site_iids from [SITE CONTEXTS]. \
Do not call write tools for compare — readonly query only. Summarize results side-by-side in the user language.',
    ARRAY['compare', 'lebih untung', 'which is more profitable'],
    ARRAY['tool_include:site.query.run'],
    129,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    topics = EXCLUDED.topics,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    kind = EXCLUDED.kind,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

-- Seed: site sales / report phrases via query catalog
INSERT INTO ai.inst (
    id, scope, kind, topic_id, topics, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.site.report',
    'global',
    'task',
    '',
    ARRAY['web.builder', 'site.commerce'],
    '[SITE.REPORT] User wants sales or transaction reports. \
Call site.query.run — use tx.sales_summary for revenue/sales, tx.profit_summary for profit. \
Pass all site_iids from [SITE CONTEXTS] (or the single default site when only one is mentioned). Readonly — never use write tools for reports.',
    ARRAY['laporan', 'report', 'sales today'],
    ARRAY['tool_include:site.query.run'],
    127,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    topics = EXCLUDED.topics,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    kind = EXCLUDED.kind,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

-- Seed: referral code create / update via Home prompt
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.referral_put',
    'global',
    'task',
    '',
    '[REFERRAL] User wants to create or update a referral or package code. Call referral.code.put with name as the label (e.g. Chito). \
Derive code from name when the user does not specify one. For package codes set type=package plus price_usd / duration_months / max_uses as needed. \
Reply briefly with the saved code and name — do not invent codes the tool did not return.',
    ARRAY[
        'buat referral code', 'buat kode referral', 'buatkan referral code',
        'create referral code', 'new referral code', 'referral code untuk',
        'kode referral untuk', 'referral code for', 'signup code untuk'
    ],
    ARRAY['tool_include:referral.code.put'],
    130,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: list / search referral codes via Home prompt
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.referral_list',
    'global',
    'task',
    '',
    '[REFERRAL] User wants to see their referral or package codes. Call referral.code.list first. \
Pass query when they filter by name or code substring. Summarize as a short list (code, name, used_count) in the user language.',
    ARRAY[
        'daftar referral code', 'daftar kode referral', 'list referral code',
        'list referral codes', 'lihat referral code', 'lihat kode referral',
        'referral codes saya', 'my referral codes', 'kode referral saya'
    ],
    ARRAY['tool_include:referral.code.list'],
    125,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: referral downline tree via Home prompt
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, priority, def_hash, updated_ts
) VALUES (
    'inst.referral_tree',
    'global',
    'task',
    '',
    '[REFERRAL] User asks about downline, referral tree, or who they referred. Call referral.tree.get. \
Use depth 2 unless they ask for deeper. Summarize node names and child_count — do not dump raw JSON.',
    ARRAY[
        'downline', 'referral tree', 'pohon referral', 'lihat downline',
        'siapa yang saya refer', 'my referrals', 'referral saya'
    ],
    ARRAY['tool_include:referral.tree.get'],
    120,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: presentation & slide deck builder workflow (clarify -> outline -> canvas -> export/build)
INSERT INTO ai.inst (
    id, scope, kind, topic_id, inst, phrases, triggers, include_tools, priority, def_hash, updated_ts
) VALUES (
    'inst.presentation',
    'global',
    'task',
    '',
    '[PRESENTATION] User wants to create a presentation, slide deck, pitch deck, or PowerPoint. \
Follow this strict 4-stage workflow: \
1. CLARIFY FIRST (GRILL-ME): Never output final slides on turn 1. Ask 2-4 clarifying questions to understand: target audience, core objective, desired tone, estimated number of slides, and any must-include metrics or data points. \
2. OUTLINE & BLUEPRINT: Once the user answers, formulate a slide-by-slide outline (Title, Core Message, and Layout/Visual cue for each slide). Ask: "Does this outline look good, or should we adjust any slide before staging on Canvas?" \
3. CANVAS STAGING: Once the user approves the outline, generate the complete slide deck into Canvas (kind: ''canvas.artifact'', language: ''slide'') with slides separated by ''---''. Include punchy headlines, structured bullet points, and speaker notes. Tell the user they can review and edit directly in the Canvas sidecar, or click ''Iterate with AI'' to refine. \
4. EXPORT & BUILD: Once the user is satisfied with the Canvas draft, ask which implementation they prefer: (a) Build directly on PC (if @Device / remote PC connected, via PowerPoint/Keynote or python-pptx), (b) Download as editable PPTX (call tool presentation.export with the markdown slides to generate the .pptx file), or (c) Export to Google Slides.',
    ARRAY[
        'presentation', 'presentasi', 'slide', 'slides', 'slide deck',
        'bikin slide', 'buat slide', 'bikin presentasi', 'buat presentasi',
        'pitch deck', 'powerpoint', 'keynote', 'deck', 'marp'
    ],
    ARRAY[]::TEXT[],
    ARRAY['presentation.export'],
    150,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    include_tools = EXCLUDED.include_tools,
    kind = EXCLUDED.kind,
    priority = EXCLUDED.priority,
    updated_ts = NOW();

