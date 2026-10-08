# YouTube transcript (yt-dlp default, API fallback) - Multitask Plan

> **For agentic workers:** One `Task` per track in parallel waves. Subagent `model`: **inherit** only.

**Goal:** Ingest user YouTube URLs for presentations with token-safe flow: structure (chapters/titles + timestamps) first, scoped text after user picks chapters or a time range (same pattern as PDF `presentation.source.*`).

**Architecture:** New `mod_youtube` crate: URL to `video_id`, **yt-dlp** subs-only via **CF proxy** (`ALIENAI_PROXY_CF_URL`), segments + chapters, cache in **CAS + YB**. Tools `presentation.source.video_structure` / `video_extract` + `inst.presentation` + enrich. **YouTube Data API** captions only when OAuth proves the user owns the channel (fallback after yt-dlp fails).

**Tech Stack:** Rust (`mod_youtube`, `mod_chat`), `yt-dlp` in cluster image, YB, CAS, `inst` Type B.

**Related:** PDF path in `servers/crates/mod_chat/src/pdf_cas/` and `_/schemas/inst.sql` `inst.presentation`.

## Global Constraints

- Read `spec.md` and `_/specs/inst.md` before coding.
- Default: yt-dlp `--skip-download --write-sub --write-auto-sub`.
- Cluster egress: `HTTP_PROXY` / `HTTPS_PROXY` from `ALIENAI_PROXY_CF_URL` (see `mod_chat::tools::egress_http`).
- Google API: direct to Google, no WARP; `captions.download` only for owned videos.
- Extract cap: default 14k chars, max 32k (match PDF).
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_youtube` / `c35_mod_chat`.
- Deploy server via `publish_server.ps1` (arm64 buildkit). Add `yt-dlp` to runtime image.

---

## Multitask Map

```
Track 0 (Schema)     --> Track 2 (cache)
Track 1 (mod_youtube) --> Track 2, 3, 4
Track 2 + 4           --> Track 5 (tools + enrich)
Track 5               --> Track 6 (inst)
Track 2               --> Track 7 (docker yt-dlp)
All                   --> Track 8 (tests + doc)
```

| Track | Focus | Depends |
|-------|-------|---------|
| 0 | DDL `ai.youtube_transcript_cache` | - |
| 1 | `mod_youtube` URL parse, VTT/SRT segments | - |
| 2 | yt-dlp subprocess + proxy + cache write | 0, 1 |
| 3 | Official API fallback (OAuth + owned video) | 0, 1 |
| 4 | Chapters: yt-dlp JSON + description timestamps | 1 |
| 5 | Tools + `inst_enrich` | 2, 4 |
| 6 | `inst.presentation` seed | 5 |
| 7 | Docker arm64: install yt-dlp | 2 |
| 8 | Tests, `_/specs/youtube-transcript.md` | all |

### Waves

| Wave | Parallel tracks | Done when |
|------|-----------------|-----------|
| 1 | 0, 1, 4 (4 after 1 types) | DDL + parser tests pass |
| 2 | 2, 3 | yt-dlp returns segments in dev; API mocked |
| 3 | 5, 7 | Tools registered; image has yt-dlp |
| 4 | 6, 8 | `prompt_compose` shows inst + video tools |

---

## Track 0 - Schema

**Files:** `_/schemas/youtube_transcript.sql`, `servers/crates/store/src/schema.rs`

```sql
CREATE TABLE IF NOT EXISTS ai.youtube_transcript_cache (
    video_id TEXT NOT NULL,
    lang TEXT NOT NULL DEFAULT 'en',
    track_kind TEXT NOT NULL DEFAULT 'auto',
    source TEXT NOT NULL DEFAULT 'yt_dlp',
    title TEXT NOT NULL DEFAULT '',
    duration_sec INT NOT NULL DEFAULT 0,
    chapters_json JSONB NOT NULL DEFAULT '[]',
    segments_json JSONB NOT NULL DEFAULT '[]',
    vtt_hash TEXT NOT NULL DEFAULT '',
    fetched_ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (video_id, lang, track_kind)
);
```

- [ ] Add SQL + schema.rs
- [ ] Apply on dev YB
- [ ] `cargo build -p server_ai`

---

## Track 1 - mod_youtube core

**Files:** `servers/crates/mod_youtube/` (`url.rs`, `caption.rs`, `lib.rs`), workspace member, `mod_chat` dependency.

Types: `Segment { start_sec, end_sec, text }`, `Chapter { title, start_sec }`, `VideoStructure { video_id, title, duration_sec, chapters, lang, track_kind }`.

- [ ] URL tests: watch, youtu.be, shorts
- [ ] VTT fixture tests
- [ ] `cargo test -p c35_mod_youtube`

---

## Track 2 - yt-dlp (primary)

**Files:** `mod_youtube/src/ytdlp.rs`, `cache.rs`

- Subprocess: `YTDLP_BIN` (default `yt-dlp`), timeout 90s
- Proxy env from `ALIENAI_PROXY_CF_URL`
- `youtube_transcript_fetch(pool, url)` -> cache upsert + CAS VTT

- [ ] Wrapper + error mapping (no subs, blocked, timeout)
- [ ] `#[ignore]` integration test with `YOUTUBE_TEST_URL`

---

## Track 3 - API fallback

**Files:** `mod_youtube/src/api_captions.rs`

- Run only if yt-dlp failed and OAuth channel owns video
- `captions.list` (50 units) + `captions.download` (200 units)
- Same VTT parser; `source = youtube_api`

- [ ] Mock HTTP tests
- [ ] `not_configured` when no OAuth

---

## Track 4 - Structure without full text

**Files:** `mod_youtube/src/structure.rs`

1. yt-dlp `--dump-json` for chapter metadata
2. Description regex timestamps
3. Optional synthetic 5-min buckets (`synthetic: true`)

`video_structure` returns chapters + duration only.

---

## Track 5 - Tools and enrich

**Files:** `mod_chat/src/video_source.rs`, register in `presentation_export.rs` or new tool file, `inst_enrich.rs`, `tools/mod.rs`

| Tool | Args | Returns |
|------|------|---------|
| `presentation.source.video_structure` | `url` or `video_id` | chapters, duration, title |
| `presentation.source.video_extract` | `video_id`, `start_sec`, `end_sec`, `max_chars?` | bounded text |

Enrich key: `presentation.youtube` (structure only; timeout 2s or cache-only).

---

## Track 6 - inst.presentation

**Files:** `_/schemas/inst.sql`

- Step 0: ask for YouTube link; if enrich present, show chapters
- Step 1: user picks chapters or time range; call `video_extract` before outline
- `include_tools`: add both video tools

- [ ] `prompt_compose` on `buat presentasi` + sample URL

---

## Track 7 - Container

- Install `yt-dlp` in server runtime image (arm64)
- Confirm `ALIENAI_PROXY_CF_URL` on `c35-server` deployment
- `publish_server.ps1` after merge

---

## Track 8 - Acceptance

- [ ] Structure for public URL (manual test)
- [ ] Extract scoped range under char cap
- [ ] Cache hit avoids second yt-dlp
- [ ] PDF + YouTube same inst thread
- [ ] Doc `_/specs/youtube-transcript.md`

## Out of scope

STT audio fallback, non-YouTube hosts, Flutter chapter picker UI, fetcher pre-warm cron.

## Risks

| Risk | Mitigation |
|------|------------|
| yt-dlp breakage | Pin version; owned-video API fallback |
| Proxy block | Log stderr; ops alert |
| Compose slow | Enrich cache-only / short timeout |

## Agent dispatch

```
Wave 1: track-0-schema, track-1-mod-youtube, track-4-chapters
Wave 2: track-2-ytdlp, track-3-api-fallback
Wave 3: track-5-tools, track-7-docker
Wave 4: track-6-inst, track-8-verify
```
