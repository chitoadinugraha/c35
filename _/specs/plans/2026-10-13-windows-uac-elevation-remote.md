# Windows UAC elevation — near-term implementation plan (draft)

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans when this track is scheduled.
>
> **Future / alternate approaches** (signed fork, RDP, spacedesk, broker-only, fleet GPO): documented in [_/specs/remote-windows-uac-future-options.md](../remote-windows-uac-future-options.md) — **not** part of this plan's scope unless product re-prioritizes.

**Goal (when scheduled):** Unattended + Remote sessions — FakerInput silent install, HID input path, elevation detection, `RemoteSessionPush` fields, Flutter banner, honest capture during elevation.

**Architecture:** `elevation_watch` + `notify_elevation_state` + optional FakerInput in `input_exec`; see full task breakdown in git history or re-expand this file when execution starts.

**Status:** **Draft / backlog** — options catalog is authoritative for long-term; implement this plan only after explicit product go-ahead.

## Waves (summary)

| Wave | Content |
|------|---------|
| Y0 | `remote.md` UAC subsection + links |
| Y1 | FakerInput bundle + silent install |
| Y2 | FakerInput `input_exec` |
| Y3 | `elevation_watch` |
| Y4 | Proto + WebRTC push |
| Y5 | Capture policy during elevation |
| Y6 | Flutter Remote banner |
| Y7 | Task / `device.screenshot` elevation metadata |
| Y8 | Dev scripts + `publish_remote_agent` |

Wire (locked when built): `RemoteSessionPush.elevation_prompt_active`, `elevation_since_ms`, `fakerinput_ready`.
