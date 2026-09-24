-- ==============================================================================
-- c35 — Server-side catalog translations (tool / mention / topic UI labels)
-- Client shell i18n stays in assets; catalog keys download per locale.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

CREATE TABLE IF NOT EXISTS ai.translation (
    lang            VARCHAR(16) NOT NULL,
    key             VARCHAR(128) NOT NULL,
    category        VARCHAR(32) NOT NULL DEFAULT 'catalog',
    text            TEXT NOT NULL,
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (lang, key)
);

CREATE INDEX IF NOT EXISTS idx_translation_lang
    ON ai.translation (lang);

CREATE INDEX IF NOT EXISTS idx_translation_category
    ON ai.translation (category);

-- Seed English ('en') catalog translations
INSERT INTO ai.translation (lang, key, category, text) VALUES
-- tool.var.* (template fallbacks)
('en', 'tool.var.source', 'tool', 'source'),
('en', 'tool.var.query', 'tool', 'web'),
-- tool.web.search.*
('en', 'tool.web.search.calling', 'tool', 'Searching {{query}}…'),
('en', 'tool.web.search.done', 'tool', 'Searched {{query}}'),
-- tool.web.visit.*
('en', 'tool.web.visit.calling', 'tool', 'Reading {{source}}…'),
('en', 'tool.web.visit.done', 'tool', 'Read {{source}}'),
-- tool.web.research.*
('en', 'tool.web.research.calling', 'tool', 'Researching {{query}}…'),
('en', 'tool.web.research.done', 'tool', 'Researched {{query}}'),
-- tool.img.generate.*
('en', 'tool.img.generate.calling', 'tool', 'Generating image…'),
('en', 'tool.img.generate.done', 'tool', 'Generated image'),
('en', 'tool.img.edit.calling', 'tool', 'Editing image…'),
('en', 'tool.img.edit.done', 'tool', 'Edited image'),
-- tool.consumption.add.*
('en', 'tool.consumption.add.calling', 'tool', 'Logging food…'),
('en', 'tool.consumption.add.done', 'tool', 'Logged food'),
-- tool.consumption.today.*
('en', 'tool.consumption.today.calling', 'tool', 'Checking meals today…'),
('en', 'tool.consumption.today.done', 'tool', 'Checked meals today'),
-- tool.expense.add.*
('en', 'tool.expense.add.calling', 'tool', 'Logging expense…'),
('en', 'tool.expense.add.done', 'tool', 'Logged expense'),
-- tool.expense.summary.*
('en', 'tool.expense.summary.calling', 'tool', 'Checking spending…'),
('en', 'tool.expense.summary.done', 'tool', 'Checked spending'),
-- tool.expense.delete.*
('en', 'tool.expense.delete.calling', 'tool', 'Removing expense…'),
('en', 'tool.expense.delete.done', 'tool', 'Removed expense'),
-- mention.research.*
('en', 'mention.research.label', 'mention', 'Research'),
('en', 'mention.research.caption', 'mention', 'Deep web research'),
('en', 'mention.image_high.label', 'mention', 'Image HD'),
('en', 'mention.image_high.caption', 'mention', 'Pro Flash Image (2K)'),
-- mention.image.*
('en', 'mention.image.label', 'mention', 'Image'),
('en', 'mention.image.caption', 'mention', 'Generate an image'),
-- mention.memorize.*
('en', 'mention.memorize.label', 'mention', 'Memorize'),
('en', 'mention.memorize.caption', 'mention', 'Save a fact to memory'),
-- topic.general.*
('en', 'topic.general.label', 'topic', 'General'),
('en', 'topic.general.caption', 'topic', 'Default assistant'),
-- topic.research.*
('en', 'topic.research.label', 'topic', 'Research'),
('en', 'topic.research.caption', 'topic', 'Multi-source web research'),
-- topic.image.*
('en', 'topic.image.label', 'topic', 'Image'),
('en', 'topic.image.caption', 'topic', 'Image generation'),
('en', 'composer.ask.label', 'catalog', 'Ask'),
('en', 'composer.ask.caption', 'catalog', 'Answer without tools'),
('en', 'hint.consumption_add.label', 'hint', 'Track Consumption'),
('en', 'hint.consumption_add.send_text', 'hint', 'Track food consumption'),
('en', 'hint.expense_add.label', 'hint', 'Track Expense'),
('en', 'hint.expense_add.send_text', 'hint', 'Track expense'),
('en', 'hint.sites.more.label', 'hint', 'More'),
('en', 'hint.site.visit.label', 'hint', 'Visit'),
('en', 'hint.site.pos.label', 'hint', 'POS'),
-- Seed Indonesian ('id') catalog translations
('id', 'tool.var.source', 'tool', 'sumber'),
('id', 'tool.var.query', 'tool', 'web'),
('id', 'tool.web.search.calling', 'tool', 'Mencari {{query}}…'),
('id', 'tool.web.search.done', 'tool', 'Telusuri {{query}}'),
('id', 'tool.web.visit.calling', 'tool', 'Membaca {{source}}…'),
('id', 'tool.web.visit.done', 'tool', 'Baca {{source}}'),
('id', 'tool.web.research.calling', 'tool', 'Meneliti {{query}}…'),
('id', 'tool.web.research.done', 'tool', 'Teliti {{query}}'),
('id', 'tool.img.generate.calling', 'tool', 'Membuat gambar…'),
('id', 'tool.img.generate.done', 'tool', 'Gambar dibuat'),
('id', 'tool.img.edit.calling', 'tool', 'Mengedit gambar…'),
('id', 'tool.img.edit.done', 'tool', 'Gambar diedit'),
('id', 'tool.consumption.add.calling', 'tool', 'Mencatat makanan…'),
('id', 'tool.consumption.add.done', 'tool', 'Makanan tercatat'),
('id', 'tool.consumption.today.calling', 'tool', 'Mengecek makan hari ini…'),
('id', 'tool.consumption.today.done', 'tool', 'Makan hari ini dicek'),
('id', 'tool.expense.add.calling', 'tool', 'Mencatat pengeluaran…'),
('id', 'tool.expense.add.done', 'tool', 'Pengeluaran tercatat'),
('id', 'tool.expense.summary.calling', 'tool', 'Mengecek pengeluaran…'),
('id', 'tool.expense.summary.done', 'tool', 'Pengeluaran dicek'),
('id', 'tool.expense.delete.calling', 'tool', 'Menghapus pengeluaran…'),
('id', 'tool.expense.delete.done', 'tool', 'Pengeluaran dihapus'),
('id', 'mention.research.label', 'mention', 'Riset'),
('id', 'mention.research.caption', 'mention', 'Riset web mendalam'),
('id', 'mention.image_high.label', 'mention', 'Gambar HD'),
('id', 'mention.image_high.caption', 'mention', 'Flash Image pro (2K)'),
('id', 'mention.image.label', 'mention', 'Image'),
('id', 'mention.image.caption', 'mention', 'Buat gambar'),
('id', 'mention.memorize.label', 'mention', 'Ingat'),
('id', 'mention.memorize.caption', 'mention', 'Simpan ke memori'),
('id', 'topic.general.label', 'topic', 'Umum'),
('id', 'topic.general.caption', 'topic', 'Asisten default'),
('id', 'topic.research.label', 'topic', 'Riset'),
('id', 'topic.research.caption', 'topic', 'Riset web multi-sumber'),
('id', 'topic.image.label', 'topic', 'Gambar'),
('id', 'topic.image.caption', 'topic', 'Pembuatan gambar'),
('id', 'composer.ask.label', 'catalog', 'Tanya'),
('id', 'composer.ask.caption', 'catalog', 'Jawab tanpa alat'),
('id', 'hint.consumption_add.label', 'hint', 'Catat konsumsi makanan'),
('id', 'hint.consumption_add.send_text', 'hint', 'Catat konsumsi makanan'),
('id', 'hint.expense_add.label', 'hint', 'Catat Pengeluaran'),
('id', 'hint.expense_add.send_text', 'hint', 'Catat pengeluaran'),
('id', 'hint.sites.more.label', 'hint', 'Lainnya'),
('id', 'hint.site.visit.label', 'hint', 'Kunjungi'),
('id', 'hint.site.pos.label', 'hint', 'POS')
ON CONFLICT (lang, key) DO NOTHING;

-- Web tool label templates (refresh on deploy)
INSERT INTO ai.translation (lang, key, category, text) VALUES
('en', 'tool.var.source', 'tool', 'source'),
('en', 'tool.var.query', 'tool', 'web'),
('en', 'tool.web.search.calling', 'tool', 'Searching {{query}}…'),
('en', 'tool.web.search.done', 'tool', 'Searched {{query}}'),
('en', 'tool.web.visit.calling', 'tool', 'Reading {{source}}…'),
('en', 'tool.web.visit.done', 'tool', 'Read {{source}}'),
('en', 'tool.web.research.calling', 'tool', 'Researching {{query}}…'),
('en', 'tool.web.research.done', 'tool', 'Researched {{query}}'),
('id', 'tool.var.source', 'tool', 'sumber'),
('id', 'tool.var.query', 'tool', 'web'),
('id', 'tool.web.search.calling', 'tool', 'Mencari {{query}}…'),
('id', 'tool.web.search.done', 'tool', 'Telusuri {{query}}'),
('id', 'tool.web.visit.calling', 'tool', 'Membaca {{source}}…'),
('id', 'tool.web.visit.done', 'tool', 'Baca {{source}}'),
('id', 'tool.web.research.calling', 'tool', 'Meneliti {{query}}…'),
('id', 'tool.web.research.done', 'tool', 'Teliti {{query}}')
ON CONFLICT (lang, key) DO UPDATE SET text = EXCLUDED.text, updated_ts = NOW();
