# SOTA Computer Use & Device Control Architecture Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` or `superpowers:executing-plans`. Checkbox tasks (`- [ ]`) are the source of truth.

## Overview & Objective

Alien AI Remote device control (`kind=computer_use`, `device.input`, `device.screenshot`) currently struggles to complete multi-step autonomous tasks (e.g. creating Google Forms, operating wizards, submitting multi-step web forms) due to:
1. Artificial hard limits in `checkpoint.rs` (`COMPUTER_USE_MAX_DEVICE_INPUT = 12`, `COMPUTER_USE_MAX_ROUNDS = 16`).
2. Immediate `stuck_ui` termination when 3 consecutive screenshots match (even during typing, loading, or focusing).
3. Physical input drops in Win32: 0ms dwell time between `mouse_down` and `mouse_up`, and absence of hover hit-testing.
4. Set-of-Mark (SoM) UIA tree traversal capped at 40 elements, cutting off actual application content.
5. Inability to clear fields before typing, leading to mangled input strings.
6. Suboptimal nearest-neighbor image scaling blurring UI labels.

**Target:** Elevate device control execution to SOTA-level reliability:
- Completes 30–60 step end-to-end automation tasks reliably.
- Zero dropped clicks on Chromium, Flutter, and WPF.
- Resilient recovery from transient UI states.
- High-fidelity visual and accessibility perception.

---

## Architectural Breakdown (Parallel Waves & Tracks)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Wave 1: Execution & Checkpoint Unblock (Foundation)                         │
│  ├─ Track A: Win32 Input Dwell, Hover & Composite Actions (c_remote_windows)│
│  ├─ Track B: Checkpoint & Dynamic Budget Expansion (mod_chat/checkpoint.rs) │
│  └─ Track C: Device Tool Schema & Execution Update (mod_chat/device.rs)     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ Wave 2: Perception, Grounding & Scaling                                      │
│  ├─ Track D: UI Automation (UIA) SoM Expansion & Filtering (uia.rs)         │
│  └─ Track E: High-Fidelity Downsampling & Post-Action Delay Tuning           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ Wave 3: Cognitive Steering & Self-Correction                                │
│  ├─ Track F: Prompt Steering & Dual-Mode Playbooks (inst.sql + live inst)    │
│  └─ Track G: Golden Task Regression & Verification Harness                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Wave 1 — Execution & Checkpoint Unblock

### Track A: Win32 Input Dwell, Hover & Composite Action Execution
**Files:**
- Modify: `remotes/c_remote_windows/src/input_exec.rs`

**Key Changes:**
- **Mouse Click Dwell:** Replace instant `send_mouse_event(down)` $\rightarrow$ `send_mouse_event(up)` with a 50–60ms sleep between button down and button up.
- **Hover Settle:** Add a 30ms settle delay after pointer positioning (`nudge_pointer_hit_test` or `sync_remote_pointer`) before sending mouse events to ensure Chromium and Windows message queues register cursor presence.
- **Composite `click_and_type`:** Add native handling for `click_and_type`: moves cursor, clicks, pauses 50ms, sends `Ctrl+A` $\rightarrow$ `Backspace` (clear existing input), pauses 30ms, and sends Unicode text.
- **Double Click Delay:** Ensure double clicks have 60ms dwell between clicks, preventing drops.

- [x] **Task A.1:** Implement hover settle (30ms) and click dwell (60ms) in `execute_input` for `mouse_click`, `double_click`, and `right_click`.
- [x] **Task A.2:** Implement `click_and_type` and `clear_text` event handlers in `input_exec.rs`.
- [x] **Task A.3:** Verify build: `cd remotes && cargo check -p c_remote_windows`.

---

### Track B: Checkpoint & Dynamic Budget Expansion
**Files:**
- Modify: `servers/crates/mod_chat/src/prompt_run/checkpoint.rs`

**Key Changes:**
- **Raise Limits:**
  - `COMPUTER_USE_MAX_DEVICE_INPUT`: raise from `12` to `60`.
  - `COMPUTER_USE_MAX_ROUNDS`: raise from `16` to `75`.
  - `COMPUTER_USE_MAX_SCREENSHOTS`: raise from `20` to `80`.
- **Smarter `checkpoint_screenshot_stuck`:**
  - Increase required consecutive identical screenshot matches from `3` to `5`.
  - Do not count identical screenshots as stuck if the tool in between was `type_text`, `click_and_type`, or keyboard shortcut (where screen layout barely changes).
  - Reset stuck count on any successful input action that changes active focus.

- [x] **Task B.1:** Update threshold constants in `checkpoint.rs`.
- [x] **Task B.2:** Refine `checkpoint_screenshot_stuck` and `checkpoint_record_tool` to prevent false-positive stuck detection during text input or loading states.
- [x] **Task B.3:** Add unit tests in `servers/crates/mod_chat/tests/checkpoint_test.rs` covering extended rounds and stuck-ui tolerance.

---

### Track C: Device Tool Schema & Execution Update
**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/device.rs`

**Key Changes:**
- **Expose `click_and_type`:** Add `click_and_type` to `device.input` parameter documentation and alias mapping.
- **Add `clear_before_type` parameter:** Optional boolean (default true for `click_and_type`) that issues `Ctrl+A` + `Backspace`.
- **Tunable Post-Screenshot Settle:** Increase `screenshot_after` sleep from 200ms to 450ms default (allow DOM/window transitions to render), with optional `settle_ms` parameter up to 1500ms.

- [x] **Task C.1:** Update `DeviceInputTool` parameters and event normalization in `device.rs`.
- [x] **Task C.2:** Support `clear_before_type` and `settle_ms` in `DeviceInputTool::execute`.
- [x] **Task C.3:** Verify `cargo check -p c35_mod_chat`.

---

## Wave 2 — Perception, Grounding & Scaling

### Track D: UI Automation (UIA) SoM Expansion & Filtering
**Files:**
- Modify: `remotes/c_remote_windows/src/uia.rs`

**Key Changes:**
- Increase `WALK_CAP` from `40` to `200`.
- Prioritize interactive elements (`Button`, `Edit`, `ComboBox`, `Hyperlink`, `ListItem`, `CheckBox`, `RadioButton`, `TabItem`).
- Skip invisible, off-screen, or zero-dimension bounding boxes earlier in the walk.
- Include control bounding dimensions and role hint in `axtree_text`.

- [x] **Task D.1:** Refactor `uia_walk` with higher node budget and priority filtering for interactive controls.
- [x] **Task D.2:** Optimize coordinate normalization and bounding box extraction.
- [x] **Task D.3:** Verify formatting in `axtree_text`.

---

### Track E: High-Fidelity Downsampling & Visual Quality
**Files:**
- Modify: `remotes/c_remote_windows/src/screen_capture.rs`

**Key Changes:**
- Replace fast nearest-neighbor `downscale_bgra` with box/area averaging for 2x downscales, preserving thin font strokes, input borders, and badge text.
- Ensure JPEG encoding quality defaults to high-clarity 80 for vision model analysis.

- [x] **Task E.1:** Implement area/box-averaging downscaler in `screen_capture.rs`.
- [x] **Task E.2:** Benchmark downsampling performance to stay under 5ms per frame.

---

## Wave 3 — Steering, Error Recovery & Verification

### Track F: Steering Playbooks & Self-Correction Instructions
**Files:**
- Modify: `_/schemas/inst.sql` (`inst.device.operate`, `inst.computer_use`, `inst.device.google_forms`)

**Key Changes:**
- Instruct agent on the **Verify-Before-Proceed** paradigm:
  1. Observe $\rightarrow$ Hypothesis $\rightarrow$ Act $\rightarrow$ Verify effect.
  2. Use `click_and_type` for filling forms to guarantee clean text entry.
  3. When clicks appear ineffective after 2 tries, pivot immediately to keyboard navigation (`Tab`, `Enter`, `Space`) or URL navigation.
  4. Always inspect follow-up screenshot markers to confirm action impact.

- [x] **Task F.1:** Update `inst.device.operate` and `inst.computer_use` in `_/schemas/inst.sql`.
- [ ] **Task F.2:** Apply updates to live DB via `inst_put` or migration.

---

### Track G: Verification & Golden Task Test Harness
**Files:**
- Verify scripts: `scripts/dev/prompt_device_form_loop.ps1`
- Unit tests: `servers/crates/mod_chat/tests/`

- [x] **Task G.1:** Run full test suite: `cargo test -p c35_mod_chat` and `cargo test -p c_remote_windows`.
- [ ] **Task G.2:** Build server and remote agent binaries:
  - `cargo build -p server_ai`
  - `cargo build -p c_remote_windows`
- [ ] **Task G.3:** Run end-to-end golden verification on VM1 (`prompt_device_form_loop.ps1`) and assert multi-step completion without premature stop.
