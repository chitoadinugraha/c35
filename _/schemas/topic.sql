-- ==============================================================================
-- c35 — Chat topics (persona + tool eligibility context)
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.topic (
    id              TEXT PRIMARY KEY,
    label_key       TEXT NOT NULL,
    inst            TEXT NOT NULL DEFAULT '',
    extend          TEXT NOT NULL DEFAULT '',
    sort            INT NOT NULL DEFAULT 0,
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    def_hash        TEXT NOT NULL DEFAULT '',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_topic_enabled_sort
    ON ai.topic (enabled, sort ASC, id ASC);

-- Seed: default chat topic
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'general',
    'topic.general.label',
    'You are a helpful, concise assistant. Answer clearly and ask clarifying questions when needed.',
    '',
    0,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: business channel bot (WhatsApp / Telegram customer bots)
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'bot',
    'topic.bot.label',
    'You are a business channel assistant. Follow the owner instructions at the top of the system prompt. Help customers with this business only — menu, orders, hours, location, policies, and related questions. Stay concise and polite.',
    'general',
    5,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.topic SET
    inst = 'You are a business channel assistant. Follow the owner instructions at the top of the system prompt. Help customers with this business only — menu, orders, hours, location, policies, and related questions. Stay concise and polite.',
    extend = 'general',
    sort = 5,
    updated_ts = NOW()
WHERE id = 'bot';

-- Seed: deep research topic
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'research',
    'topic.research.label',
    'Deep research mode: gather multiple sources with web.search, read key pages with web.visit, and synthesize a thorough answer with citations.',
    'general',
    10,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: image generation topic
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'image',
    'topic.image.label',
    'Image mode: when the user wants new visuals, call img.generate with a rich English prompt and suitable aspect ratio. When the user attaches an image to edit, call img.edit instead.',
    'general',
    20,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Seed: paired device topic (@device mention → remote PC facts via tools)
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'device',
    'topic.device.label',
    'Remote device questions use tools on the mentioned PC — shell output and screenshots — not guesses. Pass device_iid from mention targets.',
    'general',
    25,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

UPDATE ai.topic SET
    inst = 'Remote device questions use tools on the mentioned PC — shell output and screenshots — not guesses. Pass device_iid from mention targets.',
    label_key = 'topic.device.label',
    extend = 'general',
    sort = 25,
    updated_ts = NOW()
WHERE id = 'device';

-- Seed: remote browser topic (type=browser paired agent — Playwright, no desktop shell)
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'browser',
    'topic.browser.label',
    'Remote browser automation on a paired type=browser agent. Use browser.* tools (task.run, tabs, page.extract, page.act) — never shell.run, device.screenshot, device.input, computer_use.delegate, or device.fs.*. Pass device_iid from mention targets; use slot_id for persistent pages and tab_id when switching tabs. For captcha or 2FA, tell the user to complete it on the Remote tab — do not use device.input.',
    'device',
    26,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    label_key = EXCLUDED.label_key,
    extend = EXCLUDED.extend,
    sort = EXCLUDED.sort,
    updated_ts = NOW();

-- Seed: Google Sheets in Chrome extension (browser.sheets.* tools; not general device.input)
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'sheets',
    'topic.sheets.label',
    'Google Sheets in Chrome extension remote browser. Read only browser.sheets.range_read; write cell_set / append_row. device_iid + tab_id. Bot-attached API sheets: gsheet.*. Other sites: device.input.',
    'browser',
    27,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    label_key = EXCLUDED.label_key,
    extend = EXCLUDED.extend,
    sort = EXCLUDED.sort,
    updated_ts = NOW();

-- Seed: computer use topic (desktop automation subagent)
INSERT INTO ai.topic (
    id, label_key, inst, extend, sort, def_hash, updated_ts
) VALUES (
    'computer_use',
    'topic.computer_use.label',
    'Scale and plan first: state goal, data sources, join keys, and estimated row count (read pagination or export UI if unknown). If work is repetitive or more than a few dozen rows, do not UI-search row by row — prefer bulk extract (export, API, or scripted download via shell.run), join or transform locally, then bulk load (CSV import, spreadsheet API, paste import). Use device.input only for login, navigation, one-time export, or captcha; use shell.run for scripts. Pilot on a small sample and report match rate before a full batch. Row-by-row UI lookup is last resort only when no export, API, or scripted path exists — then tell the user scale limits and still minimize clicks. Desktop automation: always screenshot first, use SoM when stuck, verify each action, stop after 2 identical errors. Coordinates for device.input are normalized from 0.0 to 1.0 (top-left is 0.0, 0.0) across the desktop span. Use event_type=''double_click'' to open desktop apps or files. Use event_type=''shortcut'' with text (e.g. ''win+r'', ''ctrl+c'', ''alt+tab'') for hotkeys. Always verify outcomes with device.screenshot or screenshot_after=true.',
    'general',
    30,
    'seed',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Refresh computer_use persona on existing clusters (INSERT above is no-op when row exists)
UPDATE ai.topic SET
    inst = 'Scale and plan first: state goal, data sources, join keys, and estimated row count (read pagination or export UI if unknown). If work is repetitive or more than a few dozen rows, do not UI-search row by row — prefer bulk extract (export, API, or scripted download via shell.run), join or transform locally, then bulk load (CSV import, spreadsheet API, paste import). Use device.input only for login, navigation, one-time export, or captcha; use shell.run for scripts. Pilot on a small sample and report match rate before a full batch. Row-by-row UI lookup is last resort only when no export, API, or scripted path exists — then tell the user scale limits and still minimize clicks. Desktop automation: always screenshot first, use SoM when stuck, verify each action, stop after 2 identical errors. Coordinates for device.input are normalized from 0.0 to 1.0 (top-left is 0.0, 0.0) across the desktop span. Use event_type=''double_click'' to open desktop apps or files. Use event_type=''shortcut'' with text (e.g. ''win+r'', ''ctrl+c'', ''alt+tab'') for hotkeys. Always verify outcomes with device.screenshot or screenshot_after=true.',
    updated_ts = NOW()
WHERE id = 'computer_use';
