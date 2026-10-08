# Site preview card + draft URL — implementation plan

**Goal:** Slide-deck-style site card in chat, numeric site paths until handle claim, draft preview URLs, branded unpublished guest page.

## Waves (completed)

| Wave | Track | Deliverable |
|------|-------|-------------|
| 1 | Server `site.create` | Default `alien_id` = `site_iid` string; optional slug only when `alien_id` passed |
| 1 | Server preview | `preview_token` + `?draft=1&ptoken=` in tool block body |
| 1 | Guest HTTP | `draft=true` / `yes` accepted; resolve `/{numeric_id}` |
| 1 | Guest HTTP | `render_offline_html` branded unpublished page |
| 2 | Flutter card | Nav pills + hamburger menu; collapse `unfold_less`; draft Visit Site |
| 2 | Flutter wire | `ChatConn` → `UiMsgBlocks` → `UiSitePreviewCard` for token refresh |
| 3 | Ship | `publish_server.ps1`; `publish_app_release.ps1 -AndroidPromote` |

## Follow-up (not in scope)

- Handle claim / slug migration flow
- Live WebView preview in card (iframe token) per `site-builder.md`
- Hub block template default (`2026-10-03-site-hub-blocks-design-system.md`)
