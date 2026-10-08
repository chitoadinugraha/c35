# YouTube transcript (presentation sources)

Status: draft 2026-09-28

## Flow

1. User supplies YouTube URL in presentation flow.
2. **structure** (`presentation.source.video_structure` or enrich `presentation.youtube`): chapters + duration, no full transcript.
3. User picks chapters or `start_sec` / `end_sec`.
4. **extract** (`presentation.source.video_extract`): bounded caption text for outline/slides.

## Fetch order

1. Cache row `ai.youtube_transcript_cache`
2. **yt-dlp** subs only (`--skip-download`) via `ALIENAI_PROXY_CF_URL`
3. **YouTube Data API** captions when OAuth channel owns video (stub until linked)

## Ops

- Runtime image includes `yt-dlp` (`_/deployments/Dockerfile`).
- Env: `YTDLP_BIN`, `ALIENAI_PROXY_CF_URL`.

Plan: `_/specs/plans/2026-09-28-youtube-transcript-multitask.md`.
