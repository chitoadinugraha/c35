# Site guest renderer version

Mirrored from [`.cursor/rules/site-guest-renderer-version.mdc`](../../.cursor/rules/site-guest-renderer-version.mdc).

Bump `GUEST_RENDERER_VERSION` in `servers/crates/mod_site/src/guest_renderer.rs` by +1 when guest compile output changes — not on every server deploy. Cluster key: `ai.config` `site.guest_renderer_version`. Per site: `site.config.guest_render_version` (0 until compiled at current generation). Lazy regen on first published guest visit when site version lags cluster.
