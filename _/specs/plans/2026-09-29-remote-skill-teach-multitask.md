# Remote skill teach + Skills tab parity (master multitask plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review this file **before each wave**. Do not start the next wave until the prior **Review gate** is checked off.

**Goal:** End-to-end **interactive teach** on paired Windows remotes (record `skill_step` tape, green border on target PC, non-blocking app HUD) and **Skills tab parity** with cs_agent (edit / delete / run / steps / review), without cs_bots browser recorder.

**Specs:** [`_/specs/skill.md`](../skill.md) 뿯½ [`_/specs/remote.md`](../remote.md) 뿯½ [`_/specs/ui.md`](../ui.md) 뿯½ [`spec.md`](../../spec.md)

**References (read-only):**

| Repo | Borrow |
|------|--------|
| `D:\cs_agent` | `agent_windows` teach hooks + overlay, `PageTeachOverlay` / `PageSkillReview`, `skill_md.dart`, `/v1/teach/*` semantics |
| `D:\cs_bots` | `UiBrowserDisplay` REC chip + save dialog step preview (UX only) |
| c35 today | `UiSkillMasterDetail`, `SkillApi`, `skill_tape` playback |

---

## Outcomes (acceptance)

1. **Remote 뿯↽ Teach skill** stays on **Remote** tab; draggable HUD (default top-right) with **Stop**, live **step count** + **last step label**; pointer hits only the HUD.
2. **Target PC** shows cs_agent-style **green border** + native stop chip (F9) while recording.
3. **Stop** opens **review** (editable markdown + step list) 뿯↽ `ReqSkillPut` with **`steps[]`** persisted in `ai.skill_step`.
4. **Skill tab** shows saved skills with **steps section**, **Edit**, **Delete**, **Run**; rich empty state; no fake “record” on tab switch.
5. **Settings 뿯↽ Skills** (user scope) gets the same detail actions where applicable.

---

## Gap snapshot (why this plan exists)

| Area | Today |
|------|--------|
| `mod_skill::skill_put_rpc` | Upserts `ai.skill` only; **does not write `ai.skill_step`** |
| `remotes/` | `skill_tape` / explore / heal; **no teach recorder** |
| Flutter teach | Tab switch + `io_skill_teach` markdown dialog |
| Skill detail | Markdown only; **ignores `skill.steps`** |
| Wire | No `remote-teach` channel (pattern: `remote-fs`) |

---

## Global constraints (every wave)

- **Proto:** `_/schemas/proto/c35/remote.proto` + `skill.proto`; regenerate Dart (`clients/app` pb) after wire changes.
- **Server:** `cd servers` 뿯↽ `cargo build -p server_ai`; `cargo test -p c35_mod_skill` when crate touched.
- **Agent:** `cd remotes` 뿯↽ `cargo build -p c_remote_windows`; **publish** after `c_remote_core` / `c_remote_windows` ship: `.\_\scripts\deploy\publish_remote_agent.ps1`.
- **App:** `cd clients/app && flutter analyze`; widget tests when adding teach HUD / skill actions.
- **Docs:** Update [`_/specs/skill.md`](../skill.md) UI section in **W0** before implementation disagrees with code.
- **Do not commit** unless user asks.

---

## Architecture (locked for this plan)

```text
Viewer (Flutter)                    WebRTC data ch. `remote-teach`              c_remote_windows
─────────────────                   ─────────────────────────────              ────────────────
Teach HUD (draggable)  ──start/stop/status──뿯▽  protobuf frames     ──뿯▽  teach.rs (port cs_agent)
Remote input (existing) ──RemoteInputEvent──뿯▽  (unchanged)         ──뿯▽  teach_hook records steps
Stop 뿯↽ review dialog     ──ReqSkillPut(steps)──뿯▽  WS / server_ai      ──뿯▽  ai.skill + ai.skill_step
Skill tab library        뿯▽──list/get──────────  mod_skill           뿯▽──  sync collection `skill`
```

**Why data channel:** Same trust boundary as Files (`remote-fs`); works while viewer is connected; no new local HTTP on viewer machine.

**Teach vs Skill tab:** Record on **Remote**; **Skill** tab is library + edit/run only.

---

## Master wave map

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **W0** | Spec + contracts | — | — | `skill.md` + plan aligned; proto sketch reviewed |
| **W1** | Server steps + delete | A=step upsert, B=soft delete | W0 | Put round-trips steps; list returns them |
| **W2** | Agent teach core | C=teach module, D=overlay/HUD on PC | W0 | Unit tests; local teach start/stop |
| **W3** | WebRTC `remote-teach` | E=proto+agent DC, F=Flutter session API | W2 | Status poll returns steps from agent |
| **W4** | Flutter teach UX | G=HUD, H=flow fix, I=review+put | W3, W1 | E2E: teach 뿯↽ save 뿯↽ steps in DB |
| **W5** | Skills tab parity | J=detail actions, K=steps UI, L=empty/run | W1, W4 | Edit/delete/run work on device tab |
| **W6** | P2 polish | M=upgrade, N=needs_review, O=admin/tests | W5 | Optional gates below |

**Parallel dispatch (agents):**

- W1: **A + B** (B after A’s step upsert API shape is clear)
- W2: **C + D**
- W3: **E + F** (F mocks until E merges)
- W4: **G + H + I** (I needs W1)
- W5: **J + K + L**
- W6: **M + N + O**

---

# W0 — Spec + contracts

- [ ] Add **Teach mode UX** to [`_/specs/skill.md`](../skill.md): HUD, agent green border, review dialog, Skill tab responsibilities.
- [ ] Add **Wire** subsection: `remote-teach` messages (see W3 proto list).
- [ ] Link this plan from [`_/specs/remote.md`](../remote.md) Skill row.
- [ ] **Review gate W0:** Chito confirms data-channel approach (vs server-only RPC).

### Proto sketch (`remote.proto` — implement in W3)

| Message | Direction | Purpose |
|---------|-----------|---------|
| `RemoteTeachStartReq` | viewer 뿯↽ agent | `title`, `device_iid` |
| `RemoteTeachStartRes` | agent 뿯↽ viewer | `ok`, `error` |
| `RemoteTeachStopReq` | viewer 뿯↽ agent | — |
| `RemoteTeachStopRes` | agent 뿯↽ viewer | `steps[]` as `RemoteTeachStep` |
| `RemoteTeachStatusReq` | viewer 뿯↽ agent | poll |
| `RemoteTeachStatusRes` | agent 뿯↽ viewer | `recording`, `steps[]`, `duration_sec` |
| `RemoteTeachStep` | — | `ord`, `kind`, `label`, `ax_target_json` (optional on wire) |

---

# W1 — Server: persist steps + delete

## Track A — `skill_step` upsert on put

**File:** `servers/crates/mod_skill/src/rpc.rs` (+ small `steps.rs` if needed)

- [ ] In `skill_put_rpc`, after skill row upsert:
  - [ ] If `doc.steps` non-empty: **replace** steps for `skill_id` (soft-delete old + insert new, or delete+insert in txn).
  - [ ] Set `ord`, `kind`, `label`, `ax_target_json`, `screenshot_hash`, `comment`, `tape_local_only_json` from proto.
  - [ ] Recompute `hash_blake3` optionally from body + steps (document choice in `skill.md`).
- [ ] `skill_list_rpc` / get paths already attach steps — verify after write.
- [ ] `cargo test -p c35_mod_skill` — add integration test with `C35_TEST_DB=1` if crate has harness; else SQL fixture test.

## Track B — Soft delete

- [ ] **Option 1 (minimal):** `ReqSkillPut` with `deleted_ts_ms > 0` updates skill + soft-delete steps.
- [ ] **Option 2:** `ReqSkillDelete` in `skill.proto` + wire (only if put-delete is awkward for clients).
- [ ] Flutter uses one path consistently in W5.

- [ ] **Review gate W1:** `yb` MCP — put skill with 3 steps; `SELECT * FROM ai.skill_step WHERE skill_id = ?` shows rows.

---

# W2 — Agent: teach recorder (cs_agent port)

## Track C — `c_remote_core` / `c_remote_windows`

**Source:** `D:\cs_agent\agents\agent_windows\src\teach.rs`, `teach_hook.rs`, `teach_overlay.rs`, tests in `teach.rs` / `teach_chip_test.rs`.

- [ ] New modules: `remotes/c_remote_core/src/skill_teach.rs` (state machine) + `c_remote_windows` hook integration.
- [ ] While `recording`:
  - [ ] Low-level hooks capture click/type/focus 뿯↽ append `SkillStep`-shaped entries (match `skill_tape` kinds).
  - [ ] Ignore events on teach HUD hit-test regions (mirror cs_agent `TeachClick::Ignore`).
- [ ] `teach_start(title)` / `teach_stop()` / `teach_status()` internal API.
- [ ] **Do not** block `skill_dispatch` / OTA; teach session is separate from `active_tasks` unless spec says otherwise (default: teach counts as idle for OTA).

## Track D — Desktop overlay

- [ ] Port green border + top-left chip + **F9** stop from cs_agent overlay.
- [ ] `cargo test -p c_remote_windows` — port/adapt `teach_chip_test`, `overlay` tests.

- [ ] **Review gate W2:** `cargo build -p c_remote_windows`; manual on VM: start teach locally (dev hook) shows border.

---

# W3 — WebRTC `remote-teach` channel

## Track E — Agent + proto

- [ ] Add messages to `_/schemas/proto/c35/remote.proto`; regenerate pb.
- [ ] Register data channel label `remote-teach` next to `remote-fs` in `c_remote_core` WebRTC session.
- [ ] Frame handler dispatches to `skill_teach` module; encode/decode protobuf.
- [ ] On viewer disconnect: auto `teach_stop` (cancel or finalize — **default: stop and discard** unless steps saved).

## Track F — Flutter `RemoteSession`

**Files:** `clients/app/lib/c/remote/remote_session.dart`, new `remote_teach.dart`

- [ ] `remoteTeachStart(title)`, `remoteTeachStop()`, `remoteTeachStatus()` over data channel.
- [ ] Expose `ValueNotifier`/`Listenable` for HUD: `recording`, `steps`, `lastLabel`.
- [ ] Require WebRTC connected (same as Files).

- [ ] **Review gate W3:** Connected remote; start teach via debug button; status shows `recording: true`.

---

# W4 — Flutter: teach UX

## Track G — Draggable HUD

**New:** `clients/app/lib/widgets/devices/ui_remote_teach_hud.dart`

- [ ] `OverlayEntry` or `Stack` on `UiDeviceDetail` when `activeTab == Remote` && recording.
- [ ] Default position top-right; drag persists per `device_iid` in `RemotePrefs` or skill prefs.
- [ ] `IgnorePointer` on full-screen layer; chip handles taps only.
- [ ] UI: title, `REC mm:ss 뿯½ N steps`, last step ellipsis, **Stop** (primary).
- [ ] Optional expand: scrollable step list (cs_agent list, compact).

## Track H — Flow fix

**Files:** `ui_device_detail.dart`, `ui_remote_device.dart`

- [ ] **Remove** `_remoteTeach` 뿯↽ tab switch + `teach()` dialog.
- [ ] **Teach skill** menu: title prompt (`skillLearnAsk` / short dialog) 뿯↽ `remoteTeachStart` 뿯↽ show HUD.
- [ ] On success path only: navigate to **Skill** tab + select new skill id (post-save).

## Track I — Review + save

**New:** `clients/app/lib/widgets/skill/io_skill_review.dart` + `c/skill/skill_md.dart` (port from cs_agent)

- [ ] `ioSkillReviewShow(title, steps)` 뿯↽ markdown + editable fields + auto-submit toggle.
- [ ] Build `Skill` with `steps`, `SKILL_SOURCE_TAUGHT`, `phrases_json` from title.
- [ ] `SkillApi.put` 뿯↽ refresh skill list if Skill tab mounted.

- [ ] **Review gate W4:** Hyper-V paired device — teach 2 clicks 뿯↽ stop 뿯↽ save 뿯↽ YB has steps; publish agent if W2–W3 changed.

---

# W5 — Skills tab parity

## Track J — Detail actions

**File:** `ui_skill_master_detail.dart`

- [ ] Toolbar: **Edit**, **Run**, **Delete** (match Task tab patterns).
- [ ] **Edit:** `io_skill_edit.dart` — title, `body_md`, phrases (JSON array editor or comma field), `auto_run`, `target_app`, `url_pattern`.
- [ ] **Delete:** confirm 뿯↽ soft delete (W1).
- [ ] **Run:** device scope 뿯↽ open device chat or inject prompt (`skillRunPrompt` from cs_agent); user scope 뿯↽ home chat.

## Track K — Steps in detail

- [ ] If `skill.steps.isNotEmpty`: numbered list above markdown (ord + label).
- [ ] If empty taught skill: hint “Recorded steps appear here after teach mode.”

## Track L — Empty state + entry points

- [ ] Replace one-line empty with cs_agent-style copy (teach on Remote, + install).
- [ ] Device tab **+** menu: **Teach** launches Remote teach (switch to Remote tab + start), not markdown dialog.
- [ ] Keep manual **Import markdown** as secondary item if needed (rename current teach dialog 뿯↽ “Write skill”).

- [ ] **Review gate W5:** `flutter analyze`; manual edit/delete/run on device Skill tab.

---

# W6 — P2 polish (parallel, after W5)

## Track M — Catalog upgrade

- [ ] `ReqSkillCatalogUpgrade` or extend search/install (cs_agent `skill_catalog_upgrade`).
- [ ] Badge on list row when `catalog_release_id` < latest.

## Track N — Circuit breaker UI

- [ ] When `patch_count` high / agent sets needs attention: banner per [`skill.md`](../skill.md).
- [ ] May require `status` column on `ai.skill` if not already exposed on wire — doc first, then proto.

## Track O — Tests + admin

- [ ] Widget test: HUD renders, stop callback.
- [ ] `page_skills_test` equivalent for empty state + add menu.
- [ ] Root: catalog moderate (cs_agent `io_skill_catalog_moderate`) — only if already on server; else defer doc.

- [ ] **Review gate W6:** checklist complete or explicitly deferred with issue links.

---

## E2E checklist (Chito / Hyper-V)

- [ ] Agent online, WebRTC connected.
- [ ] Teach skill from Remote menu 뿯↽ HUD visible, remote green border on VM desktop.
- [ ] Perform 3+ actions 뿯↽ HUD step count increases; last step updates.
- [ ] Stop 뿯↽ review 뿯↽ save.
- [ ] Skill tab 뿯↽ skill selected 뿯↽ steps list + markdown.
- [ ] Run skill 뿯↽ task or chat invokes tape (or graceful message if step kinds unsupported).
- [ ] Edit title 뿯↽ put 뿯↽ reload list.
- [ ] Delete 뿯↽ row gone, steps soft-deleted.
- [ ] OTA: teach session blocks apply only while recording (if wired to `active_tasks`).

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Step kinds from teach ≠ `skill_tape` executor | Map hooks to existing kinds in `skill_tape.rs`; document unsupported in review |
| `skill_put` without step write shipped early | **W1 before W4 I** |
| HUD steals remote clicks | Hit-test only chip; cs_agent `Ignore` on overlay |
| Proto churn | Single W3 PR; regenerate pb once |
| arm64 agent publish | Run publish script after W2–W3; user applies OTA on VM |

---

## Progress snapshot (update when executing)

| Area | Status |
|------|--------|
| Plan doc | **This file** |
| `skill_step` write on put | Not started |
| Agent teach + overlay | Not started |
| `remote-teach` channel | Not started |
| Flutter HUD + review | Not started |
| Skill tab edit/delete/run | Not started |
