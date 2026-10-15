# Multi-Task Implementation Plan: Canvas OCR Set-of-Mark & Eager Device Perception

> **Target:** Elevate Alien AI remote device computer use to human-like zero-turn perception and solve canvas blindness (Google Sheets, Figma, Flutter Web) with native OS-level OCR.
> **Date:** 2026-10-15
> **Status:** Draft / Ready for Execution

---

## 1. Executive Summary & Goals

1. **Zero-Turn Cold Start Elimination**: Enable eager desktop screenshot + Set-of-Mark (SoM) pre-fetching on prompt turn 0 when mentioning a device or running `computer_use.delegate`, eliminating the 2–4s round-trip penalty of the first `device.screenshot` tool call.
2. **Canvas Accessibility & Grounding (OCR-Augmented SoM)**: Add ultra-fast, zero-dependency WinRT OCR (`Windows.Media.Ocr.OcrEngine`) to `c_remote_windows`. When a window contains `<canvas>`, `<document>`, or sparse UIA trees, detect and badge text elements as `@N [CanvasText]` alongside native UIA controls.
3. **Seamless Debuggability**: Ensure `/som <device>` immediately visualizes both UIA and OCR marks with coordinate inspection and hit-test crosshairs.
4. **Strict Direct Input Enforcement**: Steer models via prompt instructions (`inst.sql`) to always batch inputs with `device.input` (`actions: [...]`, `click_and_type`) and never drop to slow, fragile `shell.run` scripts.

---

## 2. Architecture & Flow

```
                      User Prompt Turn (Mentions @device or computer_use)
                                             │
                       Is device online in cluster cache?
                                             │
                        ┌────────────────────┴────────────────────┐
                       YES                                        NO
                        │                                         │
        ┌───────────────▼────────────────┐               ┌────────▼────────┐
        │ Eager Capture over NATS        │               │ Fallback to     │
        │ (timeout: 500ms)               │               │ standard text   │
        └───────────────┬────────────────┘               └─────────────────┘
                        │
      ┌─────────────────▼──────────────────┐
      │ Remote Agent (c_remote_windows)    │
      │ 1. Capture screen buffer           │
      │ 2. Walk UIA tree for native items  │
      │ 3. If Canvas / sparse, run WinRT   │
      │    OcrEngine on target ROI (<20ms) │
      │ 4. Fuse marks & draw numbered tags │
      └─────────────────┬──────────────────┘
                        │
        ┌───────────────▼────────────────┐
        │ Inject into Turn 0 Observation │
        │ - Image in `inlineData`        │
        │ - Merged axtree in user prompt │
        └───────────────┬────────────────┘
                        │
        ┌───────────────▼────────────────┐
        │ LLM Turn 1: Immediate Action   │
        │ Calls `device.input` directly  │
        │ (No preliminary screenshot hop)│
        └────────────────────────────────┘
```

---

## 3. Parallel Tracks & Work Breakdown

### Track A: Remote Windows Native WinRT OCR Engine (`c_remote_windows`)
**Files:**
- Modify: `remotes/c_remote_windows/Cargo.toml`
- Create: `remotes/c_remote_windows/src/ocr.rs`
- Modify: `remotes/c_remote_windows/src/uia.rs`

**Tasks:**
- [ ] **A.1:** Enable `Media_Ocr`, `Graphics_Imaging`, and `Storage_Streams` features in `c_remote_windows/Cargo.toml` under `windows` dependencies.
- [ ] **A.2:** Implement `ocr.rs`:
  - Initialize `OcrEngine::TryCreateFromUserProfileLanguages()` or default language.
  - Expose `run_ocr_bgra(data: &[u8], width: u32, height: u32, bounds: Option<[i32; 4]>) -> Result<Vec<OcrToken>>`.
  - Benchmark execution to verify latency is <25ms on 1080p canvas regions.
- [ ] **A.3:** Add fallback handling: if OCR language packs are missing or fail, log debug and smoothly return empty tokens without crashing the capture loop.
- [ ] **A.4:** Verify compilation: `cd remotes && cargo check -p c_remote_windows`.

---

### Track B: SoM Mark Fusion & Canvas Bounding Detection (`c_remote_windows`)
**Files:**
- Modify: `remotes/c_remote_windows/src/uia.rs`
- Modify: `remotes/c_remote_windows/src/screen_capture.rs`

**Tasks:**
- [ ] **B.1:** Detect canvas/document ROI during `uia_walk`:
  - Identify controls where `control_type` is `Document`, `Pane`, or `Custom`, or where total actionable UIA controls are < 10.
  - Extract the canvas bounding rectangle.
- [ ] **B.2:** Fuse OCR marks with UIA marks:
  - Label OCR tokens as `@N CanvasText '<text>'`.
  - Filter out OCR marks that spatially overlap with existing UIA controls (deduplication).
  - Cap total marks (e.g. max 50) prioritized by actionability and canvas relevance.
- [ ] **B.3:** Update `screen_capture.rs` badge drawing:
  - Render numbered badge tags on OCR bounding centers in addition to UIA centers.
- [ ] **B.4:** Ensure `axtree_text` output outputs clean coordinate metadata for both UIA controls and canvas text:
  `@14 CanvasText 'Revenue' -> center=(0.245, 0.312) pixel=(314, 224) size=(64x18)`.

---

### Track C: Turn-0 Eager Screenshot & SoM Prefetch Expansion (`c35_mod_chat`)
**Files:**
- Modify: `servers/crates/mod_chat/src/prompt/device_screenshot_prefetch.rs`
- Modify: `servers/crates/mod_chat/src/prompt_turn.rs`
- Modify: `servers/crates/mod_chat/src/prompt/tool_loop.rs`

**Tasks:**
- [ ] **C.1:** Update `device_screenshot_prefetch_wanted` in `device_screenshot_prefetch.rs`:
  - Allow prefetch for `computer_use` run kind (currently blocked by `run_kind == "computer_use"`).
  - Enable `som = true` by default for device prefetch so visual tags and `axtree_text` are included on Turn 0.
- [ ] **C.2:** Optimize prefetch timeout & cluster caching:
  - Check `agent_cluster_online` before dispatching NATS screenshot request to avoid waiting on dead devices.
  - Enforce a 600ms timeout for eager capture; on timeout, proceed immediately to LLM without vision.
- [ ] **C.3:** Attach prefetched observation cleanly:
  - Inject the image into `inlineData` and append `axtree_text` to user turn prompt content.
  - Verify that `prune_previous_screenshots` in `tool_loop.rs` treats the prefetched image identically to tool responses on subsequent rounds.
- [ ] **C.4:** Verify compilation: `cargo check -p c35_mod_chat`.

---

### Track D: Cognitive Steering & Playbooks (`inst.sql` & `google_sheets.rs`)
**Files:**
- Modify: `_/schemas/inst.sql`
- Modify: `servers/crates/mod_chat/src/prompt/google_sheets.rs`

**Tasks:**
- [ ] **D.1:** Update `inst.device.operate` and `inst.computer_use` in `inst.sql`:
  - Instruct the model: *"You receive a Set-of-Mark visual observation with Canvas OCR on Turn 0. You do NOT need to call `device.screenshot` before your first action. Proceed directly to `device.input`."*
  - Emphasize direct input batching: *"Always use `device.input` with batch `actions: [...]` or `click_and_type`. Never use `shell.run` or PowerShell SendKeys for GUI interactions."*
- [ ] **D.2:** Update `google_sheets.rs`:
  - Update `GOOGLE_SHEETS_DESKTOP_PLAYBOOK` to guide the model on utilizing `[CanvasText]` tags to locate columns and headers, combined with `Ctrl+G` (Go to range) for cell selection.
- [ ] **D.3:** Refresh live database macro instructions (`inst_put` or migration sync).

---

### Track E: Verification, Golden Tests & Debug Harness
**Files:**
- Test scripts: `scripts/dev/prompt_device_form_loop.ps1`
- Test cases: `servers/crates/mod_chat/tests/`

**Tasks:**
- [ ] **E.1:** Test `/som <device>` manually on Windows with a Google Sheets or canvas window open:
  - Assert that column headers and cell values are identified with `@N CanvasText` badges.
  - Assert that `/som <device> mark <N>` correctly targets the OCR text box.
- [ ] **E.2:** Add unit tests in `mod_chat`:
  - Verify `device_screenshot_prefetch_wanted` returns true for `computer_use` and properly includes SoM.
  - Verify `prune_previous_screenshots` correctly preserves context caching.
- [ ] **E.3:** Run automated test suite:
  - `cargo test -p c35_mod_chat`
  - `cargo test -p c_remote_windows`
- [ ] **E.4:** End-to-end task run:
  - Run multi-step spreadsheet test (`prompt_device_form_loop.ps1`) to verify 0-turn latency reduction and zero click-drops.
