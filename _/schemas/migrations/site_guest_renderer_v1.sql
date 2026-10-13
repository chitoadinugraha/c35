-- Guest HTML compiler generation (lazy regen on first visit after bump).
-- Per-site: site.config.guest_render_version (0 = needs regen when cluster is 1+).
-- Cluster: ai.config site.guest_renderer_version {"version": N}

ALTER TABLE site.config
    ADD COLUMN IF NOT EXISTS guest_render_version INT NOT NULL DEFAULT 0;

INSERT INTO ai.config (key, value, updated_at)
VALUES ('site.guest_renderer_version', '{"version":1}', NOW())
ON CONFLICT (key) DO NOTHING;
