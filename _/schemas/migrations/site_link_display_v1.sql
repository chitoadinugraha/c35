-- Per-link guest display: list | icon | card
ALTER TABLE site.link
    ADD COLUMN IF NOT EXISTS display TEXT NOT NULL DEFAULT 'list';
