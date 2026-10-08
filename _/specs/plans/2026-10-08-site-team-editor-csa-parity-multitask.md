# Site Team editor CSA parity — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement task-by-task. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make Sites → **Team** match CSA (`D:\csa_site_published` `UiSiteTeamSection`) — invite by **email or alien id**, searchable member list, role change, remove, ownership transfer, work-shift assignment, optional face enroll when attendance is on — while keeping c35’s locked ACL on **`ai.identity_grant`** (no `site_member` table).

**Architecture:** Port CSA Team **UX and HR payload** into c35. Staff ACL stays `identity_grant(resource_iid=site_iid, role=staff|manage|guest|owner)`. Work shifts / member↔shift / face / presence locations live under **`site.*`** (new tables). Grant put resolves `grantee_iid` | `grantee_alien_id` | **`grantee_email`**. Flutter Team section is a live-RPC port of CSA’s list + master/detail (not a draft autosave bag).

**Tech stack:** Flutter `clients/app`, Rust `mod_site` (+ wire WS), YB `site` + `ai` schemas, protobuf `site.proto` / `wire.proto`.

**Specs:** [`spec.md`](../../spec.md) | [`_/specs/site.md`](../site.md) | [`_/specs/identity.md`](../identity.md) | [`_/schemas/identity.sql`](../schemas/identity.sql) (site roles already include `guest`)

**CSA reference (read-only):**

| Area | Path |
|------|------|
| Team UI | `clients/app/lib/widgets/site/ui_site_team_section.dart` |
| Roles / draft member | `clients/app/lib/core/site/site_member.dart` |
| Draft member/shift APIs | `clients/app/lib/core/site/site_draft.dart` |
| Face photos IO | `clients/app/lib/widgets/site/io_site_member_face_photos.dart` |
| Schedule preview | `clients/app/lib/widgets/ui/ui_schedule_preview.dart`, `core/site/site_schedule*.dart` |
| Server HR | `crates/mod_site/src/hr.rs` |
| Schema | `_/schemas/site.sql` (`site_member`, `site_work_shift*`, `site_member_shift`, `site_member_face`, `site_presence_location`) |

**c35 today:**

| Piece | Status |
|-------|--------|
| `UiSiteTeamEditor` | List + revoke only; empty copy “via chat” |
| `SiteApi.grantPut/List/Delete` | Works; resolve **alien_id / iid only** |
| `site.grant.put` tool | Same; no email |
| Work shifts / face / transfer | **Missing** |
| Members billing quota | **Missing** (CSA `billingSummary.membersLimit`) |

---

## Locked product decisions

| Topic | Decision |
|-------|----------|
| ACL storage | **`ai.identity_grant` only** — never reintroduce `site_member` |
| CSA `employee` / `manager` / `guest` labels | UI labels match CSA; DB roles = **`staff` / `manage` / `guest`** (same mapping as CSA `role_to_db` / `role_from_db`) |
| Owner row | Always shown in Team list (synthetic from `site.config.owner_iid` / `ai.identity.owner_iid` if no grant row); cannot remove/change role except via **transfer** |
| Invite input | Single field accepts **email** *or* **alien_id** (optional `@`); server detects (`@` / no `@` + no `@` in email sense → alien; contains `@` → email) |
| Email resolve | `ai.identity_provider` where `kind='email'` and `lower(identifier)=email`; also accept `meta->>'email'` fallback if provider missing |
| Unknown email | Hard error `user not found` (CSA same) — **no** pending-invite table in v1 |
| Roles grantable via put | `staff`, `manage`, `guest` — not `owner` |
| Transfer ownership | New RPC `site.transfer_ownership` — updates `ai.identity.owner_iid` for the site, demotes previous owner to `manage`, promotes target to `owner` grant |
| Work shifts | New `site.work_shift` + `site.work_shift_slot` + `site.member_shift` (FK to grant via site_iid+grantee_iid, not site_member) |
| Presence locations | Schema + list/put RPCs in same wave as shifts (needed for Attendance later); Team UI only **consumes** shifts |
| Face enroll | Port CSA face put/list/del only when site capabilities include attendance; store `site.member_face` |
| Member seat limit | v1: show **count only** (no hard limit) unless existing billing quota exists; do **not** invent CSA Pro plan tables. UI copy omits “X / limit” until billing track lands |
| Chat tools | Extend `site.grant.put` with `grantee_email`; keep alien_id |
| Master/detail | Team joins products/contacts/objects in `_catalogMasterDetail` |
| Preview pane | Unchanged (right preview stays); Team fills center section like CSA |
| Attendance editor section | **Out of this plan** (CSA has separate Attendance nav) — only Team’s shift toggles + face block on member detail |
| Localizations | Prefer English strings matching current c35 site editors; optional keys in `assets/translations` if easy — do not block on full `easy_localization` parity with CSA keys |

---

## Role mapping (wire)

| CSA UI `role` | c35 `identity_grant.role` | Label |
|---------------|---------------------------|-------|
| `employee` | `staff` | Staff |
| `manager` | `manage` | Manager |
| `guest` | `guest` | Guest |
| `owner` | `owner` | Owner |

Extend `site_grant_role_staff_manage` → `site_grant_role_writable` accepting `staff|manage|guest`.

ACL ranks (existing `site_role_rank`): keep owner > manage > staff; treat **guest** as read-only (rank 0 or between none and staff — **locked: guest < staff**, cannot write). Update `site_role_allows` accordingly.

---

## File map

| File | Action |
|------|--------|
| `_/specs/site.md` | Document Team UX + grant+HR tables |
| `_/schemas/site.sql` | Append `site.work_shift`, `work_shift_slot`, `member_shift`, `member_face`, `presence_location` |
| `_/schemas/proto/c35/site.proto` | Enrich `SiteGrant`; add email on put; work shift / transfer / face messages |
| `_/schemas/proto/c35/wire.proto` | Wire new Req/Res |
| `servers/crates/mod_site/src/site_grant.rs` | Email resolve; guest role; list returns email/avatar/shifts; owner synthetic |
| `servers/crates/mod_site/src/site_hr.rs` | **Create** — work shifts, member_shift, presence, face, transfer (port CSA `hr.rs`) |
| `servers/crates/mod_site/src/lib.rs` | Export + register |
| `servers/crates/mod_chat/src/tools/builtin/site.rs` | `grantee_email` on grant put/delete |
| `clients/app/lib/c/pb/c35/*` | Regen via existing pb pipeline |
| `clients/app/lib/c/site/site_api.dart` | grantPut email; workShift*; transfer; face* |
| `clients/app/lib/c/chat/chat_conn.dart` | WS wrappers |
| `clients/app/lib/c/site/site_member.dart` | **Create** — roles helpers (port CSA) |
| `clients/app/lib/c/site/site_schedule.dart` | Reuse if Info plan already added; else create minimal for Team tiles |
| `clients/app/lib/widgets/ui/ui_schedule_preview.dart` | Port CSA widget (shift toggles on detail) |
| `clients/app/lib/widgets/sites/editor/ui_site_team_editor.dart` | **Replace** with CSA-parity Team UI |
| `clients/app/lib/widgets/sites/editor/io_site_member_face_photos.dart` | Port CSA face IO (attendance-gated) |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_shell.dart` | `team` in masterDetail; pass caps |
| `clients/app/test/site_member_test.dart` | Role mapping + display name |
| `servers/crates/mod_site/tests/site_grant_*` | Email resolve + guest + transfer tests |

---

## Multitask waves

```
WAVE 0  D0   Docs lock (site.md Team section) + role/guest ACL note in identity.md
WAVE 1  S1   site.sql HR tables (work_shift, slots, member_shift, face, presence)
        P1   Proto: SiteGrant enrich + ReqSiteGrantPut.grantee_email + work/face/transfer msgs + wire
WAVE 2  G1   site_grantee_resolve: email | alien_id | iid; guest role on put
        G2   grant_list: email, avatar, work_shift_ids, include owner row
WAVE 3  H1   work_shift list/put (+ slots) RPC  [done]
        H2   member_shift sync on grant put / dedicated put path
        H3   transfer_ownership RPC  [done]
WAVE 4  F1   member_face list/put/del RPC (file hash via existing file CAS)
WAVE 5  C1   Flutter pb regen + SiteApi + ChatConn wrappers
        C2   site_member.dart + schedule preview helpers
WAVE 6  [x] U1   Port UiSiteTeamSection → ui_site_team_editor (list, invite, roles, remove)
        [x] U2   Member detail + UiSchedulePreview + shell masterDetail for team
        [x]  U3   Face photos IO when capabilities.attendance
WAVE 7  [x] T1   Chat tool grantee_email + inst rag_phrases if needed
        [x] V1   Rust tests + flutter analyze/tests
        V2   Manual E2E on @test-site (Chito 99000)
WAVE 8  [x] P2   publish_server if server shipped; app verify script
```

### Parallel assignment

| Wave | Agent A | Agent B | Agent C |
|------|---------|---------|---------|
| 0 | D0 docs | — | — |
| 1 | S1 SQL | P1 proto | — |
| 2 | G1 resolve+roles | G2 list enrich | — |
| 3 | H1 shifts | H2 member_shift | H3 transfer |
| 4 | F1 face | — | — |
| 5 | C1 API wire | C2 models | — |
| 6 | U1 list/invite | U2 detail+shell | U3 face UI |
| 7 | T1 tools | V1 tests | V2 E2E |
| 8 | P2 publish | — | — |

**Dependency rule:** Wave 2 needs Wave 1. Wave 3–4 need Wave 2. Wave 5 needs Wave 1+3 (+4 for face methods). Wave 6 needs Wave 5. Wave 7 after Wave 6.

---

## Track details

### D0 — Docs lock

**Files:** `_/specs/site.md`, `_/specs/identity.md` (short note)

- [x] Add **Team** section: ACL = `identity_grant`; invite email|alien_id; HR tables under `site.*`; role mapping table above; transfer semantics; out-of-scope = Attendance nav / payroll / pending invites.
- [x] Note that guest commerce parity plan's "Full HR deferred" is **superseded for Team editor** by this plan (attendance clock-in still deferred).

### S1 — Schema

**Files:** `_/schemas/site.sql` (append)

Port CSA tables into `site` schema with c35 naming / sync columns:

```sql
-- site.work_shift (site_iid, shift_id PK)
-- site.work_shift_slot
-- site.member_shift (site_iid, grantee_iid, shift_id) — NO FK to site_member
-- site.presence_location
-- site.member_face (face_id snowflake PK; site_iid+grantee_iid; file_hash; embedding real[]; soft delete via is_active or deleted_ts)
```

Use `created_ts` / `updated_ts` / `deleted_ts` where other `site.*` tables do. `member_shift` FK: `REFERENCES site.work_shift (site_iid, shift_id) ON DELETE CASCADE`; grantee is logical (identity id), no FK to grant required (orphan shifts cleaned on grant delete in app).

- [x] Apply to cluster YB (migrate script / existing apply path used by repo).
- [ ] Commit schema only after syntax review.

### P1 — Protobuf

**Files:** `_/schemas/proto/c35/site.proto`, `wire.proto`

Extend:

```protobuf
message SiteGrant {
  // existing fields…
  string grantee_email = 6;
  string grantee_avatar_url = 7;
  repeated string work_shift_ids = 8;
  bool is_owner = 9;  // synthetic owner row or role==owner
}

message ReqSiteGrantPut {
  int64 site_iid = 1;
  int64 grantee_iid = 2;
  string grantee_alien_id = 3;
  string role = 4;
  string grantee_email = 5;           // NEW
  repeated string work_shift_ids = 6; // NEW — replace assignment when set
}
```

Add messages (mirror CSA names, c35 style):

- `ReqSiteWorkShiftList` / `ResSiteWorkShiftList` / `ReqSiteWorkShiftPut` / `ResSiteWorkShiftPut` + `SiteWorkShift` + `SiteWorkShiftSlot`
- `ReqSiteTransferOwnership` / `ResSiteTransferOwnership`
- `ReqSiteMemberFaceList|Put|Del` + `SiteMemberFacePhoto`
- Optional v1: `ReqSitePresenceLocationList|Put` (ship with H1 even if UI later)

Wire numbers: pick next free `WsReq`/`WsRes` ids after existing site grant range (~192–194).

- [ ] Regenerate Dart + Rust pb.
- [ ] `check_utf8_sources.ps1 -Changed -Fix` after edits.

### G1 — Resolve + roles

**Files:** `servers/crates/mod_site/src/site_grant.rs`, `grant.rs`

- [x] `site_grantee_resolve(pool, iid, alien_id, email)`:
  1. `iid > 0` → use
  2. else if email non-empty → lookup provider/meta
  3. else alien_id / numeric string (existing)
- [x] Allow roles `staff|manage|guest` on put.
- [x] Update `site_role_rank` / `site_role_allows` for guest.
- [x] Unit/integration test: resolve by email and alien_id.

### G2 — List enrich + owner

**Files:** `site_grant.rs`, `rows.rs`

List query joins identity + optional email subquery + `site.member_shift` aggregate. Prepend or merge **owner** as `SiteGrant{ is_owner: true, role: owner, … }` if not already in grant rows.

- [x] List SQL: identity name/alien_id/pic, email subquery, `member_shift` work_shift_ids aggregate.
- [x] Synthetic owner row (`is_owner`, role=owner) when missing from grants.
- [x] Map proto fields in `grant_from_row`.
- [x] Test: empty grants still returns owner row.

### H1 / H2 / H3 — HR RPCs

**Files:** `servers/crates/mod_site/src/site_hr.rs` (new), wire dispatch in `server_ai` / existing site RPC router

Port logic from CSA `hr.rs` with identity_grant checks (`site_grant_check(..., write=true)` for manage; transfer requires caller == owner).

On `site_grant_put` when `work_shift_ids` present: replace `site.member_shift` rows (H2). On grant delete: delete member_shift + soft-delete faces.

- [x] H1: `site_work_shift_list` / `site_work_shift_put` (+ slots); soft-delete replace; `wire_ws` dispatch; grant put calls site_member_shift_sync (H2)
- [x] H2: member_shift sync on grant put / dedicated put path
- [x] H3: transfer_ownership RPC (site_grant.rs + wire_ws field 200; integration test site_transfer_ownership_promotes_member)
- [x] F1: member_face list/put/del (+ presence_location list/put); soft-delete; wire_ws 201-205; member_face_test

Transfer (H3):

1. Require caller is owner
2. Target must already have a non-deleted grant (or allow promote-from-staff only — match CSA: must be member)
3. `UPDATE ai.identity SET owner_iid = target WHERE id = site_iid`
4. Upsert grants: old owner → `manage`, target → `owner`
5. Invalidate hints for both

### F1 - Face RPCs

Port CSA face list/put/del; embeddings stored as `REAL[]`. Client uploads image via existing file API → passes `file_hash` + embedding (or server-side embed if c35 already has face pipeline — if **no** FaceNet on c35 server, store photo hash only and defer embedding to empty array with model_version `none` until attendance module ships).

**Locked fallback:** if no FaceNet in c35, face UI stores **photos only** (`embedding = '{}'` or skip CHECK); remove CSA’s 128-dim CHECK or make it `NULL`/empty-allowed.

### C1 / C2 — Client models + API

- [x] `SiteApi.grantPut(..., {String granteeEmail = '', List<String> workShiftIds = const []})`
- [x] `workShiftList` / `workShiftPut`, `transferOwnership`, `memberFaceList|Put|Del`
- [x] `site_member.dart`: `siteMemberRoles`, labels, displayName helpers (port CSA)

### U1 / U2 / U3 — Flutter Team UI


**U1 status:** [x] list + invite + roles + remove (live RPC); masterDetail/detailId hooks for U2.
**U2 status:** [x] member detail + UiSchedulePreview + shell masterDetail/narrow drill for team.

**Primary reference:** copy structure from CSA `ui_site_team_section.dart` into `ui_site_team_editor.dart`, adapting:

- `widget.draft.members` → load via `api.grantList` (+ `workShiftList`)
- `memberAdd(email)` → `grantPut(granteeEmail: …, role: 'staff')` then reload
- Invite dialog hint: `Email or @alien_id`
- Role menu → `grantPut(granteeIid:, role:)`
- Remove → `grantDelete`
- Transfer → `transferOwnership`
- Detail shift toggles → `grantPut` with updated `work_shift_ids` **or** workShift assignment helper
- Toolbar: reuse `UiSiteCatalogToolbar` (c35 already has it; CSA menuItems variant — extend toolbar if needed with `menuItems` optional param)

Shell:

```dart
// _catalogMasterDetail: add section == 'team'
'team' => UiSiteTeamEditor(..., masterDetail: masterDetail, detailId: ..., onDetailIdChanged: ...)
```

Empty state: CSA empty title/subtitle **or** c35-style empty with primary **Invite** affordance — **must not** say “via chat only”.

### T1 — Tools

[x] Done: `grantee_email` on put/delete; `rag_phrases` extended (invite/tambah staff email); no grant inst (tool RAG only). `prompt_compose` 33000 with @test-site-2: `site.grant.put` fed for add-staff @ and invite-staff email phrases.

### V1 / V2 — Verify

**V1 status (2026-10-08):** [x] automated verify complete.

| Check | Result |
|-------|--------|
| `cargo test -p c35_mod_site` | **PASS** — lib 19/19; integration suites green (ignored DB tests left ignored; used `CARGO_TARGET_DIR=.cache/server-v1-test` once while `cargo-watch` held default target lock; later `--lib` also OK on default target) |
| `check_utf8_sources.ps1 -Changed -Fix` | **PASS** — OK on 62 changed text files (`-Files` list; `-Changed` alone can abort on git CRLF stderr under `$ErrorActionPreference=Stop`) |
| `flutter analyze` (team: `site_member` / `site_api` / `ui_site_team_editor`) | **PASS** — no issues (fixed dangling library doc on `site_member.dart`) |
| `flutter test test/site_member_test.dart` | **PASS** — 10/10 |
| `verify_flutter_app.ps1` | **SKIPPED** — targeted analyze + unit test used instead |

**Fixes during V1:** Converted `site_member.dart` file header `///` → `//` to clear `dangling_library_doc_comments`. No compile breakages found in team editor / site_api / mod_site.

```powershell
cd servers; cargo test -p c35_mod_site
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
.\_\scripts\dev\verify_flutter_app.ps1
flutter test test/site_member_test.dart
```

**V2 status:** Manual E2E **not run** this track (checklist ready for Chito 99000 / `@test-site`):

1. [ ] Team empty → Invite by alien_id of a test user → appears as Staff
2. [ ] Invite by email of known account → works
3. [ ] Change role Staff → Manager → persists
4. [ ] Assign a work shift on detail → list tile expand shows hours
5. [ ] Transfer ownership (use disposable site) → old owner becomes Manager
6. [ ] Remove staff → gone; cannot remove owner
7. [ ] Chat: “add staff …” still works with alien_id

### P2 — Publish

**P2 status (2026-10-08):** [x] `publish_server.ps1` succeeded (cluster Buildkit); `c35-server` rolled out 2/2; livez ok; `/version/server` → **280** (`20.280.0`).

If server RPCs shipped: `.\ _\scripts\deploy\publish_server.ps1` and **Publish summary** from `.cache/publish-perf/latest.json`.

---

## Out of scope (explicit)

| Item | Reason |
|------|--------|
| Pending email invites for users who do not exist | CSA resolves existing accounts only; same v1 |
| CSA Pro `membersLimit` hard cap | No c35 site billing seat quota yet |
| Full Attendance nav (clock-in, geo editor UX) | Separate plan; schema/RPC may land here for shifts/geo |
| Payroll / face matching at POS | Deferred |
| Replacing chat grant tools | Keep both UI + chat |

---

## Suggested execution order

1. **Wave 0–1** — docs + SQL + proto (unblocks everything)
2. **Wave 2–3** — grant resolve/list + shifts + transfer
3. **Wave 5–6** — Flutter Team UI (user-visible)
4. **Wave 4 / U3** — face (attendance sites)
5. **Wave 7–8** — tools, tests, publish

---

## Acceptance

- [ ] Sites → Team looks and behaves like CSA Team (list, invite, roles, detail, shifts, transfer, remove)
- [ ] Invite works with **email** and **alien id**
- [ ] No `site_member` table; ACL remains `identity_grant`
- [ ] Owner always visible; protected
- [x] Server + Flutter verify scripts pass (V1: cargo + utf8 + flutter analyze/test; full verify_flutter_app skipped)
- [ ] `_/specs/site.md` updated
